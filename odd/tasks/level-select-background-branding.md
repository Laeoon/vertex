# Feature: Branding Temático Integral de Fondo para Selectores de Nivel
Parametrización de `CyberBackground` para soportar `theme_color` y `bg_color` personalizados por modo de juego (Hacker = Verde Terminal / fondo oscuro verdoso, Heist = Morado Synthwave / fondo oscuro violeta, Cybersecurity = Azul Acuarela / fondo azul medianoche) en `LevelSelectScreen`, junto con la adaptación cromática de conexiones, hints, bordes y botones para VERTEX (Godot 4.7.2).

## Specs
- S1: "ahora solo falta cambiar el fondo de cada selector de nivel, no solo las ondas del color si no todo el brandig"
  - Extender `CyberBackground.gd` (`draw(canvas, vp, delta, theme_color, bg_color)`) para que la retícula táctica, los hologramas 3D, el hex-badge, el plexus espacial, las partículas y las líneas de escaneo se tiñan del color temático del mundo en lugar del cian fijo.
  - En `Brand.gd`: Agregar función de fondo temático `Brand.get_world_bg_color(world_id)` con tintes oscuros armónicos según el modo.
  - En `LevelSelectScreen.gd`: Pasar el color del mundo a `_cyber_bg.draw()`, teñir las líneas de conexión del riel de niveles, la marquesina de selección, el botón de volver [ESC] y los hints de navegación con la paleta activa.
- S2: "y mete en el ciclo el push automatico al terminar, no quiero commits sueltos"
  - Verificar suite global completa en Godot Headless (45 suites limpias) y realizar commit semántico con push a `origin/main`.

## Tasks
- [ ] T1 (S1) [inline]: Extender `Brand.gd` con `get_world_bg_color()` y variantes tonales por modo.
- [ ] T2 (S1) [inline]: Parametrizar `CyberBackground.gd` para aceptar `theme_color` y `bg_color` en `draw()` y en sus sub-rutinas sin romper compatibilidad.
- [ ] T3 (S1) [inline]: Actualizar `LevelSelectScreen.gd` para dibujar el fondo temático integral y teñir conexiones, hints y botones.
- [ ] T4 (S1, S2) [inline]: Verificar `test_cyber_background.gd` y la suite global de 45 pruebas en Godot headless.
- [ ] T5 (S2) [inline]: Commit semántico y push automático a `origin/main`.

## Log
- L1: "ahora solo falta cambiar el fondo de cada selector de nivel, no solo las ondas del color si no todo el brandig, despues de eso hacemos los niveles faltantes de cyber" (Usuario autoriza branding integral de fondo en selectores de nivel antes de pasar a los niveles de cyber).
