from PIL import Image

src_path = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794160635468_0e2ecceb.jpg"
im = Image.open(src_path).convert("RGB").resize((1280, 720), Image.Resampling.LANCZOS)

# Crop the 3 stat tiles from the unpatched image:
# Tile 1 Fala: x: 195..505, y: 240..340
# Tile 2 Czas: x: 520..780, y: 240..340
# Tile 3 Zabici: x: 785..1045, y: 240..340

t1 = im.crop((195, 240, 505, 340))
t2 = im.crop((520, 240, 780, 340))
t3 = im.crop((785, 240, 1045, 340))

t1.save(r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\ui_v2\t1_ref_tile.png")
t2.save(r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\ui_v2\t2_ref_tile.png")
t3.save(r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\ui_v2\t3_ref_tile.png")

print("Saved reference tiles.")
