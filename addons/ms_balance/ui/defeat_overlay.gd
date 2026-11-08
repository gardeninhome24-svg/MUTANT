extends Control
class_name MSDefeatOverlay
## True Modular High-Fidelity Defeat Overlay.
## Supports dynamic 16:9 Landscape and 9:16 Portrait layouts.
## Real dynamic Labels, real TextureButtons with Normal/Hover/Pressed/Disabled states.

signal request_revive_premium
signal request_revive_ad
signal request_retry
signal request_return_to_hub

@onready var backdrop: TextureRect = $Backdrop
@onready var card_center: Control = $CardCenter
@onready var card_frame: TextureRect = $CardCenter/CardFrame

@onready var stat_tiles: Control = $CardCenter/StatTiles
@onready var tile_fala: TextureRect = $CardCenter/StatTiles/TileFala
@onready var tile_czas: TextureRect = $CardCenter/StatTiles/TileCzas
@onready var tile_zabici: TextureRect = $CardCenter/StatTiles/TileZabici

@onready var icon_fala: TextureRect = $CardCenter/StatTiles/TileFala/Icon
@onready var title_fala: Label = $CardCenter/StatTiles/TileFala/Title
@onready var wave_val_lbl: Label = $CardCenter/StatTiles/TileFala/WaveVal

@onready var icon_czas: TextureRect = $CardCenter/StatTiles/TileCzas/Icon
@onready var title_czas: Label = $CardCenter/StatTiles/TileCzas/Title
@onready var time_val_lbl: Label = $CardCenter/StatTiles/TileCzas/TimeVal

@onready var icon_zabici: TextureRect = $CardCenter/StatTiles/TileZabici/Icon
@onready var title_zabici: Label = $CardCenter/StatTiles/TileZabici/Title
@onready var kills_val_lbl: Label = $CardCenter/StatTiles/TileZabici/KillsVal

@onready var prompt_lbl: Label = $CardCenter/PromptLabel
@onready var action_row1: Control = $CardCenter/ActionRow1
@onready var tex_revive_btn: TextureButton = $CardCenter/ActionRow1/BtnReviveGold
@onready var cost_badge: HBoxContainer = $CardCenter/ActionRow1/BtnReviveGold/CostBadge
@onready var cryst_icon: TextureRect = $CardCenter/ActionRow1/BtnReviveGold/CostBadge/CrystIcon
@onready var gem_cost_lbl: Label = $CardCenter/ActionRow1/BtnReviveGold/CostBadge/CostLabel

@onready var tex_ad_btn: TextureButton = $CardCenter/ActionRow1/BtnReviveAd
@onready var tex_attempt_info: TextureRect = $CardCenter/ActionRow1/BtnAttempt
@onready var attempt_count_lbl: Label = $CardCenter/ActionRow1/BtnAttempt/CountLabel

@onready var action_row2: Control = $CardCenter/ActionRow2
@onready var tex_retry_btn: TextureButton = $CardCenter/ActionRow2/BtnRetry
@onready var tex_hub_btn: TextureButton = $CardCenter/ActionRow2/BtnHub

# Legacy references for tests
@onready var score_label: Label = $Center/Margin/VBox/Score
@onready var summary_label: Label = $Center/Margin/VBox/Summary
@onready var revive_button: Button = $Center/Margin/VBox/RevivePremium
@onready var ad_button: Button = $Center/Margin/VBox/ReviveAd
@onready var retry_button: Button = $Center/Margin/VBox/Retry
@onready var hub_button: Button = $Center/Margin/VBox/Hub

# 16:9 Textures
var _tex_landscape_card: Texture2D
var _tex_landscape_bg: Texture2D
var _tex_gold_norm: Texture2D
var _tex_gold_hov: Texture2D
var _tex_gold_pres: Texture2D
var _tex_gold_dis: Texture2D
var _tex_ad: Texture2D
var _tex_att: Texture2D
var _tex_retry: Texture2D
var _tex_hub: Texture2D

# 9:16 Textures
var _tex_portrait_card: Texture2D
var _tex_portrait_bg: Texture2D
var _tex_port_gold_norm: Texture2D
var _tex_port_gold_hov: Texture2D
var _tex_port_gold_pres: Texture2D
var _tex_port_gold_dis: Texture2D
var _tex_port_ad: Texture2D
var _tex_port_att: Texture2D
var _tex_port_retry: Texture2D
var _tex_port_hub: Texture2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_textures()
	_connect_signals()
	update_responsive_layout()
	get_viewport().size_changed.connect(update_responsive_layout)

func _load_textures() -> void:
	# Landscape
	if ResourceLoader.exists("res://addons/ms_balance/assets/card_armored_frame.png"):
		_tex_landscape_card = load("res://addons/ms_balance/assets/card_armored_frame.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/defeat_backdrop_landscape.png"):
		_tex_landscape_bg = load("res://addons/ms_balance/assets/defeat_backdrop_landscape.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_revive_gold_normal.png"):
		_tex_gold_norm = load("res://addons/ms_balance/assets/btn_revive_gold_normal.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_revive_gold_hover.png"):
		_tex_gold_hov = load("res://addons/ms_balance/assets/btn_revive_gold_hover.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_revive_gold_pressed.png"):
		_tex_gold_pres = load("res://addons/ms_balance/assets/btn_revive_gold_pressed.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_revive_gold_disabled.png"):
		_tex_gold_dis = load("res://addons/ms_balance/assets/btn_revive_gold_disabled.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_revive_ad.png"):
		_tex_ad = load("res://addons/ms_balance/assets/btn_revive_ad.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_attempt_purple.png"):
		_tex_att = load("res://addons/ms_balance/assets/btn_attempt_purple.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_retry_blue.png"):
		_tex_retry = load("res://addons/ms_balance/assets/btn_retry_blue.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_hub_dark.png"):
		_tex_hub = load("res://addons/ms_balance/assets/btn_hub_dark.png")

	# Portrait
	if ResourceLoader.exists("res://addons/ms_balance/assets/card_armored_frame_916.png"):
		_tex_portrait_card = load("res://addons/ms_balance/assets/card_armored_frame_916.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/defeat_backdrop_portrait.png"):
		_tex_portrait_bg = load("res://addons/ms_balance/assets/defeat_backdrop_portrait.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_gold_normal.png"):
		_tex_port_gold_norm = load("res://addons/ms_balance/assets/btn_port_gold_normal.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_gold_hover.png"):
		_tex_port_gold_hov = load("res://addons/ms_balance/assets/btn_port_gold_hover.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_gold_pressed.png"):
		_tex_port_gold_pres = load("res://addons/ms_balance/assets/btn_port_gold_pressed.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_gold_disabled.png"):
		_tex_port_gold_dis = load("res://addons/ms_balance/assets/btn_port_gold_disabled.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_ad.png"):
		_tex_port_ad = load("res://addons/ms_balance/assets/btn_port_ad.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_attempt.png"):
		_tex_port_att = load("res://addons/ms_balance/assets/btn_port_attempt.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_retry.png"):
		_tex_port_retry = load("res://addons/ms_balance/assets/btn_port_retry.png")
	if ResourceLoader.exists("res://addons/ms_balance/assets/btn_port_hub.png"):
		_tex_port_hub = load("res://addons/ms_balance/assets/btn_port_hub.png")

func _connect_signals() -> void:
	if is_instance_valid(tex_revive_btn) and not tex_revive_btn.pressed.is_connected(_on_revive_pressed):
		tex_revive_btn.pressed.connect(_on_revive_pressed)
	if is_instance_valid(tex_ad_btn) and not tex_ad_btn.pressed.is_connected(_on_ad_pressed):
		tex_ad_btn.pressed.connect(_on_ad_pressed)
	if is_instance_valid(tex_retry_btn) and not tex_retry_btn.pressed.is_connected(_on_retry_pressed):
		tex_retry_btn.pressed.connect(_on_retry_pressed)
	if is_instance_valid(tex_hub_btn) and not tex_hub_btn.pressed.is_connected(_on_hub_pressed):
		tex_hub_btn.pressed.connect(_on_hub_pressed)

	# Legacy proxies
	if is_instance_valid(revive_button) and not revive_button.pressed.is_connected(_on_revive_pressed):
		revive_button.pressed.connect(_on_revive_pressed)
	if is_instance_valid(ad_button) and not ad_button.pressed.is_connected(_on_ad_pressed):
		ad_button.pressed.connect(_on_ad_pressed)
	if is_instance_valid(retry_button) and not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if is_instance_valid(hub_button) and not hub_button.pressed.is_connected(_on_hub_pressed):
		hub_button.pressed.connect(_on_hub_pressed)

func _on_revive_pressed() -> void:
	request_revive_premium.emit()

func _on_ad_pressed() -> void:
	request_revive_ad.emit()

func _on_retry_pressed() -> void:
	request_retry.emit()

func _on_hub_pressed() -> void:
	request_return_to_hub.emit()

func update_responsive_layout() -> void:
	if not is_instance_valid(card_center) or not is_instance_valid(backdrop):
		return
	var vp_size := get_viewport_rect().size
	var is_portrait := vp_size.y > vp_size.x

	if is_portrait:
		_apply_portrait_layout(vp_size)
	else:
		_apply_landscape_layout(vp_size)

func _apply_landscape_layout(vp_size: Vector2) -> void:
	if _tex_landscape_bg:
		backdrop.texture = _tex_landscape_bg
	if _tex_landscape_card and is_instance_valid(card_frame):
		card_frame.texture = _tex_landscape_card

	card_center.custom_minimum_size = Vector2(870.0, 660.0)
	card_center.size = Vector2(870.0, 660.0)
	card_center.position = (vp_size - card_center.size) * 0.5

	# Button textures (16:9)
	if is_instance_valid(tex_revive_btn):
		if _tex_gold_norm: tex_revive_btn.texture_normal = _tex_gold_norm
		if _tex_gold_hov: tex_revive_btn.texture_hover = _tex_gold_hov
		if _tex_gold_pres: tex_revive_btn.texture_pressed = _tex_gold_pres
		if _tex_gold_dis: tex_revive_btn.texture_disabled = _tex_gold_dis
	if is_instance_valid(tex_ad_btn) and _tex_ad:
		tex_ad_btn.texture_normal = _tex_ad
	if is_instance_valid(tex_attempt_info) and _tex_att:
		tex_attempt_info.texture = _tex_att
	if is_instance_valid(tex_retry_btn) and _tex_retry:
		tex_retry_btn.texture_normal = _tex_retry
	if is_instance_valid(tex_hub_btn) and _tex_hub:
		tex_hub_btn.texture_normal = _tex_hub

	# Stat tiles in horizontal row
	if is_instance_valid(tile_fala):
		tile_fala.position = Vector2(45, 222)
		tile_fala.size = Vector2(260, 95)
		if is_instance_valid(icon_fala):
			icon_fala.position = Vector2(16, 18)
			icon_fala.size = Vector2(56, 56)
		if is_instance_valid(title_fala):
			title_fala.position = Vector2(85, 16)
			title_fala.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_instance_valid(wave_val_lbl):
			wave_val_lbl.position = Vector2(85, 36)
			wave_val_lbl.size = Vector2(155, 48)
			wave_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	if is_instance_valid(tile_czas):
		tile_czas.position = Vector2(315, 222)
		tile_czas.size = Vector2(260, 95)
		if is_instance_valid(icon_czas):
			icon_czas.position = Vector2(16, 18)
			icon_czas.size = Vector2(56, 56)
		if is_instance_valid(title_czas):
			title_czas.position = Vector2(85, 16)
			title_czas.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_instance_valid(time_val_lbl):
			time_val_lbl.position = Vector2(85, 36)
			time_val_lbl.size = Vector2(155, 48)
			time_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	if is_instance_valid(tile_zabici):
		tile_zabici.position = Vector2(580, 222)
		tile_zabici.size = Vector2(260, 95)
		if is_instance_valid(icon_zabici):
			icon_zabici.position = Vector2(16, 18)
			icon_zabici.size = Vector2(56, 56)
		if is_instance_valid(title_zabici):
			title_zabici.position = Vector2(85, 16)
			title_zabici.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_instance_valid(kills_val_lbl):
			kills_val_lbl.position = Vector2(85, 36)
			kills_val_lbl.size = Vector2(155, 48)
			kills_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Prompt
	if is_instance_valid(prompt_lbl):
		prompt_lbl.position = Vector2(100, 332)
		prompt_lbl.size = Vector2(670, 26)

	# Action Row 1
	var ad_shown := tex_ad_btn.visible if is_instance_valid(tex_ad_btn) else false
	if is_instance_valid(tex_revive_btn):
		tex_revive_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_revive_btn.size = Vector2(260, 105)
		tex_revive_btn.position = Vector2(37, 372) if ad_shown else Vector2(140, 372)
		if is_instance_valid(cost_badge):
			cost_badge.position = Vector2(138, 16)
			cost_badge.size = Vector2(80, 36)
			if is_instance_valid(cryst_icon):
				cryst_icon.visible = false
			if is_instance_valid(gem_cost_lbl):
				gem_cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				gem_cost_lbl.set("theme_override_font_sizes/font_size", 28)

	if is_instance_valid(tex_ad_btn):
		tex_ad_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_ad_btn.size = Vector2(260, 105)
		tex_ad_btn.position = Vector2(319, 372)

	if is_instance_valid(tex_attempt_info):
		tex_attempt_info.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_attempt_info.size = Vector2(260, 105)
		tex_attempt_info.position = Vector2(590, 372) if ad_shown else Vector2(470, 372)
		if is_instance_valid(attempt_count_lbl):
			attempt_count_lbl.position = Vector2(115, 16)
			attempt_count_lbl.size = Vector2(70, 36)
			attempt_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			attempt_count_lbl.set("theme_override_font_sizes/font_size", 28)

	# Action Row 2
	if is_instance_valid(tex_retry_btn):
		tex_retry_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_retry_btn.size = Vector2(355, 80)
		tex_retry_btn.position = Vector2(65, 495)
	if is_instance_valid(tex_hub_btn):
		tex_hub_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_hub_btn.size = Vector2(355, 80)
		tex_hub_btn.position = Vector2(450, 495)

func _apply_portrait_layout(vp_size: Vector2) -> void:
	if _tex_portrait_bg:
		backdrop.texture = _tex_portrait_bg
	if _tex_portrait_card and is_instance_valid(card_frame):
		card_frame.texture = _tex_portrait_card

	var card_w := 660.0
	var card_h := 1140.0
	card_center.custom_minimum_size = Vector2(card_w, card_h)
	card_center.size = Vector2(card_w, card_h)
	card_center.position = (vp_size - card_center.size) * 0.5

	# Button textures (9:16 native)
	if is_instance_valid(tex_revive_btn):
		if _tex_port_gold_norm: tex_revive_btn.texture_normal = _tex_port_gold_norm
		if _tex_port_gold_hov: tex_revive_btn.texture_hover = _tex_port_gold_hov
		if _tex_port_gold_pres: tex_revive_btn.texture_pressed = _tex_port_gold_pres
		if _tex_port_gold_dis: tex_revive_btn.texture_disabled = _tex_port_gold_dis
	if is_instance_valid(tex_ad_btn) and _tex_port_ad:
		tex_ad_btn.texture_normal = _tex_port_ad
	if is_instance_valid(tex_attempt_info) and _tex_port_att:
		tex_attempt_info.texture = _tex_port_att
	if is_instance_valid(tex_retry_btn) and _tex_port_retry:
		tex_retry_btn.texture_normal = _tex_port_retry
	if is_instance_valid(tex_hub_btn) and _tex_hub:
		tex_hub_btn.texture_normal = _tex_port_hub

	# Vertical stack of stat tiles
	var tile_w := 520.0
	var tile_h := 76.0
	var tile_x := (card_w - tile_w) * 0.5

	if is_instance_valid(tile_fala):
		tile_fala.position = Vector2(tile_x, 310)
		tile_fala.size = Vector2(tile_w, tile_h)
		if is_instance_valid(icon_fala):
			icon_fala.position = Vector2(18, 10)
			icon_fala.size = Vector2(56, 56)
		if is_instance_valid(title_fala):
			title_fala.position = Vector2(95, 26)
			title_fala.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_instance_valid(wave_val_lbl):
			wave_val_lbl.position = Vector2(300, 14)
			wave_val_lbl.size = Vector2(200, 48)
			wave_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	if is_instance_valid(tile_czas):
		tile_czas.position = Vector2(tile_x, 396)
		tile_czas.size = Vector2(tile_w, tile_h)
		if is_instance_valid(icon_czas):
			icon_czas.position = Vector2(18, 10)
			icon_czas.size = Vector2(56, 56)
		if is_instance_valid(title_czas):
			title_czas.position = Vector2(95, 26)
			title_czas.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_instance_valid(time_val_lbl):
			time_val_lbl.position = Vector2(300, 14)
			time_val_lbl.size = Vector2(200, 48)
			time_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	if is_instance_valid(tile_zabici):
		tile_zabici.position = Vector2(tile_x, 482)
		tile_zabici.size = Vector2(tile_w, tile_h)
		if is_instance_valid(icon_zabici):
			icon_zabici.position = Vector2(18, 10)
			icon_zabici.size = Vector2(56, 56)
		if is_instance_valid(title_zabici):
			title_zabici.position = Vector2(95, 26)
			title_zabici.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_instance_valid(kills_val_lbl):
			kills_val_lbl.position = Vector2(300, 14)
			kills_val_lbl.size = Vector2(200, 48)
			kills_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Prompt
	if is_instance_valid(prompt_lbl):
		prompt_lbl.position = Vector2(50, 570)
		prompt_lbl.size = Vector2(560, 26)

	# Vertical stack of native portrait buttons (520x88)
	var ad_shown := tex_ad_btn.visible if is_instance_valid(tex_ad_btn) else false
	var btn_w := 520.0
	var btn_h := 88.0
	var btn_x := (card_w - btn_w) * 0.5

	var y_cursor := 610.0
	if is_instance_valid(tex_revive_btn):
		tex_revive_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_revive_btn.position = Vector2(btn_x, y_cursor)
		tex_revive_btn.size = Vector2(btn_w, btn_h)
		if is_instance_valid(cost_badge):
			cost_badge.position = Vector2(226, 20)
			cost_badge.size = Vector2(64, 36)
			if is_instance_valid(cryst_icon):
				cryst_icon.visible = false
			if is_instance_valid(gem_cost_lbl):
				gem_cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				gem_cost_lbl.set("theme_override_font_sizes/font_size", 24)
		y_cursor += 96.0

	if is_instance_valid(tex_ad_btn) and ad_shown:
		tex_ad_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_ad_btn.position = Vector2(btn_x, y_cursor)
		tex_ad_btn.size = Vector2(btn_w, btn_h)
		y_cursor += 96.0

	if is_instance_valid(tex_attempt_info):
		tex_attempt_info.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_attempt_info.position = Vector2(btn_x, y_cursor)
		tex_attempt_info.size = Vector2(btn_w, btn_h)
		if is_instance_valid(attempt_count_lbl):
			attempt_count_lbl.position = Vector2(230, 24)
			attempt_count_lbl.size = Vector2(80, 36)
			attempt_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			attempt_count_lbl.set("theme_override_font_sizes/font_size", 28)
		y_cursor += 96.0

	if is_instance_valid(tex_retry_btn):
		tex_retry_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_retry_btn.position = Vector2(btn_x, y_cursor)
		tex_retry_btn.size = Vector2(btn_w, btn_h)
		y_cursor += 96.0

	if is_instance_valid(tex_hub_btn):
		tex_hub_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tex_hub_btn.position = Vector2(btn_x, y_cursor)
		tex_hub_btn.size = Vector2(btn_w, btn_h)

func configure(data: Dictionary) -> void:
	if not is_node_ready():
		await ready

	var waves := int(data.get("wave", 5))
	var kills := int(data.get("kills", 142))
	var time_sec := maxi(0, int(data.get("time_seconds", 272)))
	var reason_text := String(data.get("reason", "Ulepsz wyposażenie lub spróbuj innej strategii."))
	var gems_avail := int(data.get("gems", 300))
	var revive_cost := int(data.get("revive_cost", 300))
	var attempts_cnt := int(data.get("attempts", 1))
	var spent := bool(data.get("already_revived", false))
	var ad_avail := bool(data.get("ad_available", true))

	# Format score lines for test assertions
	if is_instance_valid(score_label):
		score_label.text = "FALA %d/10   |   %02d:%02d   |   %d MUTANTÓW" % [waves, int(time_sec / 60), time_sec % 60, kills]
	if is_instance_valid(summary_label):
		summary_label.text = reason_text

	# Update real modular dynamic Labels
	if is_instance_valid(wave_val_lbl):
		wave_val_lbl.text = "%d/10" % waves
	if is_instance_valid(time_val_lbl):
		time_val_lbl.text = "%02d:%02d" % [int(time_sec / 60), time_sec % 60]
	if is_instance_valid(kills_val_lbl):
		kills_val_lbl.text = "%d" % kills

	# Dynamic cost & count labels
	if is_instance_valid(gem_cost_lbl):
		gem_cost_lbl.text = str(revive_cost)
	if is_instance_valid(attempt_count_lbl):
		attempt_count_lbl.text = "x%d" % attempts_cnt

	# Revive Button State (Normal vs Disabled)
	var can_revive := (gems_avail >= 30 and not spent)
	if is_instance_valid(tex_revive_btn):
		tex_revive_btn.disabled = not can_revive
	if is_instance_valid(gem_cost_lbl):
		if can_revive:
			gem_cost_lbl.set("theme_override_colors/font_color", Color(1, 1, 1, 1))
		else:
			gem_cost_lbl.set("theme_override_colors/font_color", Color(0.55, 0.58, 0.65, 0.85))

	if is_instance_valid(revive_button):
		revive_button.disabled = not can_revive

	# Ad Button State (Visible vs Hidden)
	var can_ad := (ad_avail and not spent)
	if is_instance_valid(tex_ad_btn):
		tex_ad_btn.visible = can_ad
	if is_instance_valid(ad_button):
		ad_button.visible = can_ad

	update_responsive_layout()
