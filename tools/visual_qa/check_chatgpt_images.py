import os
from PIL import Image

folder = r"c:\Users\patry\Desktop\mutant"
for f in os.listdir(folder):
    if f.startswith("ChatGPT Image") and f.endswith(".png"):
        p = os.path.join(folder, f)
        im = Image.open(p)
        print(f"{f}: size={im.size}, mode={im.mode}")
