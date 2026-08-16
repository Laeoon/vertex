extends Node

## Equivalence test (golden) para juego/tutorials/glossary.gd — etapa 5 (P1)
## de la descomposición de tutorial_player.gd.
##
## Congela a nivel DATOS (sin render): número de términos cargados de
## glossary.json, keys del primer/último término, título, toggle on/off
## (con reset de scroll al reabrir, vía el delegate público del player) y
## scroll (pasos de 40, clamp a [0, max], índices visibles según la
## geometría del overlay).
##
## Instancia la escena real del tutorial_player (como hace el juego) para
## que la carga pase por _ready → _load_glossary() del módulo. Entre S2 y
## S4 no hay awaits: el snapshot corre sincrónico y _process no interfiere
## con el scroll.
##
## Invocación:
##     godot --headless res://tests/tutorials/_test_glossary_equivalence.tscn

const CAPTURE := false
const VP_H := 600.0

var passed: int = 0
var failed: int = 0
var tp: Control


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://juego/tutorials/tutorial_player.tscn")
	var tutorial_root = scene.instantiate()
	add_child(tutorial_root)
	tp = tutorial_root.get_node("Control")
	await get_tree().process_frame

	var g = tp._glossary
	var snap: Array[String] = []

	# ── S1: carga de glossary.json (vía _ready del player) ──
	var keys: Array = g.get_sorted_keys()
	snap.append("carga|title=%s|terms=%d|first=%s|last=%s" % [
		g.get_title(), g.get_terms().size(), keys[0], keys[keys.size() - 1]])
	var fk: Array = g.get_terms()[keys[0]].keys()
	fk.sort()
	var lk: Array = g.get_terms()[keys[keys.size() - 1]].keys()
	lk.sort()
	snap.append("keys|first=%s|last=%s" % ["|".join(PackedStringArray(fk)), "|".join(PackedStringArray(lk))])

	# ── S2: toggle on/off (delegate público) y reset de scroll al reabrir ──
	snap.append("toggle|cerrado=%s" % str(not g.is_open()))
	tp.toggle_glossary()
	snap.append("toggle|abierto=%s|scroll=%s" % [str(g.is_open()), str(g.get_scroll())])
	g.scroll_by(80.0, VP_H)
	snap.append("scroll_pre_close|%s" % str(g.get_scroll()))
	tp.toggle_glossary()
	snap.append("toggle|cerrado2=%s" % str(not g.is_open()))
	tp.toggle_glossary()
	snap.append("toggle|reopen_scroll=%s" % str(g.get_scroll()))

	# ── S3: scroll — pasos de 40 y clamp (max = 12*40 - 600*0.6 = 120) ──
	snap.append("max_scroll|%s" % str(g.max_scroll(VP_H)))
	g.scroll_by(40.0, VP_H)
	snap.append("scroll|+40=%s" % str(g.get_scroll()))
	g.scroll_by(40.0, VP_H)
	snap.append("scroll|+80=%s" % str(g.get_scroll()))
	g.scroll_by(40.0, VP_H)
	snap.append("scroll|clamp=%s" % str(g.get_scroll()))
	g.scroll_by(-1000.0, VP_H)
	snap.append("scroll|floor=%s" % str(g.get_scroll()))

	# ── S4: términos visibles según scroll (geometría del overlay) ──
	g.scroll_by(120.0, VP_H)
	var vis: Array = g.visible_indices(VP_H)
	snap.append("vis|tope|count=%d|first=%d|last=%d" % [vis.size(), vis[0], vis[vis.size() - 1]])
	g.scroll_by(-120.0, VP_H)
	vis = g.visible_indices(VP_H)
	snap.append("vis|top|count=%d|first=%d|last=%d" % [vis.size(), vis[0], vis[vis.size() - 1]])

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_finish()
		return

	var golden: Array[String] = [
		"carga|title=Glosario de Términos|terms=12|first=deteccion|last=waypoint",
		"keys|first=definition|example|real_world|last=definition|example|real_world",
		"toggle|cerrado=true",
		"toggle|abierto=true|scroll=0.0",
		"scroll_pre_close|80.0",
		"toggle|cerrado2=true",
		"toggle|reopen_scroll=0.0",
		"max_scroll|120.0",
		"scroll|+40=40.0",
		"scroll|+80=80.0",
		"scroll|clamp=120.0",
		"scroll|floor=0.0",
		"vis|tope|count=8|first=4|last=11",
		"vis|top|count=12|first=0|last=11",
	]

	if snap.size() != golden.size():
		print("FAIL: tamaño snapshot %d != golden %d" % [snap.size(), golden.size()])
		failed += 1
	for i in snap.size():
		if snap[i] == golden[i]:
			print("PASS: %s" % golden[i])
			passed += 1
		else:
			print("FAIL: got='%s' want='%s'" % [snap[i], golden[i]])
			failed += 1

	_finish()


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
