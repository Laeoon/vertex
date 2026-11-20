extends Node

## Headless verification for F1.1: VaultStore, per-slot isolation, vault.cfg snapshots/.bak SHA-256,
## ProgressUtil total_stars, and real Profile.build_level_rows() / stats loading.

const SlotManagerClass = preload("res://juego/system/slot_manager.gd")
const VaultStoreClass = preload("res://juego/system/vault_store.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")
const ProfileClass = preload("res://escenas/menu/profile.gd")

const TEST_SLOT_A: int = 2
const TEST_SLOT_B: int = 3

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS: " + msg)
	else:
		_failed += 1
		push_error("FAIL: " + msg)


func _snapshot_files(slot_id: int) -> Dictionary:
	var saved: Dictionary = {}
	var dir_path: String = SlotManagerClass.get_slot_dir(slot_id)
	for fname: String in SlotManagerClass.SLOT_FILE_NAMES:
		var path: String = "%s/%s" % [dir_path, fname]
		if FileAccess.file_exists(path):
			saved[fname] = FileAccess.get_file_as_string(path)
	return saved


func _restore_files(slot_id: int, saved: Dictionary) -> void:
	var dir_path: String = SlotManagerClass.get_slot_dir(slot_id)
	DirAccess.make_dir_recursive_absolute(dir_path)
	for fname: String in SlotManagerClass.SLOT_FILE_NAMES:
		var path: String = "%s/%s" % [dir_path, fname]
		if saved.has(fname):
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_string(str(saved[fname]))
				f.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	SlotManagerClass.invalidate_cache()


func _clear_slot_direct(slot_id: int) -> void:
	var dir_path: String = SlotManagerClass.get_slot_dir(slot_id)
	for fname: String in SlotManagerClass.SLOT_FILE_NAMES:
		var path: String = "%s/%s" % [dir_path, fname]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	SlotManagerClass.invalidate_cache()


func _run_tests() -> void:
	print("--- START TEST VAULT STORE AND SLOTS (F1.1) ---")
	SlotManagerClass.init_slots()

	var orig_slot: int = SlotManagerClass.get_active_slot()
	var backup_a: Dictionary = _snapshot_files(TEST_SLOT_A)
	var backup_b: Dictionary = _snapshot_files(TEST_SLOT_B)
	var tmp_bak_path: String = "user://backups/test_f1_1_vault_export.bak"

	_clear_slot_direct(TEST_SLOT_A)
	_clear_slot_direct(TEST_SLOT_B)

	# 1. SLOT_FILE_NAMES includes vault.cfg and get_vault_path resolves per slot
	_assert(SlotManagerClass.SLOT_FILE_NAMES.has("vault.cfg"), "SlotManager.SLOT_FILE_NAMES incluye vault.cfg")
	_assert(SlotManagerClass.get_vault_path(TEST_SLOT_A).ends_with("slot_2/vault.cfg"), "get_vault_path(2) apunta a slot_2/vault.cfg")
	_assert(SlotManagerClass.get_vault_path(TEST_SLOT_B).ends_with("slot_3/vault.cfg"), "get_vault_path(3) apunta a slot_3/vault.cfg")

	# 2. Per-slot isolation for profile & .enc vault state
	SlotManagerClass.set_active_slot(TEST_SLOT_A)
	var save_prof_err: Error = VaultStoreClass.save_profile("OperadorA", "NEXO MAESTRO")
	var save_vault_err: Error = VaultStoreClass.save_vault({0: true, 2: true}, "TrackMenuA", "TrackGameA")
	_assert(save_prof_err == OK, "VaultStore.save_profile guarda en slot activo")
	_assert(save_vault_err == OK, "VaultStore.save_vault guarda en slot activo")

	var loaded_prof_a: Dictionary = VaultStoreClass.load_profile(TEST_SLOT_A)
	var loaded_vault_a: Dictionary = VaultStoreClass.load_vault(TEST_SLOT_A)
	_assert(str(loaded_prof_a.get("player_name", "")) == "OperadorA", "Slot A conserva player_name")
	_assert(bool(loaded_vault_a.get("enc_unlocked", {}).get(0, false)), "Slot A persiste _enc_unlocked[0]")
	_assert(bool(loaded_vault_a.get("enc_unlocked", {}).get(2, false)), "Slot A persiste _enc_unlocked[2]")
	_assert((loaded_vault_a.get("decrypted_enc_files", []) as Array).size() == 2, "Slot A resuelve 2 decrypted_enc_files")

	SlotManagerClass.set_active_slot(TEST_SLOT_B)
	var loaded_prof_b: Dictionary = VaultStoreClass.load_profile()
	var loaded_vault_b: Dictionary = VaultStoreClass.load_vault()
	_assert(str(loaded_prof_b.get("player_name", "")) == VaultStoreClass.DEFAULT_PLAYER_NAME, "Slot B aislado no hereda player_name de Slot A")
	_assert((loaded_vault_b.get("enc_unlocked", {}) as Dictionary).is_empty(), "Slot B aislado no hereda _enc_unlocked de Slot A")
	_assert(str(loaded_vault_b.get("pinned_menu_track", "")) == VaultStoreClass.DEFAULT_PINNED_MENU_TRACK, "Slot B aislado no hereda pinned_menu_track de Slot A")

	# 3. Snapshots & .bak SHA-256 cover vault.cfg
	var snap_res: Dictionary = SlotManagerClass.create_slot_snapshot(TEST_SLOT_A, "f1_1_vault")
	_assert(bool(snap_res.get("success", false)), "create_slot_snapshot incluye slot con vault.cfg")
	var snap_dir: String = str(snap_res.get("path", ""))
	_assert(FileAccess.file_exists(snap_dir + "/vault.cfg"), "Snapshot contiene vault.cfg")

	var export_res: Dictionary = SlotManagerClass.export_slot_to_bak(TEST_SLOT_A, tmp_bak_path)
	_assert(bool(export_res.get("success", false)), "export_slot_to_bak con vault.cfg tiene éxito")
	_assert(str(export_res.get("sha256", "")).length() == 64, "export_slot_to_bak genera checksum SHA-256")

	var import_res: Dictionary = SlotManagerClass.import_bak_to_slot(tmp_bak_path, TEST_SLOT_B)
	_assert(bool(import_res.get("success", false)), "import_bak_to_slot restaura vault.cfg a Slot B")
	var imported_vault_b: Dictionary = VaultStoreClass.load_vault(TEST_SLOT_B)
	_assert(bool(imported_vault_b.get("enc_unlocked", {}).get(2, false)), "Slot B recibe _enc_unlocked[2] vía .bak verificado")

	# delete_slot removes vault.cfg too
	_assert(SlotManagerClass.delete_slot(TEST_SLOT_B), "delete_slot(3) retorna true")
	_assert(not FileAccess.file_exists(SlotManagerClass.get_vault_path(TEST_SLOT_B)), "delete_slot elimina vault.cfg")

	# 4. ProgressUtil.cargar_progreso() computes deterministic total_stars
	SlotManagerClass.set_active_slot(TEST_SLOT_B)
	var empty_prog: Dictionary = ProgressUtilClass.cargar_progreso()
	_assert(int(empty_prog.get("total_stars", -1)) == 0, "Slot vacío retorna total_stars == 0")

	ProgressUtilClass.guardar_progreso("heist_n1", 3)
	ProgressUtilClass.guardar_progreso("heist_n2", 2)
	var prog_cfg := ConfigFile.new()
	prog_cfg.load(ProgressUtilClass.get_progress_file_path())
	prog_cfg.set_value("estrellas", "heist_n1_mejor_coste", 7.5)
	prog_cfg.save(ProgressUtilClass.get_progress_file_path())

	var loaded_prog: Dictionary = ProgressUtilClass.cargar_progreso()
	_assert(int(loaded_prog.get("total_stars", 0)) == 5, "ProgressUtil.cargar_progreso() suma total_stars == 5 ignorando _mejor_coste")
	_assert(int(loaded_prog.get("heist_n1", 0)) == 3, "ProgressUtil conserva clave heist_n1 == 3")

	# 5. Profile.build_level_rows() reflects real slot progress (empty vs populated)
	var empty_rows: Array[Dictionary] = ProfileClass.build_level_rows("heist", null, null)
	_assert(empty_rows.size() == 5, "build_level_rows('heist', null, null) devuelve 5 niveles reales")
	var empty_completed: int = 0
	for r: Dictionary in empty_rows:
		if bool(r.get("completed", false)):
			empty_completed += 1
	_assert(empty_completed == 0, "build_level_rows sobre slot vacío devuelve 0 completados")

	var stats_cfg := ConfigFile.new()
	stats_cfg.set_value("stats", "total_wins", 4)
	stats_cfg.set_value("stats", "total_losses", 1)
	stats_cfg.set_value("stats", "best_streak", 3)
	stats_cfg.set_value("levels", "heist_n1_wins", 2)
	stats_cfg.set_value("levels", "heist_n1_losses", 1)
	stats_cfg.save(SlotManagerClass.get_stats_path(TEST_SLOT_B))

	var real_rows: Array[Dictionary] = ProfileClass.build_level_rows("heist", prog_cfg, stats_cfg)
	_assert(str(real_rows[0].get("level_id", "")) == "heist_n1", "Primera fila de heist es heist_n1")
	_assert(int(real_rows[0].get("stars", 0)) == 3 and bool(real_rows[0].get("completed", false)), "heist_n1 refleja 3 estrellas reales")
	_assert(int(real_rows[0].get("attempts", 0)) == 3, "heist_n1 refleja 3 intentos reales desde stats.cfg")
	_assert(int(real_rows[2].get("stars", -1)) == 0 and not bool(real_rows[2].get("completed", true)), "heist_n3 no completado refleja 0 estrellas")

	# 6. Profile instance loads real stats from active slot (no hardcoded 20 wins / 83.3%)
	var profile_node := ProfileClass.new()
	add_child(profile_node)
	_assert(int(profile_node.stats.get("total_wins", -1)) == 4, "Profile carga total_wins real (4) desde SlotManager/VaultStore")
	_assert(int(profile_node.stats.get("total_losses", -1)) == 1, "Profile carga total_losses real (1)")
	_assert(absf(float(profile_node.stats.get("win_rate", 0.0)) - 80.0) < 0.01, "Profile calcula win_rate real (80.0%)")
	_assert(int(profile_node.stats.get("total_stars", -1)) == 5, "Profile carga total_stars real (5)")
	profile_node.queue_free()

	# Cleanup & restore original slots
	if FileAccess.file_exists(tmp_bak_path):
		DirAccess.remove_absolute(tmp_bak_path)
	_restore_files(TEST_SLOT_A, backup_a)
	_restore_files(TEST_SLOT_B, backup_b)
	SlotManagerClass.set_active_slot(orig_slot)

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)
