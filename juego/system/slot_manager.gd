class_name SlotManager extends RefCounted

## SlotManager
## Manages multiple independent operator save slots (Slots 1, 2, 3) in `user://slots/slot_X/`.
## Transparently migrates legacy flat save files into slot 1 to ensure zero progress loss.

const TOTAL_SLOTS: int = 3
const SLOTS_META_PATH: String = "user://slots.cfg"
const SLOTS_BASE_DIR: String = "user://slots"

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


## Returns an array of dictionaries summarizing each of the 3 slots.
static func get_all_slots_summary() -> Array[Dictionary]:
	if not _initialized:
		init_slots()
	var list: Array[Dictionary] = []
	for sid in range(1, TOTAL_SLOTS + 1):
		list.append(get_slot_summary(sid))
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
