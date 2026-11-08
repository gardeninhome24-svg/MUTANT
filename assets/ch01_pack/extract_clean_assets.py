import os
import json
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

REF_DIR = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\ch01_pack\MutantSurvivor_CH01_ASSETS_ANTIGRAVITY\reference"
PACK_DIR = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\ch01_pack\MutantSurvivor_CH01_ASSETS_ANTIGRAVITY"
OUT_DIR = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\mutantsurvivor_ch01"

atlas1 = Image.open(os.path.join(REF_DIR, "asset_overview_ch01.png")).convert("RGBA")
atlas2 = Image.open(os.path.join(REF_DIR, "style_and_animation_overview.png")).convert("RGBA")
atlas3 = Image.open(os.path.join(REF_DIR, "target_gameplay_visual.png")).convert("RGBA")

for sub in ["tiles", "props", "characters", "enemies", "bosses", "icons", "vfx", "ui", "weapons", "maps", "reference"]:
    os.makedirs(os.path.join(OUT_DIR, sub), exist_ok=True)

for fn in os.listdir(REF_DIR):
    if fn.endswith(".png"):
        Image.open(os.path.join(REF_DIR, fn)).save(os.path.join(OUT_DIR, "reference", fn))

for fn in os.listdir(os.path.join(PACK_DIR, "ui")):
    if fn.endswith(".png"):
        Image.open(os.path.join(PACK_DIR, "ui", fn)).save(os.path.join(OUT_DIR, "ui", fn))


def extract_clean_alpha(img_crop, tol=22, max_bg_lum=44, pad_canvas=None, single_object=True):
    """
    Flood-fill background removal starting strictly from outer border pixels.
    When single_object=True, discards any disconnected edge fragments from neighboring sprites.
    """
    arr = np.array(img_crop, dtype=np.float32)
    h, w, _ = arr.shape
    rgb = arr[:, :, :3]

    border_pixels = np.concatenate([
        rgb[0:2, :, :].reshape(-1, 3),
        rgb[h-2:h, :, :].reshape(-1, 3),
        rgb[:, 0:2, :].reshape(-1, 3),
        rgb[:, w-2:w, :].reshape(-1, 3)
    ], axis=0)
    dark_border = border_pixels[np.mean(border_pixels, axis=1) < 85]
    bg_med = np.median(dark_border, axis=0) if len(dark_border) > 0 else np.median(border_pixels, axis=0)

    dist_med = np.linalg.norm(rgb - bg_med, axis=2)
    lum = 0.299 * rgb[:, :, 0] + 0.587 * rgb[:, :, 1] + 0.114 * rgb[:, :, 2]
    sat = np.max(rgb, axis=2) - np.min(rgb, axis=2)

    is_bg_cand = (dist_med < tol) | ((lum < max_bg_lum) & (sat < 16))

    visited = np.zeros((h, w), dtype=bool)
    bg_mask = np.zeros((h, w), dtype=bool)
    queue = []

    for x in range(w):
        for y in (0, 1, h - 2, h - 1):
            if is_bg_cand[y, x] and not visited[y, x]:
                visited[y, x] = True
                queue.append((y, x))
    for y in range(h):
        for x in (0, 1, w - 2, w - 1):
            if is_bg_cand[y, x] and not visited[y, x]:
                visited[y, x] = True
                queue.append((y, x))

    head = 0
    while head < len(queue):
        cy, cx = queue[head]
        head += 1
        bg_mask[cy, cx] = True
        for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if is_bg_cand[ny, nx]:
                    queue.append((ny, nx))

    fg_mask = ~bg_mask

    # Connected component analysis on foreground
    fg_visited = np.zeros((h, w), dtype=bool)
    comps = []
    for y in range(h):
        for x in range(w):
            if fg_mask[y, x] and not fg_visited[y, x]:
                comp = []
                q = [(y, x)]
                fg_visited[y, x] = True
                idx = 0
                touches_border = False
                while idx < len(q):
                    py, px = q[idx]
                    idx += 1
                    comp.append((py, px))
                    if py <= 1 or py >= h - 2 or px <= 1 or px >= w - 2:
                        touches_border = True
                    for ny, nx in ((py - 1, px), (py + 1, px), (py, px - 1), (py, px + 1)):
                        if 0 <= ny < h and 0 <= nx < w and fg_mask[ny, nx] and not fg_visited[ny, nx]:
                            fg_visited[ny, nx] = True
                            q.append((ny, nx))
                comps.append((len(comp), touches_border, comp))

    if comps:
        comps.sort(key=lambda c: c[0], reverse=True)
        max_size = comps[0][0]
        clean_fg = np.zeros((h, w), dtype=bool)
        if single_object:
            # Always keep largest component; keep secondary components only if they DO NOT touch border
            # and are reasonably close/large (e.g. detached muzzle tip or floating crystal)
            for idx_c, (size, touches_border, comp) in enumerate(comps):
                if idx_c == 0 or (not touches_border and size >= max(20, int(max_size * 0.05))):
                    for py, px in comp:
                        clean_fg[py, px] = True
        else:
            for size, touches_border, comp in comps:
                if size >= max(24, int(max_size * 0.03)):
                    for py, px in comp:
                        clean_fg[py, px] = True
        fg_mask = clean_fg

    alpha_f = fg_mask.astype(np.float32) * 255.0
    alpha_img = Image.fromarray(alpha_f.astype(np.uint8), mode="L").filter(ImageFilter.GaussianBlur(radius=0.4))
    alpha_arr = np.array(alpha_img, dtype=np.float32)
    alpha_arr = np.clip((alpha_arr - 28.0) * (255.0 / 210.0), 0, 255).astype(np.uint8)

    out = img_crop.copy()
    out.putalpha(Image.fromarray(alpha_arr, mode="L"))

    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    if pad_canvas:
        cw, ch = pad_canvas
        out.thumbnail((cw - 8, ch - 8), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        canvas.paste(out, ((cw - out.width) // 2, (ch - out.height) // 2))
        return canvas
    return out


def extract_vfx_alpha(img_crop, pad_canvas=(128, 128)):
    arr = np.array(img_crop, dtype=np.float32)
    rgb = arr[:, :, :3]
    bg = np.percentile(rgb, 10, axis=(0, 1))
    diff = np.maximum(0.0, rgb - bg)
    strength = np.max(diff, axis=2)
    h, w = strength.shape
    yy, xx = np.mgrid[0:h, 0:w]
    edge_dist = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy))
    edge_fade = np.clip(edge_dist / 6.0, 0.0, 1.0)
    alpha = np.clip((strength - 10.0) * (255.0 / 85.0), 0, 255) * edge_fade
    out = img_crop.copy()
    out.putalpha(Image.fromarray(alpha.astype(np.uint8), mode="L"))
    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    if pad_canvas:
        cw, ch = pad_canvas
        out.thumbnail((cw - 8, ch - 8), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        canvas.paste(out, ((cw - out.width) // 2, (ch - out.height) // 2))
        return canvas
    return out


# ==============================================================================
# 1. SEAMLESS FLOOR TILES (UNIFIED BORDER FRAME + DETAIL INTERIOR)
# ==============================================================================
col_boxes = [(821, 888), (907, 972), (990, 1053), (1072, 1135)]
row_boxes = [(106, 171), (188, 253), (271, 336), (354, 414)]

tile_names = [
    ["concrete_cross", "concrete_rubble", "steel_grate", "concrete_clean"],
    ["rust_plates", "warning_stripes", "toxic_moss", "concrete_fracture"],
    ["floor_blue", "floor_grid", "rock_break", "toxic_pool"],
    ["floor_scuffed", "floor_cracks", "floor_ash", "floor_dark"]
]

# Build master periodic wrap-around base slab from concrete_clean (row 0, col 3)
base_crop = atlas1.crop((col_boxes[3][0], row_boxes[0][0], col_boxes[3][1], row_boxes[0][1])).resize((128, 128), Image.Resampling.LANCZOS).convert("RGB")
base_arr = np.array(base_crop, dtype=np.float32)
# Make base_arr 100% periodic wrap-around via 4-quadrant cosine blend with shifted self
shifted = np.roll(np.roll(base_arr, 64, axis=0), 64, axis=1)
yy, xx = np.mgrid[0:128, 0:128]
wx = 0.5 - 0.5 * np.cos(2.0 * np.pi * xx / 128.0)
wy = 0.5 - 0.5 * np.cos(2.0 * np.pi * yy / 128.0)
w_center = wx * wy  # 1 at center, 0 at all edges
seamless_base = (1.0 - w_center[:, :, None]) * shifted + w_center[:, :, None] * base_arr

# Add subtle dark sci-fi architectural slab expansion joint (1px recessed seam + 1px bevel)
seamless_base[0, :, :] = seamless_base[0, :, :] * 0.65 + np.array([22, 27, 36]) * 0.35
seamless_base[127, :, :] = seamless_base[127, :, :] * 0.65 + np.array([22, 27, 36]) * 0.35
seamless_base[:, 0, :] = seamless_base[:, 0, :] * 0.65 + np.array([22, 27, 36]) * 0.35
seamless_base[:, 127, :] = seamless_base[:, 127, :] * 0.65 + np.array([22, 27, 36]) * 0.35
seamless_base[1, 1:127, :] = np.clip(seamless_base[1, 1:127, :] * 1.08, 0, 255)
seamless_base[1:127, 1, :] = np.clip(seamless_base[1:127, 1, :] * 1.08, 0, 255)
# Corner bolts on every slab
for by, bx in ((5, 5), (5, 122), (122, 5), (122, 122)):
    seamless_base[by-1:by+2, bx-1:bx+2, :] = np.array([42, 48, 58], dtype=np.float32)

# Compute smooth interior mask (0 at outer 16px border, 1 inside core) so EVERY tile shares
# the exact same seamless border ring and never produces a visible cut-off seam!
dist_edge = np.minimum(np.minimum(xx, 127 - xx), np.minimum(yy, 127 - yy)).astype(np.float32)
interior_mask = np.clip((dist_edge - 3.0) / 18.0, 0.0, 1.0)
interior_mask = interior_mask * interior_mask * (3.0 - 2.0 * interior_mask)  # smoothstep

for r_idx, (y0, y1) in enumerate(row_boxes):
    for c_idx, (x0, x1) in enumerate(col_boxes):
        t_name = tile_names[r_idx][c_idx]
        crop = atlas1.crop((x0, y0, x1, y1)).resize((128, 128), Image.Resampling.LANCZOS).convert("RGB")
        arr = np.array(crop, dtype=np.float32)

        # Harmonize extreme brown dirt tiles slightly toward dark slate so they don't look like brown squares
        if t_name in ("floor_cracks", "rust_plates", "floor_ash", "concrete_rubble"):
            arr = arr * 0.68 + seamless_base * 0.32
        elif t_name == "floor_blue":
            # Blend horizontal bar softly
            arr = arr * 0.75 + seamless_base * 0.25

        blended = (1.0 - interior_mask[:, :, None]) * seamless_base + interior_mask[:, :, None] * arr
        tile_out = Image.fromarray(np.clip(blended, 0, 255).astype(np.uint8), mode="RGB").convert("RGBA")
        tile_out.save(os.path.join(OUT_DIR, "tiles", f"{t_name}.png"))


# ==============================================================================
# 2. EXTRACT CHARACTERS
# ==============================================================================
char_specs = {
    "soldier_idle_reference.png": (atlas1, (20, 456, 106, 570), (144, 196)),
    "engineer_idle_reference.png": (atlas1, (107, 456, 195, 570), (144, 196)),
    "medic_idle_reference.png": (atlas1, (200, 456, 293, 570), (144, 196)),
    "scout_idle_reference.png": (atlas1, (296, 456, 396, 570), (144, 196)),
}
for fn, (src, box, canvas) in char_specs.items():
    im = extract_clean_alpha(src.crop(box), tol=24, max_bg_lum=44, pad_canvas=canvas, single_object=True)
    im.save(os.path.join(OUT_DIR, "characters", fn))

portrait_crop = atlas3.crop((14, 10, 124, 124)).resize((128, 128), Image.Resampling.LANCZOS)
portrait_crop.save(os.path.join(OUT_DIR, "ui", "hero_portrait.png"))


# ==============================================================================
# 3. EXTRACT ENEMIES & BOSSES
# ==============================================================================
enemy_specs = {
    "hound_idle_reference.png": (atlas1, (422, 464, 515, 578), (160, 160)),
    "beetle_idle_reference.png": (atlas1, (515, 462, 606, 580), (160, 160)),
    "stalker_idle_reference.png": (atlas1, (606, 458, 681, 582), (160, 160)),
    "brute_idle_reference.png": (atlas1, (681, 456, 772, 582), (160, 160)),
    "spitter_idle_reference.png": (atlas1, (772, 462, 858, 582), (160, 160)),
    "winged_idle_reference.png": (atlas1, (858, 456, 965, 582), (160, 160)),
    "elite_stalker_idle_reference.png": (atlas1, (984, 458, 1055, 582), (160, 180)),
    "elite_brute_idle_reference.png": (atlas1, (1055, 454, 1152, 582), (160, 180)),
    "elite_hound_idle_reference.png": (atlas1, (1163, 464, 1238, 582), (160, 180)),
    "mutant_hound_variant.png": (atlas2, (892, 442, 956, 506), (144, 144)),
    "toxic_beetle_variant.png": (atlas2, (956, 442, 1020, 506), (144, 144)),
    "infected_human_variant.png": (atlas2, (1021, 434, 1068, 506), (144, 144)),
    "heavy_brute_variant.png": (atlas2, (1122, 434, 1182, 506), (144, 144)),
}
for fn, (src, box, canvas) in enemy_specs.items():
    im = extract_clean_alpha(src.crop(box), tol=24, max_bg_lum=44, pad_canvas=canvas, single_object=True)
    im.save(os.path.join(OUT_DIR, "enemies", fn))

boss_specs = {
    "hive_mother_reference.png": (atlas1, (1266, 454, 1518, 584), (320, 220)),
    "behemoth_boss_reference.png": (atlas2, (892, 542, 1048, 660), (260, 220)),
    "warlord_boss_reference.png": (atlas2, (1050, 540, 1158, 660), (220, 220)),
    "mindflayer_boss_reference.png": (atlas2, (1162, 536, 1298, 660), (240, 220)),
}
for fn, (src, box, canvas) in boss_specs.items():
    im = extract_clean_alpha(src.crop(box), tol=24, max_bg_lum=44, pad_canvas=canvas, single_object=True)
    im.save(os.path.join(OUT_DIR, "bosses", fn))


# ==============================================================================
# 4. EXTRACT ENVIRONMENTAL PROPS (WITH DARK METAL PROTECTION)
# ==============================================================================
prop_specs = {
    "supply_crate.png": (atlas2, (648, 582, 706, 638), (128, 128), 18, 34),
    "hazard_barrel.png": (atlas2, (710, 584, 750, 646), (128, 128), 18, 34),
    "fuel_barrel.png": (atlas2, (753, 584, 796, 646), (128, 128), 18, 34),
    "mutation_tank.png": (atlas2, (800, 578, 864, 680), (140, 200), 20, 36),
    "metal_case.png": (atlas2, (648, 640, 708, 696), (128, 128), 14, 28),
    "computer_console.png": (atlas2, (714, 650, 804, 748), (160, 160), 18, 34),
    "chain_fence.png": (atlas2, (814, 682, 910, 748), (160, 128), 18, 34),
    "street_lamp.png": (atlas2, (654, 696, 698, 826), (128, 196), 18, 34),
    "satellite_dish.png": (atlas2, (1138, 678, 1212, 752), (144, 144), 18, 34),
    "industrial_pipe.png": (atlas2, (1224, 688, 1296, 756), (144, 144), 18, 34),
    "wall_panel.png": (atlas2, (852, 746, 918, 826), (144, 144), 13, 26),
    "blast_barricade.png": (atlas2, (1078, 756, 1154, 826), (144, 128), 16, 32),
    "bunker_a01.png": (atlas1, (1168, 92, 1336, 232), (240, 200), 18, 34),
    "tall_cryo_tube.png": (atlas1, (1344, 92, 1422, 250), (140, 220), 18, 34),
}
for fn, (src, box, canvas, tol, max_lum) in prop_specs.items():
    im = extract_clean_alpha(src.crop(box), tol=tol, max_bg_lum=max_lum, pad_canvas=canvas, single_object=True)
    im.save(os.path.join(OUT_DIR, "props", fn))


# ==============================================================================
# 5. EXTRACT ICONS & SKILL BADGES (ZERO NEIGHBOR BLEED, FULL GOLDEN FRAMES)
# ==============================================================================
icon_specs = {
    "medkit.png": (atlas1, (900, 618, 962, 674), (96, 96)),
    "chest.png": (atlas1, (965, 618, 1025, 674), (96, 96)),
    "energy_cell.png": (atlas1, (1028, 618, 1085, 673), (96, 96)),
    "purple_crystal.png": (atlas1, (1088, 618, 1143, 674), (96, 96)),
    "loot_crate_icon.png": (atlas1, (1146, 616, 1212, 672), (96, 96)),
    "data_chip.png": (atlas1, (900, 678, 961, 733), (96, 96)),
    "drone_cpu.png": (atlas1, (964, 680, 1027, 733), (96, 96)),
    "grenade.png": (atlas1, (1036, 680, 1086, 734), (96, 96)),
    "ammo.png": (atlas2, (788, 880, 840, 932), (96, 96)),
    "dna_tablet.png": (atlas2, (704, 880, 760, 932), (96, 96)),
}
for fn, (src, box, canvas) in icon_specs.items():
    im = extract_clean_alpha(src.crop(box), tol=22, max_bg_lum=42, pad_canvas=canvas, single_object=True)
    im.save(os.path.join(OUT_DIR, "icons", fn))

# 7 Golden Skill Badges in atlas1: y is 761..801, x spans 905..1224
skill_boxes = {
    "skill_rifle.png": (906, 761, 946, 801),
    "skill_ammo.png": (952, 761, 992, 801),
    "skill_heal.png": (998, 761, 1038, 801),
    "skill_shield.png": (1044, 761, 1084, 801),
    "skill_tesla.png": (1090, 761, 1130, 801),
    "skill_crit.png": (1136, 761, 1176, 801),
    "skill_luck.png": (1182, 761, 1222, 801),
}
for fn, box in skill_boxes.items():
    crop = atlas1.crop(box).resize((76, 76), Image.Resampling.LANCZOS)
    # Round-rect alpha mask so the entire golden badge and its dark interior stay intact
    mask = Image.new("L", (76, 76), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle([2, 2, 73, 73], radius=10, fill=255)
    crop.putalpha(mask)
    canvas = Image.new("RGBA", (84, 84), (0, 0, 0, 0))
    canvas.paste(crop, (4, 4))
    canvas.save(os.path.join(OUT_DIR, "icons", fn))


# ==============================================================================
# 6. EXTRACT VFX
# ==============================================================================
vfx_specs = {
    "muzzle_flash.png": (atlas1, (18, 628, 134, 676), (128, 96)),
    "laser_blue.png": (atlas1, (136, 628, 212, 676), (128, 96)),
    "plasma_cyan.png": (atlas1, (214, 628, 276, 676), (128, 96)),
    "plasma_purple.png": (atlas1, (278, 628, 336, 676), (128, 128)),
    "impact_burst.png": (atlas1, (338, 628, 398, 676), (128, 128)),
    "explosion_orange.png": (atlas1, (18, 680, 96, 746), (128, 128)),
    "toxic_splash.png": (atlas1, (162, 680, 234, 746), (128, 128)),
    "smoke.png": (atlas1, (236, 680, 314, 746), (128, 128)),
    "shield.png": (atlas1, (248, 748, 318, 822), (128, 128)),
    "portal.png": (atlas1, (320, 748, 398, 824), (128, 128)),
}
for fn, (src, box, canvas) in vfx_specs.items():
    im = extract_vfx_alpha(src.crop(box), pad_canvas=canvas)
    im.save(os.path.join(OUT_DIR, "vfx", fn))


# ==============================================================================
# 7. GENERATE SEAMLESS TILEMAP PREVIEW & REPAIRED CONTACT SHEET
# ==============================================================================
with open(os.path.join(PACK_DIR, "maps", "ch01_stage001_layout.json"), "r", encoding="utf-8") as f:
    layout = json.load(f)

preview = Image.new("RGBA", (16 * 64, 16 * 64), (20, 24, 30, 255))
tile_cache = {}
for yy, row in enumerate(layout["tiles"]):
    for xx, t_name in enumerate(row):
        if t_name not in tile_cache:
            t_im = Image.open(os.path.join(OUT_DIR, "tiles", f"{t_name}.png")).resize((64, 64), Image.Resampling.LANCZOS)
            tile_cache[t_name] = t_im
        preview.paste(tile_cache[t_name], (xx * 64, yy * 64))
preview.save(os.path.join(OUT_DIR, "maps", "ch01_tilemap_preview.png"))

folders = ["characters", "enemies", "bosses", "props", "icons", "vfx", "tiles"]
items = []
for folder in folders:
    p = os.path.join(OUT_DIR, folder)
    for fn in sorted(os.listdir(p)):
        if fn.endswith(".png") and not fn.startswith("soldier_walk") and not fn.startswith("soldier_shoot"):
            items.append((f"{folder}/{fn}", os.path.join(p, fn)))

cols = 8
cell_w, cell_h = 180, 160
rows = (len(items) + cols - 1) // cols
sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (24, 28, 36, 255))
draw = ImageDraw.Draw(sheet)

for idx, (label, path) in enumerate(items):
    r, c = divmod(idx, cols)
    x, y = c * cell_w, r * cell_h
    for cy in range(y + 8, y + 128, 16):
        for cx in range(x + 8, x + 172, 16):
            col = (52, 58, 68, 255) if ((cx // 16 + cy // 16) % 2 == 0) else (36, 40, 50, 255)
            draw.rectangle([cx, cy, cx + 15, cy + 15], fill=col)
    im = Image.open(path).convert("RGBA")
    im.thumbnail((152, 112), Image.Resampling.LANCZOS)
    ox = x + (cell_w - im.width) // 2
    oy = y + 8 + (116 - im.height) // 2
    sheet.alpha_composite(im, (ox, oy))
    draw.rectangle([x + 2, y + 2, x + cell_w - 3, y + cell_h - 3], outline=(90, 130, 160, 255), width=1)
    short_lbl = label.replace("_idle_reference.png", "").replace("_reference.png", "").replace(".png", "")
    draw.text((x + 6, y + 132), short_lbl[:24], fill=(225, 245, 255, 255))

audit_out = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\ch01_pack\contact_sheet_repaired.png"
sheet.save(audit_out)
print("Pass 2 complete! Items:", len(items))
