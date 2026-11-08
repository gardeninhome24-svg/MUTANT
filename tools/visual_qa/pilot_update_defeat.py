import os

tscn_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.tscn"
gd_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.gd"

# Create a clean backup first
with open(tscn_path, "r", encoding="utf-8") as f:
    orig_tscn = f.read()

with open(tscn_path + ".v1_backup", "w", encoding="utf-8") as f:
    f.write(orig_tscn)

with open(gd_path, "r", encoding="utf-8") as f:
    orig_gd = f.read()

with open(gd_path + ".v1_backup", "w", encoding="utf-8") as f:
    f.write(orig_gd)

print("Created backups of defeat_overlay files.")

new_tscn = """[gd_scene load_steps=12 format=3]

[ext_resource type="Script" path="res://addons/ms_balance/ui/defeat_overlay.gd" id="1"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/defeat_background_landscape.png" id="2"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_biohazard_crest.png" id="3_crest"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_stat_flag.png" id="4_flag"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_stat_timer.png" id="5_timer"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_stat_skull.png" id="6_skull"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_revive.png" id="7_revive"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_ad_clapper.png" id="8_ad"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_retry.png" id="9_retry"]
[ext_resource type="Texture2D" path="res://addons/ms_balance/assets/icon_home.png" id="10_hub"]

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

[node name="Darken" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.01, 0.02, 0.04, 0.38)

[node name="Center" type="PanelContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -320.0
offset_top = -240.0
offset_right = 320.0
offset_bottom = 240.0
grow_horizontal = 2
grow_vertical = 2
custom_minimum_size = Vector2(640, 480)

[node name="Margin" type="MarginContainer" parent="Center"]
layout_mode = 2
theme_override_constants/margin_left = 24
theme_override_constants/margin_top = 18
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 20

[node name="VBox" type="VBoxContainer" parent="Center/Margin"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 10

[node name="Crest" type="TextureRect" parent="Center/Margin/VBox"]
custom_minimum_size = Vector2(50, 50)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("3_crest")
expand_mode = 1
stretch_mode = 5

[node name="Title" type="Label" parent="Center/Margin/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.28, 0.25, 1)
theme_override_colors/font_shadow_color = Color(0.35, 0.02, 0.02, 1)
theme_override_constants/shadow_offset_y = 2
theme_override_font_sizes/font_size = 30
text = "MISJA NIEUDANA"
horizontal_alignment = 1

[node name="StatsRow" type="HBoxContainer" parent="Center/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 12
alignment = 1

[node name="StatCardWave" type="PanelContainer" parent="Center/Margin/VBox/StatsRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="HBox" type="HBoxContainer" parent="Center/Margin/VBox/StatsRow/StatCardWave"]
layout_mode = 2
theme_override_constants/separation = 8
alignment = 1

[node name="Icon" type="TextureRect" parent="Center/Margin/VBox/StatsRow/StatCardWave/HBox"]
custom_minimum_size = Vector2(28, 28)
layout_mode = 2
texture = ExtResource("4_flag")
expand_mode = 1
stretch_mode = 5

[node name="VBox" type="VBoxContainer" parent="Center/Margin/VBox/StatsRow/StatCardWave/HBox"]
layout_mode = 2
theme_override_constants/separation = 1
alignment = 1

[node name="Label" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardWave/HBox/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.7, 0.78, 0.88, 1)
theme_override_font_sizes/font_size = 11
text = "FALA"

[node name="WaveVal" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardWave/HBox/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.92, 0.65, 1)
theme_override_font_sizes/font_size = 17
text = "5 / 10"

[node name="StatCardTime" type="PanelContainer" parent="Center/Margin/VBox/StatsRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="HBox" type="HBoxContainer" parent="Center/Margin/VBox/StatsRow/StatCardTime"]
layout_mode = 2
theme_override_constants/separation = 8
alignment = 1

[node name="Icon" type="TextureRect" parent="Center/Margin/VBox/StatsRow/StatCardTime/HBox"]
custom_minimum_size = Vector2(28, 28)
layout_mode = 2
texture = ExtResource("5_timer")
expand_mode = 1
stretch_mode = 5

[node name="VBox" type="VBoxContainer" parent="Center/Margin/VBox/StatsRow/StatCardTime/HBox"]
layout_mode = 2
theme_override_constants/separation = 1
alignment = 1

[node name="Label" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardTime/HBox/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.7, 0.78, 0.88, 1)
theme_override_font_sizes/font_size = 11
text = "CZAS"

[node name="TimeVal" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardTime/HBox/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.92, 0.65, 1)
theme_override_font_sizes/font_size = 17
text = "04:32"

[node name="StatCardKills" type="PanelContainer" parent="Center/Margin/VBox/StatsRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="HBox" type="HBoxContainer" parent="Center/Margin/VBox/StatsRow/StatCardKills"]
layout_mode = 2
theme_override_constants/separation = 8
alignment = 1

[node name="Icon" type="TextureRect" parent="Center/Margin/VBox/StatsRow/StatCardKills/HBox"]
custom_minimum_size = Vector2(28, 28)
layout_mode = 2
texture = ExtResource("6_skull")
expand_mode = 1
stretch_mode = 5

[node name="VBox" type="VBoxContainer" parent="Center/Margin/VBox/StatsRow/StatCardKills/HBox"]
layout_mode = 2
theme_override_constants/separation = 1
alignment = 1

[node name="Label" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardKills/HBox/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.7, 0.78, 0.88, 1)
theme_override_font_sizes/font_size = 11
text = "ZABICI"

[node name="KillsVal" type="Label" parent="Center/Margin/VBox/StatsRow/StatCardKills/HBox/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.92, 0.65, 1)
theme_override_font_sizes/font_size = 17
text = "142"

[node name="Subtitle" type="Label" parent="Center/Margin/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.65, 0.78, 0.90, 1)
theme_override_font_sizes/font_size = 13
text = "CHCESZ KONTYNUOWAĆ MISJĘ?"
horizontal_alignment = 1

[node name="Score" type="Label" parent="Center/Margin/VBox"]
visible = false
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.9, 0.62, 1)
theme_override_font_sizes/font_size = 14
text = "FALA 9/10   |   02:30   |   230 MUTANTÓW"
horizontal_alignment = 1
autowrap_mode = 3

[node name="Summary" type="Label" parent="Center/Margin/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.72, 0.80, 0.88, 1)
theme_override_font_sizes/font_size = 12
text = "Ulepsz wyposażenie lub spróbuj innej strategii."
horizontal_alignment = 1
autowrap_mode = 3

[node name="ReviveActionsRow" type="HBoxContainer" parent="Center/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 12
alignment = 1

[node name="RevivePremium" type="Button" parent="Center/Margin/VBox/ReviveActionsRow"]
custom_minimum_size = Vector2(0, 48)
layout_mode = 2
size_flags_horizontal = 3
icon = ExtResource("7_revive")
expand_icon = true
text = "  WSKRZEŚ — 30 💎"

[node name="ReviveAd" type="Button" parent="Center/Margin/VBox/ReviveActionsRow"]
custom_minimum_size = Vector2(0, 48)
layout_mode = 2
size_flags_horizontal = 3
icon = ExtResource("8_ad")
expand_icon = true
text = "  WSKRZEŚ ZA REKLAMĘ"

[node name="ExitActionsRow" type="HBoxContainer" parent="Center/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 12
alignment = 1

[node name="Retry" type="Button" parent="Center/Margin/VBox/ExitActionsRow"]
custom_minimum_size = Vector2(0, 46)
layout_mode = 2
size_flags_horizontal = 3
icon = ExtResource("9_retry")
expand_icon = true
text = "  SPRÓBUJ PONOWNIE (1 PRÓBA)"

[node name="Hub" type="Button" parent="Center/Margin/VBox/ExitActionsRow"]
custom_minimum_size = Vector2(0, 46)
layout_mode = 2
size_flags_horizontal = 3
icon = ExtResource("10_hub")
expand_icon = true
text = "  POWRÓT DO BAZY"
"""

with open(tscn_path, "w", encoding="utf-8") as f:
    f.write(new_tscn)

# Update node paths in defeat_overlay.gd
with open(gd_path, "r", encoding="utf-8") as f:
    gd_code = f.read()

gd_code = gd_code.replace(
    "@onready var revive_button: Button = $Center/Margin/VBox/RevivePremium",
    "@onready var revive_button: Button = $Center/Margin/VBox/ReviveActionsRow/RevivePremium"
)
gd_code = gd_code.replace(
    "@onready var ad_button: Button = $Center/Margin/VBox/ReviveAd",
    "@onready var ad_button: Button = $Center/Margin/VBox/ReviveActionsRow/ReviveAd"
)
gd_code = gd_code.replace(
    "@onready var retry_button: Button = $Center/Margin/VBox/Retry",
    "@onready var retry_button: Button = $Center/Margin/VBox/ExitActionsRow/Retry"
)
gd_code = gd_code.replace(
    "@onready var hub_button: Button = $Center/Margin/VBox/Hub",
    "@onready var hub_button: Button = $Center/Margin/VBox/ExitActionsRow/Hub"
)

# In update_responsive_layout:
resp_old = """\tvar vp_size := get_viewport_rect().size
\tvar is_portrait := vp_size.y > vp_size.x
\tif is_portrait:
\t\tcenter_panel.custom_minimum_size = Vector2(minf(vp_size.x * 0.92, 640.0), 620.0)
\t\tbackdrop.texture = load("res://addons/ms_balance/assets/defeat_background_portrait.png")
\telse:
\t\tcenter_panel.custom_minimum_size = Vector2(580.0, 490.0)
\t\tbackdrop.texture = load("res://addons/ms_balance/assets/defeat_background_landscape.png")"""

resp_new = """\tvar vp_size := get_viewport_rect().size
\tvar is_portrait := vp_size.y > vp_size.x
\tif is_portrait:
\t\tcenter_panel.custom_minimum_size = Vector2(minf(vp_size.x * 0.94, 660.0), 580.0)
\t\tbackdrop.texture = load("res://addons/ms_balance/assets/defeat_background_portrait.png")
\t\tvar rev_row := get_node_or_null("Center/Margin/VBox/ReviveActionsRow") as BoxContainer
\t\tif is_instance_valid(rev_row): rev_row.vertical = true
\t\tvar exit_row := get_node_or_null("Center/Margin/VBox/ExitActionsRow") as BoxContainer
\t\tif is_instance_valid(exit_row): exit_row.vertical = true
\telse:
\t\tcenter_panel.custom_minimum_size = Vector2(640.0, 480.0)
\t\tbackdrop.texture = load("res://addons/ms_balance/assets/defeat_background_landscape.png")
\t\tvar rev_row := get_node_or_null("Center/Margin/VBox/ReviveActionsRow") as BoxContainer
\t\tif is_instance_valid(rev_row): rev_row.vertical = false
\t\tvar exit_row := get_node_or_null("Center/Margin/VBox/ExitActionsRow") as BoxContainer
\t\tif is_instance_valid(exit_row): exit_row.vertical = false"""

gd_code = gd_code.replace(resp_old, resp_new)

with open(gd_path, "w", encoding="utf-8") as f:
    f.write(gd_code)

print("Updated defeat_overlay.tscn and defeat_overlay.gd with dual horizontal action rows and responsive portrait adaptation!")
