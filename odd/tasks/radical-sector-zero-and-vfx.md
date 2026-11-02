# Feature: Rediseño Radical de "Sector 0: Root Genesis", VFX Vivos y Arte Glitch
Transformación completa de la experiencia audiovisual y jugable de VERTEX para romper el molde plano:
1. **Motor Visual Continuo**: `queue_redraw()` permanente en `juego_ataque._process()` garantizando que los pulsos fotónicos, el jitter eléctrico y las partículas se animen a 60 FPS sin depender del mouse.
2. **Atmósfera "Kernel Void / Glitch" para Sector 0**:
   - Fondo negro abisal con lluvia volumétrica de volcado de memoria (Hex Dump: `0xDEADBEEF`, `0xC001CAFE`, `SEGFAULT`, `PAGE_FAULT`, `KERNEL_PANIC`).
   - Nodos que rotan proceduralmente en el canvas (anillos de energía en contrarrotación, núcleos pulsantes en carmesí carnicero y ámbar radioactivo).
   - Aristas vivas con jitter eléctrico de alta frecuencia (relámpagos lógicos de sobretensión) en lugar de polilíneas estáticas.
3. **Mecánica "Memory Collapse" (Entropía de Kernel)**:
   - En `secret_root`: Cada 2 turnos, una región del grafo sufre un colapso de memoria y se desintegra en el vacío, forzando al jugador a maniobrar contra el reloj antes de que el mapa desaparezca bajo sus pies.
4. **Verificación y Entrega**: 45+ tests pasando en headless y push automático a GitHub `origin/main`.

## Specs
- S1: "mata la liga pues, lucete, quiero que sea algo que no haya visto."
  - Eliminar por completo el comportamiento estático en partida: fotones vivos viajando a velocidad armónica continua.
  - Implementar en `GameRenderer` un renderizador especializado para `secret_root` con estética "Kernel Void": nodos octogonales rotatorios, relámpagos de jitter en aristas y telemetría glitch.
  - Diseñar el efecto de desintegración por colapso de memoria en el nivel secreto.
- S2: Verificación de la suite global en Godot headless garantizando cero regresiones y push a origin/main.

## Tasks
- [ ] T1 (S1) [inline]: Activar el loop de redibujado continuo a 60 FPS en `juego_ataque._process()` y afinar la física de los fotones en `GameRenderer.gd`.
- [ ] T2 (S1) [inline]: Implementar en `GameRenderer.gd` el renderizado de vanguardia para Sector 0 (lluvia de hex dump, nodos de energía rotatorios y aristas eléctricas de relámpago).
- [ ] T3 (S1) [inline]: Diseñar topología cinemática asimétrica para `secret_root.tres` y mecánica de Kernel Panic.
- [ ] T4 (S2) [inline]: Ejecutar suite completa en Godot headless (45+ tests).
- [ ] T5 (S2) [inline]: Commit semántico y push automático a GitHub `origin/main`.

## Log
- L1: "mata la liga pues, lucete, quiero que sea algo que no haya visto." (Usuario autoriza rediseño visual y mecánico disruptivo).
