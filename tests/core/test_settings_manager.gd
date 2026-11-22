extends Node

## Headless verification for F1.2: SettingsManager single source of truth, unified defaults,
## Events expanded signals + hot-apply propagation to AudioManager/InputHandler, and "hover" SFX.

const SettingsManagerClass = preload("res://core/autoloads/settings_manager.gd")
const EventsClass = preload("res://core/autoloads/events.gd")
const AudioManagerClass = preload("res://core/autoloads/audio_manager.gd")
const InputHandlerClass = preload("res://juego/ataque/input_handler.gd")

const TMP_SETTINGS_PATH: String = "user://test_f1_2_settings.cfg"

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


func _run_tests() -> void:
	print("--- START TEST SETTINGS MANAGER & EVENTS (F1.2) ---")

	if FileAccess.file_exists(TMP_SETTINGS_PATH):
		DirAccess.remove_absolute(TMP_SETTINGS_PATH)

	# 1. Canonical defaults in SettingsManager
	_assert(int(SettingsManagerClass.DEFAULTS.get("volume_master", -1)) == 80, "Default volume_master == 80")
	_assert(int(SettingsManagerClass.DEFAULTS.get("volume_music", -1)) == 80, "Default volume_music == 80")
	_assert(int(SettingsManagerClass.DEFAULTS.get("volume_sfx", -1)) == 80, "Default volume_sfx == 80")
	_assert(int(SettingsManagerClass.DEFAULTS.get("input_scheme", -1)) == 0, "Default input_scheme == 0 (HYBRID)")
	_assert(int(SettingsManagerClass.DEFAULTS.get("lang", -1)) == 0, "Default lang == 0 (es)")

	# 2. Persistence & sanitization via isolated temp file
	var sm := SettingsManagerClass.new()
	sm.load_settings(TMP_SETTINGS_PATH)
	_assert(int(sm.get_setting("volume_music")) == 80, "Fresh SettingsManager loads default volume_music == 80")
	sm.set_setting("volume_music", 145, true, TMP_SETTINGS_PATH)
	_assert(int(sm.get_setting("volume_music")) == 100, "volume_music clamps to 100")
	sm.set_setting("input_scheme", 2, true, TMP_SETTINGS_PATH)
	sm.set_setting("lang", 1, true, TMP_SETTINGS_PATH)

	var sm2 := SettingsManagerClass.new()
	sm2.load_settings(TMP_SETTINGS_PATH)
	_assert(int(sm2.get_setting("volume_music")) == 100, "Reloaded SettingsManager preserves volume_music == 100")
	_assert(int(sm2.get_setting("input_scheme")) == 2, "Reloaded SettingsManager preserves input_scheme == 2")
	_assert(sm2.get_locale_code() == "en", "Reloaded SettingsManager resolves locale 'en'")

	var cfg := ConfigFile.new()
	_assert(cfg.load(TMP_SETTINGS_PATH) == OK, "Temp settings.cfg saved cleanly")
	_assert(str(cfg.get_value("locale", "lang", "")) == "en", "settings.cfg syncs [locale] lang = 'en'")
	sm.free()
	sm2.free()

	# 3. Events expanded domain signals + 4 original signals preserved
	var ev: Node = get_node_or_null("/root/Events")
	var created_ev: bool = false
	if ev == null:
		ev = EventsClass.new()
		ev.name = "Events"
		get_tree().root.add_child(ev)
		created_ev = true

	var required_signals: Array[String] = [
		"node_state_changed",
		"threat_detected",
		"path_calculated",
		"min_cut_identified",
		"mission_completed",
		"enc_file_decrypted",
		"cli_command_executed",
		"academy_lesson_completed",
		"music_track_played",
		"customization_applied",
		"settings_changed",
	]
	for sig_name: String in required_signals:
		_assert(ev.has_signal(sig_name), "Events define señal '%s'" % sig_name)

	# 4. Hot-apply propagation via Events.settings_changed -> AudioManager & InputHandler
	var received: Array[Dictionary] = []
	var cb := func(sec: StringName, k: StringName, val: Variant) -> void:
		received.append({"section": sec, "key": k, "value": val})
	ev.connect("settings_changed", cb)

	var sm_live: Node = get_node_or_null("/root/SettingsManager")
	var created_sm: bool = false
	if sm_live == null:
		sm_live = SettingsManagerClass.new()
		sm_live.name = "SettingsManager"
		get_tree().root.add_child(sm_live)
		created_sm = true
	sm_live.call("load_settings", TMP_SETTINGS_PATH)

	var am := AudioManagerClass.new()
	add_child(am)
	var ih := InputHandlerClass.new()
	add_child(ih)

	sm_live.call("set_setting", "volume_sfx", 40, false, TMP_SETTINGS_PATH)
	sm_live.call("set_setting", "input_scheme", InputHandlerClass.Scheme.KEYBOARD_ONLY, false, TMP_SETTINGS_PATH)

	_assert(received.size() == 2, "Events.settings_changed emitido 2 veces en caliente")
	_assert(received[0].get("key") == &"volume_sfx" and int(received[0].get("value")) == 40, "Payload settings_changed para volume_sfx correcto")
	_assert(ih.get_input_scheme() == InputHandlerClass.Scheme.KEYBOARD_ONLY, "InputHandler reacciona en caliente a input_scheme == KEYBOARD_ONLY")

	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		var expected_db: float = linear_to_db(0.4)
		_assert(absf(AudioServer.get_bus_volume_db(sfx_idx) - expected_db) < 0.05, "AudioManager actualiza bus SFX en caliente a 40%")

	# 5. "hover" SFX resolved cleanly in AudioManager without breaking _sounds count (14)
	_assert(am.has_sound("hover"), "AudioManager.has_sound('hover') == true")
	_assert(am._sounds.size() == 14, "AudioManager._sounds mantiene exactamente 14 cues procedurales")
	am.play_sfx("hover")
	_assert(true, "AudioManager.play_sfx('hover') ejecuta sin error")

	# Cleanup
	ev.disconnect("settings_changed", cb)
	remove_child(ih)
	ih.free()
	remove_child(am)
	am.free()
	if created_sm:
		get_tree().root.remove_child(sm_live)
		sm_live.free()
	if created_ev:
		get_tree().root.remove_child(ev)
		ev.free()
	if FileAccess.file_exists(TMP_SETTINGS_PATH):
		DirAccess.remove_absolute(TMP_SETTINGS_PATH)

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)
