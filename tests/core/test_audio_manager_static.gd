extends Node

## Prueba estática de AudioManager (core/autoloads/audio_manager.gd).
##
## Deliberadamente NO reproduce audio (headless usa dummy driver y el
## runner no lo soporta): verifica que el script parsea, instancia, genera
## su banco de sonidos procedural en _ready() sin crash, y expone la API
## pública. El script no referencia otros autoloads, así que corre como
## test de script (`--script`) con una copia local.

const AudioManagerScript = preload("res://core/autoloads/audio_manager.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var am: Node = Node.new()
	am.set_script(AudioManagerScript)
	add_child(am)  # _ready() genera el banco procedural

	_afirmar(am is Node, "AudioManager instancia sin árbol de autoloads")

	for metodo in ["play_sfx", "play_music", "play_track", "play_world_music", "stop_music"]:
		_afirmar(am.has_method(metodo), "expone el método público %s()" % metodo)

	var sonidos: Dictionary = am.get("_sounds")
	var esperados: Array = [
		"move", "block", "win", "lose", "click",
		"alert", "scan", "exploit", "firewall", "reset",
	]
	var faltantes: Array = []
	for clave in esperados:
		if not sonidos.has(clave):
			faltantes.append(clave)
	_afirmar(faltantes.is_empty(),
		"_ready() genera los 10 sonidos procedurales (faltan: %s)" % str(faltantes))

	var todos_wav: bool = true
	for clave in sonidos:
		if not (sonidos[clave] is AudioStreamWAV):
			todos_wav = false
	_afirmar(todos_wav and sonidos.size() == esperados.size(),
		"todas las entradas del banco son AudioStreamWAV (%d)" % sonidos.size())

	var player: Node = am.get("_music_player")
	_afirmar(player != null and player is AudioStreamPlayer,
		"_ready() crea el reproductor de música como hijo")

	_afirmar(bool(am.get("_initialized")), "queda marcado como inicializado")

	# play_sfx con nombre desconocido debe ser un no-op silencioso (guard),
	# sin reproducir nada — es lo único ejecutable de forma segura headless.
	am.play_sfx("sonido_inexistente")
	_afirmar(true, "play_sfx con nombre desconocido no crashea (guard _sounds)")

	var disk_sounds: Dictionary = am.get("_disk_sounds")
	_afirmar(disk_sounds.has("win") and disk_sounds.has("bypass"), "carga sonidos desde res://assets/audio/sfx/")

	var playlists: Dictionary = am.get("_world_music_playlists")
	_afirmar(playlists.has("menu") and playlists["menu"].size() >= 1, "playlist de menu configurada")
	_afirmar(playlists.has("heist") and playlists["heist"].size() == 8, "playlist de heist contiene las 8 pistas Pink Bloom de juego")
	_afirmar(playlists.has("hacker") and playlists["hacker"].size() == 13, "playlist de hacker contiene las 13 pistas Code Injection")

	am.play_world_music("mundo_inexistente")
	_afirmar(true, "play_world_music con mundo inexistente no crashea")

	am.play_menu_music()
	_afirmar(am.get("_current_music_world") == "menu", "play_menu_music activa el mundo 'menu'")

	var priorities: Dictionary = am.get("SFX_PRIORITY")
	_afirmar(priorities.get("win", 0) > priorities.get("bypass", 0), "prioridad de win es mayor que bypass")
	_afirmar(priorities.get("bypass", 0) > priorities.get("move", 0), "prioridad de bypass es mayor que move")

	am.stop_music()
	_afirmar(am.get("_current_music_world") == "", "stop_music limpia _current_music_world")

	_finalizar()


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _finalizar() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
