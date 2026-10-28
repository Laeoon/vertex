extends Node

## Test Suite: Slot Backup & Restore (S5)
## Cubre snapshots preventivos con rotación, exportación .bak, importación válida,
## rechazo de .bak corruptos y restauración de snapshots.
## Usa slot 3 como origen y slot 2 como destino; el contenido previo de ambos
## (archivos y backups) se guarda en memoria y se restaura al terminar.

const SlotManagerClass = preload("res://juego/system/slot_manager.gd")

const SRC_SLOT: int = 3
const DST_SLOT: int = 2
const SLOTS_UNDER_TEST: Array[int] = [SRC_SLOT, DST_SLOT]

var _passed: int = 0
var _failed: int = 0
var _saved_state: Dictionary = {}
var _tmp_dir: String = ""


func _ready() -> void:
	print("--- START TEST SLOT BACKUP RESTORE ---")
	_tmp_dir = "user://test_slot_backup_restore_tmp"
	_save_state()

	test_snapshot_creation_and_rotation()
	test_export_to_bak()
	test_import_valid_bak()
	test_import_corrupted_bak_rejected()
	test_restore_slot_snapshot()

	_restore_state()
	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


# ---------------------------------------------------------------------------
# Helpers de aislamiento
# ---------------------------------------------------------------------------

func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t := f.get_as_text()
	f.close()
	return t


func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _remove_tree(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for sub in DirAccess.get_directories_at(dir_path):
		_remove_tree("%s/%s" % [dir_path, sub])
	for fname in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute("%s/%s" % [dir_path, fname])
	DirAccess.remove_absolute(dir_path)


func _snapshot_dir_tree(dir_path: String) -> Dictionary:
	var out := {}
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	for fname in DirAccess.get_files_at(dir_path):
		out[fname] = _read_text("%s/%s" % [dir_path, fname])
	for sub in DirAccess.get_directories_at(dir_path):
		out[sub + "/"] = _snapshot_dir_tree("%s/%s" % [dir_path, sub])
	return out


func _write_dir_tree(dir_path: String, tree: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(dir_path)
	for key in tree.keys():
		if key.ends_with("/"):
			_write_dir_tree("%s/%s" % [dir_path, key.trim_suffix("/")], tree[key])
		else:
			_write_text("%s/%s" % [dir_path, key], tree[key])


func _save_state() -> void:
	for sid in SLOTS_UNDER_TEST:
		var files := {}
		for fname in SlotManagerClass.SLOT_FILE_NAMES:
			var p := "%s/%s" % [SlotManagerClass.get_slot_dir(sid), fname]
			if FileAccess.file_exists(p):
				files[fname] = _read_text(p)
		_saved_state[sid] = {
			"files": files,
			"backups": _snapshot_dir_tree(SlotManagerClass.get_slot_backups_dir(sid)),
		}


func _restore_state() -> void:
	for sid in SLOTS_UNDER_TEST:
		_clear_slot_files(sid)
		var st: Dictionary = _saved_state[sid]
		for fname in st["files"].keys():
			_write_text("%s/%s" % [SlotManagerClass.get_slot_dir(sid), fname], st["files"][fname])
		var bdir := SlotManagerClass.get_slot_backups_dir(sid)
		_remove_tree(bdir)
		if not (st["backups"] as Dictionary).is_empty():
			_write_dir_tree(bdir, st["backups"])
	_remove_tree(_tmp_dir)
	SlotManagerClass.invalidate_cache()


func _clear_slot_files(sid: int) -> void:
	for fname in SlotManagerClass.SLOT_FILE_NAMES:
		var p := "%s/%s" % [SlotManagerClass.get_slot_dir(sid), fname]
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _prepare_slot(sid: int, stars: int, player: String) -> void:
	_clear_slot_files(sid)
	_remove_tree(SlotManagerClass.get_slot_backups_dir(sid))
	var progress := ConfigFile.new()
	progress.set_value("estrellas", "backup_level", stars)
	progress.save(SlotManagerClass.get_progress_path(sid))
	var profile := ConfigFile.new()
	profile.set_value("profile", "player_name", player)
	profile.save(SlotManagerClass.get_profile_path(sid))
	var stats := ConfigFile.new()
	stats.set_value("stats", "plays", stars * 10)
	stats.save(SlotManagerClass.get_stats_path(sid))


func _read_cfg_value(path: String, section: String, key: String) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return null
	return cfg.get_value(section, key, null)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_snapshot_creation_and_rotation() -> void:
	_prepare_slot(SRC_SLOT, 3, "Alice")
	_assert(SlotManagerClass.get_slot_snapshots(SRC_SLOT).is_empty(), "Slot sin snapshots al comenzar")

	var created: Array[String] = []
	for i in range(3):
		var r: Dictionary = SlotManagerClass.create_slot_snapshot(SRC_SLOT, "test%d" % i)
		_assert(r.get("success", false) == true, "create_slot_snapshot #%d retorna success" % i)
		_assert(DirAccess.dir_exists_absolute(r.get("path", "")), "Snapshot #%d existe en disco" % i)
		created.append(r.get("path", ""))

	var snaps: Array[String] = SlotManagerClass.get_slot_snapshots(SRC_SLOT)
	_assert(snaps.size() == 3, "get_slot_snapshots lista 3 snapshots (got %d)" % snaps.size())
	_assert(snaps == [created[2], created[1], created[0]], "Snapshots ordenados del más nuevo al más viejo")
	_assert(snaps[0].begins_with(SlotManagerClass.get_slot_backups_dir(SRC_SLOT)), "Snapshots viven en slot_X/backups")

	# Rotación: crear más del máximo
	var oldest: String = created[0]
	var latest := ""
	for i in range(SlotManagerClass.MAX_SNAPSHOTS_PER_SLOT + 3):
		var r2: Dictionary = SlotManagerClass.create_slot_snapshot(SRC_SLOT, "rot%d" % i)
		_assert(r2.get("success", false) == true, "Snapshot de rotación #%d creado" % i)
		latest = r2.get("path", "")

	snaps = SlotManagerClass.get_slot_snapshots(SRC_SLOT)
	_assert(snaps.size() == SlotManagerClass.MAX_SNAPSHOTS_PER_SLOT, "Rotación deja como máximo %d snapshots (got %d)" % [SlotManagerClass.MAX_SNAPSHOTS_PER_SLOT, snaps.size()])
	_assert(not snaps.has(oldest), "El snapshot más antiguo fue eliminado")
	_assert(not DirAccess.dir_exists_absolute(oldest), "Directorio del snapshot más antiguo no existe en disco")
	_assert(snaps[0] == latest, "El snapshot más reciente se conserva en primer lugar")
	var sorted_desc := snaps.duplicate()
	sorted_desc.sort()
	sorted_desc.reverse()
	_assert(snaps == sorted_desc, "Orden descendente se mantiene tras la rotación")

	# Slot vacío: no hay nada que respaldar
	_clear_slot_files(DST_SLOT)
	var empty_r: Dictionary = SlotManagerClass.create_slot_snapshot(DST_SLOT, "empty")
	_assert(empty_r.get("success", true) == false and empty_r.get("error", "") == "nothing_to_snapshot", "Snapshot de slot vacío falla con nothing_to_snapshot")


func test_export_to_bak() -> void:
	_prepare_slot(SRC_SLOT, 2, "Bob")
	var bak_path := "%s/export_ok.bak" % _tmp_dir
	var r: Dictionary = SlotManagerClass.export_slot_to_bak(SRC_SLOT, bak_path)
	_assert(r.get("success", false) == true, "export_slot_to_bak retorna success == true")
	_assert(FileAccess.file_exists(bak_path), "El archivo .bak existe en disco")
	_assert(not FileAccess.file_exists(bak_path + ".tmp"), "No queda archivo temporal tras la escritura atómica")

	var lines := _read_text(bak_path).split("\n")
	_assert(lines.size() == 3, "El .bak contiene exactamente 3 líneas (got %d)" % lines.size())
	if lines.size() == 3:
		_assert(lines[0] == "VERTEX_SAVE_BAK_v1", "Línea 1: cabecera mágica VERTEX_SAVE_BAK_v1")
		_assert(lines[1].length() == 64 and lines[1].is_valid_hex_number(false), "Línea 2: checksum sha256 (64 hex)")
		_assert(lines[1] == lines[2].sha256_text(), "Checksum coincide con el sha256 del payload")
		_assert(r.get("sha256", "") == lines[1], "sha256 retornado coincide con el del archivo")
		var json := JSON.new()
		_assert(json.parse(lines[2]) == OK and typeof(json.data) == TYPE_DICTIONARY, "Línea 3: payload JSON válido")
		if typeof(json.data) == TYPE_DICTIONARY:
			var files: Dictionary = json.data.get("files", {})
			_assert(files.has("progress.cfg") and files.has("profile.cfg") and files.has("stats.cfg"), "Payload incluye progress.cfg, profile.cfg y stats.cfg")

	# Exportar slot vacío falla sin crear archivo
	_clear_slot_files(DST_SLOT)
	var bad_path := "%s/export_empty.bak" % _tmp_dir
	var r_empty: Dictionary = SlotManagerClass.export_slot_to_bak(DST_SLOT, bad_path)
	_assert(r_empty.get("success", true) == false and r_empty.get("error", "") == "nothing_to_export", "Exportar slot vacío falla con nothing_to_export")
	_assert(not FileAccess.file_exists(bad_path), "Exportación fallida no crea archivo")


func test_import_valid_bak() -> void:
	_prepare_slot(SRC_SLOT, 3, "Carol")
	var bak_path := "%s/import_ok.bak" % _tmp_dir
	var exp: Dictionary = SlotManagerClass.export_slot_to_bak(SRC_SLOT, bak_path)
	_assert(exp.get("success", false) == true, "Export previo a importación exitoso")

	# Slot destino con datos distintos, para verificar el snapshot de contingencia
	_prepare_slot(DST_SLOT, 1, "Dave")
	# Calentar la caché con el estado anterior al import
	var before: Dictionary = SlotManagerClass.get_slot_summary(DST_SLOT)
	_assert(before.get("is_empty", true) == false, "Slot destino tiene datos antes de importar")

	var r: Dictionary = SlotManagerClass.import_bak_to_slot(bak_path, DST_SLOT)
	_assert(r.get("success", false) == true, "import_bak_to_slot retorna success == true")

	for fname in SlotManagerClass.SLOT_FILE_NAMES:
		var src_txt := _read_text("%s/%s" % [SlotManagerClass.get_slot_dir(SRC_SLOT), fname])
		var dst_txt := _read_text("%s/%s" % [SlotManagerClass.get_slot_dir(DST_SLOT), fname])
		_assert(not dst_txt.is_empty() and src_txt == dst_txt, "%s del destino coincide con el original" % fname)
	_assert(_read_cfg_value(SlotManagerClass.get_progress_path(DST_SLOT), "estrellas", "backup_level") == 3, "Progreso importado (estrellas == 3)")
	_assert(_read_cfg_value(SlotManagerClass.get_profile_path(DST_SLOT), "profile", "player_name") == "Carol", "Perfil importado (player_name == Carol)")

	# Caché actualizada
	var after: Dictionary = SlotManagerClass.get_slot_summary(DST_SLOT)
	_assert(after.get("is_empty", true) == false, "Resumen del destino no vacío tras importar")
	_assert(after.get("stars", -1) != before.get("stars", -2) or after.get("player_name", "") != before.get("player_name", ""), "La caché refleja los datos importados (resumen cambió)")
	var all_summaries: Array = SlotManagerClass.get_all_slots_summary()
	_assert(all_summaries[DST_SLOT - 1].get("stars", -1) == after.get("stars", -2), "get_all_slots_summary consistente con el slot importado")

	# Snapshot de contingencia del destino
	var snaps: Array[String] = SlotManagerClass.get_slot_snapshots(DST_SLOT)
	_assert(snaps.size() >= 1 and snaps[0].ends_with("_pre_import"), "Se creó snapshot pre_import del destino antes de escribir")
	if snaps.size() >= 1:
		_assert(_read_cfg_value(snaps[0] + "/progress.cfg", "estrellas", "backup_level") == 1, "Snapshot pre_import conserva los datos previos del destino")

	# Archivo inexistente
	var r_missing: Dictionary = SlotManagerClass.import_bak_to_slot("%s/no_existe.bak" % _tmp_dir, DST_SLOT)
	_assert(r_missing.get("success", true) == false and r_missing.get("error", "") == "file_not_found", "Importar archivo inexistente falla con file_not_found")
	# Slot inválido
	var r_slot: Dictionary = SlotManagerClass.import_bak_to_slot(bak_path, 99)
	_assert(r_slot.get("success", true) == false and r_slot.get("error", "") == "invalid_slot", "Importar a slot inválido falla con invalid_slot")


func test_import_corrupted_bak_rejected() -> void:
	_prepare_slot(SRC_SLOT, 3, "Erin")
	var bak_path := "%s/corrupt_base.bak" % _tmp_dir
	SlotManagerClass.export_slot_to_bak(SRC_SLOT, bak_path)
	var original := _read_text(bak_path)
	var lines := original.split("\n")

	# Estado conocido del destino para verificar que no se modifica
	_prepare_slot(DST_SLOT, 1, "Frank")
	var dst_progress_before := _read_text(SlotManagerClass.get_progress_path(DST_SLOT))
	var dst_snaps_before := SlotManagerClass.get_slot_snapshots(DST_SLOT).size()

	# 1) Payload alterado (checksum ya no coincide)
	var tampered_path := "%s/corrupt_payload.bak" % _tmp_dir
	_write_text(tampered_path, "%s\n%s\n%s" % [lines[0], lines[1], lines[2].replace("Erin", "Hack")])
	var r1: Dictionary = SlotManagerClass.import_bak_to_slot(tampered_path, DST_SLOT)
	_assert(r1.get("success", true) == false, "Payload alterado es rechazado")
	_assert(r1.get("error", "") == "checksum_mismatch", "Payload alterado → error == checksum_mismatch (got %s)" % str(r1.get("error", "")))

	# 2) Checksum alterado
	var bad_sum_path := "%s/corrupt_checksum.bak" % _tmp_dir
	_write_text(bad_sum_path, "%s\n%s\n%s" % [lines[0], "0".repeat(64), lines[2]])
	var r2: Dictionary = SlotManagerClass.import_bak_to_slot(bad_sum_path, DST_SLOT)
	_assert(r2.get("success", true) == false and r2.get("error", "") == "checksum_mismatch", "Checksum alterado → checksum_mismatch")

	# 3) Payload truncado
	var trunc_path := "%s/corrupt_truncated.bak" % _tmp_dir
	_write_text(trunc_path, "%s\n%s\n%s" % [lines[0], lines[1], lines[2].substr(0, lines[2].length() / 2)])
	var r3: Dictionary = SlotManagerClass.import_bak_to_slot(trunc_path, DST_SLOT)
	_assert(r3.get("success", true) == false and r3.get("error", "") == "checksum_mismatch", "Payload truncado → checksum_mismatch")

	# 4) Cabecera inválida
	var bad_header_path := "%s/corrupt_header.bak" % _tmp_dir
	_write_text(bad_header_path, "NOT_A_VERTEX_BAK\n%s\n%s" % [lines[1], lines[2]])
	var r4: Dictionary = SlotManagerClass.import_bak_to_slot(bad_header_path, DST_SLOT)
	_assert(r4.get("success", true) == false, "Cabecera inválida es rechazada")
	_assert(r4.get("error", "") == "invalid_header", "Cabecera inválida → error == invalid_header (got %s)" % str(r4.get("error", "")))

	# El slot destino no fue modificado ni se creó snapshot por imports rechazados
	_assert(_read_text(SlotManagerClass.get_progress_path(DST_SLOT)) == dst_progress_before, "Imports rechazados no modifican el slot destino")
	_assert(SlotManagerClass.get_slot_snapshots(DST_SLOT).size() == dst_snaps_before, "Imports rechazados no crean snapshots")


func test_restore_slot_snapshot() -> void:
	_prepare_slot(SRC_SLOT, 3, "Grace")
	var orig_progress := _read_text(SlotManagerClass.get_progress_path(SRC_SLOT))
	var orig_profile := _read_text(SlotManagerClass.get_profile_path(SRC_SLOT))
	var orig_stats := _read_text(SlotManagerClass.get_stats_path(SRC_SLOT))

	var snap: Dictionary = SlotManagerClass.create_slot_snapshot(SRC_SLOT, "before_change")
	_assert(snap.get("success", false) == true, "Snapshot previo a la modificación creado")

	# Modificar un archivo y borrar otro
	var changed := ConfigFile.new()
	changed.set_value("estrellas", "backup_level", 0)
	changed.save(SlotManagerClass.get_progress_path(SRC_SLOT))
	DirAccess.remove_absolute(SlotManagerClass.get_profile_path(SRC_SLOT))
	SlotManagerClass.invalidate_cache()
	_assert(_read_text(SlotManagerClass.get_progress_path(SRC_SLOT)) != orig_progress, "Slot modificado antes de restaurar")
	_assert(not FileAccess.file_exists(SlotManagerClass.get_profile_path(SRC_SLOT)), "profile.cfg eliminado antes de restaurar")

	var r: Dictionary = SlotManagerClass.restore_slot_snapshot(SRC_SLOT)
	_assert(r.get("success", false) == true, "restore_slot_snapshot retorna success == true")
	_assert(_read_text(SlotManagerClass.get_progress_path(SRC_SLOT)) == orig_progress, "progress.cfg restaurado fielmente")
	_assert(_read_text(SlotManagerClass.get_profile_path(SRC_SLOT)) == orig_profile, "profile.cfg restaurado fielmente")
	_assert(_read_text(SlotManagerClass.get_stats_path(SRC_SLOT)) == orig_stats, "stats.cfg restaurado fielmente")
	_assert(SlotManagerClass.get_slot_summary(SRC_SLOT).get("is_empty", true) == false, "Caché del slot restaurado refleja datos")

	# Restaurar tras borrado total del slot, indicando el snapshot explícito
	_clear_slot_files(SRC_SLOT)
	SlotManagerClass.invalidate_cache()
	_assert(SlotManagerClass.get_slot_summary(SRC_SLOT).get("is_empty", false) == true, "Slot vacío tras borrar archivos")
	var r2: Dictionary = SlotManagerClass.restore_slot_snapshot(SRC_SLOT, snap.get("path", ""))
	_assert(r2.get("success", false) == true, "Restauración de snapshot explícito tras borrado total")
	_assert(_read_text(SlotManagerClass.get_stats_path(SRC_SLOT)) == orig_stats, "stats.cfg restaurado tras borrado total")
	_assert(SlotManagerClass.get_slot_summary(SRC_SLOT).get("is_empty", true) == false, "Resumen del slot ya no está vacío")

	# Sin snapshots: error sin tocar datos
	_remove_tree(SlotManagerClass.get_slot_backups_dir(SRC_SLOT))
	var r3: Dictionary = SlotManagerClass.restore_slot_snapshot(SRC_SLOT)
	_assert(r3.get("success", true) == false and r3.get("error", "") == "no_snapshots", "Restaurar sin snapshots falla con no_snapshots")
	_assert(_read_text(SlotManagerClass.get_progress_path(SRC_SLOT)) == orig_progress, "Fallo de restauración no altera los datos")
