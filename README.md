<div align="center">

# 🔐 VERTEX

### Simulador de Ciberseguridad Basado en Teoría de Grafos

*Estrategia por turnos sobre redes dirigidas: pathfinding, detección probabilística y conceptos reales de teoría de grafos.*

![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/GDScript-100%25-478CBF)
![Tests](https://img.shields.io/badge/tests-43%20suites%20pass-39FF88)
![Plataforma](https://img.shields.io/badge/plataforma-Windows%2010%2F11-0078D6)
![Versión](https://img.shields.io/badge/versión-0.5.0-00e5ff)

[📥 Descargar](#-descargar-el-juego-windows) · [🎮 Características](#-características) · [🕹 Controles](#-controles) · [🧰 Código Fuente](#-descargar-el-código-fuente) · [🛠 Desarrollo y Motor](#-para-desarrolladores-y-uso-del-motor)

</div>

---

VERTEX es un videojuego de estrategia y educación donde navegas redes corporativas como un atacante o defiendes la infraestructura como analista de seguridad: cada nivel es un grafo dirigido con pesos, una IA que analiza rutas mediante Dijkstra y corta pasos críticos, nodos con detección probabilística, firewalls y unidades de respuesta que patrullan la topología.

---

## 🎮 Características

**Modos de Juego:**

- **🗡 Heist (Infiltración)** — Campaña de evasión: alcanza la bóveda y los waypoints críticos mientras la IA bloquea rutas de escape y los sensores alertan a las patrullas.
  - *Niveles:* N1 La Entrada, N2 El Laberinto, N3 Ojo del Casino, N4 Blackout, N5 Extracción Final.
- **💻 Hacker (Guerra Cibernética)** — Campaña completa de 5 niveles de movimiento lateral en redes corporativas con doctrina de corte mínimo $\ge 2$:
  - *Mecánicas:* Escaneo de vulnerabilidades (`Scan [X]`), evasión de aristas bloqueadas (`Bypass [1]`), elevación con telemetría de 2 saltos (`Escalate [2]`), zonas de sigilo seguras (`Persist [3]`) y despliegue activo de señuelos (`Decoy [4]`) para absorber bloqueos y desviar rastreadores.
  - *Niveles:* N1 Lateral Movement, N2 Brecha Corporativa, N3 Persistencia de Red, N4 Guerra de Señuelos, N5 Operación Root Compromise.
- **🛡 Ciberdefensa (Blue Team)** — Simulación de respuesta a incidentes en tiempo real:
  - *Ciclo Reactivo 1:1 (Ping-Pong):* Cada bloqueo de arista o contramedida defensiva resuelve el turno y activa de inmediato al adversario.
  - *Rastreo Forense EDR (0..100%):* Neutraliza el origen del ataque mediante contención metódica (+20% base, +10% bonus por desvíos).
  - *IA Adversaria Activa:* Movimiento lateral adaptativo (MITRE T1021), rutas estocásticas en bifurcaciones y uso de exploits `Bypass` al quedar acorralado.
  - *Aislamiento de Host (Cuarentena `[C]`):* Corta de raíz todas las conexiones de un nodo comprometido sacrificando disponibilidad por contención crítica.
  - *Niebla de Guerra & Intercepción `[P]`):* Telemetría oculta por defecto en niveles avanzados; revelarla topa la calificación a un máximo de 2 estrellas.
- **🎖 Metajuego & Condecoraciones:**
  - Sistema data-driven de 10 condecoraciones militares y retos tácticos en español en el expediente del operador.
  - Gestión de 3 ranuras de guardado independientes (`Slot 1`, `Slot 2`, `Slot 3`) con borrado seguro (`[Supr]`) y migración transparente de partidas previas.
- **📐 Documentación Formal y Modelado UML:**
  - Set integral de 7 diagramas de ingeniería de software (Casos de Uso, Secuencia, Actividades, Clases, Modelo de Datos ER y Máquina de Estados FSM) disponibles en HTML/SVG y en PDF consolidado (`documentacion/diagramas/`).

**Interfaz, Inmersión & Experiencia Visual:**
- 🔊 **Paisaje Sonoro & SFX Tácticos:** Motor de audio multicanal con buses dedicados (Master, Music, SFX), prioridad dinámica de sonidos para eventos críticos y bandas sonoras temáticas (packs Cyberpunk y Synth de DavidKBD).
- 💥 **Juice & Cinematismo:** Sacudida de cámara no lineal basada en trauma ante exploits/alarmas, e interpolación fluida de movimiento (tweening) entre nodos.
- 🎯 **Retícula Táctica HUD:** Doble anillo cian/dorado de alto contraste con brackets angulares para enfoque inequívoco del objetivo.
- 🌐 **Telemetría de Red Realista:** Filtrado inteligente de badges de protocolo (HTTPS, SSH, DNS, LDAP, VPN, SQL, QUIC), eliminando el ruido visual en grafos densos.
- 🧭 **Navegación Espacial & Pan-Zoom:** Selección direccional geométrica con WASD o flechas de teclado, selección rápida al posar el cursor, y controles de paneo y zoom de topología.
- 🖱 **Menús Fluidos y Control Total con Mouse:** Menú de opciones rediseñado con deslizadores arrastrables, interruptores táctiles, pestañas navegables con mouse y transiciones fluidas de dos fases entre escenas.
- 📚 **Academia de Tutoriales Modulares:** Pistas divididas por categorías (Fundamentos, Heist, Hacker) con lecciones prácticas guiadas y glosario interactivo de términos.
- ⭐ **Sistema de Par y Evaluación:** Puntuación de 1 a 3 estrellas según el rendimiento y consumo de recursos.
- 🧪 **Suite de Pruebas Robusta:** 52 suites de tests automatizados (unitarios, equivalencia golden, navegación espacial, audio, interpolación y simulación de balance por self-play).

---

## 📥 Descargar el juego (Windows)

Binario precompilado para Windows 10/11 (x64), autocontenido y listo para jugar sin instalación previa.

**Última versión:** [VERtex 0.5.0](https://github.com/Laeoon/vertex/releases/latest)

```bash
# Descarga directa vía curl
curl -L -o VERtex-0.5.0.exe https://github.com/Laeoon/vertex/releases/download/v0.5.0/VERtex-0.5.0.exe

# O con wget
wget https://github.com/Laeoon/vertex/releases/download/v0.5.0/VERtex-0.5.0.exe
```

*Requisitos:* Windows 10/11 x64, GPU compatible con Vulkan / DirectX 12.

---

## 🕹 Controles

| Acción | Tecla / Control | Descripción |
|---|---|---|
| **Moverse al nodo seleccionado** | `Enter` / `Espacio` | Avanza hacia el vecino activo en el turno. |
| **Moverse / Seleccionar con Mouse** | `Clic Izquierdo` en nodo | Moverse directo o calcular primer paso. |
| **Selección de Vecinos** | `Flechas Direccionales` | Selecciona el nodo adyacente en esa dirección angular. |
| **Control de Cámara (Pan)** | `WASD` | Mueve el viewport y desplaza la vista por redes complejas. |
| **Recentrar Cámara** | `Home` | Restaura la vista y el zoom al centro del mapa. |
| **Zoom de Topología** | `Rueda del Ratón` / `+` / `-` | Acerca o aleja la visualización centrado en el cursor. |
| **Ciclo Secuencial** | `Tab` | Cicla entre vecinos disponibles. |
| **Bloquear Arista** | `Clic Izquierdo` en arista | *(Defensa)* Sella la conexión y avanza turno en ciclo 1:1. |
| **Aislar Nodo (Cuarentena)** | `C` + `Clic` en nodo | *(Defensa)* Desconecta un host comprometido de la red. |
| **Pista / Revelar Ruta** | `P` | Alterna la visualización del camino del atacante (-1★ bajo niebla). |
| **Escanear Nodo** | `X` | *(Hacker)* Revela tipo y reduce probabilidad de alerta. |
| **Bypass de Bloqueo** | `1` | *(Hacker)* Atraviesa arista bloqueada sin detección. |
| **Escalar Privilegios** | `2` | *(Hacker)* Telemetría de red a 2 saltos de distancia. |
| **Persistir en Nodo** | `3` | *(Hacker)* Crea zona segura sin ruido y con doble disipación. |
| **Desplegar Señuelo** | `4` | *(Hacker)* Coloca señuelo adyacente que absorbe bloqueos. |
| **Pausa / Opciones** | `Esc` / `M` | Abre el menú modal de pausa y configuración. |
| **Borrar Slot de Guardado** | `Supr` / `Backspace` | *(StartScreen)* Elimina de forma permanente el perfil seleccionado. |

*Navegación post-partida:* `[R]` Reintentar · `[N]` Siguiente nivel · `[L]` Selector de niveles · `[Q]` Menú.

---

## 🧰 Descargar el código fuente

```bash
# Clonar el repositorio completo
git clone https://github.com/Laeoon/vertex.git

# O descargar el tarball de la versión más reciente
curl -L -o vertex-0.5.0.tar.gz https://github.com/Laeoon/vertex/archive/refs/tags/v0.5.0.tar.gz
tar -xzf vertex-0.5.0.tar.gz
```

---

## 🛠 Para desarrolladores y uso del motor

<details>
<summary><b>📖 Ver instrucciones de ejecución, motor y suite de pruebas</b></summary>
<br>

### Arquitectura
- **Motor:** [Godot Engine 4.7+](https://godotengine.org/)
- **Lenguaje:** GDScript 2.0 (estricto y tipado)
- **Estructura en capas:**
  - `core/`: Algoritmos puros de teoría de grafos (Dijkstra, Min-Cut / Edmonds-Karp, MinHeap), runtime de red, gestión de audio y contratos de eventos.
  - `juego/`: Lógica de juego orientada a datos (`juego_ataque.gd`, `game_logic.gd`, `hacker_logic.gd`, `game_renderer.gd`).
  - `escenas/`: Interfaz de usuario, menús y transiciones.
  - `tests/`: Batería de pruebas automatizadas y arneses de simulación.

### Cómo abrir el proyecto
1. Descarga e instala **Godot Engine 4.7** (Standard o .NET con soporte GDScript).
2. En el Administrador de Proyectos de Godot, haz clic en **Importar** y selecciona el archivo `project.godot` ubicado en la raíz del repositorio.
3. Presiona **F5** para ejecutar la escena principal o **F6** para correr la escena activa.

### Ejecución de Pruebas Automatizadas
El proyecto incluye un runner headless propio para ejecutar todas las pruebas desde la terminal:

```bash
# Correr la suite de pruebas estándar:
godot --headless --script res://tests/runner/run_all.gd

# Correr la suite COMPLETA (incluye pruebas de equivalencia y visuales - 52 suites):
godot --headless --script res://tests/runner/run_all.gd -- --all

# Correr una prueba específica de forma individual:
godot --headless --script res://tests/runner/_run_one.gd -- res://tests/system/test_spatial_navigation.gd

# Simulación de balance por self-play (ejemplo: 100 corridas monte-carlo):
godot --headless res://tests/balance/_balance_harness.tscn -- 100
```

</details>

---

## 📄 Licencia y Créditos

El contenido pedagógico y el código fuente de VERTEX se distribuyen con fines educativos y de investigación bajo acceso abierto.

Para información sobre licencias de terceros, música (DavidKBD CC-BY 4.0) y tipografías, consulta el archivo [CREDITS.md](CREDITS.md).
