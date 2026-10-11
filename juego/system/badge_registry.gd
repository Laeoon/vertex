class_name BadgeRegistry extends RefCounted

## BadgeRegistry
## Declarative registry and deterministic evaluation engine for Operator Dossier badges.
## Pure data-driven implementation with zero direct filesystem side-effects.

const LevelRegistryClass = preload("res://juego/system/level_registry.gd")

const BADGES: Array[Dictionary] = [
	{
		"id": "first_breach",
		"title": "PRIMERA BRECHA",
		"description": "Completa con éxito tu primera incursión en la red.",
		"icon": "glyph_breach",
		"rule": {"type": "min_wins", "target": 1},
	},
	{
		"id": "clean_ghost",
		"title": "FANTASMA IMPECABLE",
		"description": "Obtén 3 estrellas en cualquier misión activa.",
		"icon": "glyph_ghost",
		"rule": {"type": "single_3_star", "target": 1},
	},
	{
		"id": "heist_master",
		"title": "OPERADOR DEL CONSORCIO",
		"description": "Completa todas las misiones del sector Heist.",
		"icon": "glyph_vault",
		"rule": {"type": "world_complete", "world": "heist", "target": 5},
	},
	{
		"id": "shadow_infiltrator",
		"title": "INTRUSO DE SOMBRAS",
		"description": "Completa todas las misiones del sector Hacker.",
		"icon": "glyph_network",
		"rule": {"type": "world_complete", "world": "hacker", "target": 5},
	},
	{
		"id": "perimeter_sentinel",
		"title": "CENTINELA PERIMETRAL",
		"description": "Completa todas las misiones del sector Cybersecurity.",
		"icon": "glyph_shield",
		"rule": {"type": "world_complete", "world": "cybersecurity", "target": 2},
	},
	{
		"id": "unbroken_streak",
		"title": "ENLACE INQUEBRANTABLE",
		"description": "Mantén una racha de al menos 3 victorias consecutivas.",
		"icon": "glyph_streak",
		"rule": {"type": "best_streak", "target": 3},
	},
	{
		"id": "constellation_15",
		"title": "CONSTELACIÓN CIFRADA",
		"description": "Acumula un total de 15 estrellas de maestría.",
		"icon": "glyph_stars",
		"rule": {"type": "total_stars", "target": 15},
	},
	{
		"id": "cost_optimizer",
		"title": "MÁXIMA EFICIENCIA",
		"description": "Registra un récord de coste en al menos 3 niveles.",
		"icon": "glyph_chip",
		"rule": {"type": "best_cost_count", "target": 3},
	},
	{
		"id": "network_veteran",
		"title": "VETERANO DEL ENLACE",
		"description": "Acumula 30 minutos de tiempo activo de enlace.",
		"icon": "glyph_radar",
		"rule": {"type": "play_time", "target": 1800},
	},
	{
		"id": "grand_architect",
		"title": "ARQUITECTO SUPREMO",
		"description": "Obtén 3 estrellas en la totalidad de misiones registradas.",
		"icon": "glyph_crown",
		"rule": {"type": "all_3_stars", "target": 12},
	},
]


## Evaluates all badges deterministically from memory config files.
static func evaluate_badges(progress_cfg: ConfigFile, stats_cfg: ConfigFile) -> Array[Dictionary]:
	var evaluated: Array[Dictionary] = []

	var total_stars: int = 0
	var star_counts_by_level: Dictionary = {}
	var best_cost_count: int = 0
	var count_3_stars: int = 0

	if progress_cfg != null:
		var keys := progress_cfg.get_section_keys("estrellas")
		for k in keys:
			if k.ends_with("_mejor_coste"):
				var cost: float = progress_cfg.get_value("estrellas", k, 0.0)
				if cost > 0.0:
					best_cost_count += 1
				continue

			var stars: int = progress_cfg.get_value("estrellas", k, 0)
			star_counts_by_level[k] = stars
			total_stars += stars
			if stars >= 3:
				count_3_stars += 1

	var total_wins: int = stats_cfg.get_value("stats", "total_wins", 0) if stats_cfg != null else 0
	var best_streak: int = stats_cfg.get_value("stats", "best_streak", 0) if stats_cfg != null else 0
	var play_time: int = stats_cfg.get_value("stats", "play_time", 0) if stats_cfg != null else 0

	var total_registered_levels: int = 0
	var world_levels: Dictionary = {}
	for wid in LevelRegistryClass.WORLDS:
		world_levels[wid] = []
		var lvls: Array = LevelRegistryClass.WORLDS[wid].get("levels", [])
		for l in lvls:
			var path: String = l.get("path", "")
			var key: String = path.get_file().trim_suffix(".json")
			world_levels[wid].append(key)
			total_registered_levels += 1

	for b in BADGES:
		var rule: Dictionary = b.get("rule", {})
		var rtype: String = rule.get("type", "")
		var target: int = rule.get("target", 1)
		var current: int = 0
		var unlocked: bool = false

		match rtype:
			"min_wins":
				current = total_wins
				unlocked = current >= target

			"single_3_star":
				current = mini(count_3_stars, target)
				unlocked = count_3_stars >= target

			"best_streak":
				current = best_streak
				unlocked = current >= target

			"total_stars":
				current = total_stars
				unlocked = current >= target

			"best_cost_count":
				current = best_cost_count
				unlocked = current >= target

			"play_time":
				current = play_time
				unlocked = current >= target

			"world_complete":
				var wid: String = rule.get("world", "")
				var w_keys: Array = world_levels.get(wid, [])
				var w_completed: int = 0
				for wk in w_keys:
					if star_counts_by_level.get(wk, 0) >= 1:
						w_completed += 1
				current = w_completed
				target = w_keys.size() if w_keys.size() > 0 else target
				unlocked = w_completed >= target and target > 0

			"all_3_stars":
				var all_3: int = 0
				for wid in world_levels:
					for wk in world_levels[wid]:
						if star_counts_by_level.get(wk, 0) >= 3:
							all_3 += 1
				current = all_3
				target = total_registered_levels if total_registered_levels > 0 else target
				unlocked = all_3 >= target and target > 0

		var ratio: float = clampf(float(current) / float(target), 0.0, 1.0) if target > 0 else (1.0 if unlocked else 0.0)

		evaluated.append({
			"id": b.get("id", ""),
			"title": b.get("title", ""),
			"description": b.get("description", ""),
			"icon": b.get("icon", ""),
			"unlocked": unlocked,
			"current": current,
			"target": target,
			"progress_ratio": ratio,
		})

	return evaluated
