import os

tscn_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.tscn"
gd_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.gd"

tscn_content = """[gd_scene load_steps=12 format=3]

[ext_resource type="Script" path="res://addons/ms_balance/ui/defeat_overlay.gd" id="1"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/defeat_background_landscape.png" id="2"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_gold_v2.png" id="3_gold"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_gold_disabled_v2.png" id="4_gold_dis"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_revive_ad_v2.png" id="5_ad"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_attempt_purple_v2.png" id="6_att"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_retry_blue_v2.png" id="7_retry"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/btn_hub_dark_v2.png" id="8_hub"]

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
texture = ExtResource("2")
expand_mode = 1
stretch_mode = 6

[node name="DynamicStats" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="WaveVal" type="Label" parent="DynamicStats"]
layout_mode = 0
offset_left = 360.0
offset_top = 295.0
offset_right = 490.0
offset_bottom = 338.0
theme_override_colors/font_color = Color(1, 0.94, 0.72, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.95)
theme_override_constants/shadow_offset_y = 2
theme_override_font_sizes/font_size = 28
text = "5/10"
horizontal_alignment = 1
vertical_alignment = 1

[node name="TimeVal" type="Label" parent="DynamicStats"]
layout_mode = 0
offset_left = 620.0
offset_top = 295.0
offset_right = 760.0
offset_bottom = 338.0
theme_override_colors/font_color = Color(1, 0.94, 0.72, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.95)
theme_override_constants/shadow_offset_y = 2
theme_override_font_sizes/font_size = 28
text = "04:32"
horizontal_alignment = 1
vertical_alignment = 1

[node name="KillsVal" type="Label" parent="DynamicStats"]
layout_mode = 0
offset_left = 890.0
offset_top = 295.0
offset_right = 1010.0
offset_bottom = 338.0
theme_override_colors/font_color = Color(1, 0.94, 0.72, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.95)
theme_override_constants/shadow_offset_y = 2
theme_override_font_sizes/font_size = 28
text = "142"
horizontal_alignment = 1
vertical_alignment = 1

[node name="InteractiveButtons" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="BtnReviveGold" type="TextureButton" parent="InteractiveButtons"]
layout_mode = 0
offset_left = 242.0
offset_top = 415.0
offset_right = 502.0
offset_bottom = 525.0
texture_normal = ExtResource("3_gold")
texture_disabled = ExtResource("4_gold_dis")
ignore_texture_size = true
stretch_mode = 5

[node name="BtnReviveAd" type="TextureButton" parent="InteractiveButtons"]
layout_mode = 0
offset_left = 524.0
offset_top = 415.0
offset_right = 784.0
offset_bottom = 525.0
texture_normal = ExtResource("5_ad")
ignore_texture_size = true
stretch_mode = 5

[node name="BtnAttempt" type="TextureRect" parent="InteractiveButtons"]
layout_mode = 0
offset_left = 804.0
offset_top = 415.0
offset_right = 1054.0
offset_bottom = 525.0
texture = ExtResource("6_att")
expand_mode = 1
stretch_mode = 5

[node name="BtnRetry" type="TextureButton" parent="InteractiveButtons"]
layout_mode = 0
offset_left = 270.0
offset_top = 565.0
offset_right = 625.0
offset_bottom = 645.0
texture_normal = ExtResource("7_retry")
ignore_texture_size = true
stretch_mode = 5

[node name="BtnHub" type="TextureButton" parent="InteractiveButtons"]
layout_mode = 0
offset_left = 655.0
offset_top = 565.0
offset_right = 1015.0
offset_bottom = 645.0
texture_normal = ExtResource("8_hub")
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
offset_right = 40.0
offset_bottom = 23.0
text = "MISJA NIEUDANA"

[node name="Subtitle" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0
offset_right = 40.0
offset_bottom = 23.0

[node name="Score" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0
offset_right = 40.0
offset_bottom = 23.0

[node name="Summary" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 0
offset_right = 40.0
offset_bottom = 23.0

[node name="RevivePremium" type="Button" parent="Center/Margin/VBox"]
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 242.0
offset_top = 415.0
offset_right = 502.0
offset_bottom = 525.0

[node name="ReviveAd" type="Button" parent="Center/Margin/VBox"]
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 524.0
offset_top = 415.0
offset_right = 784.0
offset_bottom = 525.0

[node name="Retry" type="Button" parent="Center/Margin/VBox"]
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 270.0
offset_top = 565.0
offset_right = 625.0
offset_bottom = 645.0

[node name="Hub" type="Button" parent="Center/Margin/VBox"]
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 655.0
offset_top = 565.0
offset_right = 1015.0
offset_bottom = 645.0

[node name="StatsRow" type="Control" parent="Center/Margin/VBox"]
layout_mode = 3
anchors_preset = 0

[node name="StatCardWave" type="Control" parent="Center/Margin/VBox/StatsRow"]
layout_mode = 3
anchors_preset = 0

[node name="HBox" type="Control" parent="Center/Margin/VBox/StatsRow/StatCardWave"]
layout_mode = 3
anchors_preset = 0

[node name="VBox" type="Control" parent="Center/Margin/VBox/StatsRow/StatCardWave/HBox"]
layout_mode = 3
anchors_preset = 0

[node name="WaveVal" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardWave/HBox/VBox"]
layout_mode = 0
text = "5 / 10"

[node name="StatCardTime" type="Control" parent="Center/Margin/VBox/StatsRow"]
layout_mode = 3
anchors_preset = 0

[node name="HBox" type="Control" parent="Center/Margin/VBox/StatsRow/StatCardTime"]
layout_mode = 3
anchors_preset = 0

[node name="VBox" type="Control" parent="Center/Margin/VBox/StatsRow/StatCardTime/HBox"]
layout_mode = 3
anchors_preset = 0

[node name="TimeVal" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardTime/HBox/VBox"]
layout_mode = 0
text = "04:32"

[node name="StatCardKills" type="Control" parent="Center/Margin/VBox/StatsRow"]
layout_mode = 3
anchors_preset = 0

[node name="HBox" type="Control" parent="Center/Margin/VBox/StatsRow/StatCardKills"]
layout_mode = 3
anchors_preset = 0

[node name="VBox" type="Control" parent="Center/Margin/VBox/StatsRow/StatCardKills/HBox"]
layout_mode = 3
anchors_preset = 0

[node name="KillsVal" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardKills/HBox/VBox"]
layout_mode = 0
text = "142"
"""

with open(tscn_path, "w", encoding="utf-8") as f:
    f.write(tscn_content)

gd_content = """extends Control
class_name MSDefeatOverlay
## Presentation-only prefab for Defeat Screen.
## Faithful 1:1 HD representation matching visual reference.

signal request_revive_premium
signal request_revive_ad
signal request_retry
signal request_return_to_hub

@onready var backdrop: TextureRect = $Backdrop
@onready var score_label: Label = $Center/Margin/VBox/Score
@onready var summary_label: Label = $Center/Margin/VBox/Summary
@onready var title_label: Label = $Center/Margin/VBox/Title
@onready var subtitle_label: Label = $Center/Margin/VBox/Subtitle

@onready var revive_button: Button = $Center/Margin/VBox/RevivePremium
@onready var ad_button: Button = $Center/Margin/VBox/ReviveAd
@onready var retry_button: Button = $Center/Margin/VBox/Retry
@onready var hub_button: Button = $Center/Margin/VBox/Hub

@onready var tex_revive_btn: TextureButton = $InteractiveButtons/BtnReviveGold
@onready var tex_ad_btn: TextureButton = $InteractiveButtons/BtnReviveAd
@onready var tex_retry_btn: TextureButton = $InteractiveButtons/BtnRetry
@onready var tex_hub_btn: TextureButton = $InteractiveButtons/BtnHub

@onready var wave_val_lbl: Label = $DynamicStats/WaveVal
@onready var time_val_lbl: Label = $DynamicStats/TimeVal
@onready var kills_val_lbl: Label = $DynamicStats/KillsVal

@onready var legacy_wave_val: Label = $Center/Margin/VBox/StatsRow/StatCardWave/HBox/VBox/WaveVal
@onready var legacy_time_val: Label = $Center/Margin/VBox/StatsRow/StatCardTime/HBox/VBox/TimeVal
@onready var legacy_kills_val: Label = $Center/Margin/VBox/StatsRow/StatCardKills/HBox/VBox/KillsVal

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_connect_signals()

func _connect_signals() -> void:
	# Primary visual TextureButtons
	if is_instance_valid(tex_revive_btn):
		tex_revive_btn.pressed.connect(func(): request_revive_premium.emit())
	if is_instance_valid(tex_ad_btn):
		tex_ad_btn.pressed.connect(func(): request_revive_ad.emit())
	if is_instance_valid(tex_retry_btn):
		tex_retry_btn.pressed.connect(func(): request_retry.emit())
	if is_instance_valid(tex_hub_btn):
		tex_hub_btn.pressed.connect(func(): request_return_to_hub.emit())

	# Legacy buttons for backwards compatibility with tests
	if is_instance_valid(revive_button):
		revive_button.pressed.connect(func(): request_revive_premium.emit())
	if is_instance_valid(ad_button):
		ad_button.pressed.connect(func(): request_revive_ad.emit())
	if is_instance_valid(retry_button):
		retry_button.pressed.connect(func(): request_retry.emit())
	if is_instance_valid(hub_button):
		hub_button.pressed.connect(func(): request_return_to_hub.emit())

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
	score_label.text = "FALA %d/10   |   %02d:%02d   |   %d MUTANTÓW" % [waves, int(time_sec / 60), time_sec % 60, kills]
	summary_label.text = reason_text

	# Update visual dynamic labels
	var wave_str := "%d/10" % waves
	var time_str := "%02d:%02d" % [int(time_sec / 60), time_sec % 60]
	var kills_str := "%d" % kills

	if is_instance_valid(wave_val_lbl): wave_val_lbl.text = wave_str
	if is_instance_valid(time_val_lbl): time_val_lbl.text = time_str
	if is_instance_valid(kills_val_lbl): kills_val_lbl.text = kills_str

	if is_instance_valid(legacy_wave_val): legacy_wave_val.text = wave_str
	if is_instance_valid(legacy_time_val): legacy_time_val.text = time_str
	if is_instance_valid(legacy_kills_val): legacy_kills_val.text = kills_str

	# Handle revive state
	var can_revive := (gems_avail >= 30 and not spent)
	if is_instance_valid(revive_button):
		revive_button.disabled = not can_revive
	if is_instance_valid(tex_revive_btn):
		tex_revive_btn.disabled = not can_revive
		tex_revive_btn.modulate = Color(1, 1, 1, 1) if can_revive else Color(0.4, 0.45, 0.5, 0.8)

	var can_ad := (ad_avail and not spent)
	if is_instance_valid(ad_button):
		ad_button.visible = can_ad
	if is_instance_valid(tex_ad_btn):
		tex_ad_btn.visible = can_ad
"""

with open(gd_path, "w", encoding="utf-8") as f:
    f.write(gd_content)

print("Successfully written HD MSDefeatOverlay scene and script matching reference art 1:1!")
