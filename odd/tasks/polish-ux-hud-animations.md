# Feature: Pulido Maestro de UX, HUD Táctico, Animaciones y Medallas
Programa integral de refinamiento final para VERTEX (Godot 4.7.2):
1. **Modo Cuarentena y Controles de Defensa**: Auto-desenganche, cancelación por click derecho/vacío, halos visuales de nodos aislables e indicador activo en HUD.
2. **HUD In-Game Consola Táctica**: Barra superior interactiva con botones clickeables (Aristas, Firewall, Cuarentena, Radar), contador gráfico de presupuesto de bloqueos y feedback claro de turno y telemetría EDR.
3. **Animaciones y Juiciness (Game Feel)**: Interpolación de movimiento del atacante con Tween, efectos visuales de ruptura/desconexión en aristas y pulso de trauma/shockwave en alertas críticas.
4. **Logros, Medallas y Easter Eggs**: Sincronización de logros de la campaña completa de 15 niveles en ProfileScreen y registro de telemetría de juego.
5. **Verificación y Entrega**: Pruebas automatizadas en Godot headless y push automático a GitHub `origin/main`.

## Specs
- S1: "arreglar bugs (como el modo cuarentena, nada intuitivo y aveces se queda pegado)"
  - Auto-desenganche: al aislar un nodo exitosamente o presionar clic derecho o clic en el vacío, cancelar automáticamente el modo cuarentena y regresar al cursor estándar de bloqueo de aristas.
  - Resaltar visualmente en el canvas los nodos elegibles para aislamiento con un halo ámbar/dorado de advertencia mientras `quarantine_mode` esté activo.
  - Evitar estados inconsistentes en `input_handler.gd` y `defender_brain.gd`.
- S2: "el hud in game"
  - Rediseñar el HUD del modo defensor con botones/pills tácticas clickeables (`[BLOQUEAR ARISTA]`, `[FIREWALL (F)]`, `[CUARENTENA (C)]`, `[REVELAR (P)]`).
  - Indicador visual prominente del modo activo (glow en la pill correspondiente).
  - Contador visual de bloqueos disponibles en el turno (`● ● ○`).
- S3: "animaciones"
  - Interpolar la posición visual del atacante (`enemy_visual_pos`) con un Tween suave (0.22s) para mostrar la trayectoria de avance y movimiento lateral en lugar de teletransporte instantáneo.
  - Pulso visual de desconexión en aristas cortadas por cuarentena o bloqueadas.
- S4: "lo demas como niveles secretos, ester eggs, medallas, son features ... vamos a hacer todo."
  - Verificar y vincular las 10 medallas de `BadgeRegistry` con la pantalla de perfil (`ProfileScreen`).
  - Registrar easter egg táctico en la base de datos o pantalla de inicio.
- S5: "y mete en el ciclo el push automatico al terminar, no quiero commits sueltos"
  - Pruebas automatizadas limpias en headless y push a `origin/main`.

## Tasks
- [ ] T1 (S1) [inline]: Corregir UX del Modo Cuarentena en `input_handler.gd`, `game_logic.gd` y `juego_ataque.gd` (auto-desenganche, click derecho/vacío para cancelar, halos de nodos elegibles).
- [ ] T2 (S2) [inline]: Rediseñar el HUD in-game en `game_renderer.gd` con botones tácticos clickeables, pills de modo activo y contador de bloques.
- [ ] T3 (S3) [inline]: Implementar interpolación visual de desplazamiento del atacante con Tween y feedback de desconexión en `juego_ataque.gd` y `game_renderer.gd`.
- [ ] T4 (S4) [inline]: Afinar medallas, estadísticas y easter egg táctico en `badge_registry.gd` y `profile_renderer.gd`.
- [ ] T5 (S5) [verify]: Verificar suite global en Godot headless (45+ tests en verde) y push automático a GitHub `origin/main`.

## Log
- L1: "ya creo que tenemos el producto a 100% solo falta arreglar bugs( como el modo cuarentena, nada intuitivo y aveces se queda pegado) , animaciones y el hud in game. lo demas como niveles secretos, ester eggs, medallas, son features ... vamos a hacer todo." (Usuario autoriza la ejecución secuencial completa de pulido de UX, HUD, animaciones y medallas con push final).
