class_name SlotManager extends RefCounted

## SlotManager
## Manages multiple independent operator save slots (Slots 1, 2, 3) in `user://slots/slot_X/`.
## Transparently migrates legacy flat save files into slot 1 to ensure zero progress loss.

const TOTAL_SLOTS: int = 3
const SLOTS_META_PATH: String = "user://slots.cfg"
const SLOTS_BASE_DIR: String = "user://slots"
const MAX_SNAPSHOTS_PER_SLOT: int = 5
const BAK_MAGIC_HEADER: String = "VERTEX_SAVE_BAK_v1"
const DEFAULT_BACKUPS_DIR: String = "user://backups"
const SLOT_FILE_NAMES: Array[String] = ["progress.cfg", "profile.cfg", "stats.cfg"]
const SNAPSHOT_PREFIX: String = "snapshot_"

static var _active_slot: int = 1
static var _initialized: bool = false


## Initializes the slots subsystem, creating directories and migrating legacy files if present.
static func init_slots() -> void:
	if _initialized:
		return
	_ensure_directories()
	_migrate_legacy_if_needed()
	_load_active_slot()
	_initialized = true


static func get_active_slot() -> int:
	if not _initialized:
		init_slots()
	return _active_slot


static func set_active_slot(slot_id: int) -> void:
	if slot_id < 1 or slot_id > TOTAL_SLOTS:
		push_error("SlotManager: ID de slot inválido: %d" % slot_id)
		return
	if not _initialized:
		init_slots()
	_active_slot = slot_id
	_cache_dirty = true

	var cfg := ConfigFile.new()
	cfg.load(SLOTS_META_PATH)
	cfg.set_value("slots", "active_slot", _active_slot)
	cfg.save(SLOTS_META_PATH)


static func get_slot_dir(slot_id: int) -> String:
	return "%s/slot_%d" % [SLOTS_BASE_DIR, slot_id]


static func get_progress_path(slot_id: int = -1) -> String:
	var sid := _active_slot if slot_id <= 0 else slot_id
	return "%s/progress.cfg" % get_slot_dir(sid)


static func get_profile_path(slot_id: int = -1) -> String:
	var sid := _active_slot if slot_id <= 0 else slot_id
	return "%s/profile.cfg" % get_slot_dir(sid)


static func get_stats_path(slot_id: int = -1) -> String:
	var sid := _active_slot if slot_id <= 0 else slot_id
	return "%s/stats.cfg" % get_slot_dir(sid)


## Resetea y borra por completo los datos de una ranura de guardado.
static func delete_slot(slot_id: int) -> bool:
	if slot_id < 1 or slot_id > TOTAL_SLOTS:
		push_error("SlotManager: ID de slot inválido para borrar: %d" % slot_id)
		return false

	var p_path := get_progress_path(slot_id)
	var prof_path := get_profile_path(slot_id)
	var st_path := get_stats_path(slot_id)

	# Snapshot preventivo: si falla (p. ej. ranura vacía) el borrado continúa.
	create_slot_snapshot(slot_id, "pre_delete")

	if FileAccess.file_exists(p_path):
		DirAccess.remove_absolute(p_path)
	if FileAccess.file_exists(prof_path):
		DirAccess.remove_absolute(prof_path)
	if FileAccess.file_exists(st_path):
		DirAccess.remove_absolute(st_path)

	invalidate_cache()
	return true


# ---------------------------------------------------------------------------
# Snapshots preventivos
# ---------------------------------------------------------------------------

static func get_slot_backups_dir(slot_id: int) -> String:
	return "%s/backups" % get_slot_dir(slot_id)


## Copia progress/profile/stats del slot a `backups/snapshot_<timestamp>_<tag>` y rota los antiguos.
## Retorna {"success": true, "path": dir, "files": [...]} o {"success": false, "error": code, "message": text}.
static func create_slot_snapshot(slot_id: int = -1, tag: String = "auto") -> Dictionary:
	var sid := _resolve_slot_id(slot_id)
	if not _is_valid_slot(sid):
		return _fail("invalid_slot", "ID de slot inválido: %d" % sid)

	var existing: Array[String] = []
	for fname in SLOT_FILE_NAMES:
		if FileAccess.file_exists("%s/%s" % [get_slot_dir(sid), fname]):
			existing.append(fname)
	if existing.is_empty():
		return _fail("nothing_to_snapshot", "El slot %d no tiene archivos que respaldar" % sid)

	var backups_dir := get_slot_backups_dir(sid)
	var mk_err := DirAccess.make_dir_recursive_absolute(backups_dir)
	if mk_err != OK:
		return _fail("mkdir_failed", "No se pudo crear %s (error %d)" % [backups_dir, mk_err])

	var safe_tag := _sanitize_tag(tag)
	var unix_time := Time.get_unix_time_from_system()
	var dir_name := ""
	while true:
		dir_name = "%s%s_%s" % [SNAPSHOT_PREFIX, _timestamp_string(unix_time), safe_tag]
		if not DirAccess.dir_exists_absolute("%s/%s" % [backups_dir, dir_name]):
			break
		unix_time += 0.001

	var tmp_dir := "%s/tmp_%s" % [backups_dir, dir_name]
	var final_dir := "%s/%s" % [backups_dir, dir_name]
	if DirAccess.dir_exists_absolute(tmp_dir):
		_remove_dir_with_files(tmp_dir)
	if DirAccess.make_dir_recursive_absolute(tmp_dir) != OK:
		return _fail("mkdir_failed", "No se pudo crear %s" % tmp_dir)

	for fname in existing:
		if not _copy_file_atomic("%s/%s" % [get_slot_dir(sid), fname], "%s/%s" % [tmp_dir, fname]):
			_remove_dir_with_files(tmp_dir)
			return _fail("copy_failed", "No se pudo copiar %s al snapshot" % fname)

	var ren_err := DirAccess.rename_absolute(tmp_dir, final_dir)
	if ren_err != OK:
		_remove_dir_with_files(tmp_dir)
		return _fail("rename_failed", "No se pudo finalizar el snapshot (error %d)" % ren_err)

	_rotate_snapshots(sid)
	return {"success": true, "path": final_dir, "files": existing}


## Lista las rutas de snapshots del slot, del más nuevo al más antiguo.
static func get_slot_snapshots(slot_id: int = -1) -> Array[String]:
	var result: Array[String] = []
	var sid := _resolve_slot_id(slot_id)
	if not _is_valid_slot(sid):
		return result
	var backups_dir := get_slot_backups_dir(sid)
	if not DirAccess.dir_exists_absolute(backups_dir):
		return result
	var names: Array[String] = []
	for d in DirAccess.get_directories_at(backups_dir):
		if d.begins_with(SNAPSHOT_PREFIX):
			names.append(d)
	names.sort()
	names.reverse()
	for n in names:
		result.append("%s/%s" % [backups_dir, n])
	return result


## Restaura un snapshot (el más reciente si `snapshot_dir` está vacío) sobre el slot e invalida la caché.
static func restore_slot_snapshot(slot_id: int, snapshot_dir: String = "") -> Dictionary:
	if not _is_valid_slot(slot_id):
		return _fail("invalid_slot", "ID de slot inválido: %d" % slot_id)

	var snap := snapshot_dir
	if snap.is_empty():
		var snaps := get_slot_snapshots(slot_id)
		if snaps.is_empty():
			return _fail("no_snapshots", "El slot %d no tiene snapshots" % slot_id)
		snap = snaps[0]
	else:
		# Solo se aceptan snapshots dentro del directorio de backups del slot.
		var snap_name := snapshot_dir.trim_suffix("/").get_file()
		if not snap_name.begins_with(SNAPSHOT_PREFIX):
			return _fail("invalid_snapshot", "Snapshot inválido: %s" % snapshot_dir)
		snap = "%s/%s" % [get_slot_backups_dir(slot_id), snap_name]

	if not DirAccess.dir_exists_absolute(snap):
		return _fail("snapshot_not_found", "No existe el snapshot: %s" % snap)

	var to_restore: Array[String] = []
	for fname in SLOT_FILE_NAMES:
		if FileAccess.file_exists("%s/%s" % [snap, fname]):
			to_restore.append(fname)
	if to_restore.is_empty():
		return _fail("empty_snapshot", "El snapshot no contiene archivos: %s" % snap)

	var sdir := get_slot_dir(slot_id)
	DirAccess.make_dir_recursive_absolute(sdir)
	for fname in to_restore:
		if not _copy_file_atomic("%s/%s" % [snap, fname], "%s/%s" % [sdir, fname]):
			invalidate_cache()
			return _fail("copy_failed", "No se pudo restaurar %s" % fname)

	invalidate_cache()
	return {"success": true, "slot_id": slot_id, "path": snap, "files": to_restore}


# ---------------------------------------------------------------------------
# Exportación / importación .bak
# ---------------------------------------------------------------------------

## Exporta el slot a un archivo .bak: línea 1 cabecera, línea 2 sha256 del payload, línea 3 payload JSON.
static func export_slot_to_bak(slot_id: int, target_path: String = "") -> Dictionary:
	if not _is_valid_slot(slot_id):
		return _fail("invalid_slot", "ID de slot inválido: %d" % slot_id)

	var files := {}
	for fname in SLOT_FILE_NAMES:
		var fpath := "%s/%s" % [get_slot_dir(slot_id), fname]
		if not FileAccess.file_exists(fpath):
			continue
		var f := FileAccess.open(fpath, FileAccess.READ)
		if f == null:
			return _fail("read_failed", "No se pudo leer %s" % fpath)
		files[fname] = f.get_as_text()
		f.close()
	if files.is_empty():
		return _fail("nothing_to_export", "El slot %d no tiene archivos que exportar" % slot_id)

	var path := target_path
	if path.is_empty():
		path = "%s/vertex_slot_%d_%s.bak" % [DEFAULT_BACKUPS_DIR, slot_id, _timestamp_string(Time.get_unix_time_from_system())]

	var base_dir := path.get_base_dir()
	if not base_dir.is_empty() and not DirAccess.dir_exists_absolute(base_dir):
		var mk_err := DirAccess.make_dir_recursive_absolute(base_dir)
		if mk_err != OK:
			return _fail("mkdir_failed", "No se pudo crear %s (error %d)" % [base_dir, mk_err])

	var meta := {
		"format": BAK_MAGIC_HEADER,
		"slot_id": slot_id,
		"exported_at": Time.get_datetime_string_from_system(),
		"files": files,
	}
	var payload := JSON.stringify(meta)
	var checksum := payload.sha256_text()
	var content := "%s\n%s\n%s" % [BAK_MAGIC_HEADER, checksum, payload]

	# Escritura atómica: archivo temporal + rename.
	var tmp_path := path + ".tmp"
	var out := FileAccess.open(tmp_path, FileAccess.WRITE)
	if out == null:
		return _fail("write_failed", "No se pudo escribir %s (error %d)" % [tmp_path, FileAccess.get_open_error()])
	out.store_string(content)
	out.close()
	var ren_err := DirAccess.rename_absolute(tmp_path, path)
	if ren_err != OK:
		DirAccess.remove_absolute(tmp_path)
		return _fail("rename_failed", "No se pudo finalizar %s (error %d)" % [path, ren_err])

	return {"success": true, "path": path, "sha256": checksum}


## Importa un .bak al slot destino tras validar cabecera y checksum y tomar un snapshot "pre_import".
static func import_bak_to_slot(bak_path: String, target_slot_id: int) -> Dictionary:
	if not _is_valid_slot(target_slot_id):
		return _fail("invalid_slot", "ID de slot inválido: %d" % target_slot_id)
	if not FileAccess.file_exists(bak_path):
		return _fail("file_not_found", "No existe el archivo: %s" % bak_path)

	var f := FileAccess.open(bak_path, FileAccess.READ)
	if f == null:
		return _fail("read_failed", "No se pudo abrir %s" % bak_path)
	var header := f.get_line().strip_edges()
	var expected := f.get_line().strip_edges().to_lower()
	var payload := ""
	if f.get_position() < f.get_length():
		payload = f.get_buffer(f.get_length() - f.get_position()).get_string_from_utf8()
	f.close()

	if header != BAK_MAGIC_HEADER:
		return _fail("invalid_header", "Cabecera inválida (se esperaba %s)" % BAK_MAGIC_HEADER)
	if payload.sha256_text() != expected:
		return _fail("checksum_mismatch", "El checksum sha256 no coincide: el archivo está corrupto o fue modificado")

	var json := JSON.new()
	if json.parse(payload) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _fail("invalid_json", "El contenido del .bak no es JSON válido")
	var data: Dictionary = json.data
	if typeof(data.get("files")) != TYPE_DICTIONARY:
		return _fail("invalid_payload", "El .bak no contiene la sección 'files'")
	var files: Dictionary = data["files"]

	var to_write := {}
	for key in files.keys():
		if typeof(key) != TYPE_STRING or not SLOT_FILE_NAMES.has(key):
			return _fail("invalid_payload", "Archivo no permitido en el .bak: %s" % str(key))
		if typeof(files[key]) != TYPE_STRING:
			return _fail("invalid_payload", "Contenido inválido para %s" % str(key))
		var probe := ConfigFile.new()
		if probe.parse(files[key]) != OK:
			return _fail("invalid_payload", "%s no es un ConfigFile válido" % str(key))
		to_write[key] = files[key]
	if to_write.is_empty():
		return _fail("invalid_payload", "El .bak no contiene archivos de guardado")

	# Snapshot de contingencia: un slot vacío no tiene nada que respaldar.
	var snap := create_slot_snapshot(target_slot_id, "pre_import")
	if not snap.get("success", false) and snap.get("error", "") != "nothing_to_snapshot":
		return _fail("snapshot_failed", "No se pudo crear el snapshot previo: %s" % str(snap.get("message", "")))

	var sdir := get_slot_dir(target_slot_id)
	if DirAccess.make_dir_recursive_absolute(sdir) != OK:
		return _fail("mkdir_failed", "No se pudo crear %s" % sdir)
	for fname in to_write.keys():
		if not _write_text_atomic("%s/%s" % [sdir, fname], to_write[fname]):
			invalidate_cache()
			return _fail("write_failed", "No se pudo escribir %s" % fname)

	invalidate_cache()
	return {"success": true, "slot_id": target_slot_id}


# ---------------------------------------------------------------------------
# Helpers internos
# ---------------------------------------------------------------------------

static func _fail(code: String, message: String) -> Dictionary:
	push_warning("SlotManager: %s" % message)
	return {"success": false, "error": code, "message": message}


static func _is_valid_slot(slot_id: int) -> bool:
	return slot_id >= 1 and slot_id <= TOTAL_SLOTS


static func _resolve_slot_id(slot_id: int) -> int:
	return _active_slot if slot_id <= 0 else slot_id


## Timestamp ordenable lexicográficamente: YYYYMMDD_HHMMSS_mmm.
static func _timestamp_string(unix_time: float) -> String:
	var d := Time.get_datetime_dict_from_unix_time(int(unix_time))
	var ms := int(fmod(unix_time, 1.0) * 1000.0)
	return "%04d%02d%02d_%02d%02d%02d_%03d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"], d["second"], ms]


static func _sanitize_tag(tag: String) -> String:
	var out := ""
	for ch in tag:
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == "_" or ch == "-":
			out += ch
	return out if not out.is_empty() else "auto"


static func _rotate_snapshots(slot_id: int) -> void:
	var snaps := get_slot_snapshots(slot_id)
	for i in range(MAX_SNAPSHOTS_PER_SLOT, snaps.size()):
		_remove_dir_with_files(snaps[i])


static func _remove_dir_with_files(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for fname in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute("%s/%s" % [dir_path, fname])
	DirAccess.remove_absolute(dir_path)


static func _copy_file_atomic(src: String, dst: String) -> bool:
	var f_in := FileAccess.open(src, FileAccess.READ)
	if f_in == null:
		return false
	var bytes := f_in.get_buffer(f_in.get_length())
	f_in.close()
	var tmp := dst + ".tmp"
	var f_out := FileAccess.open(tmp, FileAccess.WRITE)
	if f_out == null:
		return false
	f_out.store_buffer(bytes)
	f_out.close()
	if DirAccess.rename_absolute(tmp, dst) != OK:
		DirAccess.remove_absolute(tmp)
		return false
	return true


static func _write_text_atomic(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	if DirAccess.rename_absolute(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)
		return false
	return true


# Cache de resúmenes de slots para evitar lecturas de disco por frame
static var _cached_summaries: Array[Dictionary] = []
static var _cache_dirty: bool = true


static func invalidate_cache() -> void:
	_cache_dirty = true


## Returns an array of dictionaries summarizing each of the 3 slots.
static func get_all_slots_summary() -> Array[Dictionary]:
	if not _initialized:
		init_slots()
	if not _cache_dirty and not _cached_summaries.is_empty():
		return _cached_summaries

	var list: Array[Dictionary] = []
	for sid in range(1, TOTAL_SLOTS + 1):
		list.append(get_slot_summary(sid))
	_cached_summaries = list
	_cache_dirty = false
	return list


static func get_slot_summary(slot_id: int) -> Dictionary:
	var p_path := get_progress_path(slot_id)
	var prof_path := get_profile_path(slot_id)

	var is_empty := true
	var player_name := "Operador %d" % slot_id
	var total_stars := 0
	var completed_levels := 0

	var p_cfg := ConfigFile.new()
	if p_cfg.load(p_path) == OK:
		var keys := p_cfg.get_section_keys("estrellas")
		for k in keys:
			if not k.ends_with("_mejor_coste"):
				var stars: int = p_cfg.get_value("estrellas", k, 0)
				if stars > 0:
					is_empty = false
					completed_levels += 1
					total_stars += stars

	var prof_cfg := ConfigFile.new()
	if prof_cfg.load(prof_path) == OK:
		var stored_name: String = prof_cfg.get_value("profile", "player_name", "")
		if not stored_name.is_empty():
			player_name = stored_name
			is_empty = false

	return {
		"slot_id": slot_id,
		"player_name": player_name,
		"stars": total_stars,
		"levels_completed": completed_levels,
		"is_empty": is_empty,
		"is_active": (slot_id == _active_slot),
	}


static func _ensure_directories() -> void:
	if not DirAccess.dir_exists_absolute(SLOTS_BASE_DIR):
		DirAccess.make_dir_recursive_absolute(SLOTS_BASE_DIR)
	for sid in range(1, TOTAL_SLOTS + 1):
		var sdir := get_slot_dir(sid)
		if not DirAccess.dir_exists_absolute(sdir):
			DirAccess.make_dir_recursive_absolute(sdir)


static func _load_active_slot() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SLOTS_META_PATH) == OK:
		_active_slot = clampi(cfg.get_value("slots", "active_slot", 1), 1, TOTAL_SLOTS)
	else:
		_active_slot = 1


static func _migrate_legacy_if_needed() -> void:
	# Si ya existe slots.cfg, la migración previa ya ocurrió
	if FileAccess.file_exists(SLOTS_META_PATH):
		return

	# Comprobar si existen partidas planas heredadas
	var legacy_progress := "user://progress.cfg"
	var legacy_profile := "user://profile.cfg"
	var legacy_stats := "user://stats.cfg"

	var slot1_dir := get_slot_dir(1)
	if FileAccess.file_exists(legacy_progress):
		_copy_file(legacy_progress, "%s/progress.cfg" % slot1_dir)
	if FileAccess.file_exists(legacy_profile):
		_copy_file(legacy_profile, "%s/profile.cfg" % slot1_dir)
	if FileAccess.file_exists(legacy_stats):
		_copy_file(legacy_stats, "%s/stats.cfg" % slot1_dir)

	var cfg := ConfigFile.new()
	cfg.set_value("slots", "active_slot", 1)
	cfg.save(SLOTS_META_PATH)


static func _copy_file(src: String, dst: String) -> void:
	var f_in := FileAccess.open(src, FileAccess.READ)
	if f_in != null:
		var f_out := FileAccess.open(dst, FileAccess.WRITE)
		if f_out != null:
			f_out.store_buffer(f_in.get_buffer(f_in.get_length()))
			f_out.close()
		f_in.close()
