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
var stage_title_lbl: Label = null
var stage_details_lbl: Label = null
var stage_pwr_lbl: Label = null
var stage_rewards_hbox: HBoxContainer = null
var boss_preview_tex: TextureRect = null
var diff_btn: Button = null
var play_big_btn: Button = null
var practice_btn: Button = null
var stage_prev_btn: Button = null
var stage_next_btn: Button = null
var stage_quick_buttons: Array[Button] = []

# Dolny Pasek Nawigacji (5 zakładek)
var bottom_nav_panel: PanelContainer = null
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
		var pulse := sin(idle_anim_time * 3.2) * 0.015
		play_big_btn.scale = Vector2(1.0 + pulse, 1.0 + pulse)
		play_big_btn.pivot_offset = play_big_btn.size * 0.5

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
	top_hub_panel.add_theme_stylebox_override("panel", top_st)
	add_child(top_hub_panel)

	var top_h := HBoxContainer.new()
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
	account_xp_bar.value = 65.0
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
	base_vbox.add_theme_constant_override("separation", 12)
	base_margin.add_child(base_vbox)

	_build_base_tab_content()

	# Wbudowany UserProfilePanel dla pozostałych zakładek
	user_profile_panel = UserProfilePanel.new()
	user_profile_panel.embedded_in_hub = true
	user_profile_panel.visible = false
	user_profile_panel.profile_updated.connect(update_labels)
	middle_root.add_child(user_profile_panel)
	user_profile_panel.set_embedded_mode(true)

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
	bottom_nav_panel.add_theme_stylebox_override("panel", nav_box_st)
	add_child(bottom_nav_panel)

	var nav_hbox := HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_hbox.add_theme_constant_override("separation", 4)
	bottom_nav_panel.add_child(nav_hbox)

	var nav_defs := [
		{"id": 0, "name": "Baza", "icon": "res://assets/ui/target_theme/nav_icon_baza.png"},
		{"id": 1, "name": "Postać", "icon": "res://assets/ui/target_theme/nav_icon_postac.png"},
		{"id": 2, "name": "Ekwipunek", "icon": "res://assets/ui/target_theme/nav_icon_ekwipunek.png"},
		{"id": 3, "name": "Kampania", "icon": "res://assets/ui/target_theme/nav_icon_kampania.png"},
		{"id": 4, "name": "Sklep", "icon": "res://assets/ui/target_theme/nav_icon_sklep.png"}
	]
	for nd in nav_defs:
		var tab_id: int = int(nd["id"])
		var tab_btn := Button.new()
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tab_btn.flat = true

		var btn_v := VBoxContainer.new()
		btn_v.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_v.add_theme_constant_override("separation", 2)
		tab_btn.add_child(btn_v)

		var ic_rect := TextureRect.new()
		ic_rect.custom_minimum_size = Vector2(28, 28)
		ic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(String(nd["icon"])):
			ic_rect.texture = load(String(nd["icon"]))
		btn_v.add_child(ic_rect)

		var lbl := Label.new()
		lbl.text = String(nd["name"])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_v.add_child(lbl)

		tab_btn.pressed.connect(func():
			StageDirector.play_sfx("ui_click")
			switch_hub_tab(tab_id)
		)
		nav_hbox.add_child(tab_btn)
		nav_buttons.append(tab_btn)

func _build_base_tab_content() -> void:
	# W układzie portretowym (9:16) postać i miasto stanowią integralne tło w górnej połowie.
	# Przestrzeń w górnej części (spacer) pozwala podziwiać żołnierza na tle ruin.
	var hero_spacer := Control.new()
	hero_spacer.custom_minimum_size = Vector2(0, 360)
	base_vbox.add_child(hero_spacer)

	# --------------------------------------------------------------------------
	# KARTA AKTUALNEGO ETAPU (Sci-Fi z obramowaniem cyjanowym card_stage_clean.png)
	# --------------------------------------------------------------------------
	stage_card = PanelContainer.new()
	stage_card.custom_minimum_size = Vector2(580, 270)
	var card_st := StyleBoxTexture.new()
	card_st.texture = load("res://assets/ui/target_theme/card_stage_clean.png")
	stage_card.add_theme_stylebox_override("panel", card_st)
	base_vbox.add_child(stage_card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 24)
	card_margin.add_theme_constant_override("margin_right", 24)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	stage_card.add_child(card_margin)

	var st_vbox := VBoxContainer.new()
	st_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	st_vbox.add_theme_constant_override("separation", 4)
	card_margin.add_child(st_vbox)

	# Górny wiersz karty: ◀ ETAP 030 ▶
	var title_h := HBoxContainer.new()
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
	stage_title_lbl.add_theme_font_size_override("font_size", 30)
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
	stage_details_lbl.add_theme_font_size_override("font_size", 20)
	stage_details_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	stage_details_lbl.text = "Krio Lab"
	st_vbox.add_child(stage_details_lbl)

	# Zalecana moc
	stage_pwr_lbl = Label.new()
	stage_pwr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_pwr_lbl.add_theme_font_size_override("font_size", 15)
	stage_pwr_lbl.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))
	stage_pwr_lbl.text = "Zalecana moc: 4 850"
	st_vbox.add_child(stage_pwr_lbl)

	# Odstęp
	var r_sp := Control.new()
	r_sp.custom_minimum_size = Vector2(0, 10)
	st_vbox.add_child(r_sp)

	# Wiersz 3 nagród etapu: Kryształ, Zębatka, XP
	stage_rewards_hbox = HBoxContainer.new()
	stage_rewards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_rewards_hbox.add_theme_constant_override("separation", 24)
	st_vbox.add_child(stage_rewards_hbox)

	var r_c := TextureRect.new()
	r_c.custom_minimum_size = Vector2(46, 42)
	r_c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r_c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_c.texture = load("res://assets/ui/target_theme/reward_crystal.png")
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
	play_big_btn.custom_minimum_size = Vector2(500, 126)
	play_big_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var play_tex_st := StyleBoxTexture.new()
	play_tex_st.texture = load("res://assets/ui/target_theme/btn_play_gold_clean.png")
	play_big_btn.add_theme_stylebox_override("normal", play_tex_st)
	play_big_btn.add_theme_stylebox_override("hover", play_tex_st)
	play_big_btn.add_theme_stylebox_override("pressed", play_tex_st)
	play_big_btn.add_theme_font_size_override("font_size", 32)
	play_big_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0))
	play_big_btn.text = ""
	play_big_btn.pressed.connect(_on_play_pressed)
	base_vbox.add_child(play_big_btn)

	# Pomocniczy wiersz opcji (dyskretny, przezroczysty sci-fi bez czarnych prostokątów)
	var aux_h := HBoxContainer.new()
	aux_h.alignment = BoxContainer.ALIGNMENT_CENTER
	aux_h.add_theme_constant_override("separation", 12)
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

	# Dolny odstęp aby treść nie chowała się pod paskiem nawigacji
	var bot_sp := Control.new()
	bot_sp.custom_minimum_size = Vector2(0, 120)
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
		var active := (i == current_hub_tab)
		nb.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(0.65, 0.75, 0.85, 0.65)
		if nb.get_child_count() > 0:
			var v := nb.get_child(0) as VBoxContainer
			if is_instance_valid(v) and v.get_child_count() >= 2:
				var lbl := v.get_child(1) as Label
				if is_instance_valid(lbl):
					lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0) if active else Color(0.65, 0.75, 0.85))

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
	card.custom_minimum_size = Vector2(460, 380)
	center.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)

	var t := Label.new()
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
	lang_h.add_theme_constant_override("separation", 6)
	v.add_child(lang_h)
	var lang_l := Label.new()
	lang_l.text = "🌐 Język / Language:"
	lang_l.custom_minimum_size = Vector2(150, 0)
	lang_l.add_theme_font_size_override("font_size", 12)
	lang_h.add_child(lang_l)

	for l_def in [{"id": "pl", "name": "Polski"}, {"id": "en", "name": "English"}, {"id": "de", "name": "Deutsch"}]:
		var lid: String = String(l_def["id"])
		var lb := Button.new()
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.custom_minimum_size = Vector2(0, 32)
		lb.text = String(l_def["name"])
		lb.pressed.connect(func():
			StageDirector.set_language(lid)
			StageDirector.play_sfx("ui_click")
			update_labels()
		)
		lang_h.add_child(lb)

	var net_btn := Button.new()
	net_btn.custom_minimum_size = Vector2(0, 34)
	net_btn.text = "📶 Tryb Sieci: ONLINE (Reklamy i Sklep aktywne)"
	net_btn.pressed.connect(func():
		StageDirector.is_online_mode = not StageDirector.is_online_mode
		net_btn.text = "📶 Tryb Sieci: ONLINE (Reklamy i Sklep aktywne)" if StageDirector.is_online_mode else "📴 Tryb Sieci: OFFLINE (Kampania działa, reklamy wyłączone)"
	)
	v.add_child(net_btn)

	var close_b := Button.new()
	close_b.text = "✕ ZAMKNIJ USTAWIENIA"
	close_b.custom_minimum_size = Vector2(0, 36)
	close_b.pressed.connect(func(): settings_modal.visible = false)
	v.add_child(close_b)

func _create_volume_slider_row(label_txt: String, init_val: float, cb: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = label_txt
	l.custom_minimum_size = Vector2(175, 0)
	l.add_theme_font_size_override("font_size", 12)
	h.add_child(l)

	var slider := HSlider.new()
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

	if is_instance_valid(top_hub_panel):
		top_hub_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
		top_hub_panel.offset_left = 10.0 if portrait else 24.0
		top_hub_panel.offset_top = 8.0 + safe_top
		top_hub_panel.offset_right = -10.0 if portrait else -24.0
		top_hub_panel.offset_bottom = 68.0 + safe_top

	if is_instance_valid(inbox_btn):
		inbox_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		inbox_btn.offset_left = 22.0 if portrait else 28.0
		inbox_btn.offset_top = 85.0 + safe_top
		inbox_btn.offset_right = 70.0 if portrait else 76.0
		inbox_btn.offset_bottom = 133.0 + safe_top

	if is_instance_valid(bottom_nav_panel):
		bottom_nav_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bottom_nav_panel.offset_left = 12.0 if portrait else 28.0
		bottom_nav_panel.offset_top = -76.0 if portrait else -68.0
		bottom_nav_panel.offset_right = -12.0 if portrait else -28.0
		bottom_nav_panel.offset_bottom = -6.0 if portrait else -4.0

	if is_instance_valid(middle_root):
		middle_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		middle_root.offset_left = 0.0
		middle_root.offset_top = 72.0 + safe_top
		middle_root.offset_right = 0.0
		middle_root.offset_bottom = -80.0 if portrait else -72.0

	if is_instance_valid(orient_btn):
		orient_btn.text = "📱 9:16" if portrait else "🖥 16:9"

func update_labels() -> void:
	StageDirector.refresh_attempts()
	var cfg := StageDirector.get_stage_config(StageDirector.current_stage)
	var diff := StageDirector.get_difficulty_profile()

	# Górny Pasek
	if is_instance_valid(account_lvl_lbl):
		account_lvl_lbl.text = "Lv:%d" % StageDirector.character_level
	if is_instance_valid(account_xp_bar):
		account_xp_bar.max_value = 100.0
		account_xp_bar.value = 65.0
	if is_instance_valid(credits_lbl):
		credits_lbl.text = "%d" % StageDirector.credits
	if is_instance_valid(gems_lbl):
		gems_lbl.text = "%d" % StageDirector.dark_matter_gems
	if is_instance_valid(attempts_lbl):
		attempts_lbl.text = "%d/5" % StageDirector.attempts

	if is_instance_valid(inbox_status_lbl):
		inbox_status_lbl.text = "Status zrzutu: ✓ ODEBRANO" if bool(StageDirector.inbox_claimed.get("welcome_drop", false)) else "Status zrzutu: 🎁 DO ODBIORU!"

	# Karta aktualnego etapu
	if is_instance_valid(stage_title_lbl):
		stage_title_lbl.text = "ETAP %03d" % StageDirector.current_stage
	if is_instance_valid(stage_details_lbl):
		stage_details_lbl.text = String(cfg.get("chapter_name", cfg.get("name", "Krio Lab")))
	if is_instance_valid(stage_pwr_lbl):
		var rec_pwr := 450 + StageDirector.current_stage * 140
		stage_pwr_lbl.text = "Zalecana moc: %d" % rec_pwr

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
