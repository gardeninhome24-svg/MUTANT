# -*- coding: utf-8 -*-
import os
from PIL import Image

frames_dir = r"C:\Users\patry\Desktop\2026\MutantSurvivor\build_artifacts\frames_60s"
brain_dir = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215"
out_gif_1 = os.path.join(r"C:\Users\patry\Desktop\2026\MutantSurvivor\build_artifacts", "v1_gameplay_60s_horde_battle.gif")
out_gif_2 = os.path.join(brain_dir, "v1_gameplay_60s_horde_battle.gif")

images = []
for i in range(60):
    fn = f"frame_{i:02d}.png"
    fp = os.path.join(frames_dir, fn)
    if os.path.exists(fp):
        img = Image.open(fp).convert("RGBA")
        img_small = img.resize((360, 640), Image.Resampling.LANCZOS)
        images.append(img_small.convert("P", palette=Image.ADAPTIVE))

if images:
    images[0].save(
        out_gif_1,
        save_all=True,
        append_images=images[1:],
        optimize=True,
        duration=120, # ~120ms per frame -> smooth 60-step action sequence
        loop=0
    )
    images[0].save(
        out_gif_2,
        save_all=True,
        append_images=images[1:],
        optimize=True,
        duration=120,
        loop=0
    )
    print(f"Successfully compiled 60-frame live gameplay GIF! Total frames: {len(images)}")
    print(f"File size: {os.path.getsize(out_gif_2) / (1024*1024):.2f} MB")
else:
    print("No frames found!")
