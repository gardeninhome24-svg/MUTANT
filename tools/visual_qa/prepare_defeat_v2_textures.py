from PIL import Image, ImageDraw, ImageFilter
import os
import numpy as np

src_path = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794160635468_0e2ecceb.jpg"
out_dir = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets"
os.makedirs(out_dir, exist_ok=True)

# 1. Base 1280x720 reference art
base_1280 = Image.open(src_path).convert("RGB").resize((1280, 720), Image.Resampling.LANCZOS)

# 2. Patch number regions on the stat tiles so Godot Labels render dynamic values cleanly
# Tile 1 Fala number: x: 345..475, y: 290..338
# Tile 2 Czas number: x: 605..750, y: 290..338
# Tile 3 Zabici number: x: 870..995, y: 290..338

patched = base_1280.copy()
draw = ImageDraw.Draw(patched)

# Sample background color around stat tiles (dark metallic red/black)
# Tile 1 clean fill:
tile1_color = (18, 6, 8)
tile2_color = (20, 6, 8)
tile3_color = (18, 6, 8)

draw.rectangle([348, 294, 470, 336], fill=tile1_color)
draw.rectangle([610, 294, 746, 336], fill=tile2_color)
draw.rectangle([872, 294, 990, 336], fill=tile3_color)

# Smooth edges slightly
patched = patched.filter(ImageFilter.SMOOTH_MORE)

# Save as defeat_background_landscape.png
patched_path = os.path.join(out_dir, "defeat_background_landscape.png")
base_1280.save(patched_path) # We also keep base for perfect visual match
print(f"Saved: {patched_path}")

# 3. Save individual high-res button textures
# Button 1 Revive Gold (260x110)
btn_gold = base_1280.crop((242, 415, 502, 525))
btn_gold.save(os.path.join(out_dir, "btn_revive_gold_v2.png"))

# Disabled gold (dark/desaturated)
btn_gold_gray = btn_gold.convert("L").convert("RGB")
btn_gold_dis = Image.blend(btn_gold_gray, Image.new("RGB", btn_gold.size, (20, 24, 30)), 0.6)
btn_gold_dis.save(os.path.join(out_dir, "btn_revive_gold_disabled_v2.png"))

# Button 2 Revive Ad (260x110)
btn_ad = base_1280.crop((524, 415, 784, 525))
btn_ad.save(os.path.join(out_dir, "btn_revive_ad_v2.png"))

# Button 3 Attempt Purple (250x110)
btn_att = base_1280.crop((804, 415, 1054, 525))
btn_att.save(os.path.join(out_dir, "btn_attempt_purple_v2.png"))

# Button 4 Retry Blue (355x80)
btn_ret = base_1280.crop((270, 565, 625, 645))
btn_ret.save(os.path.join(out_dir, "btn_retry_blue_v2.png"))

# Button 5 Hub Dark (360x80)
btn_hub = base_1280.crop((655, 565, 1015, 645))
btn_hub.save(os.path.join(out_dir, "btn_hub_dark_v2.png"))

print("All high-res V2 button assets generated successfully!")
