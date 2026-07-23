# Contexto del Proyecto — Simulador de Ciberseguridad

> Documento vivo. Se actualiza al cerrar cada Hito.
> Última actualización: Fase 1 — Restauración completa del ecosistema.

## Identidad

- **Motor**: Godot 4.6.3 estable (CLI en `/usr/bin/godot`)
- **Lenguaje**: GDScript con tipado estático fuerte
- **Filosofía**: Sandbox-First → Data-Driven → Game-Driven
- **Ubicación**: `/home/leonardo/nuevo-proyecto-de-juego/`
- **Backup de referencia**: `/home/leonardo/Documentos/SH antes del GUI/`
- **Estructura**:
  ```
  core/
  ├── network/      # Recursos del grafo (Hito 1)
  ├── agents/       # Algoritmos (Dijkstra, Edmonds-Karp)
  ├── autoloads/    # Event Bus (Events)
  ├── fsm/          # Máquina de estados por nodo
  └── integration/  # Wrappers reactivos (Pathfinder, Analyzer)
  sandboxes/        # 6 sandboxes (A–F), solo headless
  escenas/          # Menú principal + demos visuales
  juego/            # (Fase 2) Tutoriales + nivel jugable
  docs/             # Documentación
  ```

## Fases del Proyecto

| Fase | Estado | Descripción |
|------|--------|-------------|
| 1 | ✅ Completa | Restaurar todo del backup, docs, contexto |
| 2 | ⏳ Pendiente | Implementar Attack Path (tutoriales + nivel 1) |
| 3 | ⏳ Pendiente | Preparar .exe para presentación |

---

## Hito 1 — Cimientos del Grafo (✅)

**4 piezas en `core/network/`**:
- `NetworkNodeResource`: vértice
- `NetworkEdgeResource`: arista con 2 pesos
- `NetworkGraphResource`: contenedor `.tres` inmutable con `validate()`
- `NetworkRuntime`: capa mutable en memoria, O(1) en consultas

**Sandboxes A y B**: validan unidireccionalidad (7 asserts) y pesos duales (9 asserts).

---

## Hito 2 — Agentes Algorítmicos (✅)

**Componentes en `core/agents/`**:
- `MinHeap`: heap binario O(log N), usado por Dijkstra
- `DefensivePathfinder`: Dijkstra O((V+E) log V), consume `transit_cost`
- `StrategicAnalyzer`: Edmonds-Karp O(V·E²), consume `mitigation_capacity`

**Componentes en `core/`**:
- `core/autoloads/events.gd`: Event Bus con 4 señales tipadas (autoload `Events`)
- `core/fsm/network_node.gd`: FSM (DISPONIBLE → ALERTADO → CAPTURADO), emite al bus
- `core/integration/event_subscriber.gd`: helper subscribe/unsubscribe
- `core/integration/reactive_pathfinder.gd`: escucha `threat_detected`, emite `path_calculated`
- `core/integration/reactive_analyzer.gd`: escucha `node_state_changed(CAPTURADO)`, emite `min_cut_identified`

**Sandboxes C–F** (solo headless, excluidos del .exe):
| Sandbox | Prueba | Aserts |
|---------|--------|--------|
| C — Dijkstra | Rutas alternativas + nodo aislado | 13 |
| D — Min-Cut | Edmonds-Karp, 4 topologías | ~25 |
| E — Event Bus | FSM + 4 señales, idempotencia | 9 |
| F — Integración E2E | ReactivePathfinder + ReactiveAnalyzer | 4 |

**Demos visuales** (incluidas en el .exe):
- `case_demo_visual/`: explorador de grafo interactivo
- `case_demo_dual_weights/`: pesos duales mutables
- `case_demo_dijkstra_path/`: Dijkstra con 2 grafos (A/D), camino resaltado

---

## Decisiones Arquitectónicas Clave

### 1. Inmutabilidad del .tres
El recurso en disco nunca se modifica en runtime. Toda mutación va por `NetworkRuntime` (memoria).

### 2. Doble peso por arista
`transit_cost` (Dijkstra) y `mitigation_capacity` (Edmonds-Karp) son independientes. Ningún algoritmo toca el peso del otro.

### 3. Event Bus como singleton
`Events` es autoload en `/root/Events`. La FSM emite, los agentes reactivos escuchan, la UI se entera. Sin acoplamiento directo.

### 4. Sandboxes excluidos del .exe
Los 6 sandboxes (A–F) se excluyen del export vía `exclude_filter` porque usan `print()` y no tienen UI visible en Windows.

### 5. Attack Path como dirección del juego
Decidido en sesión de diseño (Junio 2026): el jugador **ataca**, la IA **defiende**.
- Jugador mueve pieza por turno hacia waypoints
- IA bloquea aristas prediciendo la ruta
- Win: llegar al target. Lose: sin camino posible o detección

---

## Discusiones Pendientes para Fase 2

1. **Sistema de persistencia**: `user://progress.cfg` con nombre, niveles, puntajes
2. **Pantalla de login**: perfil de estudiante al iniciar
3. **Tutoriales integrados como niveles jugables** (no son sandboxes separados)
4. **Topologías realistas**: red corporativa DMZ, capas de seguridad
5. **IA defensora con estrategias**: bloqueo aleatorio, bottleneck, adaptativa
6. **Timer por turno**: cuántos segundos tiene el jugador antes de que la IA detecte

---

## API de Referencia

| Clase | Método | Uso |
|-------|--------|-----|
| `DefensivePathfinder` | `find_path(graph, start, target)` | `→ Array[StringName]` |
| `DefensivePathfinder` | `find_path_with_cost(graph, start, target)` | `→ {path, cost, reachable}` |
| `StrategicAnalyzer` | `find_min_cut(graph, source, sink)` | `→ {max_flow, cut_edges, ...}` |
| `NetworkRuntime` | `set_transit_cost(from, to, value)` | Mutar costo en memoria |
| `NetworkRuntime` | `get_neighbors(node_id)` | `→ [{to_id, transit_cost, ...}]` |
| `Events` | `threat_detected.emit(id, level)` | Disparar pathfinder reactivo |
| `Events` | `path_calculated.emit(...)` | UI escucha para repintarse |
