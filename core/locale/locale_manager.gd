extends Node

signal locale_changed(locale: String)

var _translations: Dictionary = {}
var _current_locale: String = "es"
var _available_locales: Array[String] = ["es", "en", "pt"]
var _fallback: Dictionary = {}


func _ready() -> void:
	add_to_group("locale_manager")
	_fallback = _load_file("res://core/locale/es.json")
	_apply_locale(_current_locale)


func set_locale(locale: String) -> void:
	if locale in _available_locales:
		_apply_locale(locale)
		locale_changed.emit(locale)


func get_locale() -> String:
	return _current_locale


func get_available() -> Array[String]:
	return _available_locales


func loc(key: String) -> String:
	if _translations.has(key):
		return _translations[key]
	if _fallback.has(key):
		return _fallback[key]
	return key


func cycle_locale() -> void:
	var idx: int = _available_locales.find(_current_locale)
	idx = (idx + 1) % _available_locales.size()
	set_locale(_available_locales[idx])


func _apply_locale(locale: String) -> void:
	_current_locale = locale
	_translations = _load_file("res://core/locale/%s.json" % locale)
	print("Locale: ", locale)


func _load_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Locale: no se pudo cargar %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}
