import os
from PIL import Image
import numpy as np

folder = r"c:\Users\patry\Desktop\mutant"
files = [f for f in os.listdir(folder) if f.startswith("ChatGPT Image") and f.endswith(".png")]

print("Analyzing ChatGPT images in mutant folder...")
for f in files:
    p = os.path.join(folder, f)
    im = Image.open(p)
    # Check alpha channel presence and content
    if im.mode == "RGBA":
        a = np.array(im)[:, :, 3]
        transp_pct = np.mean(a < 10) * 100
        print(f"{f}: {im.size}, Alpha Transparent: {transp_pct:.1f}%")
    else:
        print(f"{f}: {im.size}, Mode: {im.mode}")
