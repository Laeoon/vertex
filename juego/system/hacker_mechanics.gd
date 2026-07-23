class_name HackerMechanics

## Sistema de mecánicas para el mundo Hacker.
## Implementa evasión, reconocimiento, explotación abstracta y gestión de riesgo.
## Todo es abstracto y educativo — sin instrucciones reales de hacking.

## ─── TIPOS DE EXPLOIT (abstractos) ───────────────────────────────
const EXPLOIT_BYPASS: String = "bypass"
const EXPLOIT_ESCALATE: String = "escalate"
const EXPLOIT_PERSIST: String = "persist"

## Nombres estilizados para UI (nunca describen técnicas reales)
const EXPLOIT_NAMES: Dictionary = {
	"bypass": "Infiltración",
	"escalate": "Elevación",
	"persist": "Persistencia",
}

const EXPLOIT_ICONS: Dictionary = {
	"bypass": "⚡",
	"escalate": "🔓",
	"persist": "♻",
}

const EXPLOIT_DESCRIPTIONS: Dictionary = {
	"bypass": "Salta la protección de un nodo",
	"escalate": "Accede a áreas restringidas",
	"persist": "Mantén acceso por turnos extra",
}

## ─── TIPOS DE NODO ──────────────────────────────────────────────
const NODE_VULNERABLE: String = "vulnerable"
const NODE_PROTECTED: String = "protected"
const NODE_DECOY: String = "decoy"
const NODE_NORMAL: String = "normal"

## ─── COSTOS DE RUIDO ────────────────────────────────────────────
const NOISE_MOVE_BASE: int = 5
const NOISE_EXPLOIT_BYPASS: int = 15
const NOISE_EXPLOIT_ESCALATE: int = 25
const NOISE_EXPLOIT_PERSIST: int = 10
const NOISE_SCAN: int = 2
const NOISE_DECOY_PENALTY: int = 30
const NOISE_DECAY_PER_TURN: int = 3

## ─── UMBRALES DE ALERTA ────────────────────────────────────────
const ALERT_THRESHOLD_LOW: int = 30
const ALERT_THRESHOLD_HIGH: int = 60
const ALERT_THRESHOLD_CRITICAL: int = 85

## ─── LÍMITE DE EXPLOITS ────────────────────────────────────────
const MAX_EXPLOITS_DEFAULT: int = 3


## ─── ESTRUCTURA DE ESTADO ──────────────────────────────────────

static func create_state(max_exploits: int = MAX_EXPLOITS_DEFAULT) -> Dictionary:
	return {
		"noise": 0,
		"max_noise": 100,
		"exploits": {},
		"max_exploits": max_exploits,
		"exploits_used": 0,
		"scanned_nodes": {},
		"active_persists": {},
		"discovered_vulnerabilities": [],
	}


## ─── ESCANEO DE NODOS ──────────────────────────────────────────

static func scan_node(state: Dictionary, node_id: StringName, node_metadata: Dictionary) -> Dictionary:
	state["noise"] = mini(state["noise"] + NOISE_SCAN, state["max_noise"])
	state["scanned_nodes"][str(node_id)] = true

	var node_type: String = _determine_node_type(node_metadata)
	var exploit_hint: String = _get_exploit_hint(node_type, node_metadata)
	var risk_level: String = _get_risk_level(node_metadata)

	var result: Dictionary = {
		"node_id": node_id,
		"node_type": node_type,
		"exploit_hint": exploit_hint,
		"risk_level": risk_level,
		"detection_chance": node_metadata.get("detection_chance", 0.0),
		"label": node_metadata.get("label", ""),
	}

	if node_type == NODE_VULNERABLE:
		state["discovered_vulnerabilities"].append(str(node_id))

	return result


static func _determine_node_type(metadata: Dictionary) -> String:
	var detect: float = metadata.get("detection_chance", 0.0)
	var is_firewall: bool = metadata.get("has_firewall", false)
	var is_decoy: bool = metadata.get("is_decoy", false)
	var has_exploit: bool = metadata.has("exploit_type")

	if is_decoy:
		return NODE_DECOY
	if is_firewall:
		return NODE_PROTECTED
	if has_exploit or detect > 0.15:
		return NODE_VULNERABLE
	return NODE_NORMAL


static func _get_exploit_hint(node_type: String, metadata: Dictionary) -> String:
	match node_type:
		NODE_VULNERABLE:
			var exploit: String = metadata.get("exploit_type", EXPLOIT_BYPASS)
			return EXPLOIT_DESCRIPTIONS.get(exploit, "Debilidad detectada")
		NODE_PROTECTED:
			return "Requiere elevación de privilegios"
		NODE_DECOY:
			return "⚠ Señuelo detectado — alto riesgo"
		_:
			return "Sin debilidades obvias"


static func _get_risk_level(metadata: Dictionary) -> String:
	var detect: float = metadata.get("detection_chance", 0.0)
	if detect >= 0.20:
		return "alto"
	if detect >= 0.10:
		return "medio"
	return "bajo"


## ─── USO DE EXPLOITS ───────────────────────────────────────────

static func use_exploit(state: Dictionary, exploit_type: String, target_node: StringName) -> Dictionary:
	if not state["exploits"].has(exploit_type) or state["exploits"][exploit_type] <= 0:
		return {"success": false, "reason": "No tienes exploits de tipo %s" % EXPLOIT_NAMES.get(exploit_type, exploit_type)}

	state["exploits"][exploit_type] -= 1
	state["exploits_used"] += 1

	var noise_cost: int = 0
	match exploit_type:
		EXPLOIT_BYPASS:
			noise_cost = NOISE_EXPLOIT_BYPASS
		EXPLOIT_ESCALATE:
			noise_cost = NOISE_EXPLOIT_ESCALATE
		EXPLOIT_PERSIST:
			noise_cost = NOISE_EXPLOIT_PERSIST

	state["noise"] = mini(state["noise"] + noise_cost, state["max_noise"])

	if exploit_type == EXPLOIT_PERSIST:
		state["active_persists"][str(target_node)] = 3

	return {
		"success": true,
		"exploit_used": exploit_type,
		"noise_added": noise_cost,
		"total_noise": state["noise"],
		"icon": EXPLOIT_ICONS.get(exploit_type, "?"),
		"name": EXPLOIT_NAMES.get(exploit_type, exploit_type),
	}


## ─── GESTIÓN DE RUIDO ──────────────────────────────────────────

static func add_noise(state: Dictionary, amount: int) -> void:
	state["noise"] = mini(state["noise"] + amount, state["max_noise"])


static func decay_noise(state: Dictionary) -> void:
	state["noise"] = maxi(state["noise"] - NOISE_DECAY_PER_TURN, 0)


static func get_alert_level(state: Dictionary) -> String:
	if state["noise"] >= ALERT_THRESHOLD_CRITICAL:
		return "critical"
	if state["noise"] >= ALERT_THRESHOLD_HIGH:
		return "high"
	if state["noise"] >= ALERT_THRESHOLD_LOW:
		return "low"
	return "safe"


static func get_noise_color(state: Dictionary) -> Color:
	var level: String = get_alert_level(state)
	match level:
		"critical":
			return Color(1.0, 0.1, 0.0)
		"high":
			return Color(1.0, 0.5, 0.0)
		"low":
			return Color(1.0, 0.9, 0.0)
		_:
			return Color(0.0, 1.0, 0.5)


## ─── RECOMPENSAS ───────────────────────────────────────────────

static func grant_exploits(state: Dictionary, exploit_type: String, count: int) -> void:
	if not state["exploits"].has(exploit_type):
		state["exploits"][exploit_type] = 0
	state["exploits"][exploit_type] += count


static func get_total_exploits(state: Dictionary) -> int:
	var total: int = 0
	for key in state["exploits"]:
		total += state["exploits"][key]
	return total


## ─── CONSECUENCIAS DEL RUIDO ───────────────────────────────────

static func get_ai_aggression_multiplier(state: Dictionary) -> float:
	var level: String = get_alert_level(state)
	match level:
		"critical":
			return 2.0
		"high":
			return 1.5
		"low":
			return 1.2
		_:
			return 1.0


static func should_spawn_pursuer(state: Dictionary) -> bool:
	return state["noise"] >= ALERT_THRESHOLD_HIGH and randf() < 0.3


## ─── SCORING ───────────────────────────────────────────────────

static func calculate_hacker_stars(state: Dictionary, turns_used: int, max_turns: int) -> int:
	var noise_ratio: float = 1.0 - (float(state["noise"]) / float(state["max_noise"]))
	var turns_ratio: float = 1.0 - (float(turns_used) / float(max_turns)) if max_turns > 0 else 1.0
	var exploit_efficiency: float = 1.0 - (float(state["exploits_used"]) / float(state["max_exploits"])) if state["max_exploits"] > 0 else 1.0

	var score: float = (noise_ratio * 0.4) + (turns_ratio * 0.3) + (exploit_efficiency * 0.3)

	if score >= 0.7:
		return 3
	if score >= 0.4:
		return 2
	return 1
