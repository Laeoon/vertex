extends Node

## SettingsManager
## Single source of truth for user://settings.cfg defaults, persistence, and hot-apply notifications.
## Registered as an autoload in project.godot before AudioManager.

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_OPTIONS: String = "options"
const SECTION_LOCALE: String = "locale"
const LANG_CODES: Array[String] = ["es", "en", "pt"]

const DEFAULTS: Dictionary = {
	"volume_master": 80,
	"volume_music": 80,
	"volume_sfx": 80,
	"fullscreen": true,
	"vsync": true,
	"show_hints": true,
	"lang": 0,
	"input_scheme": 0,
}

var _values: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	load_settings()


func load_settings(path: String = SETTINGS_PATH) -> void:
	_values = DEFAULTS.duplicate(true)
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		for key: String in DEFAULTS.keys():
			if cfg.has_section_key(SECTION_OPTIONS, key):
				var default_val: Variant = DEFAULTS[key]
				var saved_val: Variant = cfg.get_value(SECTION_OPTIONS, key, default_val)
				if typeof(saved_val) == typeof(default_val):
					_values[key] = _sanitize(key, saved_val)
	_loaded = true


func save_settings(path: String = SETTINGS_PATH) -> Error:
	if not _loaded:
		load_settings(path)
	var cfg := ConfigFile.new()
	cfg.load(path)
	for key: String in DEFAULTS.keys():
		var val: Variant = _values.get(key, DEFAULTS[key])
		cfg.set_value(SECTION_OPTIONS, key, val)
		if key == "lang" and val is int:
			var lang_idx: int = clampi(int(val), 0, LANG_CODES.size() - 1)
			cfg.set_value(SECTION_LOCALE, "lang", LANG_CODES[lang_idx])
	return cfg.save(path)


func get_setting(key: String, default_override: Variant = null) -> Variant:
	if not _loaded:
		load_settings()
	if _values.has(key):
		return _values[key]
	if DEFAULTS.has(key):
		return DEFAULTS[key]
	return default_override


func set_setting(key: String, value: Variant, auto_save: bool = true, path: String = SETTINGS_PATH) -> void:
	if not _loaded:
		load_settings(path)
	var sanitized: Variant = _sanitize(key, value)
	_values[key] = sanitized
	if auto_save:
		save_settings(path)
	if is_inside_tree():
		var ev: Node = get_node_or_null("/root/Events")
		if ev != null and ev.has_signal("settings_changed"):
			ev.emit_signal("settings_changed", &"options", StringName(key), sanitized)


func get_locale_code() -> String:
	var idx: int = clampi(int(get_setting("lang", 0)), 0, LANG_CODES.size() - 1)
	return LANG_CODES[idx]


func reset_to_defaults(auto_save: bool = false, path: String = SETTINGS_PATH) -> void:
	_values = DEFAULTS.duplicate(true)
	_loaded = true
	if auto_save:
		save_settings(path)


static func _sanitize(key: String, value: Variant) -> Variant:
	match key:
		"volume_master", "volume_music", "volume_sfx":
			return clampi(int(value), 0, 100)
		"lang":
			return clampi(int(value), 0, LANG_CODES.size() - 1)
		"input_scheme":
			return clampi(int(value), 0, 2)
		"fullscreen", "vsync", "show_hints":
			return bool(value)
	return value


static func read_setting_from_disk(key: String, path: String = SETTINGS_PATH) -> Variant:
	var default_val: Variant = DEFAULTS.get(key, null)
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK and cfg.has_section_key(SECTION_OPTIONS, key):
		var saved_val: Variant = cfg.get_value(SECTION_OPTIONS, key, default_val)
		if default_val == null or typeof(saved_val) == typeof(default_val):
			return _sanitize(key, saved_val)
	return default_val


static func write_setting_to_disk(key: String, value: Variant, path: String = SETTINGS_PATH) -> Error:
	var sanitized: Variant = _sanitize(key, value)
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value(SECTION_OPTIONS, key, sanitized)
	if key == "lang" and sanitized is int:
		var lang_idx: int = clampi(int(sanitized), 0, LANG_CODES.size() - 1)
		cfg.set_value(SECTION_LOCALE, "lang", LANG_CODES[lang_idx])
	return cfg.save(path)
