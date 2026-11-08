# -*- coding: utf-8 -*-
import os
from PIL import Image

frames_dir = r"C:\Users\patry\Desktop\2026\MutantSurvivor\build_artifacts\frames"
brain_dir = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215"
out_gif_path1 = os.path.join(r"C:\Users\patry\Desktop\2026\MutantSurvivor\build_artifacts", "v1_gameplay_30s_showcase.gif")
out_gif_path2 = os.path.join(brain_dir, "v1_gameplay_30s_showcase.gif")

images = []
for i in range(30):
    fn = f"gameplay_frame_{i:02d}.png"
    fp = os.path.join(frames_dir, fn)
    if os.path.exists(fp):
        img = Image.open(fp).convert("RGBA")
        # Scale to 360x640 for lightweight, fast-loading smooth GIF
        img_small = img.resize((360, 640), Image.Resampling.LANCZOS)
        # Convert to P mode with adaptive palette for crisp GIF rendering
        images.append(img_small.convert("P", palette=Image.ADAPTIVE))

if images:
    images[0].save(
        out_gif_path1,
        save_all=True,
        append_images=images[1:],
        optimize=True,
        duration=150, # 150ms per frame
        loop=0
    )
    images[0].save(
        out_gif_path2,
        save_all=True,
        append_images=images[1:],
        optimize=True,
        duration=150,
        loop=0
    )
    print(f"Successfully generated animated GIF with {len(images)} frames!")
    print(f"Saved to: {out_gif_path1}")
    print(f"Saved to: {out_gif_path2}")
else:
    print("No frames found!")
