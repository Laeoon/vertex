# Feature: Pack Maestro Pre-Release v0.6.0 (Terminal CLI, Nivel Secreto Konami, VFX & Créditos)
Implementación integral de las 4 propuestas previas al lanzamiento v0.6.0 de VERTEX (Godot 4.7.2):
1. **P1 (Nivel Secreto & Konami Code)**: Nivel secreto `secret_root` ("Sector 0: Root Genesis") accesible vía código Konami (`↑ ↑ ↓ ↓ ← → ← → B A`) en `StartScreen` o tras desbloquear 15 estrellas, con topología de panal y desafío de supervivencia híbrido.
2. **P2 (Terminal CLI Táctica In-Game)**: Consola desplegable (`[~]` o botón en HUD) con comandos interactivos estilo UNIX (`help`, `netstat`, `traceroute <nodo>`, `dmesg`, `matrix`, `whoami`, `clear`).
3. **P3 (VFX & Feedback de Ruptura)**: Efectos procedurales de chispas neón en aristas bloqueadas/aisladas, pulsos fotónicos viajando por aristas activas y glitch/trauma ante brechas críticas.
4. **P4 (Pantalla de Créditos & Expediente Clasificado)**: Pantalla estética `CreditsScreen` accesible desde el Menú Principal con formato de expediente desclasificado, teletipo tipográfico y música ambiental.
5. **Verificación & Entrega**: Suite global en Godot Headless y commit con push automático a origin/main.

## Specs
- S1: "Nivel Secreto Konami Code"
  - En `StartScreen` (`start_screen.gd`), capturar la secuencia de teclas `[UP, UP, DOWN, DOWN, LEFT, RIGHT, LEFT, RIGHT, B, A]`.
  - Al completar la secuencia, reproducir sfx de alerta/éxito, toast temático `[!] ACCESO CLASIFICADO: SECTOR 0 DESBLOQUEADO` y lanzar el nivel secreto `res://juego/secret/secret_root.json` con grafo `secret_root.tres`.
- S2: "Terminal CLI Táctica In-Game"
  - Crear componente `TerminalOverlay` (`juego/ui/terminal_overlay.gd`) activable con `[~]` (tecla tilde/grave) o `[T]`.
  - Soporte de comandos deterministas: `help`, `status`, `netstat`, `traceroute`, `matrix`, `clear`, `whoami`, `exit`.
- S3: "VFX y Juice"
  - Generador procedural de partículas/chispas de datos en `GameRenderer` al cortar o bloquear enlaces y pulso de datos dinámico a lo largo de las aristas del grafo.
- S4: "Pantalla de Créditos / Expediente Clasificado"
  - Escena `escenas/menu/credits_screen.{gd,tscn}` integrada en `main_menu.gd` con botón "Créditos" o desde Opciones, presentando el lore, autor, licencias y música.
- S5: "Verificación y Push"
  - Todas las suites de pruebas pasando limpias (45+ tests) y sincronización con GitHub.

## Tasks
- [x] T1 (S1) [inline]: Diseñar nivel secreto `secret_root` (.json y .tres) e implementar detector del código Konami en `StartScreen.gd`.
- [x] T2 (S2) [inline]: Crear componente `TerminalOverlay.gd` con intérprete de comandos tácticos e integrarlo en `JuegoAtaque.gd`.
- [x] T3 (S3) [inline]: Implementar VFX de chispas en aristas y pulsos fotónicos viajando por enlaces en `GameRenderer.gd`.
- [x] T4 (S4) [inline]: Crear pantalla estética `CreditsScreen.gd` y registrar botón de acceso en el Menú Principal.
- [x] T5 (S5) [verify]: Verificar suite global en Godot headless y realizar commit semántico con push a `origin/main`.

## Log
- L1: "las 4" (Usuario autoriza la implementación de las cuatro propuestas completas para el pack previo a la v0.6.0).
