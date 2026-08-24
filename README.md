<div align="center">

# 🔐 VERTEX

### Simulador de Ciberseguridad Basado en Teoría de Grafos

*Estrategia por turnos sobre redes dirigidas: pathfinding, detección probabilística y conceptos reales de teoría de grafos.*

![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![Lenguaje](https://img.shields.io/badge/GDScript-100%25-478CBF)
![Tests](https://img.shields.io/badge/tests-25%20%2B%2014%20escenas-39FF88)
![Plataforma](https://img.shields.io/badge/plataforma-Windows%2010%2F11-0078D6)

[📥 Descargar](#-descargar-el-juego-windows) · [🎮 Características](#-características) · [🕹 Controles](#-controles) · [🛠 Desarrollo](#-para-desarrolladores)

</div>

---

VERTEX es un juego educativo en el que el jugador navega redes de computadoras como intruso: cada nivel es un grafo dirigido con pesos, una IA que analiza sus rutas con Dijkstra y las bloquea, nodos con cámaras de detección probabilística y perseguidores que se desplazan por la red. El objetivo se alcanza aplicando conceptos de teoría de grafos: pathfinding, flujo máximo y corte mínimo.

## 🎮 Características

**Tres modos sobre el mismo motor de redes:**

- **🗡 Heist** — infiltración: alcanzar la bóveda pasando por waypoints mientras la IA bloquea rutas. Campaña con niveles de identidad propia:

  | Nivel | Identidad |
  |-------|-----------|
  | N1 · La Entrada | Movimiento básico por el grafo |
  | N2 · El Laberinto | Bloqueos de IA con aristas de retorno |
  | N3 · Ojo del Casino | Detección probabilística + perseguidores |
  | N4 · Blackout | Escalada de alarma por turnos |

- **💻 Hacker** — movimiento lateral en red corporativa: ruido, escaneos y exploits (bypass / escalate / persist).
- **🛡 Defensa** — modo invertido: el jugador administra la defensa, bloquea aristas y coloca firewalls para impedir que el atacante alcance su objetivo (corte mínimo como mecánica).

**Además:**

- 📚 **7 tutoriales guiados** paso a paso con glosario integrado
- ⭐ Sistema de par por nivel: cumplir el rendimiento de referencia otorga 3 estrellas
- 🚨 Eventos por turno definidos por datos (escalada de alarma configurable por JSON)
- 🔀 Navegación post-partida directa: siguiente nivel, selector o menú
- 🧪 Suite de tests con golden equivalence y harness de balance por self-play

<!-- TODO: capturas — soltar 2-3 PNG en .github/ y descomentar:
<p align="center">
  <img src=".github/screenshot-heist.png" width="45%" />
  <img src=".github/screenshot-defensa.png" width="45%" />
</p>
-->

## 📥 Descargar el juego (Windows)

El juego compilado para Windows 10/11 (x64). No requiere instalar nada, es un solo archivo autocontenido.

**Última versión:** [VERtex Alfa 0.1.0](https://github.com/Laeoon/vertex/releases/latest)

```bash
# Descargar el .exe directamente (v0.1.0-alpha)
curl -L -o VERtex-alpha-0.1.0.exe https://github.com/Laeoon/vertex/releases/download/v0.1.0-alpha/VERtex-alpha-0.1.0.exe

# Con wget
wget https://github.com/Laeoon/vertex/releases/download/v0.1.0-alpha/VERtex-alpha-0.1.0.exe
```

**Requisitos:** Windows 10/11 x64, GPU con DirectX 12, ~300 MB de espacio. Al ejecutarlo se abre en pantalla completa.

## 🕹 Controles

| Tecla / Acción | Atacante | Defensa |
|---|---|---|
| **Click** en nodo vecino | Moverse | Bloquear arista |
| **Tab** + **Enter** | Seleccionar y mover | Resolver turno |
| **P** | Ruta óptima (hint) | — |
| **F** | — | Firewall de nodo |
| **X / E** | Escanear / Exploit (hacker) | — |
| **R** | Reiniciar nivel | Reiniciar nivel |
| **Q** | Menú principal | Menú principal |

Al terminar una partida: **[R]** reintentar · **[N]** siguiente nivel · **[L]** selector de niveles · **[Q]** menú.

## 🧰 Descargar el código fuente

```bash
# Clonar con historial completo (recomendado para desarrollo)
git clone https://github.com/Laeoon/vertex.git

# Clon "shallow" (solo última versión)
git clone --depth 1 https://github.com/Laeoon/vertex.git

# Sin Git
curl -L -o vertex.tar.gz https://github.com/Laeoon/vertex/archive/refs/heads/main.tar.gz && tar -xzf vertex.tar.gz
```

Abrí `project.godot` con **Godot 4.7+** y presioná F5.

## 🛠 Para desarrolladores

**Stack:** Godot 4.7 · GDScript · renderizado Forward Plus · arquitectura en capas `core/` (algoritmos de grafos, autoloads) → `juego/` (lógica data-driven) → `escenas/` (UI).

Los niveles son **datos, no código**: un `.json` (params, eventos, par) + un `.tres` (grafo dirigido con costos y metadatos de detección). El balance se valida con un harness de self-play (greedy / greedy_err / random, semillas deterministas).

### Correr y testear

```bash
# Suite completa (25 pruebas)
godot --headless --script res://tests/runner/run_all.gd

# Golden equivalence tests por módulo (congelan comportamiento)
godot --headless res://tests/ataque/_test_game_logic_equivalence.tscn   # 19 asserts
godot --headless res://tests/tutorials/_test_tutorial_render_equivalence.tscn  # 34

# Harness de balance self-play (100 corridas por política)
godot --headless res://tests/balance/_balance_harness.tscn -- 100
```

Detalle completo de verificación en [`documentacion/VERTEX/17 - Handoff a orquestador.md`](documentacion/VERTEX/17%20-%20Handoff%20a%20orquestador.md).

### Convenciones de commits

[Conventional Commits](https://www.conventionalcommits.org/) en español técnico: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf` — ej: `feat(slice-6): navegación post-partida con guardas N/L`.

### Documentación

La bitácora completa vive en [`documentacion/VERTEX/`](documentacion/VERTEX/): arquitectura ([03](documentacion/VERTEX/03%20-%20Arquitectura.md)), diseño de niveles ([06](documentacion/VERTEX/06%20-%20Level%20Design.md)), historial de cambios ([14](documentacion/VERTEX/14%20-%20Historial%20de%20cambios.md)) y estado del repo ([18 - Overview](documentacion/VERTEX/18%20-%20Overview%20y%20auditor%C3%ADa%20pendiente.md)).

## Licencia

Por definir. El contenido pedagógico es de acceso libre; el código fuente se comparte con fines educativos.
