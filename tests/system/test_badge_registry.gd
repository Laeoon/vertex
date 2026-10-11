extends Node

## Test Suite: BadgeRegistry
## Tests the declarative 10 badges definition and pure evaluate_badges() rules.

const BadgeRegistryClass = preload("res://juego/system/badge_registry.gd")
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST BADGE REGISTRY ---")
	test_badges_definition()
	test_empty_evaluation()
	test_rules_activation()

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


func test_badges_definition() -> void:
	var list: Array = BadgeRegistryClass.BADGES
	_assert(list.size() == 10, "BADGES contains exactly 10 definitions (got %d)" % list.size())
	for b in list:
		var has_keys: bool = b.has("id") and b.has("title") and b.has("description") and b.has("icon") and b.has("rule")
		_assert(has_keys, "Badge entry '%s' has all required keys" % b.get("id", "UNKNOWN"))
		_assert(not String(b.get("title", "")).is_empty(), "Badge '%s' has non-empty title" % b.get("id", ""))


func test_empty_evaluation() -> void:
	var evaluated: Array = BadgeRegistryClass.evaluate_badges(null, null)
	_assert(evaluated.size() == 10, "Empty evaluation returns 10 items")
	var all_locked: bool = true
	for b in evaluated:
		if b.get("unlocked", false) == true:
			all_locked = false
	_assert(all_locked, "All badges locked when progress and stats are null/empty")


func test_rules_activation() -> void:
	# 1. first_breach (total_wins >= 1)
	var stats_cfg := ConfigFile.new()
	stats_cfg.set_value("stats", "total_wins", 1)
	var res := BadgeRegistryClass.evaluate_badges(null, stats_cfg)
	var fb = _find_badge(res, "first_breach")
	_assert(fb.get("unlocked", false) == true, "first_breach unlocks with total_wins >= 1")

	# 2. clean_ghost (at least one 3-star level)
	var prog_cfg := ConfigFile.new()
	prog_cfg.set_value("estrellas", "heist_n1", 3)
	res = BadgeRegistryClass.evaluate_badges(prog_cfg, null)
	var cg = _find_badge(res, "clean_ghost")
	_assert(cg.get("unlocked", false) == true, "clean_ghost unlocks with a 3-star level")

	# 3. unbroken_streak (best_streak >= 3)
	stats_cfg.set_value("stats", "best_streak", 3)
	res = BadgeRegistryClass.evaluate_badges(null, stats_cfg)
	var us = _find_badge(res, "unbroken_streak")
	_assert(us.get("unlocked", false) == true, "unbroken_streak unlocks with best_streak >= 3")

	# 4. constellation_15 (total_stars >= 15)
	prog_cfg = ConfigFile.new()
	for i in range(5):
		prog_cfg.set_value("estrellas", "heist_n%d" % (i + 1), 3)
	res = BadgeRegistryClass.evaluate_badges(prog_cfg, null)
	var c15 = _find_badge(res, "constellation_15")
	_assert(c15.get("unlocked", false) == true, "constellation_15 unlocks with 15 stars")

	# 5. cost_optimizer (3 or more levels with best_cost > 0)
	prog_cfg = ConfigFile.new()
	prog_cfg.set_value("estrellas", "heist_n1_mejor_coste", 10.0)
	prog_cfg.set_value("estrellas", "heist_n2_mejor_coste", 12.0)
	prog_cfg.set_value("estrellas", "heist_n3_mejor_coste", 15.0)
	res = BadgeRegistryClass.evaluate_badges(prog_cfg, null)
	var co = _find_badge(res, "cost_optimizer")
	_assert(co.get("unlocked", false) == true, "cost_optimizer unlocks with 3 cost records")

	# 6. network_veteran (play_time >= 1800)
	stats_cfg = ConfigFile.new()
	stats_cfg.set_value("stats", "play_time", 1800)
	res = BadgeRegistryClass.evaluate_badges(null, stats_cfg)
	var nv = _find_badge(res, "network_veteran")
	_assert(nv.get("unlocked", false) == true, "network_veteran unlocks with 1800 seconds")

	# 7. heist_master (all 5 heist levels completed)
	prog_cfg = ConfigFile.new()
	for i in range(5):
		prog_cfg.set_value("estrellas", "heist_n%d" % (i + 1), 1)
	res = BadgeRegistryClass.evaluate_badges(prog_cfg, null)
	var hm = _find_badge(res, "heist_master")
	_assert(hm.get("unlocked", false) == true, "heist_master unlocks when all 5 heist levels have >= 1 star")

	# 8. shadow_infiltrator (all 5 hacker levels completed)
	prog_cfg = ConfigFile.new()
	for i in range(5):
		prog_cfg.set_value("estrellas", "hacker_n%d" % (i + 1), 1)
	res = BadgeRegistryClass.evaluate_badges(prog_cfg, null)
	var si = _find_badge(res, "shadow_infiltrator")
	_assert(si.get("unlocked", false) == true, "shadow_infiltrator unlocks when all 5 hacker levels completed")

	# 9. perimeter_sentinel (all 2 cybersecurity levels completed)
	prog_cfg = ConfigFile.new()
	prog_cfg.set_value("estrellas", "cyber_n1", 1)
	prog_cfg.set_value("estrellas", "defense_n1", 1)
	res = BadgeRegistryClass.evaluate_badges(prog_cfg, null)
	var ps = _find_badge(res, "perimeter_sentinel")
	_assert(ps.get("unlocked", false) == true, "perimeter_sentinel unlocks when all cybersecurity levels completed")

	# 10. grand_architect (all 12 levels with 3 stars)
	prog_cfg = ConfigFile.new()
	var total_levels: int = 0
	for wid in LevelRegistryClass.WORLDS:
		var lvls: Array = LevelRegistryClass.WORLDS[wid].get("levels", [])
		for l in lvls:
			var path: String = l.get("path", "")
			var key: String = path.get_file().trim_suffix(".json")
			prog_cfg.set_value("estrellas", key, 3)
			total_levels += 1
	res = BadgeRegistryClass.evaluate_badges(prog_cfg, null)
	var ga = _find_badge(res, "grand_architect")
	_assert(ga.get("unlocked", false) == true, "grand_architect unlocks when all %d levels have 3 stars" % total_levels)


func _find_badge(badges: Array, id: String) -> Dictionary:
	for b in badges:
		if b.get("id", "") == id:
			return b
	return {}
