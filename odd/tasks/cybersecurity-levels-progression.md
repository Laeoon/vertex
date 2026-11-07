# Feature: Niveles de Ciberdefensa Blue Team (Cybersecurity N2, N3, N4, N5)
Diseño, balance y creación de los 3 niveles de defensa faltantes para el mundo Cybersecurity (`cyber_n2`, `cyber_n3`, `cyber_n4` y `cyber_n5` / boss) completando la curva de 5 niveles del mundo (Pilar 3 de VERTEX). Se orquesta delegando tareas discretas a Sonnet 5.5 (`gentle-ai-worker`).

## Specs
- S1: "crea las especificaciones para que uses sonet 5.5 en la creacion de los niveles, tu de orquestador, sonet de worker. go"
  - Diseñar los niveles de Cybersecurity para completar la progresión 1 a 5:
    * `cyber_n1`: "Defensa en Capas" (ya existente, dificultad 3).
    * `defense_n1`: "Defensa Perimetral" (ya existente, dificultad 2).
    * Organizar la secuencia formal en `LevelRegistry`:
      1. `defense_n1` (Dificultad 1 - Introducción a Blue Team y Bloqueos).
      2. `cyber_n1` (Dificultad 2 - Segmentación y Detección de Rutas).
      3. `cyber_n2` (Dificultad 3 - Movimiento Lateral y Contención por Cuarentena).
      4. `cyber_n3` (Dificultad 4 - Niebla de Guerra, EDR Forense e Interceptación de Telemetría).
      5. `cyber_n4` / `cyber_n5` (Dificultad 5 - Operación Zero Trust / Boss Defensivo ante Ataques MTD y Bypass).
- S2: Contrato técnico de cada nivel (.tres + .json):
  - Recursos de grafo `NetworkGraphResource` con nodos posicionados tácticamente en resolución 1280x720, tipos de nodos coherentes (`node_type`), aristas con `transit_cost` y `mitigation_capacity` y capacidades de corte mínimo.
  - JSON de configuración con `defender_mode: true`, `enemy_start_node`, `enemy_target_node`, `defender_blocks_per_turn`, `defender_block_duration`, `max_turns`.
- S3: Integración en registro y tests:
  - Registrar en `LevelRegistry.WORLDS["cybersecurity"]["levels"]`.
  - Registrar en la constante `NIVELES` de `tests/system/test_levels_data.gd`.
  - Actualizar pruebas si es necesario y validar que 100% de los tests pasen en verde.
- S4: Commit y push automático a GitHub al cerrar el ciclo.

## Tasks
- [x] T1 (S1, S2) [worker]: Crear topología y configuración de `cyber_n2` (Movimiento Lateral y Cuarentena) - JSON y TRES.
- [x] T2 (S1, S2) [worker]: Crear topología y configuración de `cyber_n3` (Niebla de Guerra y Forensics EDR) - JSON y TRES.
- [x] T3 (S1, S2) [worker]: Crear topología y configuración de `cyber_n4` (Operación Zero Trust / Boss Defensivo) - JSON y TRES.
- [x] T4 (S3) [inline]: Registrar los nuevos niveles en `LevelRegistry.gd` y en la suite `test_levels_data.gd`.
- [x] T5 (S3, S4) [verify]: Verificar suite global completa en Godot Headless y realizar commit semántico con push a `origin/main`.

## Log
- L1: "crea las especificaciones para que uses sonet 5.5 en la creacion de los niveles, tu de orquestador, sonet de worker. go" (Usuario autoriza especificaciones, delegación a Sonnet 5.5 como worker y ejecución completa con push).
