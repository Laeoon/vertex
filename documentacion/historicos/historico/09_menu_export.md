# 09 · Menú Principal y Exportación a Windows

## Motivación

Se necesita un ejecutable portable para demostrar el proyecto en otra
máquina (Windows). El Hito 1 ya está certificado con 2 sandboxes y 2
demos visuales, pero hasta ahora solo se podía ejecutar desde el editor
Godot apuntando manualmente a cada escena.

## Solución

### Menú principal

Se creó `escenas/main_menu.tscn` + `escenas/main_menu.gd` (Control)
con 4 opciones seleccionables con teclado:

| Opción | Escena destino | Descripción |
|---|---|---|
| Demo Visual (Explorador de Grafo) | `demo_visual_sandbox.tscn` | Grafo interactivo, estados, teclas A/D/Space/Tab |
| Demo Dual Weights | `demo_dual_sandbox.tscn` | Pesos duales, teclas Space/I/R |
| Sandbox A | `case_a_sandbox.tscn` | 7 asserts, direccionalidad |
| Sandbox B | `case_b_sandbox.tscn` | 9 asserts, independencia de pesos |

**Navegación:**
- Flechas arriba/abajo para seleccionar
- Enter/Space para abrir
- ESC para salir del programa (desde el menú)
- Q para volver al menú (desde las demos)
- ESC para salir del programa (desde las demos)

### Modificaciones a escenas existentes

| Archivo | Cambio |
|---|---|
| `project.godot` | `main_scene` → `escenas/main_menu.tscn` |
| `case_a_test.gd` | `get_tree().quit()` → vuelve al menú tras 2 segundos |
| `case_b_test.gd` | ídem |
| `demo_visual_test.gd` | KEY_Q → va al menú; se agregó KEY_ESCAPE para salir |
| `demo_dual_test.gd` | ídem |

Las aserciones y la lógica principal de los sandboxes NO se modificaron.

### Exportación a Windows

Se creó `export_presets.cfg` con:
- **Preset:** "Windows Desktop", plataforma `windows`
- **Arquitectura:** x86_64
- **Resolución:** 1280x720, no redimensionable
- **Salida:** `/home/leonardo/SimuladorGrafos.exe`
- PCK externo (no embebido)

**Archivos generados:**
- `SimuladorGrafos.exe` (100 MB) — contiene el engine
- `SimuladorGrafos.pck` (119 KB) — recursos del proyecto

Ambos archivos deben copiarse juntos al USB. El .exe busca el .pck
en el mismo directorio.

### Notas técnicas

- Se instaló el template de exportación de Windows descargado desde
  GitHub Releases (`Godot_v4.6.3-stable_export_templates.tpz`).
- Los templates se alojan en `~/.local/share/godot/export_templates/`.
- El formato de `export_presets.cfg` requiere `platform="Windows Desktop"`
  (con espacio y mayúsculas), no `"windows"` en minúscula.
