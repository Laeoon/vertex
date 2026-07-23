# Tareas para Ziva — Asignadas por MiMo Code

## Contexto

Soy MiMo Code (arquitecto/análisis). Te asigno tareas de implementación. Eres responsable de editor visual, grafos, niveles y builds.

Tokens limitados ($3/mes) — prioriza, no desvíes en análisis.

---

## Fase 0 — Hotfixes Críticos (urgente)

### 🔴 B1: Unificar sistema de bloqueos

**Archivo:** `juego/ataque/juego_ataque.gd`

**Problema:** `_is_blocked()` solo revisa `blocked_edges` dict, pero los firewalls escriben directo en `runtime.set_transit_cost(from, to, INF)`. Firewalls son invisibles a `_is_blocked()`.

**Qué hacer:**
1. En `_is_blocked()`, además de revisar `blocked_edges`, preguntar al runtime:
   ```gdscript
   var cost = runtime.get_transit_cost(from_n, to_n)
   if cost == INF: return true
   ```
2. Verificar que `_defender_block_edge()` y `_mover_jugador()` usen `_is_blocked()` para todo (no bypassen).

---

### 🔴 B2: Implementar exploit "persist"

**Archivo:** `juego/ataque/juego_ataque.gd` línea ~1322

**Problema:** `"persist": pass` — no hace nada.

**Qué hacer:** El persist debería mantener el acceso: durante 3 turnos, ignorar decay de ruido o permitir movimiento aunque haya bloqueos. Implementar lógica mínima:
```gdscript
"persist":
    hacker_state["active_persists"][str(selected_neighbor)] = 3
```
Ya existe `active_persists` en `hacker_state`. Usarlo en `_check_hacker_consequences()` para reducir contador cada turno.

---

### 🔴 B3: Cachear `_find_node_resource`

**Archivo:** `juego/ataque/juego_ataque.gd` línea 272

**Problema:** Recorre O(n) en cada clic. Crear un `Dictionary` cache `id → node` en `_load_graph()`:
```gdscript
var _node_cache: Dictionary = {}
# en _load_graph():
for n in graph.nodes:
    if n != null:
        _node_cache[n.id] = n
```

---

## Fase 1 — Refactor Arquitectónico (después de hotfixes)

### 1. Extraer `input_handler.gd`

De `juego_ataque.gd`, mover TODO el bloque `_input()` (~90 líneas) a una clase separada que emita señales (ej. `move_requested`, `scan_requested`, `exploit_used`).

### 2. Extraer `defender_brain.gd`

De `juego_ataque.gd`, mover:
- `_init_defender_mode()` → `init()`
- `_defender_block_edge()` → `block_edge()`
- `_ejecutar_turno_defensor()` → `resolve_turn()`
- `_enemy_move()` → `move_enemy()`
- `_defender_win()` / `_defender_lose()`
- `_calcular_estrellas_defensor()`
- Todo el estado defensor (`enemy_pos`, `blocked_edges`, etc.)

### 3. Cachear `GameRenderer`

En `_ready()`:
```gdscript
var _renderer: GameRenderer
func _ready():
    _renderer = GameRendererClass.new(self, font, ...)
```
En `_draw()`:
```gdscript
_renderer.draw_edges(...)  # no crear new cada frame
```

---

## Fase 2 — Contenido (después de refactor)

| # | Tarea | Archivos |
|---|-------|----------|
| 5 | Transiciones fade entre escenas | `escenas/main_menu.gd` + todas las escenas |
| 6 | Balance tuning + playtesting | `juego/heist/heist_n1.json`, `heist_n2.json`, `hacker_n1.json`, `cyber_n1.json` |
| 7 | Export Windows (`export_presets.cfg`) | `export_presets.cfg` — instalar templates Godot 4.7 |
| 8 | Stats extendidas (tiempo, racha, intentos) | `juego/ataque/juego_ataque.gd` → persistir en `user://stats.cfg` |
| 9 | Sonidos y feedback audiovisual | Nuevos assets + llamado en `_ganar()`, `_perder()`, movimiento |
| 10 | Más niveles (Heist N3, Hacker N2) | `juego/heist/`, `juego/hacker/` — .tres + .json |

---

## Notas para Ziva

- No toques documentación .md (es responsabilidad de MiMo)
- No toques `core/agents/` ni `core/network/` sin consultarme primero
- Si encuentras algo que requiere decisión arquitectónica, pregúntame antes de implementar
- Prioriza Fase 0 ANTES de cualquier otra cosa
- No gastes tokens en análisis ni documentación
