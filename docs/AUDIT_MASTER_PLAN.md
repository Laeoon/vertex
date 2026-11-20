# Informe Maestro de Auditoría Técnica, Arquitectura y Game Design — VERTEX

> **Estado:** Fase de Auditoría (Solo Lectura) completada. Base de ejecución sobre rama `feat/fase-1-cimientos`.  
> **Motor:** Godot 4.7 / GDScript 2.0 (49 clases registradas).

---

## 1. Radiografía del Proyecto

### Stack y punto de entrada
- **Motor y lenguaje:** Godot `4.7` (`Forward Plus`, viewport base `1280x720`, stretch `canvas_items`/`expand`), 100% GDScript 2.0, sin addons ni plugins externos (`project.godot`).
- **Flujo de entrada:** `escenas/main_menu/start_screen.tscn` → `escenas/main_menu.tscn` → pantallas de navegación (`level_select_screen`, `tutorials_menu`, `profile` / La Bóveda, `database`, `options`) → escena única de gameplay `juego/ataque/escena_juego.tscn` (orquestada por `juego/ataque/juego_ataque.gd`, que ejecuta los 4 modos: Heist, Hacker, Cybersecurity y Sector 0).
- **Autoloads actuales (6):** `GameLogger`, `Events` (solo 4 señales de grafos), `SceneParams` (bolsa global mutable de ~33 campos), `LocaleManager` (`es`/`en`/`pt`), `SceneTransition` (`CanvasLayer` 128) y `AudioManager` (buses `Master`/`Music`/`SFX`, analizador FFT-1024, pool de 8 SFX con prioridad + síntesis procedural/WAV, reproductor único `_music_player`).
- **Testing:** Runner headless propio (`tests/runner/run_all.gd` + `tests/runner/_run_one.gd`) con watchdog de 12 s y aislamiento por subproceso.

### Fortalezas actuales
1. **Identidad estética y temática cohesiva:** Estética de consola SOC/kernel oscura (`juego/ui/brand.gd`, tipografía `JetBrains Mono`, renderizado vectorial procedural 2D, paleta diferenciada por sector y visualizadores FFT reactivos).
2. **Núcleo de gameplay y algoritmos sólido:** Modelo de grafos con doble peso (`transit_cost` para Dijkstra y `mitigation_capacity` para Edmonds-Karp), 3 roles jugables bien diferenciados más modos avanzados (`MultiStageDirector` y `MultiDaemonController`).
3. **Persistencia de slots bien pensada en su base:** `juego/system/slot_manager.gd` ya soporta 3 slots aislados, snapshots atómicos y respaldos `.bak` con checksum SHA-256.
4. **Cimiento real para La Bóveda:** `escenas/menu/profile.gd` y los 5 módulos de `escenas/menu/vault/` ya utilizan contenedores nativos `Control` de Godot 4.7, demostrando que la migración fuera del `_draw()` monolítico es viable.

### Principales cuellos de botella
1. **Persistencia rota en La Bóveda (P0):** `profile.gd` busca `/root/SlotManager` (inexistente, pues `SlotManager` es `RefCounted` estático), escribe en `user://profile.cfg` global rompiendo los 3 slots y muestra estadísticas/niveles hardcodeados.
2. **God-objects y estado mutable por duck-typing:** 7 scripts superan las 800 líneas (`game_renderer.gd` 1,802 L, `main_menu.gd` 1,173 L, `database_renderer.gd` 1,073 L, `level_select_screen.gd` 1,029 L, `profile_renderer.gd` 945 L, `juego_ataque.gd` 916 L, `input_handler.gd` 826 L), con `GameState.frame_data()` empaquetando >50 claves en un `Dictionary` sin tipar.
3. **Sistemas paralelos desconectados:** Doble registro de insignias (`badge_registry.gd` vs `vault_modules.gd`), doble instancia de `UnixShellEngine`/`TerminalVFS` (`terminal_overlay.gd` vs `vault_academia_tab.gd`), catálogo musical duplicado con nombres `.ogg` desincronizados, doble transición Dive-In/Dive-Out y opciones divergentes (`options.gd` vs `pause_overlay.gd` vs `audio_manager.gd`).
4. **Fricción extrema para crear niveles:** Añadir un nivel exige sincronizar manualmente `.tres` (coordenadas en píxeles crudos + `load_steps`), `.json` sin validación cruzada, `level_registry.gd`, `cinematic_registry.gd` y `progress_util.gd`, además del límite fijo de 5 niveles/acto en `level_select_screen.gd`.

---

## 2. Matriz de Auditoría Técnica

> Prioridades: **P0** (bloqueante/corrupción de estado) · **P1** (alto riesgo/desbloqueo de roadmap) · **P2** (deuda relevante) · **P3** (menor).

### 2.1 Pulir (UX, limpieza, legibilidad, casos borde, estabilidad inmediata)

| Archivo/Módulo | Problema concreto | Acción recomendada | Prioridad |
| :--- | :--- | :--- | :---: |
| `juego/ataque/game_state.gd:145-167` · `juego/ataque/juego_ataque.gd:344-360` | `_edge_en_posicion()` duplicado con umbrales divergentes (30 px vs 24 px). | Consolidar una única función canónica en `GameState` y delegar desde `juego_ataque.gd`. | **P1** |
| `escenas/main_menu/tutorials_menu.gd:40-56` | Variables locales sombrean los autoloads `SceneParams` y `SceneTransition`. | Eliminar el shadowing y consumir directamente los autoloads globales. | **P1** |
| `juego/ataque/juego_ataque.gd:155-168` | 9 propiedades sin tipado estático estricto en GDScript 4.x. | Declarar tipos explícitos en todas las variables y firmas afectadas. | **P1** |
| `juego/ataque/input_handler.gd:708` | Acceso directo a `game.bonus_nodes` / `game.bonus_visitados` sin guarda defensiva rompe `test_hybrid_controls_and_tutorials.gd`. | Usar lectura segura (`"bonus_nodes" in game`) con fallback a `[]`. | **P1** |
| `escenas/menu/profile.gd:192-201` | `build_level_rows()` es un stub hardcodeado (siempre 5 filas, 3★, completado). | Poblar el listado desde progreso real del slot activo vía `VaultStore`/`ProgressUtil`. | **P1** |
| `escenas/main_menu/start_screen.gd:144` | Invoca SFX `"hover"`, inexistente en `AudioManager` (fallo silencioso). | Registrar `"hover"` en `AudioManager` o mapear a un cue existente. | **P2** |
| `escenas/main_menu.gd:153-170` · `escenas/main_menu/operator_advisor.gd:98` | Hint de Sector 0 erróneo (menciona `.ENC` en vez de Nodos Dorados) y `Free Ops` ausente en `LevelRegistry.WORLDS`. | Corregir texto de desbloqueo de Sector 0 y alinear visibilidad/registro de `free_ops`. | **P2** |
| `juego/ui/vault_modules.gd:601-669` | `build_hex_dump_rows()` coloca la clave siempre en `row_idx == file_idx` con 1 solo señuelo. | Reemplazar por `HexHackEngine` procedural con semilla, múltiples señuelos y brackets. | **P2** |
| `escenas/menu/profile.gd:346-352` | Pestaña 05 (`COSMÉTICOS`) expuesta como placeholder de mantenimiento. | Sustituir por `VaultCustomizationTab` (o ocultar bajo feature flag hasta Fase 3). | **P3** |

### 2.2 Mejorar (optimización, desacoplamiento, estado, audio, persistencia)

| Archivo/Módulo | Problema concreto | Acción recomendada | Prioridad |
| :--- | :--- | :--- | :---: |
| `escenas/menu/profile.gd:58-70,234-237` | Busca `/root/SlotManager` (siempre `null`); `_stats_cfg` nunca carga y muestra estadísticas falsas. | Llamar directamente a métodos estáticos de `SlotManager` mediante `VaultStore`. | **P0** |
| `escenas/menu/profile.gd:204-216` | Lee/escribe en `user://profile.cfg` global en vez de `SlotManager.get_profile_path()`. | Migrar a rutas por slot + añadir `vault.cfg` a `SlotManager.SLOT_FILE_NAMES`. | **P0** |
| `juego/ui/vault_modules.gd:680-689` · `juego/utils/progress_util.gd:25-48` | MusicBox consulta `progress.get("total_stars", 0)`, clave que `ProgressUtil` nunca genera (siempre `0`). | Calcular y exponer `total_stars` en `ProgressUtil.cargar_progreso()` con test headless. | **P1** |
| `juego/ui/vault_modules.gd:313-403` · `core/autoloads/audio_manager.gd:39-76` | Nombres `.ogg` de MusicBox no coinciden con los reales de `AudioManager`; pistas fijadas no persisten. | Unificar en `MusicCatalog`, validar rutas `.ogg` en test y persistir pistas fijadas en `vault.cfg`. | **P1** |
| `escenas/menu/profile.gd:34` | `_enc_unlocked` vive solo en RAM y se pierde al salir de la escena. | Persistir `unlocked_files` y cooldown de lockout por slot en `VaultStore`. | **P1** |
| `juego/system/badge_registry.gd` · `juego/ui/vault_modules.gd:13-206` | Dos sistemas de insignias incompatibles (10 con evaluador vs 24 sin evaluador; 4 hardcodeadas en `profile.gd:68`). | Consolidar catálogo único en `BadgeRegistry` + `BadgeService` reactivo/determinista por slot. | **P1** |
| `core/autoloads/scene_transition.gd:220-351` · `escenas/main_menu.gd:47-56` | Lógica y estado de transición Dive-In/Dive-Out duplicados. | Centralizar únicamente en `SceneTransition` y retirar la copia de `main_menu.gd`. | **P2** |
| `core/autoloads/audio_manager.gd` | Un solo `_music_player` sin crossfade provoca cortes bruscos entre contextos. | Añadir crossfade por Tween (0.35 s) y FSM explícita `MusicMode { WORLD_CONTEXT, MUSICBOX_PREVIEW }`. | **P2** |
| Renderers `_draw()` (9 archivos) | `queue_redraw()` incondicional a 60 FPS incluso en menús estáticos. | Aplicar redibujado por dirty-flag en vistas estáticas; mantener 60 FPS solo con animaciones/FFT activos. | **P2** |

### 2.3 Adaptar (refactors necesarios para soportar Menú Interno, Pipeline de Niveles y Acto II)

| Archivo/Módulo | Problema concreto | Acción recomendada | Prioridad |
| :--- | :--- | :--- | :---: |
| `juego/system/level_registry.gd` · `juego/system/level_select_screen.gd:60` | Autoría de niveles exige editar 4+ archivos manuales y `level_select_screen.gd` hardcodea 5 niveles/acto. | Soportar carga dinámica de `*.level.json` v2 y desacoplar el layout del selector del número fijo de 5. | **P0** |
| `juego/secret/secret_root.json:19-30` · `juego/system/level_manager.gd:89` · `juego/ataque/juego_ataque.gd:260-279` | Esquema JSON divergente (`eventos_alarma` vs `eventos`; `node_positions` ignorado con override ad-hoc). | Unificar lectura en `LevelManager` (`eventos_alarma` con fallback `eventos` + soporte `node_positions`) y eliminar el override de `juego_ataque.gd`. | **P1** |
| `core/autoloads/scene_params.gd` · `juego/system/level_manager.gd` | Bolsa global mutable de ~33 campos propensa a estado residual entre escenas. | Encapsular transición en un `Resource` tipado (`LevelLaunchContext`) con reset explícito. | **P1** |
| `juego/ataque/game_state.gd:196-250` · `escenas/menu/vault/vault_*_tab.gd` | `frame_data()` devuelve `Dictionary` sin tipar (>50 claves); módulos mutan `_game` y tabs mutan campos privados de `Profile`. | Introducir `RenderFrameSnapshot` tipado y contratos explícitos (`VaultStore` / señales) en los tabs de La Bóveda. | **P1** |
| `escenas/menu/options.gd` · `juego/ataque/pause_overlay.gd` · `core/autoloads/audio_manager.gd` | Opciones duplicadas con defaults divergentes (`60/70` vs `80`) y `input_scheme` ausente en `options.gd`. | Crear autoload `SettingsManager` como fuente única de `user://settings.cfg`. | **P1** |
| God-objects (`game_renderer.gd`, `main_menu.gd`, `database_renderer.gd`, `level_select_screen.gd`, `profile_renderer.gd`, `juego_ataque.gd`, `input_handler.gd`) | 7 scripts de 826–1,802 líneas mezclan datos, estado, hit-testing y renderizado. | Extraer incrementalmente catálogos de datos (`ENTRIES`, mundos) y sub-renderers respetando el tope ~350 L por módulo. | **P1** |
| `juego/ui/terminal_overlay.gd` · `escenas/menu/vault/vault_academia_tab.gd` | Instancian `UnixShellEngine`/`TerminalVFS` por separado sin estado compartido. | Compartir núcleo único (`TerminalVFS` con sandbox/clonado + `UnixShellEngine` con `ShellResult`) para Overlay, Consola y Academia. | **P2** |
| `core/locale/{es,en,pt}.json` | Solo ~110 claves básicas; narrativa, códice, niveles y Bóveda están hardcodeados en español. | Extraer cadenas a tablas por dominio (`ui`, `story`, `vault`, `levels`) con español neutro canónico y verificación headless de claves. | **P2** |

### 2.4 Evolucionar (cambios estructurales de largo plazo)

| Archivo/Módulo | Problema concreto | Acción recomendada | Prioridad |
| :--- | :--- | :--- | :---: |
| Pipeline de contenido (`LevelRegistry`, `CinematicRegistry`, `.tres`/`.json`) | Escalar a Acto II+, Free Ops o paquetes de comunidad es frágil sin validación automática. | Arquitectura 100% data-driven (`*.level.json` v2 + manifiesto) con validador headless (`tests/validate_levels.gd`) de esquema, referencias, Dijkstra y Edmonds-Karp. | **P1** |
| `core/autoloads/events.gd` | Bus global limitado a 4 señales de grafos; fuerza acoplamiento directo en UI y metajuego. | Evolucionar `Events` a bus tipado por dominios (Gameplay, Progresión, Vault/CLI, Audio, Settings). | **P1** |
| `project.godot` · `juego/ataque/input_handler.gd` | Sin `InputMap`; keycodes hardcodeados y hit-testing manual sobre `Rect2`. | Migrar a acciones declarativas en `InputMap` con soporte para perfiles remapeables y navegación teclado/gamepad. | **P1** |
| Arquitectura UI híbrida | Falta `Theme` `.tres`; 9 pantallas en `_draw()` puro dificultan accesibilidad, escalado y mantenimiento. | Crear `Theme` `.tres` derivado de `Brand` (tokens dinámicos) y migrar pantallas de menú a `Control` componibles, dejando `_draw()` para el grafo y visualizadores. | **P2** |
| Subsistemas internos (`profile.gd`, `vault_*`, `terminal_overlay.gd`, `options.gd`) | Acoplados a escenas específicas sin ciclo de vida común. | Formalizar arquitectura de servicios/sub-apps (`VaultStore`, `SettingsManager`, `BadgeService`, `UnixShellEngine`) desacoplados de la vista. | **P2** |

---

## 3. Desbloqueo Creativo (Historia y Niveles)

### 3.1 Diagnóstico narrativo y resolución de contradicciones de canon
1. **AEGIS (Comandante humano SOC en `cinematic_registry.gd` vs. Protocolo autónomo en `DOSSIER_AEGIS.enc`):** *Máscara operativa sobre perfil biométrico.* CORDON encapsuló el protocolo defensivo autónomo bajo la voz y credenciales del comandante humano original.
2. **KAIN (Renegado en `OPERATORS` vs. Arquitecto atrapado en `codec_s0_1b..3`):** *Reescritura forense de logs.* KAIN diseñó la purga como *kill-switch* de contención; los 3 fragmentos invirtieron el registro oficial para encerrarlo en Sector 0.
3. **VEX (Freelance vs. Ex-ingeniero de VERTEX):** *Expediente purgado.* Su historial laboral fue borrado tras AS-65000; EXFIL lo contrató a ciegas por coincidencia con su propia arquitectura.

### 3.2 Columna vertebral narrativa e integración diegética
- **Acto I (existente):** al completar los 3 mundos o los 3 Nodos Dorados, disparar `act2_collision_teaser` y desbloquear la pestaña **ACTO II**.
- **Sector 0 (existente):** precuela forense vía VFS (`/etc/shadow`, `/proc/sector0/kain_trace.log`, `/srv/vault_shamir/shard_manifest.b64`).
- **Acto II (4 capítulos nuevos):** colisión y convergencia de VEX, N0X y AEGIS contra EXFIL, FUZZ y CORDON.
- **Free Ops:** registrar categoría oficial `"free_ops"` en `LevelRegistry`.

### 3.3 Pipeline data-driven de niveles (`*.level.json` v2)
- Grilla normalizada (`grid: [col, row]`), enums simbólicos, herencia de arquetipos (`"extends"`), auto-registro dinámico y validador headless (`tests/validate_levels.gd`) con verificación automática de esquema, referencias, Dijkstra y Edmonds-Karp Min-Cut.

### 3.4 Cuatro propuestas de niveles (Acto II)
1. **`act2_n1` — Intersección DMZ-65** (VEX / Heist, `ia_predictiva: true`, `locked_edges` + `node_triggers`, desbloquea `DOSSIER_COLLISION_01.enc` y `/var/log/dmz_handoff.log`).
2. **`act2_n2` — Bóveda de Espejos** (N0X / Hacker, 3 nodos `is_decoy` + `hidden_nodes`, desbloquea `/secrets/vex_hr_purged.dat` y pista dark-techno).
3. **`act2_n3` — Protocolo Contención CORDON** (AEGIS / Cyber + `MultiStageDirector`, Etapa 2 con origen de intrusión interno, confirma `DOSSIER_AEGIS.enc` y `/proc/cordon/aegis_biometric.sha`).
4. **`act2_n4` — Núcleo AS-65000: Reensamblaje Shamir** (VEX + N0X + AEGIS/ZERO, `MultiStageDirector` 3 etapas + `MultiDaemonController` 3 vs 1, cierra `/srv/vault_shamir/shard_manifest.b64`, desbloquea `DOSSIER_AS65000_FINAL.enc` y Free Ops).

---

## 4. Blueprint del Menú Interno Diegético: "LA BÓVEDA // VERTEX OS"

Evolución de `escenas/menu/profile.gd` con columna izquierda fija (`VaultIdCard`) y 6 pestañas (`01 // INSIGNIAS`, `02 // TERMLINK .ENC`, `03 // CONSOLA TTY`, `04 // ACADEMIA BASH`, `05 // MUSICBOX`, `06 // PERSONALIZACIÓN`) respaldadas por:
- `VaultStore` (persistencia tipada por slot en `vault.cfg`, `profile.cfg`, `stats.cfg` vía `SlotManager` estático).
- `SettingsManager` (autoload único para `user://settings.cfg`).
- `Events` ampliado (bus tipado por dominios) + `BadgeService` + `ToastOverlay`.
- Núcleo compartido `UnixShellEngine` + `TerminalVFS` (con `clone_snapshot()` para sandbox de Academia Bash).
- `HexHackEngine` puro para desencriptación hexadecimal estilo Fallout 3 / FNV.
- `MusicCatalog` + `AudioManager` (`MusicMode` FSM + crossfade) sin solapamientos.
- `ThemePresets` + `Brand` dinámico + `VaultCustomizationTab` aplicados en caliente.

---

## 5. Roadmap de Implementación por Fases

- **Fase 1:** `F1.1` (`VaultStore` + aislamiento de slots + `total_stars` + `build_level_rows`), `F1.2` (`SettingsManager` + `Events` + unificación opciones + SFX `"hover"`), `F1.3` (tipado `juego_ataque.gd`, fix `input_handler.gd:708`, `_edge_en_posicion`, shadowing `tutorials_menu.gd`, Dive-In/Out único, `LevelManager` + `secret_root.json`).
- **Fase 2:** `F2.1` (`*.level.json` v2 + `LevelLaunchContext` + selector dinámico), `F2.2` (`tests/validate_levels.gd`), `F2.3` (núcleo CLI/VFS compartido RW + `ShellResult`).
- **Fase 3:** `F3.1` (Insignias + `ToastOverlay`), `F3.2` (Termlink `HexHackEngine`), `F3.3` (Consola TTY + Academia Bash), `F3.4` (Music Box + `AudioManager`), `F3.5` (Personalización en caliente).
- **Fase 4:** `F4.1` (Acto II `act2_n1..n4` + `act2_collision_teaser` + `Free Ops`), `F4.2` (partición de god-objects + localización `es`/`en`/`pt` por dominios).
