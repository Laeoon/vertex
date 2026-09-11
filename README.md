<div align="center">

# 🔐 VERTEX

### Simulador de Ciberseguridad Basado en Teoría de Grafos

*Estrategia por turnos sobre redes dirigidas: pathfinding, detección probabilística y conceptos reales de teoría de grafos.*

![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/GDScript-100%25-478CBF)
![Tests](https://img.shields.io/badge/tests-47%20suites%20pass-39FF88)
![Plataforma](https://img.shields.io/badge/plataforma-Windows%2010%2F11-0078D6)
![Versión](https://img.shields.io/badge/versión-0.3.5-00e5ff)

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
- **🛡 Defensa (Ciberseguridad)** — *(En desarrollo)*: Modo invertido donde administras la seguridad de la red colocando firewalls y bloqueos estratégicos para aislar al atacante.

**Interfaz & Experiencia Visual:**
- 🎯 **Retícula Táctica HUD:** Doble anillo cian/dorado de alto contraste con brackets angulares para enfoque inequívoco del objetivo.
- 🌐 **Telemetría de Red Realista:** Filtrado inteligente de badges de protocolo (HTTPS, SSH, DNS, LDAP, VPN, SQL, QUIC), eliminando el ruido visual en grafos densos.
- 🧭 **Navegación Espacial:** Selección direccional geométrica con WASD o flechas de teclado, y selección rápida al posar el cursor sobre cualquier nodo adyacente.
- 📚 **Academia de Tutoriales Modulares:** Pistas divididas por categorías (Fundamentos, Heist, Hacker) con lecciones prácticas guiadas y glosario interactivo de términos.
- ⭐ **Sistema de Par y Evaluación:** Puntuación de 1 a 3 estrellas según el rendimiento y consumo de recursos.
- 🧪 **Suite de Pruebas Robusta:** 47 suites de tests automatizados (unitarios, equivalencia golden, navegación espacial y simulación de balance por self-play).

---

## 📥 Descargar el juego (Windows)

Binario precompilado para Windows 10/11 (x64), autocontenido y listo para jugar sin instalación previa.

**Última versión:** [VERtex 0.3.5](https://github.com/Laeoon/vertex/releases/latest)

```bash
# Descarga directa vía curl
curl -L -o VERtex-0.3.5.exe https://github.com/Laeoon/vertex/releases/download/v0.3.5/VERtex-0.3.5.exe

# O con wget
wget https://github.com/Laeoon/vertex/releases/download/v0.3.5/VERtex-0.3.5.exe
```

*Requisitos:* Windows 10/11 x64, GPU compatible con Vulkan / DirectX 12.

---

## 🕹 Controles

| Acción | Tecla / Control | Descripción |
|---|---|---|
| **Moverse al nodo seleccionado** | `Enter` / `Espacio` | Avanza hacia el vecino activo en el turno. |
| **Moverse / Seleccionar con Mouse** | `Clic Izquierdo` en nodo | Moverse directo o calcular primer paso. |
| **Selección por Hover** | `Pasar cursor` sobre vecino | Enfoca instantáneamente el nodo adyacente. |
| **Navegación Espacial** | `WASD` / `Flechas` | Selecciona el vecino en esa dirección angular. |
| **Ciclo Secuencial** | `Tab` | Cicla entre vecinos disponibles. |
| **Pista de Ruta Óptima** | `P` | Alterna la visualización del camino más corto. |
| **Escanear Nodo** | `X` | *(Hacker)* Revela tipo y reduce probabilidad de alerta. |
| **Bypass de Bloqueo** | `1` | *(Hacker)* Atraviesa arista bloqueada sin detección. |
| **Escalar Privilegios** | `2` | *(Hacker)* Telemetría de red a 2 saltos de distancia. |
| **Persistir en Nodo** | `3` | *(Hacker)* Crea zona segura sin ruido y con doble disipación. |
| **Desplegar Señuelo** | `4` | *(Hacker)* Coloca señuelo adyacente que absorbe bloqueos. |
| **Reiniciar Nivel** | `R` | Reinicia la partida en curso. |
| **Menú Principal** | `Q` / `Esc` | Vuelve a la pantalla de inicio. |

*Navegación post-partida:* `[R]` Reintentar · `[N]` Siguiente nivel · `[L]` Selector de niveles · `[Q]` Menú.

---

## 🧰 Descargar el código fuente

```bash
# Clonar el repositorio completo
git clone https://github.com/Laeoon/vertex.git

# O descargar el tarball de la versión más reciente
curl -L -o vertex-0.3.5.tar.gz https://github.com/Laeoon/vertex/archive/refs/tags/v0.3.5.tar.gz
tar -xzf vertex-0.3.5.tar.gz
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
  - `core/`: Algoritmos puros de teoría de grafos (Dijkstra, Min-Cut / Edmonds-Karp, MinHeap), runtime de red y contratos de eventos.
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

# Correr la suite COMPLETA (incluye pruebas de equivalencia y visuales - 47 suites):
godot --headless --script res://tests/runner/run_all.gd -- --all

# Correr una prueba específica de forma individual:
godot --headless --script res://tests/runner/_run_one.gd -- res://tests/system/test_spatial_navigation.gd

# Simulación de balance por self-play (ejemplo: 100 corridas monte-carlo):
godot --headless res://tests/balance/_balance_harness.tscn -- 100
```

</details>

---

## 📄 Licencia

El contenido pedagógico y el código fuente de VERTEX se distribuyen con fines educativos y de investigación bajo acceso abierto.
