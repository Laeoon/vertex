# Feature: VERTEX v1.0 Master Overhaul (Cimientos, UX Híbrida, Selector 2.5D, Menú Exterior + Créditos UPTA + La Bóveda, Trilogía Sector 0, Acto 2 y Kernel DOOM)
Status: in_progress
Base: v0.6.0 (a12526e)

## Specs
- **S1 (Fase 1 - Saneamiento, Menú Principal, Dive Transitions, Rendimiento y Base i18n Realista)**: Completado (`1b9e4f9`).
- **S2 (Fase 2 - HUD In-Game Definitivo Artboard 04, Controles Híbridos Teclado/Mouse/Touch, Fix CLI Crash, Línea Verde Neón Dijkstra y Reforma de Tutoriales)**: Completado (`a899db1`).
- **S3 (Fase 3 - Selector de Niveles 3D Spine Tunnel Artboard 07, Anclaje de Wave, Motor de Cinemáticas MGS Codec y Base de Datos)**: Completado (`3bda353`).
- **S4 (Fase 4 - Acomodar Menú Exterior, Créditos Oficiales UPTA, Panel Unificado `LA BÓVEDA / PERFIL` con Decodificador Fallout, Academia CLI + Sandbox UNIX Funcional (`ls`, `grep`, `cat`, `cd`, `pwd`, `find`, `chmod`, `ps`, `kill`, `ssh`, `base64`, pipes `|`), MusicBox 22 Temas, Skins de Nodo y 24 Insignias)**:
  - **Créditos Oficiales (`escenas/menu/credits_screen.gd` & `CREDITS.md`)**:
    - **Director, Arquitectura de Software, Algoritmos & Gameplay**: **Leonardo Angulo** (C.I. 29.771.631).
    - **Co-Desarrollo, Documentación de Ingeniería (UML 2.5 / Modelo E-P-S) & QA**: **Juan Parilli** (C.I. 31.931.218) y **Ana Borges** (C.I. 32.318.803).
    - **Institución & Tutoría Académica**: Universidad Politécnica Territorial del Estado Aragua "Federico Brito Figueroa" (PNF en Informática — Proyecto Socio-Tecnológico II), **Prof. Ing. Elizabet C. Duarte P.** (Coordinación Docente) y **Prof. Ing. Miguel Mejias** (Tutor Académico).
    - **Base Matemática & Audio**: Edsger W. Dijkstra (1956), Jack Edmonds & Richard M. Karp (1972), Shivakumar & Mamatha (2022), DavidKBD (*Pink Bloom* & *Code Injection* Packs CC-BY 4.0).
    - Scroll suave con bucle continuo sin saltos bruscos, controles de pausa/velocidad y localización en `es`, `en`, `pt`.
  - **Menú Principal de 6 Nodos Unificando `BÓVEDA // PERFIL` (`escenas/main_menu.gd`)**:
    - El nodo `"profile"` del anillo orbital de 6 nodos evoluciona a **`BÓVEDA // PERFIL`** (`menu.vault` / `menu.profile` compatible), y en el Selector de Mundos (`WORLD_SELECT`) se muestran las pistas: `Academia`, `Heist`, `Hacker`, `Cybersecurity`, más el nodo de **`Sector 0: Root Genesis`** (desbloqueable al completar los 3 Actos 1 con sus 3 Nodos Dorados o vía código Konami) y **`Operaciones Libres`**.
  - **Centro Neurálgico `LA BÓVEDA` (`escenas/menu/profile.gd` expandido o integrado con `juego/ui/vault_modules.gd`)**:
    1. **Pestaña `EXPEDiente & INSIGNIAS`**: Estadísticas del operador, rango y vitrina de las **24 Insignias** tácticas.
    2. **Pestaña `DECODIFICADOR // ARCHIVOS (.ENC)` (Minijuego Fallout RobCo Terminal)**:
       - Volcado de memoria hexadecimal en dos columnas con palabras candidatas de igual longitud, contador de 4 intentos, cálculo de coincidencia posicional exacta (`LIKENESS / COINCIDENCIA: X/N`), y pares de paréntesis/corchetes trampa (`(...)`, `[...]`, `{...}`, `<...>`) que eliminan una palabra falsa (*Dud Removed*) o restauran los intentos.
       - Desbloquea los archivos en primera persona de **Kain (`SEC_0_KERNEL_SNAPSHOT`)** y las historias reales/epílogos de **Vex, N0X y Aegis**.
    3. **Pestaña `TERMINAL LAB & ACADEMIA CLI`**:
       - **Intérprete UNIX / POSIX Virtual Funcional (`juego/system/unix_shell_engine.gd`)** compartido tanto en **La Bóveda** como en la **Terminal In-Game `[~] CLI` (`terminal_overlay.gd`)**:
         - Sistema de archivos virtual jerárquico (`/`, `/home/operator`, `/etc/bgp`, `/var/log/siem`, `/srv/vault_shamir`, `/proc/sector0`) con archivos reales del lore e inspección de red.
         - Comandos 100% funcionales: `ls` (`-l`, `-a`), `cd`, `pwd`, `cat`, `grep` (`-i`, `-n`), `find`, `head`, `tail`, `wc`, `chmod`, `ps`, `kill`, `whoami`, `uname`, `ifconfig`/`ip`, `netstat`, `ssh`, `base64` (`-d`), `clear`, `help`, y soporte para **pipes (`|`)** (ej. `cat /var/log/siem/auth.log | grep FAIL` o `ps aux | grep daemon`).
       - **Academia de Terminal Integrada**: Lecciones prácticas interactivas paso a paso dentro de la pestaña donde el jugador aprende y valida comandos reales (`Módulo 1: Navegación ls/cd/pwd/cat`, `Módulo 2: Filtrado Forense con grep y pipes |`, `Módulo 3: Procesos ps/kill y Permisos chmod`, `Módulo 4: Esteganografía base64 y Auditoría de Red`).
    4. **Pestaña `MUSICBOX (22 TRACKS)`**: Reproductor de las 22 canciones de DavidKBD desbloqueables por logros/progreso, con onda de espectro en vivo y botón para fijar la pista activa en menú/partida.
    5. **Pestaña `COSMÉTICOS DE NODO`**: Selección de skin/geometría y color de estela para el nodo del jugador en el grafo.
- **S5 (Fase 5 - Trilogía de Sector 0 Multi-Grafo & 3v1, Nodos Dorados, los 15 Niveles del Acto 2, Operaciones Libres, Easter Egg `KERNEL DOOM` e i18n 100% ES/EN/PT)**:
  - Especificación canónica en `documentacion/documento_maestro_narrativo_y_t_cnico.md`.

## Tasks
- [x] **T1** (S1): Fase 1 — Saneamiento, fix Menú Principal, Dive Transitions universales y limpieza | route: worker | commit: `1b9e4f9`
- [x] **T2** (S2): Fase 2 — Controles Híbridos base y Reforma de Tutoriales | route: worker | commit: `a9cf11d`
- [x] **T3** (S3): Fase 3 — Base de Selector 2.5D, Audio Wave 3-pass, Codec MGS y Pestaña en BD | route: worker | commit: `eb37e7d`
- [x] **T4A** (S2, S3): Resolver Deuda Técnica Visual/Interactiva (Fix CLI Crash + HUD Artboard 04 + Fix TopBar collision + Línea Verde Neón Dijkstra + Fix Wave/Actos en Selector) | route: worker | commit: `a899db1`
- [ ] **T4B** (S4): **Menú Exterior, Créditos Oficiales UPTA (Leonardo Angulo, Juan Parilli, Ana Borges + Tutores) y Panel Unificado `BÓVEDA // PERFIL`** (con Intérprete UNIX Funcional `ls/grep/cat/cd/ps/kill/base64/pipes` en Bóveda y en `[~] CLI` + Academia de Terminal interactiva + Minijuego Fallout Terminal de Archivos `.enc` + MusicBox 22 pistas + Skins de Nodo + 24 Insignias) | route: worker | commit: pending
- [ ] **T5** (S5): **Trilogía de Sector 0 (`0.1` Hacker Doble Grafo, `0.2` Heist Maratón Estela Dorada, `0.3` Cyber 3 Daemons vs 1) + Nodos Dorados en Jefes Acto 1 + 15 Niveles del Acto 2** con eventos Codec en ejecución y registro neutro formal (`documentacion/documento_maestro_narrativo_y_t_cnico.md`) | route: worker | commit: pending
- [ ] **T6** (S5): **Operaciones Libres** (contratos autoconclusivos), Easter Egg **`KERNEL DOOM`** (`juego/secret/kernel_doom.gd` raycaster 3D contra los Daemons y el Kernel) e **Internacionalización 100% ES/EN/PT** | route: worker | commit: pending

## Log
- **L1-L6**: Fases 1 a 4A completadas (`a899db1`) y documento maestro `documentacion/documento_maestro_narrativo_y_t_cnico.md` establecido.
- **L7**: Definido por el usuario acomodar primero el Menú Exterior, los Créditos Oficiales UPTA (Leonardo Angulo como Director/Arquitecto, Juan Parilli y Ana Borges en Ing. Documental/QA + Profesores UPTA), unificar Perfil + Bóveda en el anillo de 6 nodos del menú, e integrar el CLI UNIX funcional (`ls`, `grep`, `cat`, pipes, etc.) + Academia de Terminal en La Bóveda y en `[~] CLI`.
