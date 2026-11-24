extends Node

## Gestor centralizado de audio con soporte para buses, pooling y sonidos en disco.
## Uso: AudioManager.play_sfx("move")

const SettingsManagerClass = preload("res://core/autoloads/settings_manager.gd")

const SFX_POOL_SIZE: int = 8

const SFX_ALIASES: Dictionary = {
	"hover": "click",
}

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
	"dive_in": 55,
	"dive_out": 55,
	"confirm": 50,
	"firewall": 50,
	"scan": 40,
	"block": 30,
	"move": 10,
	"click": 5,
	"hover": 5,
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
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 01 - Underbeat.ogg",
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
	],
	"cybersecurity": [
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 08 - Sentinel Cloud-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 10 - Space Echoes-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 09 - Ghost Steps-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 12 - Faceless Crowd-loop.ogg",
		"res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 13 - Between Everyone and Anyone-loop.ogg",
		"res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 05 - Western Cyberhorse.ogg",
	],
}


func _ready() -> void:
	_ensure_audio_buses()
	_load_saved_volumes()
	_connect_settings_events()
	_generate_sounds()
	_load_disk_sounds()
	_setup_music_player()
	_setup_sfx_pool()
	_initialized = true


func _connect_settings_events() -> void:
	var ev: Node = get_node_or_null("/root/Events")
	if ev != null and ev.has_signal("settings_changed"):
		var cb := Callable(self, "_on_settings_changed")
		if not ev.is_connected("settings_changed", cb):
			ev.connect("settings_changed", cb)


func _on_settings_changed(_section: StringName, key: StringName, value: Variant) -> void:
	match key:
		&"volume_master":
			set_bus_volume_percent("Master", int(value))
		&"volume_music":
			set_bus_volume_percent("Music", int(value))
		&"volume_sfx":
			set_bus_volume_percent("SFX", int(value))


func set_bus_volume_percent(bus_name: String, percent: int) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var clamped: int = clampi(percent, 0, 100)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(float(clamped) / 100.0))


func _load_saved_volumes() -> void:
	var sm: Node = get_node_or_null("/root/SettingsManager")
	var v_master: int
	var v_music: int
	var v_sfx: int
	if sm != null and sm.has_method("get_setting"):
		v_master = int(sm.call("get_setting", "volume_master"))
		v_music = int(sm.call("get_setting", "volume_music"))
		v_sfx = int(sm.call("get_setting", "volume_sfx"))
	else:
		v_master = int(SettingsManagerClass.read_setting_from_disk("volume_master"))
		v_music = int(SettingsManagerClass.read_setting_from_disk("volume_music"))
		v_sfx = int(SettingsManagerClass.read_setting_from_disk("volume_sfx"))
	set_bus_volume_percent("Master", v_master)
	set_bus_volume_percent("Music", v_music)
	set_bus_volume_percent("SFX", v_sfx)


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

	_ensure_spectrum_analyzer()


func _ensure_spectrum_analyzer() -> void:
	for bus_name in ["Music", "Master"]:
		var b_idx := AudioServer.get_bus_index(bus_name)
		if b_idx == -1:
			continue
		var has_spectrum := false
		for i in range(AudioServer.get_bus_effect_count(b_idx)):
			if AudioServer.get_bus_effect(b_idx, i) is AudioEffectSpectrumAnalyzer:
				has_spectrum = true
				break
		if not has_spectrum:
			var spectrum := AudioEffectSpectrumAnalyzer.new()
			spectrum.buffer_length = 0.15
			spectrum.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
			AudioServer.add_bus_effect(b_idx, spectrum)


## Retorna la instancia activa del analizador de espectro (Music o Master), o null si no está disponible.
func get_spectrum_instance() -> AudioEffectSpectrumAnalyzerInstance:
	for bus_name in ["Music", "Master"]:
		var b_idx := AudioServer.get_bus_index(bus_name)
		if b_idx == -1:
			continue
		for i in range(AudioServer.get_bus_effect_count(b_idx)):
			if AudioServer.get_bus_effect(b_idx, i) is AudioEffectSpectrumAnalyzer:
				var inst = AudioServer.get_bus_effect_instance(b_idx, i)
				if inst != null:
					return inst
	return null


## Retorna un array con las magnitudes en escala decibélica (0.0..1.0) para N bandas de frecuencia.
## Si corre en headless o con driver dummy, retorna ceros sin crashear.
func get_spectrum_magnitudes(bands: int = 16, min_freq: float = 24.0, max_freq: float = 11000.0) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(bands)
	var spectrum := get_spectrum_instance()
	if spectrum == null:
		return result

	var f_min := maxf(20.0, min_freq)
	var f_max := maxf(f_min + 10.0, max_freq)
	for b in range(bands):
		var f_low := f_min * pow(f_max / f_min, float(b) / float(bands))
		var f_high := f_min * pow(f_max / f_min, float(b + 1) / float(bands))
		var mag_vec: Vector2 = spectrum.get_magnitude_for_frequency_range(f_low, f_high)
		var mag_len := mag_vec.length()
		if mag_len < 0.00005:
			result[b] = 0.0
		else:
			var db := linear_to_db(mag_len)
			# Rango dinámico sensible: de -50 dB (silencio) a 0 dB (pico)
			var energy := clampf((db + 50.0) / 50.0, 0.0, 1.0)
			result[b] = energy
	return result


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
		"dive_in": "res://assets/audio/sfx/dive_in.wav",
		"dive_out": "res://assets/audio/sfx/dive_out.wav",
	}
	for key in sound_files:
		var path: String = sound_files[key]
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AudioStream:
				_disk_sounds[key] = res

	# Asignación provisional para demo: dive_in hereda bypass.wav si no hay dive_in.wav en disco
	if not _disk_sounds.has("dive_in") and _disk_sounds.has("bypass"):
		_disk_sounds["dive_in"] = _disk_sounds["bypass"]


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
	_sounds["error"] = _make_tone(146.83, 0.22, sr)
	_sounds["dive_in"] = _make_sweep(0.38, sr)
	_sounds["dive_out"] = _make_sweep_down(0.35, sr)
	_sounds["confirm"] = _make_chord([523.25, 659.25], 0.12, sr)


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


func _make_sweep_down(dur: float, sr: float) -> AudioStreamWAV:
	var n: int = int(sr * dur)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / sr
		var env: float = exp(-2.5 * t / dur)
		var freq: float = 850.0 - 650.0 * (t / dur)
		var s: float = sin(2.0 * PI * freq * t) * 0.28 * env
		s += (randf() - 0.5) * 0.15 * env
		data.encode_s16(i * 2, int(clampf(s * 16384.0, -32768.0, 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(sr)
	wav.stereo = false
	return wav


func _resolve_sfx_name(name: String) -> String:
	return str(SFX_ALIASES.get(name, name))


func has_sound(name: String) -> bool:
	var resolved: String = _resolve_sfx_name(name)
	return _disk_sounds.has(resolved) or _sounds.has(resolved)


func play_sfx(name: String, pitch_scale: float = 1.0) -> void:
	if not _initialized:
		return
	var resolved: String = _resolve_sfx_name(name)
	var stream: AudioStream = null
	if _disk_sounds.has(resolved):
		stream = _disk_sounds[resolved]
	elif _sounds.has(resolved):
		stream = _sounds[resolved]
	else:
		return

	var priority: int = SFX_PRIORITY.get(name, SFX_PRIORITY.get(resolved, 20))

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
		_music_player.stream_paused = false
		return
	if not ResourceLoader.exists(path):
		return
	var res = load(path)
	if res is AudioStream:
		if res is AudioStreamOggVorbis:
			res.loop = true
		_current_music_path = path
		_music_player.stream_paused = false
		play_music(res, volume_db)


func is_music_playing() -> bool:
	return _music_player != null and _music_player.playing and not _music_player.stream_paused


func is_music_paused() -> bool:
	return _music_player != null and _music_player.stream_paused


func set_music_paused(paused: bool) -> void:
	if _music_player != null and _music_player.stream != null:
		_music_player.stream_paused = paused


func get_music_playback_position() -> float:
	if _music_player != null and _music_player.stream != null and (_music_player.playing or _music_player.stream_paused):
		return _music_player.get_playback_position()
	return 0.0


func get_music_duration() -> float:
	if _music_player != null and _music_player.stream != null:
		return _music_player.stream.get_length()
	return 0.0


func seek_music(seconds: float) -> void:
	if _music_player != null and _music_player.stream != null:
		var dur: float = _music_player.stream.get_length()
		var clamped: float = clampf(seconds, 0.0, maxf(0.0, dur - 0.1))
		_music_player.seek(clamped)


func get_current_music_path() -> String:
	return _current_music_path


func get_bus_volume_percent(bus_name: String) -> int:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 80
	var lin: float = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return clampi(int(round(lin * 100.0)), 0, 100)


func play_world_music(world_id: String, track_index: int = -1, volume_db: float = -12.0) -> void:
	if not _initialized:
		return
	var normalized_world := world_id.to_lower().strip_edges()

	if not _world_music_playlists.has(normalized_world):
		return

	var playlist: Array = _world_music_playlists.get(normalized_world, [])
	if playlist.is_empty():
		return

	var chosen_idx: int = 0
	if track_index >= 0 and track_index < playlist.size():
		chosen_idx = track_index
	else:
		chosen_idx = 0

	var chosen_path: String = playlist[chosen_idx]
	# Si ya estamos sonando música del mismo mundo y pista (o mismo mundo con track_index < 0), mantenemos reproducción continua
	if _current_music_world == normalized_world and _music_player != null and _music_player.playing:
		if track_index < 0 or _current_music_path == chosen_path:
			return

	var actual_vol := volume_db
	if normalized_world == "hacker" and volume_db == -12.0:
		actual_vol = -8.0

	_current_music_world = normalized_world
	play_track(chosen_path, actual_vol)


func play_menu_music(volume_db: float = -14.0) -> void:
	play_world_music("menu", 0, volume_db)


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
	_current_music_world = ""
	_current_music_path = ""
