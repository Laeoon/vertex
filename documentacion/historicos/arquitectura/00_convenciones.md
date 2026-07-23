# 00 · Convenciones, Filosofía y Metodología

## Visión Actual

Este archivo es la fuente sobre cómo se trabaja en este proyecto. Cubre filosofía, convenciones del naming, metodología Sandbox-First, criterios de calidad de código, y reglas de documentación.

## Historia

Las convenciones nacen con el proyecto. Los principios rectores se definieron antes del Hito 1; la metodología Sandbox-First y los criterios de promoción se formalizaron durante el Hito 1.


## Lógica de Ingeniería

### 1. Principios rectores

Cuatro principios, en orden de importancia. Si una decisión viola uno, se discute; si viola dos, se revierte.

| # | Principio                     | Manifestación concreta                                                                                   |
|---|---|---|
| 1 | **Data-Driven**               | Cero datos de red hardcodeados en scripts. Topología completa en `.tres`.                                |
| 2 | **Sandbox-First**             | Nada entra a `core/` sin pasar antes por `sandboxes/`. El sandbox se queda como test de regresión.       |
| 3 | **Inmutabilidad del `.tres`** | El archivo de recurso no se modifica en runtime. Toda mutación va por `NetworkRuntime` (en memoria).     |
| 4 | **Tipado estricto**           | Variables, parámetros y retornos llevan tipo explícito. `Variant` solo donde es estrictamente necesario. |

### 2. Convenciones de naming

#### Carpetas y archivos

| Elemento          | Convención                                             | Ejemplo                                       |
|---|---|---|
| Sandbox folder    | `case_<LETRA>_<descriptivo>/`                          | `case_e_event_bus/`                           |
| Sandbox script    | `case_<LETRA>_sandbox.gd` o `<descriptivo>_sandbox.gd` | `case_a_sandbox.gd`, `case_events_sandbox.gd` |
| Doc tópico        | `arquitectura/<NN>_<componente>.md`                    | `arquitectura/01_grafo_estatico.md`           |
| Doc meta (este)   | `arquitectura/00_convenciones.md`|                     |
| Doc de deuda      | `arquitectura/99_deuda_tecnica.md` |                   |

La **letra** del sandbox es alfabética (no numérica) para forzar ordenamiento natural: el orden cronológico es evidente de un vistazo.

**Naming de sandboxes más allá de E**: se sigue con F, G, H, I... mientras queden letras razonables. Al agotar la Z (caso improbable: necesitaría ~26 sandboxes), se decide en su momento si reiniciar numéricamente (`case_aa`, `case_ab`...) 
#### Código

| Elemento | Convención | Ejemplo |
|---|---|---|
| Clases públicas | `PascalCase`, siempre con `class_name` | `DefensivePathfinder` |
| Clases internas | `_PascalCase` (prefijo underscore) | `_Result` (dentro de pathfinder) |
| Métodos públicos | `snake_case` | `find_path_with_cost` |
| Métodos privados | `_snake_case` (prefijo underscore) | `_dijkstra`, `_build_residual` |
| Constantes | `UPPER_SNAKE` | `INF_COST` |
| Variables de instancia | `snake_case` | `node_states`, `_adjacency` |
| Backing fields | `_snake_case` (mismo prefijo que privado) | `_state` |
| Enums | `PascalCase` para tipo, `UPPER_SNAKE` para valores | `NodeState.ALERTADO` |
| IDs de nodo | `StringName` con `&"..."` (no `String`) | `&"Firewall"` |

#### Nota: `class_name`

Declarar `class_name` en scripts públicos que se instancian como objetos (Resources, RefCounted). No declarar `class_name` en nodos que se añaden al árbol de escenas sin necesidad de registro global.

### 3. Metodología Sandbox-First

El protocolo de 4 pasos para introducir cualquier mecánica nueva:

```
   Sandbox (3 archivos)              Core (producción)
   ┌──────────────────┐              ┌──────────────────┐
   │ caso_sandbox.tscn │  ─promote─▶  │ core/network/...  │
   │ caso_test.gd      │              │                   │
   │ network_test.tres │  ─NO TOCA─▶  │ (los datos se     │
   └──────────────────┘              │  quedan en .tres) │
            ▲                        └──────────────────┘
            │
    se conserva para
    regresión futura
```

#### Paso 1 · Crear el contenedor aislado

Dentro de `res://sandboxes/`, una subcarpeta por caso. Dentro, una escena `.tscn` con un nodo raíz `Node` (o `Node2D` si hay UI) llamado `Sandbox`. Cero acoplamiento con el resto del proyecto.

#### Paso 2 · Configurar los datos en el Inspector

Si la mecánica depende de datos (un grafo, una configuración), crear un `.tres` en esa misma carpeta y configurarlo desde el Inspector. El escenario de prueba es legible y reproducible sin tocar código.

#### Paso 3 · Validar con `print()` y `assert()`

Conectar un `.gd` al nodo raíz de la escena. En `_ready()` orquestar la prueba:

- Cargar el `.tres`
- Instanciar el sistema a probar
- Imprimir resultados con `print()` (legible, con secciones)
- Verificar con `assert()` que el comportamiento es el esperado

El sandbox se ejecuta con `godot --headless --path <proyecto> res://sandboxes/.../<archivo>.tscn` desde la terminal.

#### Paso 4 · Promover al `core/`

Cuando el sandbox pasa consistentemente, el código va a `res://core/`. El sandbox **se queda** como test de regresión.

### 4. Criterios de calidad antes de promover

Un módulo se promueve de `sandbox/` a `core/` solo si cumple todos los puntos de cada bloque:

#### Estructura

- Existe en `core/<dominio>/` con archivos `.gd` en la cantidad y tipo correctos
- El sandbox original **sigue en su sitio** (no se borra al promover)
- Los datos del componente viven en `.tres` (si aplica), no hardcodeados

#### Calidad de código

- Tipado estático en todas las firmas (`int`, `float`, `String`, `StringName`, `Array[…]`, `Dictionary`, `bool`)
- `class_name` declarado en cada recurso público (excepto autoloads)
- Métodos `static` para funciones sin estado
- Manejo defensivo: valida inputs, devuelve defaults seguros, usa `push_warning` (no `assert`) para errores recuperables
- Constantes con nombres descriptivos (no magic numbers)

#### Data-Driven

- Cero datos de red hardcodeados en scripts de producción
- Topologías declaradas en `.tres` y editables desde el Inspector
- `.tres` permanece inmutable tras las simulaciones (verificado en sandbox)

#### Validación

- El sandbox correspondiente pasa consistentemente
- La salida del sandbox es legible: `print()` con secciones, `assert()` con mensajes
- El sandbox corre en headless sin abrir el editor

### 5. Reglas de documentación

- Estructura de docs tópicos: 5 secciones fijas (Visión, Historia, Lógica, Validación, Pendientes)
- Los links entre docs deben apuntar a archivos existentes al momento de la escritura
- Los errores reales encontrados durante el desarrollo se registran en consola con contexto y, si son relevantes, en `arquitectura/99_deuda_tecnica.md`

## Validación

Este archivo no tiene sandbox propio (es meta-documentación). El cumplimiento de las convenciones se valida transversalmente:

- Las convenciones de naming se verifican al leer los archivos en `core/`, `sandboxes/`, `docs/`
- La metodología Sandbox-First se valida porque los sandboxes existentes (A, B) la cumplen
- Los criterios de calidad se aplican retrospectivamente en cada `arquitectura/0X_*.md` (la sección "Validación" lista los asserts del sandbox que certificó la pieza)

### Cumplimiento verificado al cierre de Hito 1

| Convención | Cumplida | Evidencia |
|---|---|---|
| `class_name` en clases públicas | Sí | Todos los `core/*.gd` |
| `StringName` para IDs de nodo | Sí | Todos los `&"..."` en código de producción |
| Tipado estricto en firmas | Sí | Sin `Variant` |
| Manejo defensivo con `push_warning` | Sí | Validaciones de grafo nulo, nodos inexistentes |
| `.tres` inmutable | Sí | Verificado en sandbox B (recarga preserva valores) |
| Sandbox-First respetado | Sí | Sandboxes A y B certifican el Hito 1 |

## Pendientes

Convenciones que están implícitas en el código o en la práctica, pero que todavía no están formalizadas en este archivo. Candidatas a agregar en próximos hitos:

- **CONTRIBUTING.md**: guía de PR (qué commitear, formato de mensajes, convenciones de branch). No existe aún.
- **Política de versionado**: semver o calver. No hay releases todavía, pero conviene definirlo antes del Hito 6 (UI 2D).
- **Estilo de mensajes de commit**: conventional commits o libre. La historia actual es mixta.
- **Política de deprecación**: cuando se rompa una API pública, ¿cuál es el proceso? No aplica todavía porque no hay consumidores externos.

Estos puntos se migrarán a este mismo archivo cuando se definan. Mientras tanto, las decisiones se toman ad-hoc y se documentan en `arquitectura/99_deuda_tecnica.md` si son controversiales.
