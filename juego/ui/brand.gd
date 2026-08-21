class_name Brand extends RefCounted

## Tokens de identidad visual — paleta "Neón Ciberpunk" (Capa 0, 2026-08-21).
## Única fuente de verdad de color y tipografía: los renderers consumen estos
## tokens en vez de literales sueltos. Mapa semántico:
##   jugador/ruta/selección=ACCENT · enemigo/perseguidor=ENEMY ·
##   victoria=SUCCESS · advertencia/detección=WARNING · derrota/peligro=DANGER

const BG := Color("0d0e16")             # fondo profundo azul-violeta
const PANEL := Color("161826", 0.88)    # placa semitransparente para texto
const PANEL_SOLID := Color("10121f", 0.95)
const PANEL_BORDER := Color("2a2e4a")

const ACCENT := Color("00e5ff")         # cian eléctrico
const ENEMY := Color("ff2e88")          # magenta
const SUCCESS := Color("39ff88")
const WARNING := Color("ffc857")
const DANGER := Color("ff4757")

const TEXT := Color("eaecf5")
const TEXT_DIM := Color("8a90b8")

## Versión tenue del acento (bordes/subrayados discretos).
static func accent_dim(alpha: float = 0.35) -> Color:
	return Color(ACCENT.r, ACCENT.g, ACCENT.b, alpha)


## Copia de un token con otro alpha (para fades y fondos tenues).
static func with_alpha(c: Color, alpha: float) -> Color:
	return Color(c.r, c.g, c.b, alpha)


const FONT_REGULAR_PATH := "res://juego/ui/fonts/JetBrainsMono-Regular.ttf"
const FONT_BOLD_PATH := "res://juego/ui/fonts/JetBrainsMono-Bold.ttf"

static var _regular: Font
static var _bold: Font


static func font_regular() -> Font:
	if _regular == null:
		_regular = _load_font_file(FONT_REGULAR_PATH)
	return _regular


static func font_bold() -> Font:
	if _bold == null:
		_bold = _load_font_file(FONT_BOLD_PATH)
	return _bold


## Carga la TTF sin depender del pipeline de import del editor (en headless
## puro load("*.ttf") da null si nadie abrió el editor): FontFile lee el
## archivo directo. Fallback: fuente del sistema de temas de Godot.
static func _load_font_file(path: String) -> Font:
	var f := FontFile.new()
	if f.load_dynamic_font(path) == OK:
		return f
	push_warning("Brand: no se pudo cargar %s — uso fallback_font" % path)
	return ThemeDB.fallback_font
