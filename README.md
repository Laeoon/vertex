# VERTEX

**Simulador de Ciberseguridad Basado en Teoría de Grafos**

Juego educativo que enseña conceptos de ciberseguridad y teoría de grafos mediante mecánicas de estrategia. El jugador debe navegar redes, evitar detección, y completar objetivos usando algoritmos como Dijkstra (pathfinding) y Edmonds-Karp (max-flow/min-cut).

## Descarga Rápida

Si solo querés una copia del proyecto (sin historial de Git):

```bash
# Última versión estable (main branch)
curl -L -o vertex.tar.gz https://github.com/Laeoon/vertex/archive/refs/heads/main.tar.gz
tar -xzf vertex.tar.gz && cd vertex-main

# Versión específica (ej: alfa 0.1.0 - reemplazar con el tag real)
curl -L -o vertex.tar.gz https://github.com/Laeoon/vertex/archive/refs/tags/v0.1.0-alpha.tar.gz
tar -xzf vertex.tar.gz
```

**Alternativas:**

```bash
# Con wget (si no tenés curl)
wget https://github.com/Laeoon/vertex/archive/refs/heads/main.tar.gz

# Clonar con historial completo (recomendado para desarrollo)
git clone https://github.com/Laeoon/vertex.git
cd vertex

# Solo una versión específica de forma shallow (más rápido, menos espacio)
git clone --depth 1 https://github.com/Laeoon/vertex.git
```

Después de descargar, abrí `project.godot` con Godot 4.7+ y presioná F5.

## Stack

- **Motor**: Godot 4.7 (GDScript)
- **Física**: Jolt Physics
- **Renderizado**: Forward Plus
- **IA**: ZIVA Agent (GDExtension)

## Estructura del Proyecto

```
VERTEX/
├── core/                    # Motor de teoría de grafos
│   ├── agents/              # Algoritmos (Dijkstra, Edmonds-Karp, MinHeap)
│   ├── network/             # Recursos de red (graph, nodes, edges)
│   ├── fsm/                 # Máquinas de estado (network_node)
│   ├── integration/         # Wrappers reactivos
│   ├── autoloads/           # Singletons globales (Events, SceneParams, etc.)
│   └── locale/              # Internacionalización (ES/EN/PT)
│
├── juego/                   # Lógica del juego
│   ├── ataque/              # Modo ataque (gameplay principal)
│   ├── defense/             # Modo defensa
│   ├── hacker/              # Modo hacker
│   ├── heist/               # Modo heist
│   ├── system/              # Gestión de niveles
│   └── tutorials/           # Sistema de tutoriales
│
├── escenas/                 # Escenas Godot (.tscn)
├── addons/                  # Plugins (ziva_agent)
├── tests/                   # Tests automatizados
└── documentacion/           # Documentación del proyecto
```

## Arquitectura

El proyecto sigue una arquitectura en capas con separación clara de responsabilidades:

```
core/ (motor de grafos)
  ↓
juego/ (lógica de gameplay)
  ↓
escenas/ (UI y presentación)
```

**Principios:**
- `core/` es independiente de `juego/` (cero dependencias hacia arriba)
- Algoritmos stateless y testeables
- Event Bus para comunicación entre módulos
- Datos en recursos `.tres` y `.json` (data-driven design)

## Desarrollo

### Requisitos

- Godot 4.7+
- Jolt Physics (incluido en Godot 4.7)

### Correr el Proyecto

```bash
# Desde el editor de Godot
# Abrir project.godot y presionar F5

# Headless (para tests)
godot --headless --script res://tests/runner/run_all.gd
```

### Tests

El proyecto usa tests ad-hoc en GDScript:

```bash
# Correr todos los tests
godot --headless --script res://tests/runner/run_all.gd

# Correr un test específico
godot --headless --script res://tests/runner/_run_one.gd --test-path res://tests/core/test_defensive_pathfinder.gd
```

Ver [tests/README.md](tests/README.md) para más detalles.

## Convenciones de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/) en español técnico:

```
<tipo>(<alcance>): <descripción corta>

[opcional: cuerpo con más detalle]
```

**Tipos:**
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `refactor`: Refactorización sin cambiar comportamiento
- `test`: Añadir o modificar tests
- `docs`: Documentación
- `chore`: Tareas de mantenimiento
- `perf`: Mejoras de performance

**Ejemplos:**
```
feat(ataque): añadir modo hacker con mecánicas de ruido
fix(input-handler): validar graph/runtime antes de pathfinding
refactor(juego-ataque): extraer lógica de turno IA a AIBlocker
test(pathfinder): añadir tests para Dijkstra con grafos desconectados
docs(arquitectura): documentar flujo de datos entre core y juego
```

**Granularidad:**
- Un commit por tarea completada (para bisect preciso)
- Branch por feature/slice
- PR por cada cambio significativo

## Documentación

La documentación completa está en [`documentacion/`](documentacion/):

- [`documentacion/arquitectura/`](documentacion/arquitectura/) — Diseño del sistema
- [`documentacion/decisiones/`](documentacion/decisiones/) — ADRs (Architecture Decision Records)
- [`documentacion/guias/`](documentacion/guias/) — Guías de desarrollo

## Licencia

[TBD - Por definir]

## Contacto

[TBD - Por definir]
