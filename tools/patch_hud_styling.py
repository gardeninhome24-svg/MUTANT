# -*- coding: utf-8 -*-
path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\main.gd"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Let's inspect _apply_responsive_hud_layout and _setup_extended_hud_and_profile
# In _setup_extended_hud_and_profile, customize stats_card and objectives_panel
old_setup_start = "func _setup_extended_hud_and_profile() -> void:\n\tvar hud_root: Control = $HUD/HUDRoot\n"
new_setup_start = """func _setup_extended_hud_and_profile() -> void:
\tvar hud_root: Control = $HUD/HUDRoot

\t# Kompaktowa odznaka ocalałego (<48px wysokości, zoptymalizowany minimalistyczny HUD)
\tif is_instance_valid(chapter_label):
\t\tchapter_label.visible = false
\tif is_instance_valid(subtitle_label):
\t\tsubtitle_label.visible = false
\tif is_instance_valid(char_level_label):
\t\tchar_level_label.visible = false
\tif is_instance_valid(hp_label):
\t\thp_label.add_theme_font_size_override("font_size", 9)
\tif is_instance_valid(run_level_label):
\t\trun_level_label.add_theme_font_size_override("font_size", 9)
\t\trun_level_label.text = "POZ. 1"

\tvar avatar_rect := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/AvatarBox/Avatar") as TextureRect
\tif is_instance_valid(avatar_rect):
\t\tavatar_rect.custom_minimum_size = Vector2(38, 38)

\tif is_instance_valid(stats_card):
\t\tstats_card.custom_minimum_size = Vector2(195, 46)
\t\tvar sc_style := StyleBoxFlat.new()
\t\tsc_style.bg_color = Color(0.04, 0.08, 0.14, 0.88)
\t\tsc_style.border_width_left = 1
\t\tsc_style.border_width_top = 1
\t\tsc_style.border_width_right = 1
\t\tsc_style.border_width_bottom = 1
\t\tsc_style.border_color = Color(0.20, 0.75, 1.0, 0.80)
\t\tsc_style.corner_radius_top_left = 6
\t\tsc_style.corner_radius_top_right = 6
\t\tsc_style.corner_radius_bottom_left = 6
\t\tsc_style.corner_radius_bottom_right = 6
\t\tsc_style.content_margin_left = 6
\t\tsc_style.content_margin_top = 4
\t\tsc_style.content_margin_right = 6
\t\tsc_style.content_margin_bottom = 4
\t\tstats_card.add_theme_stylebox_override("panel", sc_style)

\tvar margin_c := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin") as MarginContainer
\tif is_instance_valid(margin_c):
\t\tmargin_c.add_theme_constant_override("margin_left", 6)
\t\tmargin_c.add_theme_constant_override("margin_top", 4)
\t\tmargin_c.add_theme_constant_override("margin_right", 6)
\t\tmargin_c.add_theme_constant_override("margin_bottom", 4)

\tvar hbox_root := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot") as HBoxContainer
\tif is_instance_valid(hbox_root):
\t\thbox_root.add_theme_constant_override("separation", 6)

\tvar vbox_stats := get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/VBoxStats") as VBoxContainer
\tif is_instance_valid(vbox_stats):
\t\tvbox_stats.add_theme_constant_override("separation", 2)

\tif is_instance_valid(hp_bar):
\t\thp_bar.custom_minimum_size = Vector2(110, 8)
\t\tvar hp_fill := StyleBoxFlat.new()
\t\thp_fill.bg_color = Color(0.15, 0.95, 0.45, 1.0)
\t\thp_fill.corner_radius_top_left = 3
\t\thp_fill.corner_radius_top_right = 3
\t\thp_fill.corner_radius_bottom_left = 3
\t\thp_fill.corner_radius_bottom_right = 3
\t\thp_bar.add_theme_stylebox_override("fill", hp_fill)

\tif is_instance_valid(xp_bar):
\t\txp_bar.custom_minimum_size = Vector2(110, 4)
\t\tvar xp_fill := StyleBoxFlat.new()
\t\txp_fill.bg_color = Color(0.18, 0.78, 1.0, 1.0)
\t\txp_fill.corner_radius_top_left = 2
\t\txp_fill.corner_radius_top_right = 2
\t\txp_fill.corner_radius_bottom_left = 2
\t\txp_fill.corner_radius_bottom_right = 2
\t\txp_bar.add_theme_stylebox_override("fill", xp_fill)

\tif is_instance_valid(objectives_panel):
\t\tvar obj_style := StyleBoxFlat.new()
\t\tobj_style.bg_color = Color(0.04, 0.07, 0.12, 0.82)
\t\tobj_style.border_width_left = 1
\t\tobj_style.border_width_top = 1
\t\tobj_style.border_width_right = 1
\t\tobj_style.border_width_bottom = 1
\t\tobj_style.border_color = Color(0.20, 0.55, 0.75, 0.65)
\t\tobj_style.corner_radius_top_left = 6
\t\tobj_style.corner_radius_top_right = 6
\t\tobj_style.corner_radius_bottom_left = 6
\t\tobj_style.corner_radius_bottom_right = 6
\t\tobj_style.content_margin_left = 6
\t\tobj_style.content_margin_top = 4
\t\tobj_style.content_margin_right = 6
\t\tobj_style.content_margin_bottom = 4
\t\tobjectives_panel.add_theme_stylebox_override("panel", obj_style)

\t\tif is_instance_valid(obj_header):
\t\t\tobj_header.add_theme_font_size_override("font_size", 10)
\t\tif is_instance_valid(obj1_label):
\t\t\tobj1_label.add_theme_font_size_override("font_size", 9)
\t\tif is_instance_valid(obj2_label):
\t\t\tobj2_label.add_theme_font_size_override("font_size", 9)
\t\tif is_instance_valid(obj3_label):
\t\t\tobj3_label.add_theme_font_size_override("font_size", 9)
"""

if old_setup_start in content and "Kompaktowa odznaka ocalałego" not in content:
    content = content.replace(old_setup_start, new_setup_start, 1)

# Now update _apply_responsive_hud_layout for sleek coordinates
old_layout_portrait = """\t\tif stats_card:
\t\t\tstats_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
\t\t\tstats_card.offset_left = 10.0
\t\t\tstats_card.offset_top = 8.0 + safe_top
\t\t\tstats_card.offset_right = 250.0
\t\t\tstats_card.offset_bottom = 58.0 + safe_top
\t\tif currency_bar:
\t\t\tcurrency_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
\t\t\tcurrency_bar.offset_left = -260.0
\t\t\tcurrency_bar.offset_top = 8.0 + safe_top
\t\t\tcurrency_bar.offset_right = -10.0
\t\t\tcurrency_bar.offset_bottom = 54.0 + safe_top
\t\tif wave_progress_box:
\t\t\twave_progress_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
\t\t\twave_progress_box.offset_left = -210.0
\t\t\twave_progress_box.offset_top = 62.0 + safe_top
\t\t\twave_progress_box.offset_right = 210.0
\t\t\twave_progress_box.offset_bottom = 120.0 + safe_top
\t\tif objectives_panel:
\t\t\tobjectives_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
\t\t\tobjectives_panel.offset_left = 10.0
\t\t\tobjectives_panel.offset_top = 128.0 + safe_top
\t\t\tobjectives_panel.offset_right = 210.0
\t\t\tobjectives_panel.offset_bottom = 232.0 + safe_top"""

new_layout_portrait = """\t\tif stats_card:
\t\t\tstats_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
\t\t\tstats_card.offset_left = 10.0
\t\t\tstats_card.offset_top = 8.0 + safe_top
\t\t\tstats_card.offset_right = 205.0
\t\t\tstats_card.offset_bottom = 54.0 + safe_top
\t\tif currency_bar:
\t\t\tcurrency_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
\t\t\tcurrency_bar.offset_left = -245.0
\t\t\tcurrency_bar.offset_top = 8.0 + safe_top
\t\t\tcurrency_bar.offset_right = -10.0
\t\t\tcurrency_bar.offset_bottom = 48.0 + safe_top
\t\tif wave_progress_box:
\t\t\twave_progress_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
\t\t\twave_progress_box.offset_left = -160.0
\t\t\twave_progress_box.offset_top = 58.0 + safe_top
\t\t\twave_progress_box.offset_right = 160.0
\t\t\twave_progress_box.offset_bottom = 98.0 + safe_top
\t\tif objectives_panel:
\t\t\tobjectives_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
\t\t\tobjectives_panel.offset_left = 10.0
\t\t\tobjectives_panel.offset_top = 60.0 + safe_top
\t\t\tobjectives_panel.offset_right = 195.0
\t\t\tobjectives_panel.offset_bottom = 138.0 + safe_top"""

if old_layout_portrait in content:
    content = content.replace(old_layout_portrait, new_layout_portrait, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("SUCCESSFULLY APPLIED SLEEK HUD STYLING TO main.gd")
