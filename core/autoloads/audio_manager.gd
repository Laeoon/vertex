extends Node

## Gestor centralizado de audio con soporte para buses, pooling y sonidos en disco.
## Uso: AudioManager.play_sfx("move")

const SFX_POOL_SIZE: int = 8

var _sounds: Dictionary = {}
var _disk_sounds: Dictionary = {}
var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _initialized: bool = false


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
		"bypass": "res://sounds/bypass.wav",
		"scalate": "res://sounds/scalate.wav",
		"escalate": "res://sounds/scalate.wav",
		"persist": "res://sounds/persist.wav",
		"decoy": "res://sounds/decoy.wav",
		"captured": "res://sounds/captured.wav",
		"lose": "res://sounds/captured.wav",
		"win": "res://sounds/win.wav",
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

	# Si el mismo sonido ya está sonando, reiniciarlo en ese reproductor
	# para evitar superposición cuando se llama repetidamente.
	for p in _sfx_pool:
		if p.playing and p.stream == stream:
			p.stop()
			p.pitch_scale = pitch_scale
			p.play()
			return

	# Reutilizar el reproductor del pool sin instanciar/destruir nodos
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if not p.playing:
			player = p
			break

	if player == null and not _sfx_pool.is_empty():
		player = _sfx_pool[_sfx_pool_index]
		_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()

	if player != null:
		player.pitch_scale = pitch_scale
		player.stream = stream
		player.play()
	else:
		var temp := AudioStreamPlayer.new()
		temp.bus = "SFX"
		temp.pitch_scale = pitch_scale
		temp.stream = stream
		temp.finished.connect(temp.queue_free)
		add_child(temp)
		temp.play()


func play_music(stream: AudioStream, volume_db: float = -10.0) -> void:
	if _music_player.stream != stream:
		_music_player.stop()
		_music_player.stream = stream
	_music_player.volume_db = volume_db
	if not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	_music_player.stop()
