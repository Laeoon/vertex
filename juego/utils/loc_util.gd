class_name LocUtil extends RefCounted
## Utilidad estática para localización (acceso al LocaleManager).
##
## Consolida la lógica duplicada de `loc()` que existía en 5 archivos:
## - `escenas/main_menu.gd`
## - `escenas/main_menu/tutorials_menu.gd`
## - `escenas/menu/database.gd`
## - `escenas/menu/profile.gd`
## - `escenas/menu/options.gd`
##
## Todas las funciones son estáticas — requieren un Node para acceder al
## SceneTree (no pueden ser puramente estáticas porque `get_tree()` es
## método de Node).


## Traduce una clave de localización usando el LocaleManager del árbol.
##
## Si no hay LocaleManager disponible o la clave no existe, devuelve la
## clave sin modificar (comportamiento idéntico al `loc()` original).
static func loc(node: Node, key: String) -> String:
	var tree := node.get_tree()
	if tree != null and tree.has_group("locale_manager"):
		var nodes := tree.get_nodes_in_group("locale_manager")
		if nodes.size() > 0:
			return nodes[0].loc(key)
	return key


## Cambia el locale activo vía el LocaleManager.
static func set_locale(node: Node, lang: String) -> void:
	var tree := node.get_tree()
	if tree != null and tree.has_group("locale_manager"):
		var nodes := tree.get_nodes_in_group("locale_manager")
		if nodes.size() > 0:
			nodes[0].set_locale(lang)


## Devuelve el LocaleManager o null si no está disponible.
static func get_manager(node: Node):
	var tree := node.get_tree()
	if tree != null and tree.has_group("locale_manager"):
		var nodes := tree.get_nodes_in_group("locale_manager")
		if nodes.size() > 0:
			return nodes[0]
	return null
