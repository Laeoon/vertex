# 04 · Demo Visual Interactiva

## Objetivo

Tener una ventana gráfica donde se vea el grafo de red dibujado en pantalla:
nodos como círculos coloreados, aristas como flechas con pesos, y la posibilidad de
interactuar con teclado para cambiar estados y explorar la direccionalidad.

Esto permite **demostrar visualmente** lo que Sandbox A valida en terminal: que las
aristas son dirigidas y que `Firewall → Internet` no existe.

## Escenario

Dos topologías intercambiables en caliente con teclado:

### Demo (tecla `D`)

```
              ┌─────────── tc=2,mc=4 ──────────┐
              │                                 │
              ▼                                 │
   DNS (100)       Servidor (250) ──tc=5,mc=8──▶ Base_Datos (420)
                             ▲
                    tc=10,mc=3│
                             │
Internet (300) ──tc=1,mc=5──▶ Firewall (300)
                             │
                    tc=20,mc=1│
                             ▼
                        Base_Datos (420)
```

- **5 nodos**: Internet, Firewall, Servidor, Base_Datos, DNS
- **5 aristas** con distintos protocolos, transit_cost y mitigation_capacity
- Pensado para mostrar una topología realista de red

### Sandbox A (tecla `A`)

```
[ Internet ]  ──HTTPS,tc=1──▶  [ Firewall ]
     ▲                              │
     │                              ▼
    (NO existe)                 (sin salida)
```

- **2 nodos**: Internet, Firewall
- **1 arista**: Internet → Firewall
- **0 aristas** en dirección inversa
- Es el mismo grafo de `sandboxes/case_a_connectivity_unidirectional/`

## Archivos del sandbox

```
sandboxes/case_demo_visual/
├── demo_visual_sandbox.tscn
├── demo_visual_test.gd
└── network_demo_visual.tres
```

## Cómo se construyó

### 1. El punto de partida: Node2D + _draw()

Godot tiene un método especial `_draw()` que se ejecuta cada vez que el nodo
necesita redibujarse. Llamando a `queue_redraw()` podemos forzar un redibujado
cuando algo cambia (ej: un nodo pasó a estado ALERTADO).

```gdscript
extends Node2D

func _draw() -> void:
    draw_circle(Vector2(100, 100), 20, Color.GREEN)
    draw_line(Vector2(100, 100), Vector2(300, 100), Color.WHITE, 2.0)
```

Esa es la base: `draw_circle` para nodos, `draw_line` para aristas,
`draw_string` para etiquetas de texto.

### 2. Cargar el grafo desde .tres

En `_ready()` se carga el archivo `.tres` usando `load()`:

```gdscript
graph = load("res://sandboxes/case_demo_visual/network_demo_visual.tres") as NetworkGraphResource
runtime = NetworkRuntime.new(graph)
for n in graph.nodes:
    node_positions[n.id] = n.position
```

Las posiciones de cada nodo (`Vector2`) se leen del campo `position` del
`NetworkNodeResource` en el `.tres`. Así el grafo se define **en datos**, no
en código.

### 3. Dibujar aristas con flechas direccionales

Cada arista se dibuja como una línea desde la posición de `from_id` hasta
`to_id`. La flecha se construye con dos líneas cortas que forman una V al
final:

```gdscript
var dir: Vector2 = (to_pos - from_pos).normalized()
var tip: Vector2 = to_pos - dir * node_radius  # hasta el borde del círculo
draw_line(from_pos + dir * node_radius, tip, edge_color, 1.5)

# Flecha (V invertida en la punta)
var base: Vector2 = tip - dir * arrow_len
var perp: Vector2 = dir.rotated(PI / 2.0)
draw_line(tip, base + perp * arrow_w, edge_color, 2.5)
draw_line(tip, base - perp * arrow_w, edge_color, 2.5)
```

Las aristas se iluminan (color más brillante + línea más gruesa) cuando el
nodo origen o destino está seleccionado.

### 4. Dibujar nodos con colores según estado

Cada nodo se pinta de un color distinto según su estado en el runtime:

| Estado | Color | Significado |
|---|---|---|
| `disponible` | Verde | Funcionando normalmente |
| `alertado` | Amarillo | Amenaza detectada |
| `capturado` | Rojo | Comprometido |

```gdscript
match str(state):
    "alertado":
        node_color = Color.YELLOW
    "capturado":
        node_color = Color.RED
    _:
        node_color = Color(0.2, 0.85, 0.3)
```

Además se dibuja una **barra de amenaza** debajo de cada nodo (roja,
proporcional al nivel 0.0–1.0).

### 5. Interacción por teclado

El método `_input(event)` captura teclas y ejecuta acciones:

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        var k: InputEventKey = event as InputEventKey
        match k.keycode:
            KEY_SPACE: _cycle_selected_state()
            KEY_TAB:   _next_node()
            KEY_A:     _load_graph(SANDBOX_A_PATH)
            KEY_D:     _load_graph(DEMO_GRAPH_PATH)
            KEY_R:     _reset_all()
            KEY_Q:     get_tree().quit()
```

Cada acción modifica el runtime y llama a `queue_redraw()` para que `_draw()`
refleje el cambio.

### 6. Panel de información lateral

Se dibuja manualmente con `draw_string` en el lado derecho de la pantalla:

- **Salientes**: llama a `runtime.get_neighbors(selected_node)` y lista cada
  vecino con su `transit_cost` y `mitigation_capacity`
- **Entrantes**: recorre `graph.edges` buscando aristas donde `to_id` sea el
  nodo seleccionado
- **Prueba Sandbox A**: ejecuta `runtime.has_edge(A, B)` y
  `runtime.has_edge(B, A)` para los dos primeros nodos del grafo, y muestra
  si hay unidireccionalidad o no

### 7. Carga dinámica de grafos

Las teclas `A` y `D` cargan distintos archivos `.tres` en caliente:

```gdscript
func _load_graph(path: String) -> void:
    graph = load(path) as NetworkGraphResource
    runtime = NetworkRuntime.new(graph)
    # ... reconstruir node_positions ...
    queue_redraw()
```

Esto permite alternar entre el grafo de 5 nodos (demo) y el de 2 nodos
(Sandbox A) sin cerrar la ventana.

## Controles

| Tecla | Acción |
|---|---|
| `TAB` | Cambiar nodo seleccionado |
| `ESPACIO` | Ciclar estado: disponible → alertado → capturado → disponible |
| `A` | Cargar grafo de Sandbox A (2 nodos, 1 arista) |
| `D` | Cargar grafo Demo (5 nodos, 5 aristas) |
| `R` | Reiniciar todos los nodos a disponible |
| `Q` | Salir |

## Comando para ejecutar

```bash
godot --path /home/leonardo/nuevo-proyecto-de-juego \
      res://sandboxes/case_demo_visual/demo_visual_sandbox.tscn
```

(Sin `--headless` porque necesitás la ventana gráfica.)

## Por qué importa

Hasta ahora todas las validaciones se hacían por terminal con `print()` y
`assert()`. La demo visual permite:

- **Mostrar a los profesores** cómo funciona la capa de datos sin que tengan
  que leer código
- **Entender la direccionalidad** viendo las flechas en pantalla: queda
  evidente qué conexiones existen y cuáles no
- **Experimentar con estados** en tiempo real: presionando ESPACIO se ve
  el cambio de color del círculo y la barra de amenaza
- **Probar ambos grafos** (Sandbox A y Demo) en la misma ventana con solo
  presionar una tecla

## ✅ Criterio de aceptación

- [x] La ventana se abre y muestra el grafo correctamente
- [x] Las flechas respetan la dirección de las aristas
- [x] Los estados se reflejan en colores (verde/amarillo/rojo)
- [x] El panel lateral muestra salientes/entrantes correctamente
- [x] La prueba Sandbox A funciona: `has_edge(Internet,Firewall)=true`,
      `has_edge(Firewall,Internet)=false`
- [x] Se puede alternar entre grafo demo y Sandbox A con teclas A/D
- [x] No requiere `--headless`, usa ventana nativa de Godot
