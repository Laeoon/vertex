# 05 · Validación y Sandboxes

## Visión Actual

El proyecto se valida exclusivamente vía **sandboxes headless**: escenas autocontenidas
con un script de prueba, un `.tres` con datos, y aserts que certifican el comportamiento.

## Sandboxes cerrados

| Letra | Carpeta | Hito | Qué valida | Asserciones |
|---|---|---|---|---|
| A | `case_a_connectivity_unidirectional/` | 1 | Conectividad básica + direccionalidad de aristas | 7 |
| B | `case_b_edge_dual_weights/` | 1 | Pesos duales independientes + inmutabilidad del .tres | 9 |

## Cómo correrlos

```bash
PROJECT=/home/leonardo/nuevo-proyecto-de-juego

godot --headless --path $PROJECT res://sandboxes/case_a_connectivity_unidirectional/case_a_sandbox.tscn
godot --headless --path $PROJECT res://sandboxes/case_b_edge_dual_weights/case_b_sandbox.tscn
```

Si todo va bien, cada uno termina con `CASO X SUPERADO`.

## Cobertura por pieza

| Pieza del `core/` | Sandbox que la certificó | Doc tópico |
|---|---|---|
| `NetworkNodeResource` | A, B | [`01_grafo_estatico.md`](01_grafo_estatico.md) |
| `NetworkEdgeResource` | A, B | [`01_grafo_estatico.md`](01_grafo_estatico.md) |
| `NetworkGraphResource` | A, B | [`01_grafo_estatico.md`](01_grafo_estatico.md) |
| `NetworkRuntime` | A, B | [`01_grafo_estatico.md`](01_grafo_estatico.md) |

## Metodología

El protocolo completo de 4 pasos (crear contenedor, configurar `.tres`, validar con
`print+assert`, promover a `core/`) está documentado en [`00_convenciones.md`](00_convenciones.md).
