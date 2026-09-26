extends Node

## Gestor centralizado de audio con soporte para buses, pooling y sonidos en disco.
## Uso: AudioManager.play_sfx("move")

const SFX_POOL_SIZE: int = 8

const SFX_PRIORITY: Dictionary = {
	"win": 100,
	"lose": 100,
	"captured": 100,
	"alert": 80,
	"exploit": 60,
	"bypass": 60,
	"escalate": 60,
	"scalate": 60,
	"persist": 60,
	"decoy": 60,
	"firewall": 50,
	"scan": 40,
	"block": 30,
	"move": 10,
	"click": 5,
	"reset": 50,
}

var _sounds: Dictionary = {}
var _disk_sounds: Dictionary = {}
var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _initialized: bool = false

var _current_music_world: String = ""
var _current_music_path: String = ""
var _world_music_playlists: Dictionary = {
	"menu": [
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 01 - Pink Bloom.ogg",
	],
	"heist": [
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 02 - Portal to Underworld.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 03 - To the Unknown.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 04 - Valley of Spirits.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 05 - Western Cyberhorse.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 06 - Diamonds on The Ceiling.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 07 - The Hidden One.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 08 - Lost Spaceship's Signal.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 09 - Lightyear City.ogg",
	],
	"hacker": [
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 06 - Electric Inferno-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 07 - Binary Chaos-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 02 - Behind the Darkness-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 11 - I.A.'s Growl-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 04 - Secret Dissonance-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 03 - Synthetic Whisper-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 08 - Sentinel Cloud-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 09 - Ghost Steps-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 10 - Space Echoes-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 12 - Faceless Crowd-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 13 - Between Everyone and Anyone-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 14 - There's Someone Here-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 01 - Underbeat.ogg",
	],
}


func _ready() -> void:
	_ensure_audio_buses()
	_generate_sounds()
	_load_disk_sounds()
	_setup_music_player()
	_setup_sfx_pool()
	_initialized = true


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		var music_idx: int = AudioServer.bus_count
		AudioServer.add_bus(music_idx)
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")

	if AudioServer.get_bus_index("SFX") == -1:
		var sfx_idx: int = AudioServer.bus_count
		AudioServer.add_bus(sfx_idx)
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")


func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)


func _setup_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)


func _load_disk_sounds() -> void:
	var sound_files := {
		"bypass": "res://assets/audio/sfx/bypass.wav",
		"scalate": "res://assets/audio/sfx/scalate.wav",
		"escalate": "res://assets/audio/sfx/scalate.wav",
		"persist": "res://assets/audio/sfx/persist.wav",
		"decoy": "res://assets/audio/sfx/decoy.wav",
		"captured": "res://assets/audio/sfx/captured.wav",
		"lose": "res://assets/audio/sfx/captured.wav",
		"win": "res://assets/audio/sfx/win.wav",
	}
	for key in sound_files:
		var path: String = sound_files[key]
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AudioStream:
				_disk_sounds[key] = res


func _generate_sounds() -> void:
	var sr: float = 22050.0
	var moves := _make_tone(440.0, 0.08, sr)
	if moves != null:
		_sounds["move"] = moves
	_sounds["block"] = _make_tone(220.0, 0.15, sr)
	_sounds["win"] = _make_chord([523.25, 659.25, 783.99], 0.6, sr)
	_sounds["lose"] = _make_tone(155.56, 0.8, sr)
	_sounds["click"] = _make_tone(880.0, 0.04, sr)
	_sounds["alert"] = _make_tone(622.25, 0.2, sr)
	_sounds["scan"] = _make_sweep(0.3, sr)
	_sounds["exploit"] = _make_tone(698.46, 0.25, sr)
	_sounds["firewall"] = _make_tone(130.81, 0.4, sr)
	_sounds["reset"] = _make_tone(350.0, 0.12, sr)


func _make_tone(freq: float, dur: float, sr: float) -> AudioStreamWAV:
	var n: int = int(sr * dur)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / sr
		var env: float = exp(-3.0 * t / dur)
		var s: float = sin(2.0 * PI * freq * t) * 0.4 * env
		data.encode_s16(i * 2, int(clampf(s * 16384.0, -32768.0, 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(sr)
	wav.stereo = false
	return wav


func _make_chord(freqs: Array, dur: float, sr: float) -> AudioStreamWAV:
	var n: int = int(sr * dur)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / sr
		var env: float = exp(-2.0 * t / dur)
		var s: float = 0.0
		for f in freqs:
			s += sin(2.0 * PI * float(f) * t)
		s /= float(freqs.size())
		s *= 0.4 * env
		data.encode_s16(i * 2, int(clampf(s * 16384.0, -32768.0, 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(sr)
	wav.stereo = false
	return wav


func _make_sweep(dur: float, sr: float) -> AudioStreamWAV:
	var n: int = int(sr * dur)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / sr
		var env: float = exp(-3.0 * t / dur)
		var freq: float = 200.0 + 1800.0 * (t / dur)
		var s: float = sin(2.0 * PI * freq * t) * 0.3 * env
		s += (randf() - 0.5) * 0.2 * env
		data.encode_s16(i * 2, int(clampf(s * 16384.0, -32768.0, 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(sr)
	wav.stereo = false
	return wav


func has_sound(name: String) -> bool:
	return _disk_sounds.has(name) or _sounds.has(name)


func play_sfx(name: String, pitch_scale: float = 1.0) -> void:
	if not _initialized:
		return
	var stream: AudioStream = null
	if _disk_sounds.has(name):
		stream = _disk_sounds[name]
	elif _sounds.has(name):
		stream = _sounds[name]
	else:
		return

	var priority: int = SFX_PRIORITY.get(name, 20)

	# Si es un sonido de alta prioridad (e.g. win, lose, captured),
	# detener cualquier SFX de menor prioridad inmediatamente para evitar contaminación sonora.
	if priority >= 90:
		for p in _sfx_pool:
			if p.playing:
				var p_prio: int = p.get_meta("sfx_priority", 0)
				if p_prio < priority:
					p.stop()

	# Si el mismo sonido ya está sonando, reiniciarlo en ese reproductor
	# para evitar superposición redundante.
	for p in _sfx_pool:
		if p.playing and p.stream == stream:
			p.stop()
			p.pitch_scale = pitch_scale
			p.set_meta("sfx_priority", priority)
			p.play()
			return

	# Reutilizar un reproductor libre del pool
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if not p.playing:
			player = p
			break

	# Si todos están ocupados, buscar el de menor prioridad que sea inferior al nuevo
	if player == null and not _sfx_pool.is_empty():
		var lowest_prio_idx: int = -1
		var lowest_prio_val: int = 9999
		for i in range(_sfx_pool.size()):
			var p: AudioStreamPlayer = _sfx_pool[i]
			var p_prio: int = p.get_meta("sfx_priority", 0)
			if p_prio < lowest_prio_val:
				lowest_prio_val = p_prio
				lowest_prio_idx = i

		if lowest_prio_val <= priority and lowest_prio_idx != -1:
			player = _sfx_pool[lowest_prio_idx]
			player.stop()
		else:
			# Si el pool está ocupado por sonidos de mayor prioridad, descartar el de menor prioridad
			return

	if player != null:
		player.pitch_scale = pitch_scale
		player.stream = stream
		player.set_meta("sfx_priority", priority)
		player.play()
	else:
		var temp := AudioStreamPlayer.new()
		temp.bus = "SFX"
		temp.pitch_scale = pitch_scale
		temp.stream = stream
		temp.set_meta("sfx_priority", priority)
		temp.finished.connect(temp.queue_free)
		add_child(temp)
		temp.play()


func play_music(stream: AudioStream, volume_db: float = -10.0) -> void:
	if _music_player == null:
		return
	if _music_player.stream != stream:
		_music_player.stop()
		_music_player.stream = stream
	_music_player.volume_db = volume_db
	if not _music_player.playing:
		_music_player.play()


func play_track(path: String, volume_db: float = -12.0) -> void:
	if not _initialized or _music_player == null:
		return
	if _current_music_path == path and _music_player.playing:
		return
	if not ResourceLoader.exists(path):
		return
	var res = load(path)
	if res is AudioStream:
		if res is AudioStreamOggVorbis:
			res.loop = true
		_current_music_path = path
		play_music(res, volume_db)


func play_world_music(world_id: String, track_index: int = -1, volume_db: float = -12.0) -> void:
	if not _initialized:
		return
	var normalized_world := world_id.to_lower().strip_edges()
	# Si ya estamos sonando música del mismo mundo y track_index == -1, mantenemos la reproducción continua
	if _current_music_world == normalized_world and _music_player != null and _music_player.playing and track_index < 0:
		return

	if not _world_music_playlists.has(normalized_world):
		# Fallback para mundos sin playlist específica (ej: cybersecurity usa pistas hacker/cyber)
		if normalized_world == "cybersecurity":
			normalized_world = "hacker"
		else:
			return

	var playlist: Array = _world_music_playlists.get(normalized_world, [])
	if playlist.is_empty():
		return

	var chosen_idx: int = 0
	if track_index >= 0 and track_index < playlist.size():
		chosen_idx = track_index
	else:
		chosen_idx = randi() % playlist.size()

	var actual_vol := volume_db
	if normalized_world == "hacker" and volume_db == -12.0:
		actual_vol = -8.0

	_current_music_world = normalized_world
	play_track(playlist[chosen_idx], actual_vol)


func play_menu_music(volume_db: float = -14.0) -> void:
	play_world_music("menu", 0, volume_db)


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
	_current_music_world = ""
	_current_music_path = ""
