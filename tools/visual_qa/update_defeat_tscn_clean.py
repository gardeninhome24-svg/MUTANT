import os

tscn_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.tscn"
with open(tscn_path, "r", encoding="utf-8") as f:
    text = f.read()

# Make StatsRow invisible so legacy labels at (0, 0) are hidden
text = text.replace(
    '[node name="StatsRow" type="Control" parent="Center/Margin/VBox"]\nlayout_mode = 3',
    '[node name="StatsRow" type="Control" parent="Center/Margin/VBox"]\nvisible = false\nlayout_mode = 3'
)

# Position DynamicStats labels cleanly over the patched tile boxes
text = text.replace(
    'theme_override_colors/font_color = Color(1, 0.94, 0.72, 1)',
    'theme_override_colors/font_color = Color(1, 1, 1, 1)'
)
text = text.replace(
    'theme_override_font_sizes/font_size = 28',
    'theme_override_font_sizes/font_size = 26'
)

text = text.replace(
    'offset_left = 360.0\noffset_top = 295.0\noffset_right = 490.0\noffset_bottom = 338.0',
    'offset_left = 340.0\noffset_top = 296.0\noffset_right = 480.0\noffset_bottom = 342.0'
)
text = text.replace(
    'offset_left = 620.0\noffset_top = 295.0\noffset_right = 760.0\noffset_bottom = 338.0',
    'offset_left = 610.0\noffset_top = 296.0\noffset_right = 760.0\noffset_bottom = 342.0'
)
text = text.replace(
    'offset_left = 890.0\noffset_top = 295.0\noffset_right = 1010.0\noffset_bottom = 338.0',
    'offset_left = 870.0\noffset_top = 296.0\noffset_right = 1000.0\noffset_bottom = 342.0'
)

with open(tscn_path, "w", encoding="utf-8") as f:
    f.write(text)

print("Updated defeat_overlay.tscn with clean centered dynamic labels and hidden legacy container!")
