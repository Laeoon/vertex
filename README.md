<div align="center">

# VERTEX

### Simulador Táctico de Ciberseguridad Basado en Teoría de Grafos

*Estrategia por turnos sobre redes dirigidas, terminal UNIX real, entrenamiento interactivo y análisis criptográfico en tiempo real.*

![Godot](https://img.shields.io/badge/Godot-4.7.2-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/GDScript-100%25-478CBF)
![Tests](https://img.shields.io/badge/tests-54%20suites-39FF88)
![Plataforma](https://img.shields.io/badge/Windows-10%2F11%20x64-0078D6)
![Versión](https://img.shields.io/badge/versión-0.7.0-00E5FF)

[Descargar v0.7.0](#-descargar-vertex-070-windows) · [Campañas](#-4-campañas-tácticas) · [La Bóveda](#-la-bóveda--hub-táctico-60-fps) · [Controles](#-controles) · [Desarrollo](#-para-desarrolladores)

</div>

---

**VERTEX** es un videojuego de estrategia y formación técnica donde navegas redes corporativas como atacante o defiendes infraestructura crítica como analista Blue Team. Cada mapa es un grafo dirigido con pesos reales, IA basada en Dijkstra y corte mínimo, detección probabilística, telemetría de red y una suite integrada de herramientas UNIX en vivo.

---

## 📥 Descargar VERTEX 0.7.0 (Windows)

Binario autocontenido para **Windows 10/11 (x64)** listo para ejecutar sin instalación previa.

- **Último lanzamiento:** [VERTEX 0.7.0 — LA BÓVEDA & VTX-ACADEMY](https://github.com/Laeoon/vertex/releases/latest)
- **Descarga directa:** [VERtex-0.7.0.exe](https://github.com/Laeoon/vertex/releases/download/v0.7.0/VERtex-0.7.0.exe)

```bash
# Descarga directa con curl
curl -L -o VERtex-0.7.0.exe https://github.com/Laeoon/vertex/releases/download/v0.7.0/VERtex-0.7.0.exe

# O con wget
wget https://github.com/Laeoon/vertex/releases/download/v0.7.0/VERtex-0.7.0.exe
```

**Verificación SHA-256:**
```text
808f96a24ae175531898456dc0334aad877cba8f48d084a19412e3e0170534dd  VERtex-0.7.0.exe
```

*Requisitos:* Windows 10/11 x64 y GPU compatible con Vulkan o DirectX 12.

---

## 🎯 4 Campañas Tácticas

| Campaña | Rol y Mecánicas Principales |
|---|---|
| **Heist (Infiltración)** | Evasión táctica por waypoints críticos mientras la IA bloquea rutas de escape y los sensores alertan a las patrullas. |
| **Hacker (Guerra Cibernética)** | Movimiento lateral con doctrina de corte mínimo ≥ 2: `Scan [X]`, `Bypass [1]`, `Escalate [2]`, `Persist [3]` y `Decoy [4]`. |
| **Ciberdefensa (Blue Team)** | Respuesta a incidentes 1:1 en tiempo real, rastreo forense EDR (`0..100%`), cuarentena de hosts `[C]` y niebla de guerra `[P]`. |
| **Sector 0 (Acto III)** | Nodos Dorados, director multietapa, múltiples Daemons simultáneos y acceso al núcleo `Root Genesis`. |

---

## 🏛 LA BÓVEDA // Hub Táctico (60 FPS)

Interfaz vectorizada `_draw()` con selector mecánico 2.5D y persistencia aislada por ranura (`Slot 1`, `Slot 2`, `Slot 3`):

| Módulo | Qué incluye en v0.7.0 |
|---|---|
| **01 // Insignias** | **5 árboles topológicos independientes** (General, Heist, Hacker, Cyber, UNIX), **24 insignias** tácticas e inspector 2.5D. |
| **02 // Termlink .ENC** | Descifrador de volcados de memoria camuflados con matriz posicional `LIKENESS` y expedientes clasificados desbloqueables. |
| **03 // Terminal & Lab** | Intérprete UNIX real (`UnixShellEngine` + `TerminalVFS` mutable, pipes `\|`, `>`, `>>`, `&&`, `nmap`, `traceroute`, `netstat`, `ping`) + **`VTX-ACADEMY v2`** (`Entrenamiento Guiado`, `Escalada SSH` de 5 nodos reales y `Guía de Comandos`). |
| **04 // MusicBox FFT** | Analizador de espectro de **32 bandas en tiempo real**, **22 pistas de DavidKBD**, filtros por pack, seek/volumen interactivo y fijado por escena. |
| **05 // Arcade `/usr/games/`** | Minijuegos jugables en pantalla: **`NETCYCLE`** (duelo 60 FPS contra IA) e **`ICEBREAKER`** (Mastermind hexadecimal), además de lanzadores CLI (`BREACH-3D`, `ROGUE-S0`). |

---

## 🕹 Controles

| Acción | Tecla / Control | Contexto |
|---|---|---|
| **Moverse / Confirmar nodo** | `Enter` / `Espacio` / `Clic` | Campañas y selector de nodos |
| **Seleccionar vecino** | `Flechas Direccionales` / `Tab` | Navegación espacial en el grafo |
| **Mover cámara (Pan) y Zoom** | `WASD` · `Rueda` / `+` / `-` · `Home` | Topología de red |
| **Bloquear arista / Cuarentena** | `Clic` en arista · `C` + `Clic` en nodo | Ciberdefensa (Blue Team) |
| **Habilidades Hacker** | `X` Scan · `1` Bypass · `2` Escalate · `3` Persist · `4` Decoy | Campaña Hacker |
| **Revelar ruta** | `P` | Asistencia táctica (`-1★` bajo niebla) |
| **Pausa / Opciones** | `Esc` / `M` | Menú modal en partida |
| **Terminal Táctica / Academia** | `[TAB]` Autocompletar · `↑/↓` Historial · `F1` Pista | Terminal & `VTX-ACADEMY` |

---

## 🛠 Para Desarrolladores

<details>
<summary><b>📖 Ver arquitectura del proyecto y suite de pruebas headless</b></summary>
<br>

### Arquitectura
- **Motor:** [Godot Engine 4.7.2](https://godotengine.org/) (Forward Plus, GDScript tipado estricto)
- **Capas principales:**
  - `core/`: algoritmos puros de grafos (Dijkstra, Edmonds-Karp / Min-Cut, MinHeap), `AudioManager`, `SettingsManager`, `SlotManager` y bus `Events`.
  - `juego/`: simulación de red, lógica de campañas (`heist`, `hacker`, `cybersecurity`, `sector_0`), `UnixShellEngine`, `TerminalVFS` y renderizadores `_draw()`.
  - `escenas/`: menús, transiciones `dive_in`/`dive_out`, `LA BÓVEDA` (`escenas/menu/vault/`) y pantallas de juego.
  - `tests/`: **54 suites** automatizadas ejecutables en modo headless.

### Ejecución desde fuente y pruebas

```bash
# Clonar el repositorio
git clone https://github.com/Laeoon/vertex.git
cd vertex

# Ejecutar suite completa de pruebas headless
godot --headless --script res://tests/runner/run_all.gd -- --all

# Ejecutar una suite específica
godot --headless --script res://tests/runner/_run_one.gd --test-path res://tests/system/test_profile_ranks_and_tabs.gd
```

</details>

---

## 📄 Licencia y Créditos

El código fuente y el contenido educativo de **VERTEX** se distribuyen con fines académicos y de investigación. Para licencias de terceros, música (**DavidKBD**, CC-BY 4.0) y tipografías, consulta [CREDITS.md](CREDITS.md).
