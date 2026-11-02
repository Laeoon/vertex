# Feature: Unificación Numérica de Controles Tácticos (1, 2, 3, 4) y Actualización de Tutoriales
Unificación del esquema de controles en modo Defensor y actualización de textos formativos:
- Atajos numéricos directos en modo Defensor:
  * `[1]`: Modo Aristas (clic en líneas para bloquear).
  * `[2]`: Modo Firewall (clic en nodo para firewall permanente).
  * `[3]`: Modo Cuarentena (clic en nodo para aislarlo de raíz).
  * `[4]`: Radar / Revelar ruta óptima (niebla de guerra).
  *(Manteniendo `[F]`, `[C]`, `[P]` como alias para evitar fricción).*
- Actualización del HUD superior en `game_renderer.gd` (`[1] ARISTAS`, `[2] FIREWALL`, `[3] CUARENTENA`, `[4] RADAR`).
- Actualización de textos en tutoriales (`tut5_defense.json`, `tut_defensa_2.json`, `tut2_perimetro.json`, `tut1_movimiento.json`, `tut6_combined.json`, `tut4_hacker.json`).
- Verificación de suites en Godot headless (45/45) y commit/push.

## Specs
- S1: "hay algunos problemas con el firewall, seria mejor meter en vez de f c etc dejarlo en 12345 etc, en los numeros"
  - Mapear `KEY_1`, `KEY_2`, `KEY_3`, `KEY_4` en `input_handler.gd` para el modo defensor de forma análoga a los exploits en modo hacker.
  - Sincronizar el HUD para mostrar claramente la hilera numérica `[1] ARISTAS`, `[2] FIREWALL`, `[3] CUARENTENA`, `[4] RADAR`.
- S2: "cambia los tutoriales tambien, quiero mejor uso de los controles en todos los modos."
  - Actualizar los JSON de tutoriales defensivos y generales para enseñar los atajos numéricos directos además de los clicks en el HUD.
- S3: Suite completa de pruebas en verde y push automático a origin/main.

## Tasks
- [ ] T1 (S1) [inline]: Mapear `KEY_1`..`KEY_4` en `input_handler.gd` para modo defensor y actualizar HUD pills en `game_renderer.gd`.
- [ ] T2 (S2) [inline]: Actualizar menciones de controles en los tutoriales de defensa y generales (`tut5_defense.json`, `tut_defensa_2.json`, `tut2_perimetro.json`).
- [ ] T3 (S3) [inline]: Verificar suites de tutoriales y niveles en Godot headless (`test_defense_tutorials.gd`, `test_input_schemes.gd`, `run_all.gd`).
- [ ] T4 (S3) [inline]: Commit semántico y push automático a GitHub `origin/main`.

## Log
- L1: "hay algunos problemas con el firewall, seria mejor meter en vez de f c etc dejarlo en 12345 etc, en los numeros" y "cambia los tutoriales tambien, quiero mejor uso de los controles en todos los modos." (Usuario autoriza unificación de controles numéricos 1-4 en defensor y actualización de tutoriales).
