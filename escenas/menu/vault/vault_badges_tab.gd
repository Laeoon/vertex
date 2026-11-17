extends RefCounted

## Tab 01 // INSIGNIAS: 4x6 badge grid + inspector.
## Extracted from escenas/menu/profile.gd. State lives on the Profile orchestrator (`p`).

const BrandClass = preload("res://juego/ui/brand.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

var p: Profile


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	_build_tab_insignias(container)


func _build_tab_insignias(container: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	var badges: Array[Dictionary] = VaultModules.BADGES
	for b_idx in range(badges.size()):
		var badge: Dictionary = badges[b_idx]
		var unlocked: bool = p.stats.get("badges", []).has(badge.get("id", "")) or b_idx < 4

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 74)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.clip_text = true
		if not unlocked:
			btn.modulate = Color(1, 1, 1, 0.38)

		var is_sel: bool = (b_idx == p._selected_badge_idx)
		var sel_accent: Color = Color("#00F0FF") if is_sel else Color.TRANSPARENT
		var norm_bg: Color = Color("#182230") if is_sel else Color("#141C26")
		btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(norm_bg, Color.TRANSPARENT, sel_accent))
		btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color.TRANSPARENT, sel_accent))
		btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color.TRANSPARENT, sel_accent))

		var mc := MarginContainer.new()
		mc.set_anchors_preset(Control.PRESET_FULL_RECT)
		mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mc.add_theme_constant_override("margin_left", 6)
		mc.add_theme_constant_override("margin_top", 4)
		mc.add_theme_constant_override("margin_right", 6)
		mc.add_theme_constant_override("margin_bottom", 4)
		btn.add_child(mc)

		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mc.add_child(vb)

		var glyph_lbl := Label.new()
		glyph_lbl.text = str(badge.get("glyph", "◈"))
		glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph_lbl.add_theme_font_override("font", p.font)
		glyph_lbl.add_theme_font_size_override("font_size", 20)
		glyph_lbl.add_theme_color_override("font_color", BrandClass.ACCENT)
		vb.add_child(glyph_lbl)

		var title_lbl := Label.new()
		title_lbl.text = str(badge.get("title", ""))
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.add_theme_font_override("font", p.font)
		title_lbl.add_theme_font_size_override("font_size", 11)
		title_lbl.add_theme_color_override("font_color", BrandClass.TEXT)
		vb.add_child(title_lbl)

		var status_lbl := Label.new()
		status_lbl.text = "[✓]" if unlocked else "[🔒 BLOQUEADA]"
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.add_theme_font_override("font", p.font)
		status_lbl.add_theme_font_size_override("font_size", 10)
		status_lbl.add_theme_color_override("font_color", BrandClass.SUCCESS if unlocked else BrandClass.ENEMY)
		vb.add_child(status_lbl)

		var captured_idx: int = b_idx
		btn.pressed.connect(func() -> void:
			p._selected_badge_idx = captured_idx
			p._play_click_sfx()
			_refresh_tab_insignias_inspector(container)
			p.queue_redraw()
		)
		grid.add_child(btn)

	var inspector_panel := PanelContainer.new()
	inspector_panel.custom_minimum_size = Vector2(300, 0)
	inspector_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#141C26"), Color("#1E2736")))
	inspector_panel.name = "InspectorPanel"
	hbox.add_child(inspector_panel)

	var insp_mc := MarginContainer.new()
	insp_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	insp_mc.add_theme_constant_override("margin_left", 14)
	insp_mc.add_theme_constant_override("margin_top", 14)
	insp_mc.add_theme_constant_override("margin_right", 14)
	insp_mc.add_theme_constant_override("margin_bottom", 14)
	inspector_panel.add_child(insp_mc)

	var insp_vb := VBoxContainer.new()
	insp_vb.name = "InspectorVBox"
	insp_vb.add_theme_constant_override("separation", 10)
	insp_mc.add_child(insp_vb)

	_refresh_tab_insignias_inspector(container)


func _refresh_tab_insignias_inspector(container: Control) -> void:
	var inspector_panel := container.find_child("InspectorPanel", true, false) as PanelContainer
	if inspector_panel == null:
		return
	var insp_vb := inspector_panel.find_child("InspectorVBox", true, false) as VBoxContainer
	if insp_vb == null:
		return
	for child in insp_vb.get_children():
		child.queue_free()

	var badges: Array[Dictionary] = VaultModules.BADGES
	if p._selected_badge_idx < 0 or p._selected_badge_idx >= badges.size():
		return
	var badge: Dictionary = badges[p._selected_badge_idx]
	var unlocked: bool = p.stats.get("badges", []).has(badge.get("id", "")) or p._selected_badge_idx < 4

	var header_lbl := Label.new()
	header_lbl.text = "INSPECTOR DE INSIGNIA"
	header_lbl.add_theme_font_override("font", p.font)
	header_lbl.add_theme_font_size_override("font_size", 12)
	header_lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	insp_vb.add_child(header_lbl)

	var big_glyph := Label.new()
	big_glyph.text = str(badge.get("glyph", "◈"))
	big_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_glyph.add_theme_font_size_override("font_size", 36)
	big_glyph.add_theme_color_override("font_color", BrandClass.ACCENT)
	insp_vb.add_child(big_glyph)

	var title_lbl := Label.new()
	title_lbl.text = str(badge.get("title", ""))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", BrandClass.TEXT)
	insp_vb.add_child(title_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "ESTADO: " + ("[✓ DESBLOQUEADA]" if unlocked else "[🔒 BLOQUEADA]")
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", BrandClass.SUCCESS if unlocked else BrandClass.ENEMY)
	insp_vb.add_child(status_lbl)

	var rarity_lbl := Label.new()
	rarity_lbl.text = "RAREZA: " + str(badge.get("rarity", "COMÚN"))
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 11)
	rarity_lbl.add_theme_color_override("font_color", BrandClass.WARNING)
	insp_vb.add_child(rarity_lbl)

	var desc_lbl := Label.new()
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.text = str(badge.get("desc", "")) if unlocked else str(badge.get("req", ""))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", BrandClass.TEXT)
	insp_vb.add_child(desc_lbl)

	var feat_btn := Button.new()
	feat_btn.custom_minimum_size = Vector2(0, 44)
	feat_btn.text = "[ ★ DESTACAR EN CARNET ]"
	feat_btn.disabled = not unlocked
	feat_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#1E2736"), BrandClass.ACCENT))
	feat_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#243044"), BrandClass.ACCENT))
	feat_btn.add_theme_color_override("font_color", BrandClass.ACCENT)
	feat_btn.pressed.connect(func() -> void:
		p._featured_badge_title = str(badge.get("title", ""))
		p._play_click_sfx()
		p._save_profile()
		p.update_featured_badge_label()
		p.queue_redraw()
	)
	insp_vb.add_child(feat_btn)
