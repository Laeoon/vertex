class_name NetworkNodeResource extends Resource

## Definición estática de un activo de red (vértice del grafo).
## Este Resource es INMUTABLE en tiempo de ejecución: los cambios
## dinámicos (estado, nivel de amenaza) viven en NetworkRuntime.

enum NodeType {
	INTERNET,      ## Nodo externo, origen típico de ataques
	FIREWALL,      ## Filtro de tráfico perimetral
	ROUTER,        ## Encaminamiento interno
	SERVER,        ## Servidor de aplicaciones
	WORKSTATION,   ## Estación de trabajo de usuario
	DATABASE,      ## Almacén de datos sensible
}

@export var id: StringName = &""
@export var node_type: NodeType = NodeType.SERVER
@export var display_name: String = ""
@export var initial_state: StringName = &"disponible"
@export var position: Vector2 = Vector2.ZERO
@export var metadata: Dictionary = {}


func _to_string() -> String:
	return "Node(%s, type=%s, state=%s)" % [id, node_type, initial_state]
