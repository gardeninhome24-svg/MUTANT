from PIL import Image

src = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794168896683_90160beb.jpg"
im = Image.open(src)

# Top Right: ELEMENTY UI / RAMKI / PANELE
# The 3 clean stat boxes are at:
# y: 235..315 (in 1024x682 coordinates)
# Box 1: x: 802..868, y: 240..310
# Box 2: x: 874..940, y: 240..310
# Box 3: x: 946..1012, y: 240..310

box1 = im.crop((802, 240, 868, 310))
box1.save(r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\ui_v2\clean_stat_box_1.png")

# Also look at the clean panel plate:
# x: 798..1012, y: 130..220
plate = im.crop((798, 130, 1012, 220))
plate.save(r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\ui_v2\clean_plate.png")

print("Saved clean stat box and plate!")
