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

## 3. Qué NO está auditado (pendiente — registros para el orquestador maestro)

- **P1-P5 del slice 3**: el obrero reportó el trabajo y quedó commiteado
  (`ae08d2d` refactor + `ddc24c6` docs), pero **no hubo auditoría
  independiente del diff completo** (revisión línea por línea de la
  descomposición, delegates, wiring, contrato congelado).
- **Slices 4 y 5**: mismos reportes/commits (`f25b7a9`, `7cabe51`) sin
  auditoría independiente del diff ni revisión de decisiones de balance.
- Los equivalence **congelan** el comportamiento pero no auditan calidad:
  naming, convenciones, tamaño de módulos, duplicación, uso de
  `print()`/GameLogger, cero `class_name` tipado en módulos, etc.
- **Commit por commit**: no se hizo revisión commit-a-commit de los 9
  commits locales (qué incluye cada uno, mensajes, granularidad de
  work-units).
- **Dudas abiertas del obrero, sin resolver** (ver 17 - Handoff, sección
  Dudas): meta `game ≤300` (estado-en-nodo como contrato vs módulos),
  `Glossary.visible_indices()` aproxima sin wrap real, `scroll_by` duplica
  clamp de `process_scroll`, `ai_enabled=true` inerte en rama defensora de
  `reset_state()`, efecto colateral cosmético del panel de info de nodo en
  modo defensor con start_node real.

## 4. Contrato congelado (NO romper sin actualizar equivalence)

Íntegro en [[17 - Handoff a orquestador]], sección "Contrato congelado":
estado mutable VIVE en el nodo juego (`juego_ataque.gd`, ~371 líneas),
servicios/renderer/tests leen vars del nodo directo; delegates consumidos por
duck-typing; tutorial_player (212) y sus vars públicas son contrato de los
3 equivalence de tutorials; módulos `RefCounted` + `setup(game)` con `_game`
sin tipar (`const preload` — class_name tipado rompe en CLI headless).

## 5. Reglas del proyecto vigentes

- Cero `print()` nuevos en código de juego (GameLogger es el canal; tests sí
  usan print — el runner parsea stdout).
- NO tocar `core/`, datos `.json`/`.tres` de niveles, ni `.tscn` de
  juego/menú.
- NO extender `run_all.gd` (tests nuevos van como escenas `_test_*`).
- NO borrar equivalence; cambio intencional → actualizar golden SÓLO en lo
  relacionado y documentarlo.
- Commits locales sin push hasta governanza nueva.

## 6. Pendientes de producto (heredados)

1. Balance del resto de mundos (hacker n1-n2, cyber n1, defense n1) con el
   harness — políticas propias por modo.
2. Transiciones fade / feedback audiovisual (roadmap).
3. i18n del contenido pedagógico (doc 16).
4. D1/D2 del doc 10 (cosméticos/no verificables).
5. Push de los 9+1 commits locales (decisión de governanza).

## Enlaces

- [[17 - Handoff a orquestador]] — contrato, reglas, dudas, cómo verificar
- [[14 - Historial de cambios]] — entradas slice 3 a slice 6
- [[03 - Arquitectura]] — estructura de módulos
- [[10 - Bugs y deuda técnica]] — deuda saldada/registrada