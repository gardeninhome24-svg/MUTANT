extends Node2D

@onready var ground_layer: Node2D = $GroundLayer
@onready var decorations_layer: Node2D = $DecorationsLayer
@onready var obstacles_layer: Node2D = $ObstaclesLayer
@onready var characters_layer: Node2D = $CharactersLayer
@onready var projectiles_layer: Node2D = $ProjectilesLayer
@onready var effects_layer: Node2D = $EffectsLayer
@onready var player: Player = $CharactersLayer/Player
@onready var hud: CanvasLayer = $HUD

# Elementy HUD
@onready var stats_card: PanelContainer = $HUD/HUDRoot/PlayerStatsCard
@onready var hp_bar: ProgressBar = $HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats/HPBar
@onready var hp_label: Label = $HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats/HPLabel
@onready var xp_bar: ProgressBar = $HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats/XPBar
@onready var run_level_label: Label = $HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats/RunLevelLabel
@onready var char_level_label: Label = $HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/AvatarBox/CharLevelLabel
@onready var chapter_label: Label = $HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats/ChapterTitle
@onready var subtitle_label: Label = $HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats/SubTitle

@onready var objectives_panel: PanelContainer = $HUD/HUDRoot/ObjectivesPanel
@onready var obj_header: Label = $HUD/HUDRoot/ObjectivesPanel/Margin/VBox/Header
@onready var obj1_label: Label = $HUD/HUDRoot/ObjectivesPanel/Margin/VBox/Obj1Label
@onready var obj2_label: Label = $HUD/HUDRoot/ObjectivesPanel/Margin/VBox/Obj2Label
@onready var obj3_label: Label = $HUD/HUDRoot/ObjectivesPanel/Margin/VBox/Obj3Label

@onready var wave_progress_box: VBoxContainer = $HUD/HUDRoot/WaveProgress
@onready var wave_label: Label = $HUD/HUDRoot/WaveProgress/WaveLabel
@onready var wave_timer_bar: ProgressBar = $HUD/HUDRoot/WaveProgress/WaveTimerBar
@onready var boss_box: VBoxContainer = $HUD/HUDRoot/WaveProgress/BossBox
@onready var boss_label: Label = $HUD/HUDRoot/WaveProgress/BossBox/BossLabel
@onready var boss_hp_bar: ProgressBar = $HUD/HUDRoot/WaveProgress/BossBox/BossHPBar

@onready var currency_bar: HBoxContainer = $HUD/HUDRoot/CurrencyBar
@onready var energy_label: Label = $HUD/HUDRoot/CurrencyBar/EnergyHBox/EnergyLabel
@onready var dark_matter_label: Label = $HUD/HUDRoot/CurrencyBar/DMHBox/DMLabel
@onready var radar_panel: PanelContainer = $HUD/HUDRoot/RadarPanel
@onready var radar: MiniRadar = $HUD/HUDRoot/RadarPanel/MiniRadar

# Kontrolki dotykowe (widoczne w trybie mobilnym 9:16 oraz przy dotyku)
@onready var joystick: MobileVirtualJoystick = $HUD/HUDRoot/VirtualJoystick
@onready var fire_btn: TextureButton = $HUD/HUDRoot/FireBtn
@onready var dash_btn: TextureButton = $HUD/HUDRoot/DashBtn

# Panele modalne
@onready var upgrade_panel: Control = $HUD/HUDRoot/UpgradePanel
@onready var cards_container: HBoxContainer = $HUD/HUDRoot/UpgradePanel/CenterContainer/VBox/UpgradeScroll/CardsContainer
@onready var reroll_btn: Button = $HUD/HUDRoot/UpgradePanel/CenterContainer/VBox/RerollBtn
@onready var death_panel: Control = $HUD/HUDRoot/DeathPanel
@onready var win_panel: Control = $HUD/HUDRoot/WinPanel
@onready var win_summary_label: Label = $HUD/HUDRoot/WinPanel/CenterContainer/VBox/SummaryLabel
@onready var premium_shop_panel: Control = $HUD/HUDRoot/PremiumShopPanel

const ENEMY_SCENES := {
	"zracy_pelzacz": preload("res://scenes/enemies/mutant_beetle.tscn"),
	"biegacz": preload("res://scenes/enemies/mutant_stalker.tscn"),
	"zdziczaly": preload("res://scenes/enemies/mutant_behemoth.tscn")
}
const EXPLOSIVE_BARREL_SCENE := preload("res://scenes/environment/explosive_barrel.tscn")
const MSWaveDirector := preload("res://addons/ms_beta/wave_director.gd")
const DEFEAT_OVERLAY_SCENE := preload("res://addons/ms_balance/ui/defeat_overlay.tscn")
const LIGHT_COOKIE := preload("res://assets/environment/flashlight_cookie.png")

const POWER_ICONS := {
	"plasma_dmg": "res://assets/mutantsurvivor_ch01/weapons/weapon_1.png",
	"plasma_cooldown": "res://assets/mutantsurvivor_ch01/icons/ammo.png",
	"vibro_saws": "res://assets/mutantsurvivor_ch01/weapons/weapon_10.png",
	"tesla_coil": "res://assets/mutantsurvivor_ch01/weapons/weapon_5.png",
	"titanium_skin": "res://assets/mutantsurvivor_ch01/icons/medkit.png",
	"bionic_speed": "res://assets/mutantsurvivor_ch01/icons/energy_cell.png",
	"magnetic_drone": "res://assets/mutantsurvivor_ch01/weapons/weapon_9.png",
	"critical_focus": "res://assets/mutantsurvivor_ch01/icons/star_badge.png",
	"energy_shield": "res://assets/mutantsurvivor_ch01/icons/shield_orb.png"
}

const WAVE_DURATION_SEC := 65.0
const TILE_SIZE := 128

var current_stage_num: int = 1
var current_wave_num: int = 1
var max_waves_in_stage: int = 10
var wave_time_left: float = WAVE_DURATION_SEC
var total_run_elapsed: float = 0.0
var spawn_timer: float = 0.0
var hazard_timer: float = 0.0
var wave_director: MSWaveDirector = null

var upgrade_tiers: Dictionary = {}
var has_used_revive: bool = false
var run_result_state: String = "active" # active / awaiting_revive / victory / failure_final
var boss_spawned_this_run: bool = false
var boss_killed_this_run: bool = false
var active_boss: MutantEnemy = null

# Cele misji (kontrakty z objective_scene_contracts.json)
var beacon_world_pos: Vector2 = Vector2(460, -280)
var primary_objective_done: bool = false
var primary_objective_type: String = "activate_terminal"
var primary_objective_progress: float = 0.0
var primary_objective_required_sec: float = 2.5
var primary_objective_hp: float = 300.0
var primary_objective_max_hp: float = 300.0
var primary_objective_area: Area2D = null
var primary_objective_ring: Sprite2D = null
var primary_objective_bar: ProgressBar = null
var data_cores_collected: int = 0
var data_cores_total: int = 3
var objective_elites_defeated: int = 0
var objective_elites_required: int = 2
var objective_steps_done: int = 0
var objective_steps_required: int = 1
var escort_destination: Vector2 = Vector2(0, -340)
var rescue_npc_freed: bool = false
var rescue_destination: Vector2 = Vector2(-500, -320)
var enemies_killed_in_run: int = 0
var solid_obstacle_positions: Array[Vector2] = []

# Rozszerzony HUD: Panel RPG, Pasek 5 Broni, 3 Przyciski Mocy, Komunikator NPC, Dziennik Dialogów
var user_profile_panel: UserProfilePanel = null
var bottom_weapons_panel: PanelContainer = null
var weapon_slots_hbox: HBoxContainer = null
var powers_hbox: HBoxContainer = null
var dash_skill_btn: Button = null
var grenade_skill_btn: Button = null
var vortex_skill_btn: Button = null
var orient_hud_btn: Button = null
var journal_hud_btn: Button = null
var profile_hud_btn: Button = null

var npc_dialogue_panel: PanelContainer = null
var npc_portrait_rect: TextureRect = null
var npc_speaker_lbl: Label = null
var npc_text_lbl: Label = null
var npc_hide_timer: float = 0.0
var _last_wave_banner_second: int = -1
var npc_dialogue_history: Array[String] = []
var npc_journal_modal: ColorRect = null
var npc_journal_lbl: Label = null
var death_summary_lbl: Label = null
var defeat_overlay_inst: Control = null

func _ready() -> void:
	get_tree().paused = false
	player.projectiles_layer = projectiles_layer
	player.effects_layer = effects_layer

	wave_director = MSWaveDirector.new()
	wave_director.name = "WaveDirector"
	add_child(wave_director)
	wave_director.bind_context(self, characters_layer, effects_layer)

	current_stage_num = StageDirector.current_stage
	_build_layered_arena(current_stage_num)
	_setup_extended_hud_and_profile()
	_style_combat_hud()
	_style_victory_overlay()

	if not StageDirector.orientation_changed.is_connected(_on_orientation_changed):
		StageDirector.orientation_changed.connect(_on_orientation_changed)

	_apply_responsive_hud_layout()
	if not get_viewport().size_changed.is_connected(_apply_responsive_hud_layout):
		get_viewport().size_changed.connect(_apply_responsive_hud_layout)
	_configure_input_mode_hud()

	update_currency_display()
	if radar:
		radar.player_ref = player
		radar.beacon_world_pos = beacon_world_pos
		radar.show_beacon = not (primary_objective_type in ["collect_item", "clear_elites", "survive_hazard", "destroy_target"])

	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)
	if not player.xp_changed.is_connected(_on_player_xp_changed):
		player.xp_changed.connect(_on_player_xp_changed)
	if not player.leveled_up.is_connected(_on_player_leveled_up):
		player.leveled_up.connect(_on_player_leveled_up)
	if not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)

	if joystick and not joystick.direction_changed.is_connected(_on_joystick_dir):
		joystick.direction_changed.connect(_on_joystick_dir)

	upgrade_panel.visible = false
	death_panel.visible = false
	win_panel.visible = false
	premium_shop_panel.visible = false

	_on_player_health_changed(player.current_health, player.max_health)
	_on_player_xp_changed(player.current_xp, player.xp_to_next_level, player.level)
	_refresh_hero_hud_avatar()
	_refresh_weapon_loadout_bar()
	start_stage(current_stage_num)

func _refresh_hero_hud_avatar() -> void:
	var avatar_rect := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/AvatarBox/Avatar") as TextureRect
	if is_instance_valid(avatar_rect):
		var cls_cfg: Dictionary = StageDirector.HERO_CLASSES.get(StageDirector.selected_class_id, StageDirector.HERO_CLASSES["soldier"])
		var skin_cfg: Dictionary = StageDirector.HERO_SKINS.get(StageDirector.selected_skin_id, StageDirector.HERO_SKINS["default"])
		avatar_rect.texture = AssetRegistry.get_tex(String(cls_cfg["sprite"]))
		avatar_rect.modulate = skin_cfg.get("tint", Color.WHITE)

func _on_orientation_changed(_is_portrait: bool) -> void:
	_apply_responsive_hud_layout()
	_configure_input_mode_hud()
	_update_objectives_ui()

func _is_compact_portrait_hud(view_width: float) -> bool:
	return StageDirector.is_portrait_mode() and view_width < 600.0

func _apply_responsive_hud_layout(view_width_override: float = -1.0) -> void:
	var portrait := StageDirector.is_portrait_mode()
	var view_width := view_width_override if view_width_override > 0.0 else get_viewport_rect().size.x
	var compact := _is_compact_portrait_hud(view_width)
	# HUD readability pass: resize real live controls for narrow phones;
	# never introduce a second HUD or alter player combat statistics.
	var hud_avatar := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/AvatarBox/Avatar") as TextureRect
	if is_instance_valid(hud_avatar):
		hud_avatar.custom_minimum_size = Vector2(32, 32) if compact else Vector2(38, 38)
	if is_instance_valid(stats_card):
		stats_card.custom_minimum_size = Vector2(195, 56) if compact else Vector2(275, 72)
	if is_instance_valid(hp_bar):
		hp_bar.custom_minimum_size = Vector2(96, 15) if compact else Vector2(176, 19)
	if is_instance_valid(xp_bar):
		xp_bar.custom_minimum_size = Vector2(96, 9) if compact else Vector2(176, 13)
	if is_instance_valid(hp_label):
		hp_label.add_theme_font_size_override("font_size", 12 if compact else 15)
	if is_instance_valid(run_level_label):
		run_level_label.add_theme_font_size_override("font_size", 12 if compact else 16)
	if is_instance_valid(wave_label):
		wave_label.add_theme_font_size_override("font_size", 16 if compact else (19 if portrait else 24))
		wave_label.clip_text = true
		wave_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		wave_label.custom_minimum_size.x = 0.0
	if is_instance_valid(wave_progress_box):
		wave_progress_box.custom_minimum_size.x = 0.0
	if is_instance_valid(boss_label):
		boss_label.add_theme_font_size_override("font_size", 11 if compact else 13)
	if is_instance_valid(obj_header):
		obj_header.add_theme_font_size_override("font_size", 13 if compact else 19)
		obj_header.clip_text = true
		obj_header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		obj_header.text = ("CELE • ETAP %03d" if compact else "◆ CELE MISJI (ETAP %03d)") % current_stage_num
	for mission_text in [obj1_label, obj2_label, obj3_label]:
		if is_instance_valid(mission_text):
			mission_text.add_theme_font_size_override("font_size", 12 if compact else 17)
			mission_text.clip_text = true
			mission_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if is_instance_valid(weapon_slots_hbox):
		weapon_slots_hbox.add_theme_constant_override("separation", 3 if compact else 6)
	if is_instance_valid(radar_panel):
		radar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		radar_panel.custom_minimum_size = Vector2.ZERO
		# Fit the minimap inside its 420px slot; the previous 144px child
		# minimum expanded the panel beyond its anchors into other HUD panels.
		var radar_view := radar_panel.get_node_or_null("MiniRadar") as MiniRadar
		if is_instance_valid(radar_view):
			radar_view.radar_size = Vector2(86, 86) if compact else (Vector2(132, 110) if portrait else Vector2(140, 110))
			radar_view.custom_minimum_size = radar_view.radar_size
			radar_view.queue_redraw()
	if is_instance_valid(npc_portrait_rect):
		npc_portrait_rect.custom_minimum_size = Vector2(38, 46) if compact else Vector2(42, 48)
	if is_instance_valid(npc_speaker_lbl):
		npc_speaker_lbl.add_theme_font_size_override("font_size", 14 if compact else 13)
	if is_instance_valid(npc_text_lbl):
		npc_text_lbl.add_theme_font_size_override("font_size", 14 if compact else 13)
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		# 0.92 camera zoom made every already-small mutant shrink further.
		# Keep the combat readable, without changing collisions/spawn geometry.
		cam.zoom = Vector2(1.10, 1.10) if portrait else Vector2(1.0, 1.0)

	if is_instance_valid(orient_hud_btn):
		orient_hud_btn.text = "9:16" if portrait else "16:9"
		orient_hud_btn.custom_minimum_size = Vector2(48, 28) if portrait else Vector2(64, 30)
		orient_hud_btn.visible = not portrait
	if is_instance_valid(journal_hud_btn):
		journal_hud_btn.text = "DZIENNIK" if not portrait else "LOG"
		journal_hud_btn.custom_minimum_size = Vector2(48, 28) if portrait else Vector2(78, 30)
		journal_hud_btn.visible = not portrait
	if is_instance_valid(profile_hud_btn):
		profile_hud_btn.text = "RPG"
		profile_hud_btn.custom_minimum_size = Vector2(48, 28) if portrait else Vector2(68, 30)
		profile_hud_btn.visible = not portrait
	if is_instance_valid(currency_bar):
		currency_bar.add_theme_constant_override("separation", (3 if compact else 8) if portrait else 18)
		for coin_group in [get_node_or_null("HUD/HUDRoot/CurrencyBar/EnergyHBox"), get_node_or_null("HUD/HUDRoot/CurrencyBar/DMHBox")]:
			if coin_group is HBoxContainer:
				coin_group.add_theme_constant_override("separation", 3 if portrait else 6)
				var icon_rect := coin_group.get_node_or_null("Icon") as TextureRect
				if icon_rect:
					icon_rect.custom_minimum_size = Vector2(24, 24) if portrait else Vector2(28, 28)
		for lbl in [energy_label, dark_matter_label]:
			if lbl:
				lbl.add_theme_font_size_override("font_size", (12 if compact else 14) if portrait else 16)
	if is_instance_valid(chapter_label):
		chapter_label.clip_text = true
		chapter_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if is_instance_valid(subtitle_label):
		subtitle_label.clip_text = true
		subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	# Dopasowanie okien modalnych (UpgradePanel, WinPanel, DeathPanel) do szerokości 720px w pionie 9:16
	if is_instance_valid(cards_container):
		cards_container.add_theme_constant_override("separation", 8 if portrait else 20)
	var upgrade_scroll := get_node_or_null("HUD/HUDRoot/UpgradePanel/CenterContainer/VBox/UpgradeScroll") as ScrollContainer
	if is_instance_valid(upgrade_scroll):
		# A 650px scroll strip clipped the last card at 720px. Use the
		# full safe width and keep horizontal swipe only for narrow phones.
		upgrade_scroll.custom_minimum_size = Vector2(
			minf(696.0, maxf(252.0, view_width - 18.0)) if portrait else 760.0,
			404.0 if portrait else 367.0
		)
		upgrade_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var up_vbox := get_node_or_null("HUD/HUDRoot/UpgradePanel/CenterContainer/VBox") as VBoxContainer
	if is_instance_valid(up_vbox):
		up_vbox.add_theme_constant_override("separation", 15 if portrait else 20)
	var up_title := get_node_or_null("HUD/HUDRoot/UpgradePanel/CenterContainer/VBox/Title") as Label
	if is_instance_valid(up_title):
		up_title.add_theme_font_size_override("font_size", (21 if compact else 30) if portrait else 29)
		up_title.text = "WYBIERZ ULEPSZENIE" if portrait else "AWANS! WYBIERZ MODUŁ BOJOWY"
	# The legacy result screen used unbounded text over the full arena.
	# Keep a real centered gold-trimmed report with its summary and real actions.
	var vp_height := get_viewport_rect().size.y
	var victory_width := minf(800.0, maxf(300.0, view_width - 28.0))
	var victory_height := minf(640.0 if portrait else 530.0, maxf(400.0, vp_height - 28.0))
	var victory_frame := get_node_or_null("HUD/HUDRoot/WinPanel/VictoryFrame") as Panel
	if is_instance_valid(victory_frame):
		victory_frame.set_anchors_preset(Control.PRESET_CENTER)
		victory_frame.offset_left = -victory_width * 0.5
		victory_frame.offset_right = victory_width * 0.5
		victory_frame.offset_top = -victory_height * 0.5
		victory_frame.offset_bottom = victory_height * 0.5
	var victory_vbox := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox") as VBoxContainer
	if is_instance_valid(victory_vbox):
		victory_vbox.custom_minimum_size.x = victory_width - (38.0 if compact else 70.0)
		victory_vbox.add_theme_constant_override("separation", 18 if portrait else 24)
	var win_title := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox/Title") as Label
	if is_instance_valid(win_title):
		win_title.add_theme_font_size_override("font_size", (23 if compact else 31) if portrait else 36)
		win_title.text = "ETAP UKOŃCZONY"
	var summary := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox/SummaryLabel") as Label
	if is_instance_valid(summary):
		summary.custom_minimum_size.x = victory_width - (42.0 if compact else 80.0)
		summary.add_theme_font_size_override("font_size", (14 if compact else 18) if portrait else 18)
	for btn_path in ["HUD/HUDRoot/WinPanel/CenterContainer/VBox/NextStageBtn", "HUD/HUDRoot/WinPanel/CenterContainer/VBox/RestartBtn"]:
		var victory_button := get_node_or_null(btn_path) as Button
		if is_instance_valid(victory_button):
			victory_button.custom_minimum_size = Vector2(minf(410.0, victory_width - 64.0), 54.0 if compact else 62.0)
	var death_title := get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/Title") as Label
	if is_instance_valid(death_title):
		death_title.add_theme_font_size_override("font_size", 20 if portrait else 32)
		death_title.text = "MISJA NIEUDANA" if portrait else "ODDZIAŁ ZOSTAŁ PRZEŁAMANY"

	for path in ["HUD/HUDRoot/WinPanel/CenterContainer/VBox", "HUD/HUDRoot/DeathPanel/CenterContainer/VBox"]:
		var modal_vbox := get_node_or_null(path) as VBoxContainer
		if modal_vbox:
			modal_vbox.add_theme_constant_override("separation", 10 if portrait else 18)
	var revive_hbox := get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox") as HBoxContainer
	if revive_hbox:
		revive_hbox.add_theme_constant_override("separation", 8 if portrait else 20)
	for path in ["HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox/ReviveAdBtn", "HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox/ReviveDMBtn"]:
		var revive_btn := get_node_or_null(path) as Button
		if revive_btn:
			revive_btn.custom_minimum_size = Vector2(160, 44) if portrait else Vector2(210, 48)
			revive_btn.add_theme_font_size_override("font_size", 11 if portrait else 14)
	var safe_top := StageDirector.get_safe_top_margin()

	if portrait:
		# UKŁAD PIONOWY 9:16 (Zoptymalizowany, kompaktowy HUD sci-fi — 80%+ pola bitwy wolne)
		if stats_card:
			stats_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
			stats_card.offset_left = 10.0
			stats_card.offset_top = 8.0 + safe_top
			stats_card.offset_right = 205.0
			stats_card.offset_bottom = (64.0 if compact else 85.0) + safe_top
		if currency_bar:
			currency_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			currency_bar.offset_left = -minf(395.0, view_width - 20.0) if compact else -302.0
			currency_bar.offset_top = (193.0 if compact else 8.0) + safe_top
			currency_bar.offset_right = -10.0
			currency_bar.offset_bottom = (227.0 if compact else 45.0) + safe_top
		if wave_progress_box:
			wave_progress_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
			wave_progress_box.offset_left = -110.0 if compact else -115.0
			wave_progress_box.offset_top = (242.0 if compact else 110.0) + safe_top
			wave_progress_box.offset_right = 110.0 if compact else 115.0
			wave_progress_box.offset_bottom = (292.0 if compact else 196.0) + safe_top
		if objectives_panel:
			objectives_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
			objectives_panel.offset_left = 10.0
			objectives_panel.offset_top = (80.0 if compact else 213.0) + safe_top
			objectives_panel.offset_right = 205.0 if compact else 304.0
			objectives_panel.offset_bottom = (181.0 if compact else 390.0) + safe_top
		if radar_panel:
			radar_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			radar_panel.offset_left = -108.0 if compact else -166.0
			radar_panel.offset_top = (75.0 if compact else 120.0) + safe_top
			radar_panel.offset_right = -10.0
			radar_panel.offset_bottom = (178.0 if compact else 258.0) + safe_top
		if bottom_weapons_panel:
			bottom_weapons_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			bottom_weapons_panel.offset_left = 12.0 if compact else maxf(185.0, (view_width - 360.0) * 0.5)
			bottom_weapons_panel.offset_top = -128.0 if compact else -110.0
			bottom_weapons_panel.offset_right = 260.0 if compact else minf(view_width - 115.0, (view_width + 360.0) * 0.5)
			bottom_weapons_panel.offset_bottom = -78.0 if compact else -30.0
		if powers_hbox:
			powers_hbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			powers_hbox.offset_left = -355.0 if not compact else -330.0
			powers_hbox.offset_top = -74.0
			powers_hbox.offset_right = -12.0
			powers_hbox.offset_bottom = -12.0
		if joystick:
			joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			joystick.offset_left = 20.0
			joystick.offset_top = -300.0 if compact else -228.0
			joystick.offset_right = 152.0
			joystick.offset_bottom = -168.0 if compact else -96.0
		if fire_btn:
			fire_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			fire_btn.offset_left = -150.0
			fire_btn.offset_top = -220.0
			fire_btn.offset_right = -24.0
			fire_btn.offset_bottom = -94.0
		if dash_btn:
			dash_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			dash_btn.offset_left = -245.0
			dash_btn.offset_top = -195.0
			dash_btn.offset_right = -165.0
			dash_btn.offset_bottom = -115.0
		if npc_dialogue_panel:
			# Briefing no longer masks the mission checklist and minimap.
			npc_dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			npc_dialogue_panel.offset_left = -minf(220.0, view_width * 0.5 - 14.0)
			npc_dialogue_panel.offset_right = minf(220.0, view_width * 0.5 - 14.0)
			# Compact phones place the movement joystick at -300..-168px.
			# The previous -316..-239px radio panel overlapped that touch area.
			# Move compact briefings above the touch-control zone.
			npc_dialogue_panel.offset_top = -460.0 if compact else -316.0
			npc_dialogue_panel.offset_bottom = -383.0 if compact else -239.0
	else:
		# UKŁAD POZIOMY 16:9 (PC / TABLET LANDSCAPE — bez nakładania paska fali i walut)
		if stats_card:
			stats_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
			stats_card.offset_left = 16.0
			stats_card.offset_top = 14.0
			stats_card.offset_right = 396.0
			stats_card.offset_bottom = 132.0
		if objectives_panel:
			objectives_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
			objectives_panel.offset_left = 16.0
			objectives_panel.offset_top = 142.0
			objectives_panel.offset_right = 380.0
			objectives_panel.offset_bottom = 264.0
		if wave_progress_box:
			wave_progress_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
			wave_progress_box.offset_left = -185.0
			wave_progress_box.offset_top = 14.0
			wave_progress_box.offset_right = 135.0
			wave_progress_box.offset_bottom = 104.0
		if currency_bar:
			currency_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			currency_bar.offset_left = -425.0
			currency_bar.offset_top = 14.0
			currency_bar.offset_right = -16.0
			currency_bar.offset_bottom = 54.0
		if radar_panel:
			radar_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			radar_panel.offset_left = -156.0
			radar_panel.offset_top = 64.0
			radar_panel.offset_right = -16.0
			radar_panel.offset_bottom = 204.0
		if bottom_weapons_panel:
			bottom_weapons_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			bottom_weapons_panel.offset_left = 18.0
			bottom_weapons_panel.offset_top = -82.0
			bottom_weapons_panel.offset_right = 374.0
			bottom_weapons_panel.offset_bottom = -14.0
		if powers_hbox:
			powers_hbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			powers_hbox.offset_left = -440.0
			powers_hbox.offset_top = -76.0
			powers_hbox.offset_right = -18.0
			powers_hbox.offset_bottom = -14.0
		if npc_dialogue_panel:
			npc_dialogue_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			npc_dialogue_panel.offset_left = -290.0
			npc_dialogue_panel.offset_top = -172.0
			npc_dialogue_panel.offset_right = 290.0
			npc_dialogue_panel.offset_bottom = -92.0

	# The currency frame tracks the actual responsive currency bar.
	var wallet_frame := get_node_or_null("HUD/HUDRoot/CurrencyFrame") as Panel
	if is_instance_valid(wallet_frame) and is_instance_valid(currency_bar):
		wallet_frame.anchor_left = currency_bar.anchor_left
		wallet_frame.anchor_right = currency_bar.anchor_right
		wallet_frame.anchor_top = currency_bar.anchor_top
		wallet_frame.anchor_bottom = currency_bar.anchor_bottom
		wallet_frame.offset_left = currency_bar.offset_left - 8.0
		wallet_frame.offset_top = currency_bar.offset_top - 5.0
		wallet_frame.offset_right = currency_bar.offset_right + 8.0
		wallet_frame.offset_bottom = currency_bar.offset_bottom + 5.0

	# Sync the cyan background AFTER its VBox has received final anchors.
	# The earlier ordering aligned it to stale editor offsets, causing a giant
	# empty frame across the entire top of the 720x1280 combat screenshot.
	var wave_frame := get_node_or_null("HUD/HUDRoot/WaveFrame") as Panel
	if is_instance_valid(wave_frame) and is_instance_valid(wave_progress_box):
		wave_frame.anchor_left = wave_progress_box.anchor_left
		wave_frame.anchor_right = wave_progress_box.anchor_right
		wave_frame.anchor_top = wave_progress_box.anchor_top
		wave_frame.anchor_bottom = wave_progress_box.anchor_bottom
		wave_frame.offset_left = wave_progress_box.offset_left - 6.0
		wave_frame.offset_top = wave_progress_box.offset_top - 5.0
		wave_frame.offset_right = wave_progress_box.offset_right + 6.0
		wave_frame.offset_bottom = wave_progress_box.offset_bottom + 5.0


func _style_victory_overlay() -> void:
	# Match the approved cyan/steel UI with a single gold victory card.
	# All data and actions remain real Godot controls, not baked-in artwork.
	if not is_instance_valid(win_panel):
		return
	win_panel.color = Color(0.014, 0.025, 0.038, 0.84)
	var frame := win_panel.get_node_or_null("VictoryFrame") as Panel
	if not is_instance_valid(frame):
		frame = Panel.new()
		frame.name = "VictoryFrame"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		win_panel.add_child(frame)
		win_panel.move_child(frame, 0)
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(0.017, 0.046, 0.067, 0.985)
	skin.border_color = Color(0.93, 0.74, 0.25, 0.97)
	skin.set_border_width_all(3)
	skin.set_corner_radius_all(13)
	skin.shadow_color = Color(0.0, 0.0, 0.0, 0.77)
	skin.shadow_size = 24
	frame.add_theme_stylebox_override("panel", skin)
	var title_label := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox/Title") as Label
	if is_instance_valid(title_label):
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_color_override("font_color", Color(1.0, 0.83, 0.32))
		title_label.add_theme_color_override("font_outline_color", Color(0.08, 0.035, 0.01))
		title_label.add_theme_constant_override("outline_size", 4)
	if is_instance_valid(win_summary_label):
		win_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		win_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		win_summary_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.99))
		win_summary_label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.04))
		win_summary_label.add_theme_constant_override("outline_size", 2)
	var next_btn := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox/NextStageBtn") as Button
	var retry_btn := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox/RestartBtn") as Button
	if is_instance_valid(next_btn):
		SurvivorVisualSystem.decorate_metal_button(next_btn, SurvivorVisualSystem.GOLD, 62.0)
		next_btn.add_theme_font_size_override("font_size", 17)
	if is_instance_valid(retry_btn):
		SurvivorVisualSystem.decorate_metal_button(retry_btn, SurvivorVisualSystem.CYAN, 56.0)
		retry_btn.add_theme_font_size_override("font_size", 16)


func _style_combat_hud() -> void:
	# Shared dark, low-noise visual treatment for the actual in-combat HUD.
	# Retain the existing node tree, mechanics and landscape layout.
	for panel in [stats_card, objectives_panel, radar_panel]:
		if not is_instance_valid(panel):
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.009, 0.025, 0.048, 0.94)
		style.border_color = Color(0.12, 0.80, 1.0, 0.91)
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.set_content_margin_all(7.0)
		panel.add_theme_stylebox_override("panel", style)
	# The reference uses a segmented metal avatar/HP/XP shell,
	# not a plain rounded rectangle around all three widgets.
	var stats_skin_path := "res://assets/ui/approved/combat_stats_frame.svg"
	if is_instance_valid(stats_card) and ResourceLoader.exists(stats_skin_path, "Texture2D"):
		var stats_skin := StyleBoxTexture.new()
		stats_skin.texture = load(stats_skin_path) as Texture2D
		stats_skin.texture_margin_left = 86.0
		stats_skin.texture_margin_right = 42.0
		stats_skin.texture_margin_top = 22.0
		stats_skin.texture_margin_bottom = 22.0
		stats_card.add_theme_stylebox_override("panel", stats_skin)

	# CurrencyBar is an HBoxContainer: adding a theme style directly to it
	# draws nothing. Give it a real Panel behind the live amounts/icons.
	if is_instance_valid(currency_bar):
		var hud_base := $HUD/HUDRoot
		var wallet_frame := hud_base.get_node_or_null("CurrencyFrame") as Panel
		if wallet_frame == null:
			wallet_frame = Panel.new()
			wallet_frame.name = "CurrencyFrame"
			wallet_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud_base.add_child(wallet_frame)
			hud_base.move_child(wallet_frame, 0)
		var wallet_art_path := "res://assets/ui/approved/combat_wallet_frame.svg"
		if ResourceLoader.exists(wallet_art_path, "Texture2D"):
			var wallet_skin := StyleBoxTexture.new()
			wallet_skin.texture = load(wallet_art_path) as Texture2D
			wallet_skin.texture_margin_left = 28.0
			wallet_skin.texture_margin_right = 28.0
			wallet_skin.texture_margin_top = 18.0
			wallet_skin.texture_margin_bottom = 18.0
			wallet_frame.add_theme_stylebox_override("panel", wallet_skin)
	if is_instance_valid(wave_label):
		wave_label.add_theme_font_size_override("font_size", 21)
		wave_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
		wave_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.07))
		wave_label.add_theme_constant_override("outline_size", 3)
	if is_instance_valid(wave_timer_bar):
		wave_timer_bar.custom_minimum_size = Vector2(0, 8)
		wave_timer_bar.show_percentage = false
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.08, 0.14, 0.20, 0.96)
		track.set_corner_radius_all(4)
		wave_timer_bar.add_theme_stylebox_override("background", track)
		var timer_fill := StyleBoxFlat.new()
		timer_fill.bg_color = Color(0.97, 0.73, 0.25)
		timer_fill.set_corner_radius_all(4)
		wave_timer_bar.add_theme_stylebox_override("fill", timer_fill)
	if is_instance_valid(boss_hp_bar):
		boss_hp_bar.custom_minimum_size = Vector2(0, 10)
		boss_hp_bar.show_percentage = false
		var boss_fill := StyleBoxFlat.new()
		boss_fill.bg_color = Color(0.96, 0.20, 0.34)
		boss_fill.set_corner_radius_all(4)
		boss_hp_bar.add_theme_stylebox_override("fill", boss_fill)
	if is_instance_valid(radar_panel):
		radar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(objectives_panel):
		objectives_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for status_label in [hp_label, run_level_label, obj1_label, obj2_label, obj3_label]:
		if is_instance_valid(status_label):
			status_label.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.06, 0.92))
			status_label.add_theme_constant_override("outline_size", 2)
	if is_instance_valid(hp_bar):
		var health_fill := StyleBoxFlat.new()
		health_fill.bg_color = Color(0.14, 0.95, 0.38)
		health_fill.set_corner_radius_all(5)
		hp_bar.add_theme_stylebox_override("fill", health_fill)
	if is_instance_valid(xp_bar):
		var xp_fill := StyleBoxFlat.new()
		xp_fill.bg_color = Color(0.08, 0.83, 1.0)
		xp_fill.set_corner_radius_all(4)
		xp_bar.add_theme_stylebox_override("fill", xp_fill)
	# WaveProgress is a VBoxContainer, not a PanelContainer. Put a real
	# decorative Panel BEHIND it so the cyan timer framing is actually rendered.
	if is_instance_valid(wave_progress_box):
		var hud_root: Control = $HUD/HUDRoot
		var wave_backdrop := hud_root.get_node_or_null("WaveFrame") as Panel
		if wave_backdrop == null:
			wave_backdrop = Panel.new()
			wave_backdrop.name = "WaveFrame"
			wave_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud_root.add_child(wave_backdrop)
			hud_root.move_child(wave_backdrop, 0)
		var wave_style := StyleBoxFlat.new()
		wave_style.bg_color = Color(0.009, 0.027, 0.052, 0.92)
		wave_style.border_color = Color(0.22, 0.81, 1.0, 0.92)
		wave_style.set_border_width_all(2)
		wave_style.set_corner_radius_all(9)
		wave_backdrop.add_theme_stylebox_override("panel", wave_style)
	# Production artwork: use real scalable 9-slice metal trims, while
	# status labels, bars and input remain actual live Godot Controls.
	var themed_panels: Array = [
		[objectives_panel, "res://assets/ui/approved/combat_objectives_frame.svg", 27.0, 26.0],
		[radar_panel, "res://assets/ui/approved/combat_radar_frame.svg", 33.0, 33.0],
		[bottom_weapons_panel, "res://assets/ui/approved/combat_inventory_frame.svg", 27.0, 25.0],
		[$HUD/HUDRoot/WaveFrame, "res://assets/ui/approved/combat_wave_frame.svg", 41.0, 24.0]
	]
	for themed in themed_panels:
		var target_node: PanelContainer = themed[0] as PanelContainer
		if themed[0] is Panel and not (themed[0] is PanelContainer):
			var wave_node: Panel = themed[0] as Panel
			if ResourceLoader.exists(String(themed[1]), "Texture2D"):
				var wave_art := StyleBoxTexture.new()
				wave_art.texture = load(String(themed[1])) as Texture2D
				wave_art.texture_margin_left = float(themed[2])
				wave_art.texture_margin_right = float(themed[2])
				wave_art.texture_margin_top = float(themed[3])
				wave_art.texture_margin_bottom = float(themed[3])
				wave_node.add_theme_stylebox_override("panel", wave_art)
		elif is_instance_valid(target_node) and ResourceLoader.exists(String(themed[1]), "Texture2D"):
			var art := StyleBoxTexture.new()
			art.texture = load(String(themed[1])) as Texture2D
			art.texture_margin_left = float(themed[2])
			art.texture_margin_right = float(themed[2])
			art.texture_margin_top = float(themed[3])
			art.texture_margin_bottom = float(themed[3])
			target_node.add_theme_stylebox_override("panel", art)

	var reroll := get_node_or_null("HUD/HUDRoot/UpgradePanel/CenterContainer/VBox/RerollBtn") as Button
	if is_instance_valid(reroll):
		reroll.custom_minimum_size = Vector2(320.0, 60.0)
		reroll.add_theme_font_size_override("font_size", 17)
		var reroll_normal := StyleBoxFlat.new()
		reroll_normal.bg_color = Color(0.019, 0.080, 0.125, 0.97)
		reroll_normal.border_color = Color(0.14, 0.80, 0.98)
		reroll_normal.set_border_width_all(2)
		reroll_normal.set_corner_radius_all(10)
		reroll_normal.set_content_margin_all(12)
		reroll.add_theme_stylebox_override("normal", reroll_normal)
		var reroll_hover := reroll_normal.duplicate() as StyleBoxFlat
		reroll_hover.bg_color = Color(0.085, 0.24, 0.33)
		reroll.add_theme_stylebox_override("hover", reroll_hover)
		reroll.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	var upgrade_shade := get_node_or_null("HUD/HUDRoot/UpgradePanel") as ColorRect
	if is_instance_valid(upgrade_shade):
		upgrade_shade.color = Color(0.008, 0.020, 0.038, 0.50)

	if is_instance_valid(stats_card):
		stats_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_joystick_dir(dir: Vector2) -> void:
	if is_instance_valid(player):
		# Ignore touches behind overlays that pause or replace combat input.
		if upgrade_panel.visible or death_panel.visible or win_panel.visible or (is_instance_valid(user_profile_panel) and user_profile_panel.visible):
			player.external_move_dir = Vector2.ZERO
		else:
			player.external_move_dir = dir

func _configure_input_mode_hud() -> void:
	# W trybie Pionowym 9:16 (Android/iOS) wirtualny joystick i przyciski dotykowe są zawsze aktywne!
	var is_touch := DisplayServer.is_touchscreen_available() or StageDirector.is_portrait_mode()
	_set_touch_controls_visible(is_touch)

func _set_touch_controls_visible(vis: bool) -> void:
	var show_mobile := vis or StageDirector.is_portrait_mode()
	if joystick:
		joystick.visible = show_mobile
	# Zgodnie z P0-08: Move-Only sterowanie - ukrywamy przyciski manualnego ognia i skilli
	if fire_btn:
		fire_btn.visible = false
	if dash_btn:
		dash_btn.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_touch_controls_visible(true)
	elif event is InputEventKey and event.pressed and not event.echo:
		_set_touch_controls_visible(false)
		var key_ev := event as InputEventKey
		if key_ev.keycode == KEY_TAB:
			toggle_user_profile_panel()

## Buduje wielowarstwową arenę dopasowaną do 1 z 5 biomów (Stages 1..100)
func _build_layered_arena(stage_num: int) -> void:
	for c in ground_layer.get_children():
		c.queue_free()
	for c in decorations_layer.get_children():
		c.queue_free()
	for c in obstacles_layer.get_children():
		c.queue_free()
	solid_obstacle_positions.clear()

	var cfg := StageDirector.get_stage_config(stage_num)
	var biome_id := String(cfg.get("biome", "wasteland"))
	var palette: Dictionary = AssetRegistry.BIOME_PALETTES.get(biome_id, AssetRegistry.BIOME_PALETTES["wasteland"])
	var biome_tiles: Array = palette.get("tiles", ["cracked_concrete", "concrete_clean"])
	var border_tile := String(palette.get("border_tile", "warning_stripes"))
	var tint: Color = palette.get("ambient_tint", Color.WHITE)

	var base_tiles := ["concrete_clean", "dark_slab", "floor_dark", "floor_grid"]
	var cracked_tiles := ["cracked_concrete", "concrete_fracture", "concrete_rubble", "broken_stone", "floor_cracks"]
	var grate_tiles := ["metal_grate", "steel_grate", "rusted_plate", "rust_plates", "bolted_tile"]
	var hazard_tiles := ["warning_stripes", "acid_pit_glow", "toxic_pool", "scorched_floor", "reactor_tile"]

	if biome_id == "cryo_lab":
		base_tiles = ["cryo_tile", "concrete_clean", "lab_panel_clean"]
		cracked_tiles = ["broken_stone", "floor_cracks"]
		grate_tiles = ["bolted_tile", "metal_grate"]
		hazard_tiles = ["cryo_tile", "warning_stripes"]
	elif biome_id == "toxic_sewers":
		base_tiles = ["mossy_concrete", "dark_slab"]
		cracked_tiles = ["cracked_concrete", "concrete_fracture"]
		grate_tiles = ["rusted_plate", "metal_grate"]
		hazard_tiles = ["acid_pit_glow", "toxic_pool"]
	elif biome_id == "abandoned_city":
		# Ruined streets use fractured masonry and burnt paving, not the
		# industrial-laboratory default tile palette.
		base_tiles = ["broken_stone", "concrete_rubble", "scorched_floor"]
		cracked_tiles = ["floor_cracks", "concrete_fracture", "cracked_concrete"]
		grate_tiles = ["rusted_plate", "bolted_tile"]
		hazard_tiles = ["scorched_floor", "warning_stripes"]
	elif biome_id == "reactor":
		# The final reactor chapters have a distinct high-contrast floor
		# language without adding expensive runtime geometry.
		base_tiles = ["reactor_tile", "cryo_tile", "bolted_tile"]
		cracked_tiles = ["concrete_fracture", "floor_cracks"]
		grate_tiles = ["metal_grate", "steel_grate"]
		hazard_tiles = ["reactor_tile", "warning_stripes", "acid_pit_glow"]

	var cols := 26
	var rows := 22
	var start_x := -int(cols / 2) * TILE_SIZE
	var start_y := -int(rows / 2) * TILE_SIZE

	for r in range(rows):
		for c in range(cols):
			var tile_name: String
			var is_edge := (r == 0 or r == rows - 1 or c == 0 or c == cols - 1)
			var is_near_edge := (r == 1 or r == rows - 2 or c == 1 or c == cols - 2)

			if is_edge:
				tile_name = "warning_stripes" if (r + c) % 3 == 0 else "rusted_plate"
			elif is_near_edge and (r + c) % 4 == 0:
				tile_name = "warning_stripes"
			else:
				# Large random-pattern checkerboards look unlike the approved
				# industrial battlefield. Keep an intact metal floor as the
				# dominant material and group rust, fractures and acid into
				# coherent 3x3 sections instead of one-cell confetti.
				var sector_x: int = int(c / 3)
				var sector_y: int = int(r / 3)
				var patch: int = absi((sector_x * 1637) ^ (sector_y * 8191) ^ (stage_num * 7919)) % 100
				var detail: int = absi((r * 73 + c * 47 + stage_num * 101)) % 17
				var h: int = clampi(int(float(patch) * 0.85) + detail, 0, 99)
				if h < 66:
					tile_name = base_tiles[(r + sector_x * 3 + stage_num) % base_tiles.size()]
				elif h < 88:
					tile_name = cracked_tiles[(r + c + sector_y) % cracked_tiles.size()]
				elif h < 97:
					tile_name = grate_tiles[(r * 2 + c + sector_x) % grate_tiles.size()]
				else:
					tile_name = hazard_tiles[(r + c + stage_num) % hazard_tiles.size()]

			var tile_spr := Sprite2D.new()
			tile_spr.texture = AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/tiles/" + tile_name + ".png")
			tile_spr.centered = false
			tile_spr.modulate = tint
			tile_spr.position = Vector2(start_x + c * TILE_SIZE, start_y + r * TILE_SIZE)
			ground_layer.add_child(tile_spr)

	# 2. Warstwa Dekoracji i Celów Misji (zgodnie z objective_scene_contracts.json)
	primary_objective_type = String(cfg.get("scene_type", "activate_terminal"))
	primary_objective_required_sec = 2.5
	objective_steps_required = 1
	# Campaign v2 defines the actual target, not a generic terminal hold.
	var story_objectives: Array = cfg.get("objectives_v2", [])
	for story_obj in story_objectives:
		if story_obj is Dictionary:
			if String(story_obj.get("type", "")) == "collect_item":
				data_cores_total = mini(3, maxi(1, int(story_obj.get("count", 3))))
			elif String(story_obj.get("type", "")) == "clear_elites":
				objective_elites_required = maxi(1, int(story_obj.get("count", 2)))
			elif String(story_obj.get("type", "")) in ["survive_hazard", "defend_node"]:
				primary_objective_required_sec = maxf(1.0, float(story_obj.get("count", 90)))
			elif String(story_obj.get("type", "")) in ["repair_generator", "destroy_target"]:
				objective_steps_required = maxi(1, int(story_obj.get("count", 2)))
	if primary_objective_type == "escort":
		primary_objective_required_sec = beacon_world_pos.distance_to(escort_destination)
	_spawn_primary_mission_target(beacon_world_pos, primary_objective_type)
	# These missions have world pickups, enemy targets or a survival timer.
	# A fake central console and its radar marker would mislead players.
	var uses_world_objective: bool = primary_objective_type in ["collect_item", "clear_elites", "survive_hazard", "destroy_target"]
	if uses_world_objective and is_instance_valid(primary_objective_area):
		primary_objective_area.visible = false
	if is_instance_valid(radar):
		radar.show_beacon = not uses_world_objective
	_spawn_data_cores_and_medkits()
	_spawn_lamp_posts()

	# 3. Warstwa Przeszkód z Kolizją StaticBody2D dopasowana do biomu
	var biome_props: Array = palette.get("props", ["bunker_a01", "tall_cryo_tube", "supply_crate", "blast_barricade"])
	var anchor_positions := [
		Vector2(-520, -340), Vector2(560, 320),
		Vector2(-340, -180), Vector2(340, -180),
		Vector2(-640, 220), Vector2(660, -240),
		Vector2(430, -340), Vector2(-420, 290),
		Vector2(-240, 180), Vector2(260, 210),
		Vector2(-180, -380), Vector2(210, -380),
		Vector2(-760, -60), Vector2(760, 60)
	]
	for i in range(anchor_positions.size()):
		var p_id := String(biome_props[(i + stage_num) % biome_props.size()])
		_create_obstacle_prop(p_id, anchor_positions[i])

	spawn_hazard_barrels()
	if primary_objective_type == "destroy_target":
		_spawn_mission_destructibles()

func _spawn_mission_destructibles() -> void:
	# These are genuine shootable objects, not a proximity progress bar.
	# Spawn after ordinary barrels so the arena reset does not remove them.
	var positions: Array[Vector2] = [
		Vector2(-440, -140), Vector2(430, 130), Vector2(0, 310)
	]
	for i in range(mini(objective_steps_required, positions.size())):
		var target_barrel: ExplosiveBarrel = EXPLOSIVE_BARREL_SCENE.instantiate() as ExplosiveBarrel
		target_barrel.position = positions[i]
		target_barrel.max_health = 90.0 + current_stage_num * 2.0
		target_barrel.set_meta("mission_target", true)
		obstacles_layer.add_child(target_barrel)
		var target_sprite: Sprite2D = target_barrel.get_node_or_null("Sprite2D") as Sprite2D
		if is_instance_valid(target_sprite):
			target_sprite.texture = AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/props/mutation_tank.png")
			target_sprite.scale = Vector2(0.8, 0.8)
		target_barrel.exploded.connect(_on_mission_destructible_exploded)


func _on_mission_destructible_exploded(target: ExplosiveBarrel) -> void:
	if primary_objective_type != "destroy_target" or run_result_state != "active":
		return
	if not is_instance_valid(target) or not target.has_meta("mission_target"):
		return
	objective_steps_done = mini(objective_steps_required, objective_steps_done + 1)
	if objective_steps_done >= objective_steps_required:
		_complete_primary_objective()
	else:
		_update_objectives_ui()


func _create_obstacle_prop(prop_id: String, world_pos: Vector2) -> void:
	var spec: Dictionary = AssetRegistry.PROP_ASSETS.get(prop_id, {})
	if spec.is_empty():
		return
	var tex := AssetRegistry.get_tex(String(spec.get("path", "")))
	if tex == null:
		return

	var body := StaticBody2D.new()
	body.position = world_pos

	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(0, -24)
	body.add_child(spr)

	if bool(spec.get("solid", true)):
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = spec.get("collision", Vector2(64, 48))
		col.shape = rect
		col.position = spec.get("offset", Vector2(0, 12))
		body.add_child(col)
		solid_obstacle_positions.append(world_pos)

	if spec.has("glow_color"):
		var glow_col: Color = spec["glow_color"]
		var light := PointLight2D.new()
		light.texture = LIGHT_COOKIE
		light.color = glow_col
		light.energy = 0.85
		light.texture_scale = 1.6
		body.add_child(light)

	obstacles_layer.add_child(body)

func _spawn_lamp_posts() -> void:
	# A few soft-light tweens provide biome atmosphere without expensive
	# per-enemy particles or full-screen post-processing on Android.
	var biome := String(StageDirector.get_stage_config(StageDirector.current_stage).get("biome", "wasteland"))
	var lamp_color := Color(1.0, 0.82, 0.42, 1.0)
	match biome:
		"cryo_lab": lamp_color = Color(0.40, 0.80, 1.0)
		"toxic_sewers": lamp_color = Color(0.47, 1.0, 0.36)
		"reactor": lamp_color = Color(0.76, 0.39, 1.0)
		"abandoned_city": lamp_color = Color(1.0, 0.57, 0.29)
	var lamp_positions := [
		Vector2(-460, -20), Vector2(460, -20),
		Vector2(-460, 440), Vector2(460, 440)
	]
	var tex := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/props/street_lamp.png")
	for pos in lamp_positions:
		var lamp := Sprite2D.new()
		lamp.texture = tex
		lamp.position = pos + Vector2(0, -32)
		decorations_layer.add_child(lamp)

		var l := PointLight2D.new()
		l.texture = LIGHT_COOKIE
		l.color = lamp_color
		l.energy = 0.65
		l.texture_scale = 2.0
		l.position = pos + Vector2(0, -48)
		decorations_layer.add_child(l)
		var light_anim := create_tween()
		light_anim.set_loops()
		light_anim.tween_property(l, "energy", 0.48, 1.9).set_trans(Tween.TRANS_SINE)
		light_anim.tween_property(l, "energy", 0.72, 2.1).set_trans(Tween.TRANS_SINE)

func _spawn_primary_mission_target(pos: Vector2, scene_type: String) -> void:
	var area := Area2D.new()
	area.position = pos
	area.collision_layer = 4
	area.collision_mask = 1

	var ring := Sprite2D.new()
	ring.texture = AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/vfx/portal.png")
	ring.material = PowerEffects.get_additive_mat()
	ring.scale = Vector2(1.05, 1.05)
	area.add_child(ring)

	var target_spr := Sprite2D.new()
	var tex_path := "res://assets/mutantsurvivor_ch01/props/computer_console.png"
	match scene_type:
		"rescue_npc":
			tex_path = "res://assets/mutantsurvivor_ch01/characters/medic_idle.png"
		"escort":
			tex_path = "res://assets/mutantsurvivor_ch01/weapons/weapon_9.png"
		"destroy_target":
			tex_path = "res://assets/mutantsurvivor_ch01/props/mutation_tank.png"
		"defend_node", "repair_generator":
			tex_path = "res://assets/mutantsurvivor_ch01/props/satellite_dish.png"
		"defeat_boss":
			tex_path = "res://assets/mutantsurvivor_ch01/props/portal_gate.png"
	target_spr.texture = AssetRegistry.get_tex(tex_path)
	target_spr.position = Vector2(0, -22)
	target_spr.scale = Vector2(0.72, 0.72)
	area.add_child(target_spr)

	var pbar := ProgressBar.new()
	pbar.position = Vector2(-46, -84)
	pbar.size = Vector2(92, 10)
	pbar.max_value = primary_objective_required_sec
	pbar.value = 0.0
	pbar.show_percentage = false
	area.add_child(pbar)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 85.0
	col.shape = shape
	area.add_child(col)

	primary_objective_area = area
	primary_objective_ring = ring
	primary_objective_bar = pbar
	primary_objective_progress = 0.0
	decorations_layer.add_child(area)

func _spawn_data_cores_and_medkits() -> void:
	var core_positions := [
		Vector2(-380, 120),
		Vector2(290, -110),
		Vector2(-120, -290)
	]
	var dna_tex := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/icons/dna_tablet.png")
	for pos in core_positions:
		var core := Area2D.new()
		core.position = pos
		core.collision_layer = 4
		core.collision_mask = 1

		var spr := Sprite2D.new()
		spr.texture = dna_tex
		spr.scale = Vector2(0.58, 0.58)
		core.add_child(spr)

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 30.0
		col.shape = shape
		core.add_child(col)

		core.body_entered.connect(func(body: Node2D):
			if body is Player:
				data_cores_collected = mini(data_cores_total, data_cores_collected + 1)
				player.add_xp(30.0)
				if primary_objective_type == "collect_item" and data_cores_collected >= data_cores_total:
					_complete_primary_objective()
				_update_objectives_ui()
				core.queue_free()
		)
		decorations_layer.add_child(core)

	var med_positions := [Vector2(-180, 240), Vector2(360, 180)]
	var med_tex := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/icons/medkit.png")
	for pos in med_positions:
		var med := Area2D.new()
		med.position = pos
		med.collision_layer = 4
		med.collision_mask = 1

		var spr := Sprite2D.new()
		spr.texture = med_tex
		spr.scale = Vector2(0.58, 0.58)
		med.add_child(spr)

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 28.0
		col.shape = shape
		med.add_child(col)

		med.body_entered.connect(func(body: Node2D):
			if body is Player and player.current_health < player.max_health:
				player.heal(45.0)
				med.queue_free()
		)
		decorations_layer.add_child(med)

func spawn_hazard_barrels() -> void:
	# Only this arena owns these props. Never free destructibles from a
	# different arena/subviewport (notably during all-stage smoke and Visual QA).
	# _build_layered_arena already queues the previous obstacles_layer children.
	var barrel_positions := [
		Vector2(-220, -90), Vector2(220, -70),
		Vector2(-310, 260), Vector2(310, 280),
		Vector2(0, -240), Vector2(120, 290)
	]
	for pos in barrel_positions:
		var barrel := EXPLOSIVE_BARREL_SCENE.instantiate()
		barrel.position = pos
		obstacles_layer.add_child(barrel)

func start_stage(stage_num: int) -> void:
	current_stage_num = clampi(stage_num, 1, 100)
	StageDirector.current_stage = current_stage_num
	total_run_elapsed = 0.0
	primary_objective_done = false
	primary_objective_hp = 300.0
	primary_objective_max_hp = 300.0
	data_cores_collected = 0
	objective_elites_defeated = 0
	objective_steps_done = 0
	rescue_npc_freed = false
	enemies_killed_in_run = 0
	has_used_revive = false
	run_result_state = "active"
	boss_spawned_this_run = false
	boss_killed_this_run = false
	active_boss = null
	boss_box.visible = false
	npc_dialogue_history.clear()

	var cfg := StageDirector.get_stage_config(current_stage_num)
	StageDirector.play_biome_ambience(String(cfg.get("biome", "wasteland")))
	_show_npc_dialogue_from_stage(cfg, "intro_dialogue")
	start_wave(current_stage_num, 1)

func _show_npc_dialogue_from_stage(cfg: Dictionary, key: String) -> void:
	var lines: Array = cfg.get(key, [])
	if lines.size() > 0 and lines[0] is Dictionary:
		var d: Dictionary = lines[0]
		show_npc_comms(String(d.get("speaker", cfg.get("npc", "Mara"))), String(d.get("text", "")))

func show_npc_comms(speaker: String, text: String) -> void:
	if not is_instance_valid(npc_dialogue_panel) or text.is_empty():
		return
	var p_path: String = AssetRegistry.NPC_PORTRAITS.get(speaker, AssetRegistry.NPC_PORTRAITS["Mara"])
	npc_portrait_rect.texture = AssetRegistry.get_tex(p_path)
	npc_speaker_lbl.text = "RADIO • %s" % speaker.to_upper()
	# Avoid repeating NPC names in the subtitle; keep original in the log.
	var preview := text.strip_edges()
	if preview.to_lower().begins_with(speaker.to_lower() + ":"):
		preview = preview.substr(speaker.length() + 1).strip_edges()
	# Full dialogue is saved to the journal below. A short radio toast
	# keeps the tactical objectives and opponent field readable on phones.
	var max_chars: int = 94 if StageDirector.is_portrait_mode() else 185
	if preview.length() > max_chars:
		preview = preview.substr(0, max_chars - 1).strip_edges() + "…"
	npc_text_lbl.text = preview
	npc_dialogue_panel.visible = true
	npc_hide_timer = 4.0 if StageDirector.is_portrait_mode() else clampf(4.0 + float(preview.length()) / 42.0, 5.0, 8.0)
	var log_entry := "[Etap %03d | Fala %d] %s: %s" % [current_stage_num, current_wave_num, speaker.to_upper(), text]
	if not npc_dialogue_history.has(log_entry):
		npc_dialogue_history.append(log_entry)
	if is_instance_valid(npc_journal_lbl):
		npc_journal_lbl.text = "\n\n".join(npc_dialogue_history)

func start_wave(stage_num: int, wave_num: int) -> void:
	current_stage_num = stage_num
	current_wave_num = wave_num
	wave_time_left = StageDirector.wave_duration_sec
	wave_timer_bar.max_value = StageDirector.wave_duration_sec
	wave_timer_bar.value = wave_time_left

	var stage_cfg := StageDirector.get_stage_config(current_stage_num)
	var diff_cfg := StageDirector.get_difficulty_profile()
	max_waves_in_stage = int(stage_cfg.get("waves", 10))

	chapter_label.text = "ETAP %03d/100 — %s" % [current_stage_num, String(stage_cfg.get("name", "Pierwszy trop"))]
	subtitle_label.text = "Rozdz. %d: %s | %s" % [
		int(stage_cfg.get("chapter", 1)),
		String(stage_cfg.get("chapter_name", "Pustkowia")),
		String(diff_cfg.get("name", "Ocalały"))
	]
	char_level_label.text = "Konto Lv.%d" % StageDirector.character_level
	obj_header.text = ("CELE • ETAP %03d" if _is_compact_portrait_hud(get_viewport_rect().size.x) else "◆ CELE MISJI (ETAP %03d)") % current_stage_num

	_last_wave_banner_second = maxi(0, int(ceil(wave_time_left)))
	_update_wave_banner()
	_update_objectives_ui()

	if is_instance_valid(wave_director):
		wave_director.start_wave(current_wave_num, StageDirector.wave_duration_sec)
	else:
		var initial_count := 4 + mini(6, current_wave_num)
		for i in range(initial_count):
			spawn_wave_enemy()

	if current_wave_num == 5:
		_show_npc_dialogue_from_stage(stage_cfg, "progress_dialogue")
		if primary_objective_type == "clear_elites":
			# Make the two mandatory elite kills actually available on stage 7 of each chapter.
			var scripted_elite_id := "elite_ch%02d_stage07" % int(stage_cfg.get("chapter", 1))
			for elite_idx in range(objective_elites_required):
				spawn_special_enemy(scripted_elite_id, "miniboss", "⚠ ELITA %d/%d ⚠" % [elite_idx + 1, objective_elites_required])
		var elite_id := String(stage_cfg.get("elite_id", ""))
		if not elite_id.is_empty():
			spawn_special_enemy(elite_id, "miniboss", "⚠ ELITA FALI 5: %s ⚠" % elite_id.to_upper())
		elif current_stage_num == 1:
			spawn_special_enemy("miniboss_ch01", "miniboss", "⚠ MINIBOSS FALI 5: ELITARNY NISZCZYCIEL ⚠")
	elif current_wave_num == 10:
		var boss_id := String(stage_cfg.get("boss_id", ""))
		if not boss_id.is_empty():
			var b_stats := StageDirector.get_enemy_scaled_stats(boss_id, current_stage_num, total_run_elapsed, "boss")
			var b_name := String(b_stats.get("display_name", boss_id)).to_upper()
			spawn_special_enemy(boss_id, "boss", "☠ BOSS ROZDZIAŁU: %s ☠" % b_name)
		elif current_stage_num == 1:
			spawn_special_enemy("boss_ch01", "boss", "☠ BOSS ETAPU: MATKA ROJU A-03 ☠")

func _update_wave_banner() -> void:
	var display_time := maxi(0, int(ceil(wave_time_left)))
	var mins := int(display_time / 60)
	var secs := display_time % 60
	var compact_text := _is_compact_portrait_hud(get_viewport_rect().size.x)
	if current_wave_num == 5:
		wave_label.text = ("FALA 5/10 • ELITA %02d:%02d" if compact_text else "FALA 5/10 — ELITA! • %02d:%02d") % [mins, secs]
	elif current_wave_num == max_waves_in_stage:
		if _stage_requires_final_boss():
			wave_label.text = ("FALA %d/%d • BOSS %02d:%02d" if compact_text else "FALA %d/%d — BOSS! • %02d:%02d") % [current_wave_num, max_waves_in_stage, mins, secs]
		else:
			wave_label.text = ("FALA %d/%d • FINAŁ %02d:%02d" if compact_text else "FALA %d/%d — OSTATNIA FALA • %02d:%02d") % [current_wave_num, max_waves_in_stage, mins, secs]
	else:
		wave_label.text = ("FALA %d/%d • %02d:%02d" if compact_text else "FALA %d / %d • %02d:%02d") % [current_wave_num, max_waves_in_stage, mins, secs]

func _update_objectives_ui() -> void:
	var c1 := "☑" if primary_objective_done else "☐"
	var c2 := "☑" if data_cores_collected >= data_cores_total else "☐"
	var c3 := "☑" if (current_wave_num >= max_waves_in_stage and wave_time_left <= 0.0) else "☐"
	var obj_pl := StageDirector.translate_objective(primary_objective_type)
	var pct := 100 if primary_objective_done else int(roundf(clampf(primary_objective_progress / maxf(0.1, primary_objective_required_sec), 0.0, 1.0) * 100.0))
	if primary_objective_type == "collect_item":
		obj1_label.text = "%s DNA %d/%d" % [c1, data_cores_collected, data_cores_total]
	elif primary_objective_type == "clear_elites":
		obj1_label.text = "%s Elity %d/%d" % [c1, objective_elites_defeated, objective_elites_required]
	elif primary_objective_type == "destroy_target":
		obj1_label.text = "%s Inkubatory %d/%d" % [c1, objective_steps_done, objective_steps_required]
	elif primary_objective_type == "repair_generator":
		obj1_label.text = "%s Generatory %d/%d (%d%%)" % [c1, objective_steps_done, objective_steps_required, pct]
	elif primary_objective_type == "escort":
		obj1_label.text = "%s Eskorta %d%%" % [c1, pct]
	elif primary_objective_type == "rescue_npc":
		obj1_label.text = "%s %s" % [c1, ("Eskortuj ocalałego" if StageDirector.is_portrait_mode() else "Doprowadź ocalałego do ewakuacji") if rescue_npc_freed else "Uwolnij ocalałego"]
	elif primary_objective_type == "defeat_boss":
		obj1_label.text = "%s Boss (%d/1)" % [c1, 1 if primary_objective_done else 0] if StageDirector.is_portrait_mode() else "%s %s (%d/1)" % [c1, obj_pl, 1 if primary_objective_done else 0]
	elif primary_objective_type == "defend_node":
		obj1_label.text = "%s Obrona %d%% (HP %d)" % [c1, pct, int(primary_objective_hp)] if StageDirector.is_portrait_mode() else "%s %s (%d%% | HP: %d/%d)" % [c1, obj_pl, pct, int(primary_objective_hp), int(primary_objective_max_hp)]
	else:
		obj1_label.text = "%s Cel misji: %d%%" % [c1, pct] if StageDirector.is_portrait_mode() else "%s %s (%d%%)" % [c1, obj_pl, pct]
	# Avoid printing the same DNA mission twice. For collection contracts,
	# show combat progress instead of a duplicated checklist item.
	if primary_objective_type == "collect_item":
		obj2_label.text = "▸ Mutanci: %d" % enemies_killed_in_run
	else:
		obj2_label.text = "%s DNA %d/%d" % [c2, data_cores_collected, data_cores_total] if StageDirector.is_portrait_mode() else "%s Próbki DNA (%d/%d)" % [c2, data_cores_collected, data_cores_total]
	obj3_label.text = "%s Fale %d/%d" % [c3, current_wave_num, max_waves_in_stage] if StageDirector.is_portrait_mode() else "%s Przetrwaj 10 fal (Fala %d/%d | Zabici: %d)" % [c3, current_wave_num, max_waves_in_stage, enemies_killed_in_run]
	# The live objective palette makes the next required action unmistakable
	# without changing victory checks or adding new HUD widgets.
	for objective_label in [obj1_label, obj2_label, obj3_label]:
		if is_instance_valid(objective_label):
			var done: bool = objective_label.text.begins_with("☑")
			objective_label.add_theme_color_override("font_color",
				Color(0.47, 0.96, 0.68) if done else Color(0.90, 0.95, 1.0))
	if is_instance_valid(obj_header):
		obj_header.add_theme_color_override("font_color", Color(0.42, 0.88, 1.0))

func _process(delta: float) -> void:
	if run_result_state != "active":
		return
	total_run_elapsed += delta
	wave_time_left = maxf(0.0, wave_time_left - delta)
	wave_timer_bar.value = wave_time_left
	var displayed_second := int(ceil(wave_time_left))
	if displayed_second != _last_wave_banner_second:
		_last_wave_banner_second = displayed_second
		_update_wave_banner()
	_update_active_power_buttons()
	if primary_objective_type == "survive_hazard" and not primary_objective_done:
		_advance_hazard_survival(delta)
	if primary_objective_type == "defend_node" and not primary_objective_done:
		_advance_defense_objective(delta)
		if run_result_state != "active":
			return
	if primary_objective_type == "rescue_npc" and not primary_objective_done:
		_advance_rescue_objective(delta)

	# Interaktywny postęp celu głównego na mapie (terminal / generator / eskorta / obrona węzła / zniszczenie)
	if not primary_objective_done and not (primary_objective_type in ["defeat_boss", "collect_item", "clear_elites", "survive_hazard", "destroy_target", "defend_node", "rescue_npc"]) and is_instance_valid(primary_objective_area) and is_instance_valid(player):
		var dist_to_obj := player.global_position.distance_to(primary_objective_area.global_position)
		if dist_to_obj <= 115.0:
			if primary_objective_type == "escort":
				var old_position: Vector2 = primary_objective_area.position
				primary_objective_area.position = old_position.move_toward(escort_destination, 75.0 * delta)
				primary_objective_progress = minf(primary_objective_required_sec,
					primary_objective_progress + old_position.distance_to(primary_objective_area.position))
				if radar:
					radar.beacon_world_pos = primary_objective_area.position
			else:
				primary_objective_progress = minf(primary_objective_required_sec, primary_objective_progress + delta)
			if is_instance_valid(primary_objective_bar):
				primary_objective_bar.value = primary_objective_progress
			if primary_objective_progress >= primary_objective_required_sec or (primary_objective_type == "escort" and primary_objective_area.position.distance_to(escort_destination) <= 0.5):
				if primary_objective_type == "repair_generator" and objective_steps_done + 1 < objective_steps_required:
					objective_steps_done += 1
					primary_objective_progress = 0.0
					primary_objective_area.position = Vector2(-280, 190)
					if radar:
						radar.beacon_world_pos = primary_objective_area.position
					if is_instance_valid(primary_objective_bar):
						primary_objective_bar.value = 0.0
				else:
					if primary_objective_type == "repair_generator":
						objective_steps_done = objective_steps_required
					_complete_primary_objective()
			_update_objectives_ui()

	# Zagrożenia środowiskowe biomu (acid_spots, cryo_vent, sewer_gas, falling_debris, radiation_pulse)
	hazard_timer += delta
	if hazard_timer >= 6.5:
		hazard_timer = 0.0
		_trigger_biome_hazard()

	if npc_hide_timer > 0.0:
		npc_hide_timer -= delta
		if npc_hide_timer <= 0.0 and is_instance_valid(npc_dialogue_panel):
			npc_dialogue_panel.visible = false

	if is_instance_valid(active_boss):
		boss_box.visible = true
		boss_hp_bar.max_value = active_boss.max_health
		boss_hp_bar.value = maxf(0.0, active_boss.current_health)
	else:
		boss_box.visible = false

	if wave_time_left <= 0.0:
		on_wave_completed()
		return

	if is_instance_valid(wave_director):
		wave_director.process_wave(delta, player, current_stage_num, total_run_elapsed)
	else:
		var diff := StageDirector.get_difficulty_profile()
		var spawn_rate_mult := float(diff.get("spawn_rate", 1.0))
		var interval := maxf(0.32, (1.25 - float(current_wave_num) * 0.065) / maxf(0.5, spawn_rate_mult))
		var max_active := 16 + current_wave_num * 4

		spawn_timer += delta
		if spawn_timer >= interval:
			spawn_timer = 0.0
			var enemies_count := get_tree().get_nodes_in_group("enemies").size()
			if enemies_count < max_active:
				spawn_wave_enemy()

func _advance_rescue_objective(delta: float) -> void:
	# Stage 5 of every chapter: release the survivor, then personally lead
	# them to extraction. Both interactions matter, unlike a generic console.
	if run_result_state != "active" or primary_objective_done or primary_objective_type != "rescue_npc":
		return
	if not is_instance_valid(player) or not is_instance_valid(primary_objective_area):
		return
	var npc_pos: Vector2 = primary_objective_area.global_position
	var hero_distance: float = player.global_position.distance_to(npc_pos)
	if not rescue_npc_freed:
		if hero_distance <= 100.0:
			primary_objective_progress = minf(2.5, primary_objective_progress + maxf(0.0, delta))
			if is_instance_valid(primary_objective_bar):
				primary_objective_bar.value = primary_objective_progress
			if primary_objective_progress >= 2.5:
				rescue_npc_freed = true
				primary_objective_progress = 0.0
				primary_objective_required_sec = npc_pos.distance_to(rescue_destination)
				if is_instance_valid(primary_objective_bar):
					primary_objective_bar.max_value = primary_objective_required_sec
					primary_objective_bar.value = 0.0
				show_npc_comms("Mara", "Ocalały jest wolny! Doprowadź go do punktu ewakuacji.")
	else:
		# The NPC moves only while the hero stays close; when the player runs
		# away, the survivor waits rather than teleporting through the horde.
		if hero_distance <= 180.0 and hero_distance >= 45.0:
			var old_pos: Vector2 = primary_objective_area.global_position
			var next_pos: Vector2 = old_pos.move_toward(player.global_position, 90.0 * maxf(0.0, delta))
			primary_objective_area.global_position = next_pos
			primary_objective_progress = minf(primary_objective_required_sec,
				primary_objective_progress + old_pos.distance_to(next_pos))
		if is_instance_valid(radar):
			radar.beacon_world_pos = primary_objective_area.global_position
		if is_instance_valid(primary_objective_bar):
			primary_objective_bar.value = primary_objective_progress
		if primary_objective_area.global_position.distance_to(rescue_destination) <= 85.0 and player.global_position.distance_to(rescue_destination) <= 140.0:
			_complete_primary_objective()
	_update_objectives_ui()


func _advance_defense_objective(delta: float) -> void:
	# Defense completes after surviving the contract timer while the
	# objective remains intact. The player need not stand on the generator.
	if run_result_state != "active" or primary_objective_done or primary_objective_type != "defend_node":
		return
	var attackers: int = 0
	if is_instance_valid(primary_objective_area) and is_instance_valid(characters_layer):
		# Limit damage to mutants from THIS combat arena. Global enemy
		# groups can contain actors from another SubViewport/QA scene.
		for enemy in characters_layer.get_children():
			if not (enemy is MutantEnemy) or not is_instance_valid(enemy):
				continue
			if enemy.is_dying or enemy.current_health <= 0.0:
				continue
			if enemy.global_position.distance_to(primary_objective_area.global_position) <= 95.0:
				attackers += 1
				if attackers >= 3:
					break
	if attackers > 0:
		primary_objective_hp = maxf(0.0, primary_objective_hp - 7.5 * float(attackers) * maxf(0.0, delta))
	if primary_objective_hp <= 0.0:
		_update_objectives_ui()
		_on_player_died()
		return
	primary_objective_progress = minf(primary_objective_required_sec, primary_objective_progress + maxf(0.0, delta))
	if is_instance_valid(primary_objective_bar):
		primary_objective_bar.value = primary_objective_progress
	if primary_objective_progress >= primary_objective_required_sec:
		_complete_primary_objective()
	else:
		_update_objectives_ui()


func _advance_hazard_survival(delta: float) -> void:
	# This objective measures active survival time; the player is free
	# to dodge threats instead of standing at a generic console.
	if run_result_state != "active" or primary_objective_done or primary_objective_type != "survive_hazard":
		return
	primary_objective_progress = minf(primary_objective_required_sec, primary_objective_progress + maxf(0.0, delta))
	if is_instance_valid(primary_objective_bar):
		primary_objective_bar.value = primary_objective_progress
	if primary_objective_progress >= primary_objective_required_sec:
		_complete_primary_objective()
	else:
		_update_objectives_ui()


func _complete_primary_objective() -> void:
	if primary_objective_done or run_result_state != "active":
		return
	primary_objective_done = true
	if is_instance_valid(player):
		player.add_xp(65.0)
	if radar:
		radar.show_beacon = false
	if is_instance_valid(primary_objective_ring):
		primary_objective_ring.modulate = Color(0.3, 1.0, 0.5, 0.78)
	_update_objectives_ui()


func _get_wave_enemy_archetype() -> String:
	var pool := ["biegacz", "zracy_pelzacz", "zdziczaly", "zarazony", "plujacy_kwasem", "lowca", "skrzydlaty", "czerw"]
	if current_stage_num <= 3 and current_wave_num <= 2:
		var early_pool := ["biegacz", "zracy_pelzacz", "zdziczaly"]
		return early_pool[randi() % early_pool.size()]
	return pool[randi() % pool.size()]

func _find_valid_spawn_position(min_dist: float, max_dist: float) -> Vector2:
	var center := player.global_position if is_instance_valid(player) else Vector2.ZERO
	for _attempt in range(12):
		var angle := randf() * TAU
		var dist := randf_range(min_dist, max_dist)
		var candidate := center + Vector2(cos(angle), sin(angle)) * dist
		candidate.x = clampf(candidate.x, -1160.0, 1160.0)
		candidate.y = clampf(candidate.y, -900.0, 900.0)
		var blocked := false
		for obs_pos in solid_obstacle_positions:
			if candidate.distance_to(obs_pos) < 95.0:
				blocked = true
				break
		if not blocked and candidate.distance_to(center) >= 240.0:
			return candidate
	return Vector2(clampf(center.x + 420.0, -1100.0, 1100.0), clampf(center.y - 320.0, -860.0, 860.0))

func spawn_wave_enemy() -> void:
	if not is_instance_valid(player):
		return
	var enemy_id := _get_wave_enemy_archetype()
	var scene: PackedScene = ENEMY_SCENES.get(enemy_id, ENEMY_SCENES["zracy_pelzacz"])
	var enemy: MutantEnemy = scene.instantiate()
	enemy.global_position = _find_valid_spawn_position(340.0, 580.0)
	enemy.effects_layer = effects_layer
	characters_layer.add_child(enemy)

	var is_elite := (current_wave_num >= 5) and (randf() < 0.14 * float(StageDirector.get_difficulty_profile().get("elite_chance", 1.0)))
	var tier := "elite" if is_elite else "normal"
	enemy.setup_enemy_archetype(enemy_id, tier, current_stage_num, total_run_elapsed)
	enemy.enemy_died.connect(_on_enemy_died)

func spawn_special_enemy(enemy_id: String, tier: String, banner_title: String) -> void:
	# Duplicate wave callbacks must never create a second chapter boss.
	# Once defeated, the boss is terminal for this run.
	if tier == "boss" and boss_spawned_this_run:
		return
	if not is_instance_valid(player):
		return
	var scene: PackedScene = ENEMY_SCENES["zdziczaly"]
	var boss: MutantEnemy = scene.instantiate()
	boss.global_position = _find_valid_spawn_position(340.0, 480.0)
	boss.effects_layer = effects_layer
	characters_layer.add_child(boss)
	boss.setup_enemy_archetype(enemy_id, tier, current_stage_num, total_run_elapsed)
	boss.enemy_died.connect(_on_enemy_died)

	active_boss = boss
	if tier == "boss":
		boss_spawned_this_run = true
	boss_label.text = banner_title
	boss_box.visible = true
	boss_hp_bar.max_value = boss.max_health
	boss_hp_bar.value = boss.current_health

func _on_enemy_died(enemy: MutantEnemy) -> void:
	if run_result_state != "active":
		return
	enemies_killed_in_run += 1
	# MutantEnemy.die() already records each kill exactly once.
	_update_objectives_ui()
	# Only the chapter's contracted elites count; incidental elite spawns
	# may still grant XP but cannot complete this story objective.
	if primary_objective_type == "clear_elites" and enemy.tier == "miniboss":
		var required_elite_id: String = "elite_ch%02d_stage07" % int(StageDirector.get_stage_config(current_stage_num).get("chapter", 1))
		if enemy.enemy_id == required_elite_id:
			objective_elites_defeated = mini(objective_elites_required, objective_elites_defeated + 1)
			if objective_elites_defeated >= objective_elites_required:
				_complete_primary_objective()
			_update_objectives_ui()
	if enemy == active_boss:
		# A wave-five elite is displayed in the boss HUD, but must never
		# complete the final chapter boss objective or victory gate.
		var final_boss_defeated: bool = (enemy.tier == "boss"
			and boss_spawned_this_run
			and current_wave_num >= max_waves_in_stage)
		if final_boss_defeated:
			boss_killed_this_run = true
		active_boss = null
		boss_box.visible = false
		if final_boss_defeated and primary_objective_type == "defeat_boss":
			primary_objective_done = true
		_update_objectives_ui()

func _stage_requires_final_boss() -> bool:
	# Chapter finales have a configured boss; stage one is the tutorial
	# exception. Ordinary 90-stage missions must not be locked by a missing boss.
	return current_stage_num == 1 or not String(StageDirector.get_stage_config(current_stage_num).get("boss_id", "")).is_empty()

func _can_claim_victory() -> bool:
	return (run_result_state == "active"
		and current_wave_num >= max_waves_in_stage
		and wave_time_left <= 0.0
		and primary_objective_done
		and ((not _stage_requires_final_boss() and not boss_spawned_this_run)
			or (boss_spawned_this_run and boss_killed_this_run))
		and is_instance_valid(player) and player.current_health > 0.0)

func on_wave_completed() -> void:
	if run_result_state != "active":
		return
	if current_wave_num >= max_waves_in_stage:
		if _can_claim_victory():
			_on_stage_victory()
		else:
			# Keep the final wave active while the boss or objective remains.
			# Missing boss data never grants an automatic stage victory.
			wave_time_left = 1.0
		return
	current_wave_num += 1
	player.add_xp(18.0)
	start_wave(current_stage_num, current_wave_num)

func _on_stage_victory() -> void:
	if not _can_claim_victory():
		return
	run_result_state = "victory"
	death_panel.visible = false
	upgrade_panel.visible = false
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not (e is Player):
			e.queue_free()

	if is_instance_valid(wave_director):
		wave_director.recycle_all_enemies()
	StageDirector.play_sfx("victory")
	var cfg := StageDirector.get_stage_config(current_stage_num)
	_show_npc_dialogue_from_stage(cfg, "completion_dialogue")

	var result := StageDirector.complete_stage_run(current_stage_num, true, max_waves_in_stage)
	update_currency_display()
	char_level_label.text = "Konto Lv.%d" % StageDirector.character_level
	_update_objectives_ui()

	var mins := int(total_run_elapsed / 60.0)
	var secs := int(total_run_elapsed) % 60
	var score_val := enemies_killed_in_run * 125 + current_stage_num * 500 + (1500 if primary_objective_done else 0)
	var unlock_txt := "Postęp Kampanii: Odblokowano Etap %03d/100!" % int(result["max_unlocked_stage"]) if bool(result["unlocked_next_stage"]) else "Postęp Kampanii: Etap %03d/100 ukończony!" % current_stage_num

	var drop_txt := "• Wylosowany przedmiot RPG: Brak nowego zrzutu w tym przelocie"
	var dropped: Dictionary = result.get("dropped_item", {})
	if not dropped.is_empty():
		var r_name := String(StageDirector.RARITY_NAMES.get(String(dropped.get("rarity", "common")), "Zwykła"))
		var pwr := StageDirector.get_item_effective_power(dropped)
		drop_txt = "🎁 WYLOSOWANY PRZEDMIOT RPG: %s [%s | Moc: %.1f]!" % [String(dropped.get("name", "Moduł")), r_name.to_upper(), pwr]

	win_summary_label.text = (
		"🏆 WYNIK OPERACJI: %d pkt  |  ⏱ Czas przeżycia: %02d:%02d\n" % [score_val, mins, secs] +
		"☠ Pokonani mutanci: %d  |  ⭐ Zdobyte XP Konta: +%d XP (Poziom Konta: Lv.%d)\n" % [enemies_killed_in_run, int(result["earned_character_xp"]), int(result["character_level"])] +
		"⚡ Kredyty: +%d  |  🔩 Złom Techniczny: +%d szt.\n" % [int(result["earned_credits"]), int(result.get("earned_scrap", 1))] +
		"%s\n🗺 %s" % [drop_txt, unlock_txt]
	)
	get_tree().paused = true
	win_panel.visible = true

func start_next_unlocked_stage() -> void:
	if run_result_state != "victory":
		return
	var next_s := current_stage_num + 1
	if next_s > 100 or next_s > StageDirector.max_unlocked_stage:
		_return_to_main_menu()
		return
	if not StageDirector.is_practice_mode and not StageDirector.spend_campaign_attempt():
		_return_to_main_menu()
		return
	win_panel.visible = false
	get_tree().paused = false
	StageDirector.current_stage = next_s
	StageDirector.save_campaign_profile()
	get_tree().reload_current_scene()

func restart_current_stage() -> void:
	if run_result_state == "awaiting_revive":
		_finalize_failure_once()
	if not StageDirector.is_practice_mode and not StageDirector.spend_campaign_attempt():
		_return_to_main_menu()
		return
	win_panel.visible = false
	death_panel.visible = false
	if is_instance_valid(defeat_overlay_inst): defeat_overlay_inst.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_player_health_changed(curr: float, max_v: float) -> void:
	hp_bar.max_value = max_v
	hp_bar.value = curr
	hp_label.text = "HP: %d / %d" % [int(roundf(curr)), int(roundf(max_v))]

func _on_player_xp_changed(curr: float, needed: float, lvl: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = curr
	run_level_label.text = "POZ. %d / 100 (%d/%d XP)" % [lvl, int(curr), int(needed)]

func _on_player_leveled_up(_lvl: int) -> void:
	player.external_move_dir = Vector2.ZERO
	if is_instance_valid(joystick):
		joystick.cancel_touch()
	get_tree().paused = true
	# Upgrade selection is a focused modal. Hide the transient radio toast
	# until combat resumes so it cannot sit under the reroll CTA.
	if is_instance_valid(npc_dialogue_panel):
		npc_dialogue_panel.visible = false
		npc_hide_timer = 0.0
	upgrade_panel.visible = true
	_populate_upgrade_cards()

func _populate_upgrade_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	if reroll_btn:
		reroll_btn.text = "🎲 PRZELOSUJ KARTY (%d)" % player.free_rerolls
		reroll_btn.disabled = player.free_rerolls <= 0

	var available: Array = []
	for up in GameProgression.UPGRADES_DB:
		var current_tier: int = int(upgrade_tiers.get(up["id"], 0))
		if current_tier < int(up["max_tier"]):
			available.append(up)

	available.shuffle()
	var count := mini(3, available.size())
	for i in range(count):
		var card := create_upgrade_card(available[i])
		cards_container.add_child(card)

func _on_reroll_pressed() -> void:
	if player.free_rerolls > 0:
		player.free_rerolls -= 1
		_populate_upgrade_cards()

func create_upgrade_card(upgrade_data: Dictionary) -> Control:
	var portrait: bool = StageDirector.is_portrait_mode()
	var current_tier: int = int(upgrade_tiers.get(upgrade_data["id"], 0))
	var next_tier: int = current_tier + 1
	var max_tier: int = int(upgrade_data["max_tier"])
	# Higher ranks get gold/violet trims, but EVERY card keeps a readable CTA.
	var accent: Color = Color(0.34, 0.88, 0.98)
	var grade: String = "MODUŁ STANDARD"
	if next_tier >= 4:
		accent = Color(1.0, 0.77, 0.34)
		grade = "MODUŁ ELITARNY"
	elif next_tier >= 2:
		accent = Color(0.70, 0.49, 1.0)
		grade = "MODUŁ ULEPSZONY"

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(202, 368) if portrait else Vector2(245, 342)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.092, 0.98)
	style.border_color = accent.darkened(0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 5
	# A real nine-slice metallic frame replaces generic flat boxes;
	# rarity color remains data-bound in the header and SELECT action.
	var card_art_path := "res://assets/ui/approved/upgrade_card_frame.svg"
	if ResourceLoader.exists(card_art_path, "Texture2D"):
		var frame := StyleBoxTexture.new()
		frame.texture = load(card_art_path) as Texture2D
		frame.texture_margin_left = 32.0
		frame.texture_margin_right = 32.0
		frame.texture_margin_top = 32.0
		frame.texture_margin_bottom = 32.0
		panel.add_theme_stylebox_override("panel", frame)
	else:
		panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 11)
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 9 if portrait else 10)
	margin.add_child(body)

	var header := Label.new()
	header.text = "◆ " + grade + " ◆"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12 if portrait else 13)
	header.add_theme_color_override("font_color", accent)
	body.add_child(header)

	var icon := TextureRect.new()
	icon.texture = AssetRegistry.get_tex(String(POWER_ICONS.get(upgrade_data["id"], "res://assets/mutantsurvivor_ch01/weapons/weapon_1.png")))
	icon.custom_minimum_size = Vector2(86, 109) if portrait else Vector2(88, 98)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(icon)

	var title := Label.new()
	title.text = String(upgrade_data["name"]).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 15 if portrait else 17)
	title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	body.add_child(title)

	var detail := Label.new()
	detail.text = String(upgrade_data["desc"])
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 14 if portrait else 14)
	detail.add_theme_color_override("font_color", Color(0.72, 0.83, 0.91))
	body.add_child(detail)

	var level := Label.new()
	level.text = "POZIOM %d / %d" % [next_tier, max_tier]
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.add_theme_font_size_override("font_size", 13 if portrait else 14)
	level.add_theme_color_override("font_color", accent)
	body.add_child(level)

	var button := Button.new()
	button.text = "WYBIERZ"
	button.custom_minimum_size = Vector2(0, 60 if portrait else 56)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17 if portrait else 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent.darkened(0.38)
	normal.border_color = accent
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = accent.darkened(0.15)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = accent.darkened(0.52)
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(func():
		apply_upgrade(String(upgrade_data["id"]))
		upgrade_panel.visible = false
		get_tree().paused = false
	)
	body.add_child(button)
	return panel

func apply_upgrade(up_id: String) -> void:
	upgrade_tiers[up_id] = int(upgrade_tiers.get(up_id, 0)) + 1
	match up_id:
		"plasma_dmg":
			player.attack_damage *= 1.25
		"plasma_cooldown":
			player.attack_cooldown *= 0.82
		"vibro_saws":
			player.enable_vibro_saws()
		"tesla_coil":
			player.has_tesla = true
			player.tesla_damage *= 1.25
		"titanium_skin":
			player.max_health += 35.0
			player.current_health += 35.0
			player.health_regen += 1.5
			player.emit_signal("health_changed", player.current_health, player.max_health)
		"bionic_speed":
			player.move_speed *= 1.18
		"magnetic_drone":
			player.magnet_radius *= 1.45
		"critical_focus":
			player.crit_chance += 0.12
			player.crit_multiplier += 0.35
		"energy_shield":
			player.has_shield = true
			player.shield_charges = 2
			player.queue_redraw()
	_refresh_weapon_loadout_bar()

func _setup_extended_hud_and_profile() -> void:
	var hud_root: Control = $HUD/HUDRoot

	# Kompaktowa odznaka ocalałego (<48px wysokości, zoptymalizowany minimalistyczny HUD)
	if is_instance_valid(chapter_label):
		chapter_label.visible = false
	if is_instance_valid(subtitle_label):
		subtitle_label.visible = false
	if is_instance_valid(char_level_label):
		char_level_label.visible = false
	if is_instance_valid(hp_label):
		hp_label.add_theme_font_size_override("font_size", 11)
	if is_instance_valid(run_level_label):
		run_level_label.add_theme_font_size_override("font_size", 11)
		run_level_label.text = "POZ. 1"

	var avatar_rect := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/AvatarBox/Avatar") as TextureRect
	if is_instance_valid(avatar_rect):
		avatar_rect.custom_minimum_size = Vector2(38, 38)

	if is_instance_valid(stats_card):
		stats_card.custom_minimum_size = Vector2(195, 46)
		var sc_style := StyleBoxFlat.new()
		sc_style.bg_color = Color(0.04, 0.08, 0.14, 0.88)
		sc_style.border_width_left = 1
		sc_style.border_width_top = 1
		sc_style.border_width_right = 1
		sc_style.border_width_bottom = 1
		sc_style.border_color = Color(0.20, 0.75, 1.0, 0.80)
		sc_style.corner_radius_top_left = 6
		sc_style.corner_radius_top_right = 6
		sc_style.corner_radius_bottom_left = 6
		sc_style.corner_radius_bottom_right = 6
		sc_style.content_margin_left = 6
		sc_style.content_margin_top = 4
		sc_style.content_margin_right = 6
		sc_style.content_margin_bottom = 4
		stats_card.add_theme_stylebox_override("panel", SurvivorVisualSystem.panel(SurvivorVisualSystem.LIME, true))

	var margin_c := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin") as MarginContainer
	if is_instance_valid(margin_c):
		margin_c.add_theme_constant_override("margin_left", 6)
		margin_c.add_theme_constant_override("margin_top", 4)
		margin_c.add_theme_constant_override("margin_right", 6)
		margin_c.add_theme_constant_override("margin_bottom", 4)

	var hbox_root := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot") as HBoxContainer
	if is_instance_valid(hbox_root):
		hbox_root.add_theme_constant_override("separation", 6)

	var vbox_stats := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats") as VBoxContainer
	if is_instance_valid(vbox_stats):
		vbox_stats.add_theme_constant_override("separation", 2)

	if is_instance_valid(hp_bar):
		hp_bar.custom_minimum_size = Vector2(110, 8)
		var hp_fill := StyleBoxFlat.new()
		hp_fill.bg_color = Color(0.15, 0.95, 0.45, 1.0)
		hp_fill.corner_radius_top_left = 3
		hp_fill.corner_radius_top_right = 3
		hp_fill.corner_radius_bottom_left = 3
		hp_fill.corner_radius_bottom_right = 3
		hp_bar.add_theme_stylebox_override("fill", hp_fill)

	if is_instance_valid(xp_bar):
		xp_bar.custom_minimum_size = Vector2(110, 4)
		var xp_fill := StyleBoxFlat.new()
		xp_fill.bg_color = Color(0.18, 0.78, 1.0, 1.0)
		xp_fill.corner_radius_top_left = 2
		xp_fill.corner_radius_top_right = 2
		xp_fill.corner_radius_bottom_left = 2
		xp_fill.corner_radius_bottom_right = 2
		xp_bar.add_theme_stylebox_override("fill", xp_fill)

	if is_instance_valid(objectives_panel):
		var obj_style := StyleBoxFlat.new()
		obj_style.bg_color = Color(0.04, 0.07, 0.12, 0.82)
		obj_style.border_width_left = 1
		obj_style.border_width_top = 1
		obj_style.border_width_right = 1
		obj_style.border_width_bottom = 1
		obj_style.border_color = Color(0.20, 0.55, 0.75, 0.65)
		obj_style.corner_radius_top_left = 6
		obj_style.corner_radius_top_right = 6
		obj_style.corner_radius_bottom_left = 6
		obj_style.corner_radius_bottom_right = 6
		obj_style.content_margin_left = 6
		obj_style.content_margin_top = 4
		obj_style.content_margin_right = 6
		obj_style.content_margin_bottom = 4
		objectives_panel.add_theme_stylebox_override("panel", obj_style)

		if is_instance_valid(obj_header):
			obj_header.add_theme_font_size_override("font_size", 10)
			obj_header.text = "MISJA / CELE"
			obj_header.clip_text = true
		if is_instance_valid(obj1_label):
			obj1_label.add_theme_font_size_override("font_size", 11)
			obj1_label.clip_text = true
			obj1_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if is_instance_valid(obj2_label):
			obj2_label.add_theme_font_size_override("font_size", 11)
			obj2_label.clip_text = true
			obj2_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if is_instance_valid(obj3_label):
			obj3_label.add_theme_font_size_override("font_size", 11)
			obj3_label.clip_text = true
			obj3_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	# 1. Przyciski w prawym górnym rogu: 📓 Dziennik, 👤 RPG [TAB] oraz 📱/🖥 9:16↔16:9
	if currency_bar:
		var log_btn := Button.new()
		log_btn.text = "📓 Dziennik"
		log_btn.custom_minimum_size = Vector2(78, 30)
		log_btn.add_theme_font_size_override("font_size", 11)
		log_btn.pressed.connect(func():
			if is_instance_valid(npc_journal_modal):
				npc_journal_modal.visible = not npc_journal_modal.visible
		)
		currency_bar.add_child(log_btn)
		journal_hud_btn = log_btn

		var prof_btn := Button.new()
		prof_btn.text = "👤 RPG"
		prof_btn.custom_minimum_size = Vector2(68, 30)
		prof_btn.add_theme_font_size_override("font_size", 11)
		prof_btn.pressed.connect(toggle_user_profile_panel)
		currency_bar.add_child(prof_btn)
		profile_hud_btn = prof_btn

		orient_hud_btn = Button.new()
		orient_hud_btn.text = "9:16"
		orient_hud_btn.custom_minimum_size = Vector2(64, 30)
		orient_hud_btn.add_theme_font_size_override("font_size", 11)
		orient_hud_btn.pressed.connect(func(): StageDirector.toggle_orientation_mode())
		currency_bar.add_child(orient_hud_btn)

	# 2. Dolny Pasek 5 Slotów Broni i Modułów
	bottom_weapons_panel = PanelContainer.new()
	var bp_style := StyleBoxFlat.new()
	bp_style.bg_color = Color(0.05, 0.08, 0.13, 0.92)
	bp_style.border_width_left = 2
	bp_style.border_width_top = 2
	bp_style.border_width_right = 2
	bp_style.border_width_bottom = 2
	bp_style.border_color = Color(0.20, 0.78, 1.0, 0.80)
	bp_style.corner_radius_top_left = 8
	bp_style.corner_radius_top_right = 8
	bp_style.corner_radius_bottom_left = 8
	bp_style.corner_radius_bottom_right = 8
	bp_style.content_margin_left = 6
	bp_style.content_margin_right = 6
	bp_style.content_margin_top = 4
	bp_style.content_margin_bottom = 4
	bottom_weapons_panel.add_theme_stylebox_override("panel", bp_style)
	hud_root.add_child(bottom_weapons_panel)

	weapon_slots_hbox = HBoxContainer.new()
	weapon_slots_hbox.add_theme_constant_override("separation", 6)
	bottom_weapons_panel.add_child(weapon_slots_hbox)

	# 3. Pasek Mocy Bojowych (ukryty zgodnie z P0-08 auto-combat; zaplecze zachowane)
	powers_hbox = HBoxContainer.new()
	powers_hbox.alignment = BoxContainer.ALIGNMENT_END
	powers_hbox.add_theme_constant_override("separation", 8)
	powers_hbox.visible = false
	hud_root.add_child(powers_hbox)

	dash_skill_btn = _create_power_button("[Spacja] Unik", Color(0.25, 0.90, 1.0), func(): player.perform_dash())
	grenade_skill_btn = _create_power_button("[Q] Granat", Color(1.0, 0.65, 0.20), func(): player.use_plasma_grenade())
	vortex_skill_btn = _create_power_button("[E] Wir A-03", Color(0.75, 0.40, 1.0), func(): player.use_antigravity_vortex())
	powers_hbox.add_child(dash_skill_btn)
	powers_hbox.add_child(grenade_skill_btn)
	powers_hbox.add_child(vortex_skill_btn)

	# 4. Panel Komunikatora NPC (Mara / Iwo / Nina / Kira)
	npc_dialogue_panel = PanelContainer.new()
	npc_dialogue_panel.visible = false
	if ResourceLoader.exists("res://assets/ui/fixpack_20261108/overlays/dialogue_panel.png"):
		var npc_tex_st := StyleBoxTexture.new()
		npc_tex_st.texture = load("res://assets/ui/fixpack_20261108/overlays/dialogue_panel.png")
		npc_tex_st.texture_margin_left = 14
		npc_tex_st.texture_margin_right = 14
		npc_tex_st.texture_margin_top = 10
		npc_tex_st.texture_margin_bottom = 10
		npc_tex_st.content_margin_left = 12
		npc_tex_st.content_margin_right = 12
		npc_tex_st.content_margin_top = 6
		npc_tex_st.content_margin_bottom = 6
		npc_dialogue_panel.add_theme_stylebox_override("panel", npc_tex_st)
	else:
		var npc_st := StyleBoxFlat.new()
		npc_st.bg_color = Color(0.05, 0.09, 0.15, 0.94)
		npc_st.border_width_left = 2
		npc_st.border_width_top = 2
		npc_st.border_width_right = 2
		npc_st.border_width_bottom = 2
		npc_st.border_color = Color(0.32, 0.95, 0.62, 0.88)
		npc_st.corner_radius_top_left = 10
		npc_st.corner_radius_top_right = 10
		npc_st.corner_radius_bottom_left = 10
		npc_st.corner_radius_bottom_right = 10
		npc_st.content_margin_left = 10
		npc_st.content_margin_right = 10
		npc_st.content_margin_top = 6
		npc_st.content_margin_bottom = 6
		npc_dialogue_panel.add_theme_stylebox_override("panel", npc_st)
	hud_root.add_child(npc_dialogue_panel)

	if is_instance_valid(objectives_panel) and ResourceLoader.exists("res://assets/ui/fixpack_20261108/overlays/objective_panel.png"):
		var obj_st := StyleBoxTexture.new()
		obj_st.texture = load("res://assets/ui/fixpack_20261108/overlays/objective_panel.png")
		obj_st.texture_margin_left = 14
		obj_st.texture_margin_right = 14
		obj_st.texture_margin_top = 10
		obj_st.texture_margin_bottom = 10
		obj_st.content_margin_left = 10
		obj_st.content_margin_right = 10
		obj_st.content_margin_top = 6
		obj_st.content_margin_bottom = 6
		objectives_panel.add_theme_stylebox_override("panel", obj_st)

	var npc_hbox := HBoxContainer.new()
	npc_hbox.add_theme_constant_override("separation", 10)
	npc_dialogue_panel.add_child(npc_hbox)

	npc_portrait_rect = TextureRect.new()
	npc_portrait_rect.custom_minimum_size = Vector2(42, 48)
	npc_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	npc_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	npc_hbox.add_child(npc_portrait_rect)

	var npc_vbox := VBoxContainer.new()
	npc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_vbox.add_theme_constant_override("separation", 2)
	npc_hbox.add_child(npc_vbox)

	npc_speaker_lbl = Label.new()
	npc_speaker_lbl.add_theme_font_size_override("font_size", 13)
	npc_speaker_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.65))
	npc_vbox.add_child(npc_speaker_lbl)

	npc_text_lbl = Label.new()
	npc_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	npc_text_lbl.add_theme_font_size_override("font_size", 13)
	npc_text_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	npc_vbox.add_child(npc_text_lbl)

	# 5. Modalny Panel Postaci RPG (UserProfilePanel)
	user_profile_panel = UserProfilePanel.new()
	user_profile_panel.player_ref = player
	user_profile_panel.visible = false
	user_profile_panel.profile_updated.connect(func():
		update_currency_display()
		_refresh_hero_hud_avatar()
		char_level_label.text = "Konto Lv.%d" % StageDirector.character_level
		if StageDirector.current_stage != current_stage_num:
			current_stage_num = StageDirector.current_stage
			_build_layered_arena(current_stage_num)
			start_stage(current_stage_num)
	)
	user_profile_panel.panel_closed.connect(func():
		# Any remaining overlay or terminal run state owns the pause.
		if run_result_state == "active" and not upgrade_panel.visible and not death_panel.visible and not win_panel.visible and not premium_shop_panel.visible:
			get_tree().paused = false
	)
	hud_root.add_child(user_profile_panel)

	# 6. Dodaj przycisk powrotu do Menu Głównego w oknie Zwycięstwa (WinPanel) i Porażki (DeathPanel)
	var win_vbox := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox") as VBoxContainer
	if is_instance_valid(win_vbox):
		var next_btn := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox/NextStageBtn") as Button
		if is_instance_valid(next_btn) and ResourceLoader.exists("res://assets/ui/fixpack_20261108/icons/next.png"):
			next_btn.icon = load("res://assets/ui/fixpack_20261108/icons/next.png")
			next_btn.expand_icon = true
		var restart_w_btn := get_node_or_null("HUD/HUDRoot/WinPanel/CenterContainer/VBox/RestartBtn") as Button
		if is_instance_valid(restart_w_btn) and ResourceLoader.exists("res://assets/ui/fixpack_20261108/icons/retry.png"):
			restart_w_btn.icon = load("res://assets/ui/fixpack_20261108/icons/retry.png")
			restart_w_btn.expand_icon = true

		var menu_w_btn := Button.new()
		menu_w_btn.custom_minimum_size = Vector2(196, 40)
		menu_w_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		menu_w_btn.text = " POWRÓT DO MENU GŁÓWNEGO"
		if ResourceLoader.exists("res://assets/ui/fixpack_20261108/icons/return.png"):
			menu_w_btn.icon = load("res://assets/ui/fixpack_20261108/icons/return.png")
			menu_w_btn.expand_icon = true
		menu_w_btn.pressed.connect(_return_to_main_menu)
		win_vbox.add_child(menu_w_btn)

	var death_vbox := get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox") as VBoxContainer
	if is_instance_valid(death_vbox):
		var revive_ad_btn := get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox/ReviveAdBtn") as Button
		if is_instance_valid(revive_ad_btn) and ResourceLoader.exists("res://assets/ui/fixpack_20261108/icons/revive.png"):
			revive_ad_btn.icon = load("res://assets/ui/fixpack_20261108/icons/revive.png")
			revive_ad_btn.expand_icon = true
		var giveup_btn := get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/GiveUpBtn") as Button
		if is_instance_valid(giveup_btn) and ResourceLoader.exists("res://assets/ui/fixpack_20261108/icons/retry.png"):
			giveup_btn.icon = load("res://assets/ui/fixpack_20261108/icons/retry.png")
			giveup_btn.expand_icon = true

		death_summary_lbl = Label.new()
		death_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		death_summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		death_summary_lbl.custom_minimum_size = Vector2(440, 0)
		death_summary_lbl.add_theme_font_size_override("font_size", 13)
		death_summary_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
		death_vbox.add_child(death_summary_lbl)
		death_vbox.move_child(death_summary_lbl, 2)

		var menu_d_btn := Button.new()
		menu_d_btn.custom_minimum_size = Vector2(196, 40)
		menu_d_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		menu_d_btn.text = " POWRÓT DO MENU GŁÓWNEGO"
		if ResourceLoader.exists("res://assets/ui/fixpack_20261108/icons/return.png"):
			menu_d_btn.icon = load("res://assets/ui/fixpack_20261108/icons/return.png")
			menu_d_btn.expand_icon = true
		menu_d_btn.pressed.connect(_return_to_main_menu)
		death_vbox.add_child(menu_d_btn)

	# 7. Modalny Dziennik Komunikatów NPC (do ponownego czytania dialogów)
	npc_journal_modal = ColorRect.new()
	npc_journal_modal.visible = false
	npc_journal_modal.color = Color(0.02, 0.04, 0.08, 0.90)
	npc_journal_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.add_child(npc_journal_modal)

	# 8. Nakładka Porażki z Balance Addon (MSDefeatOverlay)
	defeat_overlay_inst = DEFEAT_OVERLAY_SCENE.instantiate()
	defeat_overlay_inst.visible = false
	defeat_overlay_inst.request_revive_premium.connect(_on_revive_premium_pressed)
	defeat_overlay_inst.request_revive_ad.connect(_on_revive_ad_pressed)
	defeat_overlay_inst.request_retry.connect(restart_current_stage)
	defeat_overlay_inst.request_return_to_hub.connect(_return_to_main_menu)
	hud_root.add_child(defeat_overlay_inst)

	var j_center := CenterContainer.new()
	j_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	npc_journal_modal.add_child(j_center)

	var j_card := PanelContainer.new()
	j_card.custom_minimum_size = Vector2(480, 340)
	var j_st := StyleBoxFlat.new()
	j_st.bg_color = Color(0.05, 0.09, 0.16, 0.98)
	j_st.border_width_left = 2
	j_st.border_width_top = 2
	j_st.border_width_right = 2
	j_st.border_width_bottom = 2
	j_st.border_color = Color(0.32, 0.95, 0.65, 0.92)
	j_st.corner_radius_top_left = 12
	j_st.corner_radius_top_right = 12
	j_st.corner_radius_bottom_left = 12
	j_st.corner_radius_bottom_right = 12
	j_st.content_margin_left = 14
	j_st.content_margin_right = 14
	j_st.content_margin_top = 12
	j_st.content_margin_bottom = 12
	j_card.add_theme_stylebox_override("panel", j_st)
	j_center.add_child(j_card)

	var j_vbox := VBoxContainer.new()
	j_vbox.add_theme_constant_override("separation", 10)
	j_card.add_child(j_vbox)

	var j_title := Label.new()
	j_title.text = "📓 DZIENNIK KOMUNIKATÓW DOWÓDZTWA NPC"
	j_title.add_theme_font_size_override("font_size", 15)
	j_title.add_theme_color_override("font_color", Color(0.38, 1.0, 0.68))
	j_vbox.add_child(j_title)

	npc_journal_lbl = Label.new()
	npc_journal_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	npc_journal_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	npc_journal_lbl.add_theme_font_size_override("font_size", 12)
	npc_journal_lbl.text = "Brak zapisanych komunikatów w tej operacji."
	j_vbox.add_child(npc_journal_lbl)

	var j_close := Button.new()
	j_close.text = "✕ ZAMKNIJ DZIENNIK"
	j_close.custom_minimum_size = Vector2(0, 36)
	j_close.pressed.connect(func(): npc_journal_modal.visible = false)
	j_vbox.add_child(j_close)

func _return_to_main_menu() -> void:
	if run_result_state == "awaiting_revive":
		_finalize_failure_once()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _trigger_biome_hazard() -> void:
	if not is_instance_valid(player) or not is_instance_valid(effects_layer):
		return
	var cfg := StageDirector.get_stage_config(current_stage_num)
	var haz_type := String(cfg.get("hazard", "acid_spots"))
	var angle := randf() * TAU
	var h_pos := player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(95.0, 210.0)
	var vfx := Sprite2D.new()
	vfx.texture = AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/vfx/toxic_splash.png")
	vfx.material = PowerEffects.get_additive_mat()
	vfx.global_position = h_pos
	vfx.scale = Vector2(0.85, 0.85)
	match haz_type:
		"cryo_vent":
			vfx.modulate = Color(0.35, 0.88, 1.0, 0.78)
		"radiation_pulse":
			vfx.modulate = Color(0.95, 0.35, 1.0, 0.78)
		"falling_debris":
			vfx.modulate = Color(1.0, 0.62, 0.25, 0.78)
		_:
			vfx.modulate = Color(0.45, 1.0, 0.28, 0.78)
	effects_layer.add_child(vfx)
	var tw := vfx.create_tween()
	tw.tween_property(vfx, "scale", Vector2(1.18, 1.18), 0.9)
	tw.tween_callback(func():
		if is_instance_valid(player) and player.global_position.distance_to(h_pos) <= 82.0:
			player.take_damage(8.0 + float(current_stage_num) * 0.15)
	)
	tw.tween_property(vfx, "modulate:a", 0.0, 0.45)
	tw.tween_callback(vfx.queue_free)

func _create_power_button(label_txt: String, border_col: Color, cb: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(106, 50)
	btn.text = label_txt
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.10, 0.16, 0.94)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 2
	st.border_color = border_col
	st.corner_radius_top_left = 8
	st.corner_radius_top_right = 8
	st.corner_radius_bottom_left = 8
	st.corner_radius_bottom_right = 8
	SurvivorVisualSystem.decorate_button(btn, border_col, 50.0)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(cb)
	return btn

func _update_active_power_buttons() -> void:
	if not is_instance_valid(player):
		return
	if dash_skill_btn:
		dash_skill_btn.text = "[Spacja] Unik\nGOTOWY" if player.dash_timer <= 0.0 else "[Spacja] Unik\n%.1fs" % player.dash_timer
	if grenade_skill_btn:
		grenade_skill_btn.text = "[Q] Granat\nGOTOWY" if player.grenade_timer <= 0.0 else "[Q] Granat\n%.1fs" % player.grenade_timer
	if vortex_skill_btn:
		vortex_skill_btn.text = "[E] Wir A-03\nGOTOWY" if player.vortex_timer <= 0.0 else "[E] Wir A-03\n%.1fs" % player.vortex_timer

func _refresh_weapon_loadout_bar() -> void:
	if not is_instance_valid(weapon_slots_hbox):
		return
	for c in weapon_slots_hbox.get_children():
		c.queue_free()

	var items: Array[Dictionary] = [
		{"icon": "res://assets/mutantsurvivor_ch01/weapons/weapon_1.png", "lvl": 1 + int(upgrade_tiers.get("plasma_dmg", 0))}
	]
	for up_id in upgrade_tiers.keys():
		if up_id == "plasma_dmg":
			continue
		if items.size() >= 5:
			break
		items.append({
			"icon": POWER_ICONS.get(up_id, "res://assets/mutantsurvivor_ch01/weapons/weapon_1.png"),
			"lvl": int(upgrade_tiers[up_id])
		})
	while items.size() < 5:
		items.append({"icon": "", "lvl": 0})

	for slot_data in items:
		var slot_box := PanelContainer.new()
		slot_box.custom_minimum_size = Vector2(46, 44) if StageDirector.is_portrait_mode() else Vector2(56, 50)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.08, 0.12, 0.19, 0.95)
		st.border_width_left = 1
		st.border_width_top = 1
		st.border_width_right = 1
		st.border_width_bottom = 1
		var active := int(slot_data["lvl"]) > 0
		st.border_color = Color(0.25, 0.90, 1.0, 0.9) if active else Color(0.22, 0.30, 0.40, 0.5)
		st.corner_radius_top_left = 6
		st.corner_radius_top_right = 6
		st.corner_radius_bottom_left = 6
		st.corner_radius_bottom_right = 6
		slot_box.add_theme_stylebox_override("panel", st)

		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_box.add_child(v)

		if active and not String(slot_data["icon"]).is_empty():
			var tr := TextureRect.new()
			tr.texture = AssetRegistry.get_tex(String(slot_data["icon"]))
			tr.custom_minimum_size = Vector2(28, 23) if StageDirector.is_portrait_mode() else Vector2(34, 28)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			v.add_child(tr)

			var l := Label.new()
			l.text = "Lv.%d" % int(slot_data["lvl"])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.add_theme_font_size_override("font_size", 10)
			l.add_theme_color_override("font_color", Color(0.4, 0.98, 1.0))
			v.add_child(l)
		else:
			var empty_l := Label.new()
			empty_l.text = "—"
			empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_l.add_theme_color_override("font_color", Color(0.35, 0.45, 0.55))
			v.add_child(empty_l)

		weapon_slots_hbox.add_child(slot_box)

func toggle_user_profile_panel() -> void:
	if not is_instance_valid(user_profile_panel):
		return
	if is_instance_valid(player):
		player.external_move_dir = Vector2.ZERO
	if is_instance_valid(joystick):
		joystick.cancel_touch()
	if user_profile_panel.visible:
		user_profile_panel.close_panel()
	else:
		get_tree().paused = true
		user_profile_panel.open_panel(0)

func _finalize_failure_once() -> void:
	if run_result_state != "awaiting_revive":
		return
	run_result_state = "failure_final"
	StageDirector.complete_stage_run(current_stage_num, false, current_wave_num - 1)
	update_currency_display()

func _on_player_died() -> void:
	if run_result_state != "active":
		return
	run_result_state = "awaiting_revive"
	StageDirector.play_sfx("defeat")
	win_panel.visible = false
	upgrade_panel.visible = false
	var mins := int(total_run_elapsed / 60.0)
	var secs := int(total_run_elapsed) % 60
	var ad_btn := get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox/ReviveAdBtn") as Button
	if not is_instance_valid(ad_btn):
		ad_btn = get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/ReviveAdBtn") as Button
	var prem_btn := get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox/ReviveDMBtn") as Button
	if not is_instance_valid(prem_btn):
		prem_btn = get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/RevivePremiumBtn") as Button
	if is_instance_valid(ad_btn):
		if has_used_revive:
			ad_btn.disabled = true
			ad_btn.text = "✓ WSKRZESZENIE WYKORZYSTANE (LIMIT 1/ETAP)"
		else:
			# No rewarded-ad SDK / verified completion callback in this beta.
			ad_btn.disabled = true
			ad_btn.text = "REKLAMY NIEDOSTĘPNE W BECIE"
	var objective_destroyed: bool = primary_objective_type == "defend_node" and primary_objective_hp <= 0.0
	if is_instance_valid(prem_btn):
		prem_btn.disabled = has_used_revive or objective_destroyed
	if is_instance_valid(death_summary_lbl):
		death_summary_lbl.text = (
			"⏱ Czas przeżycia: %02d:%02d  |  🌊 Osiągnięta fala: %d/%d  |  ☠ Pokonani mutanci: %d\n" % [mins, secs, current_wave_num, max_waves_in_stage, enemies_killed_in_run] +
			"Nagroda za porażkę zostanie rozliczona dopiero po rezygnacji z wskrzeszenia.\n" +
			("Cel obrony został zniszczony — wskrzeszenie nie przywróci misji. Powtórz etap lub wróć do bazy." if objective_destroyed else
			"Możesz skorzystać z 1 wskrzeszenia (z 3.5s tarczą ochronną), powtórzyć etap lub wrócić do bazy." if not has_used_revive else
			"Limit 1 wskrzeszenia na etap został już wykorzystany.")
		)
	player.external_move_dir = Vector2.ZERO
	if is_instance_valid(joystick):
		joystick.cancel_touch()
	get_tree().paused = true
	# The modular defeat screen replaces the legacy DeathPanel. Keeping both
	# visible overlays two full-screen cards and blocks portrait touch input.
	death_panel.visible = not is_instance_valid(defeat_overlay_inst)

	if is_instance_valid(defeat_overlay_inst):
		var cfg_data := {
			"title": "MISJA NIEUDANA",
			"wave": current_wave_num,
			"kills": enemies_killed_in_run,
			"time_seconds": int(total_run_elapsed),
			"reason": ("Etap %03d: Cel obrony został zniszczony. Wskrzeszenie nie jest dostępne." % current_stage_num if objective_destroyed else
				"Etap %03d: Ulepsz wyposażenie lub spróbuj innej strategii." % current_stage_num),
			"already_revived": has_used_revive,
			"gems": StageDirector.dark_matter_gems,
			"revive_cost": 30,
			"attempts": StageDirector.attempts,
			"ad_available": false
		}
		defeat_overlay_inst.call("configure", cfg_data)
		defeat_overlay_inst.visible = true

func _on_revive_ad_pressed() -> void:
	# Block unverified ad rewards until the Android rewarded-ad SDK is integrated.
	# Re-enable only inside the SDK's successful server-verified completion callback.
	return

func _on_revive_premium_pressed() -> void:
	if run_result_state != "awaiting_revive" or has_used_revive:
		return
	# Reviving the hero cannot repair a destroyed defense objective.
	# Reject the purchase BEFORE charging the player's premium currency.
	if primary_objective_type == "defend_node" and primary_objective_hp <= 0.0:
		return
	if StageDirector.spend_premium_gems(30):
		StageDirector.save_campaign_profile()
		has_used_revive = true
		run_result_state = "active"
		premium_shop_panel.visible = false
		death_panel.visible = false
		if is_instance_valid(defeat_overlay_inst): defeat_overlay_inst.visible = false
		get_tree().paused = false
		player.revive(1.0)
		update_currency_display()
	else:
		toggle_premium_shop()

func toggle_premium_shop() -> void:
	premium_shop_panel.visible = not premium_shop_panel.visible
	# Closing the shop must not resume gameplay while the player is
	# still dead, viewing victory rewards or selecting an upgrade.
	get_tree().paused = (premium_shop_panel.visible
		or run_result_state != "active"
		or upgrade_panel.visible)

func _on_buy_energy_pack() -> void:
	if StageDirector.spend_premium_gems(20):
		StageDirector.credits += 150
		StageDirector.save_campaign_profile()
		update_currency_display()

func _on_watch_ad_for_energy() -> void:
	# Previous prototype granted 75 credits without displaying an advertisement.
	# No reward is issued until an ad completion callback is integrated and verified.
	return

func update_currency_display() -> void:
	energy_label.text = "%d" % StageDirector.credits
	dark_matter_label.text = "%d" % StageDirector.dark_matter_gems
