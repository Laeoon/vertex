class_name VaultStore
extends RefCounted

## VaultStore
## Typed per-slot persistence facade for LA BÓVEDA (profile.cfg, stats.cfg, vault.cfg).
## Delegates all file paths exclusively to SlotManager static methods.

const SlotManagerClass = preload("res://juego/system/slot_manager.gd")
const VaultModulesClass = preload("res://juego/ui/vault_modules.gd")

const DEFAULT_PLAYER_NAME: String = "Jugador"
const DEFAULT_FEATURED_BADGE: String = "ENLACE INICIAL"
const DEFAULT_PINNED_MENU_TRACK: String = "Pink Bloom"
const DEFAULT_PINNED_GAME_TRACK: String = "Neon Subroutines"


static func _ensure_slot_dir(slot_id: int) -> void:
	var sid: int = SlotManagerClass.get_active_slot() if slot_id <= 0 else slot_id
	var dir_path: String = SlotManagerClass.get_slot_dir(sid)
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)


static func load_profile(slot_id: int = -1) -> Dictionary:
	var result: Dictionary = {
		"player_name": DEFAULT_PLAYER_NAME,
		"featured_badge": DEFAULT_FEATURED_BADGE,
	}
	var cfg := ConfigFile.new()
	var path: String = SlotManagerClass.get_profile_path(slot_id)
	if cfg.load(path) == OK:
		result["player_name"] = str(cfg.get_value("profile", "player_name", DEFAULT_PLAYER_NAME))
		result["featured_badge"] = str(cfg.get_value("profile", "featured_badge", DEFAULT_FEATURED_BADGE))
	return result


static func save_profile(player_name: String, featured_badge: String, slot_id: int = -1) -> Error:
	_ensure_slot_dir(slot_id)
	var path: String = SlotManagerClass.get_profile_path(slot_id)
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("profile", "player_name", player_name)
	cfg.set_value("profile", "featured_badge", featured_badge)
	var err: Error = cfg.save(path)
	if err == OK:
		SlotManagerClass.invalidate_cache()
	return err


static func load_stats_cfg(slot_id: int = -1) -> ConfigFile:
	var cfg := ConfigFile.new()
	var path: String = SlotManagerClass.get_stats_path(slot_id)
	if FileAccess.file_exists(path):
		cfg.load(path)
	return cfg


static func load_stats_summary(slot_id: int = -1) -> Dictionary:
	var cfg: ConfigFile = load_stats_cfg(slot_id)
	var total_wins: int = int(cfg.get_value("stats", "total_wins", 0))
	var total_losses: int = int(cfg.get_value("stats", "total_losses", 0))
	var stored_attempts: int = int(cfg.get_value("stats", "total_attempts", 0))
	var total_attempts: int = maxi(stored_attempts, total_wins + total_losses)
	var best_streak: int = int(cfg.get_value("stats", "best_streak", 0))
	var play_time_seconds: int = int(
		cfg.get_value("stats", "play_time_seconds", cfg.get_value("stats", "play_time", 0))
	)
	var decided: int = total_wins + total_losses
	var win_rate: float = (float(total_wins) / float(decided)) * 100.0 if decided > 0 else 0.0
	return {
		"play_time_seconds": play_time_seconds,
		"best_streak": best_streak,
		"total_attempts": total_attempts,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"win_rate": win_rate,
	}


static func resolve_decrypted_enc_files(enc_unlocked: Dictionary) -> Array[String]:
	var files: Array[String] = []
	for key in enc_unlocked.keys():
		if not bool(enc_unlocked.get(key, false)):
			continue
		var idx: int = int(key)
		if idx >= 0 and idx < VaultModulesClass.ENC_FILES.size():
			var fname: String = str(VaultModulesClass.ENC_FILES[idx].get("file", ""))
			if not fname.is_empty() and not files.has(fname):
				files.append(fname)
	return files


static func load_vault(slot_id: int = -1) -> Dictionary:
	var enc_unlocked: Dictionary = {}
	var pinned_menu: String = DEFAULT_PINNED_MENU_TRACK
	var pinned_game: String = DEFAULT_PINNED_GAME_TRACK

	var cfg := ConfigFile.new()
	var path: String = SlotManagerClass.get_vault_path(slot_id)
	if cfg.load(path) == OK:
		var raw_indices: Variant = cfg.get_value("termlink", "unlocked_indices", [])
		if raw_indices is Array or raw_indices is PackedInt32Array or raw_indices is PackedInt64Array:
			for raw_idx in raw_indices:
				var idx: int = int(raw_idx)
				if idx >= 0 and idx < VaultModulesClass.ENC_FILES.size():
					enc_unlocked[idx] = true
		pinned_menu = str(cfg.get_value("musicbox", "pinned_menu_track", DEFAULT_PINNED_MENU_TRACK))
		pinned_game = str(cfg.get_value("musicbox", "pinned_game_track", DEFAULT_PINNED_GAME_TRACK))

	return {
		"enc_unlocked": enc_unlocked,
		"decrypted_enc_files": resolve_decrypted_enc_files(enc_unlocked),
		"pinned_menu_track": pinned_menu,
		"pinned_game_track": pinned_game,
	}


static func save_vault(
	enc_unlocked: Dictionary,
	pinned_menu_track: String = DEFAULT_PINNED_MENU_TRACK,
	pinned_game_track: String = DEFAULT_PINNED_GAME_TRACK,
	slot_id: int = -1
) -> Error:
	_ensure_slot_dir(slot_id)
	var path: String = SlotManagerClass.get_vault_path(slot_id)
	var cfg := ConfigFile.new()
	cfg.load(path)

	var unlocked_indices: Array[int] = []
	for key in enc_unlocked.keys():
		if bool(enc_unlocked.get(key, false)):
			var idx: int = int(key)
			if idx >= 0 and idx < VaultModulesClass.ENC_FILES.size() and not unlocked_indices.has(idx):
				unlocked_indices.append(idx)
	unlocked_indices.sort()

	var decrypted_files: PackedStringArray = PackedStringArray(resolve_decrypted_enc_files(enc_unlocked))
	cfg.set_value("termlink", "unlocked_indices", unlocked_indices)
	cfg.set_value("termlink", "decrypted_enc_files", decrypted_files)
	cfg.set_value("musicbox", "pinned_menu_track", pinned_menu_track)
	cfg.set_value("musicbox", "pinned_game_track", pinned_game_track)

	var err: Error = cfg.save(path)
	if err == OK:
		SlotManagerClass.invalidate_cache()
	return err
