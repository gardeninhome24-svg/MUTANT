import os
from PIL import Image

brain_uploaded = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded"
ref_base = r"C:\Users\patry\Desktop\2026\MutantSurvivor\visual_qa\references"

print("--- Extracting Reference Images for Visual QA ---")

# 1. Defeat Screen Reference (1280x720)
defeat_src = os.path.join(brain_uploaded, "media_1794160635468_0e2ecceb.jpg")
if os.path.exists(defeat_src):
    img = Image.open(defeat_src).convert("RGB")
    img_res = img.resize((1280, 720), Image.Resampling.LANCZOS)
    target_p = os.path.join(ref_base, "defeat", "defeat_overlay_1280x720_ref.png")
    img_res.save(target_p)
    print("Saved:", target_p, img_res.size)

# 2. HUD 16:9 Combat Reference (1280x720)
hud169_src = os.path.join(brain_uploaded, "media_1794167634756_a88b2ea6.jpg")
if os.path.exists(hud169_src):
    img = Image.open(hud169_src).convert("RGB")
    img_res = img.resize((1280, 720), Image.Resampling.LANCZOS)
    target_p = os.path.join(ref_base, "hud_16x9", "hud_combat_1280x720_ref.png")
    img_res.save(target_p)
    print("Saved:", target_p, img_res.size)

# 3. HUD 9:16 Mobile Reference (720x1280)
hud916_src = os.path.join(brain_uploaded, "media_1794167634743_ca9d78ab.jpg")
if os.path.exists(hud916_src):
    img = Image.open(hud916_src).convert("RGB")
    img_res = img.resize((720, 1280), Image.Resampling.LANCZOS)
    target_p = os.path.join(ref_base, "hud_9x16", "hud_mobile_720x1280_ref.png")
    img_res.save(target_p)
    print("Saved:", target_p, img_res.size)

# 4. Inventory Reference (1280x720)
inv_src = os.path.join(brain_uploaded, "media_1794167645461_7ba6df86.jpg")
if os.path.exists(inv_src):
    img = Image.open(inv_src).convert("RGB")
    img_res = img.resize((1280, 720), Image.Resampling.LANCZOS)
    target_p = os.path.join(ref_base, "inventory", "inventory_1280x720_ref.png")
    img_res.save(target_p)
    print("Saved:", target_p, img_res.size)

# 5. Victory Reference (1280x720)
vic_src = os.path.join(brain_uploaded, "media_1794160898385_6ee83d8e.jpg")
if os.path.exists(vic_src):
    img = Image.open(vic_src).convert("RGB")
    img_res = img.resize((1280, 720), Image.Resampling.LANCZOS)
    target_p = os.path.join(ref_base, "victory", "victory_1280x720_ref.png")
    img_res.save(target_p)
    print("Saved:", target_p, img_res.size)

print("All base references extracted and scaled successfully!")
