extends Node

## Test de stats visibles en perfil (mundo heist): ejercita la función PURA
## `Profile.build_level_rows()` con ConfigFiles inyectados EN MEMORIA — sin
## tocar el user:// real. Cubre: filas por nivel registrado, agregado de
## intentos (wins+losses), niveles sin datos (fila en cero → "—" en UI),
## mundo inexistente y primer arranque (cfgs null).
##
## Invocación:
##     godot --headless res://tests/system/_test_stats_perfil.tscn

const ProfileScript = preload("res://escenas/menu/profile.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# ── S1: lectura y agregado con datos ──
	var progress_cfg := ConfigFile.new()
	progress_cfg.set_value("estrellas", "heist_n1", 3)
	progress_cfg.set_value("estrellas", "heist_n1_mejor_coste", 9.0)
	progress_cfg.set_value("estrellas", "heist_n2", 2)
	progress_cfg.set_value("estrellas", "heist_n2_mejor_coste", 14.0)

	var stats_cfg := ConfigFile.new()
	stats_cfg.set_value("levels", "heist_n1_wins", 2)
	stats_cfg.set_value("levels", "heist_n1_losses", 1)
	stats_cfg.set_value("levels", "heist_n2_losses", 3)

	var rows: Array = ProfileScript.build_level_rows("heist", progress_cfg, stats_cfg)

	_af(rows.size() == 3, "heist registra 3 filas (una por nivel del WORLDS)")

	var r1: Dictionary = rows[0]
	_af(r1.key == "heist_n1" and r1.stars == 3 and r1.best_cost == 9.0,
		"heist_n1: 3★ / mejor coste 9.0")
	_af(r1.wins == 2 and r1.losses == 1 and r1.attempts == 3,
		"heist_n1: V2/D1 → intentos 3")

	var r2: Dictionary = rows[1]
	_af(r2.key == "heist_n2" and r2.stars == 2 and r2.wins == 0
		and r2.losses == 3 and r2.attempts == 3,
		"heist_n2: 2★, 0W/3L → intentos 3 (las derrotas cuentan)")

	var r3: Dictionary = rows[2]
	_af(r3.key == "heist_n3" and r3.stars == 0 and r3.best_cost == 0.0
		and r3.attempts == 0,
		"heist_n3 sin datos: fila en cero (la UI la dibuja con '—')")

	# ── S2: mundo no registrado → lista vacía sin error ──
	var empty: Array = ProfileScript.build_level_rows(
		"mundo_inexistente", progress_cfg, stats_cfg)
	_af(empty.is_empty(), "mundo no registrado → [] (no crashea)")

	# ── S3: primer arranque — cfgs null tolerados ──
	var fresh: Array = ProfileScript.build_level_rows("heist", null, null)
	_af(fresh.size() == 3 and fresh[0].stars == 0 and fresh[0].attempts == 0,
		"cfgs null → filas en cero (perfil recién instalado)")

	_fin()


func _af(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _fin() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
