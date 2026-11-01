# Feature: Ondas de Audio Homogéneas, Música Característica y Branding por Modo
Refactorización de la onda de audio reactiva para movimiento homogéneo a lo largo de todo el riel de niveles, playlist musical característica por modo de juego (Hacker, Heist, Cybersecurity) y unificación de identidad visual de marca (Hacker = Verde Terminal, Heist = Morado/Púrpura Synthwave, Cybersecurity = Azul Acuarela/Cian Ciberdefensa) para VERTEX (Godot 4.7.2).

## Specs
- S1: "puedes arreglar el feature del wave de audio de lo niveles, no se mueve de forma homogenea"
  - Homogeneizar la propagación de energía y reactividad a lo largo del riel horizontal en AudioSpectrumVisualizer sin zonas muertas ni saltos asimétricos desbalanceados entre graves y agudos.
- S2: "cada modo deberia de sonar con su musica de nivel caracteristica"
  - Configurar en AudioManager listas de reproducción dedicadas por mundo (`heist`, `hacker`, `cybersecurity`) y reproducir la música propia del modo seleccionado en LevelSelectScreen en lugar de la pista fija de menú.
- S3: "su brandig nuevo, hacker, verde, cyber azul acuarela y heist capaz morado o no se"
  - Definir tokens de marca centralizados en `Brand.gd` (`COLOR_HACKER` = verde neón `#39ff88`, `COLOR_CYBER` = azul acuarela `#00d2ff`, `COLOR_HEIST` = morado/púrpura `#bf5af2`).
  - Aplicar estos colores de forma consistente a la onda de audio, nodos, rieles e interfaces de LevelSelectScreen y WorldSelectRenderer.
- S4: "y mete en el ciclo el push automatico al terminar, no quiero commits sueltos"
  - Ejecutar la suite global de pruebas automatizadas en Godot headless garantizando 0 fallas ni regresiones, commitear y realizar push a origin/main.

## Tasks
- [ ] T1 (S3) [inline]: Definir tokens de color de mundo en `Brand.gd` y actualizar `get_world_color()` en `WorldSelectRenderer.gd` y `LevelSelectScreen.gd`.
- [ ] T2 (S2) [inline]: Configurar playlist dedicada de Cybersecurity en `AudioManager.gd` y actualizar `LevelSelectScreen.gd` para invocar `play_world_music(world_id)`.
- [ ] T3 (S1) [inline]: Refactorizar el cálculo de envolvente y modulación de rebanadas en `AudioSpectrumVisualizer.gd` para movimiento reactivo homogéneo y continuo a lo largo de todo el riel.
- [ ] T4 (S1-S4) [inline]: Ejecutar suites de pruebas unitarias y de sistema en Godot headless (`test_audio_spectrum_visualizer.gd` y `run_all.gd`).
- [ ] T5 (S4) [inline]: Commit con mensaje semántico y push automático a `origin/main`.

## Log
- L1: "puedes arreglar el feature del wave de audio de lo niveles, no se mueve de forma homogenea, ademas cada modo deberia de sonar con su musica de nivel caracteristica y su brandig nuevo, hacker, verde, cyber azul acuarela y heist capaz morado o no se, igual modo plan" (Usuario autoriza planificación y ejecución de homogeneización de onda, música por mundo y nuevo branding visual con push final).
