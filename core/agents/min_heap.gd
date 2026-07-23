class_name MinHeap extends RefCounted

## Min-heap binario keyed por un float (priority).
## Almacena entradas del tipo [priority: float, payload: Variant].
##
## Usado por el algoritmo de Dijkstra del agente defensivo
## (DefensivePathfinder) para extraer el nodo con menor distancia
## acumulada en O(log N) en vez de O(N) por extracción.
##
## No es un heap genérico: se especializa en [float, Variant] para
## mantener el tipado estricto. El payload (segundo elemento) puede
## ser cualquier cosa (típicamente StringName, el id del nodo).
##
## Complejidad:
##   push  → O(log N)
##   pop   → O(log N)
##   peek  → O(1)
##   size  → O(1)

var _data: Array = []  # Array<Array> donde cada entry = [priority, payload]


func push(priority: float, payload: Variant) -> void:
	_data.append([priority, payload])
	_sift_up(_data.size() - 1)


## Devuelve la entrada [priority, payload] de menor priority.
## Assertea si el heap está vacío.
func pop() -> Array:
	assert(not _data.is_empty(), "MinHeap.pop() en heap vacío")
	var top: Array = _data[0]
	var last: Array = _data.pop_back()
	if not _data.is_empty():
		_data[0] = last
		_sift_down(0)
	return top


## Devuelve (sin extraer) la entrada de menor priority.
func peek() -> Array:
	assert(not _data.is_empty(), "MinHeap.peek() en heap vacío")
	return _data[0]


func is_empty() -> bool:
	return _data.is_empty()


func size() -> int:
	return _data.size()


func clear() -> void:
	_data.clear()


# ─── Operaciones internas (sift up / sift down) ───────────────────────

func _sift_up(idx: int) -> void:
	while idx > 0:
		var parent: int = (idx - 1) / 2
		if _data[idx][0] < _data[parent][0]:
			var tmp: Array = _data[idx]
			_data[idx] = _data[parent]
			_data[parent] = tmp
			idx = parent
		else:
			break


func _sift_down(idx: int) -> void:
	var n: int = _data.size()
	while true:
		var left: int = 2 * idx + 1
		var right: int = 2 * idx + 2
		var smallest: int = idx
		if left < n and _data[left][0] < _data[smallest][0]:
			smallest = left
		if right < n and _data[right][0] < _data[smallest][0]:
			smallest = right
		if smallest == idx:
			break
		var tmp: Array = _data[idx]
		_data[idx] = _data[smallest]
		_data[smallest] = tmp
		idx = smallest
