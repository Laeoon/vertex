class_name DatabaseRenderer extends RefCounted

## DatabaseRenderer
## Dedicated tactical codex renderer for the cybersecurity database in VERTEX.
## Provides static data schema across CONCEPTOS, SISTEMAS, and ARCHIVOS.
## Renders two-panel viewport, procedural vector schematics, and structured educational telemetry.

const BrandClass = preload("res://juego/ui/brand.gd")

const CATEGORIES: Array[Dictionary] = [
	{
		"id": "conceptos",
		"title": "CONCEPTOS",
		"color": BrandClass.ACCENT,
		"tag": "ALGORITMOS & FUNDAMENTOS"
	},
	{
		"id": "sistemas",
		"title": "SISTEMAS",
		"color": BrandClass.WARNING,
		"tag": "COMPONENTES DEFENSIVOS"
	},
	{
		"id": "archivos",
		"title": "ARCHIVOS",
		"color": BrandClass.SUCCESS,
		"tag": "DOCUMENTACIÓN & PEDAGOGÍA"
	},
]

const ENTRIES: Dictionary = {
	"conceptos": [
		{
			"id": "dijkstra",
			"title": "Algoritmo de Dijkstra",
			"classification": "NIVEL 1 // CAMINO MÍNIMO",
			"schematic": "dijkstra",
			"theory": "Algoritmo voraz (greedy) formulado por Edsger W. Dijkstra en 1956. Calcula la ruta de coste acumulado mínimo desde un nodo origen a todos los demás vértices de un grafo con pesos no negativos. Emplea relajación de aristas y una cola de prioridad con complejidad O((V + E) log V).",
			"mechanics": "En VERTEX, determina la trayectoria óptima calculada por el jugador y el vector de persecución del agente hostil. Cada arista tiene un costo de latencia y tránsito que pondera la ruta crítica bajo restricciones de sigilo.",
			"real_world": "Base de los protocolos de enrutamiento dinámico en redes de conmutación de paquetes como OSPF (Open Shortest Path First) e IS-IS en la infraestructura troncal de Internet."
		},
		{
			"id": "edmonds_karp",
			"title": "Edmonds-Karp / Corte Mínimo",
			"classification": "NIVEL 2 // FLUJO MÁXIMO",
			"schematic": "edmonds_karp",
			"theory": "Especialización del método Ford-Fulkerson que calcula el flujo máximo en redes de transporte empleando búsquedas en anchura (BFS) para hallar caminos de aumento más cortos en O(V * E^2). El teorema de corte mínimo y flujo máximo demuestra que el flujo saturado equivale a la capacidad del corte mínimo que desarticula la fuente del sumidero.",
			"mechanics": "Modela la contención defensiva en VERTEX: bloquear aristas estratégicas que componen el corte mínimo estrangula el flujo de intrusión de paquetes del atacante hacia nodos críticos del sistema.",
			"real_world": "Diseño de microsegmentación perimetral en centros de datos, cálculo de tolerancia a fallos en fibra óptica y balanceo de carga ante ataques masivos de denegación distribuida de servicio (DDoS)."
		},
		{
			"id": "mtd",
			"title": "Moving Target Defense (MTD)",
			"classification": "NIVEL 3 // MUTACIÓN PROACTIVA",
			"schematic": "mtd",
			"theory": "Paradigma de ciberseguridad dinámica que altera continuamente la superficie de ataque y los parámetros de red (direcciones IP, topologías, puertos y rutas lógicas) para romper la asimetría temporal del atacante e invalidar su labor de reconocimiento previo.",
			"mechanics": "En VERTEX, se traduce en la reconfiguración periódica de la topología: los enlaces entre nodos mutan dinámicamente, forzando al jugador o adversario a reevaluar rutas y anulando ataques planificados en estados estáticos.",
			"real_world": "Aleatorización del espacio de direcciones de memoria (ASLR), salto dinámico de frecuencias en redes militares y migración reactiva de contenedores en arquitecturas de nube (SDN/NFV)."
		},
		{
			"id": "attack_graphs",
			"title": "Grafos de Ataque",
			"classification": "NIVEL 2 // MODELADO DE AMENAZAS",
			"schematic": "attack_graphs",
			"theory": "Grafos dirigidos acíclicos (DAGs) donde los nodos representan estados de compromiso o privilegios alcanzados en el sistema y las aristas corresponden a transiciones exitosas de exploits. Permiten cuantificar rutas críticas de intrusión y métricas de riesgo acumulado.",
			"mechanics": "La estructura vertebral del modo Hacker en VERTEX: el agente avanza explotando vulnerabilidades en cascada para escalar privilegios desde la DMZ exterior hasta los niveles más profundos de Root.",
			"real_world": "Motores automatizados de análisis de amenazas como MulVAL y marcos MITRE ATT&CK para auditar vectores de penetración lateral y verificar políticas de acceso en modelos Zero Trust."
		},
		{
			"id": "graph_theory",
			"title": "Teoría de Grafos",
			"classification": "NIVEL 1 // TOPOLOGÍA DE RED",
			"schematic": "graph_theory",
			"theory": "Disciplina matemática originada en 1736 por Leonhard Euler con el problema de los puentes de Königsberg. Estudia las propiedades de estructuras discretas formadas por vértices (nodos) y aristas (enlaces), analizando conectividad, árboles generadores, ciclos y planaridad.",
			"mechanics": "Núcleo fundacional de toda la arquitectura de VERTEX: cada misión es una instancia formal de un grafo ponderado sobre el que se ejecutan algoritmos de distancia, flujos, bloqueos y mutaciones.",
			"real_world": "Topologías físicas y lógicas de telecomunicaciones, análisis de sistemas autónomos (BGP), detección de infraestructuras de comando y control (C2) y modelado epidemiológico de malware."
		}
	],
	"sistemas": [
		{
			"id": "firewall",
			"title": "Firewall Perimetral",
			"classification": "SISTEMA DEFENSIVO // FILTRADO",
			"schematic": "firewall",
			"theory": "Mecanismo de control de acceso perimetral que inspecciona paquetes de datos entrantes y salientes según reglas deterministas basadas en tuplas de red (IP origen, IP destino, puerto, protocolo) y estado de conexión (Stateful Packet Inspection).",
			"mechanics": "Actúa en VERTEX como barrera en enlaces clave, impidiendo la propagación de paquetes a través de la arista hasta que el agente despliega un bypass o satura su capacidad mediante señuelos.",
			"real_world": "Dispositivos NGFW (Next-Generation Firewalls) como Fortinet y Palo Alto que aíslan zonas de confianza en infraestructuras corporativas mediante inspección profunda de paquetes (DPI)."
		},
		{
			"id": "ids",
			"title": "Sistema de Detección (IDS)",
			"classification": "SISTEMA DEFENSIVO // TELEMETRÍA",
			"schematic": "ids",
			"theory": "Módulo sensor pasivo que monitoriza el tráfico de red en busca de firmas de ataque conocidas o desviaciones estadísticas respecto a perfiles de comportamiento basal mediante detección de anomalías.",
			"mechanics": "Incrementa el nivel de alarma y vigilancia cada vez que el agente efectúa acciones ruidosas o falla intentos de explotación en zonas de red monitorizadas.",
			"real_world": "Herramientas de monitorización de seguridad como Snort, Suricata y Zeek integradas en centros de operaciones de ciberseguridad (SOC) para telemetría de incidentes."
		},
		{
			"id": "honeypot",
			"title": "HoneyPot / Señuelo Táctico",
			"classification": "SISTEMA DEFENSIVO // ENGAÑO",
			"schematic": "honeypot",
			"theory": "Recurso computacional trampa configurado deliberadamente con vulnerabilidades aparentes para atraer adversarios, retardar su progresión en la red real y recopilar inteligencia forense sobre sus herramientas y técnicas.",
			"mechanics": "Nodo trampa en VERTEX que desvía las rutas del adversario o de la IA perseguidora, atrayéndolos a nodos aislados para ganar turnos críticos de maniobra.",
			"real_world": "Redes trampa (Honeynets) y canarios de autenticación desplegados en entornos corporativos para detección temprana de intrusiones y análisis de malware sin riesgo operativo."
		},
		{
			"id": "terminal",
			"title": "Terminal / Nodo Root",
			"classification": "NÚCLEO DE RED // OBJETIVO",
			"schematic": "terminal",
			"theory": "Entidad central de cómputo que concentra los privilegios administrativos máximos (UID 0 / Anillo 0 del kernel) y el almacenamiento de datos estratégicos en la infraestructura de red.",
			"mechanics": "Representa el objetivo final de extracción y control en los escenarios de VERTEX. Su captura consolida la victoria del operador y la finalización exitosa de la misión.",
			"real_world": "Servidores de directorio activo (Active Directory Domain Controllers) y bases de datos maestras protegidas bajo esquemas estrictos de control de privilegios (PAM)."
		},
		{
			"id": "pursuer",
			"title": "Perseguidor / Agente Táctico",
			"classification": "CONTRAMEDIDA // INTERCEPCIÓN",
			"schematic": "pursuer",
			"theory": "Proceso autónomo guiado por heurísticas de búsqueda adversaria y predicción cinemática sobre grafos para converger sobre agentes hostiles minimizando la distancia de intercepción.",
			"mechanics": "Entidad activa de contramedida que calcula y anticipa la ruta del jugador a través de la topología, forzando tácticas de distracción, desvío y uso óptimo de recursos.",
			"real_world": "Sistemas de respuesta automatizada EDR/XDR (Endpoint Detection and Response) y plataformas SOAR que aíslan dinámicamente endpoints infectados para neutralizar intrusiones activas."
		}
	],
	"archivos": [
		{
			"id": "vertex_arch",
			"title": "Sobre VERTEX",
			"classification": "DOCUMENTO TÁCTICO // ARQUITECTURA",
			"schematic": "vertex_arch",
			"theory": "VERTEX es una plataforma de simulación interactiva diseñada para modelar de forma lúdica y matemáticamente rigurosa conceptos de ciberseguridad defensiva y ofensiva mediante teoría de grafos.",
			"mechanics": "Articula tres modalidades complementarias: Heist (navegación sigilosa por caminos mínimos), Hacker (escalada de privilegios y grafos de ataque) y Cybersecurity (contención defensiva perimetral y MTD).",
			"real_world": "Puente pedagógico entre el modelado abstracto de algoritmos computacionales y la toma de decisiones tácticas en infraestructuras de seguridad de la información."
		},
		{
			"id": "paper_ref",
			"title": "Paper Shivakumar & Mamatha (2022)",
			"classification": "INVESTIGACIÓN // BASE CIENTÍFICA",
			"schematic": "paper_ref",
			"theory": "Referencia académica: Shivakumar, N., & Mamatha, H. R. (2022). Moving Target Defense: A Survey on Dynamic Defense Mechanisms in Cybersecurity. Computer Science Review, Elsevier. Analiza la eficacia de la aleatorización de redes ante adversarios persistentes.",
			"mechanics": "Fundamenta los modelos matemáticos de frecuencia de reconfiguración topológica, asimetría de costes computacionales y contención de flujo implementados en los modos avanzados de VERTEX.",
			"real_world": "Estudio seminal para el despliegue de infraestructuras elásticas resilientes en computación en la nube (Cloud) y redes definidas por software (SDN)."
		},
		{
			"id": "education",
			"title": "Objetivos Educativos",
			"classification": "EXPEDIENTE ACADÉMICO // PEDAGOGÍA",
			"schematic": "education",
			"theory": "Diseño instruccional estructurado sobre la taxonomía de Bloom: comprensión de conceptos algorítmicos, aplicación en entornos interactivos, análisis de rutas críticas y evaluación de estrategias de mitigación.",
			"mechanics": "El sistema de misiones y la base de datos táctica vinculan formalmente cada acción del jugador con el principio computacional y de seguridad subyacente.",
			"real_world": "Metodología orientada a la capacitación y formación técnica de ingenieros de software y analistas de ciberseguridad mediante simulación táctica (Serious Games)."
		}
	]
}

const DATA: Dictionary = ENTRIES


static func get_categories() -> Array[Dictionary]:
	return CATEGORIES


static func get_entries_for_category(cat_idx: int) -> Array[Dictionary]:
	if cat_idx < 0 or cat_idx >= CATEGORIES.size():
		return []
	var cat_id: String = CATEGORIES[cat_idx]["id"]
	var result: Array[Dictionary] = []
	var raw = ENTRIES.get(cat_id, [])
	for item in raw:
		result.append(item)
	return result


static func get_entry_count(cat_idx: int) -> int:
	return get_entries_for_category(cat_idx).size()


func get_back_button_rect(_vp: Vector2) -> Rect2:
	return Rect2(40.0, 36.0, 170.0, 36.0)


func get_left_panel_rect(vp: Vector2) -> Rect2:
	var left_x := 40.0
	var top_y := 96.0
	var panel_h := maxf(200.0, vp.y - top_y - 32.0)
	var total_avail_w := vp.x - 80.0 - 24.0
	var left_w := clampf(total_avail_w * 0.35, 320.0, 420.0)
	return Rect2(left_x, top_y, left_w, panel_h)


func get_right_panel_rect(vp: Vector2) -> Rect2:
	var lp := get_left_panel_rect(vp)
	var right_x := lp.position.x + lp.size.x + 24.0
	var top_y := 96.0
	var panel_h := maxf(200.0, vp.y - top_y - 32.0)
	var right_w := maxf(200.0, vp.x - right_x - 40.0)
	return Rect2(right_x, top_y, right_w, panel_h)


func get_category_tab_rect(cat_idx: int, vp: Vector2) -> Rect2:
	var lp := get_left_panel_rect(vp)
	var tab_gap := 6.0
	var tab_w := (lp.size.x - 28.0 - (float(CATEGORIES.size() - 1) * tab_gap)) / float(CATEGORIES.size())
	var tab_x := lp.position.x + 14.0 + float(cat_idx) * (tab_w + tab_gap)
	var tab_y := lp.position.y + 44.0
	return Rect2(tab_x, tab_y, tab_w, 32.0)


func get_entry_row_rect(entry_idx: int, vp: Vector2) -> Rect2:
	var lp := get_left_panel_rect(vp)
	var row_y := lp.position.y + 88.0 + float(entry_idx) * 48.0
	return Rect2(lp.position.x + 14.0, row_y, lp.size.x - 28.0, 42.0)


func get_dossier_viewport_height(right_rect: Rect2) -> float:
	return maxf(100.0, right_rect.size.y - 84.0)


static func wrap_text(text: String, font: Font, font_size: int, max_width: float) -> Array[String]:
	if text.is_empty():
		return [""]
	var f := font
	if f == null:
		f = BrandClass.font_regular()
	if f == null:
		f = ThemeDB.fallback_font

	var raw_paragraphs: PackedStringArray = text.split("\n")
	var lines: Array[String] = []

	for paragraph in raw_paragraphs:
		if paragraph.is_empty():
			lines.append("")
			continue
		var words: PackedStringArray = paragraph.split(" ")
		var current_line: String = ""
		for word in words:
			var test_line: String = current_line + (" " if current_line != "" else "") + word
			var test_w: float = 0.0
			if f != null:
				test_w = f.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			else:
				test_w = float(test_line.length()) * float(font_size) * 0.6
			if test_w > max_width and current_line != "":
				lines.append(current_line)
				current_line = word
			else:
				current_line = test_line
		if current_line != "":
			lines.append(current_line)

	if lines.is_empty():
		lines.append(text)
	return lines


static func compute_dossier_height(entry: Dictionary, font: Font, font_size: int, content_width: float) -> float:
	var total_h: float = 0.0
	# 1. Schematic box height + margin
	total_h += 160.0 + 16.0

	var card_w := maxf(120.0, content_width)
	var text_w := maxf(80.0, card_w - 28.0)
	var line_step := 20.0
	var card_header_and_pad := 36.0
	var card_gap := 14.0

	# 2. Theory section
	var theory_lines := wrap_text(entry.get("theory", ""), font, font_size - 1, text_w)
	var theory_h := card_header_and_pad + float(theory_lines.size()) * line_step
	total_h += theory_h + card_gap

	# 3. Mechanics section
	var mech_lines := wrap_text(entry.get("mechanics", ""), font, font_size - 1, text_w)
	var mech_h := card_header_and_pad + float(mech_lines.size()) * line_step
	total_h += mech_h + card_gap

	# 4. Real world section
	var real_lines := wrap_text(entry.get("real_world", ""), font, font_size - 1, text_w)
	var real_h := card_header_and_pad + float(real_lines.size()) * line_step
	total_h += real_h + 24.0

	return total_h


func draw(
	canvas: CanvasItem,
	vp: Vector2,
	font: Font,
	font_size: int,
	big_font_size: int,
	pulse: float,
	active_cat_idx: int,
	selected_entry_idx: int,
	scroll_y: float,
	hovered_back: bool,
	hovered_cat_idx: int,
	hovered_entry_idx: int
) -> void:
	_draw_header(canvas, vp, font, font_size, big_font_size, hovered_back)

	var lp := get_left_panel_rect(vp)
	var rp := get_right_panel_rect(vp)

	_draw_left_panel(
		canvas,
		lp,
		vp,
		font,
		font_size,
		pulse,
		active_cat_idx,
		selected_entry_idx,
		hovered_cat_idx,
		hovered_entry_idx
	)

	_draw_right_panel(
		canvas,
		rp,
		font,
		font_size,
		big_font_size,
		pulse,
		active_cat_idx,
		selected_entry_idx,
		scroll_y
	)


func _draw_header(
	canvas: CanvasItem,
	vp: Vector2,
	font: Font,
	font_size: int,
	big_font_size: int,
	hovered_back: bool
) -> void:
	# Back Button
	var btn_rect := get_back_button_rect(vp)
	if hovered_back:
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.85), false, 1.5)
		canvas.draw_string(font, Vector2(btn_rect.position.x + 16, btn_rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.ACCENT)
	else:
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.70))
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), false, 1.0)
		canvas.draw_string(font, Vector2(btn_rect.position.x + 16, btn_rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)

	# Main Dossier Title & Subtitle
	var title_pos := Vector2(230.0, 52.0)
	canvas.draw_string(font, title_pos, "BASE DE DATOS // CODEX TÁCTICO", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 4, BrandClass.ACCENT)

	var sub_pos := Vector2(230.0, 72.0)
	canvas.draw_string(font, sub_pos, "ARCHIVO CLASIFICADO DE INTELIGENCIA Y TELEMETRÍA", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	# Classified Badge (Top Right)
	var badge_txt := "BASE DE DATOS // ARCHIVO CLASIFICADO"
	var bsize := font.get_string_size(badge_txt, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 2)
	var badge_rect := Rect2(vp.x - bsize.x - 56.0, 36.0, bsize.x + 32.0, 36.0)
	canvas.draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
	canvas.draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.55), false, 1.2)
	canvas.draw_string(font, Vector2(badge_rect.position.x + 16.0, badge_rect.position.y + 23.0), badge_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)


func _draw_left_panel(
	canvas: CanvasItem,
	rect: Rect2,
	vp: Vector2,
	font: Font,
	font_size: int,
	pulse: float,
	active_cat_idx: int,
	selected_entry_idx: int,
	hovered_cat_idx: int,
	hovered_entry_idx: int
) -> void:
	# Main Panel Plate
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.94))
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.50), false, 1.2)

	# Corner bracket decorations
	var cb := 8.0
	canvas.draw_line(rect.position, rect.position + Vector2(cb, 0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position, rect.position + Vector2(0, cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x - cb, rect.position.y), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x + cb, rect.position.y + rect.size.y), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x, rect.position.y + rect.size.y - cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(cb, 0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(0, cb), BrandClass.ACCENT, 2.0)

	# Panel Header Bar
	var h_rect := Rect2(rect.position.x, rect.position.y, rect.size.x, 34.0)
	canvas.draw_rect(h_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.12))
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + 34.0), Vector2(rect.position.x + rect.size.x, rect.position.y + 34.0), BrandClass.with_alpha(BrandClass.ACCENT, 0.40), 1.0)
	canvas.draw_string(font, Vector2(rect.position.x + 14.0, rect.position.y + 23.0), "[ÍNDICE DE INTELIGENCIA]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)

	# Category Tabs
	for i in range(CATEGORIES.size()):
		var tab_data: Dictionary = CATEGORIES[i]
		var tab_rect := get_category_tab_rect(i, vp)
		var is_active := (i == active_cat_idx)
		var is_hover := (i == hovered_cat_idx)
		var col: Color = tab_data["color"]

		if is_active:
			canvas.draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
			canvas.draw_rect(tab_rect, BrandClass.with_alpha(col, 0.75), false, 1.2)
			canvas.draw_rect(Rect2(tab_rect.position.x, tab_rect.position.y + tab_rect.size.y - 2.5, tab_rect.size.x, 2.5), col)
			canvas.draw_string(font, Vector2(tab_rect.position.x + 8.0, tab_rect.position.y + 21.0), tab_data["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, col)
		elif is_hover:
			canvas.draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
			canvas.draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.45), false, 1.0)
			canvas.draw_string(font, Vector2(tab_rect.position.x + 8.0, tab_rect.position.y + 21.0), tab_data["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT)
		else:
			canvas.draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.50))
			canvas.draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.30), false, 1.0)
			canvas.draw_string(font, Vector2(tab_rect.position.x + 8.0, tab_rect.position.y + 21.0), tab_data["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)

	# Entries List
	var entries := get_entries_for_category(active_cat_idx)
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var row_rect := get_entry_row_rect(i, vp)
		var is_sel := (i == selected_entry_idx)
		var is_hov := (i == hovered_entry_idx)

		if is_sel:
			canvas.draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
			canvas.draw_rect(row_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.80), false, 1.4)
			# Selection Reticle bar on left
			canvas.draw_rect(Rect2(row_rect.position.x, row_rect.position.y, 4.0, row_rect.size.y), BrandClass.ACCENT)
			var reticle_char := ">"
			canvas.draw_string(font, Vector2(row_rect.position.x + 10.0, row_rect.position.y + 19.0), reticle_char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.ACCENT)
			canvas.draw_string(font, Vector2(row_rect.position.x + 24.0, row_rect.position.y + 19.0), entry["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)
			canvas.draw_string(font, Vector2(row_rect.position.x + 24.0, row_rect.position.y + 35.0), entry["classification"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.accent_dim(0.85))
		elif is_hov:
			canvas.draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.80))
			canvas.draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.60), false, 1.0)
			canvas.draw_string(font, Vector2(row_rect.position.x + 18.0, row_rect.position.y + 19.0), entry["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)
			canvas.draw_string(font, Vector2(row_rect.position.x + 18.0, row_rect.position.y + 35.0), entry["classification"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)
		else:
			canvas.draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.40))
			canvas.draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.20), false, 1.0)
			canvas.draw_string(font, Vector2(row_rect.position.x + 18.0, row_rect.position.y + 19.0), entry["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)
			canvas.draw_string(font, Vector2(row_rect.position.x + 18.0, row_rect.position.y + 35.0), entry["classification"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, Color(0.40, 0.44, 0.58))


func _draw_right_panel(
	canvas: CanvasItem,
	rect: Rect2,
	font: Font,
	font_size: int,
	big_font_size: int,
	pulse: float,
	active_cat_idx: int,
	selected_entry_idx: int,
	scroll_y: float
) -> void:
	# 1. Main Panel Solid Base Plate
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.94))

	var entries := get_entries_for_category(active_cat_idx)
	if entries.is_empty() or selected_entry_idx < 0 or selected_entry_idx >= entries.size():
		canvas.draw_string(font, Vector2(rect.position.x + 24.0, rect.position.y + 40.0), "NO HAY REGISTROS DISPONIBLES", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)
		return

	var entry: Dictionary = entries[selected_entry_idx]
	var cat_color: Color = CATEGORIES[active_cat_idx]["color"]

	var h_top := rect.position.y
	var content_top_y := h_top + 76.0
	var viewport_h := get_dossier_viewport_height(rect)
	var clip_top := content_top_y
	var clip_bottom := rect.position.y + rect.size.y - 12.0

	var cur_y := content_top_y - scroll_y
	var content_w := rect.size.x - 48.0
	var card_x := rect.position.x + 20.0
	var text_w := maxf(80.0, content_w - 28.0)

	# 2. Scrollable Telemetry Viewport (Drawn under fixed header and frame)
	# 2.1 Procedural Vector Schematic Viewport
	var schem_h := 160.0
	var schem_rect := Rect2(card_x, cur_y, content_w, schem_h)
	if schem_rect.position.y + schem_h >= clip_top and schem_rect.position.y <= clip_bottom:
		canvas.draw_rect(schem_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
		canvas.draw_rect(schem_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.50), false, 1.0)
		_draw_crosshair(canvas, schem_rect.position + Vector2(6, 6), BrandClass.with_alpha(BrandClass.ACCENT, 0.40))
		_draw_crosshair(canvas, Vector2(schem_rect.position.x + schem_rect.size.x - 6, schem_rect.position.y + 6), BrandClass.with_alpha(BrandClass.ACCENT, 0.40))
		_draw_crosshair(canvas, Vector2(schem_rect.position.x + 6, schem_rect.position.y + schem_rect.size.y - 6), BrandClass.with_alpha(BrandClass.ACCENT, 0.40))
		_draw_crosshair(canvas, schem_rect.position + schem_rect.size - Vector2(6, 6), BrandClass.with_alpha(BrandClass.ACCENT, 0.40))

		var schem_label := "[DIAGRAMA PROCEDURAL // %s]" % entry["schematic"].to_upper()
		canvas.draw_string(font, Vector2(schem_rect.position.x + 14.0, schem_rect.position.y + 18.0), schem_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)

		_draw_schematic(canvas, schem_rect, entry["schematic"], pulse, font, font_size)

	cur_y += schem_h + 16.0

	# 2.2 Section: Definición Teórica Card
	var theory_lines := wrap_text(entry.get("theory", ""), font, font_size - 1, text_w)
	var theory_h := 36.0 + float(theory_lines.size()) * 20.0
	var theory_rect := Rect2(card_x, cur_y, content_w, theory_h)
	_draw_telemetry_card(canvas, theory_rect, "1. DEFINICIÓN TEÓRICA", theory_lines, BrandClass.ACCENT, clip_top, clip_bottom, font, font_size)
	cur_y += theory_h + 14.0

	# 2.3 Section: Mecánica en VERTEX Card
	var mech_lines := wrap_text(entry.get("mechanics", ""), font, font_size - 1, text_w)
	var mech_h := 36.0 + float(mech_lines.size()) * 20.0
	var mech_rect := Rect2(card_x, cur_y, content_w, mech_h)
	_draw_telemetry_card(canvas, mech_rect, "2. MECÁNICA EN VERTEX", mech_lines, BrandClass.WARNING, clip_top, clip_bottom, font, font_size)
	cur_y += mech_h + 14.0

	# 2.4 Section: Aplicación Real Card
	var real_lines := wrap_text(entry.get("real_world", ""), font, font_size - 1, text_w)
	var real_h := 36.0 + float(real_lines.size()) * 20.0
	var real_rect := Rect2(card_x, cur_y, content_w, real_h)
	_draw_telemetry_card(canvas, real_rect, "3. APLICACIÓN REAL", real_lines, BrandClass.SUCCESS, clip_top, clip_bottom, font, font_size)
	cur_y += real_h + 24.0

	# 3. Fixed Header Bar (Drawn ON TOP to cleanly mask scrolled content)
	canvas.draw_rect(Rect2(rect.position.x, h_top, rect.size.x, 72.0), BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.98))
	canvas.draw_line(Vector2(rect.position.x, h_top + 72.0), Vector2(rect.position.x + rect.size.x, h_top + 72.0), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.60), 1.0)

	# Clearance Pill
	var c_tag: String = entry["classification"]
	var c_size := font.get_string_size(c_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3)
	var c_rect := Rect2(rect.position.x + 20.0, h_top + 12.0, c_size.x + 16.0, 18.0)
	canvas.draw_rect(c_rect, BrandClass.with_alpha(cat_color, 0.15))
	canvas.draw_rect(c_rect, BrandClass.with_alpha(cat_color, 0.50), false, 1.0)
	canvas.draw_string(font, Vector2(c_rect.position.x + 8.0, c_rect.position.y + 13.0), c_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, cat_color)

	# Entry Title
	canvas.draw_string(font, Vector2(rect.position.x + 20.0, h_top + 54.0), entry["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 2, BrandClass.TEXT)

	# Telemetry Status / Identifier
	var id_tag := "REG_ID: %s // STATUS: VERIFICADO" % entry["id"].to_upper()
	var id_size := font.get_string_size(id_tag, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 3)
	canvas.draw_string(font, Vector2(rect.position.x + rect.size.x - id_size.x - 20.0, h_top + 24.0), id_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	# 4. Bottom Mask Plate (Drawn ON TOP of scrolled content)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - 12.0, rect.size.x, 12.0), BrandClass.PANEL_SOLID)

	# 5. Outer Frame Border & Corner Brackets (Drawn ON TOP)
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.50), false, 1.2)
	var cb := 8.0
	canvas.draw_line(rect.position, rect.position + Vector2(cb, 0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position, rect.position + Vector2(0, cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x - cb, rect.position.y), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x + cb, rect.position.y + rect.size.y), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x, rect.position.y + rect.size.y - cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(cb, 0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(0, cb), BrandClass.ACCENT, 2.0)

	# 6. Scrollbar Indicator (Drawn ON TOP)
	var total_h := compute_dossier_height(entry, font, font_size, content_w)
	if total_h > viewport_h:
		var track_x := rect.position.x + rect.size.x - 10.0
		var track_y := content_top_y
		var track_h := viewport_h
		canvas.draw_line(Vector2(track_x, track_y), Vector2(track_x, track_y + track_h), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), 2.0)

		var thumb_h := maxf(28.0, track_h * (track_h / total_h))
		var max_s := total_h - track_h
		var scroll_fraction := clampf(scroll_y / max_s, 0.0, 1.0)
		var thumb_y := track_y + scroll_fraction * (track_h - thumb_h)
		var thumb_rect := Rect2(track_x - 1.5, thumb_y, 4.0, thumb_h)
		canvas.draw_rect(thumb_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.85))


func _draw_telemetry_card(
	canvas: CanvasItem,
	card_rect: Rect2,
	header_text: String,
	lines: Array[String],
	accent_color: Color,
	clip_top: float,
	clip_bottom: float,
	font: Font,
	font_size: int
) -> void:
	if card_rect.position.y + card_rect.size.y < clip_top or card_rect.position.y > clip_bottom:
		return

	# Card background plate and border
	canvas.draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.75))
	canvas.draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.45), false, 1.0)

	# Left vertical accent strip
	var strip_rect := Rect2(card_rect.position.x, card_rect.position.y, 3.0, card_rect.size.y)
	canvas.draw_rect(strip_rect, BrandClass.with_alpha(accent_color, 0.85))

	var inner_x := card_rect.position.x + 14.0
	var inner_w := card_rect.size.x - 28.0

	# Card header
	var header_y := card_rect.position.y + 18.0
	if header_y >= clip_top and header_y <= clip_bottom:
		canvas.draw_string(font, Vector2(inner_x, header_y), header_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, accent_color)

	# Divider line under header
	var div_y := card_rect.position.y + 24.0
	if div_y >= clip_top and div_y <= clip_bottom:
		canvas.draw_line(Vector2(inner_x, div_y), Vector2(inner_x + inner_w, div_y), BrandClass.with_alpha(accent_color, 0.22), 1.0)

	# Body text lines
	var cur_text_y := card_rect.position.y + 40.0
	var line_step := 20.0
	for line in lines:
		if cur_text_y >= clip_top and cur_text_y <= clip_bottom:
			canvas.draw_string(font, Vector2(inner_x, cur_text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT)
		cur_text_y += line_step


func _draw_crosshair(canvas: CanvasItem, pos: Vector2, col: Color) -> void:
	canvas.draw_line(pos - Vector2(4, 0), pos + Vector2(4, 0), col, 1.0)
	canvas.draw_line(pos - Vector2(0, 4), pos + Vector2(0, 4), col, 1.0)


func _draw_schematic(
	canvas: CanvasItem,
	rect: Rect2,
	schematic_id: String,
	pulse: float,
	font: Font,
	font_size: int
) -> void:
	var center := rect.position + rect.size * 0.5
	match schematic_id:
		"dijkstra":
			_draw_schem_dijkstra(canvas, rect, center, pulse, font, font_size)
		"edmonds_karp":
			_draw_schem_edmonds_karp(canvas, rect, center, pulse, font, font_size)
		"mtd":
			_draw_schem_mtd(canvas, rect, center, pulse, font, font_size)
		"attack_graphs":
			_draw_schem_attack_graphs(canvas, rect, center, pulse, font, font_size)
		"graph_theory":
			_draw_schem_graph_theory(canvas, rect, center, pulse, font, font_size)
		"firewall":
			_draw_schem_firewall(canvas, rect, center, pulse, font, font_size)
		"ids":
			_draw_schem_ids(canvas, rect, center, pulse, font, font_size)
		"honeypot":
			_draw_schem_honeypot(canvas, rect, center, pulse, font, font_size)
		"terminal":
			_draw_schem_terminal(canvas, rect, center, pulse, font, font_size)
		"pursuer":
			_draw_schem_pursuer(canvas, rect, center, pulse, font, font_size)
		"vertex_arch":
			_draw_schem_vertex_arch(canvas, rect, center, pulse, font, font_size)
		"paper_ref":
			_draw_schem_paper_ref(canvas, rect, center, pulse, font, font_size)
		"education":
			_draw_schem_education(canvas, rect, center, pulse, font, font_size)
		_:
			canvas.draw_string(font, Vector2(center.x - 80.0, center.y + 5.0), "[DIAGRAMA EN LÍNEA]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT_DIM)


func _draw_schem_dijkstra(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	var n0 := c + Vector2(-140.0, 10.0)
	var n1 := c + Vector2(-50.0, -38.0)
	var n2 := c + Vector2(40.0, -38.0)
	var n3 := c + Vector2(130.0, 10.0)
	var n4 := c + Vector2(-10.0, 48.0)

	# Alternate sub-optimal path
	canvas.draw_line(n0, n4, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.70), 1.5)
	canvas.draw_line(n4, n3, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.70), 1.5)
	canvas.draw_string(font, (n0 + n4) * 0.5 + Vector2(-10, 14), "c=7", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)
	canvas.draw_string(font, (n4 + n3) * 0.5 + Vector2(5, 14), "c=6", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)

	# Optimal Shortest Path
	canvas.draw_line(n0, n1, BrandClass.ACCENT, 2.5)
	canvas.draw_line(n1, n2, BrandClass.ACCENT, 2.5)
	canvas.draw_line(n2, n3, BrandClass.ACCENT, 2.5)

	canvas.draw_string(font, (n0 + n1) * 0.5 + Vector2(-16, -6), "c=1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.ACCENT)
	canvas.draw_string(font, (n1 + n2) * 0.5 + Vector2(-8, -8), "c=2", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.ACCENT)
	canvas.draw_string(font, (n2 + n3) * 0.5 + Vector2(8, -6), "c=1", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.ACCENT)

	# Animated traversal beacon
	var cycle := fmod(pulse * 0.9, 3.0)
	var bpos: Vector2
	if cycle < 1.0:
		bpos = n0.lerp(n1, cycle)
	elif cycle < 2.0:
		bpos = n1.lerp(n2, cycle - 1.0)
	else:
		bpos = n2.lerp(n3, cycle - 2.0)
	canvas.draw_circle(bpos, 5.0, BrandClass.ACCENT)
	canvas.draw_circle(bpos, 8.0, BrandClass.with_alpha(BrandClass.ACCENT, 0.35), false, 1.5)

	# Draw Nodes
	var nodes := [
		{"pos": n0, "lbl": "SRC", "col": BrandClass.SUCCESS},
		{"pos": n1, "lbl": "A", "col": BrandClass.ACCENT},
		{"pos": n2, "lbl": "B", "col": BrandClass.ACCENT},
		{"pos": n3, "lbl": "DST", "col": BrandClass.WARNING},
		{"pos": n4, "lbl": "C", "col": BrandClass.TEXT_DIM},
	]
	for nd in nodes:
		canvas.draw_circle(nd["pos"], 12.0, BrandClass.PANEL_SOLID)
		canvas.draw_circle(nd["pos"], 12.0, nd["col"], false, 1.5)
		canvas.draw_string(font, nd["pos"] + Vector2(-8, 4), nd["lbl"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, nd["col"])


func _draw_schem_edmonds_karp(canvas: CanvasItem, _rect: Rect2, c: Vector2, _pulse: float, font: Font, font_size: int) -> void:
	var s := c + Vector2(-140.0, 0.0)
	var u := c + Vector2(-40.0, -42.0)
	var w := c + Vector2(-40.0, 42.0)
	var v := c + Vector2(50.0, -42.0)
	var z := c + Vector2(50.0, 42.0)
	var t := c + Vector2(140.0, 0.0)

	# Flow edges
	var edges := [
		{"from": s, "to": u, "flow": "12/12", "sat": true},
		{"from": s, "to": w, "flow": "14/14", "sat": true},
		{"from": u, "to": v, "flow": "12/12", "sat": true},
		{"from": w, "to": z, "flow": "14/16", "sat": false},
		{"from": v, "to": t, "flow": "12/12", "sat": true},
		{"from": z, "to": t, "flow": "14/14", "sat": true},
		{"from": u, "to": z, "flow": "0/4", "sat": false},
	]
	for e in edges:
		var col: Color = BrandClass.DANGER if e["sat"] else BrandClass.PANEL_BORDER
		canvas.draw_line(e["from"], e["to"], col, 2.0 if e["sat"] else 1.2)
		var mid: Vector2 = (e["from"] + e["to"]) * 0.5
		canvas.draw_string(font, mid + Vector2(-12, -4), e["flow"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, col)

	# Min-Cut Boundary (dashed vertical barrier)
	var cut_x := c.x + 5.0
	for y_off in range(-60, 65, 12):
		canvas.draw_line(Vector2(cut_x, c.y + float(y_off)), Vector2(cut_x, c.y + float(y_off + 6)), BrandClass.DANGER, 2.0)
	canvas.draw_string(font, Vector2(cut_x - 38.0, c.y - 52.0), "[CORTE MÍNIMO]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.DANGER)

	# Nodes
	var nodes := [
		{"pos": s, "lbl": "S", "col": BrandClass.ACCENT},
		{"pos": u, "lbl": "U", "col": BrandClass.TEXT_DIM},
		{"pos": w, "lbl": "W", "col": BrandClass.TEXT_DIM},
		{"pos": v, "lbl": "V", "col": BrandClass.TEXT_DIM},
		{"pos": z, "lbl": "Z", "col": BrandClass.TEXT_DIM},
		{"pos": t, "lbl": "T", "col": BrandClass.WARNING},
	]
	for nd in nodes:
		canvas.draw_circle(nd["pos"], 11.0, BrandClass.PANEL_SOLID)
		canvas.draw_circle(nd["pos"], 11.0, nd["col"], false, 1.4)
		canvas.draw_string(font, nd["pos"] + Vector2(-4, 4), nd["lbl"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, nd["col"])


func _draw_schem_mtd(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	# Rotating & oscillating topology
	var num_nodes := 5
	var center_node := c
	canvas.draw_circle(center_node, 14.0, BrandClass.PANEL_SOLID)
	canvas.draw_circle(center_node, 14.0, BrandClass.ACCENT, false, 2.0)
	canvas.draw_string(font, center_node + Vector2(-10, 4), "CORE", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.ACCENT)

	# Radiating mutation wave
	var wave_r := fmod(pulse * 35.0, 75.0)
	var wave_alpha := 1.0 - (wave_r / 75.0)
	canvas.draw_circle(center_node, wave_r, BrandClass.with_alpha(BrandClass.ACCENT, wave_alpha * 0.4), false, 1.2)

	var peri_nodes: Array[Vector2] = []
	for i in range(num_nodes):
		var base_ang := (float(i) / float(num_nodes)) * TAU + pulse * 0.6
		var dist := 55.0 + 12.0 * sin(pulse * 2.0 + float(i))
		var pos := center_node + Vector2(cos(base_ang), sin(base_ang)) * dist
		peri_nodes.append(pos)

	for i in range(num_nodes):
		var n_pos: Vector2 = peri_nodes[i]
		var col := BrandClass.WARNING if (i % 2 == 0) else BrandClass.SUCCESS
		canvas.draw_line(center_node, n_pos, BrandClass.with_alpha(col, 0.70), 1.5)
		var next_pos: Vector2 = peri_nodes[(i + 1) % num_nodes]
		var active_link := sin(pulse * 1.5 + float(i)) > -0.2
		if active_link:
			canvas.draw_line(n_pos, next_pos, BrandClass.with_alpha(BrandClass.ACCENT, 0.85), 1.5)
		else:
			canvas.draw_line(n_pos, next_pos, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.35), 1.0)
		canvas.draw_circle(n_pos, 8.0, BrandClass.PANEL_SOLID)
		canvas.draw_circle(n_pos, 8.0, col, false, 1.4)


func _draw_schem_attack_graphs(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	var t0 := c + Vector2(-140.0, 0.0)
	var t1 := c + Vector2(-45.0, -28.0)
	var t2 := c + Vector2(45.0, 24.0)
	var t3 := c + Vector2(135.0, 0.0)

	# Escalation links
	canvas.draw_line(t0, t1, BrandClass.SUCCESS, 2.0)
	canvas.draw_line(t1, t2, BrandClass.WARNING, 2.0)
	canvas.draw_line(t2, t3, BrandClass.DANGER, 2.0)

	canvas.draw_string(font, (t0 + t1) * 0.5 + Vector2(-30, -10), "[CVE: RCE]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.SUCCESS)
	canvas.draw_string(font, (t1 + t2) * 0.5 + Vector2(-30, -6), "[PRIV_ESC]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.WARNING)
	canvas.draw_string(font, (t2 + t3) * 0.5 + Vector2(-20, 16), "[ROOT_EXPLOIT]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.DANGER)

	var stages := [
		{"pos": t0, "lbl": "DMZ", "sub": "TIER 0", "col": BrandClass.SUCCESS},
		{"pos": t1, "lbl": "USER", "sub": "TIER 1", "col": BrandClass.ACCENT},
		{"pos": t2, "lbl": "ADMIN", "sub": "TIER 2", "col": BrandClass.WARNING},
		{"pos": t3, "lbl": "ROOT", "sub": "TIER 3", "col": BrandClass.DANGER},
	]
	for st in stages:
		canvas.draw_circle(st["pos"], 13.0, BrandClass.PANEL_SOLID)
		canvas.draw_circle(st["pos"], 13.0, st["col"], false, 1.6)
		canvas.draw_string(font, st["pos"] + Vector2(-10, 4), st["lbl"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, st["col"])
		canvas.draw_string(font, st["pos"] + Vector2(-14, 23), st["sub"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.TEXT_DIM)

	# Breach indicator pulse
	var target_stage: Vector2 = t2 if sin(pulse * 2.0) > 0.0 else t3
	canvas.draw_circle(target_stage, 17.0 + 3.0 * sin(pulse * 4.0), BrandClass.with_alpha(BrandClass.DANGER, 0.45), false, 1.5)


func _draw_schem_graph_theory(canvas: CanvasItem, _rect: Rect2, c: Vector2, _pulse: float, font: Font, font_size: int) -> void:
	var num_v := 6
	var r := 54.0
	var verts: Array[Vector2] = []
	for i in range(num_v):
		var ang := (float(i) / float(num_v)) * TAU - PI * 0.5
		verts.append(c + Vector2(cos(ang), sin(ang)) * r)

	# Complete/Chord connections
	for i in range(num_v):
		for j in range(i + 1, num_v):
			var is_perimeter := (j == i + 1) or (i == 0 and j == num_v - 1)
			if is_perimeter:
				canvas.draw_line(verts[i], verts[j], BrandClass.ACCENT, 2.0)
			elif (i + j) % 2 == 0:
				canvas.draw_line(verts[i], verts[j], BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.60), 1.0)

	for i in range(num_v):
		canvas.draw_circle(verts[i], 8.0, BrandClass.PANEL_SOLID)
		canvas.draw_circle(verts[i], 8.0, BrandClass.ACCENT, false, 1.5)
		canvas.draw_string(font, verts[i] + Vector2(-3, 3), "v%d" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.TEXT)

	canvas.draw_string(font, c + Vector2(-36, -5), "|V|=6  |E|=11", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)
	canvas.draw_string(font, c + Vector2(-40, 12), "deg(v) in [3, 4]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.accent_dim(0.85))


func _draw_schem_firewall(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	# Central firewall barrier
	var bar_w := 14.0
	var bar_h := 110.0
	var bar_rect := Rect2(c.x - bar_w * 0.5, c.y - bar_h * 0.5, bar_w, bar_h)
	canvas.draw_rect(bar_rect, BrandClass.with_alpha(BrandClass.WARNING, 0.20))
	canvas.draw_rect(bar_rect, BrandClass.WARNING, false, 1.5)

	# Firewall brick hatching
	for y_step in range(int(bar_rect.position.y), int(bar_rect.position.y + bar_h), 14):
		canvas.draw_line(Vector2(bar_rect.position.x, float(y_step)), Vector2(bar_rect.position.x + bar_w, float(y_step)), BrandClass.WARNING, 1.0)

	canvas.draw_string(font, Vector2(bar_rect.position.x - 28.0, bar_rect.position.y - 8.0), "FIREWALL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.WARNING)

	# Left Packets (Moving Right)
	var left_lanes := [-30.0, 0.0, 30.0]
	for i in range(left_lanes.size()):
		var ly: float = c.y + left_lanes[i]
		var px_raw := fmod(pulse * 60.0 + float(i) * 55.0, 180.0)
		var is_blocked := (i != 1)
		var cur_px := c.x - 140.0 + px_raw
		var pcol: Color = BrandClass.DANGER if is_blocked else BrandClass.SUCCESS

		if is_blocked:
			cur_px = minf(cur_px, bar_rect.position.x - 6.0)
			canvas.draw_circle(Vector2(cur_px, ly), 4.5, pcol)
			if cur_px >= bar_rect.position.x - 7.0:
				canvas.draw_line(Vector2(cur_px - 3, ly - 3), Vector2(cur_px + 3, ly + 3), BrandClass.DANGER, 2.0)
				canvas.draw_line(Vector2(cur_px - 3, ly + 3), Vector2(cur_px + 3, ly - 3), BrandClass.DANGER, 2.0)
		else:
			canvas.draw_circle(Vector2(cur_px, ly), 4.5, pcol)

		canvas.draw_line(Vector2(c.x - 140.0, ly), Vector2(c.x + 140.0, ly), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.25), 1.0)


func _draw_schem_ids(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	# Concentric Radar Rings
	var radii := [25.0, 50.0, 72.0]
	for r in radii:
		canvas.draw_circle(c, r, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), false, 1.0)

	canvas.draw_line(c - Vector2(76, 0), c + Vector2(76, 0), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), 1.0)
	canvas.draw_line(c - Vector2(0, 76), c + Vector2(0, 76), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), 1.0)

	# Sweeping Radar Line
	var ang := pulse * 2.2
	var sweep_end := c + Vector2(cos(ang), sin(ang)) * 72.0
	canvas.draw_line(c, sweep_end, BrandClass.ACCENT, 2.0)

	# Detection Blips
	var blips := [
		{"ang": 0.8, "dist": 42.0, "lbl": "TRAFICO ANOMALO"},
		{"ang": 2.4, "dist": 60.0, "lbl": "FIRMA #402"},
	]
	for b in blips:
		var b_ang: float = b["ang"]
		var b_dist: float = b["dist"]
		var bpos: Vector2 = c + Vector2(cos(b_ang), sin(b_ang)) * b_dist
		var diff: float = fmod(ang - b_ang + TAU, TAU)
		var intensity: float = clampf(1.0 - (diff / 2.0), 0.2, 1.0)
		var bcol: Color = BrandClass.with_alpha(BrandClass.WARNING, intensity)
		canvas.draw_circle(bpos, 4.0, bcol)
		if intensity > 0.6:
			canvas.draw_circle(bpos, 8.0, BrandClass.with_alpha(BrandClass.WARNING, 0.40), false, 1.2)
			canvas.draw_string(font, bpos + Vector2(8, 4), b["lbl"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.WARNING)


func _draw_schem_honeypot(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	# Quarantine Zone
	canvas.draw_circle(c, 58.0, BrandClass.with_alpha(BrandClass.WARNING, 0.10))
	canvas.draw_circle(c, 58.0, BrandClass.with_alpha(BrandClass.WARNING, 0.55), false, 1.2)
	canvas.draw_string(font, c + Vector2(-48, -64), "[ZONA DE ENGAÑO]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.WARNING)

	# Central Decoy Node
	canvas.draw_circle(c, 16.0, BrandClass.PANEL_SOLID)
	canvas.draw_circle(c, 16.0, BrandClass.WARNING, false, 2.0)
	canvas.draw_string(font, c + Vector2(-15, 4), "DECOY", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.WARNING)

	# Lure Vectors
	var lure_angles := [0.6, 2.1, 4.0, 5.2]
	for i in range(lure_angles.size()):
		var la: float = lure_angles[i]
		var src := c + Vector2(cos(la), sin(la)) * 110.0
		var t := fmod(pulse * 0.7 + float(i) * 0.25, 1.0)
		var bpos := src.lerp(c, t)
		canvas.draw_line(src, c, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.35), 1.0)
		canvas.draw_circle(bpos, 3.5, BrandClass.DANGER)

	canvas.draw_string(font, c + Vector2(-35, 34), "SSH:22 [OPEN]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)


func _draw_schem_terminal(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	# Concentric security orbital rings with gaps
	var r3 := 65.0
	var r1 := 44.0
	var r0 := 24.0

	var ang_offset := pulse * 0.4
	canvas.draw_arc(c, r3, ang_offset, ang_offset + PI * 1.5, 32, BrandClass.with_alpha(BrandClass.ACCENT, 0.70), 1.5)
	canvas.draw_arc(c, r1, -ang_offset, -ang_offset + PI * 1.4, 32, BrandClass.with_alpha(BrandClass.WARNING, 0.70), 1.5)

	# Core Root Node
	canvas.draw_circle(c, r0, BrandClass.PANEL_SOLID)
	canvas.draw_circle(c, r0, BrandClass.DANGER, false, 2.2)
	canvas.draw_string(font, c + Vector2(-12, 4), "ROOT", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.DANGER)

	canvas.draw_string(font, c + Vector2(-55, -72), "ANILLO 3: USER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.ACCENT)
	canvas.draw_string(font, c + Vector2(25, -48), "ANILLO 1: SVC", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.WARNING)
	canvas.draw_string(font, c + Vector2(-45, 52), "ANILLO 0: KERNEL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.DANGER)


func _draw_schem_pursuer(canvas: CanvasItem, _rect: Rect2, c: Vector2, pulse: float, font: Font, font_size: int) -> void:
	# Target / Player
	var p_pos := c + Vector2(-60.0, 24.0)
	var p_vel := Vector2(70.0, 0.0)
	canvas.draw_circle(p_pos, 10.0, BrandClass.PANEL_SOLID)
	canvas.draw_circle(p_pos, 10.0, BrandClass.ACCENT, false, 1.8)
	canvas.draw_string(font, p_pos + Vector2(-4, 4), "P", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.ACCENT)
	canvas.draw_line(p_pos, p_pos + p_vel * 0.7, BrandClass.ACCENT, 2.0)

	# Pursuer / Hostile Agent
	var e_pos := c + Vector2(-80.0, -42.0)
	canvas.draw_circle(e_pos, 10.0, BrandClass.PANEL_SOLID)
	canvas.draw_circle(e_pos, 10.0, BrandClass.ENEMY, false, 1.8)
	canvas.draw_string(font, e_pos + Vector2(-4, 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.ENEMY)

	# Intercept Point
	var i_pos := p_pos + Vector2(100.0, 0.0)
	canvas.draw_line(e_pos, i_pos, BrandClass.with_alpha(BrandClass.ENEMY, 0.75), 1.5)
	canvas.draw_line(p_pos, i_pos, BrandClass.with_alpha(BrandClass.ACCENT, 0.40), 1.0)

	# Reticle on Intercept
	var r_sz := 7.0 + 2.0 * sin(pulse * 3.0)
	canvas.draw_line(i_pos - Vector2(r_sz, 0), i_pos + Vector2(r_sz, 0), BrandClass.ENEMY, 1.5)
	canvas.draw_line(i_pos - Vector2(0, r_sz), i_pos + Vector2(0, r_sz), BrandClass.ENEMY, 1.5)
	canvas.draw_circle(i_pos, r_sz * 0.7, BrandClass.with_alpha(BrandClass.ENEMY, 0.35), false, 1.0)

	canvas.draw_string(font, i_pos + Vector2(10, 4), "INTERCEPT = POS + V*t", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.ENEMY)


func _draw_schem_vertex_arch(canvas: CanvasItem, _rect: Rect2, c: Vector2, _pulse: float, font: Font, font_size: int) -> void:
	var b_w := 180.0
	var b_h := 26.0

	var b1 := Rect2(c.x - b_w * 0.5 + 24.0, c.y - 48.0, b_w, b_h)
	var b2 := Rect2(c.x - b_w * 0.5 + 24.0, c.y - 12.0, b_w, b_h)
	var b3 := Rect2(c.x - b_w * 0.5 + 24.0, c.y + 24.0, b_w, b_h)

	var layers := [
		{"rect": b1, "lbl": "HEIST // CAMINO MINIMO", "col": BrandClass.SUCCESS},
		{"rect": b2, "lbl": "HACKER // ATTACK GRAPHS", "col": BrandClass.ACCENT},
		{"rect": b3, "lbl": "DEFENDER // MTD & CORTE", "col": BrandClass.WARNING},
	]
	for ly in layers:
		canvas.draw_rect(ly["rect"], BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
		canvas.draw_rect(ly["rect"], ly["col"], false, 1.2)
		canvas.draw_string(font, Vector2(ly["rect"].position.x + 8.0, ly["rect"].position.y + 17.0), ly["lbl"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, ly["col"])

	# Bus interconnects
	var bus_x := c.x - b_w * 0.5 - 20.0
	var bus_y_top := c.y - 35.0
	var bus_y_mid := c.y + 1.0
	var bus_y_bot := c.y + 37.0
	canvas.draw_line(Vector2(bus_x, bus_y_top), Vector2(bus_x, bus_y_bot), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(bus_x, bus_y_top), Vector2(b1.position.x, bus_y_top), BrandClass.ACCENT, 1.5)
	canvas.draw_line(Vector2(bus_x, bus_y_mid), Vector2(b2.position.x, bus_y_mid), BrandClass.ACCENT, 1.5)
	canvas.draw_line(Vector2(bus_x, bus_y_bot), Vector2(b3.position.x, bus_y_bot), BrandClass.ACCENT, 1.5)
	canvas.draw_string(font, Vector2(bus_x - 30.0, bus_y_top - 10.0), "GRAPH BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)


func _draw_schem_paper_ref(canvas: CanvasItem, _rect: Rect2, c: Vector2, _pulse: float, font: Font, font_size: int) -> void:
	var o := c + Vector2(-120.0, 45.0)
	var x_end := c + Vector2(120.0, 45.0)
	var y_end := c + Vector2(-120.0, -50.0)

	canvas.draw_line(o, x_end, BrandClass.TEXT_DIM, 1.5)
	canvas.draw_line(o, y_end, BrandClass.TEXT_DIM, 1.5)

	canvas.draw_string(font, x_end + Vector2(-45, 14), "TIEMPO (t)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.TEXT_DIM)
	canvas.draw_string(font, y_end + Vector2(-8, -6), "P(RESILIENCIA)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.TEXT_DIM)

	# Static defense curve (decaying)
	var pts_static: PackedVector2Array = []
	for i in range(10):
		var t := float(i) / 9.0
		var x := o.x + t * 220.0
		var y := o.y - (1.0 - t * 0.8) * 80.0
		pts_static.append(Vector2(x, y))
	for i in range(pts_static.size() - 1):
		canvas.draw_line(pts_static[i], pts_static[i + 1], BrandClass.DANGER, 1.5)

	# MTD dynamic defense curve (resilient, high)
	var pts_mtd: PackedVector2Array = []
	for i in range(10):
		var t := float(i) / 9.0
		var x := o.x + t * 220.0
		var y := o.y - (0.85 + 0.08 * sin(t * PI * 3.0)) * 80.0
		pts_mtd.append(Vector2(x, y))
	for i in range(pts_mtd.size() - 1):
		canvas.draw_line(pts_mtd[i], pts_mtd[i + 1], BrandClass.SUCCESS, 2.0)

	# Relocate legend to top-right corner clear of curves
	canvas.draw_string(font, Vector2(c.x + 10.0, y_end.y + 12.0), "--- ESTATICA (DECAE)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.DANGER)
	canvas.draw_string(font, Vector2(c.x + 10.0, y_end.y + 26.0), "─── DINAMICA MTD (RESILIENTE)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.SUCCESS)


func _draw_schem_education(canvas: CanvasItem, _rect: Rect2, c: Vector2, _pulse: float, font: Font, font_size: int) -> void:
	var tiers := [
		{"y": c.y - 40.0, "w": 160.0, "lbl": "NIVEL 3: EVALUAR / CREAR", "col": BrandClass.SUCCESS},
		{"y": c.y - 8.0, "w": 200.0, "lbl": "NIVEL 2: APLICAR / ANALIZAR", "col": BrandClass.WARNING},
		{"y": c.y + 24.0, "w": 240.0, "lbl": "NIVEL 1: RECORDAR / COMPRENDER", "col": BrandClass.ACCENT},
	]
	for tr in tiers:
		var r := Rect2(c.x - tr["w"] * 0.5 + 20.0, tr["y"], tr["w"], 22.0)
		canvas.draw_rect(r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
		canvas.draw_rect(r, tr["col"], false, 1.2)
		canvas.draw_string(font, Vector2(r.position.x + 10.0, r.position.y + 15.0), tr["lbl"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, tr["col"])

	# Progression arrow on the left
	var arrow_x := c.x - 130.0
	canvas.draw_line(Vector2(arrow_x, c.y + 40.0), Vector2(arrow_x, c.y - 36.0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(arrow_x, c.y - 36.0), Vector2(arrow_x - 4, c.y - 28.0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(arrow_x, c.y - 36.0), Vector2(arrow_x + 4, c.y - 28.0), BrandClass.ACCENT, 2.0)
	canvas.draw_string(font, Vector2(arrow_x - 22.0, c.y - 44.0), "DOMINIO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.ACCENT)
