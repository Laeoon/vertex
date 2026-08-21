---
title: "Overview y auditoría pendiente"
created: "2026-08-16"
updated: "2026-08-16"
tags:
  - overview
  - audit
  - handoff
---

# Overview y auditoría pendiente

> Registro para el **orquestador maestro** (governanza nueva). Documenta el
> estado real del repo al cierre del slice 6: línea de commits, qué se
> verificó con el harness y qué **NO** pasó por auditoría independiente.

## 1. Estado general

- **Juego**: simulador Godot (GDScript) de ciberseguridad — modos atacante
  (heist/hacker/cyber), defensor y tutoriales. Rama `main`.
- **Modelo de trabajo usado hasta acá**: agente obrero (edita y reporta) +
  orquestador (audita, commitea, pushea). A partir de acá entra governanza
  nueva sobre cómo y dónde se trabaja.
- **Repositorio local**: 9 commits avanzados sobre `822b038` (post-puesta a
  punto) — **SIN push a GitHub** (indicación explícita del usuario
  2026-08-16: commits locales; el push quedó pendiente de la nueva
  governanza).
- **Línea de commits locales** (git log --oneline):

```
7cabe51 feat(slice-5): balance Heist N1-N3 con self-play + par por nivel
f25b7a9 feat(slice-4): implementar mostrar_ruta y congelar el renderer con equivalence
ddc24c6 docs(slice-3): documentar módulos, saldar deuda y nota de handoff
ae08d2d refactor(slice-3): descomponer orquestadores en módulos + fix defensor (Enmienda A)
911557c docs(deuda): registrar cobertura de tests del slice 2
840e64b test(cobertura): agregar tests de system, autoloads, datos de niveles y smoke de modos
c42188d docs(deuda): corregir estado de tests y marcar entradas no verificables
84c729a chore(limpieza): eliminar archivos obsoletos *_old e ignorar *.uid
3ccc471 refactor(tests): mover tests scene-based a tests/ y soportarlos en run_all.gd
822b038 chore(docs): puesta a punto de documentación
```

- **Slice 6**: commiteado locale tras este overview (mismo working tree).

## 2. Qué se verificó con el harness (auditoría del orquestador, 2026-08-16)

El orquestador corrió TODO de cero al cierre del slice 6 sobre el working
tree completo (slices 3-6):

| Verificación | Resultado |
|---|---|
| `run_all.gd` (suite) | **25/25** (0 fallidas, 0 errores) |
| `_test_ai_blocker_equivalence` | 19/19 |
| `_test_game_state_equivalence` | 14/14 |
| `_test_game_logic_equivalence` | 19/19 |
| `_test_hacker_logic_equivalence` | 18/18 |
| `_test_pursuit_system_equivalence` | 10/10 |
| `_test_defender_flow_equivalence` | 7/7 |
| `_test_mostrar_ruta` | 8/8 |
| `_test_game_renderer_equivalence` | 9/9 |
| `_test_par_estrellas` | 9/9 |
| `_test_progress_service_equivalence` | 14/14 |
| `_test_level_nav` (slice 6, nuevo) | 13/13 |
| `_test_tutorial_logic_equivalence` | 17/17 |
| `_test_glossary_equivalence` | 14/14 |
| `_test_tutorial_render_equivalence` | 34/34 |

- Los equivalence usan **claves seleccionadas** del dict (no comparan el dict
  completo), por eso `frame_data()` pudo añadir `has_next_level` sin romper
  goldens. Punto a revisar en auditoría profunda: si conviene congelar el
  contrato completo de `frame_data()`.
- `find_level` (slice 6) funciona en runtime: los `id` de los JSON de niveles
  coinciden con el nombre de archivo (`heist_n1` ↔ `heist_n1.json`).
- Guards de teclas N/L verificados por test: mid-partida no emiten; derrota
  sólo L; victoria ambos.

## 3. Auditoría P1-P5 (REALIZADA 2026-08-21 — resultado: PASS con hallazgos)

Alcance: diffs completos de los 4 commits del obrero (`ae08d2d`, `ddc24c6`,
`f25b7a9`, `7cabe51`) + verificación cruzada contra docs y datos. Los
slices 1-2 ya tenían auditoría propia (2026-08-16) y el slice 6 se audité al
committearlo. Resultado por commit:

- **`ae08d2d` slice 3 (descomposición + fix defensor): PASS.** Fix defensor
  correcto y bien razonado (`player_pos = start_node` real, skip de
  `initial_block()` documentado en el código, guard en `_on_move_requested`,
  early-return en `take_turn`). Extracción limpia: orquestadores quedaron en
  delegates+wiring puros; convenciones sostenidas (cero `print()` fuera del
  logger, patrón preload, class_name declarado pero consumido sin tipar).
- **`ddc24c6` docs slice 3: PASS** (docs + `.gitignore *.uid`).
- **`f25b7a9` slice 4: PASS.** `mostrar_ruta()` con guards correctos
  (defensor/runtime/graph null), respeta bloqueos vía runtime; historia del
  contrato actualizada coherentemente en `test_bugfixes_static`.
- **`7cabe51` slice 5: PASS con hallazgos.** Datos de balance verificados
  contra lo documentado (par 6/9, 7/11, 8/19; presupuesto 28; detección
  0.10-0.12 en los 4 nodos del `.tres`). Harness determinista con
  backup/restore de `user://`. **Hallazgo 1 (menor, doc)**: la regla de 2★
  decía "coste ≤1.5×par **o** turnos ≤1.25×par" pero el código hace
  `mini(cost_stars, turn_stars)` = semántica **Y** — wording corregido en
  docs [[06]] y [[14]] el 2026-08-21 (el comportamiento queda como está,
  congelado por `_test_par_estrellas`). **Hallazgo 2 (conocido)**:
  `ai_enabled = true` inerte en la rama defensora de `reset_state()` — sigue
  abierto como limpieza futura.

Pendiente de auditoría que esta pasada NO cubre: revisión de diseño profunda
(meta ≤300 vs contrato estado-en-nodo) y las dudas menores del obrero
(`visible_indices`, `scroll_by`, panel de info cosmético en defensor).

## 4. Dudas abiertas del obrero (sin resolver)

Ver [[17 - Handoff a orquestador]], sección Dudas: meta `game ≤300`
(estado-en-nodo como contrato vs módulos), `Glossary.visible_indices()`
aproxima sin wrap real, `scroll_by` duplica clamp de `process_scroll`,
`ai_enabled=true` inerte en rama defensora de `reset_state()`, efecto
colateral cosmético del panel de info de nodo en modo defensor con
start_node real.

## 5. Contrato congelado (NO romper sin actualizar equivalence)

Íntegro en [[17 - Handoff a orquestador]], sección "Contrato congelado":
estado mutable VIVE en el nodo juego (`juego_ataque.gd`, ~371 líneas),
servicios/renderer/tests leen vars del nodo directo; delegates consumidos por
duck-typing; tutorial_player (212) y sus vars públicas son contrato de los
3 equivalence de tutorials; módulos `RefCounted` + `setup(game)` con `_game`
sin tipar (`const preload` — class_name tipado rompe en CLI headless).

## 6. Reglas del proyecto vigentes

- Cero `print()` nuevos en código de juego (GameLogger es el canal; tests sí
  usan print — el runner parsea stdout).
- NO tocar `core/`, datos `.json`/`.tres` de niveles, ni `.tscn` de
  juego/menú.
- NO extender `run_all.gd` (tests nuevos van como escenas `_test_*`).
- NO borrar equivalence; cambio intencional → actualizar golden SÓLO en lo
  relacionado y documentarlo.
- Commits locales sin push hasta governanza nueva.

## 7. Pendientes de producto (heredados)

1. Balance del resto de mundos (hacker n1-n2, cyber n1, defense n1) con el
   harness — políticas propias por modo.
2. Transiciones fade / feedback audiovisual (roadmap).
3. i18n del contenido pedagógico (doc 16).
4. D1/D2 del doc 10 (cosméticos/no verificables).
5. Push de los commits locales (decisión de governanza).
6. Limpieza menor post-auditoría: `ai_enabled=true` inerte en defensor,
   naming legacy `nivel1_red.tres` (grafo de heist_n1), docs 01/02/13
   desactualizados (fade ya existe y está en uso).

## Enlaces

- [[17 - Handoff a orquestador]] — contrato, reglas, dudas, cómo verificar
- [[14 - Historial de cambios]] — entradas slice 3 a slice 6
- [[03 - Arquitectura]] — estructura de módulos
- [[10 - Bugs y deuda técnica]] — deuda saldada/registrada