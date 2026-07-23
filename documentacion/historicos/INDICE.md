# Índice — Simulador de Ciberseguridad Basado en Teoría de Grafos

## La idea en una frase

Modelar una red informática como un grafo dirigido y ponderado para sentar las bases de un simulador de ciberseguridad educativo, validado mediante sandboxes headless.

## Stack técnico

| Pieza | Versión | Para qué |
|---|---|---|
| Godot Engine | 4.7 stable | Motor + CLI para sandboxes headless |
| GDScript | Godot 4.7 | Lógica con tipado estático fuerte |
| Custom Resources | `.tres` | Topología de la red |
| SceneTree headless | `godot --headless` | Validación sin abrir editor |

## Navegación

- [README](../README.md) — Presentación del proyecto
- [CHANGELOG](CHANGELOG.md) — Historial de hitos
- [ROADMAP](../ROADMAP.md) — Plan de hitos y requisitos

### Histórico (por orden cronológico)

| Doc | Tema |
|---|---|
| [`00_vision_y_stack.md`](historico/00_vision_y_stack.md) | Visión general y stack tecnológico |
| [`01_filosofia_sandbox_first.md`](historico/01_filosofia_sandbox_first.md) | Metodología Sandbox-First |
| [`02_estructura_del_grafo.md`](historico/02_estructura_del_grafo.md) | Diseño del grafo estático |
| [`03_sandbox_caso_a.md`](historico/03_sandbox_caso_a.md) | Sandbox A — Conectividad unidireccional |
| [`04_demo_visual.md`](historico/04_demo_visual.md) | Demo visual interactiva (Sandbox A) |
| [`05_sandbox_caso_b.md`](historico/05_sandbox_caso_b.md) | Sandbox B — Pesos duales independientes |
| [`06_demo_dual_weights.md`](historico/06_demo_dual_weights.md) | Demo visual de pesos duales |
| [`CONTEXTO_PROYECTO.md`](historico/CONTEXTO_PROYECTO.md) | Estado actual del proyecto |

## Mapa del repositorio

```
nuevo-proyecto-de-juego/
├── core/
│   ├── network/              # .tres + runtime (Hito 1)
│   ├── agents/               # Dijkstra + Edmonds-Karp (Hitos 2-3)
│   ├── fsm/                  # FSM de nodos (Hito 4)
│   ├── integration/          # ReactivePathfinder + ReactiveAnalyzer (Hito 5)
│   └── autoloads/            # Events + SceneParams
├── juego/
│   ├── ataque/               # Escena principal de juego
│   │   ├── juego_ataque.gd   # Orquestador de lógica
│   │   ├── game_renderer.gd  # Capa de rendering separada
│   │   └── ia_defensora.gd   # IA bloqueadora
│   ├── system/               # GameManager, LevelRegistry, HackerMechanics
│   ├── heist/                # Niveles Heist (.tres + .json)
│   ├── hacker/               # Niveles Hacker (.tres + .json)
│   ├── cyber/                # Niveles Cybersecurity (.tres + .json)
│   ├── tutorials/            # Sistema de tutoriales
│   └── nivel1/               # Grafo base Heist N1
├── escenas/
│   ├── main_menu.gd          # Menú principal cyberpunk
│   └── menu/                 # Options, Profile, Database
├── archive/                  # Sandboxes históricos (A-F)
└── docs/                     # Documentación del proyecto
```

## Glosario

| Término | Significado |
|---|---|
| Grafo $G=(V,E)$ | Conjunto de nodos y aristas |
| Arista dirigida | Conexión con sentido único (de A a B, no de B a A) |
| `transit_cost` | Peso de arista (latencia/resistencia) |
| `mitigation_capacity` | Peso de arista (capacidad de mitigación) |
| `.tres` | Formato texto de Godot para recursos |
| NetworkRuntime | Capa mutable en memoria que envuelve un `.tres` inmutable |
| GameRenderer | Clase de rendering separada de la lógica de juego |
| LevelManager | Conecta menú con carga de niveles |
| HackerMechanics | Sistema de mecánicas para el mundo Hacker |
| Data-Driven | Los datos viven en `.tres`, no hardcodeados |

## Lo que este proyecto ES

- Un simulador educativo de ciberseguridad basado en teoría de grafos
- Herramienta interactiva para aprender conceptos de redes de forma abstracta
- Implementación de Dijkstra y Edmonds-Karp en contexto de seguridad
- Sistema de niveles con mecánicas únicas por mundo (Heist, Hacker, Cybersecurity)
- Proyecto académico TSU con base teórica WJARR 2022

## Lo que este proyecto NO es

- No es un juego de hacking real — todas las mecánicas son abstractas y educativas
- No contiene exploits, comandos ni procedimientos replicables
- No es un cyber range profesional — es una herramienta de aprendizaje
- No persiste estado en disco (solo progreso de estrellas en user://)
