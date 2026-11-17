extends RefCounted

## Left operator ID card (Carnet Izquierdo) for LA BÓVEDA // PERFIL.
## Extracted from escenas/menu/profile.gd. State lives on the Profile orchestrator (`p`).

const BrandClass = preload("res://juego/ui/brand.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")

var p: Profile
var featured_label: Label


func _init(profile: Profile) -> void:
	p = profile


func refresh_featured() -> void:
	if featured_label != null:
		featured_label.text = "★ DESTACADA: " + p._featured_badge_title


func build(parent: Control) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(310, 0)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#0E131A"), Color("#1E2736")))
	parent.add_child(card)
	
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 14)
	left_margin.add_theme_constant_override("margin_top", 14)
	left_margin.add_theme_constant_override("margin_right", 14)
	left_margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(left_margin)
	
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 10)
	left_margin.add_child(left_vbox)
	
	var left_header := HBoxContainer.new()
	left_vbox.add_child(left_header)
	var lbl_kernel := Label.new()
	lbl_kernel.text = "VERTEX // KERNEL"
	lbl_kernel.add_theme_color_override("font_color", BrandClass.ACCENT)
	left_header.add_child(lbl_kernel)
	
	var sp_hdr := Control.new()
	sp_hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_header.add_child(sp_hdr)
	
	var btn_back := Button.new()
	btn_back.text = "[ ← VOLVER ]"
	btn_back.custom_minimum_size = Vector2(0, 36)
	btn_back.pressed.connect(p._back_to_menu)
	left_header.add_child(btn_back)
	
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color("#1E2736"))
	left_vbox.add_child(sep)
	
	var rank_info: Dictionary = ProfileRendererClass.get_rank_info(int(p.stats.get("total_stars", 0)))
	var id_box := VBoxContainer.new()
	id_box.add_theme_constant_override("separation", 6)
	left_vbox.add_child(id_box)
	
	var lbl_state := Label.new()
	lbl_state.text = "ESTADO DEL OPERADOR"
	lbl_state.add_theme_font_size_override("font_size", 11)
	lbl_state.add_theme_color_override("font_color", Color("#6E7B8B"))
	id_box.add_child(lbl_state)
	
	var lbl_rank := Label.new()
	lbl_rank.text = str(rank_info.get("title", ""))
	lbl_rank.add_theme_font_size_override("font_size", 18)
	lbl_rank.add_theme_color_override("font_color", rank_info.get("color", BrandClass.ACCENT))
	lbl_rank.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	id_box.add_child(lbl_rank)
	
	var lbl_tier := Label.new()
	lbl_tier.text = "%s // ESTRELLAS: %d ★" % [str(rank_info.get("tier", "")), int(p.stats.get("total_stars", 0))]
	lbl_tier.add_theme_font_size_override("font_size", 12)
	lbl_tier.add_theme_color_override("font_color", Color("#39FF88"))
	id_box.add_child(lbl_tier)
	
	var line_name := LineEdit.new()
	line_name.text = p.player_name
	line_name.custom_minimum_size = Vector2(0, 34)
	var le_style := StyleBoxFlat.new()
	le_style.bg_color = Color("#07090C")
	le_style.border_width_bottom = 1
	le_style.border_color = Color("#00F0FF")
	line_name.add_theme_stylebox_override("normal", le_style)
	line_name.text_changed.connect(func(new_text: String) -> void: p.player_name = new_text; p._save_profile())
	id_box.add_child(line_name)
	
	var feat_panel := PanelContainer.new()
	feat_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#141C26"), Color.TRANSPARENT, Color("#00F0FF")))
	left_vbox.add_child(feat_panel)
	var feat_margin := MarginContainer.new()
	feat_margin.add_theme_constant_override("margin_left", 10)
	feat_margin.add_theme_constant_override("margin_top", 8)
	feat_margin.add_theme_constant_override("margin_right", 10)
	feat_margin.add_theme_constant_override("margin_bottom", 8)
	feat_panel.add_child(feat_margin)
	var lbl_feat := Label.new()
	featured_label = lbl_feat
	lbl_feat.text = "★ DESTACADA: " + p._featured_badge_title
	lbl_feat.add_theme_font_size_override("font_size", 12)
	lbl_feat.add_theme_color_override("font_color", BrandClass.ACCENT)
	feat_margin.add_child(lbl_feat)
	
	var tele_box := VBoxContainer.new()
	tele_box.add_theme_constant_override("separation", 4)
	left_vbox.add_child(tele_box)
	
	var metrics: Array[String] = [
		"Niveles Superados: %d" % int(p.stats.get("levels_completed", 0)),
		"Tiempo de Enlace: %ds" % int(p.stats.get("play_time_seconds", 0)),
		"Racha Máxima: %d" % int(p.stats.get("best_streak", 0)),
		"Ratio de Victoria: %.1f%%" % float(p.stats.get("win_rate", 0.0)),
		"Insignias Tácticas: %d / 24" % Array(p.stats.get("badges", [])).size()
	]
	for m_str in metrics:
		var ml := Label.new()
		ml.text = m_str
		ml.add_theme_font_size_override("font_size", 12)
		ml.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
		tele_box.add_child(ml)
	
	var sp_bot := Control.new()
	sp_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(sp_bot)
	
	var slots_hbox := HBoxContainer.new()
	slots_hbox.add_theme_constant_override("separation", 8)
	left_vbox.add_child(slots_hbox)
	for slot_idx in range(3):
		var sbtn := Button.new()
		sbtn.text = "SLOT 0%d" % [slot_idx + 1]
		sbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sbtn.custom_minimum_size = Vector2(0, 40)
		slots_hbox.add_child(sbtn)
	return card
