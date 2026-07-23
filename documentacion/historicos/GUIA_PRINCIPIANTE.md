# Guía para Principiantes — Godot + GDScript + Este Proyecto

> Para: compañeros que nunca tocaron Godot y necesitan entender el código.
>
> Prerrequisitos: tener Godot 4.6.3 instalado y el proyecto clonado.

---

## 1. ¿Qué es Godot?

Godot es un motor para hacer juegos y simulaciones. Acá lo usamos **sin interfaz gráfica**
(para validar algoritmos), pero igual necesitás conocer 3 conceptos:

| Concepto | Explicación | En este proyecto |
|---|---|---|
| **Nodo** | Pieza básica: un `Node` puede tener hijos. Forman un árbol. | El `Sandbox` es un `Node` que ejecuta la prueba |
| **Escena** (`tscn`) | Conjunto de nodos guardado en archivo. | `case_a_sandbox.tscn` |
| **Inspector** | Panel derecho del editor. Muestra propiedades del nodo seleccionado. | Sirve para editar `.tres` sin escribir código |

## 2. Abrir el proyecto

```
1. Abrí Godot 4.6.3
2. Click en "Importar" (Import)
3. Seleccioná la carpeta del proyecto (donde está project.godot)
4. Click en "Importar y Editar"
```

Una vez abierto, vas a ver:

- **Panel izquierdo**: FileSystem (todos los archivos del proyecto)
- **Centro**: editor de escenas / scripts
- **Derecha**: Inspector

### Estructura del proyecto

```
core/network/         → código del grafo (recursos + runtime)
sandboxes/
  case_a/             → Sandbox A: unidireccionalidad
  case_b/             → Sandbox B: pesos duales independientes
  case_demo_visual/   → demo visual interactiva
  case_demo_dual/     → demo visual de pesos duales
docs/                 → documentación
```

## 3. Ejecutar el Sandbox A (primera prueba)

### Desde el editor

1. En FileSystem, navegá a `sandboxes/case_a_connectivity_unidirectional/`
2. Hacé doble click en `case_a_sandbox.tscn`
3. Presioná **F6** (o menú Scene → Run Current Scene)

Vas a ver la consola imprimir algo como:

```
===============================================
  SANDBOX A: Conectividad Unidireccional
===============================================
✅ CASO A SUPERADO: la estructura respeta la unidireccionalidad
```

Si no ves errores, todo funciona.

### Desde la terminal (más rápido para pruebas)

```bash
cd /ruta/al/proyecto
godot --headless --path . res://sandboxes/case_a_connectivity_unidirectional/case_a_sandbox.tscn
```

El flag `--headless` corre sin abrir la ventana del editor. Ideal para automatizar.

---

## 4. GDScript mínimo para entender este proyecto

GDScript es parecido a Python. Acá está lo que aparece en el código del proyecto.

### Variables y tipos

```gdscript
var name: String = "Firewall"          # texto
var count: int = 42                     # número entero
var price: float = 1.5                  # número decimal
var is_active: bool = true              # verdadero/falso
```

### StringName (aparece como `&"..."`)

Es un string optimizado para búsquedas en diccionarios. Se escribe con `&` adelante:

```gdscript
var id := &"Firewall"         # StringName
var name: String = "Firewall"  # String común (no se usa como clave)
```

**Regla práctica**: si vas a usarlo como clave de diccionario o para identificar nodos del grafo, usá `StringName` con `&`. Si es para mostrar al usuario, usá `String`.

### Diccionarios (el pan de cada día)

```gdscript
# Diccionario simple: clave → valor
var person: Dictionary = {
	"name": "Juan",
	"age": 30
}
print(person["name"])   # imprime "Juan"

# Diccionario anidado (clave → {clave → datos})
var adjacency := {
	"Internet": {
		"Firewall": { "cost": 1.0 }
	}
}
print(adjacency["Internet"]["Firewall"]["cost"])  # imprime 1.0
```

### Arrays

```gdscript
var numbers: Array[int] = [1, 2, 3]
numbers.append(4)
print(numbers.size())    # 4
print(numbers[0])        # 1 (el primer elemento)

# Array sin tipo específico
var mixed := ["texto", 42, true]
```

### Funciones

```gdscript
# Función simple
func sum(a: int, b: int) -> int:
	return a + b

# Función que no devuelve nada
func log_message(msg: String) -> void:
	print(msg)
```

### if / for / in

```gdscript
# if
if x > 10:
	print("grande")
elif x > 5:
	print("mediano")
else:
	print("chico")

# for sobre array
var items := ["a", "b", "c"]
for item in items:
	print(item)

# for sobre diccionario (claves)
var dict := {"a": 1, "b": 2}
for key in dict.keys():
	print(key, " → ", dict[key])
```

### assert() — la herramienta de validación

```gdscript
assert(1 + 1 == 2, "las matemáticas no fallan")
# Si el assert falla, el programa se detiene con error
```

### extends — de dónde hereda cada clase

```gdscript
extends Node          # puede vivir en el árbol de escenas (como el Sandbox)
extends Resource      # sus datos se guardan en archivo .tres
extends RefCounted    # vive solo en memoria, no persiste (como NetworkRuntime)
```

---

## 5. Recorrido: `network_node_resource.gd` — el vértice del grafo

```gdscript
class_name NetworkNodeResource extends Resource
```

- `class_name` hace que cualquier otro script pueda usar `NetworkNodeResource` sin importarlo.
- `extends Resource` significa que los datos de esta clase se pueden guardar en un archivo `.tres`.

```gdscript
enum NodeType {
	INTERNET,
	FIREWALL,
	ROUTER,
	SERVER,
	WORKSTATION,
	DATABASE,
}
```

Los `enum` son constantes agrupadas. Adentro del código se usan como `NodeType.FIREWALL`.
En el archivo `.tres` se guardan como números (0, 1, 2...).

```gdscript
@export var id: StringName = &""
```

`@export` hace que esta variable aparezca en el Inspector de Godot.
Se puede editar visualmente sin tocar código.

### Ejemplo de uso

```gdscript
# En cualquier script del proyecto:
var nodo := NetworkNodeResource.new()
nodo.id = &"Servidor_Web"
nodo.node_type = NetworkNode.NodeType.SERVER
nodo.display_name = "Servidor Web Principal"
nodo.position = Vector2(300, 150)
```

---

## 6. Recorrido: `network_edge_resource.gd` — la arista

```gdscript
class_name NetworkEdgeResource extends Resource

@export var from_id: StringName = &""
@export var to_id: StringName = &""
@export var transit_cost: float = 1.0
@export var mitigation_capacity: float = 1.0
@export var protocol: StringName = &"TCP"
```

Una arista **dirigida**: va de `from_id` a `to_id`.
Tiene **dos pesos independientes**: `transit_cost` (latencia) y `mitigation_capacity` (capacidad).

### Ejemplo de uso

```gdscript
var edge := NetworkEdgeResource.new()
edge.from_id = &"Firewall"
edge.to_id = &"Servidor_Web"
edge.transit_cost = 10.0          # costo de ruta (Dijkstra)
edge.mitigation_capacity = 3.0    # capacidad de mitigación (Edmonds-Karp)
edge.protocol = &"HTTPS"

# Preguntar si es un self-loop
print(edge.is_self_loop())  # false
```

---

## 7. Recorrido: `network_graph_resource.gd` — el contenedor del grafo

```gdscript
class_name NetworkGraphResource extends Resource

@export var nodes: Array[NetworkNodeResource] = []
@export var edges: Array[NetworkEdgeResource] = []
@export var directed: bool = true
```

Tiene un array de nodos y un array de aristas. Eso es todo: es la "foto" de la red.

### validate() — el control de calidad

```gdscript
func validate() -> Array[String]:
	# devuelve una lista de errores
	# si está vacía, el grafo es válido
```

### Ejemplo de uso

```gdscript
var graph := NetworkGraphResource.new()
graph.nodes = [node_internet, node_firewall]
graph.edges = [edge_internet_firewall]

var errors := graph.validate()
if errors.is_empty():
	print("Grafo válido 👍")
else:
	for e in errors:
		push_error(e)

# También: consultar tamaño
print(graph.node_count())  # cantidad de nodos
print(graph.edge_count())  # cantidad de aristas
```

---

## 8. Recorrido: `network_runtime.gd` — el motor de consultas

Este es el archivo más importante. Es la capa **mutable** en memoria que permite
preguntarle cosas al grafo.

```gdscript
class_name NetworkRuntime extends RefCounted
```

`extends RefCounted` → no necesita `free()`, Godot lo borra solo cuando no se usa más.

### Cómo se usa

```gdscript
# 1. Cargar el grafo desde un archivo .tres
var graph := load("res://sandboxes/case_a_connectivity_unidirectional/network_test_a.tres") as NetworkGraphResource

# 2. Crear el runtime (esto construye el índice de adyacencia)
var runtime := NetworkRuntime.new(graph)

# 3. Hacer consultas
var tiene_conexion: bool = runtime.has_edge(&"Internet", &"Firewall")
# → true

var vecinos: Array = runtime.get_neighbors(&"Firewall")
# → [] (Firewall no tiene salidas)

var costo: float = runtime.get_transit_cost(&"Internet", &"Firewall")
# → 1.0

var capacidad: float = runtime.get_mitigation_capacity(&"Internet", &"Firewall")
# → 1.0
```

### ¿Qué pasa si la arista no existe?

```gdscript
var costo_inverso := runtime.get_transit_cost(&"Firewall", &"Internet")
# → INF (no existe la arista en esa dirección)

var capacidad_inversa := runtime.get_mitigation_capacity(&"Firewall", &"Internet")
# → 0.0 (no existe)
```

### ¿Cómo se modifica algo?

```gdscript
# Cambiar el costo de tránsito (solo en memoria, el .tres no se modifica)
runtime.set_transit_cost(&"Internet", &"Firewall", 99.0)
print(runtime.get_transit_cost(&"Internet", &"Firewall"))  # 99.0

# Cambiar el estado de un nodo
runtime.set_node_state(&"Firewall", &"alertado")
print(runtime.get_node_state(&"Firewall"))  # "alertado"

# Nivel de amenaza
runtime.set_threat_level(&"Firewall", 0.8)
print(runtime.get_threat_level(&"Firewall"))  # 0.8
```

### Ejemplo completo: crear un grafo desde código

```gdscript
# 1. Crear nodos
var internet := NetworkNodeResource.new()
internet.id = &"Internet"
internet.node_type = NetworkNodeResource.NodeType.INTERNET
internet.display_name = "Internet Pública"

var firewall := NetworkNodeResource.new()
firewall.id = &"Firewall"
firewall.node_type = NetworkNodeResource.NodeType.FIREWALL
firewall.display_name = "Firewall Perimetral"

# 2. Crear arista (Internet → Firewall)
var edge := NetworkEdgeResource.new()
edge.from_id = &"Internet"
edge.to_id = &"Firewall"
edge.transit_cost = 5.0
edge.mitigation_capacity = 10.0
edge.protocol = &"HTTPS"

# 3. Armar el grafo
var graph := NetworkGraphResource.new()
graph.nodes = [internet, firewall]
graph.edges = [edge]

# 4. Validar
assert(graph.validate().is_empty(), "El grafo debe ser válido")

# 5. Crear runtime y consultar
var runtime := NetworkRuntime.new(graph)
assert(runtime.has_edge(&"Internet", &"Firewall"))
assert(not runtime.has_edge(&"Firewall", &"Internet"))
print("✅ Grafo creado y verificado")
```

---

## 9. Anatomía de un archivo `.tres`

El archivo `network_test_a.tres` define la topología. Es texto plano, se puede editar
a mano o desde el Inspector de Godot.

```
[gd_resource type="Resource" script_class="NetworkGraphResource" load_steps=6 format=3]

[ext_resource type="Script" path="res://core/network/network_node_resource.gd" id="2_node"]
[ext_resource type="Script" path="res://core/network/network_edge_resource.gd" id="3_edge"]
[ext_resource type="Script" path="res://core/network/network_graph_resource.gd" id="1_graph"]

[sub_resource type="Resource" id="Node_Internet"]
script = ExtResource("2_node")
id = &"Internet"
display_name = "Internet (red pública)"
node_type = 0
position = Vector2(100, 200)

[sub_resource type="Resource" id="Node_Firewall"]
script = ExtResource("2_node")
id = &"Firewall"
display_name = "Firewall Perimetral"
node_type = 1
position = Vector2(400, 200)

[sub_resource type="Resource" id="Edge_A"]
script = ExtResource("3_edge")
from_id = &"Internet"
to_id = &"Firewall"
transit_cost = 1.0
mitigation_capacity = 1.0
protocol = &"HTTPS"

[resource]
script = ExtResource("1_graph")
nodes = Array[Resource]([SubResource("Node_Internet"), SubResource("Node_Firewall")])
edges = Array[Resource]([SubResource("Edge_A")])
directed = true
```

### Cómo crear un `.tres` desde el editor

1. En FileSystem, hacé click derecho → `New Resource...`
2. Buscá `NetworkGraphResource` en la lista
3. Guardalo con un nombre (ej: `mi_red.tres`)
4. En el Inspector, agregá nodos y aristas desde las propiedades `nodes` y `edges`

### Cómo cargarlo desde código

```gdscript
var graph := load("res://ruta/a/mi_red.tres") as NetworkGraphResource
var runtime := NetworkRuntime.new(graph)
```

---

## 10. Recorrido completo: `case_a_test.gd`

Este es el script que valida el Sandbox A. Leelo completo:

```gdscript
extends Node
```

Es un `Node` (vive en la escena, tiene `_ready()`).

```gdscript
const NetworkGraphResource = preload("res://core/network/network_graph_resource.gd")
const NetworkRuntime = preload("res://core/network/network_runtime.gd")
```

`preload()` carga el script al inicio. Es como `import` en otros lenguajes.

```gdscript
func _ready() -> void:
```

`_ready()` se ejecuta automáticamente cuando el nodo aparece en la escena.
Es el punto de entrada del sandbox.

```gdscript
	var graph: NetworkGraphResource = load("res://sandboxes/case_a_connectivity_unidirectional/network_test_a.tres")
```

`load()` carga un archivo en tiempo de ejecución (distinto a `preload`).

```gdscript
	var errors: Array[String] = graph.validate()
	assert(errors.is_empty(), "El grafo debería ser válido")
```

Primero se valida el grafo, después se usa.

```gdscript
	var runtime := NetworkRuntime.new(graph)
```

Se envuelve el grafo en el runtime (que es quien tiene la caché de adyacencia).

```gdscript
	var internet_neighbors: Array = runtime.get_neighbors(&"Internet")
	assert(internet_neighbors.size() == 1)
```

Se consultan los vecinos y se verifica con `assert()`.

```gdscript
	print("\n✅ CASO A SUPERADO: la estructura respeta la unidireccionalidad")
	get_tree().quit()
```

Al final se imprime éxito y se cierra la simulación con `get_tree().quit()`.

---

## 11. Flujo de trabajo típico

```
1. Crear o modificar un .tres con la topología que querés probar
2. Escribir un script que cargue el .tres y haga asserts
3. Ejecutar con F6 o godot --headless
4. Si falla un assert → corregir → volver a ejecutar
```

### Tu primer script desde cero

```gdscript
# 1. Creá un archivo nuevo: sandboxes/mi_prueba/mi_test.gd
# 2. Pegá esto:

extends Node

func _ready() -> void:
	# Cargar el .tres del sandbox A
	var graph := load("res://sandboxes/case_a_connectivity_unidirectional/network_test_a.tres") as NetworkGraphResource
	var runtime := NetworkRuntime.new(graph)

	# Consultar
	print("¿Internet → Firewall? ", runtime.has_edge(&"Internet", &"Firewall"))
	print("¿Firewall → Internet? ", runtime.has_edge(&"Firewall", &"Internet"))

	# Modificar
	runtime.set_transit_cost(&"Internet", &"Firewall", 99.0)
	print("Nuevo costo: ", runtime.get_transit_cost(&"Internet", &"Firewall"))

	# Validar
	assert(runtime.get_mitigation_capacity(&"Internet", &"Firewall") == 1.0, "El otro peso no se tocó")

	print("✅ Todo bien, el runtime funciona")
	get_tree().quit()
```

```gdscript
# 3. Creá una escena que use ese script:
#    - Nueva escena → Node (raíz)
#    - En el Inspector, asignale el script mi_test.gd
# 4. Ejecutá con F6
```

---

## 12. Glosario rápido

| Término | Explicación | Cómo se escribe |
|---|---|---|
| `StringName` | String optimizado para claves | `&"Firewall"` |
| `Dictionary` | Mapa clave → valor | `{"clave": "valor"}` |
| `Array` | Lista de elementos | `[1, 2, 3]` |
| `@export` | Propiedad visible en Inspector | `@export var x: int` |
| `extends` | De quién hereda | `extends Resource` |
| `class_name` | Hace la clase global | `class_name MiClase` |
| `assert(cond, msg)` | Si falla, se detiene | `assert(x == 1)` |
| `preload()` | Carga al compilar | `preload("ruta.gd")` |
| `load()` | Carga al ejecutar | `load("ruta.tres")` |
| `INF` | Infinito (arista no existe) | `const INF_COST = INF` |
| `_ready()` | Se ejecuta al iniciar | `func _ready():` |
| `_init()` | Constructor de la clase | `func _init():` |
| `get_tree().quit()` | Cierra la simulación | `get_tree().quit()` |
| `push_warning()` | Advertencia sin detener | `push_warning("cuidado")` |

---

## 13. Si algo no funciona

- **"No encuentra el script"** → revisá que la ruta en `preload()` o `load()` sea correcta
- **"Assertion failed"** → leé el mensaje del assert, dice exactamente qué se esperaba
- **"Class_name no encontrado"** → asegurate de que el script existe y está bien escrito
- **"No se puede cargar el .tres"** → abrí el archivo en el editor, probablemente tiene referencias rotas
- **El sandbox no termina** → si falta `get_tree().quit()`, Godot se queda esperando

Siempre corré primero el sandbox A para confirmar que el proyecto base funciona.
