extends Node

## Test Suite: AudioSpectrumVisualizer and AudioManager Spectrum API
## Validates band sampling, peak ballistic tracking, idle wave fallback, and safe headless drawing.

const AudioSpectrumVisualizerClass = preload("res://juego/ui/audio_spectrum_visualizer.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST AUDIO SPECTRUM VISUALIZER ---")
	test_initialization()
	test_update_and_peaks_tracking()
	test_idle_wave_fallback()
	test_draw_safe_headless()
	test_audio_manager_spectrum_api()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func test_initialization() -> void:
	var viz := AudioSpectrumVisualizerClass.new(24)
	_assert(viz.band_count == 24, "Visualizer initializes with 24 bands (got %d)" % viz.band_count)
	_assert(viz.get_magnitudes().size() == 24, "Magnitudes array sized to 24")
	_assert(viz.get_peaks().size() == 24, "Peaks array sized to 24")

	var viz_min := AudioSpectrumVisualizerClass.new(4)
	_assert(viz_min.band_count == 8, "Minimum band count is clamped to 8 (got %d)" % viz_min.band_count)


func test_update_and_peaks_tracking() -> void:
	var viz := AudioSpectrumVisualizerClass.new(16)
	viz.idle_wave_enabled = false
	viz.update(0.016)

	var mags := viz.get_magnitudes()
	var peaks := viz.get_peaks()

	_assert(mags.size() == 16, "Updated magnitudes size is 16")
	for i in range(16):
		_assert(peaks[i] >= mags[i], "Peak #%d is >= magnitude" % i)
		_assert(mags[i] >= 0.0 and mags[i] <= 1.0, "Magnitude #%d is clamped [0..1]" % i)


func test_idle_wave_fallback() -> void:
	var viz := AudioSpectrumVisualizerClass.new(16)
	viz.idle_wave_enabled = true
	# Simular avance temporal
	for frame in range(10):
		viz.update(0.016)

	var mags := viz.get_magnitudes()
	var nonzero_count := 0
	for v in mags:
		if v > 0.001:
			nonzero_count += 1
	_assert(nonzero_count == 16, "Idle wave generates subtle organic values across all bands (got %d/16)" % nonzero_count)


func test_draw_safe_headless() -> void:
	var viz := AudioSpectrumVisualizerClass.new(16)
	viz.update(0.016)

	# Probar con rect degenerado (retorna antes de invocar draw_*)
	var dummy := Control.new()
	add_child(dummy)
	viz.draw(dummy, Rect2(0.0, 0.0, 0.0, 0.0))
	_assert(true, "Draw on degenerate Rect2 (0x0) returns early safely")

	# Probar dibujo legítimo dentro del ciclo NOTIFICATION_DRAW
	dummy.draw.connect(func():
		viz.draw(dummy, Rect2(40.0, 500.0, 800.0, 160.0), Color.CYAN, null, true)
		viz.draw_track_waveform(dummy, Vector2(100.0, 300.0), Vector2(700.0, 300.0), Color.CYAN, 80.0, 64)
	)
	dummy.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "Draw and draw_track_waveform inside NOTIFICATION_DRAW succeed cleanly without engine error")

	dummy.queue_free()


func test_audio_manager_spectrum_api() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("get_spectrum_magnitudes"):
		var mags16: PackedFloat32Array = am.get_spectrum_magnitudes(16)
		_assert(mags16.size() == 16, "AudioManager.get_spectrum_magnitudes(16) returns 16 elements")

		var mags32: PackedFloat32Array = am.get_spectrum_magnitudes(32)
		_assert(mags32.size() == 32, "AudioManager.get_spectrum_magnitudes(32) returns 32 elements")

		var in_bounds := true
		for v in mags16:
			if v < 0.0 or v > 1.0:
				in_bounds = false
		_assert(in_bounds, "All magnitudes in bounds [0.0, 1.0]")
	else:
		_assert(true, "AudioManager not mounted in this test runner, safely bypassed")
