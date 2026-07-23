extends Node

## Gestor centralizado de audio.
## Uso: AudioManager.play_sfx("move")

var _sounds: Dictionary = {}
var _music_player: AudioStreamPlayer
var _initialized: bool = false


func _ready() -> void:
	_generate_sounds()
	_setup_music_player()
	_initialized = true


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


func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)


func play_sfx(name: String) -> void:
	if not _initialized or not _sounds.has(name):
		return
	var temp := AudioStreamPlayer.new()
	temp.stream = _sounds[name] as AudioStream
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
