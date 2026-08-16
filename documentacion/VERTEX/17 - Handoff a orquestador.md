---
title: "Handoff a Orquestador"
created: "2026-08-16"
updated: "2026-08-16"
tags:
  - handoff
  - agent
  - status
---

# Handoff a Orquestador

> Nota del agente obrero (sesiones P1–P5 del slice 3 + slice 4) para el agente
> orquestador cuando retome el proyecto. Estado al cierre del slice 4.

## Estado del repo

- **Slice 3 y slice 4 completos y commiteados localmente (SIN push a GitHub,
  indicación del usuario 2026-08-16: commits locales, no push).**
- Commits: `refactor(slice-3)` + `docs(slice-3)` (código/tests y docs del
  slice 3) y `feat(slice-4)` + docs (mostrar_ruta real + equivalence del
  renderer). Si falta alguno, ver `git status` / `git log --oneline`.
- Rama `main`. Sin push. `.zcode/` ignorado.

## Qué se hizo (resumen ejecutivo)

1. **Descomposición completa** de los dos orquestadores (P1–P5):
   - `juego/ataque/juego_ataque.gd`: **371 líneas** (fue ~1000 en la alfa).
   - `juego/tutorials/tutorial_player.gd`: **212 líneas**.
   - Módulos nuevos: `game_state.gd` (367), `game_logic.gd` (256),
     `hacker_logic.gd` (163), `tutorial_logic.gd` (310), `glossary.gd` (133),
     `tutorial_render.gd` (666), `tutorial_input.gd` (114).
2. **Renderer por datos**: `GameRenderer.draw_frame(d)` orquesta el frame con
   el dict puro de `GameState.frame_data()`. Se eliminaron TODOS los
   callables (`is_blocked_func`/`is_in_path_func`/`find_node_res_func`).
3. **Fix defensor "Enmienda A"** (P4): start_node real (sin sentinel
   `&"DEFENSOR"`), IA no bloquea al inicio en defensor, `_on_move_requested`
   no-op en defensor. Congelado por `_test_defender_flow_equivalence`.
4. **`mostrar_ruta()`** —historia: stub silencioso (origen) → push_warning
   (slice 1) → no-op documentado (P5) → **implementación real (slice 4)**:
   `GameState.mostrar_ruta()` puebla `current_path` con la ruta óptima
   respetando bloqueos; no-op en defensor. Cubierto por `_test_mostrar_ruta`
   y `test_bugfixes_static` (contrato actualizado).
5. **Equivalence del renderer (slice 4)**:
   `_test_game_renderer_equivalence` — golden de `frame_data()` +
   smoke de `draw_frame` vía `notification(NOTIFICATION_DRAW)` (en headless
   `_draw` no se dispara solo; esa es la vía legal para testearlo).

## Cómo verificar (todo en verde al cierre)

```
godot --headless --script res://tests/runner/run_all.gd   # 25/25
godot --headless res://tests/ataque/_test_game_state_equivalence.tscn        # 14
godot --headless res://tests/ataque/_test_game_logic_equivalence.tscn        # 19
godot --headless res://tests/ataque/_test_hacker_logic_equivalence.tscn      # 18
godot --headless res://tests/ataque/_test_defender_flow_equivalence.tscn     # 7
godot --headless res://tests/ataque/_test_mostrar_ruta.tscn                  # 8
godot --headless res://tests/ataque/_test_game_renderer_equivalence.tscn     # 9
godot --headless res://tests/tutorials/_test_tutorial_logic_equivalence.tscn # 17
godot --headless res://tests/tutorials/_test_glossary_equivalence.tscn       # 14
godot --headless res://tests/tutorials/_test_tutorial_render_equivalence.tscn # 34
```

## Contrato congelado (NO romper sin actualizar los equivalence tests)

- **El estado mutable VIVE en el nodo juego** (`juego_ataque.gd`): servicios
  (AIBlocker, DefenderBrain, PursuitSystem), GameRenderer y tests leen
  `_game.player_pos`, `_game.blocked_edges`, `inst.pursuers`,
  `inst.max_turns`, etc. directo. Por eso el orquestador no baja de ~370
  líneas: ~115 son vars del contrato + wiring de señales + `_init_defender_mode`.
- **Delegates del orquestador** consumidos por duck-typing (`has_method`) o
  tests: `reset_state`, `_target_actual`, `_find_node_resource`,
  `mostrar_ruta`, `_vecinos_jugador`, `_mover_jugador`, `_is_blocked`,
  `_block_edge`, `_unblock_edge`, `_limpiar_bloqueos_expirados`,
  `_edge_en_posicion`, `_nodo_en_posicion`, `_nodo_en_posicion_firewall`,
  `_perder`, `_auto_select_vecino`, `_cycle_neighbor`,
  `_scan_selected_node`, `_use_hacker_exploit`,
  `_check_hacker_consequences`, `_on_move_requested`,
  `_on_defender_block_edge`, `_on_defender_resolve_turn`,
  `_notify_tutorial_input`, `_on_enemy_moved`.
- En tutorials: los métodos públicos de `tutorial_player` y sus vars
  (`steps`, `current_step_index`, `_waiting_for_action`...) son el contrato
  (`test_tutorial_system` + 3 equivalences).
- Patrón de módulos: `RefCounted` + `setup(game)` con `_game` sin tipar
  (const preload; el class_name tipado rompe en CLI headless sin editor).

## Reglas vigentes del proyecto (heredadas P1–P5)

- Cero `print()` nuevos en código de juego (tests usan `print`, GameLogger en juego).
- NO tocar `core/`, datos `.json`/`.tres` de niveles, ni `.tscn` de juego/menú.
- NO extender `run_all.gd` (los tests nuevos van como escenas `_test_*`).
- NO borrar tests de equivalencia; si un cambio de comportamiento es
  intencional, actualizar el golden SOLO en lo relacionado y documentarlo.
- Commits locales sin push (hasta nueva orden del usuario).

## Dudas abiertas (del obrero, sin resolver)

1. Meta "game ≤300" no alcanzada (371): ver contrato congelado arriba.
   Requiere una decisión de diseño (mover estado a los módulos y romper el
   patrón) — no hacer sin el orquestador/usuario.
2. Convención `print()` en tests: se interpretó como correcta (el runner
   parsea resultados por stdout).
3. Menores de P1: `Glossary.visible_indices()` aproxima 1 línea/término sin
   wrap real; `scroll_by` duplica aritmética de clamp de `process_scroll`.

## Próximos pasos recomendados (prioridad)

1. **Balance y playtesting** — prioridad ALTA del roadmap (doc 02), depende
   de niveles jugables (ya los hay: 7). Requiere criterio de diseño del
   orquestador/usuario (dificultad objetivo por nivel).
2. Transiciones fade / feedback audiovisual (roadmap, media/baja).
3. i18n del contenido pedagógico de tutoriales + glosario (doc 16).
4. D1/D2 del doc 10 (cosméticos/no verificables).
5. Opcional técnico (sólo con decisión explícita): romper el patrón
   estado-en-nodo para bajar `juego_ataque.gd` de 371 a ≤300 — ver duda 1.

## Enlaces

- [[03 - Arquitectura]] — estructura de módulos actualizada
- [[14 - Historial de cambios]] — entradas slice 3 y slice 4
- [[10 - Bugs y deuda técnica]] — saldados de los slices 3 y 4
