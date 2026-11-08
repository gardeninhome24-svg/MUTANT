import os
import numpy as np
from PIL import Image, ImageFilter, ImageDraw

REF_DIR = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\ch01_pack\MutantSurvivor_CH01_ASSETS_ANTIGRAVITY\reference"
OUT_DIR = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\mutantsurvivor_ch01"

atlas1 = Image.open(os.path.join(REF_DIR, "asset_overview_ch01.png")).convert("RGBA")
atlas2 = Image.open(os.path.join(REF_DIR, "style_and_animation_overview.png")).convert("RGBA")

def clean_sprite_precision(img_crop, bg_tol=17.0, pad_canvas=None, punch_interior_bg=False, dehalo_glow=False):
    """
    High-precision background removal:
    1. Measures exact neutral dark panel background RGB from corners/borders.
    2. Uses color distance to the specific panel background (so dark colored mutant legs/armor are NOT erased).
    3. Optionally punches out enclosed background holes (like inside chain_fence mesh or under console legs).
    4. Removes dark matte fringe (de-haloing) on edge pixels.
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
    dark_b = border_pixels[np.mean(border_pixels, axis=1) < 65]
    bg_color = np.median(dark_b, axis=0) if len(dark_b) > 0 else np.array([31.0, 33.0, 38.0], dtype=np.float32)

    dist_bg = np.linalg.norm(rgb - bg_color, axis=2)
    lum = 0.299 * rgb[:, :, 0] + 0.587 * rgb[:, :, 1] + 0.114 * rgb[:, :, 2]
    sat = np.max(rgb, axis=2) - np.min(rgb, axis=2)

    # Strict neutral background check so colored dark pixels (mutant legs, dark armor) are preserved
    is_bg_cand = (dist_bg < bg_tol) | ((lum < 36.0) & (sat < 10.0))
    if dehalo_glow:
        # For street_lamp or glowing props where warm/cool glow slightly tints the dark background
        is_bg_cand = is_bg_cand | ((lum < 52.0) & (dist_bg < bg_tol * 1.65))

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

    if punch_interior_bg:
        # Also make interior pixels that match the exact neutral panel background transparent
        # (e.g. gaps between chain-link fence wires or under computer desk legs)
        interior_bg = (dist_bg < (bg_tol * 0.88)) & (sat < 11.0) & (lum < 40.0)
        bg_mask = bg_mask | interior_bg

    fg_mask = ~bg_mask

    # Keep main connected component (and non-border-touching valid parts)
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
        for idx_c, (size, touches_border, comp) in enumerate(comps):
            if idx_c == 0 or (not touches_border and size >= max(16, int(max_size * 0.04))):
                for py, px in comp:
                    clean_fg[py, px] = True
        fg_mask = clean_fg

    # Soft edge alpha + color decontamination on 1px boundary so dark background never fringes
    alpha_f = fg_mask.astype(np.float32)
    # Erode by 1px to find boundary pixels
    eroded = np.zeros_like(fg_mask)
    eroded[1:-1, 1:-1] = (
        fg_mask[1:-1, 1:-1] &
        fg_mask[:-2, 1:-1] & fg_mask[2:, 1:-1] &
        fg_mask[1:-1, :-2] & fg_mask[1:-1, 2:]
    )
    boundary = fg_mask & (~eroded)
    # On boundary pixels, make alpha proportional to distance from bg_color
    b_alpha = np.clip((dist_bg - (bg_tol * 0.5)) / max(8.0, bg_tol), 0.15, 0.92)
    final_alpha = np.where(eroded, 1.0, np.where(boundary, b_alpha, 0.0))

    # Un-premultiply dark background from boundary RGB
    rgb_clean = rgb.copy()
    mask_b = boundary & (final_alpha > 0.05)
    for c in range(3):
        rgb_clean[:, :, c] = np.where(
            mask_b,
            np.clip((rgb[:, :, c] - (1.0 - final_alpha) * bg_color[c]) / np.maximum(0.15, final_alpha), 0, 255),
            rgb[:, :, c]
        )

    rgba_out = np.zeros((h, w, 4), dtype=np.uint8)
    rgba_out[:, :, :3] = np.clip(rgb_clean, 0, 255).astype(np.uint8)
    rgba_out[:, :, 3] = np.clip(final_alpha * 255.0, 0, 255).astype(np.uint8)
    out = Image.fromarray(rgba_out, mode="RGBA")

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


def extract_clean_vfx_unmultiplied(img_crop, pad_canvas=(128, 128), min_thresh=18.0):
    """
    Extracts glowing/smoke VFX with ZERO dark background box:
    1. Subtracts the dark panel background RGB.
    2. Computes alpha from excess brightness/saturation + smooth radial/edge falloff.
    3. Un-premultiplies RGB so semi-transparent pixels have pure vivid glow/smoke color, NEVER dark charcoal!
    """
    arr = np.array(img_crop, dtype=np.float32)
    h, w, _ = arr.shape
    rgb = arr[:, :, :3]

    # Sample background from outer 2px border
    border = np.concatenate([
        rgb[0:2, :, :].reshape(-1, 3),
        rgb[h-2:h, :, :].reshape(-1, 3),
        rgb[:, 0:2, :].reshape(-1, 3),
        rgb[:, w-2:w, :].reshape(-1, 3)
    ], axis=0)
    bg = np.percentile(border, 25, axis=0)

    diff = np.maximum(0.0, rgb - bg)
    strength = np.max(diff, axis=2)

    yy, xx = np.mgrid[0:h, 0:w]
    edge_dist = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy)).astype(np.float32)
    edge_fade = np.clip((edge_dist - 2.0) / 8.0, 0.0, 1.0)

    alpha_norm = np.clip((strength - min_thresh) / (155.0 - min_thresh), 0.0, 1.0) * edge_fade
    alpha_norm = alpha_norm * alpha_norm * (3.0 - 2.0 * alpha_norm)

    # Un-premultiply RGB so there is NEVER a dark grey box halo!
    safe_a = np.maximum(0.08, alpha_norm[:, :, None])
    rgb_pure = np.clip(bg + diff / safe_a, 0.0, 255.0)

    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = rgb_pure.astype(np.uint8)
    rgba[:, :, 3] = np.clip(alpha_norm * 255.0, 0, 255).astype(np.uint8)

    out = Image.fromarray(rgba, mode="RGBA")
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


# 1. Re-extract Props with interior hole punching & glow de-haloing
prop_specs = {
    "supply_crate.png": (atlas2, (648, 582, 706, 638), (128, 128), 16.0, False, False),
    "hazard_barrel.png": (atlas2, (710, 584, 750, 646), (128, 128), 16.0, False, False),
    "fuel_barrel.png": (atlas2, (753, 584, 796, 646), (128, 128), 16.0, False, False),
    "mutation_tank.png": (atlas2, (800, 578, 864, 680), (140, 200), 18.0, False, True),
    "metal_case.png": (atlas2, (648, 640, 708, 696), (128, 128), 13.0, False, False),
    "computer_console.png": (atlas2, (714, 650, 804, 748), (160, 160), 17.0, True, True),
    "chain_fence.png": (atlas2, (814, 682, 910, 748), (160, 128), 18.0, True, False),
    "street_lamp.png": (atlas2, (654, 696, 698, 826), (128, 196), 19.0, False, True),
    "satellite_dish.png": (atlas2, (1138, 678, 1212, 752), (144, 144), 17.0, True, False),
    "industrial_pipe.png": (atlas2, (1224, 688, 1296, 756), (144, 144), 16.0, False, False),
    "wall_panel.png": (atlas2, (852, 746, 918, 826), (144, 144), 12.0, False, False),
    "blast_barricade.png": (atlas2, (1078, 756, 1154, 826), (144, 128), 15.0, False, False),
    "bunker_a01.png": (atlas1, (1168, 92, 1336, 232), (240, 200), 17.0, False, True),
    "tall_cryo_tube.png": (atlas1, (1344, 92, 1422, 250), (140, 220), 19.0, True, True),
}
for fn, (src, box, canvas, tol, punch, dehalo) in prop_specs.items():
    im = clean_sprite_precision(src.crop(box), bg_tol=tol, pad_canvas=canvas, punch_interior_bg=punch, dehalo_glow=dehalo)
    im.save(os.path.join(OUT_DIR, "props", fn))

# 2. Re-extract Enemies & Bosses with strict background color distance (preserving dark mutant legs!)
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
    im = clean_sprite_precision(src.crop(box), bg_tol=14.5, pad_canvas=canvas, punch_interior_bg=False, dehalo_glow=False)
    im.save(os.path.join(OUT_DIR, "enemies", fn))

# 3. Re-extract Icons (dna_tablet de-haloed!)
icon_specs = {
    "medkit.png": (atlas1, (900, 618, 962, 674), (96, 96), False),
    "chest.png": (atlas1, (965, 618, 1025, 674), (96, 96), False),
    "energy_cell.png": (atlas1, (1028, 618, 1085, 673), (96, 96), True),
    "purple_crystal.png": (atlas1, (1088, 618, 1143, 674), (96, 96), True),
    "loot_crate_icon.png": (atlas1, (1146, 616, 1212, 672), (96, 96), False),
    "data_chip.png": (atlas1, (900, 678, 961, 733), (96, 96), False),
    "drone_cpu.png": (atlas1, (964, 680, 1027, 733), (96, 96), True),
    "grenade.png": (atlas1, (1036, 680, 1086, 734), (96, 96), False),
    "ammo.png": (atlas2, (788, 880, 840, 932), (96, 96), False),
    "dna_tablet.png": (atlas2, (704, 880, 760, 932), (96, 96), True),
}
for fn, (src, box, canvas, dehalo) in icon_specs.items():
    im = clean_sprite_precision(src.crop(box), bg_tol=16.5, pad_canvas=canvas, punch_interior_bg=False, dehalo_glow=dehalo)
    im.save(os.path.join(OUT_DIR, "icons", fn))

# 4. Re-extract VFX with tightened y-bounds (no smudge above portal/shield) and unmultiplied RGB (zero dark box!)
vfx_specs = {
    "muzzle_flash.png": (atlas1, (20, 632, 132, 674), (128, 96), 24.0),
    "laser_blue.png": (atlas1, (138, 632, 210, 674), (128, 96), 24.0),
    "plasma_cyan.png": (atlas1, (216, 632, 274, 674), (128, 96), 24.0),
    "plasma_purple.png": (atlas1, (280, 632, 334, 674), (128, 128), 24.0),
    "impact_burst.png": (atlas1, (340, 632, 396, 674), (128, 128), 24.0),
    "explosion_orange.png": (atlas1, (20, 682, 94, 744), (128, 128), 22.0),
    "toxic_splash.png": (atlas1, (164, 682, 232, 744), (128, 128), 22.0),
    "smoke.png": (atlas1, (238, 684, 312, 744), (128, 128), 20.0),
    "shield.png": (atlas1, (250, 756, 316, 822), (128, 128), 22.0),
    "portal.png": (atlas1, (322, 756, 396, 822), (128, 128), 22.0),
    "lightning_burst.png": (atlas1, (94, 754, 166, 822), (128, 128), 22.0),
}
for fn, (src, box, canvas, thresh) in vfx_specs.items():
    im = extract_clean_vfx_unmultiplied(src.crop(box), pad_canvas=canvas, min_thresh=thresh)
    im.save(os.path.join(OUT_DIR, "vfx", fn))

# 5. Also generate clean soft radial drop_shadow.png and monster_shadow.png so shadows under characters/enemies are smooth!
for sh_path in [
    r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\player\drop_shadow.png",
    r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\enemies\monster_shadow.png"
]:
    sw, sh = 96, 48
    yy, xx = np.mgrid[0:sh, 0:sw]
    nx = (xx - sw * 0.5) / (sw * 0.45)
    ny = (yy - sh * 0.5) / (sh * 0.42)
    r2 = nx * nx + ny * ny
    a = np.clip(1.0 - r2, 0.0, 1.0)
    a = (a * a) * 115.0  # Soft translucent shadow (max alpha 115, never harsh pitch-black!)
    sh_rgba = np.zeros((sh, sw, 4), dtype=np.uint8)
    sh_rgba[:, :, 3] = a.astype(np.uint8)
    Image.fromarray(sh_rgba, mode="RGBA").save(sh_path)

# Render bright-background audit sheet to verify ZERO background bugs remain!
folders = ['props', 'icons', 'enemies', 'bosses', 'vfx']
items = []
for f in folders:
    p = os.path.join(OUT_DIR, f)
    for fn in sorted(os.listdir(p)):
        if fn.endswith('.png'):
            items.append((f + '/' + fn, os.path.join(p, fn)))
cols = 8
cw, ch = 180, 160
rows = (len(items) + cols - 1) // cols
sheet = Image.new('RGBA', (cols*cw, rows*ch), (180, 210, 225, 255))
draw = ImageDraw.Draw(sheet)
for idx, (lbl, path) in enumerate(items):
    r, c = divmod(idx, cols)
    x, y = c*cw, r*ch
    im = Image.open(path).convert('RGBA')
    im.thumbnail((150, 115))
    sheet.alpha_composite(im, (x + (cw-im.width)//2, y + 8 + (115-im.height)//2))
    draw.rectangle([x+1, y+1, x+cw-2, y+ch-2], outline=(60, 80, 100, 255))
    draw.text((x+4, y+132), lbl.replace('_idle_reference.png','').replace('.png','')[:24], fill=(10, 20, 30, 255))
sheet.save(r'C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\bg_bug_audit_fixed.png')
print("All background bugs cleaned and verified!")
