class_name OperatorAdvisor extends RefCounted

## OperatorAdvisor
## Contextual tactical advisor ("guia en off") providing onboarding hints,
## system descriptions, profile creation prompts, and security lock telemetries.

const BrandClass = preload("res://juego/ui/brand.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")

var _player_name: String = "Jugador"
var _show_hints: bool = true
var _alert_message: String = ""
var _alert_timer: float = 0.0
var _pulse: float = 0.0


func _init() -> void:
	reload_settings_and_profile()


func reload_settings_and_profile() -> void:
	# Load hints toggle from settings
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		_show_hints = cfg.get_value("controls", "show_hints", true)
	else:
		_show_hints = true

	# Load profile player name
	var pcfg := ConfigFile.new()
	if pcfg.load("user://profile.cfg") == OK:
		_player_name = pcfg.get_value("profile", "player_name", "Jugador")
	else:
		_player_name = "Jugador"


func notify_locked(reason: String) -> void:
	_alert_message = "[ACCESO DENEGADO] %s" % (reason if reason != "" else "COMPLETA LOS TUTORIALES REQUERIDOS")
	_alert_timer = 3.5


func update(delta: float) -> void:
	_pulse += delta * 2.5
	if _alert_timer > 0.0:
		_alert_timer = maxf(0.0, _alert_timer - delta)


func get_guidance_text(is_world_select: bool, selected_item: Dictionary, progress: Dictionary) -> String:
	if not _show_hints:
		return ""

	if _alert_timer > 0.0 and _alert_message != "":
		return _alert_message

	if not is_world_select:
		# Main Menu Context
		var act: String = selected_item.get("action", "")
		if _player_name == "Jugador" or _player_name.strip_edges() == "":
			if act == "profile":
				return "[OPERADOR] Identidad sin registrar. Pulsa [ENTER] para configurar tu alias de red."
			else:
				return "[OPERADOR::AVISO] Identidad no configurada. Accede a PERFIL para registrar tu alias."

		match act:
			"play":
				return "[OPERADOR] Accede a las simulaciones de red e infraestructuras operativas."
			"options":
				return "[OPERADOR] Calibra niveles de audio, visualizacion y esquemas de control."
			"profile":
				return "[OPERADOR] Revisa telemetria de juego, historial de misiones y condecoraciones."
			"database":
				return "[OPERADOR] Consulta el archivo tactico y estado de misiones completadas."
			"exit":
				return "[OPERADOR] Terminar enlace y cerrar sesion de forma segura."
			_:
				return "[OPERADOR] Selecciona un subsistema para interactuar."
	else:
		# World Select Context
		var wid: String = selected_item.get("id", "")
		if wid == "tutorials":
			return "[OPERADOR] Simulaciones basicas. Completa estos modulos para desbloquear los sectores operativos."

		if not ProgressUtilClass.is_world_unlocked(wid, progress):
			var reason: String = ProgressUtilClass.get_world_lock_reason(wid, progress)
			if reason != "":
				return "[OPERADOR::BLOQUEADO] Acceso restringido. %s." % reason
			return "[OPERADOR::BLOQUEADO] Acceso restringido por protocolos de seguridad."

		match wid:
			"heist":
				return "[OPERADOR] Sector Heist: Infiltracion fisica, sensores de perimetro y gestion de presupuesto."
			"hacker":
				return "[OPERADOR] Sector Hacker: Operaciones ofensivas, scripting de exploits y persistencia."
			"cybersecurity":
				return "[OPERADOR] Sector Cybersecurity: Analisis de red, topologias complejas y contramedidas."
			_:
				return "[OPERADOR] Sector activo y disponible para brecha."


func draw(canvas: CanvasItem, vp: Vector2, alpha: float, font: Font, font_size: int, is_world_select: bool, selected_item: Dictionary, progress: Dictionary) -> void:
	var text := get_guidance_text(is_world_select, selected_item, progress)
	if text == "":
		return

	var is_alert := _alert_timer > 0.0
	var bar_w := clampf(vp.x - 80.0, 480.0, 960.0)
	var bar_h := 30.0
	var bar_x := (vp.x - bar_w) * 0.5
	var bar_y := vp.y - (52.0 if is_world_select else 98.0)
	var bar_rect := Rect2(bar_x, bar_y, bar_w, bar_h)

	var theme_col: Color
	if is_alert:
		theme_col = BrandClass.ENEMY
	elif text.begins_with("[OPERADOR::AVISO]") or text.begins_with("[OPERADOR::BLOQUEADO]"):
		theme_col = BrandClass.WARNING
	else:
		theme_col = BrandClass.ACCENT

	var bg_col := BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.90)
	var border_col := BrandClass.with_alpha(theme_col, alpha * (0.80 if is_alert else 0.45))

	canvas.draw_rect(bar_rect, bg_col)
	canvas.draw_rect(bar_rect, border_col, false, 1.2)

	# Left indicator icon / pip
	var pip_pos := Vector2(bar_x + 12.0, bar_y + bar_h * 0.5)
	var pip_pulse := 0.7 + sin(_pulse) * 0.3
	canvas.draw_circle(pip_pos, 3.5, BrandClass.with_alpha(theme_col, alpha * pip_pulse))

	# Message text
	var text_pos := Vector2(bar_x + 24.0, bar_y + 20.0)
	var text_col := BrandClass.with_alpha(BrandClass.TEXT if not is_alert else BrandClass.ENEMY, alpha * (0.95 if is_alert else 0.88))
	canvas.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, bar_w - 32.0, font_size - 2, text_col)
