from PIL import Image, ImageDraw, ImageFilter
import os
import numpy as np

bg_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\defeat_background_landscape.png"
im = Image.open(bg_path).convert("RGBA")

# Sample dark metallic red texture from inside each tile:
# Tile 1 clean inner area: x: 260..320, y: 300..330
sample1 = im.crop((260, 300, 320, 330)).resize((140, 48))
im.paste(sample1, (340, 296))

# Tile 2 clean inner area: x: 530..585, y: 300..330
sample2 = im.crop((530, 300, 585, 330)).resize((160, 48))
im.paste(sample2, (605, 296))

# Tile 3 clean inner area: x: 795..855, y: 300..330
sample3 = im.crop((795, 300, 855, 330)).resize((140, 48))
im.paste(sample3, (865, 296))

im.convert("RGB").save(bg_path)
print("Successfully patched number regions on defeat_background_landscape.png!")
