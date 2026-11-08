import os

tscn_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.tscn"
gd_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.gd"

tscn_content = """[gd_scene load_steps=17 format=3]

[ext_resource type="Script" path="res://addons/ms_balance/ui/defeat_overlay.gd" id="1"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/defeat_backdrop_landscape.png" id="2_backdrop"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/card_armored_frame.png" id="3_frame"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/tile_stat_box_clean.png" id="4_tile_bg"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_flag.png" id="5_flag"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_timer.png" id="6_timer"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_skull.png" id="7_skull"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_gold_normal.png" id="8_gold_norm"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_gold_hover.png" id="9_gold_hov"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_gold_pressed.png" id="10_gold_pres"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_gold_disabled.png" id="11_gold_dis"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_ad.png" id="12_ad"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_attempt_purple.png" id="13_att"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_retry_blue.png" id="14_retry"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_hub_dark.png" id="15_hub"]

[node name="MSDefeatOverlay" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Backdrop" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("2_backdrop")
expand_mode = 1
stretch_mode = 6

[node name="CardCenter" type="Control" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -435.0
offset_top = -330.0
offset_right = 435.0
offset_bottom = 330.0
grow_horizontal = 2
grow_vertical = 2
custom_minimum_size = Vector2(870, 660)

[node name="CardFrame" type="TextureRect" parent="CardCenter"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("3_frame")
expand_mode = 1
stretch_mode = 5

[node name="StatTiles" type="Control" parent="CardCenter"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="TileFala" type="TextureRect" parent="CardCenter/StatTiles"]
layout_mode = 0
offset_left = 45.0
offset_top = 232.0
offset_right = 305.0
offset_bottom = 332.0
texture = ExtResource("4_tile_bg")
expand_mode = 1

[node name="Icon" type="TextureRect" parent="CardCenter/StatTiles/TileFala"]
layout_mode = 0
offset_left = 16.0
offset_top = 20.0
offset_right = 76.0
offset_bottom = 80.0
texture = ExtResource("5_flag")
expand_mode = 1
stretch_mode = 5

[node name="Title" type="Label" parent="CardCenter/StatTiles/TileFala"]
layout_mode = 0
offset_left = 85.0
offset_top = 16.0
offset_right = 230.0
offset_bottom = 39.0
theme_override_colors/font_color = Color(0.72, 0.8, 0.9, 1)
theme_override_font_sizes/font_size = 14
text = "FALA"

[node name="WaveVal" type="Label" parent="CardCenter/StatTiles/TileFala"]
layout_mode = 0
offset_left = 85.0
offset_top = 38.0
offset_right = 240.0
offset_bottom = 86.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.95)
theme_override_constants/shadow_offset_y = 2
theme_override_font_sizes/font_size = 30
text = "5/10"
vertical_alignment = 1

[node name="TileCzas" type="TextureRect" parent="CardCenter/StatTiles"]
layout_mode = 0
offset_left = 315.0
offset_top = 232.0
offset_right = 575.0
offset_bottom = 332.0
texture = ExtResource("4_tile_bg")
expand_mode = 1

[node name="Icon" type="TextureRect" parent="CardCenter/StatTiles/TileCzas"]
layout_mode = 0
offset_left = 16.0
offset_top = 20.0
offset_right = 76.0
offset_bottom = 80.0
texture = ExtResource("6_timer")
expand_mode = 1
stretch_mode = 5

[node name="Title" type="Label" parent="CardCenter/StatTiles/TileCzas"]
layout_mode = 0
offset_left = 85.0
offset_top = 16.0
offset_right = 230.0
offset_bottom = 39.0
theme_override_colors/font_color = Color(0.72, 0.8, 0.9, 1)
theme_override_font_sizes/font_size = 14
text = "CZAS"

[node name="TimeVal" type="Label" parent="CardCenter/StatTiles/TileCzas"]
layout_mode = 0
offset_left = 85.0
offset_top = 38.0
offset_right = 240.0
offset_bottom = 86.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.95)
theme_override_constants/shadow_offset_y = 2
theme_override_font_sizes/font_size = 30
text = "04:32"
vertical_alignment = 1

[node name="TileZabici" type="TextureRect" parent="CardCenter/StatTiles"]
layout_mode = 0
offset_left = 580.0
offset_top = 232.0
offset_right = 840.0
offset_bottom = 332.0
texture = ExtResource("4_tile_bg")
expand_mode = 1

[node name="Icon" type="TextureRect" parent="CardCenter/StatTiles/TileZabici"]
layout_mode = 0
offset_left = 16.0
offset_top = 20.0
offset_right = 76.0
offset_bottom = 80.0
texture = ExtResource("7_skull")
expand_mode = 1
stretch_mode = 5

[node name="Title" type="Label" parent="CardCenter/StatTiles/TileZabici"]
layout_mode = 0
offset_left = 85.0
offset_top = 16.0
offset_right = 230.0
offset_bottom = 39.0
theme_override_colors/font_color = Color(0.72, 0.8, 0.9, 1)
theme_override_font_sizes/font_size = 14
text = "ZABICI"

[node name="KillsVal" type="Label" parent="CardCenter/StatTiles/TileZabici"]
layout_mode = 0
offset_left = 85.0
offset_top = 38.0
offset_right = 240.0
offset_bottom = 86.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.95)
theme_override_constants/shadow_offset_y = 2
theme_override_font_sizes/font_size = 30
text = "142"
vertical_alignment = 1

[node name="PromptLabel" type="Label" parent="CardCenter"]
layout_mode = 0
offset_left = 100.0
offset_top = 348.0
offset_right = 770.0
offset_bottom = 376.0
theme_override_colors/font_color = Color(0.68, 0.78, 0.88, 1)
theme_override_font_sizes/font_size = 15
text = "— CHCESZ KONTYNUOWAĆ MISJĘ? —"
horizontal_alignment = 1

[node name="ActionRow1" type="Control" parent="CardCenter"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="BtnReviveGold" type="TextureButton" parent="CardCenter/ActionRow1"]
layout_mode = 0
offset_left = 37.0
offset_top = 405.0
offset_right = 297.0
offset_bottom = 515.0
texture_normal = ExtResource("8_gold_norm")
texture_pressed = ExtResource("10_gold_pres")
texture_hover = ExtResource("9_gold_hov")
texture_disabled = ExtResource("11_gold_dis")
ignore_texture_size = true
stretch_mode = 5

[node name="BtnReviveAd" type="TextureButton" parent="CardCenter/ActionRow1"]
layout_mode = 0
offset_left = 319.0
offset_top = 405.0
offset_right = 579.0
offset_bottom = 515.0
texture_normal = ExtResource("12_ad")
ignore_texture_size = true
stretch_mode = 5

[node name="BtnAttempt" type="TextureRect" parent="CardCenter/ActionRow1"]
layout_mode = 0
offset_left = 599.0
offset_top = 405.0
offset_right = 844.0
offset_bottom = 515.0
texture = ExtResource("13_att")
expand_mode = 1
stretch_mode = 5

[node name="ActionRow2" type="Control" parent="CardCenter"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="BtnRetry" type="TextureButton" parent="CardCenter/ActionRow2"]
layout_mode = 0
offset_left = 65.0
offset_top = 555.0
offset_right = 420.0
offset_bottom = 635.0
texture_normal = ExtResource("14_retry")
ignore_texture_size = true
stretch_mode = 5

[node name="BtnHub" type="TextureButton" parent="CardCenter/ActionRow2"]
layout_mode = 0
offset_left = 450.0
offset_top = 555.0
offset_right = 810.0
offset_bottom = 635.0
texture_normal = ExtResource("15_hub")
ignore_texture_size = true
stretch_mode = 5

[node name="Center" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="Margin" type="Control" parent="Center"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="VBox" type="Control" parent="Center/Margin"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="Title" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0
text = "MISJA NIEUDANA"

[node name="Subtitle" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0

[node name="Score" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0

[node name="Summary" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0

[node name="RevivePremium" type="Button" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0

[node name="ReviveAd" type="Button" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0

[node name="Retry" type="Button" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0

[node name="Hub" type="Button" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0
"""

with open(tscn_path, "w", encoding="utf-8") as f:
    f.write(tscn_content)

gd_content = """extends Control
class_name MSDefeatOverlay
## True Modular High-Fidelity Defeat Overlay.
## Real dynamic Labels, real TextureButtons with Normal/Hover/Pressed/Disabled states.

signal request_revive_premium
signal request_revive_ad
signal request_retry
signal request_return_to_hub

@onready var backdrop: TextureRect = $Backdrop
@onready var card_center: Control = $CardCenter

@onready var wave_val_lbl: Label = $CardCenter/StatTiles/TileFala/WaveVal
@onready var time_val_lbl: Label = $CardCenter/StatTiles/TileCzas/TimeVal
@onready var kills_val_lbl: Label = $CardCenter/StatTiles/TileZabici/KillsVal

@onready var tex_revive_btn: TextureButton = $CardCenter/ActionRow1/BtnReviveGold
@onready var tex_ad_btn: TextureButton = $CardCenter/ActionRow1/BtnReviveAd
@onready var tex_attempt_info: TextureRect = $CardCenter/ActionRow1/BtnAttempt
@onready var tex_retry_btn: TextureButton = $CardCenter/ActionRow2/BtnRetry
@onready var tex_hub_btn: TextureButton = $CardCenter/ActionRow2/BtnHub

# Legacy references for tests
@onready var score_label: Label = $Center/Margin/VBox/Score
@onready var summary_label: Label = $Center/Margin/VBox/Summary
@onready var revive_button: Button = $Center/Margin/VBox/RevivePremium
@onready var ad_button: Button = $Center/Margin/VBox/ReviveAd
@onready var retry_button: Button = $Center/Margin/VBox/Retry
@onready var hub_button: Button = $Center/Margin/VBox/Hub

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_connect_signals()
	update_responsive_layout()
	get_viewport().size_changed.connect(update_responsive_layout)

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
		card_center.custom_minimum_size = Vector2(minf(vp_size.x * 0.94, 680.0), 620.0)
		backdrop.texture = load("res://addons/ms_balance/assets/defeat_background_portrait.png")
	else:
		card_center.custom_minimum_size = Vector2(870.0, 660.0)
		backdrop.texture = load("res://addons/ms_balance/assets/defeat_backdrop_landscape.png")

func configure(data: Dictionary) -> void:
	if not is_node_ready():
		await ready

	var waves := int(data.get("wave", 5))
	var kills := int(data.get("kills", 142))
	var time_sec := maxi(0, int(data.get("time_seconds", 272)))
	var reason_text := String(data.get("reason", "Ulepsz wyposażenie lub spróbuj innej strategii."))
	var gems_avail := int(data.get("gems", 300))
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

	# Revive Button State (Normal vs Disabled)
	var can_revive := (gems_avail >= 30 and not spent)
	if is_instance_valid(tex_revive_btn):
		tex_revive_btn.disabled = not can_revive
	if is_instance_valid(revive_button):
		revive_button.disabled = not can_revive

	# Ad Button State (Visible vs Hidden)
	var can_ad := (ad_avail and not spent)
	if is_instance_valid(tex_ad_btn):
		tex_ad_btn.visible = can_ad
	if is_instance_valid(ad_button):
		ad_button.visible = can_ad

	update_responsive_layout()
"""

with open(gd_path, "w", encoding="utf-8") as f:
    f.write(gd_content)

print("Generated true modular defeat_overlay scene and script!")
