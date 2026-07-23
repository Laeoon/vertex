class_name NetworkNode extends Node

## Máquina de Estados Finitos (FSM) de un activo de red.
## Diseñada para adjuntarse como Nodo en la escena, NO como Resource.
##
## Responsabilidad: gestionar el estado dinámico de un activo
## (DISPONIBLE → ALERTADO → CAPTURADO) y notificar al Event Bus
## cada cambio. NO hace nada visual.
##
## Restricción arquitectónica: este script NO contiene referencias
## a colores, Modulate, ni nodos visuales. Su único trabajo es
## lógica de estado + notificación.
##
## Relación con NetworkNodeResource:
##   - NetworkNodeResource (Resource, .tres) = foto estática del activo
##   - NetworkNode (este Node)              = instancia viva con FSM
##   - El Node REFERENCIA al Resource vía @export, no lo reemplaza.
##     El .tres permanece inmutable.

enum NodeState {
	DISPONIBLE,  ## Estado nominal, sin incidentes
	ALERTADO,    ## Se detectó actividad sospechosa, el agente debe intervenir
	CAPTURADO,   ## El activo está comprometido, requiere aislamiento
}


# ─── CONFIGURACIÓN ────────────────────────────────────────────────────

## Referencia al Resource que define los datos estáticos del activo.
## Se arrastra desde el Inspector o se asigna por código.
@export var node_resource: NetworkNodeResource

## Estado inicial. Por convención, sincroniza con NetworkNodeResource.initial_state.
@export var initial_state: NodeState = NodeState.DISPONIBLE

## Nivel de amenaza (0.0 a 1.0). Se incluye en la señal threat_detected.
@export_range(0.0, 1.0, 0.01) var threat_level: float = 0.0


# ─── ESTADO INTERNO ───────────────────────────────────────────────────

## Backing field para evitar recursión en el setter de `state`.
var _state: NodeState = NodeState.DISPONIBLE


# ─── PROPIEDAD CON SETTER (punto central de la FSM) ──────────────────

## Estado actual del nodo. Asignar aquí dispara la lógica de transición:
##   - Si el valor no cambia: no hace nada (idempotente)
##   - Si cambia: emite `node_state_changed` al Event Bus
##   - Si el nuevo estado es ALERTADO: emite también `threat_detected`
var state: NodeState:
	get:
		return _state
	set(value):
		if value == _state:
			return  # Idempotente: evita spam de señales
		# Validar node_resource ANTES de mutar _state
		if node_resource == null:
			push_warning("NetworkNode: node_resource no asignado, no se puede emitir señal")
			return
		var old_state: NodeState = _state
		_state = value
		Events.node_state_changed.emit(node_resource.id, old_state, value)
		if value == NodeState.ALERTADO:
			Events.threat_detected.emit(node_resource.id, threat_level)


# ─── CICLO DE VIDA ────────────────────────────────────────────────────

func _ready() -> void:
	# Sincroniza el estado interno con el configurado en @export.
	# Usamos asignación directa (no la propiedad con setter) para evitar
	# emitir señales durante la inicialización.
	_state = initial_state


# ─── HELPERS ──────────────────────────────────────────────────────────

## Devuelve el nombre legible del estado actual (útil para logs/UI).
func get_state_name() -> String:
	return NodeState.keys()[_state]


## Cambia el estado programáticamente con un mensaje de log opcional.
## Es un wrapper de `state = value` para mayor legibilidad en el caller.
func transition_to(new_state: NodeState) -> void:
	state = new_state


## Helper para alertar rápidamente: marca ALERTADO con nivel de amenaza.
func alert(threat: float = 0.5) -> void:
	threat_level = threat
	state = NodeState.ALERTADO
