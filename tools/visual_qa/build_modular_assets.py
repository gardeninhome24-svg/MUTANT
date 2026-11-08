from PIL import Image, ImageDraw, ImageFilter
import os
import numpy as np

src_ref = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794160635468_0e2ecceb.jpg"
src_atlas = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794168896683_90160beb.jpg"
out_dir = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\modular_ui"
os.makedirs(out_dir, exist_ok=True)

im_ref = Image.open(src_ref).convert("RGBA").resize((1280, 720), Image.Resampling.LANCZOS)
im_atlas = Image.open(src_atlas).convert("RGBA")

# 1. Clean Battlefield Backdrop without the baked card
# We keep the left part (helmet, crystals, x: 0..220), right part (flag, car, x: 1060..1280),
# top (sky, y: 0..60), bottom (rubble, crystals, y: 650..720)
# and fill the center with dark metallic battlefield atmosphere
backdrop = im_ref.copy()
draw = ImageDraw.Draw(backdrop)

# Draw dark battlefield gradient in center x: 210..1070, y: 40..660
dark_center = Image.new("RGBA", (880, 630), (14, 18, 24, 255))
# Add subtle noise/vignette to match surrounding rubble
np_center = np.zeros((630, 880, 4), dtype=np.uint8)
np_center[:, :, 0] = 16
np_center[:, :, 1] = 18
np_center[:, :, 2] = 22
np_center[:, :, 3] = 255
dark_tex = Image.fromarray(np_center)
backdrop.paste(dark_tex, (200, 35))

# Smooth transition borders
backdrop = backdrop.filter(ImageFilter.SMOOTH_MORE)
backdrop.save(os.path.join(out_dir, "defeat_backdrop_landscape.png"))

# Copy to root assets as well
root_assets = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets"
backdrop.save(os.path.join(root_assets, "defeat_backdrop_landscape.png"))

# 2. Armored Card Frame (Standalone NinePatch / TextureRect)
# Crop armored frame from atlas or ref
card_frame = im_ref.crop((205, 10, 1075, 670))
# Clear the interior of the card (where dynamic buttons and tiles will live)
card_clean = card_frame.copy()
draw_card = ImageDraw.Draw(card_clean)
# We keep the outer frame (border ~35px) and crest/title at top
# Fill interior: x: 30..840, y: 225..630 with clean dark textured plate
interior_fill = Image.new("RGBA", (810, 410), (16, 20, 26, 255))
card_clean.paste(interior_fill, (30, 225))
card_clean.save(os.path.join(out_dir, "card_armored_frame.png"))
card_clean.save(os.path.join(root_assets, "card_armored_frame.png"))

# 3. Clean Red Beveled Stat Tile (Empty background for dynamic text)
# In ref: tile size is 260x100
tile_clean = Image.new("RGBA", (260, 100), (0, 0, 0, 0))
draw_t = ImageDraw.Draw(tile_clean)
# Rounded rectangle with dark red bevel and outer red glow
draw_t.rounded_rectangle([2, 2, 258, 98], radius=10, fill=(24, 8, 12, 240), outline=(220, 45, 45, 230), width=2)
# Inner bevel highlight
draw_t.rounded_rectangle([5, 5, 255, 95], radius=8, outline=(90, 18, 22, 180), width=1)
tile_clean.save(os.path.join(out_dir, "tile_stat_box_clean.png"))
tile_clean.save(os.path.join(root_assets, "tile_stat_box_clean.png"))

# 4. Sliced High-Res Buttons with exact states
# Button 1 Revive Gold: Normal, Hover, Pressed, Disabled
btn_gold_norm = im_ref.crop((242, 415, 502, 525))
btn_gold_norm.save(os.path.join(out_dir, "btn_revive_gold_normal.png"))
btn_gold_norm.save(os.path.join(root_assets, "btn_revive_gold_normal.png"))

# Hover: brighter outer glow
btn_gold_hov = btn_gold_norm.copy().filter(ImageFilter.EDGE_ENHANCE)
btn_gold_hov.save(os.path.join(out_dir, "btn_revive_gold_hover.png"))
btn_gold_hov.save(os.path.join(root_assets, "btn_revive_gold_hover.png"))

# Pressed: slightly darker
btn_gold_pres = Image.blend(btn_gold_norm, Image.new("RGBA", btn_gold_norm.size, (0, 0, 0, 255)), 0.15)
btn_gold_pres.save(os.path.join(out_dir, "btn_revive_gold_pressed.png"))
btn_gold_pres.save(os.path.join(root_assets, "btn_revive_gold_pressed.png"))

# Disabled: from user's atlas middle-left state 4 (disabled dark steel with disabled icon)
btn_gold_dis = im_atlas.crop((381, 400, 493, 455)).resize((260, 110), Image.Resampling.LANCZOS)
btn_gold_dis.save(os.path.join(out_dir, "btn_revive_gold_disabled.png"))
btn_gold_dis.save(os.path.join(root_assets, "btn_revive_gold_disabled.png"))

# Button 2 Revive Ad (Cyan)
btn_ad = im_ref.crop((524, 415, 784, 525))
btn_ad.save(os.path.join(out_dir, "btn_revive_ad.png"))
btn_ad.save(os.path.join(root_assets, "btn_revive_ad.png"))

# Button 3 Attempt (Purple)
btn_att = im_ref.crop((804, 415, 1054, 525))
btn_att.save(os.path.join(out_dir, "btn_attempt_purple.png"))
btn_att.save(os.path.join(root_assets, "btn_attempt_purple.png"))

# Button 4 Retry (Blue)
btn_ret = im_ref.crop((270, 565, 625, 645))
btn_ret.save(os.path.join(out_dir, "btn_retry_blue.png"))
btn_ret.save(os.path.join(root_assets, "btn_retry_blue.png"))

# Button 5 Hub (Dark Steel)
btn_hub = im_ref.crop((655, 565, 1015, 645))
btn_hub.save(os.path.join(out_dir, "btn_hub_dark.png"))
btn_hub.save(os.path.join(root_assets, "btn_hub_dark.png"))

# Stat icons:
icon_flag = im_ref.crop((260, 255, 320, 315))
icon_flag.save(os.path.join(out_dir, "icon_flag.png"))
icon_flag.save(os.path.join(root_assets, "icon_flag.png"))

icon_timer = im_ref.crop((530, 255, 590, 315))
icon_timer.save(os.path.join(out_dir, "icon_timer.png"))
icon_timer.save(os.path.join(root_assets, "icon_timer.png"))

icon_skull = im_ref.crop((795, 255, 855, 315))
icon_skull.save(os.path.join(out_dir, "icon_skull.png"))
icon_skull.save(os.path.join(root_assets, "icon_skull.png"))

print("All modular visual components generated and saved to addons/ms_balance/assets/!")
