from PIL import Image
import os

src_path = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794160635468_0e2ecceb.jpg"
out_dir = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\hd_defeat_v2"
os.makedirs(out_dir, exist_ok=True)

img = Image.open(src_path).convert("RGBA")
# Target 1280x720 base
img_1280 = img.resize((1280, 720), Image.Resampling.LANCZOS)
img_1280.save(os.path.join(out_dir, "defeat_bg_full_1280x720.png"))

print("Original size:", img.size)
print("Saved defeat_bg_full_1280x720.png")

# Now let's find the card coordinates in 1280x720:
# Card center is around x: 200..1080 (width ~880), y: 10..680 (height ~670)
# Let's crop individual elements precisely:

# 1. Top Biohazard Crest
# Crest center top: x: ~580..700, y: 0..120
crest = img_1280.crop((570, 4, 710, 134))
crest.save(os.path.join(out_dir, "crest_biohazard_glow.png"))

# 2. MISJA NIEUDANA Title
# x: 340..940, y: 110..210
title = img_1280.crop((350, 115, 930, 205))
title.save(os.path.join(out_dir, "title_misja_nieudana.png"))

# 3. Stat Tile Left (Fala)
# x: 250..510, y: 240..340
tile_fala = img_1280.crop((250, 242, 510, 342))
tile_fala.save(os.path.join(out_dir, "tile_stat_fala.png"))

# 4. Stat Tile Center (Czas)
# x: 520..780, y: 240..340
tile_czas = img_1280.crop((520, 242, 780, 342))
tile_czas.save(os.path.join(out_dir, "tile_stat_czas.png"))

# 5. Stat Tile Right (Zabici)
# x: 790..1050, y: 240..340
tile_zabici = img_1280.crop((785, 242, 1045, 342))
tile_zabici.save(os.path.join(out_dir, "tile_stat_zabici.png"))

# 6. Generic Stat Tile Background (clean box without text for dynamic numbers)
# Let's extract tile background texture
tile_bg = img_1280.crop((250, 242, 510, 342))
tile_bg.save(os.path.join(out_dir, "tile_stat_bg_base.png"))

# 7. Button Revive Gold
# x: 240..500, y: 415..525
btn_gold = img_1280.crop((242, 415, 502, 525))
btn_gold.save(os.path.join(out_dir, "btn_revive_gold_ref.png"))

# 8. Button Revive Ad Teal
# x: 520..780, y: 415..525
btn_ad = img_1280.crop((524, 415, 784, 525))
btn_ad.save(os.path.join(out_dir, "btn_revive_ad_ref.png"))

# 9. Button Attempt Purple
# x: 800..1050, y: 415..525
btn_attempt = img_1280.crop((804, 415, 1054, 525))
btn_attempt.save(os.path.join(out_dir, "btn_attempt_purple_ref.png"))

# 10. Button Retry Blue
# x: 270..620, y: 565..645
btn_retry = img_1280.crop((270, 565, 625, 645))
btn_retry.save(os.path.join(out_dir, "btn_retry_blue_ref.png"))

# 11. Button Hub Dark
# x: 655..1015, y: 565..645
btn_hub = img_1280.crop((655, 565, 1015, 645))
btn_hub.save(os.path.join(out_dir, "btn_hub_dark_ref.png"))

# 12. Full Armored Card Frame (cut out from background)
# x: 200..1080, y: 15..675
card_full = img_1280.crop((200, 10, 1085, 675))
card_full.save(os.path.join(out_dir, "card_armored_full.png"))

print("Successfully sliced all high-res defeat screen assets!")
