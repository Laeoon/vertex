# 02 · Agente de Intercepción (Dijkstra)

## Visión General

El Hito 2 introduce el **primer agente algorítmico** del simulador:
`DefensivePathfinder`. Su función es encontrar la ruta de menor `transit_cost`
entre dos nodos del grafo, usando el algoritmo de Dijkstra respaldado por un
min-heap binario. Es el motor de movimiento del atacante en el **Juego 1:
Network Defender**.

### Game 1 — Network Defender (Metáfora)

> Eres el analista de seguridad de una red corporativa. Un atacante ha
> comprometido un nodo periférico y avanza hacia un activo crítico. Tu
> misión es predecir la ruta que tomará (Dijkstra sobre `transit_cost`)
> y colocar barreras que incrementen el costo de las aristas para
> desviarlo o frenarlo. El agente recalcula la ruta automáticamente y
> el analista ve si la barrera fue efectiva.

---

## Lógica de Ingeniería

### 1. Desición de diseño: alcance acotado

El Hito 2 se centra **exclusivamente** en `DefensivePathfinder` +
`MinHeap`. Queda fuera del alcance inmediato:

| Concepto | Postergado a | Motivo |
|---|---|---|
| Betweenness centrality | Hito 3+ / futuro PB | Requiere V ejecuciones de Dijkstra (O(V·E log V)). No certificado en sandbox. |
| Edmonds-Karp (flujo) | Hito 3 | Algoritmo diferente, peso distinto (`mitigation_capacity`). |
| Event Bus / FSM | Hito 4 | Mecanismo de comunicación, no de cómputo de rutas. |
| ReactivePathfinder | Hito 5 | Wrapper reactivo sobre el bus; el core algorítmico es el mismo que Hito 2. |

### 2. Componentes

#### `core/agents/min_heap.gd`

Estructura de datos: heap binario con operaciones `push(priority, payload)`
y `pop() → [priority, payload]` en O(log N).

- Entradas: `[priority: float, payload: Variant]`
- Decrease-key implícito: se inserta duplicado y se descarta el obsoleto al pop

#### `core/agents/defensive_pathfinder.gd`

Algoritmo estático (stateless, métodos `static`):

```gdscript
DefensivePathfinder.find_path(graph, &"Agente", &"Servidor_Web") -> Array[StringName]
DefensivePathfinder.find_path_with_cost(graph, &"Agente", &"Servidor_Web") -> Dictionary
# → { "path": Array[StringName], "cost": float, "reachable": bool }
```

Características:
- **Consume solo `transit_cost`**, ignora `mitigation_capacity`
- **3 breaks de protección**: safety INF, entrada obsoleta, target alcanzado
- **Manejo defensivo**: grafo nulo, nodos inexistentes → `[]` + `push_warning`
- **Complejidad**: O((V+E) log V) garantizado por el min-heap

#### `sandboxes/case_c_dijkstra_pathfinding/`

Dos sub-casos (rutas alternativas + nodo aislado) — ~13 asserts.

### 3. Loop del Game 1 (interacción jugador → agente)

El jugador no ataca directamente. Coloca barreras y consulta rutas:

```
  ┌──────────────────────────────────────────────────┐
  │  1. Jugador coloca barrera                       │
  │     runtime.set_transit_cost(arista, 99.0)       │
  │     (solo en memoria, .tres intacto)            │
  │                                                  │
  │  2. Jugador (o sistema) invoca recalculo         │
  │     result := Pathfinder.find_path_with_cost(...) │
  │                                                  │
  │  3. Resultado se muestra (ruta nueva, coste)     │
  │     print / UI actualiza colores                 │
  └──────────────────────────────────────────────────┘
```

**Reglas**:
- `set_transit_cost` **NO emite señales** — es una mutación silenciosa de datos
- El recalculo es **explícito** (por input del jugador o por temporizador), nunca automático desde una señal
- La ruta se calcula desde cero cada vez (Dijkstra es stateless)

### 4. Seguridad contra bucles infinitos (cuando llegue el Event Bus)

Cuando Hito 4+5 agregue el Event Bus y los wrappers reactivos, se
requiere una salvaguarda para evitar que el pathfinder se re-dispare
a sí mismo. Dos mecanismos lo garantizan:

#### A. Separación de señales (por diseño)

| Señal | Emisor | ¿Dispara pathfinder? |
|---|---|---|
| `node_state_changed` | FSM | Sí (ReactivePathfinder escucha `threat_detected`) |
| `threat_detected` | FSM | Sí (es el trigger del ReactivePathfinder) |
| `path_calculated` | Pathfinder | **No** (es output, la UI lo consume) |
| `min_cut_identified` | Analyzer | No (es del otro agente) |

`set_transit_cost()` nunca emite ninguna señal. Por tanto, el pathfinder
solo recalcula cuando un nodo cambia a `ALERTADO`, nunca por una mutación
de peso.

#### B. Dirty flag (recalculo on-demand)

Si en el futuro se desea recalculo automático al colocar barreras (sin
botón manual), se usa un flag que impide la reentrada:

```gdscript
var recalculation_pending: bool = false

func on_barrier_placed(from: StringName, to: StringName, new_cost: float) -> void:
    runtime.set_transit_cost(from, to, new_cost)
    recalculation_pending = true

func _process(delta: float) -> void:
    if recalculation_pending:
        var result := DefensivePathfinder.find_path_with_cost(graph, source, target)
        Events.path_calculated.emit(source, target, result.path, result.cost)
        recalculation_pending = false
```

El `_process` se ejecuta una vez por frame. La UI escucha `path_calculated`
y se repinta. La emisión de `path_calculated` **no** re-dispara el flag
porque `on_barrier_placed` es el único que lo activa.

### 5. Heurística de conectividad local (reemplazo temporal de centrality)

Hasta que exista un algoritmo de betweenness centrality (futuro PB-11),
se usa el **grado del nodo** (`get_neighbors(id).size()`) como indicador
de "nodos puente". Es una medida de centralidad local O(grado saliente)
disponible desde Hito 1 sin código nuevo.

```gdscript
# Visual: nodo con grado alto = candidato a puente crítico
var degree: int = runtime.get_neighbors(&"Firewall").size()
```

---

## Implementación planificada

### Archivos a crear

```
core/agents/
├── min_heap.gd
└── defensive_pathfinder.gd

sandboxes/case_c_dijkstra_pathfinding/
├── case_c_sandbox.tscn
├── case_c_test.gd
├── network_test_c_routes.tres
└── network_test_c_isolated.tres
```

### Orden de implementación

1. `min_heap.gd` — heap binario con push/pop O(log N)
2. `DefensivePathfinder` — Dijkstra usando el heap
3. Sandbox C — 2 sub-casos (rutas alternativas + nodo aislado)
4. Demo visual opcional que muestre el path sobre el grafo

### Criterio de aceptación

- [ ] `MinHeap.push()` y `MinHeap.pop()` mantienen orden correcto (verificado con asserts)
- [ ] `find_path(A, B)` devuelve ruta mínima cuando existe
- [ ] `find_path(A, B)` devuelve `[]` cuando B es inalcanzable
- [ ] `find_path_with_cost(A, B)` devuelve `{path, cost, reachable}`
- [ ] No consume `mitigation_capacity` en ningún caso
- [ ] Grafo nulo o nodos inexistentes → `[]` con `push_warning`
- [ ] Sandbox C pasa 13 asserts
- [ ] Mutación de `transit_cost` no altera el `.tres` en disco
- [ ] `set_transit_cost` no emite señales
