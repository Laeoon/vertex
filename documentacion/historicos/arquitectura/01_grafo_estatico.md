# 01 · Grafo Estático y Runtime Mutable

## Visión Actual

La capa de datos de la red. Modela la topología como un grafo dirigido y ponderado $G=(V,E)$ donde cada arista carga dos pesos independientes. Los datos viven en Custom Resources (`.tres`) inmutables; las mutaciones en runtime se hacen sobre un `NetworkRuntime` que envuelve el recurso en memoria.

Esta capa es la base sobre la que se construirán agentes y FSM en hitos posteriores.

### Componentes

| Pieza | Tipo | Vida | Mutabilidad |
|---|---|---|---|
| `NetworkNodeResource` | `Resource` (`.tres`) | Estática (topología) | Inmutable en runtime |
| `NetworkEdgeResource` | `Resource` (`.tres`) | Estática (topología) | Inmutable en runtime |
| `NetworkGraphResource` | `Resource` (`.tres`) | Estática (contenedor) | Inmutable en runtime |
| `NetworkRuntime` | `RefCounted` | Dinámica (capa mutable) | Mutación libre en memoria |

## Historia

Hito 1 del proyecto. Nació con el objetivo de representar una red como un grafo que:
1. Fuera data-driven (datos en `.tres`, no en código).
2. Soportara dos pesos independientes por arista (latencia + mitigación).
3. Permitiese consultas rápidas de adyacencia (objetivo: O(1) por arista específica).
4. Fuera inmutable en disco y mutable solo en memoria (la FSM mandaría más adelante).

El diseño de doble peso permitirá que en el futuro Dijkstra y Edmonds-Karp corran sobre la misma red sin pisarse. La capa mutable se justificó por el principio "inmutabilidad del `.tres`" que después se formalizó como principio rector.

## Lógica de Ingeniería

### 1. `NetworkNodeResource` (vértice)

Un `Resource` por activo. Datos:

| Campo | Tipo | Ejemplo |
|---|---|---|
| `id` | `StringName` | `&"Firewall"` |
| `node_type` | `enum NodeType` | `FIREWALL` |
| `display_name` | `String` | `"Firewall Perimetral"` |
| `initial_state` | `StringName` | `&"disponible"` (legacy, no usado por la FSM actual) |
| `position` | `Vector2` | `(300, 100)` (para futuro overlay visual) |
| `metadata` | `Dictionary` | libre (subnet, OS, criticidad) |

**Por qué `StringName` para los IDs**: en Godot 4 son el tipo nativo para claves de `Dictionary`. Comparaciones y lookups son ~2x más rápidos que con `String` plano.

### 2. `NetworkEdgeResource` (arista con doble peso)

| Campo | Tipo | Significado |
|---|---|---|
| `from_id` | `StringName` | origen |
| `to_id` | `StringName` | destino |
| `transit_cost` | `float` | latencia o resistencia |
| `mitigation_capacity` | `float` | coste de parchear |
| `protocol` | `StringName` | metadato |

Los dos pesos son **canales independientes**: viven en claves separadas del diccionario interno. Modificar uno no toca al otro.

### 3. `NetworkGraphResource` (contenedor)

```gdscript
@export var nodes: Array[NetworkNodeResource] = []
@export var edges: Array[NetworkEdgeResource] = []
@export var directed: bool = true
```

Más un `validate()` que reporta:
- IDs duplicados o vacíos
- aristas con origen/destino inexistente
- self-loops
- pesos negativos
- aristas duplicadas (en grafo dirigido, `(A→B)` solo puede aparecer una vez)

Esto permite a los sandboxes hacer `assert(errors.is_empty())` antes de probar nada.

### 4. `NetworkRuntime` (capa mutable)

Es la **única** vía para consultar/mutar en runtime. Almacena:

```gdscript
var _adjacency: Dictionary = {}  # {from: {to: {tc, mc, protocol}}}
```

**Estructura de doble hash**: dos niveles de `Dictionary`. El primer nivel es `from_id → dict_interno`. El segundo es `to_id → datos_arista`. Esto da:

- `has_edge(a, b)` → O(1) (dos lookups)
- `get_transit_cost(a, b)` → O(1)
- `get_mitigation_capacity(a, b)` → O(1)
- `get_neighbors(a)` → O(grado saliente) (necesario enumerar)

Además mantiene:
- `node_states: Dictionary` → estado por nodo (usado internamente; la FSM del Hito 4 tiene su propio sistema paralelo, ver Pendientes)
- `node_threat_levels: Dictionary` → nivel de amenaza (0..1)

### 5. Inmutabilidad del `.tres`

El `.tres` original **no se toca jamás** en runtime. Las mutaciones pasan por setters que escriben sobre `_adjacency` (memoria RAM). Al cerrar la simulación, todo se descarta; al abrirla de nuevo, se parte del `.tres` limpio.

```gdscript
# Bien: mutar vía runtime
runtime.set_transit_cost(&"FW", &"Web", 99.0)

# Mal: escribir directamente sobre el recurso
graph.edges[0].transit_cost = 99.0  # viola el principio
```

## Validación

Dos sandboxes certifican esta capa.

### Sandbox A — Conectividad unidireccional

Demuestra que declarar `Internet → Firewall` no implica `Firewall → Internet`. Topología: 2 nodos, 1 arista. 7 asserts en verde:

- `graph.validate()` devuelve array vacío
- `get_neighbors(&"Internet")` tiene 1 elemento (Firewall)
- `get_neighbors(&"Firewall")` está vacío
- `has_edge(Internet, Firewall)` → `true`
- `has_edge(Firewall, Internet)` → `false`
- `get_transit_cost(Firewall, Internet)` → `INF`
- `get_mitigation_capacity(Firewall, Internet)` → `0.0`

### Sandbox B — Pesos duales independientes

Demuestra que `transit_cost` y `mitigation_capacity` son canales separados.
Topología: 3 nodos en cadena, 2 aristas. 9 asserts en verde, entre ellos:

- Modificar `transit_cost` a 99.0 no toca `mitigation_capacity` (sigue en 1.0)
- Recargar el `.tres` desde disco devuelve los valores originales (10.0, 1.0)

Comando para reproducir ambos:

```bash
godot --headless --path /home/leonardo/nuevo-proyecto-de-juego \
      res://sandboxes/case_a_connectivity_unidirectional/case_a_sandbox.tscn

godot --headless --path /home/leonardo/nuevo-proyecto-de-juego \
      res://sandboxes/case_b_edge_dual_weights/case_b_sandbox.tscn
```

## API completa de `NetworkRuntime`

| Método | Tipo retorno | Coste |
|---|---|---|
| `get_neighbors(p_id)` | `Array[Dictionary]` | O(grado saliente) |
| `has_edge(p_from, p_to)` | `bool` | O(1) |
| `get_transit_cost(p_from, p_to)` | `float` (INF si no existe) | O(1) |
| `get_mitigation_capacity(p_from, p_to)` | `float` (0 si no existe) | O(1) |
| `set_transit_cost(p_from, p_to, p_value)` | `void` | O(1) |
| `set_mitigation_capacity(p_from, p_to, p_value)` | `void` | O(1) |
| `set_node_state(p_id, p_state)` | `void` | O(1) |
| `get_node_state(p_id)` | `StringName` | O(1) |
| `set_threat_level(p_id, p_level)` | `void` | O(1) |
| `get_threat_level(p_id)` | `float` | O(1) |
| `rebuild_adjacency()` | `void` | O(|E|) |
