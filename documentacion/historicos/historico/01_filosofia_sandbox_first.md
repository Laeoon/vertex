# 01 · Filosofía Sandbox-First

## La regla de oro

> **Ninguna mecánica, algoritmo o estructura de datos se integra al `core/` sin haber sido certificada en un `sandbox/`.**

Suena a burocracia, pero te ahorra horas. La idea es simple: si tu algoritmo de Dijkstra tiene un bucle infinito o corrompe memoria, solo rompe una escena aislada de 3 archivos. La simulación principal queda intacta.

## Los 4 pasos del protocolo

### Paso 1 · Crear el contenedor aislado

Dentro de `res://sandboxes/`, una subcarpeta por caso:

```
sandboxes/case_a_connectivity_unidirectional/
```

Dentro, una escena `.tscn` con un nodo raíz `Node` (o `Node2D` si hay UI) llamado `Sandbox`. Sin más. Cero acoplamiento.

### Paso 2 · Configurar los datos en el Inspector

Si la mecánica depende de datos (un grafo, por ejemplo), crea un `.tres` en esa misma carpeta y configúralo desde el Inspector. Así el escenario de prueba es **legible y reproducible** sin tocar código.

### Paso 3 · Validar con `print()` y `assert()`

Conecta un `.gd` al nodo raíz de la escena. En `_ready()` orquesta la prueba:

- carga el `.tres`
- instancia el sistema a probar
- imprime resultados con `print()`
- verifica con `assert()` que el comportamiento es el esperado

El sandbox se ejecuta con **F6 en el editor** o con `godot --headless ...` desde la terminal. Es instantáneo.

### Paso 4 · Promover al `core/`

Cuando el sandbox pasa consistentemente, el código va a `res://core/`. **El sandbox se queda** como test de regresión: si en seis meses rompes Dijkstra y el sandbox A empieza a fallar, sabes exactamente qué commit lo rompió.

## Por qué funciona

| Beneficio | Cómo se manifiesta |
|---|---|
| **Fallas confinadas** | Un bucle infinito solo congela la escena de prueba, no el juego entero |
| **Pruebas de estrés limpias** | Puedes meter 10.000 nodos en un sandbox sin miedo a romper niveles reales |
| **Validación en segundos** | `F6` en Godot corre el sandbox al instante; `F5` carga todo el juego |
| **Documentación ejecutable** | El sandbox es a la vez prueba y ejemplo de uso de la API |

## Inmutabilidad: la otra mitad de la regla

El `.tres` define la **topología estática**. Los cambios en tiempo de ejecución se hacen sobre **instancias en memoria** controladas por el `NetworkRuntime`. Nunca escribimos sobre el archivo `.tres` durante la simulación.

Esto se consigue con un wrapper mutable (`NetworkRuntime` en nuestro caso) que envuelve el recurso inmutable. El runtime expone getters y setters, pero el `.tres` original queda virgen para que la próxima simulación parta del mismo estado limpio.

## Resumen visual

```
       Sandbox (3 archivos)              Core (producción)
       ┌──────────────────┐              ┌──────────────────┐
       │ caso_sandbox.tscn │   ─promote─▶ │ core/network/...  │
       │ caso_test.gd      │              │                   │
       │ network_test.tres │   ─NO TOCA─▶ │ (los datos se     │
       └──────────────────┘              │  quedan en .tres) │
                ▲                        └──────────────────┘
                │
        se conserva para
        regresión futura
```

## ✅ Criterio de aceptación de esta fase

- [x] Existe `res://sandboxes/` con subcarpetas por caso
- [x] Existe `res://core/` con subcarpetas por dominio (`network`)
- [x] Cada sandbox tiene `tscn + gd + tres`
- [x] La documentación de cada paso queda en `docs/`
