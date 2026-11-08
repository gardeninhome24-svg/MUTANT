import re

tscn_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.tscn"
gd_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.gd"

with open(tscn_path, "r", encoding="utf-8") as f:
    tscn = f.read()

# 1. Lighten darken color rect from 0.45 alpha to 0.25 to let rich background show
tscn = tscn.replace('color = Color(0.01, 0.02, 0.04, 0.45)', 'color = Color(0.01, 0.02, 0.04, 0.25)')

# 2. Adjust title font size to 32 and crest size to 52x52
tscn = tscn.replace('theme_override_font_sizes/font_size = 28', 'theme_override_font_sizes/font_size = 32')
tscn = tscn.replace('custom_minimum_size = Vector2(46, 46)', 'custom_minimum_size = Vector2(52, 52)')

# 3. Card dimensions: 600x520
tscn = tscn.replace('custom_minimum_size = Vector2(580, 510)', 'custom_minimum_size = Vector2(600, 520)')
tscn = tscn.replace('offset_left = -290.0', 'offset_left = -300.0')
tscn = tscn.replace('offset_right = 290.0', 'offset_right = 300.0')
tscn = tscn.replace('offset_top = -255.0', 'offset_top = -260.0')
tscn = tscn.replace('offset_bottom = 255.0', 'offset_bottom = 260.0')

with open(tscn_path, "w", encoding="utf-8") as f:
    f.write(tscn)

# In defeat_overlay.gd, polish card frame and colors
with open(gd_path, "r", encoding="utf-8") as f:
    gd = f.read()

# Make card background slightly more metallic and stylish
gd = gd.replace(
    'card_bg.bg_color = Color(0.045, 0.065, 0.105, 0.96)',
    'card_bg.bg_color = Color(0.05, 0.07, 0.11, 0.94)'
)
gd = gd.replace(
    'card_bg.border_color = Color(0.88, 0.20, 0.20, 0.95)',
    'card_bg.border_color = Color(0.92, 0.22, 0.18, 0.98)'
)

# Responsive sizing
gd = gd.replace(
    'center_panel.custom_minimum_size = Vector2(580.0, 490.0)',
    'center_panel.custom_minimum_size = Vector2(600.0, 520.0)'
)

with open(gd_path, "w", encoding="utf-8") as f:
    f.write(gd)

print("Applied clean visual polish to defeat_overlay without altering node hierarchy!")
