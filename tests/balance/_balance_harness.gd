extends Node

## Harness de self-play para balance (slice 5) — JUEGA niveles headless y
## reporta win-rate/turnos/coste/estrellas por nivel y política.
##
## Políticas:
##   - greedy: sigue la ruta recomendada (current_path de mostrar_ruta) —
##     proxy de jugador guiado por el juego.
##   - greedy_err: como greedy pero toma UN paso equivocado al inicio (move #2)
##     y sigue guiado — proxy de jugador nuevo con pistas que se equivoca una
##     vez (modela "N gana en 2-3 intentos": ~50% en greedy_err ≈ 2 intentos).
##   - random: vecino aleatorio válido — proxy de jugador nuevo perdido.
##
## Determinismo: seed(semilla + nro_corrida) por partida (la IA bloqueadora es
## determinista; la detección usa randf). Los números son comparables entre
## corridas del harness y ediciones de JSON si no cambia la semilla.
##
## PROTECCIÓN DE DATOS: las partidas ganadas escriben user://progress.cfg y
## stats.cfg vía ProgressService.save/record_loss — el harness respalda ambos
## archivos al iniciar y los restaura al final (el progreso real no se toca).
##
## Invocación:
##     godot --headless res://tests/balance/_balance_harness.tscn -- 50
## (argumento opcional tras --: corridas por política, default 100)

const RUNS_DEFAULT := 100
const SEED_BASE := 42
const MAX_MOVES := 400  # corte de seguridad por partida

const LevelRegistryClass = preload("res://juego/system/level_registry.gd")
const LevelManagerClass = preload("res://juego/system/level_manager.gd")

var _stats := {}  # "level_id/politica" -> acumuladores


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var runs: int = RUNS_DEFAULT
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			runs = int(a)
	_back_up_user_files()

	var levels := [
		"res://juego/heist/heist_n1.json",
		"res://juego/heist/heist_n2.json",
		"res://juego/heist/heist_n3.json",
	]
	for path in levels:
		var data: Dictionary = LevelRegistryClass.load_level_data(path)
		if data.is_empty():
			print("ERROR: no se pudo cargar %s" % path)
			continue
		for politica in ["greedy", "greedy_err", "random"]:
			for i in runs:
				await _jugar(path, data, politica, SEED_BASE + i)

	_report(runs)
	_restore_user_files()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0)


## Una partida completa: bootea el nivel con la política dada y acumula métricas.
func _jugar(path: String, data: Dictionary, politica: String, run_seed: int) -> void:
	seed(run_seed)
	SceneParams.reset()
	LevelManagerClass._apply_to_scene_params(data)
	SceneParams.level_key = data.get("id", "")

	var juego = load("res://juego/ataque/escena_juego.tscn").instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if juego.graph == null:
		print("ERROR: graph no cargo (%s)" % path)
		juego.queue_free()
		return

	var moves: int = 0
	var err_ya: bool = false
	while not juego.game_over and moves < MAX_MOVES:
		var dest: StringName = _elegir(juego, politica, moves, err_ya)
		if politica == "greedy_err" and dest != &"" and juego.current_path.size() >= 2 \
				and dest != juego.current_path[1] and moves < 3:
			err_ya = true
		if dest == &"":
			break  # sin vecinos accesibles (el juego degrada a derrota)
		juego._mover_jugador(dest)
		moves += 1

	var key: String = "%s/%s" % [data.get("id", "?"), politica]
	if not _stats.has(key):
		_stats[key] = {
			"total": 0, "wins": 0, "sum_turns": 0.0, "sum_cost": 0.0,
			"sum_stars": 0.0, "sum_budget": 0.0, "loss_reasons": {},
		}
	var s: Dictionary = _stats[key]
	s.total += 1
	if juego.game_won:
		s.wins += 1
		s.sum_turns += juego.turn
		s.sum_cost += juego.player_total_cost
		s.sum_stars += juego._progress_service.calculate_stars()
		s.sum_budget += juego.movement_points
	else:
		# motivo de derrota: el mensaje "PERDISTE: <razón>" se normaliza a una
		# categoría (presupuesto / salida / turnos / capturado / ia_ruta)
		var motivo: String = str(juego.mensaje_estado).to_lower()
		var tag: String = "?"
		if motivo.contains("presupuesto"):
			tag = "presupuesto"
		elif motivo.contains("debes pasar por"):
			tag = "wp_pendiente"
		elif motivo.contains("salida"):
			tag = "sin_salida"
		elif motivo.contains("turnos maximo"):
			tag = "max_turnos"
		elif motivo.contains("capturado"):
			tag = "capturado"
		elif motivo.contains("ia bloqueo"):
			tag = "ia_sello"
		s.loss_reasons[tag] = int(s.loss_reasons.get(tag, 0)) + 1
	juego.queue_free()
	await get_tree().process_frame


## Política de movimiento: greedy sigue current_path (ruta recomendada);
## greedy_err mete un paso equivocado en el PRIMER movimiento con elección
## real (≥2 vecinos, dentro de los primeros 3 movimientos) y luego sigue
## guiado; random elige vecino aleatorio.
func _elegir(juego, politica: String, move_n: int, err_ya: bool) -> StringName:
	var vecinos: Array = juego._vecinos_jugador()
	if vecinos.is_empty():
		return &""
	if politica == "greedy_err" and not err_ya and move_n < 3 and vecinos.size() >= 2:
		# paso equivocado: un vecino que NO sea el siguiente de la ruta
		var malos: Array = vecinos.duplicate()
		if juego.current_path.size() >= 2:
			malos.erase(juego.current_path[1])
		if malos.size() > 0:
			return malos[randi() % malos.size()]
	if politica == "greedy" or politica == "greedy_err":
		if juego.current_path.size() >= 2 and juego.current_path[1] in vecinos:
			return juego.current_path[1]
		return vecinos[0]
	return vecinos[randi() % vecinos.size()]


func _report(runs: int) -> void:
	print("════════ SELF-PLAY HEIST (runs=%d/política, seed base %d) ════════" % [runs, SEED_BASE])
	print("%-12s %-10s %7s %8s %8s %7s %9s  %s" % ["nivel", "política", "win%", "turnos", "coste", "estrel", "budget√", "derrotas"])
	var ids := _stats.keys()
	ids.sort()
	for key in ids:
		var s: Dictionary = _stats[key]
		var win_rate: float = 100.0 * s.wins / s.total
		var avg_turns: float = s.sum_turns / s.wins if s.wins > 0 else 0.0
		var avg_cost: float = s.sum_cost / s.wins if s.wins > 0 else 0.0
		var avg_stars: float = s.sum_stars / s.wins if s.wins > 0 else 0.0
		var avg_budget: float = s.sum_budget / s.wins if s.wins > 0 else 0.0
		var motivos: String = ""
		for m in s.loss_reasons:
			motivos += "%s×%d " % [m, s.loss_reasons[m]]
		print("%-12s %-10s %6.1f%% %8.1f %8.1f %7.1f %9.1f  %s" % [
			key.split("/")[0], key.split("/")[1], win_rate, avg_turns, avg_cost, avg_stars, avg_budget, motivos])


# ── Backup/restore de user:// (el self-play no debe pisar progreso real) ──

func _back_up_user_files() -> void:
	for f in ["progress.cfg", "stats.cfg"]:
		var src := FileAccess.open("user://%s" % f, FileAccess.READ)
		if src == null:
			continue
		var contenido := src.get_as_text()
		src.close()
		var dst := FileAccess.open("user://%s.harness_bak" % f, FileAccess.WRITE)
		if dst:
			dst.store_string(contenido)
			dst.close()


func _restore_user_files() -> void:
	for f in ["progress.cfg", "stats.cfg"]:
		var bak := FileAccess.open("user://%s.harness_bak" % f, FileAccess.READ)
		if bak == null:
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://%s" % f))
			continue
		var contenido := bak.get_as_text()
		bak.close()
		var dst := FileAccess.open("user://%s" % f, FileAccess.WRITE)
		if dst:
			dst.store_string(contenido)
			dst.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://%s.harness_bak" % f))
