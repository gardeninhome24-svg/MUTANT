extends Control
class_name MSDefeatOverlay
## Presentation-only prefab for Defeat Screen.
## Bridge signal handlers from scripts/main.gd; never touch wallet directly here.

signal request_revive_premium
signal request_revive_ad
signal request_retry
signal request_return_to_hub

@onready var backdrop: TextureRect = $Backdrop
@onready var center_panel: PanelContainer = $Center
@onready var title_label: Label = $Center/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Margin/VBox/Subtitle
@onready var score_label: Label = $Center/Margin/VBox/Score
@onready var summary_label: Label = $Center/Margin/VBox/Summary
@onready var revive_button: Button = $Center/Margin/VBox/RevivePremium
@onready var ad_button: Button = $Center/Margin/VBox/ReviveAd
@onready var retry_button: Button = $Center/Margin/VBox/Retry
@onready var hub_button: Button = $Center/Margin/VBox/Hub

@onready var wave_val_lbl: Label = $Center/Margin/VBox/StatsRow/StatCardWave/HBox/VBox/WaveVal
@onready var time_val_lbl: Label = $Center/Margin/VBox/StatsRow/StatCardTime/HBox/VBox/TimeVal
@onready var kills_val_lbl: Label = $Center/Margin/VBox/StatsRow/StatCardKills/HBox/VBox/KillsVal

@onready var stat_card_wave: PanelContainer = $Center/Margin/VBox/StatsRow/StatCardWave
@onready var stat_card_time: PanelContainer = $Center/Margin/VBox/StatsRow/StatCardTime
@onready var stat_card_kills: PanelContainer = $Center/Margin/VBox/StatsRow/StatCardKills

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_visual_styling()
	_connect_signals()
	update_responsive_layout()
	get_viewport().size_changed.connect(update_responsive_layout)

func _apply_visual_styling() -> void:
	# 1. Main Modal Frame (Heavy Sci-Fi Armored Card)
	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color(0.045, 0.065, 0.105, 0.96)
	card_bg.border_color = Color(0.88, 0.20, 0.20, 0.95)
	card_bg.border_width_left = 2
	card_bg.border_width_top = 2
	card_bg.border_width_right = 2
	card_bg.border_width_bottom = 2
	card_bg.corner_radius_top_left = 14
	card_bg.corner_radius_top_right = 14
	card_bg.corner_radius_bottom_left = 14
	card_bg.corner_radius_bottom_right = 14
	card_bg.content_margin_left = 16
	card_bg.content_margin_top = 14
	card_bg.content_margin_right = 16
	card_bg.content_margin_bottom = 14
	center_panel.add_theme_stylebox_override("panel", card_bg)

	# 2. Stat Cards Framing (Wave, Time, Kills)
	for sc in [stat_card_wave, stat_card_time, stat_card_kills]:
		if is_instance_valid(sc):
			var sc_st := StyleBoxFlat.new()
			sc_st.bg_color = Color(0.065, 0.09, 0.14, 0.90)
			sc_st.border_color = Color(0.24, 0.32, 0.45, 0.85)
			sc_st.set_border_width_all(1)
			sc_st.set_corner_radius_all(8)
			sc_st.set_content_margin_all(8)
			sc.add_theme_stylebox_override("panel", sc_st)

	# 3. Button Styles: Revive Premium (Gold/Amber)
	var gold_normal := _create_btn_style(Color(0.84, 0.52, 0.08, 0.95), Color(1.0, 0.74, 0.22, 1.0), 2, 8)
	var gold_hover := _create_btn_style(Color(0.96, 0.62, 0.14, 1.0), Color(1.0, 0.86, 0.40, 1.0), 2, 8)
	var gold_pressed := _create_btn_style(Color(0.66, 0.40, 0.05, 1.0), Color(0.85, 0.55, 0.15, 1.0), 2, 8)
	var gold_disabled := _create_btn_style(Color(0.12, 0.15, 0.20, 0.95), Color(0.26, 0.32, 0.42, 0.80), 1, 8)
	revive_button.add_theme_stylebox_override("normal", gold_normal)
	revive_button.add_theme_stylebox_override("hover", gold_hover)
	revive_button.add_theme_stylebox_override("pressed", gold_pressed)
	revive_button.add_theme_stylebox_override("disabled", gold_disabled)
	revive_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	revive_button.add_theme_color_override("font_disabled_color", Color(0.65, 0.72, 0.82))

	# 4. Button Styles: Revive Ad (Cyan/Teal)
	var ad_normal := _create_btn_style(Color(0.06, 0.45, 0.52, 0.95), Color(0.20, 0.82, 0.90, 1.0), 2, 8)
	var ad_hover := _create_btn_style(Color(0.10, 0.56, 0.65, 1.0), Color(0.35, 0.92, 0.98, 1.0), 2, 8)
	var ad_pressed := _create_btn_style(Color(0.04, 0.32, 0.38, 1.0), Color(0.15, 0.68, 0.76, 1.0), 2, 8)
	var ad_disabled := _create_btn_style(Color(0.11, 0.14, 0.18, 0.95), Color(0.22, 0.28, 0.36, 0.80), 1, 8)
	ad_button.add_theme_stylebox_override("normal", ad_normal)
	ad_button.add_theme_stylebox_override("hover", ad_hover)
	ad_button.add_theme_stylebox_override("pressed", ad_pressed)
	ad_button.add_theme_stylebox_override("disabled", ad_disabled)
	ad_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	ad_button.add_theme_color_override("font_disabled_color", Color(0.65, 0.72, 0.82))

	# 5. Button Styles: Retry (Sci-Fi Blue)
	var ret_normal := _create_btn_style(Color(0.11, 0.24, 0.39, 0.95), Color(0.28, 0.54, 0.78, 1.0), 2, 8)
	var ret_hover := _create_btn_style(Color(0.16, 0.33, 0.52, 1.0), Color(0.38, 0.66, 0.92, 1.0), 2, 8)
	var ret_pressed := _create_btn_style(Color(0.08, 0.17, 0.28, 1.0), Color(0.20, 0.42, 0.64, 1.0), 2, 8)
	retry_button.add_theme_stylebox_override("normal", ret_normal)
	retry_button.add_theme_stylebox_override("hover", ret_hover)
	retry_button.add_theme_stylebox_override("pressed", ret_pressed)
	retry_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	# 6. Button Styles: Return to Hub (Gunmetal Dark Armor)
	var hub_normal := _create_btn_style(Color(0.13, 0.16, 0.22, 0.95), Color(0.29, 0.35, 0.44, 1.0), 1, 8)
	var hub_hover := _create_btn_style(Color(0.18, 0.22, 0.30, 1.0), Color(0.38, 0.45, 0.56, 1.0), 1, 8)
	var hub_pressed := _create_btn_style(Color(0.09, 0.11, 0.16, 1.0), Color(0.22, 0.27, 0.35, 1.0), 1, 8)
	hub_button.add_theme_stylebox_override("normal", hub_normal)
	hub_button.add_theme_stylebox_override("hover", hub_hover)
	hub_button.add_theme_stylebox_override("pressed", hub_pressed)
	hub_button.add_theme_color_override("font_color", Color(0.85, 0.89, 0.94))

func _create_btn_style(bg: Color, border: Color, width: int = 2, radius: int = 8) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(width)
	st.set_corner_radius_all(radius)
	st.set_content_margin_all(10)
	return st

func _connect_signals() -> void:
	if not revive_button.pressed.is_connected(_on_revive_pressed):
		revive_button.pressed.connect(_on_revive_pressed)
	if not ad_button.pressed.is_connected(_on_ad_pressed):
		ad_button.pressed.connect(_on_ad_pressed)
	if not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if not hub_button.pressed.is_connected(_on_hub_pressed):
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
	if not is_instance_valid(center_panel) or not is_instance_valid(backdrop):
		return
	var vp_size := get_viewport_rect().size
	var is_portrait := vp_size.y > vp_size.x
	if is_portrait:
		center_panel.custom_minimum_size = Vector2(minf(vp_size.x * 0.92, 640.0), 620.0)
		backdrop.texture = load("res://addons/ms_balance/assets/defeat_background_portrait.png")
	else:
		center_panel.custom_minimum_size = Vector2(580.0, 490.0)
		backdrop.texture = load("res://addons/ms_balance/assets/defeat_background_landscape.png")

func play_entry_animation() -> void:
	if not is_node_ready():
		await ready
	center_panel.pivot_offset = center_panel.custom_minimum_size * 0.5
	center_panel.scale = Vector2(0.92, 0.92)
	center_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_panel, "scale", Vector2.ONE, 0.25)
	tw.tween_property(center_panel, "modulate:a", 1.0, 0.20)

func configure(data: Dictionary) -> void:
	if not is_node_ready():
		await ready

	title_label.text = String(data.get("title", "MISJA NIEUDANA"))
	var waves := int(data.get("wave", 0))
	var kills := int(data.get("kills", 0))
	var time_sec := maxi(0, int(data.get("time_seconds", 0)))
	var reason_text := String(data.get("reason", "Ulepsz wyposażenie lub spróbuj innej strategii."))
	var gems_avail := int(data.get("gems", 0))
	var spent := bool(data.get("already_revived", false))
	var ad_avail := bool(data.get("ad_available", false))

	# Format score line for backward compatibility with existing tests
	score_label.text = "FALA %d/10   |   %02d:%02d   |   %d MUTANTÓW" % [waves, int(time_sec / 60), time_sec % 60, kills]
	summary_label.text = reason_text

	# Update separate high-impact stat badges
	if is_instance_valid(wave_val_lbl):
		wave_val_lbl.text = "%d / 10" % waves
	if is_instance_valid(time_val_lbl):
		time_val_lbl.text = "%02d:%02d" % [int(time_sec / 60), time_sec % 60]
	if is_instance_valid(kills_val_lbl):
		kills_val_lbl.text = "%d" % kills

	# Configure Revive Button with professional disabled state
	if spent:
		revive_button.disabled = true
		revive_button.text = "  WSKRZESZENIE WYKORZYSTANE"
	elif gems_avail < 30:
		revive_button.disabled = true
		revive_button.text = "  BRAK KRYSZTAŁÓW (WYMAGA 30 💎)"
	else:
		revive_button.disabled = false
		revive_button.text = "  WSKRZEŚ — 30 KRYSZTAŁÓW"

	# Configure Ad Button
	ad_button.visible = ad_avail and not spent

	update_responsive_layout()
	play_entry_animation()
