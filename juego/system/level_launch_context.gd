class_name LevelLaunchContext
extends Resource

## Typed immutable-per-transition context holding all level launch parameters.
## Supports both legacy v1 (.json + .tres) and v2 (*.level.json with inline compiled graph).

const NetworkGraphResourceClass = preload("res://core/network/network_graph_resource.gd")

@export var schema_version: int = 1
@export var level_key: String = ""
@export var world_id: String = ""
@export var act: int = 1
@export var order: int = 1
@export var is_golden_boss: bool = false
@export var cinematic_intro: String = ""
@export var cinematic_outro: String = ""
@export var unlocks: Dictionary = {}

@export var graph_path: String = ""
var inline_graph: NetworkGraphResourceClass = null

@export var start_node: StringName = &""
@export var target_node: StringName = &""
@export var waypoints: Array = []
@export var titulo_nivel: String = ""
@export var mensaje_tutorial: String = ""

@export var ai_enabled: bool = true
@export var ai_block_per_turn: int = 1
@export var ai_bloquea_al_inicio: bool = true
@export var max_ai_blocks: int = 999
@export var max_turns: int = 0
@export var max_movement_points: int = 0

@export var hacker_mode: bool = false
@export var starting_exploits: Dictionary = {}

@export var defender_mode: bool = false
@export var defender_blocks_per_turn: int = 2
@export var defender_block_duration: int = 4
@export var defender_max_blocks: int = 999
@export var enemy_start_node: StringName = &""
@export var enemy_target_node: StringName = &""
@export var firewall_cost: int = 2

@export var block_duration: int = 3
@export var pursuer_delay: int = 2
@export var max_pursuers: int = 4
@export var pursuer_speed: int = 1
@export var eventos_alarma: Array = []
@export var ia_predictiva: bool = false
@export var bonus_nodes: Array = []
@export var node_triggers: Dictionary = {}
@export var locked_edges: Array = []
@export var hidden_nodes: Array = []
@export var node_positions: Dictionary = {}
@export var stages: Array = []
@export var multi_daemons: Array = []
