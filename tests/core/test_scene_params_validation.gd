extends Node

## Tests de validación para SceneParams.
##
## Verifica que:
## - Los valores fuera de rango se clampan correctamente
## - Los valores dentro de rango se aceptan sin modificación
## - reset() restaura todos los valores por defecto
## - Los strings vacíos se manejan apropiadamente

const SceneParamsScript = preload("res://core/autoloads/scene_params.gd")

var _params: Node
var _tests_passed: int = 0
var _tests_failed: int = 0


func _ready() -> void:
	print("==============================================")
	print("TEST: SceneParams Validation")
	print("==============================================")

	_params = Node.new()
	_params.set_script(SceneParamsScript)
	add_child(_params)

	_test_ai_block_per_turn()
	_test_max_ai_blocks()
	_test_max_turns()
	_test_max_movement_points()
	_test_defender_blocks_per_turn()
	_test_defender_block_duration()
	_test_defender_max_blocks()
	_test_firewall_cost()
	_test_block_duration()
	_test_pursuer_delay()
	_test_max_pursuers()
	_test_pursuer_speed()
	_test_graph_path()
	_test_level_key()
	_test_tutorial_path()
	_test_reset()

	print("==============================================")
	print("Resumen: %d aprobadas, %d fallidas" % [_tests_passed, _tests_failed])
	print("==============================================")

	if _tests_failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
		print("  OK: %s" % message)
	else:
		_tests_failed += 1
		print("  FAIL: %s" % message)


# ──────────────────────────────────────────────────────────────────────────────
# Tests de rangos numéricos
# ──────────────────────────────────────────────────────────────────────────────

func _test_ai_block_per_turn() -> void:
	print("\n[Test ai_block_per_turn]")

	_params.ai_block_per_turn = 5
	_assert(_params.ai_block_per_turn == 5, "Valor dentro de rango (5)")

	_params.ai_block_per_turn = 0
	_assert(_params.ai_block_per_turn == 0, "Valor mínimo (0)")

	_params.ai_block_per_turn = 10
	_assert(_params.ai_block_per_turn == 10, "Valor máximo (10)")

	_params.ai_block_per_turn = -5
	_assert(_params.ai_block_per_turn == 0, "Valor negativo clampeado a 0")

	_params.ai_block_per_turn = 15
	_assert(_params.ai_block_per_turn == 10, "Valor excesivo clampeado a 10")


func _test_max_ai_blocks() -> void:
	print("\n[Test max_ai_blocks]")

	_params.max_ai_blocks = 500
	_assert(_params.max_ai_blocks == 500, "Valor dentro de rango (500)")

	_params.max_ai_blocks = 0
	_assert(_params.max_ai_blocks == 0, "Valor mínimo (0)")

	_params.max_ai_blocks = 9999
	_assert(_params.max_ai_blocks == 9999, "Valor máximo (9999)")

	_params.max_ai_blocks = -1
	_assert(_params.max_ai_blocks == 0, "Valor negativo clampeado a 0")

	_params.max_ai_blocks = 10000
	_assert(_params.max_ai_blocks == 9999, "Valor excesivo clampeado a 9999")


func _test_max_turns() -> void:
	print("\n[Test max_turns]")

	_params.max_turns = 50
	_assert(_params.max_turns == 50, "Valor dentro de rango (50)")

	_params.max_turns = 0
	_assert(_params.max_turns == 0, "Valor mínimo (0 = ilimitado)")

	_params.max_turns = 1000
	_assert(_params.max_turns == 1000, "Valor máximo (1000)")

	_params.max_turns = -1
	_assert(_params.max_turns == 0, "Valor negativo clampeado a 0")

	_params.max_turns = 1001
	_assert(_params.max_turns == 1000, "Valor excesivo clampeado a 1000")


func _test_max_movement_points() -> void:
	print("\n[Test max_movement_points]")

	_params.max_movement_points = 50
	_assert(_params.max_movement_points == 50, "Valor dentro de rango (50)")

	_params.max_movement_points = 0
	_assert(_params.max_movement_points == 0, "Valor mínimo (0 = ilimitado)")

	_params.max_movement_points = 100
	_assert(_params.max_movement_points == 100, "Valor máximo (100)")

	_params.max_movement_points = -1
	_assert(_params.max_movement_points == 0, "Valor negativo clampeado a 0")

	_params.max_movement_points = 101
	_assert(_params.max_movement_points == 100, "Valor excesivo clampeado a 100")


func _test_defender_blocks_per_turn() -> void:
	print("\n[Test defender_blocks_per_turn]")

	_params.defender_blocks_per_turn = 10
	_assert(_params.defender_blocks_per_turn == 10, "Valor dentro de rango (10)")

	_params.defender_blocks_per_turn = 0
	_assert(_params.defender_blocks_per_turn == 0, "Valor mínimo (0)")

	_params.defender_blocks_per_turn = 20
	_assert(_params.defender_blocks_per_turn == 20, "Valor máximo (20)")

	_params.defender_blocks_per_turn = -1
	_assert(_params.defender_blocks_per_turn == 0, "Valor negativo clampeado a 0")

	_params.defender_blocks_per_turn = 21
	_assert(_params.defender_blocks_per_turn == 20, "Valor excesivo clampeado a 20")


func _test_defender_block_duration() -> void:
	print("\n[Test defender_block_duration]")

	_params.defender_block_duration = 50
	_assert(_params.defender_block_duration == 50, "Valor dentro de rango (50)")

	_params.defender_block_duration = 1
	_assert(_params.defender_block_duration == 1, "Valor mínimo (1)")

	_params.defender_block_duration = 100
	_assert(_params.defender_block_duration == 100, "Valor máximo (100)")

	_params.defender_block_duration = 0
	_assert(_params.defender_block_duration == 1, "Valor 0 clampeado a 1")

	_params.defender_block_duration = -5
	_assert(_params.defender_block_duration == 1, "Valor negativo clampeado a 1")

	_params.defender_block_duration = 101
	_assert(_params.defender_block_duration == 100, "Valor excesivo clampeado a 100")


func _test_defender_max_blocks() -> void:
	print("\n[Test defender_max_blocks]")

	_params.defender_max_blocks = 500
	_assert(_params.defender_max_blocks == 500, "Valor dentro de rango (500)")

	_params.defender_max_blocks = 0
	_assert(_params.defender_max_blocks == 0, "Valor mínimo (0)")

	_params.defender_max_blocks = 9999
	_assert(_params.defender_max_blocks == 9999, "Valor máximo (9999)")

	_params.defender_max_blocks = -1
	_assert(_params.defender_max_blocks == 0, "Valor negativo clampeado a 0")

	_params.defender_max_blocks = 10000
	_assert(_params.defender_max_blocks == 9999, "Valor excesivo clampeado a 9999")


func _test_firewall_cost() -> void:
	print("\n[Test firewall_cost]")

	_params.firewall_cost = 50
	_assert(_params.firewall_cost == 50, "Valor dentro de rango (50)")

	_params.firewall_cost = 1
	_assert(_params.firewall_cost == 1, "Valor mínimo (1)")

	_params.firewall_cost = 100
	_assert(_params.firewall_cost == 100, "Valor máximo (100)")

	_params.firewall_cost = 0
	_assert(_params.firewall_cost == 1, "Valor 0 clampeado a 1")

	_params.firewall_cost = -1
	_assert(_params.firewall_cost == 1, "Valor negativo clampeado a 1")

	_params.firewall_cost = 101
	_assert(_params.firewall_cost == 100, "Valor excesivo clampeado a 100")


func _test_block_duration() -> void:
	print("\n[Test block_duration]")

	_params.block_duration = 50
	_assert(_params.block_duration == 50, "Valor dentro de rango (50)")

	_params.block_duration = 1
	_assert(_params.block_duration == 1, "Valor mínimo (1)")

	_params.block_duration = 100
	_assert(_params.block_duration == 100, "Valor máximo (100)")

	_params.block_duration = 0
	_assert(_params.block_duration == 1, "Valor 0 clampeado a 1")

	_params.block_duration = -1
	_assert(_params.block_duration == 1, "Valor negativo clampeado a 1")

	_params.block_duration = 101
	_assert(_params.block_duration == 100, "Valor excesivo clampeado a 100")


func _test_pursuer_delay() -> void:
	print("\n[Test pursuer_delay]")

	_params.pursuer_delay = 25
	_assert(_params.pursuer_delay == 25, "Valor dentro de rango (25)")

	_params.pursuer_delay = 0
	_assert(_params.pursuer_delay == 0, "Valor mínimo (0)")

	_params.pursuer_delay = 50
	_assert(_params.pursuer_delay == 50, "Valor máximo (50)")

	_params.pursuer_delay = -1
	_assert(_params.pursuer_delay == 0, "Valor negativo clampeado a 0")

	_params.pursuer_delay = 51
	_assert(_params.pursuer_delay == 50, "Valor excesivo clampeado a 50")


func _test_max_pursuers() -> void:
	print("\n[Test max_pursuers]")

	_params.max_pursuers = 10
	_assert(_params.max_pursuers == 10, "Valor dentro de rango (10)")

	_params.max_pursuers = 1
	_assert(_params.max_pursuers == 1, "Valor mínimo (1)")

	_params.max_pursuers = 20
	_assert(_params.max_pursuers == 20, "Valor máximo (20)")

	_params.max_pursuers = 0
	_assert(_params.max_pursuers == 1, "Valor 0 clampeado a 1")

	_params.max_pursuers = -1
	_assert(_params.max_pursuers == 1, "Valor negativo clampeado a 1")

	_params.max_pursuers = 21
	_assert(_params.max_pursuers == 20, "Valor excesivo clampeado a 20")


func _test_pursuer_speed() -> void:
	print("\n[Test pursuer_speed]")

	_params.pursuer_speed = 5
	_assert(_params.pursuer_speed == 5, "Valor dentro de rango (5)")

	_params.pursuer_speed = 1
	_assert(_params.pursuer_speed == 1, "Valor mínimo (1)")

	_params.pursuer_speed = 10
	_assert(_params.pursuer_speed == 10, "Valor máximo (10)")

	_params.pursuer_speed = 0
	_assert(_params.pursuer_speed == 1, "Valor 0 clampeado a 1")

	_params.pursuer_speed = -1
	_assert(_params.pursuer_speed == 1, "Valor negativo clampeado a 1")

	_params.pursuer_speed = 11
	_assert(_params.pursuer_speed == 10, "Valor excesivo clampeado a 10")


# ──────────────────────────────────────────────────────────────────────────────
# Tests de strings
# ──────────────────────────────────────────────────────────────────────────────

func _test_graph_path() -> void:
	print("\n[Test graph_path]")

	_params.graph_path = "res://levels/test.tscn"
	_assert(_params.graph_path == "res://levels/test.tscn", "String válido aceptado")

	var previous_graph: String = _params.graph_path
	_params.graph_path = ""
	_assert(_params.graph_path == previous_graph, "String vacío rechazado — mantiene valor anterior")


func _test_level_key() -> void:
	print("\n[Test level_key]")

	_params.level_key = "level_01"
	_assert(_params.level_key == "level_01", "String válido aceptado")

	var previous_key: String = _params.level_key
	_params.level_key = ""
	_assert(_params.level_key == previous_key, "String vacío rechazado — mantiene valor anterior")


func _test_tutorial_path() -> void:
	print("\n[Test tutorial_path]")

	_params.tutorial_path = "res://tutorials/intro.tscn"
	_assert(_params.tutorial_path == "res://tutorials/intro.tscn", "String válido aceptado")

	_params.tutorial_path = ""
	_assert(_params.tutorial_path == "", "String vacío aceptado (opcional)")


# ──────────────────────────────────────────────────────────────────────────────
# Test de reset()
# ──────────────────────────────────────────────────────────────────────────────

func _test_reset() -> void:
	print("\n[Test reset()]")

	# Modificar algunos valores
	_params.ai_block_per_turn = 7
	_params.max_turns = 500
	_params.graph_path = "res://test.tscn"
	_params.defender_mode = true

	# Reset
	_params.reset()

	# Verificar valores por defecto
	_assert(_params.ai_block_per_turn == 1, "reset: ai_block_per_turn = 1")
	_assert(_params.max_turns == 0, "reset: max_turns = 0")
	_assert(_params.max_movement_points == 0, "reset: max_movement_points = 0")
	_assert(_params.max_ai_blocks == 999, "reset: max_ai_blocks = 999")
	_assert(_params.defender_blocks_per_turn == 2, "reset: defender_blocks_per_turn = 2")
	_assert(_params.defender_block_duration == 4, "reset: defender_block_duration = 4")
	_assert(_params.defender_max_blocks == 999, "reset: defender_max_blocks = 999")
	_assert(_params.firewall_cost == 2, "reset: firewall_cost = 2")
	_assert(_params.block_duration == 3, "reset: block_duration = 3")
	_assert(_params.pursuer_delay == 2, "reset: pursuer_delay = 2")
	_assert(_params.max_pursuers == 4, "reset: max_pursuers = 4")
	_assert(_params.pursuer_speed == 1, "reset: pursuer_speed = 1")
	_assert(_params.ai_enabled == true, "reset: ai_enabled = true")
	_assert(_params.ai_bloquea_al_inicio == true, "reset: ai_bloquea_al_inicio = true")
	_assert(_params.hacker_mode == false, "reset: hacker_mode = false")
	_assert(_params.defender_mode == false, "reset: defender_mode = false")
