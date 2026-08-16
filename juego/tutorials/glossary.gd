class_name Glossary
extends RefCounted

## Glosario del tutorial — etapa 5 (P1) de la descomposición de
## tutorial_player.gd.
##
## Aporta la carga de glossary.json, el toggle [G] y el scroll del overlay.
## A diferencia de tutorial_logic (que deja el estado en el player porque
## juego/renderer/tests lo leen de ahí), el estado del glosario vive en este
## módulo: nada externo lo consumía. El dibujado (_draw_glossary_overlay)
## permanece en tutorial_player.gd y consulta este módulo por datos
## (título, términos, scroll).
##
## Equivalencia congelada por
## tests/tutorials/_test_glossary_equivalence.{gd,tscn}.

# Geometría a nivel datos del overlay (espeja _draw_glossary_overlay en
# tutorial_player.gd): 1 línea por término, sin wrap de fuente.
const OVERLAY_MAX_H := 420.0
const OVERLAY_MARGIN_V := 40.0
const TERMS_TOP := 50.0
const CLIP_TOP := 42.0
const CLIP_BOTTOM_PAD := 30.0
const TERM_LINE_H := 22.0
const TERM_GAP := 4.0
const SCROLL_STEP := 40.0
const TERM_SCROLL_H := 40.0

var _p: Control

# Estado porte de tutorial_player.gd
var _show_glossary: bool = false
var _glossary_data: Dictionary = {}
var _glossary_scroll: float = 0.0


func setup(player: Control) -> void:
	_p = player


## Puerto del viejo tutorial_player._load_glossary().
func _load_glossary() -> void:
	var file: FileAccess = FileAccess.open("res://juego/tutorials/glossary.json", FileAccess.READ)
	if file == null:
		push_warning("TutorialPlayer: no se pudo cargar glossary.json")
		return
	var json_text: String = file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed != null and parsed is Dictionary:
		_glossary_data = parsed
		GameLogger.info("TutorialPlayer", "Glosario cargado: %d términos" % parsed.get("terms", {}).size())


## Puerto del viejo tutorial_player.toggle_glossary().
func toggle_glossary() -> void:
	_show_glossary = not _show_glossary
	_glossary_scroll = 0.0
	if _show_glossary:
		GameLogger.info("TutorialPlayer", "Glosario abierto")


func is_open() -> bool:
	return _show_glossary


func get_title() -> String:
	return _glossary_data.get("title", "Glosario")


func get_terms() -> Dictionary:
	return _glossary_data.get("terms", {})


func get_scroll() -> float:
	return _glossary_scroll


## Datos que consume _draw_glossary_overlay (P5: los empaqueta el módulo).
func draw_pack() -> Dictionary:
	return {
		"title": get_title(),
		"terms": get_terms(),
		"sorted_keys": get_sorted_keys(),
		"scroll": _glossary_scroll,
	}


## Keys de términos ordenadas, como las consume _draw_glossary_overlay.
func get_sorted_keys() -> Array:
	var sorted_keys: Array = []
	for k in get_terms().keys():
		sorted_keys.append(k)
	sorted_keys.sort()
	return sorted_keys


## Puerto del bloque de scroll de tutorial_player._process() (input con
## ui_up/ui_down y clamp contra el máximo según el alto del viewport).
func process_scroll(vp_height: float) -> void:
	var terms_count: int = _glossary_data.get("terms", {}).size()
	if terms_count > 0:
		var max_scroll: float = max(0.0, float(terms_count) * TERM_SCROLL_H - vp_height * 0.6)
		if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_page_down"):
			_glossary_scroll += SCROLL_STEP
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_page_up"):
			_glossary_scroll -= SCROLL_STEP
		_glossary_scroll = clamp(_glossary_scroll, 0.0, max_scroll)


## Scroll determinista con clamp (vía datos, para tests y navegación
## programática). Misma aritmética que process_scroll sin leer Input.
func scroll_by(delta: float, vp_height: float) -> void:
	_glossary_scroll = clamp(_glossary_scroll + delta, 0.0, max_scroll(vp_height))


func max_scroll(vp_height: float) -> float:
	var terms_count: int = _glossary_data.get("terms", {}).size()
	return max(0.0, float(terms_count) * TERM_SCROLL_H - vp_height * 0.6)


## Índices de términos visibles con el scroll actual, según la geometría del
## overlay (vista a nivel datos del clip de _draw_glossary_overlay).
func visible_indices(vp_height: float) -> Array:
	var overlay_h: float = min(OVERLAY_MAX_H, vp_height - OVERLAY_MARGIN_V)
	var clip_top: float = CLIP_TOP
	var clip_bottom: float = overlay_h - CLIP_BOTTOM_PAD
	var total: int = get_sorted_keys().size()
	var out: Array = []
	for i in range(total):
		var term_y: float = TERMS_TOP + i * (TERM_LINE_H + TERM_GAP) - _glossary_scroll
		if term_y + TERM_LINE_H > clip_top and term_y < clip_bottom:
			out.append(i)
	return out
