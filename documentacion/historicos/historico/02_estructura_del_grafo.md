# 02 · Estructura del Grafo (Diseño)

## El problema

Representar una red informática como un **grafo dirigido y ponderado** $G=(V,E)$ que:

1. Sea **Data-Driven** (los datos viven en `.tres`, no en código).
2. Permita **dos pesos independientes** por arista (latencia + mitigación).
3. Soporte **consultas rápidas** de adyacencia (objetivo: O(1) por arista específica).
4. Sea **inmutable en disco** y mutable solo en memoria (FSM manda).

## La solución: 4 piezas

```
NetworkNodeResource     NetworkEdgeResource
        (vértice)              (arista con 2 pesos)
              \                /
               \              /
                ▼            ▼
            NetworkGraphResource   ← contenedor (.tres)
                     │
                     ▼
            NetworkRuntime         ← capa mutable en memoria
```

### Pieza 1 — `NetworkNodeResource` (vértice)

Un `Resource` por activo. Datos que trae:

| Campo | Tipo | Ejemplo |
|---|---|---|
| `id` | `StringName` | `"Firewall"` |
| `node_type` | `enum` | `FIREWALL` |
| `display_name` | `String` | `"Firewall Perimetral"` |
| `initial_state` | `StringName` | `"disponible"` |
| `position` | `Vector2` | `(300, 100)` (para futuro overlay visual) |
| `metadata` | `Dictionary` | libre (subnet, OS, criticidad…) |

**Por qué `StringName` para los IDs**: en Godot 4 son el tipo nativo para claves de `Dictionary`. Comparaciones y lookups son ~2x más rápidos que con `String` plano.

### Pieza 2 — `NetworkEdgeResource` (arista con doble peso)

| Campo | Tipo | Significado | Algoritmo destino |
|---|---|---|---|
| `from_id` | `StringName` | origen | — |
| `to_id` | `StringName` | destino | — |
 | `transit_cost` | `float` | latencia o resistencia | — |
| `mitigation_capacity` | `float` | coste de parchear | — |
| `protocol` | `StringName` | metadato | futuro firewall |

**Clave**: los dos pesos son **canales independientes**. Modificar uno no toca al otro.

### Pieza 3 — `NetworkGraphResource` (contenedor)

Dos arrays exportados:
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

### Pieza 4 — `NetworkRuntime` (capa mutable)

Es la **única** vía para consultar/mutar. Almacena:

```gdscript
var _adjacency: Dictionary = {}  # {from: {to: {tc, mc, protocol}}}
```

**Estructura de doble hash**: dos niveles de `Dictionary`. El primer nivel es `from_id → dict_interno`. El segundo es `to_id → datos_arista`. Esto da:

- `has_edge(a, b)` → `O(1)` (dos lookups)
- `get_transit_cost(a, b)` → `O(1)`
- `get_mitigation_capacity(a, b)` → `O(1)`
- `get_neighbors(a)` → O(grado saliente) (necesario enumerar)

Además mantiene:
- `node_states: Dictionary` → estado por nodo
- `node_threat_levels: Dictionary` → nivel de amenaza (0..1)

**Regla**: el `.tres` original no se toca jamás. Las mutaciones pasan por setters que escriben sobre `_adjacency` (memoria RAM). Al cerrar la simulación, todo se descarta; al abrirla de nuevo, se parte del `.tres` limpio.

## Cómo resuelve el Caso de Prueba

### Caso A — Conectividad Unidireccional

```gdscript
# El .tres declara SOLO esta arista:
#   Internet → Firewall

var runtime := NetworkRuntime.new(graph)

runtime.get_neighbors(&"Internet")  # → [{to_id: "Firewall", ...}]
runtime.get_neighbors(&"Firewall")  # → []  ← VACÍO
runtime.get_transit_cost(&"Firewall", &"Internet")  # → INF  ← no existe
```

La unidireccionalidad **emerge** del hecho de que solo declaramos una dirección en el array `edges`. No hay código que "bloquee" la salida; simplemente no existe la arista de vuelta.

## ✅ Criterio de aceptación de esta fase

- [x] 4 archivos `.gd` creados en `core/network/`
- [x] Tipado estático en todas las firmas
- [x] `class_name` declarado en cada uno
- [x] `validate()` implementado en el grafo
- [x] Caché de adyacencia con doble hash (O(1) por arista)
- [x] `.tres` permanece inmutable (todas las mutaciones vía runtime)
- [x] Caso A resuelto por construcción
