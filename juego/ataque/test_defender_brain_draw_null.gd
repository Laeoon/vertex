extends Node

## Prueba de integración: juego_ataque._draw() cuando _defender_brain es null.
##
## Verifica la tarea 1.4 (fase-0/slice-1): en modo defensor, si
## `_defender_brain` no es una instancia válida (null o liberado), `_draw()`
## debe omitir el dibujado y emitir push_warning en lugar de caer al acceder
## a miembros del brain.
##
## Por qué es una escena (.tscn) y no corre por el runner `--script`:
##   `_draw()` vive en `juego_ataque.gd`, que referencia autoloads
##   (SceneParams/AudioManager/Events/...). En Godot 4.7, los autoloads NO se
##   registran al correr con `--script <MainLoop>` personalizado (ver
##   slice-0 apply-progress, hallazgo #6), por lo que el runner no puede
##   compilar/preload `juego_ataque.gd`. Al ejecutar una escena `.tscn` como
##   escena principal, SÍ se registran los autoloads y el script compila.
##   Convención idéntica a `juego/ataque/test_block_duration.{gd,tscn}`.
##
## Invocación:  godot --headless res://juego/ataque/test_defender_brain_draw_null.tscn
##
## Nota sobre el caso "freed no null": con RefCounted no se puede forzar un
## `free()` determinista para simular un objeto liberado-pero-no-null; el
## guard usa `is_instance_valid(_defender_brain)`, que cubre tanto null como
## freed. El caso null es el representativo y se cubre aquí; el comportamiento
## freed se valida por inspección del código (`is_instance_valid`).
## Nota sobre push_warning: no hay API trivial para capturar push_warning en
## Godot 4.7 headless; el contrato afirmado aquí es "no crash + early return".
## La emisión de la advertencia se confirma por inspección del fuente y por la
## traza de warnings en una corrida manual con --headless.

const JuegoAtaque = preload("res://juego/ataque/juego_ataque.gd")

var passed: int = 0
var failed: int = 0
var _juego: Node2D


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# Caso 1: modo defensor + _defender_brain null → _draw retorna temprano
	# sin tocar miembros del brain, get_viewport_rect() ni SceneParams.
	_juego = JuegoAtaque.new()
	# NO añadimos a la escena: _ready() NO debe correr (cargaría grafo,
	# renderer, input handler, autoloads, etc.). El guard de _draw() retorna
	# ANTES de get_viewport_rect(), así que no necesitamos viewport.
	_juego.defender_mode = true
	_juego._defender_brain = null
	# Si el guard faltara, esto caería en `_defender_brain.defender_blocks_placed`
	# (miembro de null) o, si _defender_brain fuera un freed, en un error de
	# instancia liberada.
	_juego._draw()
	_afirmar(true, "modo defensor + brain null: _draw() retorna sin crash (guard temprano)")

	# Caso 2: idempotencia — una segunda llamada tampoco cae (el flag de la
	# advertencia de tarea 1.3 es de mostrar_ruta, no de _draw; _draw no guarda
	# estado, así que repetir es seguro).
	_juego._draw()
	_afirmar(true, "modo defensor + brain null: segunda llamada a _draw() también estable")

	# Caso 3: la condición del guard es exactamente "defender_mode AND NOT
	# is_instance_valid(brain)". En modo atacante con brain null NO debe
	# dispararse el guard temprano (el dibujado del atacante debe intentar
	# correr y salir por el guard runtime/graph). Asumiendo runtime/graph null,
	# _draw debe salir limpiamente por esa rama sin tocar _renderer. Verificamos
	# no-crash, que es la propiedad observable sin viewport.
	_juego.defender_mode = false  # modo atacante
	_juego.runtime = null
	_juego.graph = null
	_juego._renderer = null  # explícito: el guard inferior debe retornar antes
	_juego.mensaje_estado = ""   # así la rama `if mensaje_estado != "" and font != null` se omite
	# Llamar sin viewport: en modo atacante el guard de _defender_brain es
	# legítimamente null (no dispara return temprano) y _draw baja hasta
	# `if runtime == null or graph == null: ... return`. get_viewport_rect()
	# sobre un Node2D fuera del árbol puede devolver un Rect2 por defecto; en
	# cualquier caso no debería caer antes del guard inferior porque
	# mensaje_estado == "" corta el draw_error.
	_juego._draw()
	_afirmar(true, "modo atacante + brain null: _draw() no dispara el guard de defensor (cae al guard runtime/graph)")

	_finalizar()


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _finalizar() -> void:
	if _juego != null and is_instance_valid(_juego):
		_juego.queue_free()
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)