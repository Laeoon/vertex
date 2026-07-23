# Quickstart — Tour guiado

> **Para quién es esto**: devs que llegan al proyecto por primera vez.

## La idea en una línea

Simulás una red informática. Hay nodos (`Internet`, `Firewall`) conectados por aristas dirigidas con pesos. El sandbox A verifica que la dirección se respeta.

## Paso 1 — Mirar un `.tres` (datos, no código)

Los datos viven en `res://`. Mirá `sandboxes/case_a_connectivity_unidirectional/network_test_a.tres`. Es un grafo de 2 nodos y 1 arista:

```
[ Internet ]  --HTTPS-->  [ Firewall ]
   (origen)                (sin salida)
```

## Paso 2 — Cargar el grafo en código

```gdscript
var graph: NetworkGraphResource = load("res://sandboxes/case_a_connectivity_unidirectional/network_test_a.tres")
var runtime: NetworkRuntime = NetworkRuntime.new(graph)
```

## Paso 3 — Consultar la topología

```gdscript
runtime.get_neighbors(&"Internet")   # devuelve [Firewall]
runtime.get_neighbors(&"Firewall")   # devuelve []
runtime.has_edge(&"Internet", &"Firewall")   # true
runtime.has_edge(&"Firewall", &"Internet")   # false
```

## Paso 4 — Correr los sandboxes

```bash
PROJECT=/home/leonardo/nuevo-proyecto-de-juego

# Sandbox A — unidireccionalidad
godot --headless --path $PROJECT \
  res://sandboxes/case_a_connectivity_unidirectional/case_a_sandbox.tscn

# Sandbox B — pesos duales independientes
godot --headless --path $PROJECT \
  res://sandboxes/case_b_edge_dual_weights/case_b_sandbox.tscn
```

Salida esperada: `✅ CASO A SUPERADO` y `✅ CASO B SUPERADO`

## Próximos pasos

| Si quieres... | Andá a... |
|---|---|
| Entender la estructura del grafo | `historico/02_estructura_del_grafo.md` |
| Ver el sandbox A en detalle | `historico/03_sandbox_caso_a.md` |
| Ver el sandbox B en detalle | `historico/05_sandbox_caso_b.md` |
| Demo visual interactiva | `historico/04_demo_visual.md` y `historico/06_demo_dual_weights.md` |
| Conocer las reglas del proyecto | `arquitectura/00_convenciones.md` |
