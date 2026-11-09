extends ColorRect
class_name UserProfilePanel

## Profesjonalny Panel Postaci RPG (6 slotów wokół bohatera + inspektor przedmiotu),
## Osobny Ekran Ekwipunku i Plecaka (siatka HD, filtry slotu/jakości, sortowanie, porównywanie),
## Mapa Kampanii 1-100 & Talenty oraz Sklep Premium Sandbox (8 sekcji z blokadą duplikacji).
## Wspiera zarówno tryb wbudowany w Hub Menu Głównego (embedded_in_hub), jak i modalny w trakcie gry.

signal profile_updated()
signal panel_closed()
signal launch_stage_requested(practice_mode: bool)

var player_ref: Player = null
var embedded_in_hub: bool = false
var current_tab: int = 0 # 0=Postać RPG, 1=Ekwipunek, 2=Kampania 1-100, 3=Sklep Premium, 4=Nagrody 7 Dni

var tab_bg_tex: TextureRect = null
var main_card: PanelContainer
var top_header_hbox: HBoxContainer
var currencies_lbl: Label
var tab_buttons_hbox: HBoxContainer
var tab_buttons: Array[Button] = []
var profile_title_lbl: Label = null
var profile_orient_btn: Button = null
var inv_slot_filters_grid: GridContainer = null
var tab_containers: Array[Control] = []

# --- TAB 0: PANEL POSTACI RPG (Bohater w centrum + 6 slotów wokół niego) ---
var hero_center_tex: TextureRect
var hero_weapon_badge_tex: TextureRect
var hero_weapon_badge_lbl: Label
var hero_power_lbl: Label
var commander_title_lbl: Label
var class_bonus_lbl: Label
var account_lvl_lbl: Label
var account_xp_bar: ProgressBar
var stats_summary_lbl: Label
var class_buttons: Dictionary = {}
var skin_buttons: Dictionary = {}
var left_slots_vbox: VBoxContainer
var right_slots_vbox: VBoxContainer
var selected_inspect_instance_id: String = ""
var selected_inspect_slot_id: String = "weapon"
var char_inspector_box: PanelContainer

# --- TAB 1: EKWIPUNEK I PLECAK (Siatka, Filtry, Sortowanie, Porównanie) ---
var filter_slot: String = "all"
var filter_rarity: String = "all"
var sort_mode: String = "power" # "power", "level", "rarity"
var inv_slot_filter_btns: Dictionary = {}
var inv_rarity_btn: Button
var inv_sort_btn: Button
var inv_materials_lbl: Label
var inv_chest_btn: Button = null
var inv_grid: GridContainer
var inv_detail_box: PanelContainer
var selected_bag_instance_id: String = ""

# --- TAB 2: KAMPANIA 1-100 & TALENTY ---
var talent_rows: Dictionary = {}
var stage_info_lbl: Label
var stage_boss_preview: TextureRect
var diff_info_lbl: Label
var practice_check_btn: Button

# --- TAB 3: SKLEP PREMIUM (8 Sekcji Sandbox) ---
var store_category_filter: String = "all"
var store_cat_btns: Dictionary = {}
var store_cards_grid: GridContainer
var store_categories_grid: GridContainer = null
var sandbox_status_lbl: Label
var store_purchase_dialog: ConfirmationDialog = null
var pending_store_purchase: Dictionary = {}
var free_daily_pack_btn: Button

# --- TAB 4: CODZIENNE NAGRODY 7 DNI & ZADANIA DZIENNE ---
var daily_grid: GridContainer
var daily_missions_vbox: VBoxContainer
var daily_reset_lbl: Label
var bp_label: Label
var bp_bar: ProgressBar

const CLASS_ORDER := ["soldier", "engineer", "medic", "scout"]
const SKIN_ORDER := ["default", "gold_veteran", "neon_hunter", "crimson_storm", "hazmat_trooper", "void_sniper"]
const DIFF_ORDER := ["rekrut", "ocalaly", "weteran", "koszmar", "apokalipsa"]
const LEFT_SLOTS := ["weapon", "chest", "boots"]
const RIGHT_SLOTS := ["helmet", "gloves", "amulet"]

const TALENT_DEFS := [
	{"id": "vitality", "name": "Witalność Nano-Ogniw", "desc": "+6% Maks. HP na poziom", "icon": "res://assets/mutantsurvivor_ch01/icons/medkit.png", "base_cost": 60},
	{"id": "firepower", "name": "Rdzeń Siły Ognia", "desc": "+5% Obrażeń Broni na poziom", "icon": "res://assets/mutantsurvivor_ch01/weapons/weapon_1.png", "base_cost": 65},
	{"id": "scanner", "name": "Skaner Magnetyczny", "desc": "+18 px Zasięgu Skanera XP na poziom", "icon": "res://assets/mutantsurvivor_ch01/icons/skill_luck.png", "base_cost": 50},
	{"id": "armor_plating", "name": "Poszycie Tytanowe", "desc": "+3% Redukcji Obrażeń na poziom", "icon": "res://assets/mutantsurvivor_ch01/icons/shield_orb.png", "base_cost": 75}
]

const STORE_PRODUCTS := [
	{
		"id": "skin_neon_hunter", "category": "skins",
		"category_label": "SKÓRKI OPERATORÓW",
		"title": "Cyber Ronin X-9",
		"contents": "Wygląd operatora Cyber Ronin • bez bonusów bojowych • na stałe",
		"price_label": "120 kryształów",
		"icon": "res://assets/mutantsurvivor_ch01/characters/cyber_ronin.png",
		"accent": Color(0.25, 0.92, 1.0), "once": true, "skin_unlock": "neon_hunter"
	},
	{
		"id": "skin_hazmat_trooper", "category": "skins",
		"category_label": "SKÓRKI OPERATORÓW",
		"title": "Szturmowiec Bio-Hazmat",
		"contents": "Wygląd kombinezonu Hazmat • bez bonusów bojowych • na stałe",
		"price_label": "120 kryształów",
		"icon": "res://assets/mutantsurvivor_ch01/characters/hazmat_trooper.png",
		"accent": Color(0.45, 1.0, 0.35), "once": true, "skin_unlock": "hazmat_trooper"
	},
	{
		"id": "skin_crimson_storm", "category": "skins",
		"category_label": "SKÓRKI OPERATORÓW",
		"title": "Karmazynowy Medyk",
		"contents": "Wygląd medyka • bez bonusów bojowych • na stałe",
		"price_label": "120 kryształów",
		"icon": "res://assets/mutantsurvivor_ch01/characters/crimson_medic.png",
		"accent": Color(1.0, 0.35, 0.45), "once": true, "skin_unlock": "crimson_storm"
	},
	{
		"id": "skin_void_sniper", "category": "skins",
		"category_label": "SKÓRKI OPERATORÓW",
		"title": "Snajper Otchłani",
		"contents": "Wygląd zwiadowcy • bez bonusów bojowych • na stałe",
		"price_label": "150 kryształów",
		"icon": "res://assets/mutantsurvivor_ch01/characters/void_sniper.png",
		"accent": Color(0.78, 0.42, 1.0), "once": true, "skin_unlock": "void_sniper"
	},
	{
		"id": "attempts_refill_full", "category": "attempts",
		"category_label": "PRÓBY KAMPANII",
		"title": "Odnowienie prób 5/5",
		"contents": "Odnawia wszystkie próby • normalna regeneracja pozostaje darmowa",
		"price_label": "60 kryształów",
		"icon": "res://assets/mutantsurvivor_ch01/icons/energy_cell.png",
		"accent": Color(0.28, 0.95, 0.72), "once": false
	},
	{
		"id": "crystals_pack_500", "category": "crystals",
		"category_label": "KRYSZTAŁY PREMIUM",
		"title": "500 kryształów",
		"contents": "Zakup za prawdziwe pieniądze zostanie uruchomiony dopiero po wdrożeniu bezpiecznej płatności.",
		"price_label": "W przygotowaniu",
		"icon": "res://assets/mutantsurvivor_ch01/icons/purple_crystal.png",
		"accent": Color(0.82, 0.45, 1.0), "once": false
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.04, 0.08, 0.0 if embedded_in_hub else 0.92)
	_build_ui()
	_setup_store_confirmation()
	if not StageDirector.orientation_changed.is_connected(_on_orientation_changed):
		StageDirector.orientation_changed.connect(_on_orientation_changed)
	_apply_responsive_metrics()
	if not get_viewport().size_changed.is_connected(_apply_responsive_metrics):
		get_viewport().size_changed.connect(_apply_responsive_metrics)
	refresh_ui()

func _on_orientation_changed(_is_portrait: bool) -> void:
	_apply_responsive_metrics()
	refresh_ui()

func _apply_responsive_metrics(test_width_override: float = -1.0) -> void:
	if not is_instance_valid(main_card):
		return
	var portrait := StageDirector.is_portrait_mode()
	# The production UI reads its actual viewport. In headless QA, Godot may
	# retain its configured 720px render size even after SceneTree.root.size
	# changes. An explicit test width exercises the same layout branch.
	var available_width := test_width_override if test_width_override > 0.0 else get_viewport_rect().size.x
	var narrow := portrait and available_width < 600.0
	main_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if embedded_in_hub:
		main_card.offset_left = 8
		main_card.offset_top = 4
		main_card.offset_right = -8
		main_card.offset_bottom = -4
	elif portrait:
		var safe_t := StageDirector.get_safe_top_margin()
		main_card.offset_left = 10
		main_card.offset_top = 12 + safe_t
		main_card.offset_right = -10
		main_card.offset_bottom = -12
	else:
		main_card.offset_left = 36
		main_card.offset_top = 16
		main_card.offset_right = -36
		main_card.offset_bottom = -16

	if is_instance_valid(profile_title_lbl):
		profile_title_lbl.text = "POSTAĆ / EKWIPUNEK" if portrait else "CENTRUM DOWODZENIA RPG"
		profile_title_lbl.add_theme_font_size_override("font_size", 13 if portrait else 17)
	if is_instance_valid(profile_orient_btn):
		profile_orient_btn.text = "9:16" if portrait else "16:9"
		profile_orient_btn.custom_minimum_size = Vector2(54, 34) if portrait else Vector2(118, 34)
	for i in range(tab_buttons.size()):
		var short_titles := ["POSTAĆ", "PLECAK", "MAPA", "SKLEP", "NAGRODY"]
		tab_buttons[i].text = short_titles[i] if portrait else ["POSTAĆ RPG", "EKWIPUNEK", "KAMPANIA", "SKLEP", "NAGRODY"][i]
		tab_buttons[i].add_theme_font_size_override("font_size", 10 if portrait else 12)
	if is_instance_valid(inv_chest_btn):
		inv_chest_btn.text = "SKRZYNIA · 80 Kr" if portrait else "SKRZYNIA ZBROJOWNI (-80 Kr)"
		inv_chest_btn.custom_minimum_size = Vector2(126, 34) if portrait else Vector2(180, 34)
		inv_chest_btn.add_theme_font_size_override("font_size", 10 if portrait else 12)
	if is_instance_valid(inv_slot_filters_grid):
		inv_slot_filters_grid.columns = (2 if narrow else 4) if portrait else 7
	if is_instance_valid(inv_grid):
		inv_grid.columns = (2 if narrow else 4) if portrait else 6
	if is_instance_valid(store_cards_grid):
		store_cards_grid.columns = (1 if narrow else 2) if portrait else 3
	if is_instance_valid(store_categories_grid):
		store_categories_grid.columns = (2 if narrow else 4) if portrait else 4
	if is_instance_valid(daily_grid):
		daily_grid.columns = (2 if narrow else 4) if portrait else 7

func _build_ui() -> void:
	tab_bg_tex = TextureRect.new()
	tab_bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tab_bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(tab_bg_tex)

	main_card = PanelContainer.new()
	main_card.clip_contents = true
	var card_style := StyleBoxFlat.new()
	if embedded_in_hub:
		# Dark backing is essential: the scenic hub illustration previously
		# showed through equipment text, icons and campaign descriptions.
		card_style.bg_color = Color(0.025, 0.045, 0.075, 0.96)
		card_style.border_width_left = 0
		card_style.border_width_top = 0
		card_style.border_width_right = 0
		card_style.border_width_bottom = 0
	else:
		card_style.bg_color = Color(0.04, 0.07, 0.12, 0.96)
		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.border_color = Color(0.18, 0.85, 0.98, 0.88)
	card_style.corner_radius_top_left = 14
	card_style.corner_radius_top_right = 14
	card_style.corner_radius_bottom_left = 14
	card_style.corner_radius_bottom_right = 14
	card_style.content_margin_left = 10
	card_style.content_margin_right = 10
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8
	main_card.add_theme_stylebox_override("panel", card_style)
	add_child(main_card)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	main_card.add_child(root_vbox)

	# Nagłówek (widoczny w trybie modalnym podczas rozgrywki; w Hubie ukryty, bo Hub ma własny górny i dolny pasek)
	top_header_hbox = HBoxContainer.new()
	top_header_hbox.add_theme_constant_override("separation", 8)
	top_header_hbox.visible = not embedded_in_hub
	root_vbox.add_child(top_header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "⚡ CENTRUM DOWODZENIA RPG"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.28, 0.95, 1.0))
	top_header_hbox.add_child(title_lbl)
	profile_title_lbl = title_lbl

	var orient_btn := Button.new()
	orient_btn.text = "📱/🖥 9:16↔16:9"
	orient_btn.custom_minimum_size = Vector2(118, 34)
	orient_btn.add_theme_font_size_override("font_size", 12)
	orient_btn.pressed.connect(func(): StageDirector.toggle_orientation_mode())
	top_header_hbox.add_child(orient_btn)
	profile_orient_btn = orient_btn

	var close_btn := Button.new()
	close_btn.text = "✕ ZAMKNIJ"
	close_btn.custom_minimum_size = Vector2(104, 34)
	close_btn.add_theme_font_size_override("font_size", 12)
	close_btn.pressed.connect(close_panel)
	top_header_hbox.add_child(close_btn)

	currencies_lbl = Label.new()
	currencies_lbl.visible = not embedded_in_hub
	currencies_lbl.add_theme_font_size_override("font_size", 12)
	currencies_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	root_vbox.add_child(currencies_lbl)

	tab_buttons_hbox = HBoxContainer.new()
	tab_buttons_hbox.add_theme_constant_override("separation", 6)
	tab_buttons_hbox.visible = not embedded_in_hub
	root_vbox.add_child(tab_buttons_hbox)

	var tab_titles := [
		"👤 POSTAĆ",
		"🎒 EKWIPUNEK",
		"🗺 KAMPANIA",
		"🛒 SKLEP",
		"🎁 NAGRODY"
	]
	for i in range(tab_titles.size()):
		var t_btn := Button.new()
		t_btn.text = tab_titles[i]
		t_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_btn.custom_minimum_size = Vector2(0, 36)
		t_btn.add_theme_font_size_override("font_size", 12)
		var idx: int = i
		t_btn.pressed.connect(func(): switch_tab(idx))
		tab_buttons_hbox.add_child(t_btn)
		tab_buttons.append(t_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var content_holder := VBoxContainer.new()
	content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_holder)

	var tab_char := _build_tab_character_showcase()
	var tab_inv := _build_tab_inventory_backpack()
	var tab_camp := _build_tab_campaign_and_talents()
	var tab_shop := _build_tab_premium_store()
	var tab_rew := _build_tab_daily_rewards()

	content_holder.add_child(tab_char)
	content_holder.add_child(tab_inv)
	content_holder.add_child(tab_camp)
	content_holder.add_child(tab_shop)
	content_holder.add_child(tab_rew)
	tab_containers = [tab_char, tab_inv, tab_camp, tab_shop, tab_rew]
	switch_tab(0)

func set_embedded_mode(embedded: bool) -> void:
	embedded_in_hub = embedded
	color = Color(0.02, 0.04, 0.08, 0.0 if embedded_in_hub else 0.92)
	if is_instance_valid(top_header_hbox):
		top_header_hbox.visible = not embedded_in_hub
	if is_instance_valid(currencies_lbl):
		currencies_lbl.visible = not embedded_in_hub
	if is_instance_valid(tab_buttons_hbox):
		tab_buttons_hbox.visible = not embedded_in_hub
	_apply_responsive_metrics()

func switch_tab(tab_idx: int) -> void:
	current_tab = clampi(tab_idx, 0, tab_containers.size() - 1)
	_update_tab_background()
	for i in range(tab_containers.size()):
		tab_containers[i].visible = (i == current_tab)
		if i < tab_buttons.size():
			tab_buttons[i].modulate = Color(0.32, 1.0, 0.68) if (i == current_tab) else Color(0.82, 0.88, 0.96)
	refresh_ui()

func _update_tab_background() -> void:
	if not is_instance_valid(tab_bg_tex):
		return
	match current_tab:
		0, 1:
			tab_bg_tex.texture = load("res://assets/ui/target_theme/bg_armory_pedestal.png")
		2:
			tab_bg_tex.texture = load("res://assets/ui/target_theme/bg_clean_soldier_ruins.png")
		3, 4:
			tab_bg_tex.texture = load("res://assets/ui/target_theme/bg_store_depot.png")
		_:
			tab_bg_tex.texture = load("res://assets/ui/target_theme/bg_armory_pedestal.png")

func open_panel(tab_idx: int = 0) -> void:
	visible = true
	switch_tab(tab_idx)

func close_panel() -> void:
	visible = false
	emit_signal("panel_closed")

# ==============================================================================
# 1. PANEL POSTACI RPG (Bohater w centrum + 6 slotów wokół postaci + Inspektor)
# ==============================================================================
func _build_tab_character_showcase() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	# Górna belka klasy i poziomu konta
	var top_card := _create_subpanel(Color(0.22, 0.82, 1.0, 0.75))
	vbox.add_child(top_card)
	var top_v := VBoxContainer.new()
	top_v.add_theme_constant_override("separation", 4)
	top_card.add_child(top_v)

	var title_row := HBoxContainer.new()
	top_v.add_child(title_row)

	commander_title_lbl = Label.new()
	commander_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	commander_title_lbl.add_theme_font_size_override("font_size", 15)
	commander_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42))
	title_row.add_child(commander_title_lbl)

	hero_power_lbl = Label.new()
	hero_power_lbl.add_theme_font_size_override("font_size", 15)
	hero_power_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
	title_row.add_child(hero_power_lbl)

	class_bonus_lbl = Label.new()
	class_bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	class_bonus_lbl.add_theme_font_size_override("font_size", 11)
	class_bonus_lbl.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0))
	top_v.add_child(class_bonus_lbl)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 8)
	top_v.add_child(xp_row)

	account_lvl_lbl = Label.new()
	account_lvl_lbl.add_theme_font_size_override("font_size", 11)
	xp_row.add_child(account_lvl_lbl)

	account_xp_bar = ProgressBar.new()
	account_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_xp_bar.custom_minimum_size = Vector2(120, 12)
	account_xp_bar.show_percentage = false
	xp_row.add_child(account_xp_bar)

	# CENTRALNA ARENA POSTACI: 3 Sloty po lewej | Duża Sylwetka Bohatera w środku | 3 Sloty po prawej
	var arena_card := _create_subpanel(Color(0.25, 0.95, 0.65, 0.80))
	vbox.add_child(arena_card)

	var arena_hbox := HBoxContainer.new()
	arena_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	arena_hbox.add_theme_constant_override("separation", 14)
	arena_card.add_child(arena_hbox)

	left_slots_vbox = VBoxContainer.new()
	left_slots_vbox.custom_minimum_size = Vector2(82, 0)
	left_slots_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_slots_vbox.add_theme_constant_override("separation", 10)
	arena_hbox.add_child(left_slots_vbox)

	# Środkowy Obszar Bohatera na Podeście
	var center_pedestal := PanelContainer.new()
	center_pedestal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_pedestal.custom_minimum_size = Vector2(280, 330)
	var ped_st := StyleBoxFlat.new()
	ped_st.bg_color = Color(0, 0, 0, 0.0) # Przezroczyste, tło podestu widać bezpośrednio
	ped_st.border_width_left = 0
	ped_st.border_width_top = 0
	ped_st.border_width_right = 0
	ped_st.border_width_bottom = 0
	center_pedestal.add_theme_stylebox_override("panel", ped_st)
	arena_hbox.add_child(center_pedestal)

	var ped_vbox := VBoxContainer.new()
	ped_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ped_vbox.add_theme_constant_override("separation", 6)
	center_pedestal.add_child(ped_vbox)

	hero_center_tex = TextureRect.new()
	hero_center_tex.custom_minimum_size = Vector2(250, 280)
	hero_center_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_center_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ped_vbox.add_child(hero_center_tex)

	var w_badge_hbox := HBoxContainer.new()
	w_badge_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	w_badge_hbox.add_theme_constant_override("separation", 6)
	ped_vbox.add_child(w_badge_hbox)

	hero_weapon_badge_tex = TextureRect.new()
	hero_weapon_badge_tex.custom_minimum_size = Vector2(28, 22)
	hero_weapon_badge_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_weapon_badge_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	w_badge_hbox.add_child(hero_weapon_badge_tex)

	hero_weapon_badge_lbl = Label.new()
	hero_weapon_badge_lbl.add_theme_font_size_override("font_size", 12)
	hero_weapon_badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.32))
	w_badge_hbox.add_child(hero_weapon_badge_lbl)

	right_slots_vbox = VBoxContainer.new()
	right_slots_vbox.custom_minimum_size = Vector2(82, 0)
	right_slots_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_slots_vbox.add_theme_constant_override("separation", 10)
	arena_hbox.add_child(right_slots_vbox)

	# Wybór 4 Klas + 6 Skinów HD
	var selector_card := _create_subpanel()
	vbox.add_child(selector_card)
	var sel_vbox := VBoxContainer.new()
	sel_vbox.add_theme_constant_override("separation", 6)
	selector_card.add_child(sel_vbox)

	var cls_hbox := HBoxContainer.new()
	cls_hbox.add_theme_constant_override("separation", 6)
	sel_vbox.add_child(cls_hbox)
	var cls_lbl := Label.new()
	cls_lbl.text = "Klasa:"
	cls_lbl.custom_minimum_size = Vector2(52, 0)
	cls_lbl.add_theme_font_size_override("font_size", 12)
	cls_hbox.add_child(cls_lbl)

	for cid in CLASS_ORDER:
		var c_key: String = String(cid)
		var c_cfg: Dictionary = StageDirector.HERO_CLASSES[c_key]
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 30)
		btn.add_theme_font_size_override("font_size", 12)
		btn.text = String(c_cfg["name"]).split(" ")[0]
		btn.pressed.connect(func():
			StageDirector.switch_class(c_key)
			if is_instance_valid(player_ref):
				player_ref.apply_class_and_talents(false)
			refresh_ui()
			emit_signal("profile_updated")
		)
		cls_hbox.add_child(btn)
		class_buttons[c_key] = btn

	var skin_hbox := HBoxContainer.new()
	skin_hbox.add_theme_constant_override("separation", 4)
	sel_vbox.add_child(skin_hbox)
	var skin_lbl := Label.new()
	skin_lbl.text = "Skin HD:"
	skin_lbl.custom_minimum_size = Vector2(52, 0)
	skin_lbl.add_theme_font_size_override("font_size", 11)
	skin_hbox.add_child(skin_lbl)

	for sid in SKIN_ORDER:
		var s_key: String = String(sid)
		var s_cfg: Dictionary = StageDirector.HERO_SKINS[s_key]
		var s_btn := Button.new()
		s_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s_btn.custom_minimum_size = Vector2(0, 28)
		s_btn.add_theme_font_size_override("font_size", 10)
		s_btn.clip_text = true
		s_btn.text = String(s_cfg["name"])
		s_btn.pressed.connect(func():
			if not StageDirector.unlocked_skins.has(s_key) and s_key != "default":
				return
			StageDirector.selected_skin_id = s_key
			StageDirector.save_campaign_profile()
			if is_instance_valid(player_ref):
				player_ref.apply_class_and_talents(false)
			refresh_ui()
			emit_signal("profile_updated")
		)
		skin_hbox.add_child(s_btn)
		skin_buttons[s_key] = s_btn

	# INSPEKTOR WYBRANEGO PRZEDMIOTU / SLOTU (Nazwa, Grafika, Rzadkość, Poziom, Afiksy, Porównanie, Załóż/Ulepsz/Zdejmij)
	char_inspector_box = _create_subpanel(Color(1.0, 0.78, 0.25, 0.85))
	vbox.add_child(char_inspector_box)

	# Podsumowanie statystyk bojowych
	var stats_card := _create_subpanel()
	vbox.add_child(stats_card)
	stats_summary_lbl = Label.new()
	stats_summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_summary_lbl.add_theme_font_size_override("font_size", 11)
	stats_summary_lbl.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0))
	stats_card.add_child(stats_summary_lbl)

	return vbox

func _build_slot_widget(slot_id: String) -> Control:
	var inst_id := String(StageDirector.equipped_items.get(slot_id, ""))
	var item := StageDirector.get_item_instance(inst_id)
	var slot_title := String(StageDirector.GEAR_SLOT_NAMES.get(slot_id, slot_id))
	var is_selected := (selected_inspect_slot_id == slot_id)

	var rar := String(item.get("rarity", "common")) if not item.is_empty() else "common"
	var r_col: Color = StageDirector.RARITY_COLORS.get(rar, Color(0.45, 0.55, 0.68))
	var border_col := Color(1.0, 0.90, 0.28) if is_selected else (r_col if not item.is_empty() else Color(0.24, 0.34, 0.48, 0.75))

	var card := Button.new()
	card.custom_minimum_size = Vector2(80, 84)
	card.flat = true
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.08, 0.16, 0.82) if not item.is_empty() else Color(0.02, 0.05, 0.10, 0.65)
	st.border_width_left = 3 if is_selected else 2
	st.border_width_top = 3 if is_selected else 2
	st.border_width_right = 3 if is_selected else 2
	st.border_width_bottom = 3 if is_selected else 2
	st.border_color = border_col
	st.corner_radius_top_left = 10
	st.corner_radius_top_right = 10
	st.corner_radius_bottom_left = 10
	st.corner_radius_bottom_right = 10
	card.add_theme_stylebox_override("normal", st)
	card.add_theme_stylebox_override("hover", st)
	card.add_theme_stylebox_override("pressed", st)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)

	var slot_lbl := Label.new()
	slot_lbl.text = slot_title.to_upper()
	slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_lbl.add_theme_font_size_override("font_size", 9)
	slot_lbl.add_theme_color_override("font_color", Color(0.60, 0.85, 1.0))
	v.add_child(slot_lbl)

	var icon_r := TextureRect.new()
	var icon_path := AssetRegistry.get_item_icon_path(item) if not item.is_empty() else String(AssetRegistry.EQUIPMENT_SLOT_ICONS.get(slot_id, ""))
	icon_r.texture = AssetRegistry.get_tex(icon_path)
	icon_r.custom_minimum_size = Vector2(44, 44)
	icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item.is_empty():
		icon_r.modulate = Color(0.4, 0.5, 0.65, 0.40)
	v.add_child(icon_r)

	var btm_lbl := Label.new()
	btm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btm_lbl.add_theme_font_size_override("font_size", 9)
	if item.is_empty():
		btm_lbl.text = "PUSTY"
		btm_lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.65))
	else:
		var lvl := int(item.get("level", 0))
		btm_lbl.text = "+%d" % lvl if lvl > 0 else "✓"
		btm_lbl.add_theme_color_override("font_color", r_col)
	v.add_child(btm_lbl)

	var s_cap: String = String(slot_id)
	var i_cap: String = inst_id
	card.pressed.connect(func():
		StageDirector.play_sfx("ui_click")
		selected_inspect_slot_id = s_cap
		selected_inspect_instance_id = i_cap
		refresh_ui()
	)
	return card

func _refresh_character_inspector() -> void:
	if not is_instance_valid(char_inspector_box):
		return
	for c in char_inspector_box.get_children():
		c.queue_free()

	var slot_id := selected_inspect_slot_id
	var slot_title := String(StageDirector.GEAR_SLOT_NAMES.get(slot_id, slot_id))
	var eq_inst_id := String(StageDirector.equipped_items.get(slot_id, ""))
	var inspect_id := selected_inspect_instance_id if not selected_inspect_instance_id.is_empty() else eq_inst_id
	var item := StageDirector.get_item_instance(inspect_id)

	# Jeśli slot jest pusty, znajdź pierwszy dostępny przedmiot z plecaka dla tego slotu do podglądu
	if item.is_empty():
		for bag_it in StageDirector.inventory:
			if bag_it is Dictionary and String(bag_it.get("slot", "")) == slot_id:
				item = bag_it
				inspect_id = String(bag_it.get("instance_id", ""))
				break

	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 6)
	char_inspector_box.add_child(main_v)

	if item.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "🔍 SLOT: %s — Brak założonego przedmiotu. Otwórz zakładkę „🎒 Ekwipunek” lub „🛒 Sklep”, aby zdobyć wyposażenie." % slot_title.to_upper()
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		main_v.add_child(empty_lbl)
		return

	var rar := String(item.get("rarity", "common"))
	var r_col: Color = StageDirector.RARITY_COLORS.get(rar, Color.WHITE)
	var r_name := String(StageDirector.RARITY_NAMES.get(rar, "Zwykła"))
	var lvl := int(item.get("level", 0))
	var pwr := StageDirector.get_item_effective_power(item)
	var is_equipped := (eq_inst_id == inspect_id)

	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 10)
	main_v.add_child(top_h)

	var ic_rect := TextureRect.new()
	ic_rect.texture = AssetRegistry.get_tex(AssetRegistry.get_item_icon_path(item))
	ic_rect.custom_minimum_size = Vector2(58, 58)
	ic_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top_h.add_child(ic_rect)

	var info_v := VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	top_h.add_child(info_v)

	var header_l := Label.new()
	header_l.text = "%s +%d  [%s — %s] %s" % [
		String(item.get("name", slot_title)),
		lvl,
		r_name.to_upper(),
		slot_title,
		"✓ ZAŁOŻONO" if is_equipped else "(W PLECAKU)"
	]
	header_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_l.add_theme_font_size_override("font_size", 13)
	header_l.add_theme_color_override("font_color", r_col)
	info_v.add_child(header_l)

	var base_stat_desc := "Atak Bazowy: +%.1f" % pwr if slot_id == "weapon" else ("Zdrowie Pancerza: +%.0f HP" % (pwr * 2.5) if (slot_id == "helmet" or slot_id == "chest") else "Moc Modułu: +%.1f" % pwr)
	var af_parts: PackedStringArray = []
	for af in item.get("affixes", []):
		if af is Dictionary:
			af_parts.append("%s +%.1f" % [StageDirector.translate_affix(String(af.get("id", ""))), float(af.get("value", 0.0))])
	var af_str := " | ".join(af_parts) if af_parts.size() > 0 else "Brak dodatkowych afiksów"

	# Porównanie z aktualnie założonym przedmiotem
	var cmp_str := "Aktualnie założony w slocie %s" % slot_title
	if not is_equipped:
		var eq_it := StageDirector.get_item_instance(eq_inst_id)
		var eq_pwr := StageDirector.get_item_effective_power(eq_it)
		var diff_p := pwr - eq_pwr
		var sign_s := "+" if diff_p >= 0.0 else ""
		cmp_str = "Porównanie z założonym (%s): %s%.1f Mocy" % [String(eq_it.get("name", "Brak")), sign_s, diff_p]

	var stats_l := Label.new()
	stats_l.text = "• %s  |  • Afiksy: %s\n• %s" % [base_stat_desc, af_str, cmp_str]
	stats_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_l.add_theme_font_size_override("font_size", 11)
	stats_l.add_theme_color_override("font_color", Color(0.86, 0.94, 1.0))
	info_v.add_child(stats_l)

	# Przyciski akcji: Załóż | Ulepsz | Zdejmij | Zmień przedmiot
	var btns_h := HBoxContainer.new()
	btns_h.add_theme_constant_override("separation", 8)
	main_v.add_child(btns_h)

	var btn_equip := Button.new()
	btn_equip.text = "✓ ZAŁOŻONO" if is_equipped else "📥 ZAŁÓŻ"
	btn_equip.disabled = is_equipped
	btn_equip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_equip.custom_minimum_size = Vector2(0, 34)
	btn_equip.add_theme_font_size_override("font_size", 12)
	var cap_inst: String = inspect_id
	btn_equip.pressed.connect(func():
		StageDirector.equip_item(cap_inst)
		if is_instance_valid(player_ref):
			player_ref.apply_class_and_talents(false)
		refresh_ui()
		emit_signal("profile_updated")
	)
	btns_h.add_child(btn_equip)

	var cost_c := 45 + lvl * 30
	var cost_s := 1 + int(lvl / 3)
	var btn_upg := Button.new()
	btn_upg.text = "⬆ ULEPSZ +1 (-%d Kr, -%d Złom)" % [cost_c, cost_s] if lvl < 10 else "MAKS. POZIOM (+10)"
	btn_upg.disabled = (lvl >= 10) or (StageDirector.credits < cost_c) or (StageDirector.scrap_materials < cost_s)
	btn_upg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_upg.custom_minimum_size = Vector2(0, 34)
	btn_upg.add_theme_font_size_override("font_size", 12)
	btn_upg.pressed.connect(func():
		if StageDirector.upgrade_item_by_instance(cap_inst):
			if is_instance_valid(player_ref):
				player_ref.apply_class_and_talents(false)
			refresh_ui()
			emit_signal("profile_updated")
	)
	btns_h.add_child(btn_upg)

	var btn_unequip := Button.new()
	btn_unequip.text = "📤 ZDEJMIJ"
	btn_unequip.disabled = not is_equipped
	btn_unequip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_unequip.custom_minimum_size = Vector2(0, 34)
	btn_unequip.add_theme_font_size_override("font_size", 12)
	var cap_slot: String = slot_id
	btn_unequip.pressed.connect(func():
		StageDirector.unequip_slot(cap_slot)
		selected_inspect_instance_id = ""
		if is_instance_valid(player_ref):
			player_ref.apply_class_and_talents(false)
		refresh_ui()
		emit_signal("profile_updated")
	)
	btns_h.add_child(btn_unequip)

# ==============================================================================
# 2. EKWIPUNEK I PLECAK (Siatka HD, Filtry Slotu/Rzadkości, Sortowanie, Porównanie)
# ==============================================================================
func _build_tab_inventory_backpack() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	# Belka materiałów do ulepszeń + otwieranie skrzyni
	var top_bar := _create_subpanel(Color(0.22, 0.85, 1.0, 0.78))
	vbox.add_child(top_bar)
	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 8)
	top_bar.add_child(top_h)

	inv_materials_lbl = Label.new()
	inv_materials_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_materials_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_materials_lbl.add_theme_font_size_override("font_size", 12)
	inv_materials_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.38))
	top_h.add_child(inv_materials_lbl)

	var chest_btn := Button.new()
	chest_btn.text = "🎁 SKRZYNIA ZBR. (-80 Kr)"
	chest_btn.custom_minimum_size = Vector2(180, 34)
	chest_btn.add_theme_font_size_override("font_size", 12)
	chest_btn.pressed.connect(func():
		if StageDirector.credits < 80:
			return
		var dropped := StageDirector.roll_new_equipment_drop(StageDirector.current_stage)
		if dropped.is_empty():
			# The player must never lose credits for a failed loot roll.
			return
		StageDirector.credits -= 80
		selected_bag_instance_id = String(dropped.get("instance_id", ""))
		StageDirector.save_campaign_profile()
		refresh_ui()
		emit_signal("profile_updated")
	)
	top_h.add_child(chest_btn)
	inv_chest_btn = chest_btn

	# Pasek filtrów slotu (Wszystkie, Broń, Hełm, Pancerz, Rękawice, Buty, Artefakt)
	var filter_card := _create_subpanel()
	vbox.add_child(filter_card)
	var f_vbox := VBoxContainer.new()
	f_vbox.add_theme_constant_override("separation", 6)
	filter_card.add_child(f_vbox)

	# Seven filter buttons in one HBox overflow narrow phones.
	inv_slot_filters_grid = GridContainer.new()
	inv_slot_filters_grid.columns = 4 if StageDirector.is_portrait_mode() else 7
	inv_slot_filters_grid.add_theme_constant_override("h_separation", 4)
	inv_slot_filters_grid.add_theme_constant_override("v_separation", 4)
	f_vbox.add_child(inv_slot_filters_grid)

	var slot_filters := [
		{"id": "all", "label": "Wszystkie"},
		{"id": "weapon", "label": "Broń"},
		{"id": "helmet", "label": "Hełm"},
		{"id": "chest", "label": "Pancerz"},
		{"id": "gloves", "label": "Rękawice"},
		{"id": "boots", "label": "Buty"},
		{"id": "amulet", "label": "Artefakt"}
	]
	for sf in slot_filters:
		var sf_id: String = String(sf["id"])
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 30)
		b.add_theme_font_size_override("font_size", 11)
		b.text = String(sf["label"])
		b.pressed.connect(func():
			filter_slot = sf_id
			refresh_ui()
		)
		inv_slot_filters_grid.add_child(b)
		inv_slot_filter_btns[sf_id] = b

	# Pasek filtru rzadkości oraz sortowania
	var sort_hbox := HBoxContainer.new()
	sort_hbox.add_theme_constant_override("separation", 8)
	f_vbox.add_child(sort_hbox)

	inv_rarity_btn = Button.new()
	inv_rarity_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_rarity_btn.custom_minimum_size = Vector2(0, 30)
	inv_rarity_btn.add_theme_font_size_override("font_size", 11)
	inv_rarity_btn.pressed.connect(func():
		var order := ["all", "rare", "epic", "legendary", "mythic"]
		var idx := (order.find(filter_rarity) + 1) % order.size()
		filter_rarity = order[idx]
		refresh_ui()
	)
	sort_hbox.add_child(inv_rarity_btn)

	inv_sort_btn = Button.new()
	inv_sort_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_sort_btn.custom_minimum_size = Vector2(0, 30)
	inv_sort_btn.add_theme_font_size_override("font_size", 11)
	inv_sort_btn.pressed.connect(func():
		var s_order := ["power", "level", "rarity"]
		var idx := (s_order.find(sort_mode) + 1) % s_order.size()
		sort_mode = s_order[idx]
		refresh_ui()
	)
	sort_hbox.add_child(inv_sort_btn)

	# Siatka przedmiotów z dużymi ikonami HD i kolorowymi ramkami rzadkości
	var grid_panel := _create_subpanel()
	vbox.add_child(grid_panel)
	inv_grid = GridContainer.new()
	inv_grid.columns = 4 if StageDirector.is_portrait_mode() else 6
	inv_grid.add_theme_constant_override("h_separation", 8)
	inv_grid.add_theme_constant_override("v_separation", 8)
	grid_panel.add_child(inv_grid)

	# Panel szczegółów wybranego przedmiotu i porównania ze założonym
	inv_detail_box = _create_subpanel(Color(0.28, 0.96, 0.65, 0.85))
	vbox.add_child(inv_detail_box)

	return vbox

func _refresh_inventory_tab_ui() -> void:
	if not is_instance_valid(inv_grid):
		return
	if StageDirector.is_portrait_mode():
		inv_materials_lbl.text = "KR %d  •  ZŁOM %d  •  PLECAK %d" % [StageDirector.credits, StageDirector.scrap_materials, StageDirector.inventory.size()]
	else:
		inv_materials_lbl.text = "Materiały: %d Kredytów  |  %d Złomu Technicznego  |  Plecak: %d" % [StageDirector.credits, StageDirector.scrap_materials, StageDirector.inventory.size()]

	for sf_id in inv_slot_filter_btns.keys():
		var b: Button = inv_slot_filter_btns[sf_id]
		b.modulate = Color(0.35, 1.0, 0.68) if (String(sf_id) == filter_slot) else Color(0.82, 0.88, 0.96)

	var rar_names := {"all": "Wszystkie jakości", "rare": "Od: Rzadka+", "epic": "Od: Epicka+", "legendary": "Od: Legendarna+", "mythic": "Tylko: Mityczna"}
	inv_rarity_btn.text = "🔍 Jakość: %s" % String(rar_names.get(filter_rarity, "Wszystkie"))

	var sort_names := {"power": "Moc Bojowa ↓", "level": "Poziom Ulepszenia ↓", "rarity": "Rzadkość ↓"}
	inv_sort_btn.text = "⇅ Sortowanie: %s" % String(sort_names.get(sort_mode, "Moc Bojowa ↓"))

	for c in inv_grid.get_children():
		c.queue_free()

	var min_rar_rank: int = int(StageDirector.RARITY_ORDER.get(filter_rarity, 0))
	var filtered: Array[Dictionary] = []
	for it in StageDirector.inventory:
		if not (it is Dictionary):
			continue
		var s := String(it.get("slot", "weapon"))
		var r := String(it.get("rarity", "common"))
		var r_rank: int = int(StageDirector.RARITY_ORDER.get(r, 1))
		if filter_slot != "all" and s != filter_slot:
			continue
		if min_rar_rank > 0 and r_rank < min_rar_rank:
			continue
		filtered.append(it)

	filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if sort_mode == "level":
			var la := int(a.get("level", 0))
			var lb := int(b.get("level", 0))
			if la != lb:
				return la > lb
		elif sort_mode == "rarity":
			var ra := int(StageDirector.RARITY_ORDER.get(String(a.get("rarity", "common")), 1))
			var rb := int(StageDirector.RARITY_ORDER.get(String(b.get("rarity", "common")), 1))
			if ra != rb:
				return ra > rb
		return StageDirector.get_item_effective_power(a) > StageDirector.get_item_effective_power(b)
	)

	if selected_bag_instance_id.is_empty() and filtered.size() > 0:
		selected_bag_instance_id = String(filtered[0].get("instance_id", ""))

	for it in filtered:
		var inst_id := String(it.get("instance_id", ""))
		var slot := String(it.get("slot", "weapon"))
		var rar := String(it.get("rarity", "common"))
		var r_col: Color = StageDirector.RARITY_COLORS.get(rar, Color.WHITE)
		var lvl := int(it.get("level", 0))
		var pwr := StageDirector.get_item_effective_power(it)
		var is_eq := (String(StageDirector.equipped_items.get(slot, "")) == inst_id)
		var is_sel := (selected_bag_instance_id == inst_id)

		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(124, 114) if StageDirector.is_portrait_mode() else Vector2(148, 108)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cst := StyleBoxFlat.new()
		cst.bg_color = Color(r_col.r * 0.16, r_col.g * 0.16, r_col.b * 0.18, 0.95)
		cst.border_width_left = 3 if is_sel else 2
		cst.border_width_top = 3 if is_sel else 2
		cst.border_width_right = 3 if is_sel else 2
		cst.border_width_bottom = 3 if is_sel else 2
		cst.border_color = Color(1.0, 0.92, 0.30) if is_sel else r_col
		cst.corner_radius_top_left = 10
		cst.corner_radius_top_right = 10
		cst.corner_radius_bottom_left = 10
		cst.corner_radius_bottom_right = 10
		cst.content_margin_left = 6
		cst.content_margin_right = 6
		cst.content_margin_top = 6
		cst.content_margin_bottom = 6
		cell.add_theme_stylebox_override("panel", cst)

		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 2)
		cell.add_child(cv)

		var top_tag := Label.new()
		if StageDirector.is_portrait_mode():
			top_tag.text = "ZAŁOŻONY +%d" % lvl if is_eq else "%s +%d" % [String(StageDirector.GEAR_SLOT_NAMES.get(slot, slot)), lvl]
		else:
			top_tag.text = "✓ ZAŁOŻONO | +%d" % lvl if is_eq else "%s | +%d" % [String(StageDirector.GEAR_SLOT_NAMES.get(slot, slot)), lvl]
		top_tag.clip_text = true
		top_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		top_tag.add_theme_font_size_override("font_size", 11)
		top_tag.add_theme_color_override("font_color", Color(0.38, 1.0, 0.62) if is_eq else Color(0.78, 0.88, 1.0))
		cv.add_child(top_tag)

		var ic := TextureRect.new()
		ic.texture = AssetRegistry.get_tex(AssetRegistry.get_item_icon_path(it))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.custom_minimum_size = Vector2(40, 36) if StageDirector.is_portrait_mode() else Vector2(48, 44)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cv.add_child(ic)

		var nm := Label.new()
		nm.text = String(it.get("name", "Moduł"))
		nm.clip_text = true
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 13)
		nm.add_theme_color_override("font_color", r_col)
		cv.add_child(nm)

		var pw := Label.new()
		pw.text = "Moc: %.1f" % pwr
		pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pw.add_theme_font_size_override("font_size", 11)
		pw.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
		cv.add_child(pw)

		var click_b := Button.new()
		click_b.flat = true
		click_b.mouse_filter = Control.MOUSE_FILTER_STOP
		click_b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var cap_id: String = inst_id
		click_b.pressed.connect(func():
			selected_bag_instance_id = cap_id
			refresh_ui()
		)
		cell.add_child(click_b)
		inv_grid.add_child(cell)

	_refresh_inventory_detail_panel()

func _refresh_inventory_detail_panel() -> void:
	if not is_instance_valid(inv_detail_box):
		return
	for c in inv_detail_box.get_children():
		c.queue_free()

	var item := StageDirector.get_item_instance(selected_bag_instance_id)
	if item.is_empty():
		var l := Label.new()
		l.text = "Wybierz dowolny przedmiot z siatki powyżej, aby zobaczyć jego szczegóły, porównać statystyki i ulepszyć."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 12)
		inv_detail_box.add_child(l)
		return

	var slot_id := String(item.get("slot", "weapon"))
	var slot_title := String(StageDirector.GEAR_SLOT_NAMES.get(slot_id, slot_id))
	var rar := String(item.get("rarity", "common"))
	var r_col: Color = StageDirector.RARITY_COLORS.get(rar, Color.WHITE)
	var r_name := String(StageDirector.RARITY_NAMES.get(rar, "Zwykła"))
	var lvl := int(item.get("level", 0))
	var pwr := StageDirector.get_item_effective_power(item)
	var eq_id := String(StageDirector.equipped_items.get(slot_id, ""))
	var is_eq := (eq_id == selected_bag_instance_id)
	var eq_item := StageDirector.get_item_instance(eq_id)
	var eq_pwr := StageDirector.get_item_effective_power(eq_item)
	var diff_pwr := pwr - eq_pwr

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 6)
	inv_detail_box.add_child(root_v)

	var cmp_hbox := HBoxContainer.new()
	cmp_hbox.add_theme_constant_override("separation", 12)
	root_v.add_child(cmp_hbox)

	var ic := TextureRect.new()
	ic.texture = AssetRegistry.get_tex(AssetRegistry.get_item_icon_path(item))
	ic.custom_minimum_size = Vector2(60, 60)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cmp_hbox.add_child(ic)

	var col_left := VBoxContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.add_theme_constant_override("separation", 2)
	cmp_hbox.add_child(col_left)

	var t_lbl := Label.new()
	t_lbl.text = "%s +%d  [%s — %s]" % [String(item.get("name", "Moduł")), lvl, r_name.to_upper(), slot_title]
	t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t_lbl.add_theme_font_size_override("font_size", 13)
	t_lbl.add_theme_color_override("font_color", r_col)
	col_left.add_child(t_lbl)

	var af_parts: PackedStringArray = []
	for af in item.get("affixes", []):
		if af is Dictionary:
			af_parts.append("%s +%.1f" % [StageDirector.translate_affix(String(af.get("id", ""))), float(af.get("value", 0.0))])
	var af_txt := " | ".join(af_parts) if af_parts.size() > 0 else "Brak afiksów"

	var diff_txt := "To jest Twój aktualnie założony przedmiot w slocie %s." % slot_title if is_eq else (
		"Porównanie z założonym (%s +%d, Moc %.1f): Różnica Mocy %s%.1f" % [
			String(eq_item.get("name", "Brak")), int(eq_item.get("level", 0)), eq_pwr, "+" if diff_pwr >= 0.0 else "", diff_pwr
		]
	)

	var cost_c := 45 + lvl * 30
	var cost_s := 1 + int(lvl / 3)
	var mat_txt := "Wymagane materiały do +%d: %d Kredytów + %d Złomu (Posiadasz: %d Kr, %d Złomu)" % [
		lvl + 1, cost_c, cost_s, StageDirector.credits, StageDirector.scrap_materials
	] if lvl < 10 else "Przedmiot osiągnął maksymalny poziom ulepszenia (+10)."

	var sub_l := Label.new()
	sub_l.text = "• Moc Bojowa: %.1f  |  • Afiksy: %s\n• %s\n• %s" % [pwr, af_txt, diff_txt, mat_txt]
	sub_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_l.add_theme_font_size_override("font_size", 11)
	sub_l.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
	col_left.add_child(sub_l)

	var act_hbox := HBoxContainer.new()
	act_hbox.add_theme_constant_override("separation", 8)
	root_v.add_child(act_hbox)

	var cap_inst: String = selected_bag_instance_id
	var cap_slot: String = slot_id

	var b_eq := Button.new()
	b_eq.text = "✓ ZAŁOŻONO" if is_eq else "📥 ZAŁÓŻ DO SLOTU"
	b_eq.disabled = is_eq
	b_eq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_eq.custom_minimum_size = Vector2(0, 36)
	b_eq.add_theme_font_size_override("font_size", 12)
	b_eq.pressed.connect(func():
		StageDirector.equip_item(cap_inst)
		if is_instance_valid(player_ref):
			player_ref.apply_class_and_talents(false)
		refresh_ui()
		emit_signal("profile_updated")
	)
	act_hbox.add_child(b_eq)

	var b_up := Button.new()
	b_up.text = "⬆ ULEPSZ +1 (-%d Kr, -%d Złom)" % [cost_c, cost_s] if lvl < 10 else "MAKS. POZIOM (+10)"
	b_up.disabled = (lvl >= 10) or (StageDirector.credits < cost_c) or (StageDirector.scrap_materials < cost_s)
	b_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_up.custom_minimum_size = Vector2(0, 36)
	b_up.add_theme_font_size_override("font_size", 12)
	b_up.pressed.connect(func():
		if StageDirector.upgrade_item_by_instance(cap_inst):
			if is_instance_valid(player_ref):
				player_ref.apply_class_and_talents(false)
			refresh_ui()
			emit_signal("profile_updated")
	)
	act_hbox.add_child(b_up)

	var b_un := Button.new()
	b_un.text = "📤 ZDEJMIJ"
	b_un.disabled = not is_eq
	b_un.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_un.custom_minimum_size = Vector2(0, 36)
	b_un.add_theme_font_size_override("font_size", 12)
	b_un.pressed.connect(func():
		StageDirector.unequip_slot(cap_slot)
		if is_instance_valid(player_ref):
			player_ref.apply_class_and_talents(false)
		refresh_ui()
		emit_signal("profile_updated")
	)
	act_hbox.add_child(b_un)

# ==============================================================================
# 3. KAMPANIA 1-100 & WARSZTAT TALENTÓW
# ==============================================================================
func _build_tab_campaign_and_talents() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)

	var camp_card := _create_subpanel(Color(0.25, 0.90, 1.0, 0.80))
	vbox.add_child(camp_card)
	var c_vbox := VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 8)
	camp_card.add_child(c_vbox)

	var c_title := Label.new()
	c_title.text = "KAMPANIA 1–100"
	c_title.add_theme_font_size_override("font_size", 17)
	c_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28))
	c_vbox.add_child(c_title)

	var mid_h := HBoxContainer.new()
	mid_h.add_theme_constant_override("separation", 12)
	c_vbox.add_child(mid_h)

	stage_boss_preview = TextureRect.new()
	stage_boss_preview.custom_minimum_size = Vector2(88, 88)
	stage_boss_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_boss_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mid_h.add_child(stage_boss_preview)

	stage_info_lbl = Label.new()
	stage_info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_info_lbl.add_theme_font_size_override("font_size", 14)
	mid_h.add_child(stage_info_lbl)

	# Use a compact directional row and a separate grid for chapter shortcuts.
	# Nine buttons in one HBox can overflow the 9:16 campaign panel.
	var stage_nav := HBoxContainer.new()
	stage_nav.name = "StageDirectionRow"
	stage_nav.add_theme_constant_override("separation", 6)
	c_vbox.add_child(stage_nav)
	var stage_jump_grid := GridContainer.new()
	stage_jump_grid.name = "StageJumpGrid"
	stage_jump_grid.columns = 5
	stage_jump_grid.add_theme_constant_override("h_separation", 5)
	stage_jump_grid.add_theme_constant_override("v_separation", 4)
	c_vbox.add_child(stage_jump_grid)

	var b_prev10 := Button.new()
	b_prev10.text = "⏪ -10"
	b_prev10.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_prev10.custom_minimum_size = Vector2(0, 34)
	b_prev10.pressed.connect(func(): _select_stage(StageDirector.current_stage - 10))
	stage_nav.add_child(b_prev10)

	var b_prev1 := Button.new()
	b_prev1.text = "◀ -1"
	b_prev1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_prev1.custom_minimum_size = Vector2(0, 34)
	b_prev1.pressed.connect(func(): _select_stage(StageDirector.current_stage - 1))
	stage_nav.add_child(b_prev1)

	for s_jump in [1, 10, 30, 50, 100]:
		var target_s: int = int(s_jump)
		var jb := Button.new()
		jb.text = "%03d" % target_s
		jb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		jb.custom_minimum_size = Vector2(0, 34)
		jb.add_theme_font_size_override("font_size", 13)
		jb.pressed.connect(func(): _select_stage(target_s))
		stage_jump_grid.add_child(jb)

	var b_next1 := Button.new()
	b_next1.text = "+1 ▶"
	b_next1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_next1.custom_minimum_size = Vector2(0, 34)
	b_next1.pressed.connect(func(): _select_stage(StageDirector.current_stage + 1))
	stage_nav.add_child(b_next1)

	var b_next10 := Button.new()
	b_next10.text = "+10 ⏩"
	b_next10.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_next10.custom_minimum_size = Vector2(0, 34)
	b_next10.pressed.connect(func(): _select_stage(StageDirector.current_stage + 10))
	stage_nav.add_child(b_next10)

	var diff_row := VBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 6)
	c_vbox.add_child(diff_row)

	diff_info_lbl = Label.new()
	diff_info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_info_lbl.add_theme_font_size_override("font_size", 12)
	diff_info_lbl.add_theme_color_override("font_color", Color(0.45, 0.96, 1.0))
	diff_row.add_child(diff_info_lbl)

	var diff_cycle_btn := Button.new()
	diff_cycle_btn.text = "⚔ ZMIEŃ TRUDNOŚĆ"
	diff_cycle_btn.custom_minimum_size = Vector2(150, 34)
	diff_cycle_btn.add_theme_font_size_override("font_size", 11)
	diff_cycle_btn.pressed.connect(func():
		var idx := DIFF_ORDER.find(StageDirector.selected_difficulty_id)
		idx = (idx + 1) % DIFF_ORDER.size()
		StageDirector.selected_difficulty_id = DIFF_ORDER[idx]
		StageDirector.save_campaign_profile()
		refresh_ui()
		emit_signal("profile_updated")
	)
	diff_row.add_child(diff_cycle_btn)

	practice_check_btn = Button.new()
	practice_check_btn.custom_minimum_size = Vector2(170, 34)
	practice_check_btn.add_theme_font_size_override("font_size", 11)
	practice_check_btn.pressed.connect(func():
		StageDirector.is_practice_mode = not StageDirector.is_practice_mode
		refresh_ui()
		emit_signal("profile_updated")
	)
	diff_row.add_child(practice_check_btn)

	# Warsztat Talentów
	var t_header := Label.new()
	t_header.text = "TALENTY DOWÓDCY"
	t_header.add_theme_font_size_override("font_size", 14)
	t_header.add_theme_color_override("font_color", Color(0.35, 0.96, 1.0))
	vbox.add_child(t_header)

	for t_def in TALENT_DEFS:
		var t_id := String(t_def["id"])
		var row_card := _create_subpanel()
		vbox.add_child(row_card)
		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 10)
		row_card.add_child(row_hbox)

		var ic := TextureRect.new()
		ic.texture = AssetRegistry.get_tex(String(t_def["icon"]))
		ic.custom_minimum_size = Vector2(40, 40)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row_hbox.add_child(ic)

		var info_v := VBoxContainer.new()
		info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_hbox.add_child(info_v)

		var name_lbl := Label.new()
		name_lbl.add_theme_font_size_override("font_size", 13)
		info_v.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = String(t_def["desc"])
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.68, 0.82, 0.94))
		info_v.add_child(desc_lbl)

		var upg_btn := Button.new()
		upg_btn.custom_minimum_size = Vector2(145, 36)
		upg_btn.add_theme_font_size_override("font_size", 12)
		var b_cost: int = int(t_def["base_cost"])
		upg_btn.pressed.connect(func(): _upgrade_talent(t_id, b_cost))
		row_hbox.add_child(upg_btn)

		talent_rows[t_id] = {
			"name_lbl": name_lbl,
			"btn": upg_btn,
			"base_cost": b_cost,
			"title": String(t_def["name"])
		}

	return vbox

# ==============================================================================
# 4. PROFESJONALNY SKLEP PREMIUM (8 Sekcji w bezpiecznym trybie Sandbox)
# ==============================================================================
func _build_tab_premium_store() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	var banner := _create_subpanel(Color(1.0, 0.80, 0.22, 0.90))
	vbox.add_child(banner)
	var b_vbox := VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 4)
	banner.add_child(b_vbox)

	var b_title := Label.new()
	b_title.text = "ZBROJOWNIA • SKLEP OPERATORA"
	b_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b_title.add_theme_font_size_override("font_size", 14)
	b_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	b_vbox.add_child(b_title)

	sandbox_status_lbl = Label.new()
	sandbox_status_lbl.text = "Skórki kupujesz za kryształy. Kredyty, złom i ekwipunek zdobywasz w rozgrywce. Zakup kryształów za pieniądze jest jeszcze wyłączony."
	sandbox_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sandbox_status_lbl.add_theme_font_size_override("font_size", 11)
	sandbox_status_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	b_vbox.add_child(sandbox_status_lbl)

	var top_actions_h := HBoxContainer.new()
	top_actions_h.add_theme_constant_override("separation", 8)
	b_vbox.add_child(top_actions_h)

	free_daily_pack_btn = Button.new()
	free_daily_pack_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	free_daily_pack_btn.custom_minimum_size = Vector2(0, 44)
	free_daily_pack_btn.add_theme_font_size_override("font_size", 12)
	free_daily_pack_btn.pressed.connect(func():
		if StageDirector.claim_daily_free_shop_pack():
			sandbox_status_lbl.text = "Odebrano codzienne zaopatrzenie: +150 Kr i +5 Złomu."
			refresh_ui()
			emit_signal("profile_updated")
	)
	top_actions_h.add_child(free_daily_pack_btn)

	var odds_btn := Button.new()
	odds_btn.text = "📊 SZANSE LOSOWANIA (DROP ODDS %)"
	odds_btn.custom_minimum_size = Vector2(170, 44)
	odds_btn.add_theme_font_size_override("font_size", 11)
	odds_btn.pressed.connect(func():
		sandbox_status_lbl.text = StageDirector.get_drop_probabilities_text()
	)
	top_actions_h.add_child(odds_btn)

	# Pasek 8 kategorii sklepu
	var cats_grid := GridContainer.new()
	store_categories_grid = cats_grid
	cats_grid.columns = 4
	cats_grid.add_theme_constant_override("h_separation", 4)
	cats_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(cats_grid)

	var store_cats := [
		{"id": "all", "label": "Wszystkie"},
		{"id": "skins", "label": "Skórki"},
		{"id": "attempts", "label": "Próby"},
		{"id": "crystals", "label": "Kryształy"}
	]
	for sc in store_cats:
		var cid: String = String(sc["id"])
		var cb := Button.new()
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.custom_minimum_size = Vector2(0, 40)
		cb.add_theme_font_size_override("font_size", 12)
		cb.text = String(sc["label"])
		cb.pressed.connect(func():
			store_category_filter = cid
			refresh_ui()
		)
		cats_grid.add_child(cb)
		store_cat_btns[cid] = cb

	store_cards_grid = GridContainer.new()
	store_cards_grid.columns = 2 if StageDirector.is_portrait_mode() else 3
	store_cards_grid.add_theme_constant_override("h_separation", 8)
	store_cards_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(store_cards_grid)

	return vbox

func _refresh_store_tab_ui() -> void:
	if not is_instance_valid(store_cards_grid):
		return
	if is_instance_valid(free_daily_pack_btn):
		free_daily_pack_btn.text = "✓ ZAOPATRZENIE ODEBRANE" if StageDirector.daily_free_pack_claimed else "ODBIERZ ZAOPATRZENIE: +150 Kr, +5 Złomu"
		free_daily_pack_btn.disabled = StageDirector.daily_free_pack_claimed
	for cid in store_cat_btns.keys():
		var b: Button = store_cat_btns[cid]
		b.modulate = Color(1.0, 0.88, 0.32) if (String(cid) == store_category_filter) else Color(0.82, 0.88, 0.96)

	for c in store_cards_grid.get_children():
		c.queue_free()

	for prod in STORE_PRODUCTS:
		var p_cat := String(prod.get("category", "special"))
		if store_category_filter != "all" and p_cat != store_category_filter:
			continue

		var p_id := String(prod["id"])
		var is_once := bool(prod.get("once", false))
		var skin_unlock := String(prod.get("skin_unlock", ""))
		var already_owned := false
		if is_once and bool(StageDirector.purchased_sandbox_packs.get(p_id, false)):
			already_owned = true
		if not skin_unlock.is_empty() and StageDirector.unlocked_skins.has(skin_unlock):
			already_owned = true
		if p_id == "battle_pass_s1" and StageDirector.battle_pass_premium_unlocked:
			already_owned = true
		if p_id == "vip_pass_a03" and StageDirector.vip_sandbox_active:
			already_owned = true

		var accent: Color = prod.get("accent", Color(0.25, 0.90, 1.0))
		var card := _create_subpanel(accent)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		store_cards_grid.add_child(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)

		var cat_lbl := Label.new()
		cat_lbl.text = String(prod["category_label"])
		cat_lbl.add_theme_font_size_override("font_size", 11)
		cat_lbl.add_theme_color_override("font_color", accent)
		cv.add_child(cat_lbl)

		var top_h := HBoxContainer.new()
		top_h.add_theme_constant_override("separation", 8)
		cv.add_child(top_h)

		var ic := TextureRect.new()
		ic.texture = AssetRegistry.get_tex(String(prod["icon"]))
		ic.custom_minimum_size = Vector2(54, 58)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		top_h.add_child(ic)

		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 2)
		top_h.add_child(tv)

		var title_l := Label.new()
		title_l.text = String(prod["title"])
		title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_l.add_theme_font_size_override("font_size", 14)
		title_l.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
		tv.add_child(title_l)

		var desc_l := Label.new()
		desc_l.text = String(prod["contents"])
		desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_l.add_theme_font_size_override("font_size", 12)
		desc_l.add_theme_color_override("font_color", Color(0.76, 0.88, 0.98))
		tv.add_child(desc_l)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(0, 44)
		buy_btn.add_theme_font_size_override("font_size", 12)
		var gem_price := int(StageDirector.SKIN_GEM_PRICES.get(skin_unlock, 0))
		var is_skin := not skin_unlock.is_empty() and gem_price > 0
		var is_refill := p_id == "attempts_refill_full"
		var can_refill := is_refill and StageDirector.can_buy_full_attempts_refill()
		var can_buy_skin := is_skin and not already_owned and StageDirector.dark_matter_gems >= gem_price
		if already_owned:
			buy_btn.text = "POSIADANE"
		elif is_skin:
			buy_btn.text = "KUP ZA %d KRYSZTAŁÓW" % gem_price
		elif is_refill:
			buy_btn.text = "ODNÓW PRÓBY: %d KRYSZTAŁÓW" % StageDirector.FULL_ATTEMPTS_REFILL_GEMS
		else:
			buy_btn.text = "NIEDOSTĘPNE — W PRZYGOTOWANIU"
		buy_btn.disabled = not (can_buy_skin or can_refill)
		var cap_prod: Dictionary = prod
		buy_btn.pressed.connect(func(): _request_player_shop_purchase(cap_prod))
		cv.add_child(buy_btn)

func _setup_store_confirmation() -> void:
	store_purchase_dialog = ConfirmationDialog.new()
	store_purchase_dialog.title = "Potwierdź zakup"
	store_purchase_dialog.ok_button_text = "KUPUJĘ"
	store_purchase_dialog.cancel_button_text = "ANULUJ"
	add_child(store_purchase_dialog)
	store_purchase_dialog.confirmed.connect(_confirm_player_shop_purchase)

func _request_player_shop_purchase(prod: Dictionary) -> void:
	var skin_id := String(prod.get("skin_unlock", ""))
	var price := int(StageDirector.SKIN_GEM_PRICES.get(skin_id, 0))
	if String(prod.get("id", "")) == "attempts_refill_full":
		price = StageDirector.FULL_ATTEMPTS_REFILL_GEMS
	if price <= 0 or not is_instance_valid(store_purchase_dialog):
		return
	pending_store_purchase = prod.duplicate(true)
	store_purchase_dialog.dialog_text = "Kupić %s za %d kryształów?\nObecne saldo: %d kryształów." % [
		String(prod.get("title", "przedmiot")), price, StageDirector.dark_matter_gems
	]
	store_purchase_dialog.popup_centered(Vector2i(440, 230))

func _confirm_player_shop_purchase() -> void:
	if pending_store_purchase.is_empty():
		return
	var product := pending_store_purchase.duplicate(true)
	pending_store_purchase.clear()
	_execute_player_shop_purchase(product)

func _execute_player_shop_purchase(prod: Dictionary) -> void:
	var product_id := String(prod.get("id", ""))
	var skin_id := String(prod.get("skin_unlock", ""))
	if StageDirector.SKIN_GEM_PRICES.has(skin_id):
		if StageDirector.buy_skin_with_gems(skin_id):
			sandbox_status_lbl.text = "Zakupiono skórkę: %s." % String(prod.get("title", skin_id))
			if is_instance_valid(player_ref):
				player_ref.apply_class_and_talents(false)
		else:
			sandbox_status_lbl.text = "Zakup niemożliwy: brak kryształów lub skórka już posiadana."
	elif product_id == "attempts_refill_full":
		if StageDirector.buy_full_attempts_refill():
			sandbox_status_lbl.text = "Przywrócono 5 prób kampanii."
		else:
			sandbox_status_lbl.text = "Próby są pełne lub brakuje kryształów."
	else:
		# Real-money purchases must be verified by a future payment backend.
		# No fake purchase, free grant, or direct balance modification.
		return
	refresh_ui()
	emit_signal("profile_updated")

func _build_tab_daily_rewards() -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)

	var daily_card := _create_subpanel(Color(1.0, 0.86, 0.28, 0.85))
	vbox.add_child(daily_card)
	var d_vbox := VBoxContainer.new()
	d_vbox.add_theme_constant_override("separation", 8)
	daily_card.add_child(d_vbox)

	var d_header_h := HBoxContainer.new()
	d_vbox.add_child(d_header_h)

	var d_title := Label.new()
	d_title.text = "7 DNI NAGRÓD POWITALNYCH"
	d_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d_title.add_theme_font_size_override("font_size", 14)
	d_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
	d_header_h.add_child(d_title)

	daily_reset_lbl = Label.new()
	daily_reset_lbl.add_theme_font_size_override("font_size", 11)
	daily_reset_lbl.add_theme_color_override("font_color", Color(0.45, 0.96, 1.0))
	d_header_h.add_child(daily_reset_lbl)

	daily_grid = GridContainer.new()
	daily_grid.columns = 4 if StageDirector.is_portrait_mode() else 7
	daily_grid.add_theme_constant_override("h_separation", 8)
	daily_grid.add_theme_constant_override("v_separation", 8)
	d_vbox.add_child(daily_grid)

	# Sekcja Zadań Dziennych
	var missions_card := _create_subpanel(Color(0.28, 0.95, 0.65, 0.85))
	vbox.add_child(missions_card)
	var m_vbox := VBoxContainer.new()
	m_vbox.add_theme_constant_override("separation", 6)
	missions_card.add_child(m_vbox)

	var m_title := Label.new()
	m_title.text = "📋 ZADANIA DZIENNE DOWÓDZTWA (ODNAWIANE CO 24H)"
	m_title.add_theme_font_size_override("font_size", 13)
	m_title.add_theme_color_override("font_color", Color(0.38, 1.0, 0.68))
	m_vbox.add_child(m_title)

	daily_missions_vbox = VBoxContainer.new()
	daily_missions_vbox.add_theme_constant_override("separation", 6)
	m_vbox.add_child(daily_missions_vbox)

	var bp_card := _create_subpanel(Color(0.82, 0.45, 1.0, 0.85))
	vbox.add_child(bp_card)
	var bp_vbox := VBoxContainer.new()
	bp_vbox.add_theme_constant_override("separation", 6)
	bp_card.add_child(bp_vbox)

	bp_label = Label.new()
	bp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bp_label.add_theme_font_size_override("font_size", 13)
	bp_label.add_theme_color_override("font_color", Color(0.88, 0.62, 1.0))
	bp_vbox.add_child(bp_label)

	bp_bar = ProgressBar.new()
	bp_bar.custom_minimum_size = Vector2(0, 18)
	bp_bar.max_value = 1000.0
	bp_vbox.add_child(bp_bar)

	return vbox

func _select_stage(s_num: int) -> void:
	StageDirector.current_stage = clampi(s_num, 1, StageDirector.max_unlocked_stage)
	StageDirector.save_campaign_profile()
	refresh_ui()
	emit_signal("profile_updated")

func _upgrade_talent(talent_id: String, base_cost: int) -> void:
	var curr_lvl := int(StageDirector.talent_levels.get(talent_id, 0))
	if curr_lvl >= 10:
		return
	var cost := base_cost + curr_lvl * 35
	if StageDirector.credits < cost:
		return
	StageDirector.credits -= cost
	StageDirector.talent_levels[talent_id] = curr_lvl + 1
	StageDirector.save_campaign_profile()
	if is_instance_valid(player_ref):
		player_ref.apply_class_and_talents(false)
	refresh_ui()
	emit_signal("profile_updated")

func _create_subpanel(border_col: Color = Color(0.20, 0.58, 0.82, 0.70)) -> PanelContainer:
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.06, 0.13, 0.76)
	st.border_width_left = 1
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = border_col
	st.corner_radius_top_left = 12
	st.corner_radius_top_right = 12
	st.corner_radius_bottom_left = 12
	st.corner_radius_bottom_right = 12
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", st)
	return panel

func refresh_ui() -> void:
	if not is_inside_tree():
		return
	StageDirector.refresh_attempts()
	var cls_id := StageDirector.selected_class_id
	var cls_cfg: Dictionary = StageDirector.HERO_CLASSES.get(cls_id, StageDirector.HERO_CLASSES["soldier"])
	var skin_cfg: Dictionary = StageDirector.HERO_SKINS.get(StageDirector.selected_skin_id, StageDirector.HERO_SKINS["default"])

	currencies_lbl.text = "⚡ Kredyty: %d  |  💎 Kryształy: %d  |  🔩 Złom: %d  |  🎯 Próby: %d/5 %s" % [
		StageDirector.credits,
		StageDirector.dark_matter_gems,
		StageDirector.scrap_materials,
		StageDirector.attempts,
		"(👑 VIP)" if StageDirector.vip_sandbox_active else ""
	]

	# Tab 0: Centralny Bohater + 6 Slotów wokół niego
	var hero_tex_path := AssetRegistry.get_hero_skin_sprite(cls_id, StageDirector.selected_skin_id)
	if is_instance_valid(hero_center_tex):
		hero_center_tex.texture = AssetRegistry.get_tex(hero_tex_path)
		hero_center_tex.modulate = skin_cfg.get("tint", Color.WHITE)

	var w_inst := String(StageDirector.equipped_items.get("weapon", ""))
	var w_item := StageDirector.get_item_instance(w_inst)
	if is_instance_valid(hero_weapon_badge_tex):
		hero_weapon_badge_tex.texture = AssetRegistry.get_tex(AssetRegistry.get_item_icon_path(w_item))
	if is_instance_valid(hero_weapon_badge_lbl):
		hero_weapon_badge_lbl.text = "%s +%d" % [String(w_item.get("name", "Karabin A-03")), int(w_item.get("level", 0))] if not w_item.is_empty() else "Brak broni"

	commander_title_lbl.text = "%s — %s" % [String(cls_cfg["name"]), String(skin_cfg["name"])]
	hero_power_lbl.text = "⚔ MOC BOJOWA: %d" % StageDirector.get_total_combat_power()
	class_bonus_lbl.text = String(cls_cfg["bonus_desc"])

	var xp_req := StageDirector.get_character_xp_needed(StageDirector.character_level)
	account_lvl_lbl.text = "Poziom Konta: Lv.%d (%d/%d XP)" % [StageDirector.character_level, StageDirector.character_xp, xp_req]
	account_xp_bar.max_value = float(xp_req)
	account_xp_bar.value = float(StageDirector.character_xp)

	for cid in class_buttons.keys():
		var btn: Button = class_buttons[cid]
		btn.modulate = Color(0.38, 1.0, 0.65) if (String(cid) == cls_id) else Color(0.85, 0.90, 1.0)
	for sid in skin_buttons.keys():
		var sbtn: Button = skin_buttons[sid]
		var skin_owned := StageDirector.unlocked_skins.has(String(sid)) or String(sid) == "default"
		sbtn.disabled = not skin_owned
		sbtn.modulate = Color(1.0, 0.88, 0.35) if (String(sid) == StageDirector.selected_skin_id) else (Color(0.82, 0.88, 0.96) if skin_owned else Color(0.48, 0.51, 0.58))

	if is_instance_valid(left_slots_vbox) and is_instance_valid(right_slots_vbox):
		for c in left_slots_vbox.get_children():
			c.queue_free()
		for c in right_slots_vbox.get_children():
			c.queue_free()
		for s_left in LEFT_SLOTS:
			left_slots_vbox.add_child(_build_slot_widget(String(s_left)))
		for s_right in RIGHT_SLOTS:
			right_slots_vbox.add_child(_build_slot_widget(String(s_right)))

	_refresh_character_inspector()

	# Podsumowanie statystyk
	var eq_b := StageDirector.get_total_equipment_bonuses()
	var vit_lvl := int(StageDirector.talent_levels.get("vitality", 1))
	var fire_lvl := int(StageDirector.talent_levels.get("firepower", 1))
	var hp_val := roundf((150.0 + float(eq_b["flat_hp"])) * float(cls_cfg.get("hp_mult", 1.0)) * (1.0 + 0.06 * float(vit_lvl) + float(eq_b["hp_pct"]) * 0.01))
	var dmg_val := roundf((35.0 + float(eq_b["flat_damage"])) * float(cls_cfg.get("dmg_mult", 1.0)) * (1.0 + 0.05 * float(fire_lvl) + float(eq_b["attack_pct"]) * 0.01))
	var crit_val := roundf(((22.0 if cls_id == "scout" else 10.0) + float(eq_b["crit_chance_pct"])))
	var arm_val := roundf(float(eq_b["flat_armor"]))

	stats_summary_lbl.text = (
		"📊 ŁĄCZNE STATYSTYKI OPERATORA (Klasa + 6 Slotów RPG + Talenty):\n" +
		"• Zdrowie: %d HP (+%.0f HP, +%.1f%%)  |  • Siła Ataku: %d (+%.0f, +%.1f%%)  |  • Pancerz: +%d  |  • Krytyk: %d%%" % [
			int(hp_val), float(eq_b["flat_hp"]), float(eq_b["hp_pct"]),
			int(dmg_val), float(eq_b["flat_damage"]), float(eq_b["attack_pct"]),
			int(arm_val), int(crit_val)
		]
	)

	# Tab 1: Ekwipunek
	_refresh_inventory_tab_ui()

	# Tab 2: Kampania & Talenty
	for t_id in talent_rows.keys():
		var row: Dictionary = talent_rows[t_id]
		var lvl := int(StageDirector.talent_levels.get(t_id, 0))
		var cost := int(row["base_cost"]) + lvl * 35
		var n_lbl: Label = row["name_lbl"]
		var u_btn: Button = row["btn"]
		n_lbl.text = "%s (Poziom %d / 10)" % [String(row["title"]), lvl]
		if lvl >= 10:
			u_btn.text = "MAKS. POZIOM"
			u_btn.disabled = true
		else:
			u_btn.text = "ULEPSZ (-%d Kr)" % cost
			u_btn.disabled = StageDirector.credits < cost

	var st_cfg := StageDirector.get_stage_config(StageDirector.current_stage)
	var boss_id := String(st_cfg.get("boss_id", ""))
	var boss_tex_path := "res://assets/mutantsurvivor_ch01/bosses/hive_mother_reference.png"
	var boss_name := "Fala 10: Natarcie Elity"
	if not boss_id.is_empty():
		var b_spec: Dictionary = AssetRegistry.ENEMY_ASSETS.get(boss_id, AssetRegistry.ENEMY_ASSETS["boss_ch01"])
		boss_tex_path = String(b_spec.get("texture_path", boss_tex_path))
		boss_name = "Boss Fali 10: %s" % String(b_spec.get("display_name", boss_id))
	if is_instance_valid(stage_boss_preview):
		stage_boss_preview.texture = AssetRegistry.get_tex(boss_tex_path)

	var obj_pl := StageDirector.translate_objective(String(st_cfg.get("scene_type", "activate_terminal")))
	var haz_pl := StageDirector.translate_hazard(String(st_cfg.get("hazard", "acid_spots")))
	var rew_v2: Dictionary = st_cfg.get("rewards_v2", {})
	var r_cred := int(rew_v2.get("soft_credits", 100 + StageDirector.current_stage * 18)) if rew_v2.get("soft_credits") != null else (100 + StageDirector.current_stage * 18)
	var materials: Dictionary = rew_v2.get("materials", {}) if rew_v2.get("materials") is Dictionary else {}
	var r_scrap := int(materials.get("scrap", 2 + int(StageDirector.current_stage / 10)))
	stage_info_lbl.text = (
		"ETAP %03d/100: %s (Rozdział %d — %s)\n" % [
			StageDirector.current_stage, String(st_cfg.get("name", "Operacja")), int(st_cfg.get("chapter", 1)), String(st_cfg.get("chapter_name", "Pustkowia"))
		] +
		"• Dowódca NPC: %s  |  • Cel: %s\n" % [String(st_cfg.get("npc", "Mara")), obj_pl] +
		"• Zagrożenie: %s  |  • %s\n" % [haz_pl, boss_name] +
		"• Pierwsze ukończenie: +%d Kr, +%d Złomu i ekwipunek RPG" % [
			r_cred, r_scrap
		]
	)

	var diff_cfg := StageDirector.get_difficulty_profile()
	diff_info_lbl.text = "Trudność: %s (HP x%.2f | Nagrody x%.2f)" % [
		String(diff_cfg.get("name", "Ocalały")), float(diff_cfg.get("enemy_hp", 1.0)), float(diff_cfg.get("reward", 1.0))
	]
	if is_instance_valid(practice_check_btn):
		practice_check_btn.text = "✓ Tryb Treningowy (0 Prób)" if StageDirector.is_practice_mode else "☐ Tryb Treningowy (0 Prób)"
		practice_check_btn.modulate = Color(0.4, 1.0, 0.65) if StageDirector.is_practice_mode else Color(0.85, 0.9, 1.0)

	# Tab 3: Sklep
	_refresh_store_tab_ui()

	# Tab 4: Codzienne Nagrody
	_refresh_daily_and_bp_ui()

func _refresh_daily_and_bp_ui() -> void:
	if is_instance_valid(daily_grid):
		for c in daily_grid.get_children():
			c.queue_free()
		for r in StageDirector.DAILY_REWARDS_TABLE:
			var d_num := int(r["day"])
			var claimed := StageDirector.daily_claimed_days.has(d_num)
			var box := _create_subpanel()
			box.custom_minimum_size = Vector2(128, 108)
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var v := VBoxContainer.new()
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.add_theme_constant_override("separation", 3)
			box.add_child(v)

			var dl := Label.new()
			dl.text = "Dzień %d" % d_num
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dl.add_theme_font_size_override("font_size", 12)
			dl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25))
			v.add_child(dl)

			var rl := Label.new()
			rl.text = "+%d Kr  •  +%d Złomu" % [int(r["credits"]), int(r["scrap"])]
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rl.add_theme_font_size_override("font_size", 10)
			v.add_child(rl)

			var cb := Button.new()
			var today := int(Time.get_unix_time_from_system() / 86400)
			var claimable := not claimed and d_num == StageDirector.daily_login_day and StageDirector.last_daily_calendar_claim_day < today
			cb.text = "ODEBRANO" if claimed else ("ODBIERZ" if claimable else "ZABLOKOWANE")
			cb.disabled = not claimable
			cb.custom_minimum_size = Vector2(96, 28)
			cb.add_theme_font_size_override("font_size", 11)
			var day_cap: int = d_num
			cb.pressed.connect(func():
				StageDirector.claim_daily_reward(day_cap)
				refresh_ui()
				emit_signal("profile_updated")
			)
			v.add_child(cb)
			daily_grid.add_child(box)

	if is_instance_valid(daily_reset_lbl):
		daily_reset_lbl.text = "⏱ Reset za: %s" % StageDirector.get_daily_reset_countdown_str()

	if is_instance_valid(daily_missions_vbox):
		for c in daily_missions_vbox.get_children():
			c.queue_free()
		StageDirector._ensure_daily_missions()
		for dm in StageDirector.daily_missions:
			if not (dm is Dictionary):
				continue
			var m_id := String(dm.get("id", ""))
			var prog := int(dm.get("progress", 0))
			var target := int(dm.get("target", 1))
			var claimed := bool(dm.get("claimed", false))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			daily_missions_vbox.add_child(row)

			var title_key := "title_" + StageDirector.lang
			var m_title := String(dm.get(title_key, dm.get("title_pl", m_id)))
			var lbl := Label.new()
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.text = "• %s (%d/%d) — Nagroda: +%d Kr, +%d Złomu" % [
				m_title, prog, target, int(dm.get("credits", 150)), int(dm.get("scrap", 3))
			]
			lbl.add_theme_font_size_override("font_size", 11)
			row.add_child(lbl)

			var mb := Button.new()
			mb.custom_minimum_size = Vector2(120, 28)
			mb.add_theme_font_size_override("font_size", 11)
			mb.text = "✓ ODEBRANO" if claimed else ("ODBIERZ" if prog >= target else "W TOKU")
			mb.disabled = claimed or (prog < target)
			var cap_mid: String = m_id
			mb.pressed.connect(func():
				if StageDirector.claim_daily_mission(cap_mid):
					refresh_ui()
					emit_signal("profile_updated")
			)
			row.add_child(mb)

	if is_instance_valid(bp_label) and is_instance_valid(bp_bar):
		var tier := 1 + int(StageDirector.battle_pass_xp / 100)
		var prog := StageDirector.battle_pass_xp % 1000
		var p_tag := "[PREMIUM AKTYWNE]" if StageDirector.battle_pass_premium_unlocked else "[ŚCIEŻKA DARMOWA]"
		bp_label.text = "🏆 PRZEPUSTKA BITEWNA — Sezon 1: Mutacje | Poziom %d (%d / 1000 XP) %s" % [tier, prog, p_tag]
		bp_bar.value = float(prog)
