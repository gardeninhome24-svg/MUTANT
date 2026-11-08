import os
from PIL import Image

src_atlas = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794168896683_90160beb.jpg"
out_dir = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\ui_v2"
os.makedirs(out_dir, exist_ok=True)

im = Image.open(src_atlas).convert("RGBA")

# 1. Button 4 States (Normal, Hover, Pressed, Disabled)
# Exact coordinates measured:
btn_normal = im.crop((26, 400, 138, 455))
btn_hover = im.crop((145, 400, 257, 455))
btn_pressed = im.crop((263, 400, 375, 455))
btn_disabled = im.crop((381, 400, 493, 455))

btn_normal.save(os.path.join(out_dir, "btn_revive_normal.png"))
btn_hover.save(os.path.join(out_dir, "btn_revive_hover.png"))
btn_pressed.save(os.path.join(out_dir, "btn_revive_pressed.png"))
btn_disabled.save(os.path.join(out_dir, "btn_revive_disabled.png"))

# 2. Stat Tiles (Fala, Czas, Zabici)
tile_fala = im.crop((518, 400, 630, 455))
tile_czas = im.crop((640, 400, 752, 455))
tile_zabici = im.crop((762, 400, 874, 455))

tile_fala.save(os.path.join(out_dir, "tile_fala_ref.png"))
tile_czas.save(os.path.join(out_dir, "tile_czas_ref.png"))
tile_zabici.save(os.path.join(out_dir, "tile_zabici_ref.png"))

# 3. Clean UI Frames (Top Right)
crest_bio = im.crop((807, 246, 873, 310))
crest_bio.save(os.path.join(out_dir, "crest_biohazard_circle.png"))

frame_header = im.crop((800, 28, 1010, 85))
frame_header.save(os.path.join(out_dir, "frame_hazard_header.png"))

plate_container = im.crop((800, 95, 1010, 160))
plate_container.save(os.path.join(out_dir, "plate_armored_container.png"))

bar_bottom = im.crop((800, 320, 1010, 375))
bar_bottom.save(os.path.join(out_dir, "bar_hazard_bottom.png"))

# 4. Portrait 9:16 Full Defeat Screen
defeat_916 = im.crop((580, 20, 785, 380)).resize((720, 1280), Image.Resampling.LANCZOS)
defeat_916.save(os.path.join(out_dir, "defeat_background_portrait_v2.png"))

# Copy to root assets folder so Godot can load them
root_assets = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets"
defeat_916.save(os.path.join(root_assets, "defeat_background_portrait.png"))

# 5. Extract system icons from icon row
# y: 490..525
icons_spec = [
    ("icon_biohazard", 16, 44),
    ("icon_skull", 54, 82),
    ("icon_flag", 92, 120),
    ("icon_timer", 130, 158),
    ("icon_heart", 168, 196),
    ("icon_crystal", 206, 234),
    ("icon_gold", 244, 272),
    ("icon_xp", 282, 310),
    ("icon_chest", 320, 348),
    ("icon_gear", 358, 386),
    ("icon_retry", 396, 424),
    ("icon_ad", 434, 462),
    ("icon_battery", 472, 500),
]

for name, x1, x2 in icons_spec:
    ic = im.crop((x1, 492, x2, 524))
    ic.save(os.path.join(out_dir, f"{name}.png"))

print("All elements successfully sliced and saved to ui_v2!")
