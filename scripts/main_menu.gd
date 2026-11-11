extends Control

## Profesjonalne Menu Główne — MutantSurvivor V1
## Wygląd zgodny z zatwierdzoną referencją produkcyjną:
## Pionowe menu (9:16) z dużym żołnierzem na tle płonącego postapokaliptycznego miasta,
## elegancką kartą etapu, złotym przyciskiem GRAJ i dopracowanym dolnym paskiem nawigacji.

@onready var bg_rect: TextureRect = $Background
@onready var legacy_top_bar: Control = $TopBar
@onready var legacy_center: Control = $CenterContainer

var user_profile_panel: UserProfilePanel = null
var current_hub_tab: int = 0 # 0=Baza, 1=Postać, 2=Ekwipunek, 3=Kampania, 4=Sklep, 5=Nagrody/Zadania

# Górny Pasek Dowódcy
var top_hub_panel: PanelContainer = null
var top_hub_content: HBoxContainer = null
var avatar_tex: TextureRect = null
var account_lvl_lbl: Label = null
var account_xp_bar: ProgressBar = null
var account_pwr_lbl: Label = null
var credits_lbl: Label = null
var gems_lbl: Label = null
var attempts_lbl: Label = null
var orient_btn: Button = null
var inbox_btn: Button = null
var daily_btn: Button = null
var settings_btn: Button = null

# Środkowy obszar (Baza vs Wbudowany Panel)
var middle_root: Control = null
var base_scroll: ScrollContainer = null
var base_vbox: VBoxContainer = null

# Elementy ekranu Bazy
var hero_big_tex: TextureRect = null
var hero_name_lbl: Label = null
var hero_skin_lbl: Label = null
var weapon_icon_tex: TextureRect = null
var weapon_name_lbl: Label = null

var stage_card: PanelContainer = null
var mission_description: Label = null
var stage_preview: TextureRect = null
var hero_spacer_control: Control = null
var stage_title_lbl: Label = null
var stage_details_lbl: Label = null
var stage_pwr_lbl: Label = null
var stage_rewards_hbox: HBoxContainer = null
var boss_preview_tex: TextureRect = null
var diff_btn: Button = null
var play_big_btn: Button = null
var campaign_progress_label: Label = null
var campaign_progress_bar: ProgressBar = null
var campaign_milestone_labels: Array[Label] = []
var base_power_label: Label = null
var practice_btn: Button = null
var stage_prev_btn: Button = null
var stage_next_btn: Button = null
var stage_quick_buttons: Array[Button] = []

# Dolny Pasek Nawigacji (5 zakładek)
var bottom_nav_panel: PanelContainer = null
var base_overlay: Control = null
var base_logo: TextureRect = null
var base_logo_title: HBoxContainer = null
var base_left_actions: VBoxContainer = null
var base_right_actions: VBoxContainer = null
var nav_buttons: Array[Button] = []

# Modale: Skrzynka Odbiorcza oraz Ustawienia
var inbox_modal: ColorRect = null
var inbox_status_lbl: Label = null
var settings_modal: ColorRect = null

var idle_anim_time: float = 0.0
const DIFF_IDS := ["rekrut", "ocalaly", "weteran", "koszmar", "apokalipsa"]
const CLASS_IDS := ["soldier", "engineer", "medic", "scout"]
const SKIN_IDS := ["default", "gold_veteran", "neon_hunter", "crimson_storm", "hazmat_trooper", "void_sniper"]

func _ready() -> void:
	if legacy_top_bar:
		legacy_top_bar.visible = false
	if legacy_center:
		legacy_center.visible = false

	# Ustaw tło na wysokiej rozdzielczości grafikę żołnierza na tle płonącego miasta (bez zduplikowanych elementów UI)
	if is_instance_valid(bg_rect):
		bg_rect.texture = load("res://assets/ui/target_theme/bg_clean_soldier_ruins.png")
		bg_rect.modulate = Color.WHITE

	_build_commercial_hub_ui()
	_build_inbox_modal()
	_build_settings_modal()
	_polish_hub_visuals()
	_apply_approved_menu_style()

	if not StageDirector.orientation_changed.is_connected(_on_orientation_changed):
		StageDirector.orientation_changed.connect(_on_orientation_changed)
	if not StageDirector.profile_data_changed.is_connected(update_labels):
		StageDirector.profile_data_changed.connect(update_labels)

	_apply_responsive_menu_layout()
	switch_hub_tab(0)
	update_labels()

func _process(delta: float) -> void:
	idle_anim_time += delta
	if current_hub_tab == 0 and is_instance_valid(play_big_btn):
		var pulse := sin(idle_anim_time * 2.1) * 0.006
		play_big_btn.scale = Vector2(1.0 + pulse, 1.0 + pulse)
		play_big_btn.pivot_offset = play_big_btn.size * 0.5

func _polish_hub_visuals() -> void:
	# Reuse the accepted art and existing interactive navigation. Improve
	# hierarchy/contrast rather than covering the reference background with
	# extra decorative text or non-functional buttons.
	if is_instance_valid(top_hub_panel):
		var header := StyleBoxFlat.new()
		header.bg_color = Color(0.018, 0.035, 0.060, 0.94)
		header.border_color = Color(0.22, 0.72, 0.85, 0.78)
		header.border_width_bottom = 2
		header.set_corner_radius_all(12)
		header.set_content_margin_all(8)
		# Inner shadows keep text clear over the ruined city backdrop.
		header.shadow_color = Color(0, 0, 0, 0.45)
		header.shadow_size = 5
		top_hub_panel.add_theme_stylebox_override("panel", header)
	if is_instance_valid(bottom_nav_panel):
		var navigation := StyleBoxFlat.new()
		navigation.bg_color = Color(0.014, 0.030, 0.055, 0.97)
		navigation.border_color = Color(0.24, 0.70, 0.81, 0.74)
		navigation.border_width_top = 2
		navigation.set_corner_radius_all(11)
		navigation.set_content_margin_all(5)
		bottom_nav_panel.add_theme_stylebox_override("panel", navigation)
	if is_instance_valid(mission_description):
		mission_description.add_theme_font_size_override("font_size", 13)
		mission_description.add_theme_color_override("font_color", Color(0.92, 0.95, 0.99))
		mission_description.add_theme_color_override("font_outline_color", Color(0.015, 0.028, 0.045, 0.95))
		mission_description.add_theme_constant_override("outline_size", 2)
	if is_instance_valid(stage_title_lbl):
		stage_title_lbl.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04))
		stage_title_lbl.add_theme_constant_override("outline_size", 3)
	if is_instance_valid(play_big_btn):
		play_big_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		play_big_btn.focus_mode = Control.FOCUS_ALL
		play_big_btn.mouse_entered.connect(func(): play_big_btn.modulate = Color(1.08, 1.05, 0.96))
		play_big_btn.mouse_exited.connect(func(): play_big_btn.modulate = Color.WHITE)


func _apply_approved_menu_style() -> void:
	# Approved gameplay UI reference: live card/button controls, not a
	# flattened screenshot or painted-in fake currency values.
	if is_instance_valid(stage_card):
		var card := StyleBoxFlat.new()
		card.bg_color = Color(0.009, 0.035, 0.060, 0.98)
		card.border_color = Color(0.17, 0.80, 0.96)
		card.set_border_width_all(3)
		card.set_corner_radius_all(14)
		card.shadow_color = Color(0.0, 0.01, 0.03, 0.72)
		card.shadow_size = 8
		var approved_frame_path := "res://assets/ui/approved/mission_card_frame.svg"
		if ResourceLoader.exists(approved_frame_path, "Texture2D"):
			var frame := StyleBoxTexture.new()
			frame.texture = load(approved_frame_path) as Texture2D
			# Preserve the bevelled corners and hazard detail when the mission
			# card is resized from 420 to 720px portrait and to landscape.
			frame.texture_margin_left = 62.0
			frame.texture_margin_right = 62.0
			frame.texture_margin_top = 42.0
			frame.texture_margin_bottom = 42.0
			stage_card.add_theme_stylebox_override("panel", frame)
		else:
			stage_card.add_theme_stylebox_override("panel", card)
	if is_instance_valid(top_hub_panel):
		var bar := StyleBoxFlat.new()
		bar.bg_color = Color(0.012, 0.035, 0.059, 0.96)
		bar.border_color = Color(0.22, 0.76, 1.0, 0.86)
		bar.set_border_width_all(2)
		bar.set_corner_radius_all(11)
		top_hub_panel.add_theme_stylebox_override("panel", bar)
	if is_instance_valid(bottom_nav_panel):
		var bar := StyleBoxFlat.new()
		bar.bg_color = Color(0.009, 0.030, 0.055, 0.97)
		bar.border_color = Color(0.17, 0.76, 0.94, 0.90)
		bar.set_border_width_all(2)
		bar.set_corner_radius_all(10)
		bottom_nav_panel.add_theme_stylebox_override("panel", bar)
	if is_instance_valid(stage_title_lbl):
		stage_title_lbl.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	if is_instance_valid(stage_details_lbl):
		stage_details_lbl.add_theme_color_override("font_color", Color(0.55, 0.97, 0.16))


func _build_commercial_hub_ui() -> void:
	# --------------------------------------------------------------------------
	# 1. GÓRNY PASEK DOWÓDCY (Awatar + Lv:12 + Pasek XP | Kredyty | Kryształy | Próby | ⚙)
	# --------------------------------------------------------------------------
	top_hub_panel = PanelContainer.new()
	var top_st := StyleBoxFlat.new()
	top_st.bg_color = Color(0.01, 0.03, 0.06, 0.72)
	top_st.border_width_bottom = 2
	top_st.border_color = Color(0.18, 0.78, 0.95, 0.65)
	top_st.corner_radius_bottom_left = 14
	top_st.corner_radius_bottom_right = 14
	top_st.content_margin_left = 12
	top_st.content_margin_right = 12
	top_st.content_margin_top = 8
	top_st.content_margin_bottom = 8
	top_hub_panel.add_theme_stylebox_override("panel", SurvivorVisualSystem.panel(SurvivorVisualSystem.CYAN, true))
	top_hub_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(top_hub_panel)

	var top_h := HBoxContainer.new()
	top_hub_content = top_h
	top_h.add_theme_constant_override("separation", 12)
	top_h.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hub_panel.add_child(top_h)

	# Awatar gracza + Poziom + Pasek postępu XP
	var av_box := HBoxContainer.new()
	av_box.add_theme_constant_override("separation", 8)
	top_h.add_child(av_box)

	avatar_tex = TextureRect.new()
	avatar_tex.custom_minimum_size = Vector2(46, 46)
	avatar_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar_tex.texture = load("res://assets/ui/target_theme/avatar_hero.png")
	av_box.add_child(avatar_tex)

	var av_text_v := VBoxContainer.new()
	av_text_v.alignment = BoxContainer.ALIGNMENT_CENTER
	av_text_v.add_theme_constant_override("separation", 2)
	av_box.add_child(av_text_v)

	account_lvl_lbl = Label.new()
	account_lvl_lbl.add_theme_font_size_override("font_size", 14)
	account_lvl_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	account_lvl_lbl.text = "Lv:12"
	av_text_v.add_child(account_lvl_lbl)

	account_xp_bar = ProgressBar.new()
	account_xp_bar.custom_minimum_size = Vector2(72, 6)
	account_xp_bar.show_percentage = false
	account_xp_bar.max_value = 100.0
	account_xp_bar.value = 0.0
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.08, 0.16, 0.24, 0.9)
	xp_bg.corner_radius_top_left = 3
	xp_bg.corner_radius_top_right = 3
	xp_bg.corner_radius_bottom_left = 3
	xp_bg.corner_radius_bottom_right = 3
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.20, 0.85, 1.0, 1.0)
	xp_fill.corner_radius_top_left = 3
	xp_fill.corner_radius_top_right = 3
	xp_fill.corner_radius_bottom_left = 3
	xp_fill.corner_radius_bottom_right = 3
	account_xp_bar.add_theme_stylebox_override("background", xp_bg)
	account_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	av_text_v.add_child(account_xp_bar)

	# Spacer rozpychający
	var sp1 := Control.new()
	sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(sp1)

	# Waluta 1: Gwiazda / Kredyty
	var c_cred := HBoxContainer.new()
	c_cred.add_theme_constant_override("separation", 4)
	c_cred.alignment = BoxContainer.ALIGNMENT_CENTER
	top_h.add_child(c_cred)

	var star_icon := TextureRect.new()
	star_icon.custom_minimum_size = Vector2(24, 24)
	star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_icon.texture = load("res://assets/ui/target_theme/icon_star_coin.png")
	c_cred.add_child(star_icon)

	credits_lbl = Label.new()
	credits_lbl.add_theme_font_size_override("font_size", 15)
	credits_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	credits_lbl.text = "2 450"
	c_cred.add_child(credits_lbl)

	# Waluta 2: Fioletowy Kryształ
	var c_gem := HBoxContainer.new()
	c_gem.add_theme_constant_override("separation", 4)
	c_gem.alignment = BoxContainer.ALIGNMENT_CENTER
	top_h.add_child(c_gem)

	var gem_icon := TextureRect.new()
	gem_icon.custom_minimum_size = Vector2(24, 24)
	gem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gem_icon.texture = load("res://assets/ui/target_theme/icon_purple_crystal.png")
	c_gem.add_child(gem_icon)

	gems_lbl = Label.new()
	gems_lbl.add_theme_font_size_override("font_size", 15)
	gems_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	gems_lbl.text = "185"
	c_gem.add_child(gems_lbl)

	# Waluta 3: Próby (Niebieski kanister)
	var c_att := HBoxContainer.new()
	c_att.add_theme_constant_override("separation", 4)
	c_att.alignment = BoxContainer.ALIGNMENT_CENTER
	top_h.add_child(c_att)

	var flask_icon := TextureRect.new()
	flask_icon.custom_minimum_size = Vector2(24, 24)
	flask_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flask_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flask_icon.texture = load("res://assets/ui/target_theme/icon_energy_flask.png")
	c_att.add_child(flask_icon)

	attempts_lbl = Label.new()
	attempts_lbl.add_theme_font_size_override("font_size", 15)
	attempts_lbl.add_theme_color_override("font_color", Color(0.38, 0.94, 1.0))
	attempts_lbl.text = "5/5"
	c_att.add_child(attempts_lbl)

	# Spacer
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(4, 0)
	top_h.add_child(sp2)

	# Przycisk Ustawienia ⚙
	settings_btn = Button.new()
	settings_btn.custom_minimum_size = Vector2(36, 36)
	settings_btn.flat = true
	var set_tex := TextureRect.new()
	set_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_tex.texture = load("res://assets/ui/target_theme/icon_settings.png")
	settings_btn.add_child(set_tex)
	settings_btn.pressed.connect(func():
		StageDirector.play_sfx("ui_click")
		if is_instance_valid(settings_modal):
			settings_modal.visible = true
	)
	top_h.add_child(settings_btn)

	# Pływający przycisk Skrzynki Pocztowej 📬 pod awatarem
	inbox_btn = Button.new()
	inbox_btn.custom_minimum_size = Vector2(44, 44)
	inbox_btn.flat = true
	var mail_tex := TextureRect.new()
	mail_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mail_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mail_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mail_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mail_tex.texture = load("res://assets/ui/target_theme/icon_mail.png")
	inbox_btn.add_child(mail_tex)
	inbox_btn.pressed.connect(func():
		StageDirector.play_sfx("ui_click")
		if is_instance_valid(inbox_modal):
			inbox_modal.visible = true
	)
	add_child(inbox_btn)

	# --------------------------------------------------------------------------
	# 2. ŚRODKOWY OBSZAR HUBA
	# --------------------------------------------------------------------------
	middle_root = Control.new()
	middle_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(middle_root)

	base_scroll = ScrollContainer.new()
	base_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	base_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	middle_root.add_child(base_scroll)

	var base_margin := MarginContainer.new()
	base_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	base_margin.add_theme_constant_override("margin_left", 12)
	base_margin.add_theme_constant_override("margin_right", 12)
	base_margin.add_theme_constant_override("margin_top", 8)
	base_margin.add_theme_constant_override("margin_bottom", 8)
	base_scroll.add_child(base_margin)

	base_vbox = VBoxContainer.new()
	base_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	base_vbox.add_theme_constant_override("separation", 10)
	base_margin.add_child(base_vbox)

	_build_base_tab_content()

	# Wbudowany UserProfilePanel dla pozostałych zakładek
	user_profile_panel = UserProfilePanel.new()
	user_profile_panel.embedded_in_hub = true
	user_profile_panel.visible = false
	user_profile_panel.profile_updated.connect(update_labels)
	middle_root.add_child(user_profile_panel)
	user_profile_panel.set_embedded_mode(true)
	_build_base_overlays()

	# --------------------------------------------------------------------------
	# 3. DOLNY STAŁY PASEK NAWIGACJI (Baza | Postać | Ekwipunek | Kampania | Sklep)
	# --------------------------------------------------------------------------
	bottom_nav_panel = PanelContainer.new()
	var nav_box_st := StyleBoxFlat.new()
	nav_box_st.bg_color = Color(0.02, 0.05, 0.10, 0.95)
	nav_box_st.border_width_top = 2
	nav_box_st.border_color = Color(0.25, 0.85, 1.0, 0.85)
	nav_box_st.corner_radius_top_left = 12
	nav_box_st.corner_radius_top_right = 12
	nav_box_st.content_margin_left = 6
	nav_box_st.content_margin_right = 6
	nav_box_st.content_margin_top = 4
	nav_box_st.content_margin_bottom = 6
	bottom_nav_panel.add_theme_stylebox_override("panel", SurvivorVisualSystem.panel(SurvivorVisualSystem.LIME, true))
	add_child(bottom_nav_panel)

	var nav_hbox := HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_hbox.add_theme_constant_override("separation", 4)
	bottom_nav_panel.add_child(nav_hbox)

	var nav_defs := [
		{"id": 3, "name": "Kampania", "icon": "res://assets/ui/target_theme/nav_clean_kampania.svg"},
		{"id": 1, "name": "Postać", "icon": "res://assets/ui/target_theme/nav_clean_postac.svg"},
		{"id": 2, "name": "Ekwipunek", "icon": "res://assets/ui/target_theme/nav_clean_ekwipunek.svg"},
		{"id": 4, "name": "Sklep", "icon": "res://assets/ui/target_theme/nav_clean_sklep.svg"}
	]
	for nd in nav_defs:
		var tab_id: int = int(nd["id"])
		var tab_btn := Button.new()
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tab_btn.flat = false
		tab_btn.set_meta("hub_tab_id", tab_id)
		SurvivorVisualSystem.decorate_button(tab_btn, SurvivorVisualSystem.CYAN, 54.0)
		tab_btn.custom_minimum_size = Vector2(0, 56)
		# Bottom bar buttons are actual touch targets, not decorative art.

		var btn_v := VBoxContainer.new()
		btn_v.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn_v.add_theme_constant_override("separation", 0)
		tab_btn.add_child(btn_v)

		var ic_rect := TextureRect.new()
		ic_rect.custom_minimum_size = Vector2(28, 28)
		ic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_path: String = String(nd["icon"])
		if ResourceLoader.exists(icon_path):
			ic_rect.texture = load(icon_path) as Texture2D
		if ic_rect.texture == null:
			var fallback_icons: Array[String] = [
				"res://assets/ui/target_theme/nav_icon_baza.png",
				"res://assets/ui/target_theme/nav_icon_postac.png",
				"res://assets/ui/target_theme/nav_icon_ekwipunek.png",
				"res://assets/ui/target_theme/nav_icon_kampania.png",
				"res://assets/ui/target_theme/nav_icon_sklep.png"
			]
			ic_rect.texture = load(fallback_icons[tab_id]) as Texture2D
		btn_v.add_child(ic_rect)

		var lbl := Label.new()
		lbl.text = String(nd["name"]).to_upper()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_v.add_child(lbl)

		tab_btn.pressed.connect(func():
			StageDirector.play_sfx("ui_click")
			switch_hub_tab(tab_id)
		)
		nav_hbox.add_child(tab_btn)
		nav_buttons.append(tab_btn)

# Production overlays use real clickable Godot controls, never a flattened UI image.
# The illustration of the operator remains part of the clean background texture.
func _build_base_overlays() -> void:
	base_overlay = Control.new()
	base_overlay.name = "BaseProductionOverlay"
	base_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle_root.add_child(base_overlay)

	base_logo = TextureRect.new()
	base_logo.name = "MutantSurvivorLogo"
	base_logo.texture = load("res://assets/ui/target_theme/logo_reference_exact.png")
	base_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	base_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_overlay.add_child(base_logo)
	base_logo_title = HBoxContainer.new()
	base_logo_title.name = "BrandedLogoLetters"
	base_logo_title.alignment = BoxContainer.ALIGNMENT_CENTER
	base_logo_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base_logo_title.add_theme_constant_override("separation", 0)
	base_overlay.add_child(base_logo_title)
	base_logo_title.visible = false # New font-independent texture contains the metallic wordmark.
	for part in [
		{"text": "MUTANT", "color": Color(0.92, 0.95, 0.96)},
		{"text": "SURVIVOR", "color": SurvivorVisualSystem.LIME}
	]:
		var letter_label := Label.new()
		letter_label.text = String(part["text"])
		letter_label.add_theme_color_override("font_color", part["color"])
		letter_label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.02))
		letter_label.add_theme_constant_override("outline_size", 5)
		letter_label.add_theme_font_size_override("font_size", 37)
		letter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		base_logo_title.add_child(letter_label)

	base_left_actions = VBoxContainer.new()
	base_left_actions.name = "BaseLeftActions"
	base_left_actions.add_theme_constant_override("separation", 9)
	base_overlay.add_child(base_left_actions)
	base_right_actions = VBoxContainer.new()
	base_right_actions.name = "BaseRightActions"
	base_right_actions.add_theme_constant_override("separation", 9)
	base_overlay.add_child(base_right_actions)

	for item in [
		{"title": "POCZTA", "path": "res://assets/ui/target_theme/icon_mail.png", "tab": -2},
		{"title": "ZADANIA", "path": "res://assets/ui/approved/icon_daily_tasks.svg", "tab": -3},
		{"title": "PRZEPUSTKA", "path": "res://assets/ui/approved/icon_battle_pass.svg", "tab": -4}
	]:
		_add_base_action(base_left_actions, String(item["title"]), String(item["path"]), int(item["tab"]))
	_add_base_action(base_right_actions, "NAGRODY", "res://assets/ms_beta_kit/ui/icons/reward_chest.png", 5)
	_add_base_action(base_right_actions, "USTAWIENIA", "res://assets/ui/target_theme/icon_settings.png", -1)

func _add_base_action(parent: VBoxContainer, title: String, icon_path: String, destination: int) -> void:
	var action := Button.new()
	action.name = "Side" + title.capitalize()
	action.text = ""
	action.tooltip_text = title
	action.set_meta("full_label", title)
	action.custom_minimum_size = Vector2(76, 76)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SurvivorVisualSystem.decorate_metal_button(action, SurvivorVisualSystem.GOLD if destination == 5 else SurvivorVisualSystem.CYAN, 76.0)
	var action_content := VBoxContainer.new()
	action_content.name = "SideActionContent"
	action_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	action_content.alignment = BoxContainer.ALIGNMENT_CENTER
	action_content.add_theme_constant_override("separation", 2)
	action_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_child(action_content)
	var action_icon := TextureRect.new()
	action_icon.name = "SideActionIcon"
	action_icon.custom_minimum_size = Vector2(38, 40)
	action_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	action_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	action_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(icon_path):
		action_icon.texture = load(icon_path) as Texture2D
	action_content.add_child(action_icon)
	var action_caption := Label.new()
	action_caption.name = "SideActionCaption"
	action_caption.text = title
	action_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_caption.add_theme_font_size_override("font_size", 10)
	action_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_content.add_child(action_caption)
	action.pressed.connect(func():
		StageDirector.play_sfx("ui_click")
		if destination == -1:
			if is_instance_valid(settings_modal):
				settings_modal.visible = true
		elif destination == -2:
			if is_instance_valid(inbox_modal):
				inbox_modal.visible = true
		elif destination == -3:
			_open_rewards_shortcut("DailyMissionHeading")
		elif destination == -4:
			_open_rewards_shortcut("BattlePassHeading")
		else:
			switch_hub_tab(destination)
	)
	parent.add_child(action)

func _open_rewards_shortcut(focus_name: String) -> void:
	# The tasks/pass icons focus the corresponding live reward content.
	# Do not invent separate empty screens or silently grant rewards.
	switch_hub_tab(5)
	await get_tree().process_frame
	if not is_instance_valid(user_profile_panel):
		return
	var scroller := user_profile_panel.find_child("ProfileContentScroll", true, false) as ScrollContainer
	var section := user_profile_panel.find_child(focus_name, true, false) as Control
	if is_instance_valid(scroller) and is_instance_valid(section):
		scroller.ensure_control_visible(section)


func _build_base_tab_content() -> void:
	# W układzie portretowym (9:16) postać i miasto stanowią integralne tło w górnej połowie.
	# Przestrzeń w górnej części (spacer) pozwala podziwiać żołnierza na tle ruin.
	var hero_spacer := Control.new()
	hero_spacer.custom_minimum_size = Vector2(0, 220)
	hero_spacer_control = hero_spacer
	base_vbox.add_child(hero_spacer)

	# --------------------------------------------------------------------------
	# KARTA AKTUALNEGO ETAPU (Sci-Fi z obramowaniem cyjanowym card_stage_clean.png)
	# --------------------------------------------------------------------------
	stage_card = PanelContainer.new()
	stage_card.custom_minimum_size = Vector2(630, 315)
	var card_st := StyleBoxTexture.new()
	card_st.texture = load("res://assets/ui/target_theme/card_stage_clean.png")
	stage_card.add_theme_stylebox_override("panel", SurvivorVisualSystem.artwork_panel("res://assets/ui/target_theme/mission_frame_reference_clean.webp", SurvivorVisualSystem.LIME, true))
	base_vbox.add_child(stage_card)

	var card_margin := MarginContainer.new()
	card_margin.name = "MissionCardMargins"
	card_margin.add_theme_constant_override("margin_left", 30)
	card_margin.add_theme_constant_override("margin_right", 30)
	card_margin.add_theme_constant_override("margin_top", 14)
	card_margin.add_theme_constant_override("margin_bottom", 14)
	stage_card.add_child(card_margin)

	var stage_row := HBoxContainer.new()
	stage_row.name = "MissionStageRow"
	stage_row.add_theme_constant_override("separation", 12)
	card_margin.add_child(stage_row)
	stage_preview = TextureRect.new()
	stage_preview.name = "StageEnvironmentPreview"
	stage_preview.texture = load("res://assets/ui/target_theme/mission_wasteland_reference.webp")
	stage_preview.custom_minimum_size = Vector2(178, 225)
	stage_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_row.add_child(stage_preview)
	var st_vbox := VBoxContainer.new()
	st_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	st_vbox.add_theme_constant_override("separation", 6)
	stage_row.add_child(st_vbox)

	# Górny wiersz karty: ◀ ETAP 030 ▶
	var map_link := Button.new()
	map_link.name = "OpenCampaignMap"
	map_link.text = "KAMPANIA  •  MAPA 1–100"
	map_link.flat = true
	map_link.custom_minimum_size = Vector2(0, 30)
	map_link.add_theme_font_size_override("font_size", 16)
	map_link.add_theme_color_override("font_color", Color(1.0, 0.77, 0.28))
	map_link.pressed.connect(func(): switch_hub_tab(3))
	st_vbox.add_child(map_link)
	var title_h := HBoxContainer.new()
	title_h.name = "MissionTitleRow"
	title_h.alignment = BoxContainer.ALIGNMENT_CENTER
	title_h.add_theme_constant_override("separation", 16)
	st_vbox.add_child(title_h)

	stage_prev_btn = Button.new()
	stage_prev_btn.text = "◀"
	stage_prev_btn.flat = true
	stage_prev_btn.custom_minimum_size = Vector2(36, 36)
	stage_prev_btn.add_theme_font_size_override("font_size", 20)
	stage_prev_btn.add_theme_color_override("font_color", Color(0.38, 0.94, 1.0))
	stage_prev_btn.pressed.connect(func(): _jump_to_stage(StageDirector.current_stage - 1))
	title_h.add_child(stage_prev_btn)

	stage_title_lbl = Label.new()
	stage_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_title_lbl.clip_text = true
	stage_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_title_lbl.add_theme_font_size_override("font_size", 32)
	stage_title_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.045))
	stage_title_lbl.add_theme_constant_override("outline_size", 5)
	stage_title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	stage_title_lbl.text = "ETAP 030"
	title_h.add_child(stage_title_lbl)

	stage_next_btn = Button.new()
	stage_next_btn.text = "▶"
	stage_next_btn.flat = true
	stage_next_btn.custom_minimum_size = Vector2(36, 36)
	stage_next_btn.add_theme_font_size_override("font_size", 20)
	stage_next_btn.add_theme_color_override("font_color", Color(0.38, 0.94, 1.0))
	stage_next_btn.pressed.connect(func(): _jump_to_stage(StageDirector.current_stage + 1))
	title_h.add_child(stage_next_btn)

	# Podtytuł biomu: Krio Lab
	stage_details_lbl = Label.new()
	stage_details_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_details_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_details_lbl.custom_minimum_size.y = 34.0
	stage_details_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_details_lbl.clip_text = false
	stage_details_lbl.add_theme_font_size_override("font_size", 20)
	stage_details_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_details_lbl.add_theme_color_override("font_color", SurvivorVisualSystem.LIME)
	stage_details_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.07, 0.035))
	stage_details_lbl.add_theme_constant_override("outline_size", 3)
	stage_details_lbl.text = "Krio Lab"
	st_vbox.add_child(stage_details_lbl)
	mission_description = Label.new()
	mission_description.name = "MissionDescription"
	mission_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_description.add_theme_font_size_override("font_size", 12)
	mission_description.add_theme_color_override("font_color", Color(0.87, 0.92, 0.94))
	st_vbox.add_child(mission_description)

	# Zalecana moc
	var power_frame := PanelContainer.new()
	power_frame.name = "RecommendedPowerFrame"
	var power_style := SurvivorVisualSystem.button_style(SurvivorVisualSystem.LIME, "normal")
	power_style.bg_color = Color(0.025, 0.115, 0.065, 0.96)
	power_style.set_border_width_all(2)
	power_style.set_content_margin_all(6.0)
	power_frame.add_theme_stylebox_override("panel", power_style)
	power_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_vbox.add_child(power_frame)
	stage_pwr_lbl = Label.new()
	stage_pwr_lbl.name = "RecommendedPowerLabel"
	stage_pwr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_pwr_lbl.clip_text = true
	stage_pwr_lbl.add_theme_font_size_override("font_size", 15)
	stage_pwr_lbl.add_theme_color_override("font_color", SurvivorVisualSystem.LIME)
	stage_pwr_lbl.text = "ZALECANA MOC  590"
	power_frame.add_child(stage_pwr_lbl)

	# Odstęp
	var r_sp := Control.new()
	r_sp.custom_minimum_size = Vector2(0, 2)
	st_vbox.add_child(r_sp)

	# Wiersz 3 nagród etapu: Kryształ, Zębatka, XP
	var reward_heading := Label.new()
	reward_heading.name = "MissionRewardHeading"
	reward_heading.text = "NAGRODY ZA UKOŃCZENIE"
	reward_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_heading.clip_text = true
	reward_heading.add_theme_font_size_override("font_size", 12)
	reward_heading.add_theme_color_override("font_color", SurvivorVisualSystem.GOLD)
	st_vbox.add_child(reward_heading)
	var reward_frame := PanelContainer.new()
	reward_frame.name = "MissionRewardsFrame"
	var reward_style := StyleBoxFlat.new()
	reward_style.bg_color = Color(0.015, 0.065, 0.068, 0.95)
	reward_style.border_color = Color(0.44, 0.73, 0.18, 0.8)
	reward_style.border_width_bottom = 2
	reward_style.set_content_margin_all(6.0)
	reward_frame.add_theme_stylebox_override("panel", reward_style)
	st_vbox.add_child(reward_frame)
	stage_rewards_hbox = HBoxContainer.new()
	stage_rewards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_rewards_hbox.add_theme_constant_override("separation", 18)
	reward_frame.add_child(stage_rewards_hbox)

	var r_c := TextureRect.new()
	r_c.custom_minimum_size = Vector2(46, 42)
	r_c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r_c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_c.texture = load("res://assets/ui/target_theme/icon_star_coin.png")
	stage_rewards_hbox.add_child(r_c)

	var r_g := TextureRect.new()
	r_g.custom_minimum_size = Vector2(46, 42)
	r_g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r_g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_g.texture = load("res://assets/ui/target_theme/reward_cog.png")
	stage_rewards_hbox.add_child(r_g)

	var r_x := TextureRect.new()
	r_x.custom_minimum_size = Vector2(46, 42)
	r_x.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r_x.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_x.texture = load("res://assets/ui/target_theme/reward_xp.png")
	stage_rewards_hbox.add_child(r_x)

	# --------------------------------------------------------------------------
	# DUŻY ZŁOTY PRZYCISK „GRAJ ▶” (btn_play_gold_clean.png)
	# --------------------------------------------------------------------------
	play_big_btn = Button.new()
	play_big_btn.custom_minimum_size = Vector2(550, 100)
	play_big_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var play_tex_st := StyleBoxTexture.new()
	play_tex_st.texture = load("res://assets/ui/target_theme/btn_play_gold_clean.png")
	play_big_btn.add_theme_stylebox_override("normal", play_tex_st)
	play_big_btn.add_theme_stylebox_override("hover", play_tex_st)
	play_big_btn.add_theme_stylebox_override("pressed", play_tex_st)
	play_big_btn.add_theme_stylebox_override("disabled", SurvivorVisualSystem.button_style(SurvivorVisualSystem.GOLD, "disabled"))
	play_big_btn.add_theme_font_size_override("font_size", 25)
	play_big_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0))
	play_big_btn.text = "" # The gold artwork already contains GRAJ.
	play_big_btn.tooltip_text = "Rozpocznij misję"
	play_big_btn.pressed.connect(_on_play_pressed)
	base_vbox.add_child(play_big_btn)
	# Second main action matches the approved reference and opens a real campaign screen.
	var continue_btn := Button.new()
	continue_btn.name = "ContinueCampaignButton"
	continue_btn.text = "▶  KONTYNUUJ KAMPANIĘ"
	continue_btn.custom_minimum_size = Vector2(480, 60)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	SurvivorVisualSystem.decorate_metal_button(continue_btn, SurvivorVisualSystem.LIME, 60.0)
	continue_btn.add_theme_font_size_override("font_size", 19)
	continue_btn.pressed.connect(func(): switch_hub_tab(3))
	continue_btn.visible = false # Replaced by the mission card's real map link
	base_vbox.add_child(continue_btn)
	# Preserve the approved golden PLAY artwork while making the disabled state clear.

	# Pomocniczy wiersz opcji (dyskretny, przezroczysty sci-fi bez czarnych prostokątów)
	var aux_h := HBoxContainer.new()
	aux_h.alignment = BoxContainer.ALIGNMENT_CENTER
	aux_h.add_theme_constant_override("separation", 12)
	aux_h.visible = false # Practice and difficulty remain accessible in campaign
	base_vbox.add_child(aux_h)

	var opt_st := StyleBoxFlat.new()
	opt_st.bg_color = Color(0.03, 0.08, 0.16, 0.65)
	opt_st.border_width_left = 1
	opt_st.border_width_top = 1
	opt_st.border_width_right = 1
	opt_st.border_width_bottom = 1
	opt_st.border_color = Color(0.20, 0.85, 1.0, 0.70)
	opt_st.corner_radius_top_left = 8
	opt_st.corner_radius_top_right = 8
	opt_st.corner_radius_bottom_left = 8
	opt_st.corner_radius_bottom_right = 8
	opt_st.content_margin_left = 10
	opt_st.content_margin_right = 10
	opt_st.content_margin_top = 4
	opt_st.content_margin_bottom = 4

	practice_btn = Button.new()
	practice_btn.custom_minimum_size = Vector2(170, 32)
	practice_btn.add_theme_stylebox_override("normal", opt_st)
	practice_btn.add_theme_stylebox_override("hover", opt_st)
	practice_btn.add_theme_font_size_override("font_size", 11)
	practice_btn.pressed.connect(_on_practice_pressed)
	aux_h.add_child(practice_btn)

	diff_btn = Button.new()
	diff_btn.custom_minimum_size = Vector2(130, 32)
	diff_btn.add_theme_stylebox_override("normal", opt_st)
	diff_btn.add_theme_stylebox_override("hover", opt_st)
	diff_btn.add_theme_font_size_override("font_size", 11)
	diff_btn.pressed.connect(_on_diff_pressed)
	aux_h.add_child(diff_btn)

	orient_btn = Button.new()
	orient_btn.text = "📱 9:16"
	orient_btn.custom_minimum_size = Vector2(76, 32)
	orient_btn.add_theme_stylebox_override("normal", opt_st)
	orient_btn.add_theme_stylebox_override("hover", opt_st)
	orient_btn.add_theme_font_size_override("font_size", 11)
	orient_btn.pressed.connect(func():
		StageDirector.play_sfx("ui_click")
		StageDirector.toggle_orientation_mode()
	)
	aux_h.add_child(orient_btn)

	# Narzędzia deweloperskie (ukryte w normalnym interfejsie gracza, oddzielone)
	stage_quick_buttons.clear()
	for s_id in [1, 30, 60, 100]:
		var target_stage: int = int(s_id)
		var sb := Button.new()
		sb.set_meta("target_stage", target_stage)
		sb.pressed.connect(func(): _jump_to_stage(target_stage))
		stage_quick_buttons.append(sb)

	# A compact roadmap fills the formerly empty lower half with real progress,
	# without adding fake rewards or another store widget.
	var progress_gap := Control.new()
	progress_gap.custom_minimum_size = Vector2(0, 8)
	base_vbox.add_child(progress_gap)
	var progress_card := PanelContainer.new()
	progress_card.name = "CampaignProgressCard"
	progress_card.custom_minimum_size = Vector2(0, 144)
	progress_card.visible = false # 100-stage detail belongs in the campaign screen
	var progress_style := StyleBoxFlat.new()
	progress_style.bg_color = Color(0.025, 0.055, 0.09, 0.92)
	progress_style.border_color = Color(0.12, 0.56, 0.74, 0.76)
	progress_style.set_border_width_all(1)
	progress_style.set_corner_radius_all(10)
	progress_style.set_content_margin_all(12.0)
	progress_card.add_theme_stylebox_override("panel", progress_style)
	base_vbox.add_child(progress_card)
	progress_card.add_theme_stylebox_override("panel", SurvivorVisualSystem.metal_panel(SurvivorVisualSystem.LIME))
	var progress_col := VBoxContainer.new()
	progress_col.add_theme_constant_override("separation", 8)
	progress_card.add_child(progress_col)
	campaign_progress_label = Label.new()
	campaign_progress_label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	campaign_progress_label.add_theme_font_size_override("font_size", 14)
	progress_col.add_child(campaign_progress_label)
	campaign_progress_bar = ProgressBar.new()
	campaign_progress_bar.custom_minimum_size = Vector2(0, 9)
	campaign_progress_bar.max_value = 100
	campaign_progress_bar.show_percentage = false
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color(0.17, 0.84, 0.82)
	progress_fill.set_corner_radius_all(4)
	campaign_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	progress_col.add_child(campaign_progress_bar)
	# Release home roadmap: visible real stage milestones, not an empty plate.
	var milestone_row := HBoxContainer.new()
	milestone_row.name = "CampaignMilestones"
	milestone_row.add_theme_constant_override("separation", 6)
	progress_col.add_child(milestone_row)
	for milestone in [1, 25, 50, 75, 100]:
		var milestone_label := Label.new()
		milestone_label.name = "Milestone_%03d" % milestone
		milestone_label.text = "%03d" % milestone
		milestone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		milestone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		milestone_label.add_theme_font_size_override("font_size", 13)
		milestone_label.add_theme_color_override("font_color", SurvivorVisualSystem.MUTED)
		milestone_row.add_child(milestone_label)
		campaign_milestone_labels.append(milestone_label)
	var progress_hint := Label.new()
	progress_hint.name = "CampaignProgressHint"
	progress_hint.text = "Pokonuj etapy, aby odblokować kolejne rozdziały"
	progress_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_hint.add_theme_font_size_override("font_size", 11)
	progress_hint.add_theme_color_override("font_color", SurvivorVisualSystem.TEXT)
	progress_col.add_child(progress_hint)

	# Real-player quick actions fill the former empty hub area.
	var quick_card := PanelContainer.new()
	quick_card.name = "OperatorQuickActions"
	quick_card.add_theme_stylebox_override("panel", SurvivorVisualSystem.panel(SurvivorVisualSystem.GOLD, false))
	quick_card.custom_minimum_size = Vector2(0, 100)
	quick_card.visible = false # Remove duplicate links from home composition
	base_vbox.add_child(quick_card)
	var quick_content := VBoxContainer.new()
	quick_content.add_theme_constant_override("separation", 8)
	quick_card.add_child(quick_content)
	var quick_heading := Label.new()
	quick_heading.text = "CENTRUM OPERACYJNE"
	SurvivorVisualSystem.decorate_section(quick_heading, SurvivorVisualSystem.GOLD, 17)
	quick_content.add_child(quick_heading)
	base_power_label = Label.new()
	base_power_label.add_theme_font_size_override("font_size", 14)
	base_power_label.add_theme_color_override("font_color", SurvivorVisualSystem.TEXT)
	quick_content.add_child(base_power_label)
	var quick_buttons := HBoxContainer.new()
	quick_buttons.add_theme_constant_override("separation", 8)
	quick_content.add_child(quick_buttons)
	for entry in [
		{"text": "KAMPANIA", "tab": 3, "color": SurvivorVisualSystem.LIME},
		{"text": "NAGRODY", "tab": 5, "color": SurvivorVisualSystem.GOLD},
		{"text": "EKWIPUNEK", "tab": 2, "color": SurvivorVisualSystem.CYAN}
	]:
		var shortcut := Button.new()
		shortcut.text = String(entry["text"])
		shortcut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		SurvivorVisualSystem.decorate_button(shortcut, entry["color"], 48.0)
		var destination: int = int(entry["tab"])
		shortcut.pressed.connect(func(): switch_hub_tab(destination))
		quick_buttons.add_child(shortcut)

	# Dolny odstęp aby treść nie chowała się pod paskiem nawigacji
	var bot_sp := Control.new()
	bot_sp.custom_minimum_size = Vector2(0, 22)
	base_vbox.add_child(bot_sp)

func _jump_to_stage(s_num: int) -> void:
	StageDirector.play_sfx("ui_click")
	StageDirector.current_stage = clampi(s_num, 1, StageDirector.max_unlocked_stage)
	StageDirector.save_campaign_profile()
	update_labels()

func switch_hub_tab(tab_id: int) -> void:
	current_hub_tab = tab_id
	for i in range(nav_buttons.size()):
		var nb: Button = nav_buttons[i]
		var destination: int = int(nb.get_meta("hub_tab_id", -1))
		var active := destination == current_hub_tab or (current_hub_tab == 0 and destination == 3)
		SurvivorVisualSystem.decorate_button(nb, SurvivorVisualSystem.LIME if active else SurvivorVisualSystem.CYAN, 58.0)
		if active:
			nb.add_theme_stylebox_override("normal", SurvivorVisualSystem.button_style(SurvivorVisualSystem.LIME, "hover"))
			nb.add_theme_stylebox_override("hover", SurvivorVisualSystem.button_style(SurvivorVisualSystem.LIME, "hover"))
		nb.modulate = Color.WHITE if active else Color(0.86, 0.91, 0.94, 1.0)
		if nb.get_child_count() > 0:
			var v := nb.get_child(0) as VBoxContainer
			if is_instance_valid(v) and v.get_child_count() >= 2:
				var lbl := v.get_child(1) as Label
				if is_instance_valid(lbl):
					lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0) if active else Color(0.65, 0.75, 0.85))
				var icon_rect := v.get_child(0) as TextureRect
				if is_instance_valid(icon_rect):
					icon_rect.modulate = SurvivorVisualSystem.LIME if active else Color(0.80, 0.86, 0.89)

	if is_instance_valid(base_overlay):
		base_overlay.visible = current_hub_tab == 0
	if current_hub_tab == 0:
		base_scroll.visible = true
		user_profile_panel.visible = false
		base_vbox.modulate = Color(1, 1, 1, 0.0)
		var tw := create_tween()
		tw.tween_property(base_vbox, "modulate:a", 1.0, 0.14)
	else:
		base_scroll.visible = false
		user_profile_panel.visible = true
		var target_subtab := current_hub_tab - 1 # 1->0(Postać), 2->1(Ekwipunek), 3->2(Kampania), 4->3(Sklep), 5->4(Nagrody)
		user_profile_panel.open_panel(target_subtab)
		user_profile_panel.modulate = Color(1, 1, 1, 0.0)
		var tw2 := create_tween()
		tw2.tween_property(user_profile_panel, "modulate:a", 1.0, 0.14)
	update_labels()

func _build_inbox_modal() -> void:
	inbox_modal = ColorRect.new()
	inbox_modal.visible = false
	inbox_modal.color = Color(0.02, 0.04, 0.08, 0.88)
	inbox_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(inbox_modal)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inbox_modal.add_child(center)

	var card := _make_card(Color(0.28, 0.92, 1.0, 0.95))
	card.custom_minimum_size = Vector2(480, 260)
	center.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)

	var t := Label.new()
	t.text = "📬 SKRZYNKA ODBIORCZA DOWÓDZTWA A-03"
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	v.add_child(t)

	var msg := Label.new()
	msg.text = (
		"1. [DOWÓDCA MARA]: Witaj w Kompleksie A-03! Przygotowaliśmy zrzut zaopatrzeniowy dla Twojego oddziału.\n" +
		"2. [RAPORT TECHNICZNY IWO]: Wszystkie 6 slotów pancerza i losowe afiksy są aktywne. Pamiętaj o codziennym pakiecie w Sklepie!"
	)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 12)
	v.add_child(msg)

	inbox_status_lbl = Label.new()
	inbox_status_lbl.add_theme_font_size_override("font_size", 12)
	inbox_status_lbl.add_theme_color_override("font_color", Color(0.42, 1.0, 0.65))
	v.add_child(inbox_status_lbl)

	var claim_btn := Button.new()
	claim_btn.custom_minimum_size = Vector2(0, 38)
	claim_btn.text = "🎁 ODBIERZ ZRZUT POWITALNY (+250 Kr, +40 💎, +5 Złomu)"
	claim_btn.pressed.connect(func():
		if not bool(StageDirector.inbox_claimed.get("welcome_drop", false)):
			StageDirector.inbox_claimed["welcome_drop"] = true
			StageDirector.credits += 250
			StageDirector.dark_matter_gems += 40
			StageDirector.scrap_materials += 5
			StageDirector.play_sfx("victory")
			StageDirector.save_campaign_profile()
			update_labels()
	)
	v.add_child(claim_btn)

	var close_b := Button.new()
	close_b.text = "✕ ZAMKNIJ"
	close_b.custom_minimum_size = Vector2(0, 36)
	close_b.pressed.connect(func(): inbox_modal.visible = false)
	v.add_child(close_b)

func _build_settings_modal() -> void:
	settings_modal = ColorRect.new()
	settings_modal.visible = false
	settings_modal.color = Color(0.02, 0.04, 0.08, 0.88)
	settings_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(settings_modal)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_modal.add_child(center)

	var card := _make_card(Color(0.28, 0.92, 1.0, 0.95))
	card.name = "SettingsCard"
	card.custom_minimum_size = Vector2(460, 380)
	center.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)

	var t := Label.new()
	t.name = "SettingsTitle"
	t.text = "⚙ USTAWIENIA SYSTEMOWE, AUDIO I JĘZYK"
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color(0.35, 0.96, 1.0))
	v.add_child(t)

	v.add_child(_create_volume_slider_row("🎵 Głośność Muzyki", StageDirector.vol_music, func(val: float):
		StageDirector.vol_music = val
		StageDirector.save_campaign_profile()
	))
	v.add_child(_create_volume_slider_row("💥 Głośność Efektów (SFX)", StageDirector.vol_sfx, func(val: float):
		StageDirector.vol_sfx = val
		StageDirector.play_sfx("shoot")
		StageDirector.save_campaign_profile()
	))
	v.add_child(_create_volume_slider_row("🔘 Dźwięki Interfejsu (UI)", StageDirector.vol_ui, func(val: float):
		StageDirector.vol_ui = val
		StageDirector.play_sfx("ui_click")
		StageDirector.save_campaign_profile()
	))

	var lang_h := HBoxContainer.new()
	lang_h.name = "SettingsLanguageRow"
	lang_h.add_theme_constant_override("separation", 6)
	v.add_child(lang_h)
	var lang_l := Label.new()
	lang_l.name = "SettingsLanguageLabel"
	lang_l.text = "🌐 Język / Language:"
	lang_l.custom_minimum_size = Vector2(150, 0)
	lang_l.add_theme_font_size_override("font_size", 12)
	lang_h.add_child(lang_l)

	for l_def in [{"id": "pl", "name": "Polski"}, {"id": "en", "name": "English"}, {"id": "de", "name": "Deutsch"}]:
		var lid: String = String(l_def["id"])
		var lb := Button.new()
		lb.name = "SettingsLanguage_" + lid
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.custom_minimum_size = Vector2(0, 44)
		lb.text = String(l_def["name"])
		lb.pressed.connect(func():
			StageDirector.set_language(lid)
			StageDirector.play_sfx("ui_click")
			update_labels()
		)
		lang_h.add_child(lb)

	var net_btn := Button.new()
	net_btn.name = "SettingsNetworkButton"
	net_btn.custom_minimum_size = Vector2(0, 44)
	net_btn.text = "📶 Połączenie: włączone (funkcje testowe)"
	net_btn.pressed.connect(func():
		StageDirector.is_online_mode = not StageDirector.is_online_mode
		net_btn.text = "📶 Połączenie: włączone (funkcje testowe)" if StageDirector.is_online_mode else "📴 Połączenie: wyłączone (kampania offline)"
	)
	v.add_child(net_btn)

	var close_b := Button.new()
	close_b.name = "SettingsCloseButton"
	close_b.text = "✕ ZAMKNIJ USTAWIENIA"
	close_b.custom_minimum_size = Vector2(0, 48)
	close_b.pressed.connect(func(): settings_modal.visible = false)
	v.add_child(close_b)

func _create_volume_slider_row(label_txt: String, init_val: float, cb: Callable) -> Control:
	var h := HBoxContainer.new()
	h.name = "SettingsVolumeRow"
	h.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.name = "SettingsVolumeLabel"
	l.text = label_txt
	l.custom_minimum_size = Vector2(175, 0)
	l.add_theme_font_size_override("font_size", 12)
	h.add_child(l)

	var slider := HSlider.new()
	slider.name = "SettingsVolumeSlider"
	slider.custom_minimum_size.x = 112.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = init_val
	slider.value_changed.connect(cb)
	h.add_child(slider)
	return h

func _make_card(border_col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.09, 0.16, 0.94)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 2
	st.border_color = border_col
	st.corner_radius_top_left = 12
	st.corner_radius_top_right = 12
	st.corner_radius_bottom_left = 12
	st.corner_radius_bottom_right = 12
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", st)
	return p

func _on_orientation_changed(_is_portrait: bool) -> void:
	_apply_responsive_menu_layout()
	update_labels()

func _apply_responsive_menu_layout() -> void:
	var portrait := StageDirector.is_portrait_mode()
	var safe_top := StageDirector.get_safe_top_margin()
	# Use the smaller of actual viewport and resized root canvas. The 420px
	# QA path resizes the Control while Godot can keep a 720px root viewport.
	var compact_hub := portrait and minf(size.x, get_viewport_rect().size.x) < 600.0

	# Settings were previously a fixed 460px card and clipped on 420px phones.
	# Resize actual controls on every orientation/viewport change.
	var settings_card := find_child("SettingsCard", true, false) as PanelContainer
	if is_instance_valid(settings_card):
		var available_settings_width := maxf(280.0, minf(size.x, get_viewport_rect().size.x) - (24.0 if portrait else 48.0))
		settings_card.custom_minimum_size = Vector2(minf(460.0, available_settings_width), 380.0)
		var settings_title := settings_card.find_child("SettingsTitle", true, false) as Label
		if is_instance_valid(settings_title):
			settings_title.text = "USTAWIENIA • AUDIO / JĘZYK" if compact_hub else "⚙ USTAWIENIA SYSTEMOWE, AUDIO I JĘZYK"
			settings_title.add_theme_font_size_override("font_size", 13 if compact_hub else 16)
		for volume_row in settings_card.get_child(0).get_children():
			if not (volume_row is HBoxContainer):
				continue
			volume_row.add_theme_constant_override("separation", 6 if compact_hub else 8)
			var volume_label := volume_row.find_child("SettingsVolumeLabel", false, false) as Label
			if is_instance_valid(volume_label):
				volume_label.custom_minimum_size.x = 104.0 if compact_hub else 175.0
				volume_label.add_theme_font_size_override("font_size", 10 if compact_hub else 12)
			var volume_slider := volume_row.find_child("SettingsVolumeSlider", false, false) as HSlider
			if is_instance_valid(volume_slider):
				volume_slider.custom_minimum_size.x = 118.0 if compact_hub else 155.0
		var language_row := settings_card.find_child("SettingsLanguageRow", true, false) as HBoxContainer
		if is_instance_valid(language_row):
			language_row.add_theme_constant_override("separation", 3 if compact_hub else 6)
			for language_button in language_row.get_children():
				if language_button is Button:
					(language_button as Button).add_theme_font_size_override("font_size", 10 if compact_hub else 12)
			var language_label := language_row.find_child("SettingsLanguageLabel", false, false) as Label
			if is_instance_valid(language_label):
				language_label.text = "JĘZYK:" if compact_hub else "🌐 Język / Language:"
				language_label.custom_minimum_size.x = 52.0 if compact_hub else 150.0
				language_label.add_theme_font_size_override("font_size", 10 if compact_hub else 12)
		var network_button := settings_card.find_child("SettingsNetworkButton", true, false) as Button
		if is_instance_valid(network_button):
			network_button.add_theme_font_size_override("font_size", 11 if compact_hub else 12)
			network_button.text = ("📶 ONLINE (TEST)" if StageDirector.is_online_mode else "📴 OFFLINE") if compact_hub else ("📶 Połączenie: włączone (funkcje testowe)" if StageDirector.is_online_mode else "📴 Połączenie: wyłączone (kampania offline)")
		var settings_close := settings_card.find_child("SettingsCloseButton", true, false) as Button
		if is_instance_valid(settings_close):
			settings_close.add_theme_font_size_override("font_size", 12 if compact_hub else 14)

	# On phones around 420px, the normal 720px header cannot physically
	# contain the portrait, three wallets and settings at full desktop scale.
	if is_instance_valid(top_hub_content):
		top_hub_content.add_theme_constant_override("separation", 2 if compact_hub else 15)
		for row_child in top_hub_content.get_children():
			if row_child is HBoxContainer:
				row_child.add_theme_constant_override("separation", 2 if compact_hub else 8)
				for element in row_child.get_children():
					if element is TextureRect:
						element.custom_minimum_size = Vector2(15, 15) if compact_hub else Vector2(31, 31)
					elif element is Label:
						element.add_theme_font_size_override("font_size", 10 if compact_hub else 21)
	if is_instance_valid(avatar_tex):
		avatar_tex.custom_minimum_size = Vector2(32, 32) if compact_hub else Vector2(60, 60)
	if is_instance_valid(account_xp_bar):
		account_xp_bar.custom_minimum_size = Vector2(42, 7) if compact_hub else Vector2(106, 10)
	if is_instance_valid(account_lvl_lbl):
		account_lvl_lbl.add_theme_font_size_override("font_size", 12 if compact_hub else 21)
	if is_instance_valid(settings_btn):
		settings_btn.custom_minimum_size = Vector2(28, 34) if compact_hub else Vector2(50, 50)
	for nav_btn in nav_buttons:
		var nav_content := nav_btn.get_child(0) as VBoxContainer
		if is_instance_valid(nav_content):
			for nav_child in nav_content.get_children():
				if nav_child is TextureRect:
					nav_child.custom_minimum_size = Vector2(26, 28) if compact_hub else Vector2(47, 51)
				elif nav_child is Label:
					nav_child.add_theme_font_size_override("font_size", 10 if compact_hub else 17)

	if is_instance_valid(top_hub_panel):
		top_hub_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
		top_hub_panel.offset_left = 10.0 if portrait else 24.0
		top_hub_panel.offset_top = 8.0 + safe_top
		top_hub_panel.offset_right = -10.0 if portrait else -24.0
		top_hub_panel.offset_bottom = (68.0 if compact_hub else 90.0) + safe_top

	# Four real routes remain visible on every device. Home and the campaign
	# screen share the Campaign active state; no duplicate hidden navigation.
	if is_instance_valid(inbox_btn):
		# The approved portrait already has POCZTA in left-side navigation.
		# Hide the duplicate floating envelope without removing its callback.
		inbox_btn.visible = not portrait
		inbox_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		inbox_btn.offset_left = 22.0 if portrait else 28.0
		inbox_btn.offset_top = 85.0 + safe_top
		inbox_btn.offset_right = 70.0 if portrait else 76.0
		inbox_btn.offset_bottom = 133.0 + safe_top

	if is_instance_valid(bottom_nav_panel):
		bottom_nav_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bottom_nav_panel.offset_left = 12.0 if portrait else 28.0
		bottom_nav_panel.offset_top = (-78.0 if compact_hub else -114.0) if portrait else -82.0
		bottom_nav_panel.offset_right = -12.0 if portrait else -28.0
		bottom_nav_panel.offset_bottom = -10.0 if portrait else -4.0

	if is_instance_valid(middle_root):
		middle_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		middle_root.offset_left = 0.0
		middle_root.offset_top = (72.0 if compact_hub else 95.0) + safe_top
		middle_root.offset_right = 0.0
		middle_root.offset_bottom = (-84.0 if compact_hub else -100.0) if portrait else -88.0

	if is_instance_valid(base_overlay):
		base_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if is_instance_valid(base_logo):
		base_logo.set_anchors_preset(Control.PRESET_TOP_WIDE)
		base_logo.offset_left = 32.0 if compact_hub else 50.0
		base_logo.offset_right = -32.0 if compact_hub else -50.0
		base_logo.offset_top = 0.0
		base_logo.offset_bottom = 72.0 if compact_hub else 90.0
	if is_instance_valid(base_logo_title):
		base_logo_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
		base_logo_title.offset_left = 0.0
		base_logo_title.offset_right = 0.0
		base_logo_title.offset_top = 20.0
		base_logo_title.offset_bottom = 94.0
		for label in base_logo_title.get_children():
			if label is Label:
				label.add_theme_font_size_override("font_size", 21 if compact_hub else (43 if portrait else 47))
	for side_index in range(2):
		var actions: VBoxContainer = base_left_actions if side_index == 0 else base_right_actions
		if not is_instance_valid(actions):
			continue
		var left_side: bool = side_index == 0
		actions.set_anchors_preset(Control.PRESET_TOP_LEFT if left_side else Control.PRESET_TOP_RIGHT)
		actions.offset_left = 8.0 if left_side else (-62.0 if compact_hub else -94.0)
		actions.offset_right = (62.0 if compact_hub else 94.0) if left_side else -8.0
		actions.offset_top = 65.0
		actions.offset_bottom = 65.0 + (3 if left_side else 2) * (69 if compact_hub else 109)
		for btn in actions.get_children():
			if btn is Button:
				btn.custom_minimum_size = Vector2(0, 66.0 if compact_hub else 96.0)
				btn.text = ""
				btn.tooltip_text = String(btn.get_meta("full_label", btn.name.trim_prefix("Side").to_upper()))
				var action_content := btn.get_node_or_null("SideActionContent") as VBoxContainer
				if is_instance_valid(action_content):
					var caption := action_content.get_node_or_null("SideActionCaption") as Label
					var icon_rect := action_content.get_node_or_null("SideActionIcon") as TextureRect
					if is_instance_valid(caption):
						caption.add_theme_font_size_override("font_size", 9 if compact_hub else 14)
					if is_instance_valid(icon_rect):
						icon_rect.custom_minimum_size = Vector2(30, 34) if compact_hub else Vector2(51, 53)

	# Keep the main call to action and stage card inside the actual hub content
	# on smaller devices; do not depend on the nominal 720px design viewport.
	var available_width := maxf(180.0, minf(size.x, get_viewport_rect().size.x) - (44.0 if portrait else 110.0))
	if is_instance_valid(stage_card):
		stage_card.custom_minimum_size = Vector2(minf(640.0 if portrait else 680.0, available_width), (218.0 if compact_hub else 342.0) if portrait else 330.0)
	# Compress intrinsic child minimum widths before the 420px screenshot:
	# a wide title/navigation row used to force the whole card to 480px.
	# Compact home must show its single primary CTA without sacrificing the
	# campaign card to an offscreen scroll region on 420px devices.
	if is_instance_valid(base_vbox):
		base_vbox.add_theme_constant_override("separation", 5 if compact_hub else 10)
	if is_instance_valid(stage_card):
		var margins := stage_card.get_node_or_null("MissionCardMargins") as MarginContainer
		if is_instance_valid(margins):
			for direction in ["left", "right"]:
				margins.add_theme_constant_override("margin_" + direction, 8 if compact_hub else 30)
			margins.add_theme_constant_override("margin_top", 8 if compact_hub else 25)
			margins.add_theme_constant_override("margin_bottom", 8 if compact_hub else 25)
		var stage_layout := stage_card.find_child("MissionStageRow", true, false) as HBoxContainer
		if is_instance_valid(stage_layout):
			stage_layout.add_theme_constant_override("separation", 2 if compact_hub else 18)
		var title_layout := stage_card.find_child("MissionTitleRow", true, false) as HBoxContainer
		if is_instance_valid(title_layout):
			title_layout.add_theme_constant_override("separation", 2 if compact_hub else 16)
		for direction_btn in [stage_prev_btn, stage_next_btn]:
			if is_instance_valid(direction_btn):
				direction_btn.custom_minimum_size = Vector2(26, 30) if compact_hub else Vector2(36, 36)
		var power_lbl := stage_card.find_child("RecommendedPowerLabel", true, false) as Label
		if is_instance_valid(power_lbl):
			power_lbl.add_theme_font_size_override("font_size", 11 if compact_hub else 15)
		var reward_heading_label := stage_card.find_child("MissionRewardHeading", true, false) as Label
		if is_instance_valid(reward_heading_label):
			reward_heading_label.add_theme_font_size_override("font_size", 10 if compact_hub else 12)
		var stage_row := stage_card.find_child("MissionStageRow", true, false) as HBoxContainer
		if is_instance_valid(stage_row) and stage_row.get_child_count() > 1:
			var content_col := stage_row.get_child(1) as VBoxContainer
			if is_instance_valid(content_col):
				content_col.add_theme_constant_override("separation", 2 if compact_hub else 6)
		if is_instance_valid(stage_rewards_hbox):
			stage_rewards_hbox.add_theme_constant_override("separation", 3 if compact_hub else 14)
			for reward_icon in stage_rewards_hbox.get_children():
				if reward_icon is TextureRect:
					reward_icon.custom_minimum_size = Vector2(24, 25) if compact_hub else Vector2(46, 42)
	var map_link_btn := stage_card.find_child("OpenCampaignMap", true, false) as Button
	if is_instance_valid(map_link_btn):
		map_link_btn.text = "KAMPANIA" if compact_hub else "KAMPANIA  •  MAPA 1–100"
		map_link_btn.add_theme_font_size_override("font_size", 10 if compact_hub else 16)
		map_link_btn.custom_minimum_size.y = 20.0 if compact_hub else 30.0
	if is_instance_valid(mission_description):
		mission_description.add_theme_font_size_override("font_size", 10 if compact_hub else 17)
	if is_instance_valid(stage_preview):
		stage_preview.visible = true
		stage_preview.custom_minimum_size = Vector2(82, 138) if compact_hub else (Vector2(165, 212) if portrait else Vector2(175, 180))
	if is_instance_valid(play_big_btn):
		play_big_btn.custom_minimum_size = Vector2(minf(630.0 if portrait else 600.0, available_width), (70.0 if compact_hub else 118.0) if portrait else 100.0)
	var campaign_continue := base_vbox.get_node_or_null("ContinueCampaignButton") as Button
	if is_instance_valid(campaign_continue):
		campaign_continue.custom_minimum_size = Vector2(minf(480.0, available_width), 50.0 if compact_hub else 60.0)
		campaign_continue.add_theme_font_size_override("font_size", 13 if compact_hub else 19)
	if is_instance_valid(play_big_btn):
		play_big_btn.text = "" if ResourceLoader.exists("res://assets/ui/target_theme/btn_play_gold_clean.png") else "GRAJ"
	if is_instance_valid(hero_spacer_control):
		hero_spacer_control.custom_minimum_size = Vector2(0, (clampf(minf(size.y, get_viewport_rect().size.y) * 0.22, 157.0, 190.0) if compact_hub else 438.0) if portrait else 145.0)
	if is_instance_valid(stage_title_lbl):
		stage_title_lbl.add_theme_font_size_override("font_size", 18 if compact_hub else (35 if portrait else 33))
	if is_instance_valid(stage_details_lbl):
		stage_details_lbl.add_theme_font_size_override("font_size", 13 if compact_hub else (22 if portrait else 25))
		stage_details_lbl.custom_minimum_size.y = 18.0 if compact_hub else 36.0
	if is_instance_valid(orient_btn):
		orient_btn.text = "9:16" if portrait else "16:9"

func update_labels() -> void:
	StageDirector.refresh_attempts()
	var cfg := StageDirector.get_stage_config(StageDirector.current_stage)
	var diff := StageDirector.get_difficulty_profile()

	# Górny Pasek
	if is_instance_valid(account_lvl_lbl):
		account_lvl_lbl.text = "Lv:%d" % StageDirector.character_level
	if is_instance_valid(account_xp_bar):
		# StageDirector stores XP within the current account level.
		var xp_needed := StageDirector.get_character_xp_needed(StageDirector.character_level)
		account_xp_bar.max_value = float(maxi(1, xp_needed))
		account_xp_bar.value = float(clampi(StageDirector.character_xp, 0, xp_needed))
		account_xp_bar.tooltip_text = "XP: %d / %d" % [StageDirector.character_xp, xp_needed]
	if is_instance_valid(credits_lbl):
		credits_lbl.text = "%d" % StageDirector.credits
	if is_instance_valid(gems_lbl):
		gems_lbl.text = "%d" % StageDirector.dark_matter_gems
	if is_instance_valid(attempts_lbl):
		attempts_lbl.text = "%d/5" % StageDirector.attempts
	if is_instance_valid(campaign_progress_label):
		var finished := maxi(0, StageDirector.max_unlocked_stage - 1)
		campaign_progress_label.text = "KAMPANIA  •  %d / 100 ETAPÓW" % finished
	if is_instance_valid(campaign_progress_bar):
		campaign_progress_bar.value = maxi(0, StageDirector.max_unlocked_stage - 1)
	for milestone_index in range(campaign_milestone_labels.size()):
		var milestone_label: Label = campaign_milestone_labels[milestone_index]
		if not is_instance_valid(milestone_label):
			continue
		var required_stage: int = [1, 25, 50, 75, 100][milestone_index]
		var unlocked: bool = StageDirector.max_unlocked_stage >= required_stage
		milestone_label.add_theme_color_override("font_color", SurvivorVisualSystem.LIME if unlocked else SurvivorVisualSystem.MUTED)
		milestone_label.text = ("◆ %03d" if unlocked else "◇ %03d") % required_stage
	if is_instance_valid(base_power_label):
		base_power_label.text = "MOC OPERATORA  %d     |     ODBLOKOWANO ETAP %03d" % [StageDirector.get_total_combat_power(), StageDirector.max_unlocked_stage]

	if is_instance_valid(inbox_status_lbl):
		inbox_status_lbl.text = "Status zrzutu: ✓ ODEBRANO" if bool(StageDirector.inbox_claimed.get("welcome_drop", false)) else "Status zrzutu: 🎁 DO ODBIORU!"

	# Karta aktualnego etapu
	if is_instance_valid(stage_title_lbl):
		stage_title_lbl.text = "ETAP %03d" % StageDirector.current_stage
	if is_instance_valid(stage_details_lbl):
		var stage_subtitle := String(cfg.get("name", "")).strip_edges()
		if stage_subtitle.is_empty():
			stage_subtitle = String(cfg.get("chapter_name", "Pustkowia")).strip_edges()
		stage_details_lbl.text = stage_subtitle.to_upper()
	if is_instance_valid(mission_description):
		mission_description.text = String(cfg.get("description", "Oczyść sektor i zabezpiecz cel misji."))
	if is_instance_valid(stage_pwr_lbl):
		var rec_pwr := 450 + StageDirector.current_stage * 140
		stage_pwr_lbl.text = "ZALECANA MOC  %d" % rec_pwr

	if is_instance_valid(diff_btn):
		diff_btn.text = "⚔ %s" % String(diff.get("name", "Ocalały")).to_upper()

	if is_instance_valid(stage_prev_btn):
		stage_prev_btn.disabled = (StageDirector.current_stage <= 1)
	if is_instance_valid(stage_next_btn):
		stage_next_btn.disabled = (StageDirector.current_stage >= StageDirector.max_unlocked_stage)

	for sb in stage_quick_buttons:
		if is_instance_valid(sb):
			var tgt: int = int(sb.get_meta("target_stage", 1))
			var locked: bool = (tgt > StageDirector.max_unlocked_stage)
			sb.disabled = locked
			if locked:
				sb.text = "🔒 %03d" % tgt
				sb.modulate = Color(0.65, 0.65, 0.65, 0.70)
			else:
				var active: bool = (tgt == StageDirector.current_stage)
				sb.text = "Etap %03d" % tgt
				sb.modulate = Color(0.38, 1.0, 0.68) if active else Color(0.85, 0.92, 1.0)

	if is_instance_valid(practice_btn):
		practice_btn.text = "🎯 Trening (0 Prób)"

func _on_play_pressed() -> void:
	StageDirector.play_sfx("ui_click")
	StageDirector.is_practice_mode = false
	if not StageDirector.spend_campaign_attempt():
		switch_hub_tab(4)
		return
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_practice_pressed() -> void:
	StageDirector.play_sfx("ui_click")
	StageDirector.is_practice_mode = true
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_diff_pressed() -> void:
	StageDirector.play_sfx("ui_click")
	var idx := DIFF_IDS.find(StageDirector.selected_difficulty_id)
	idx = (idx + 1) % DIFF_IDS.size()
	StageDirector.selected_difficulty_id = DIFF_IDS[idx]
	StageDirector.save_campaign_profile()
	update_labels()
