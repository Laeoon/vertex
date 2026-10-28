# Feature: Visualizador de Ondas de Audio Reactivas (Pilar 2)
Implementación de AudioEffectSpectrumAnalyzer en AudioManager y visualizador táctico procedural de espectro de audio en fondos de selectores de niveles y mundos para VERTEX (Godot 4.7.2).

## Specs
- S1: "Configurar AudioEffectSpectrumAnalyzer en el bus Music dentro de AudioManager sin romper pruebas estáticas ni ejecución headless."
- S2: "Exponer en AudioManager métodos seguros get_spectrum_instance() y get_spectrum_magnitudes(bands, min_freq, max_freq) con suavizado y protección contra bus inexistente."
- S3: "Crear componente visualizador AudioSpectrumVisualizer (juego/ui/audio_spectrum_visualizer.gd) con renderizado vectorial procedural (barras de ecualizador táctico, curvas de onda reactivas y telemetría de frecuencias)."
- S4: "Integrar el visualizador en el fondo de LevelSelectScreen (level_select_screen.gd) y WorldSelectRenderer (world_select_renderer.gd) con paleta temática según el mundo activo."
- S5: "Crear suite de pruebas automatizadas tests/system/test_audio_spectrum_visualizer.gd que verifique la captura de bandas, el comportamiento seguro ante dummy driver (headless) y la API pública sin crash."
- S6: "Verificación de la suite global de 45 pruebas en Godot Headless y push automático del commit final a GitHub origin/main."

## Tasks
- [x] T1 (S1, S2) [worker]: Extender AudioManager con AudioEffectSpectrumAnalyzer y API de telemetría de frecuencias.
- [x] T2 (S3) [worker]: Crear AudioSpectrumVisualizer con dibujo procedural de barras, picos de amortiguación y ondas tácticas.
- [x] T3 (S5) [worker]: Crear suite de pruebas tests/system/test_audio_spectrum_visualizer.gd y verificar pase limpio.
- [x] T4 (S4) [worker]: Integrar AudioSpectrumVisualizer en LevelSelectScreen y WorldSelectRenderer adaptando el color al mundo.
- [x] T5 (S1-S6) [verify]: Verificar suite global completa en Godot Headless y ejecutar push automático a GitHub.

## Log
- L1: "vamos con lo que sigue, y mete en el ciclo el push automatico al terminar, no quiero commits sueltos" (Usuario autoriza Pilar 2: Visualizador de ondas de audio reactivas con push automático mandatario al cierre).
