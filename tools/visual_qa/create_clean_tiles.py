from PIL import Image, ImageDraw, ImageFilter
import os

d = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\hd_defeat_v2"

# For each stat tile, create:
# 1. Base tile texture (blank dark beveled metallic tile with red border glow)
# Let's inspect tile_stat_fala
fala = Image.open(os.path.join(d, "tile_stat_fala.png")).convert("RGBA")
w, h = fala.size

# A clean tile base can be created from the tile borders and dark metallic fill
# Let's clone and patch the number area with the clean dark texture from the tile background
tile_base = fala.copy()
# Sample background patch from x: 140..250, y: 70..95 (clean dark area)
patch = tile_base.crop((140, 70, 240, 95))

# Also extract icons cleanly:
# Flag icon: x: 15..80, y: 15..85
icon_flag = fala.crop((15, 15, 85, 85))
icon_flag.save(os.path.join(d, "icon_flag_red_glow.png"))

czas = Image.open(os.path.join(d, "tile_stat_czas.png")).convert("RGBA")
icon_timer = czas.crop((15, 15, 85, 85))
icon_timer.save(os.path.join(d, "icon_timer_red_glow.png"))

zabici = Image.open(os.path.join(d, "tile_stat_zabici.png")).convert("RGBA")
icon_skull = zabici.crop((15, 15, 85, 85))
icon_skull.save(os.path.join(d, "icon_skull_red_glow.png"))

print("Extracted clean glowing red stat icons: flag, timer, skull!")
