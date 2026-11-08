import os
import shutil

src_diffs = r"C:\Users\patry\Desktop\2026\MutantSurvivor\visual_qa\diffs"
art_dir = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215"

files = [
    "defeat_overlay_16x9_comparison.png",
    "defeat_overlay_16x9_heatmap.png",
    "defeat_overlay_16x9_overlay_50.png",
    "defeat_overlay_16x9_difference.png",
    "defeat_overlay_16x9_actual.png",
    "defeat_overlay_16x9_reference.png",
    "summary_report.json"
]

for f in files:
    p = os.path.join(src_diffs, f)
    if os.path.exists(p):
        shutil.copy2(p, os.path.join(art_dir, f))
        print("Copied to artifact:", f)
