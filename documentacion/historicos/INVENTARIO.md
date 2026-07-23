# INVENTARIO — Mapa de repositorios y código disponible

## Estructura actual del proyecto

Hay dos lugares con código de este proyecto. Este documento explica
qué hay en cada uno para evitar confusiones.

---

## 1. Repositorio activo (GitHub → `main`)

**Ruta:** `/home/leonardo/nuevo-proyecto-de-juego/`
**Remote:** `https://github.com/Laeoon/proyecto-.git`
**Último commit:** `832226d` — "feat: menu principal + export Windows del Hito 1"

### Contenido actual (Hito 1 completo + infraestructura)

```
core/network/           # NetworkNode/Edge/GraphResource + NetworkRuntime
escenas/                # main_menu.tscn + main_menu.gd
sandboxes/
  case_a_connectivity_unidirectional/   # 7 asserts (direccionalidad)
  case_b_edge_dual_weights/             # 9 asserts (pesos duales)
  case_demo_visual/                     # Grafo interactivo con teclas A/D/Tab/Space
  case_demo_dual_weights/               # Pesos duales interactivo con Space/I/R
docs/
  arquitectura/         # Convenciones, diseño de Hito 2
  historico/            # Docs de cada componente (09 docs hasta ahora)
  CHANGELOG.md
export_presets.cfg      # Export a Windows (genera SimuladorGrafos.exe + .pck)
```

---

## 2. Backup histórico (NO tocar — solo referencia)

**Ruta:** `/home/leonardo/Documentos/SH antes del GUI/`
**Propósito:** Código de hitos 2-5 que existía antes de las demos visuales.
**Regla:** NO copiar archivos de aquí al proyecto activo. Usar como
referencia de implementación, no como fuente de archivos.

### Contenido del backup

```
core/
  network/             # Mismo NetworkRuntime que el activo
  agents/
    min_heap.gd                  # Min-heap binario (Hito 2)
    defensive_pathfinder.gd      # Dijkstra (Hito 2)
    strategic_analyzer.gd        # Edmonds-Karp (Hito 3)
  autoloads/
    events.gd                    # Event Bus (Hito 4)
  fsm/                           # Máquina de estados (Hito 4)
  integration/                   # Integración E2E (Hito 5)

sandboxes/
  case_c_dijkstra_pathfinding/   # 13 asserts (Hito 2)
  case_d_mincut_analysis/        # ~25 asserts (Hito 3)
  case_e_event_bus/              # 10 tests (Hito 4)
  case_f_integration_e2e/        # Tests E2E (Hito 5)
```

### Lo que el backup NO tiene (vs. el repositorio activo)

- `escenas/` (menú principal)
- `sandboxes/case_demo_visual/`
- `sandboxes/case_demo_dual_weights/`
- `export_presets.cfg`
- `docs/historico/` (solo tiene `CONTEXTO_PROYECTO.md`)
- Documentación actualizada (CHANGELOG, INDICE, README, GUIA, ROADMAP)

---

## 3. Mapa de hitos y su ubicación

| Hito | Descripción | En activo | En backup |
|---|---|---|---|
| 1 | Grafo estático, direccionalidad, pesos duales | ✅ Completo + demos | ✅ Sin demos |
| 2 | Dijkstra + MinHeap + Sandbox C | ❌ No implementado | ✅ Código existente |
| 3 | Edmonds-Karp + Sandbox D | ❌ No implementado | ✅ Código existente |
| 4 | Event Bus + FSM + Sandbox E | ❌ No implementado | ✅ Código existente |
| 5 | Integración E2E + Sandbox F | ❌ No implementado | ✅ Código existente |

---

## 4. Flujo de trabajo recomendado

1. Todo el desarrollo nuevo se hace **exclusivamente** en
   `/home/leonardo/nuevo-proyecto-de-juego/`
2. El backup es **solo consulta** — se puede leer, NO copiar archivos
3. Cuando se implemente Hito 2, usar el backup como guía de
   implementación, pero escribir el código desde cero (política de
   "fresh implementation" para mantener consistencia con las demos,
   el menú y la documentación actual)
4. Commits siempre al `main` de GitHub

---

## 5. Archivos generados (no se suben a git)

```
/home/leonardo/SimuladorGrafos.exe   # Export Windows (100 MB)
/home/leonardo/SimuladorGrafos.pck   # PCK del export (119 KB)
.godot/                              # Caché del editor (en .gitignore)
```
