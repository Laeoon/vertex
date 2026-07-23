# VERTEX — Guia Completa de Assets e Integracion

**Version:** 1.0  
**Motor:** Godot 4.6.3  
**Resolucion base:** 1366x768 (adaptativo)  
**Estilo:** Neon cyberpunk rustico  
**Fecha:** 2026-06-21

---

## INDICE

1. [Estructura de carpetas](#1-estructura-de-carpetas)
2. [Convencion de nombres](#2-convencion-de-nombres)
3. [Lista completa de assets por prioridad](#3-lista-completa-de-assets)
4. [Especificaciones tecnicas por asset](#4-especificaciones-tecnicas)
5. [Guia paso a paso para el artista](#5-guia-para-el-artista)
6. [Animaciones: como crearlas](#6-animaciones)
7. [Integracion en Godot](#7-integracion-en-godot)
8. [Testing y verificacion](#8-testing)
9. [Checklist de entrega](#9-checklist)

---

## 1. ESTRUCTURA DE CARPETAS

```
assets_vertex_placeholders/
├── manifest.json                    ← Levantado por Godot al inicio
├── backgrounds/
│   └── bg_mainmenu_neon.png         ← Fondo del MainMenu
├── ui/
│   ├── icons/                       ← Iconos de botones y UI
│   │   ├── ui_icon_play.png
│   │   ├── ui_icon_tutorial.png
│   │   ├── ui_icon_options.png
│   │   ├── ui_icon_missionlog.png
│   │   ├── ui_icon_exit.png
│   │   ├── ui_icon_confirm.png
│   │   ├── ui_icon_back.png
│   │   ├── ui_icon_replay.png
│   │   ├── ui_icon_export.png
│   │   ├── ui_icon_step.png
│   │   ├── ui_icon_pause.png
│   │   ├── ui_icon_sound_on.png
│   │   ├── ui_icon_sound_off.png
│   │   ├── ui_icon_fullscreen.png
│   │   ├── ui_icon_lock.png
│   │   ├── ui_icon_unlock.png
│   │   ├── ui_icon_settings.png
│   │   ├── star_0.png               ← Sin estrellas
│   │   ├── star_1.png               ← 1 estrella
│   │   ├── star_2.png               ← 2 estrellas
│   │   └── star_3.png               ← 3 estrellas (max)
│   ├── panels/                      ← Paneles redimensionables
│   │   ├── panel_dialog.9.png       ← NinePatch principal
│   │   ├── floating_text_panel.png  ← Panel de tutoriales
│   │   ├── floating_arrow_top.png
│   │   ├── floating_arrow_right.png
│   │   ├── floating_arrow_left.png
│   │   ├── floating_arrow_bottom.png
│   │   ├── level_tile_frame.png     ← Marco del tile de nivel
│   │   ├── tooltip_panel.png
│   │   └── modal_bg.png             ← Fondo de modales
│   └── fonts/                       ← Fuentes tipograficas
│       ├── vertex_regular.ttf
│       ├── vertex_bold.ttf
│       └── vertex_mono.ttf
├── thumbnails/                      ← Previews de niveles (pequenos)
│   ├── level_heist_preview.png
│   ├── level_hacker_preview.png
│   └── level_cybersec_preview.png
├── levels/                          ← Assets especificos por nivel
│   ├── heist/
│   │   └── frame_heist.png
│   ├── hacker/
│   │   └── frame_hacker.png
│   └── cybersec/
│       └── frame_cybersec.png
├── hud/                             ← Elementos del HUD in-game
│   ├── topbar_left.png
│   ├── topbar_right.png
│   ├── topbar_center.png
│   ├── alert_base.png
│   ├── alert_glow.png
│   ├── alert_lvl_1.png
│   ├── alert_lvl_2.png
│   ├── alert_lvl_3.png
│   ├── cost_meter.png
│   ├── cost_bar_bg.png
│   ├── cost_bar_fill.png
│   ├── turn_icon.png
│   ├── minimap_frame.png
│   ├── minimap_bg.png
│   ├── waypoint_icon.png
│   ├── target_icon.png
│   └── start_icon.png
├── nodes/                           ← Iconos de nodos del grafo
│   ├── node_camera.png
│   ├── node_firewall.png
│   ├── node_adminpc.png
│   ├── node_db.png
│   ├── node_honeypot.png
│   ├── node_router.png
│   ├── node_shutdown.png
│   ├── node_default.png
│   ├── node_pursuer.png
│   ├── node_player.png
│   ├── edge_blocked.png
│   ├── edge_highlight.png
│   ├── edge_glow_cyan.png
│   └── edge_glow_magenta.png
├── fx/                              ← Efectos visuales
│   ├── neon_scanlines.png
│   ├── glitch_overlay.png
│   ├── vignette.png
│   ├── particle_neon.png
│   └── particle_spark.png
├── portraits/                       ← Retratos de personajes
│   ├── portrait_heist.png
│   ├── portrait_hacker.png
│   └── portrait_cybersec.png
└── animations/                      ← Spritesheets / frames
    ├── logo_glitch/
    │   └── logo_glitch.png          ← Spritesheet 6 frames
    ├── level_tile_hover/
    │   └── level_tile_hover.png     ← Spritesheet 8 frames
    ├── pursuer_trail/
    │   └── pursuer_trail.png        ← Spritesheet 6 frames
    ├── alert_pulse/
    │   └── alert_pulse.png          ← Spritesheet 3 frames
    └── floating_arrow_bounce/
        └── floating_arrow_bounce.png ← Spritesheet 6 frames
```

**Total de archivos a crear: ~55 archivos**

---

## 2. CONVENCION DE NOMBRES

**Formato:** `tipo_contexto_nombre[_variant].ext`

**Reglas:**
- Todo en minusculas
- Separador: guion bajo `_`
- Sin espacios ni caracteres especiales
- Extensiones: `.png` para imagenes, `.ttf` para fuentes, `.json` para datos

**Ejemplos correctos:**
- `ui_icon_play.png`
- `bg_mainmenu_neon.png`
- `node_adminpc.png`
- `hud_alert_base.png`

**Ejemplos incorrectos:**
- `Icon-Play.png` (guion)
- `UI_Icon_Play.png` (mayusculas)
- `ui icon play.png` (espacio)

---

## 3. LISTA COMPLETA DE ASSETS

### PRIORIDAD ALTA (16 archivos) — Necesarios para MainMenu y Tutoriales

| # | Archivo | Tamano | Descripcion |
|---|---------|--------|-------------|
| 1 | `backgrounds/bg_mainmenu_neon.png` | 1366x768 | Fondo del MainMenu. Neons sobre ciudad oscura. |
| 2 | `ui/panels/logo_vertex.png` | 1200x300 | Titulo "VERTEX" en estilo neon glitch. |
| 3 | `thumbnails/level_heist_preview.png` | 640x360 | Preview nivel Heist (estilo corporativo). |
| 4 | `thumbnails/level_hacker_preview.png` | 640x360 | Preview nivel Hacker (estilo neon verde). |
| 5 | `thumbnails/level_cybersec_preview.png` | 640x360 | Preview nivel Cybersec (estilo amber). |
| 6 | `ui/panels/floating_text_panel.png` | 420x140 | Panel para bloques de texto de tutoriales. |
| 7 | `ui/panels/floating_arrow_top.png` | 64x32 | Flecha apuntando arriba. |
| 8 | `ui/panels/floating_arrow_right.png` | 64x32 | Flecha apuntando derecha. |
| 9 | `ui/panels/floating_arrow_left.png` | 64x32 | Flecha apuntando izquierda. |
| 10 | `ui/panels/floating_arrow_bottom.png` | 64x32 | Flecha apuntando abajo. |
| 11 | `ui/icons/ui_icon_play.png` | 64x64 | Icono Play (triangulo). |
| 12 | `ui/icons/ui_icon_tutorial.png` | 64x64 | Icono Tutorial (libro interrogante). |
| 13 | `ui/icons/ui_icon_options.png` | 64x64 | Icono Opciones (engranaje). |
| 14 | `ui/icons/ui_icon_missionlog.png` | 64x64 | Icono Log de Misiones (bitacora). |
| 15 | `ui/icons/ui_icon_exit.png` | 64x64 | Icono Salir (puerta/flecha). |
| 16 | `ui/panels/panel_dialog.9.png` | 512x256 | NinePatch principal (margins 24px). |

### PRIORIDAD MEDIA (24 archivos) — HUD, Nodos, FX

| # | Archivo | Tamano | Descripcion |
|---|---------|--------|-------------|
| 17 | `ui/icons/star_0.png` | 64x64 | Estrella vacia. |
| 18 | `ui/icons/star_1.png` | 64x64 | 1 estrella llena. |
| 19 | `ui/icons/star_2.png` | 64x64 | 2 estrellas llenas. |
| 20 | `ui/icons/star_3.png` | 64x64 | 3 estrellas llenas. |
| 21 | `ui/icons/ui_icon_confirm.png` | 64x64 | Icono Confirmar (check). |
| 22 | `ui/icons/ui_icon_back.png` | 64x64 | Icono Volver (flecha izq). |
| 23 | `ui/icons/ui_icon_pause.png` | 64x64 | Icono Pausa. |
| 24 | `ui/icons/ui_icon_sound_on.png` | 64x64 | Icono Sonido On. |
| 25 | `ui/icons/ui_icon_sound_off.png` | 64x64 | Icono Sonido Off. |
| 26 | `ui/icons/ui_icon_fullscreen.png` | 64x64 | Icono Pantalla Completa. |
| 27 | `nodes/node_camera.png` | 64x64 | Nodo camara de seguridad. |
| 28 | `nodes/node_firewall.png` | 64x64 | Nodo firewall. |
| 29 | `nodes/node_adminpc.png` | 64x64 | Nodo PC del admin. |
| 30 | `nodes/node_db.png` | 64x64 | Nodo Base de Datos. |
| 31 | `nodes/node_honeypot.png` | 64x64 | Nodo honeypot (defensor). |
| 32 | `nodes/node_default.png` | 64x64 | Nodo generico por defecto. |
| 33 | `nodes/node_pursuer.png` | 64x64 | Nodo perseguidor (IA). |
| 34 | `nodes/node_player.png` | 64x64 | Nodo jugador. |
| 35 | `hud/topbar_left.png` | 400x80 | Barra superior izquierda. |
| 36 | `hud/topbar_right.png` | 400x80 | Barra superior derecha. |
| 37 | `hud/alert_base.png` | 128x128 | Widget de alerta (base). |
| 38 | `hud/alert_glow.png` | 128x128 | Glow del widget de alerta. |
| 39 | `hud/cost_meter.png` | 48x48 | Icono de coste. |
| 40 | `hud/minimap_frame.png` | 320x180 | Marco del minimapa. |
| 41 | `fx/neon_scanlines.png` | 512x512 | Overlay de scanlines (tileable). |
| 42 | `ui/panels/level_tile_frame.png` | 360x200 | Marco del tile de nivel. |

### PRIORIDAD BAJA (13 archivos) — Portraits, FX extra, Animaciones

| # | Archivo | Tamano | Descripcion |
|---|---------|--------|-------------|
| 43 | `portraits/portrait_heist.png` | 512x512 | Retrato personaje Heist. |
| 44 | `portraits/portrait_hacker.png` | 512x512 | Retrato personaje Hacker. |
| 45 | `portraits/portrait_cybersec.png` | 512x512 | Retrato personaje Cybersec. |
| 46 | `fx/glitch_overlay.png` | 512x512 | Overlay de glitch. |
| 47 | `fx/vignette.png` | 1366x768 | Viñeta oscura para bordes. |
| 48 | `fx/particle_neon.png` | 32x32 | Particula neon (cyan/magenta). |
| 49 | `fx/particle_spark.png` | 16x16 | Particula de chispa. |
| 50 | `animations/logo_glitch/logo_glitch.png` | 7200x300 | Spritesheet 6 frames (1200x300 c/u). |
| 51 | `animations/level_tile_hover/level_tile_hover.png` | 2880x200 | Spritesheet 8 frames (360x200 c/u). |
| 52 | `animations/pursuer_trail/pursuer_trail.png` | 384x64 | Spritesheet 6 frames (64x64 c/u). |
| 53 | `animations/alert_pulse/alert_pulse.png` | 384x128 | Spritesheet 3 frames (128x128 c/u). |
| 54 | `animations/floating_arrow_bounce/floating_arrow_bounce.png` | 384x32 | Spritesheet 6 frames (64x32 c/u). |
| 55 | `ui/icons/ui_icon_lock.png` | 64x64 | Icono candado cerrado. |

---

## 4. ESPECIFICACIONES TECNICAS

### Formatos de imagen
- **PNG** con canal alpha para todo lo que tenga transparencia.
- **PNG** sin alpha para fondos opacos (backgrounds).
- **SVG** aceptable para icons (pero preferir PNG para compatibilidad).

### Resoluciones base
- **Icons UI:** 64x64 (crear tambien 32x32 como fallback)
- **Thumbnails nivel:** 640x360
- **Backgrounds:** 1366x768 (o multiplos para HiDPI)
- **Portraits:** 512x512
- **HUD elements:** ver tabla en seccion 3

### Colores clave de la paleta

| Color | Hex | Uso |
|-------|-----|-----|
| Neon Cyan | `#00FFD5` | Acentos principales, borde selected |
| Magenta Profundo | `#FF2D95` | Highlights, alertas criticas |
| Oxido Oscuro | `#1A1A1A` a `#221818` | Fondos rústicos |
| Amarillo Amber | `#FFB84D` | Warnings, defensor |
| Verde Electrico | `#39FF14` | Hacker, exito |
| Rojo Neón | `#FF073A` | Peligro, game over |
| Gris Metal | `#4A4A52` a `#2D2D35` | Paneles, bordes |

### NinePatch (panel_dialog.9.png)
- Margenes de seguridad: **24px** por lado.
- El area central (464x208) se estira sin deformar bordes.
- Marcar los 9-patch en Godot o en la herramienta de edicion de imagenes.

---

## 5. GUIA PARA EL ARTISTA

### Paso 1: Fondos (empezar por aqui)
1. **bg_mainmenu_neon.png** — Ciudad cyberpunk de noche, vista aerea o calle. Neons visibles. Textura rústica sutil (ruido metalico). Paleta oscura con toques cyan/magenta.
2. **vignette.png** — Degradado radial negro a transparente. Se superpone al fondo del MainMenu.

### Paso 2: Logo
1. **logo_vertex.png** — Palabra "VERTEX" en tipografia angular/geometrica. Efecto neon brillante (glow cyan). Textura rústica sutil (grietas o ruido). Fondo transparente.

### Paso 3: Thumbnails de niveles (3 archivos)
Cada thumbnail es un "screenshot stylized" del nivel:
- **Heist:** Grafo con nodos corporativos, tonos azul-gris, lineas limpias.
- **Hacker:** Grafo con nodos verdes/neon, fondo oscuro, estilo terminal.
- **Cybersec:** Grafo con nodos amber, paneles de control, estilo dashboard.

### Paso 4: Paneles UI
- **floating_text_panel.png** — Rectangulo semitransparente con borde neon cyan. Esquinas redondeadas. Textura sutil de metal rústico.
- **panel_dialog.9.png** — Mismo estilo pero mas grande (512x256). NinePatch margins 24px.
- **Flechas (4):** Flechas simples en estilo neon. 64x32 c/u.

### Paso 5: Icons UI (16+ icons)
Estilo: lineales, borde neon cyan o magenta, fondo transparente.
- Play: triangulo pointing right
- Tutorial: libro con interrogante
- Options: engranaje
- MissionLog: bitacora o scroll
- Exit: puerta con flecha
- Confirm: check mark
- Back: flecha izquierda
- Pause: dos barras verticales
- Stars: estrellas (vacia, 1, 2, 3 llenas)
- Lock/Unlock: candado abierto/cerrado

### Paso 6: Nodos del grafo (10 icons)
- Cada nodo es un icono 64x64 que representa su funcion.
- Estilo consistente: borde neon, interior semitransparente.
- Colores: cyan para neutral, rojo para peligro, verde para objetivo, amber para firewall.

### Paso 7: HUD
- **topbar_*.png** — Barra horizontal semitransparente con borde neon.
- **alert_*.png** — Widget circular con nivel de alerta (1-3).
- **cost_meter.png** — Icono de moneda o chip.

### Paso 8: Portraits (placeholders)
- Siluetas estilizadas con color distintivo por personaje.
- Heist: cyan, mascara/mask
- Hacker: magenta, hood + laptop
- Cybersec: amber, auriculares + panel

### Paso 9: FX
- **neon_scanlines.png** — Lineas horizontales finas, tileable, opacity baja.
- **glitch_overlay.png** — Bloques de color desplazados (efecto glitch).
- **particle_*.png** — Small sprites for particles.

### Paso 10: Animaciones (spritesheets)
Ver seccion 6 para instrucciones detalladas.

---

## 6. ANIMACIONES

### Que son los spritesheets
Un spritesheet es UNA sola imagen que contiene todos los frames de una animacion, dispuestos en fila o en grilla. Godot los importa y crea la animacion automaticamente.

### Estructura de frames

**logo_glitch** (6 frames):
```
Frame: 0     1     2     3     4     5
Efecto: Normal Glitch1 Normal Glitch2 Glitch3 Normal
```
- Tamano total: 7200x300 (6 frames de 1200x300)
- FPS: 12 (dura 0.5 segundos)
- Loop: NO (se reproduce una vez al cargar MainMenu)

**level_tile_hover** (8 frames):
```
Frame: 0    1    2    3    4    5    6    7
Efecto: Base Glow Up Glow Full Glow Down Glow Base
```
- Tamano total: 2880x200 (8 frames de 360x200)
- FPS: 24 (dura 0.33 segundos)
- Loop: NO (se reproduce al hacer hover sobre un tile)

**pursuer_trail** (6 frames):
```
Frame: 0   1   2   3   4   5
Efecto: Fade In Full Full Fade Out Gone Gone
```
- Tamano total: 384x64 (6 frames de 64x64)
- FPS: 24
- Loop: SI (se repite mientras el perseguidor se mueve)

**alert_pulse** (3 frames):
```
Frame: 0    1    2
Efecto: Base Pico Base
```
- Tamano total: 384x128 (3 frames de 128x128)
- FPS: 8
- Loop: SI (pulso continuo mientras alerta activa)

**floating_arrow_bounce** (6 frames):
```
Frame: 0   1   2   3   4   5
Efecto: Up  Mid Down Mid Up  Mid
```
- Tamano total: 384x32 (6 frames de 64x32)
- FPS: 12
- Loop: SI (bucle continuo en tutoriales)

### Como crear spritesheets

**Opcion A: TexturePacker (recomendado)**
1. Exportar cada frame como PNG individual.
2. Abrir TexturePacker → New Project.
3. Arrastrar frames → empacar como "Godot".
4. Exportar: Image + JSON.
5. Renombrar image a nombre del spritesheet.

**Opcion B: A mano en Aseprite/Photoshop**
1. Crear canvas del tamano total (ej: 7200x300 para logo_glitch).
2. Colocar frames de izquierda a derecha.
3. Guardar como PNG.

**Opcion C: Herramienta online**
- https://www.codeandweb.com/texturepacker
- https://shatteredplane.github.io/spritesheet-generator/

---

## 7. INTEGRACION EN GODOT

### Paso 1: Copiar assets al proyecto
```bash
# Desde la raiz del proyecto Godot
cp -r assets_vertex_placeholders/ res://assets_vertex_placeholders/
```

### Paso 2: Importar en Godot
1. Abrir Godot.
2. Ir a FileSystem → navegar a `res://assets_vertex_placeholders/`.
3. Verificar que todos los archivos se importaron.
4. Para spritesheets: hacer clic derecho → "Import As" → "SpriteSheet" o configurar en Import.

### Paso 3: Configurar NinePatch
1. Abrir `panel_dialog.9.png` en Godot.
2. En Inspector → Scene → NinePatch.
3. Establecer margins: 24px por lado.

### Paso 4: Configurar AnimatedSprite2D (para animaciones)
1. Crear nodo `AnimatedSprite2D`.
2. En Inspector → SpriteFrames → New SpriteFrames.
3. Doble clic en SpriteFrames → Add animations.
4. Cargar spritesheet como frame por frame o usar import automatico.

### Paso 5: Cargar manifest.json
En `MainMenu.gd`:
```gdscript
var manifest = {}
func _ready():
    var file = FileAccess.open("res://assets_vertex_placeholders/manifest.json", FileAccess.READ)
    manifest = JSON.parse_string(file.get_as_text())
    # Usar manifest para cargar texturas
    var bg = load("res://assets_vertex_placeholders/" + manifest["mainmenu"]["background"])
    $Background.texture = bg
```

### Paso 6: Fallbacks
Si un asset falta, usar un color solido o el icono por defecto:
```gdscript
func load_asset(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        return load(path)
    else:
        # Fallback: rectangulo de color
        var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
        img.fill(Color.MAGENTA)  # Magenta = asset faltante
        return ImageTexture.create_from_image(img)
```

---

## 8. TESTING

### Test de manifest (headless)
Verificar que todos los archivos del manifest existen:
```gdscript
# test_manifest_check.gd
extends SceneTree
func _init():
    var manifest = load_json("res://assets_vertex_placeholders/manifest.json")
    var missing = []
    for key in manifest:
        var path = "res://assets_vertex_placeholders/" + manifest[key]
        if not ResourceLoader.exists(path):
            missing.append(path)
    if missing.size() == 0:
        print("PASS: Todos los assets existen")
    else:
        print("FAIL: Faltan %d assets" % missing.size())
        for m in missing:
            print("  - %s" % m)
    quit()
```

### Ejecutar test
```bash
godot --headless --script res://test_manifest_check.gd
```

---

## 9. CHECKLIST DE ENTREGA

Antes de integrar, verificar:

- [ ] `manifest.json` existe y es JSON valido
- [ ] Todas las rutas del manifest apuntan a archivos reales
- [ ] Todos los archivos PNG tienen canal alpha donde es necesario
- [ ] Los spritesheets tienen frames de tamano uniforme
- [ ] El NinePatch tiene margins de 24px marcados
- [ ] Los icons son 64x64 (con fallbacks 32x32)
- [ ] Los thumbnails son 640x360
- [ ] El fondo del MainMenu es 1366x768
- [ ] No hay espacios ni mayusculas en nombres de archivo
- [ ] Las animaciones tienen frames numerados secuencialmente

---

## RESUMEN RAPIDO

| Categoria | Cantidad | Tamano aprox |
|-----------|----------|--------------|
| Backgrounds | 1 | ~2 MB |
| UI Icons | 20 | ~1.5 MB |
| UI Panels | 8 | ~3 MB |
| Thumbnails | 3 | ~1 MB |
| HUD | 15 | ~2 MB |
| Nodes | 14 | ~1.5 MB |
| FX | 5 | ~1 MB |
| Portraits | 3 | ~1.5 MB |
| Animations | 5 spritesheets | ~3 MB |
| Fonts | 3 | ~0.5 MB |
| **TOTAL** | **~77 archivos** | **~17 MB** |
