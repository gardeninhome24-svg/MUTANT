import os
import numpy as np
from PIL import Image, ImageDraw

PACK_DIR = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\pack_123\123"
OUT_ROOT = r"C:\Users\patry\Desktop\2026\MutantSurvivor\assets\mutantsurvivor_ch01"
ARTIFACT_SHEET = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\hd_123_contact_sheet.png"

for sub in ["characters", "enemies", "bosses", "weapons", "icons", "vfx", "props", "tiles", "ui"]:
    os.makedirs(os.path.join(OUT_ROOT, sub), exist_ok=True)


def load_sheet(num: int) -> Image.Image:
    for fn in os.listdir(PACK_DIR):
        if fn.endswith(f"-{num}.png"):
            return Image.open(os.path.join(PACK_DIR, fn)).convert("RGBA")
    raise FileNotFoundError(f"Sheet -{num}.png not found")


def crop_tight_rgba(im: Image.Image, box: tuple, pad: int = 4) -> Image.Image:
    sub = im.crop(box)
    arr = np.array(sub)
    mask = arr[:, :, 3] > 12
    if not mask.any():
        return sub
    ys, xs = np.where(mask)
    y0 = max(0, int(ys.min()) - pad)
    y1 = min(sub.height, int(ys.max()) + 1 + pad)
    x0 = max(0, int(xs.min()) - pad)
    x1 = min(sub.width, int(xs.max()) + 1 + pad)
    cropped = sub.crop((x0, y0, x1, y1))
    # Zero out RGB on fully transparent pixels for clean bilinear filtering
    c_arr = np.array(cropped)
    zero_a = c_arr[:, :, 3] < 8
    c_arr[zero_a] = [0, 0, 0, 0]
    return Image.fromarray(c_arr, "RGBA")


saved_previews = []


def save_sprite(im: Image.Image, rel_paths: list, label: str, max_dim: int = 256):
    if max(im.width, im.height) > max_dim:
        scale = max_dim / float(max(im.width, im.height))
        new_size = (max(1, int(round(im.width * scale))), max(1, int(round(im.height * scale))))
        im = im.resize(new_size, Image.Resampling.LANCZOS)
    for rp in rel_paths:
        full_p = os.path.join(OUT_ROOT, rp)
        os.makedirs(os.path.dirname(full_p), exist_ok=True)
        im.save(full_p)
    saved_previews.append((label, im))


# 1. SHEET -2: 8 REGULAR ENEMIES
s2 = load_sheet(2)
enemy_specs = [
    ((10, 130, 360, 470), ["enemies/hound_idle_reference.png", "enemies/mutant_hound_variant.png"], "Hound (Biegacz)"),
    ((365, 130, 725, 470), ["enemies/beetle_idle_reference.png", "enemies/toxic_beetle_variant.png"], "Beetle (Pelzacz)"),
    ((730, 120, 1130, 470), ["enemies/brute_idle_reference.png", "enemies/heavy_brute_variant.png"], "Brute (Zdziczaly)"),
    ((1140, 140, 1440, 470), ["enemies/infected_human_variant.png"], "Feral Runner"),
    ((5, 580, 370, 940), ["enemies/spitter_idle_reference.png"], "Acid Spitter"),
    ((372, 580, 720, 940), ["enemies/stalker_idle_reference.png"], "Claw Stalker"),
    ((720, 580, 1110, 940), ["enemies/winged_idle_reference.png"], "Mutant Bat"),
    ((1065, 650, 1444, 940), ["enemies/larva_idle_reference.png"], "Toxic Larva"),
]
for box, paths, lbl in enemy_specs:
    spr = crop_tight_rgba(s2, box)
    save_sprite(spr, paths, lbl, max_dim=180)

# 2. SHEET -3: 10 HERO CLASSES & SKINS
s3 = load_sheet(3)
hero_specs = [
    ((5, 80, 322, 500), ["characters/soldier_idle.png", "characters/soldier_idle_reference.png"], "Hero: Soldier"),
    ((325, 80, 565, 500), ["characters/engineer_idle.png", "characters/engineer_idle_reference.png"], "Hero: Engineer"),
    ((580, 80, 840, 500), ["characters/medic_idle.png", "characters/medic_idle_reference.png"], "Hero: Medic"),
    ((842, 80, 1155, 500), ["characters/scout_idle.png", "characters/scout_idle_reference.png"], "Hero: Scout"),
    ((1140, 80, 1440, 500), ["characters/hazmat_trooper.png"], "Skin: Bio-Trooper"),
    ((10, 545, 295, 1005), ["characters/cyber_ronin.png"], "Skin: Cyber Ronin"),
    ((310, 545, 595, 1005), ["characters/wasteland_raider.png"], "Skin: Raider"),
    ((575, 545, 845, 1005), ["characters/commander_mara.png"], "NPC: Mara"),
    ((855, 545, 1140, 1005), ["characters/crimson_medic.png"], "NPC: Nina"),
    ((1118, 545, 1445, 1005), ["characters/void_sniper.png"], "NPC: Kira"),
]
for box, paths, lbl in hero_specs:
    spr = crop_tight_rgba(s3, box)
    save_sprite(spr, paths, lbl, max_dim=190)

# Create crisp Hero Portrait for HUD from Soldier upper body
soldier_full = crop_tight_rgba(s3, (5, 80, 322, 500))
portrait = soldier_full.crop((20, 0, min(soldier_full.width, 230), min(soldier_full.height, 210))).resize((128, 128), Image.Resampling.LANCZOS)
portrait.save(os.path.join(OUT_ROOT, "ui/hero_portrait.png"))

# 3. SHEET -4: 4 ELITES + 4 CHAPTER BOSSES
s4 = load_sheet(4)
elite_boss_specs = [
    ((15, 150, 385, 420), ["enemies/elite_hound_idle_reference.png"], "Elite Hound", 210),
    ((390, 85, 715, 420), ["enemies/elite_brute_idle_reference.png"], "Elite Brute", 220),
    ((720, 85, 1040, 420), ["enemies/elite_stalker_idle_reference.png"], "Elite Stalker", 220),
    ((1050, 95, 1440, 420), ["enemies/elite_spider_idle_reference.png"], "Elite Brood", 220),
    ((2, 485, 348, 940), ["bosses/hive_mother_reference.png"], "Boss: Matka Roju", 280),
    ((348, 485, 719, 940), ["bosses/behemoth_boss_reference.png"], "Boss: Taran", 280),
    ((719, 485, 1100, 940), ["bosses/cryo_king_boss.png"], "Boss: Krol Krio", 280),
    ((1100, 455, 1445, 945), ["bosses/architect_zero_boss.png"], "Boss: Architekt Zero", 280),
]
for box, paths, lbl, mdim in elite_boss_specs:
    spr = crop_tight_rgba(s4, box)
    save_sprite(spr, paths, lbl, max_dim=mdim)

# 4. SHEET -5: 12 WEAPONS & GADGETS
s5 = load_sheet(5)
weapon_specs = [
    ((35, 50, 485, 265), ["weapons/weapon_1.png", "icons/skill_rifle.png"], "Weapon 1: Plasma"),
    ((500, 40, 955, 270), ["weapons/weapon_2.png"], "Weapon 2: Assault"),
    ((970, 50, 1420, 265), ["weapons/weapon_3.png"], "Weapon 3: Shotgun"),
    ((50, 280, 440, 510), ["weapons/weapon_4.png"], "Weapon 4: SMG"),
    ((475, 280, 940, 505), ["weapons/weapon_5.png", "icons/skill_tesla.png"], "Weapon 5: Railgun"),
    ((965, 275, 1425, 500), ["weapons/weapon_6.png"], "Weapon 6: Cannon"),
    ((35, 520, 475, 750), ["weapons/weapon_7.png"], "Weapon 7: Flamer"),
    ((505, 515, 940, 755), ["weapons/weapon_8.png"], "Weapon 8: Bio-Gun"),
    ((980, 495, 1400, 735), ["weapons/weapon_9.png", "icons/drone_cpu.png"], "Weapon 9: Drone"),
    ((50, 775, 440, 1035), ["weapons/weapon_10.png", "icons/skill_crit.png"], "Weapon 10: Saw"),
    ((590, 765, 830, 1050), ["weapons/weapon_11.png"], "Weapon 11: Grenade"),
    ((990, 775, 1400, 1030), ["weapons/weapon_12.png"], "Weapon 12: Injector"),
]
for box, paths, lbl in weapon_specs:
    spr = crop_tight_rgba(s5, box)
    save_sprite(spr, paths, lbl, max_dim=160)

# 5. SHEET -6: 20 PICKUPS, ICONS & VFX
s6 = load_sheet(6)
vfx_icon_specs = [
    ((35, 55, 275, 280), ["icons/data_chip.png"], "Credits", 110),
    ((300, 35, 520, 275), ["icons/purple_crystal.png"], "Crystals", 110),
    ((580, 50, 795, 270), ["icons/ammo.png", "icons/skill_ammo.png"], "Ammo", 110),
    ((830, 20, 1120, 285), ["icons/medkit.png", "icons/skill_heal.png"], "Medkit", 120),
    ((1160, 15, 1400, 285), ["icons/energy_cell.png"], "Energy Cell", 120),
    ((20, 305, 285, 525), ["icons/chest.png", "icons/loot_crate_icon.png"], "Loot Chest", 128),
    ((310, 300, 515, 525), ["icons/grenade.png"], "Frag Grenade", 110),
    ((535, 310, 740, 525), ["icons/skill_luck.png"], "Magnet", 110),
    ((760, 305, 975, 520), ["icons/shield_orb.png"], "Shield Orb", 110),
    ((985, 315, 1225, 515), ["icons/keycard_icon.png"], "Keycard", 110),
    ((1245, 295, 1420, 525), ["icons/dna_tablet.png"], "DNA Sample", 115),
    ((35, 550, 240, 748), ["icons/star_badge.png"], "Star Token", 110),
    ((270, 555, 600, 738), ["vfx/muzzle_flash.png"], "Muzzle Flash", 150),
    ((602, 540, 820, 738), ["vfx/impact_burst.png", "vfx/lightning_burst.png"], "Hit Spark", 140),
    ((830, 575, 1130, 715), ["vfx/laser_blue.png", "vfx/plasma_cyan.png"], "Plasma Bolt", 140),
    ((1135, 600, 1435, 685), ["vfx/red_beam.png"], "Laser Beam", 150),
    ((30, 780, 355, 1030), ["vfx/toxic_splash.png"], "Toxic Splash", 170),
    ((375, 745, 690, 1040), ["vfx/portal.png", "vfx/plasma_purple.png"], "Vortex Portal", 180),
    ((710, 740, 1080, 1035), ["vfx/explosion_orange.png"], "Explosion", 190),
    ((1110, 735, 1435, 1045), ["vfx/shield.png", "icons/skill_shield.png"], "Energy Shield", 170),
]
for box, paths, lbl, mdim in vfx_icon_specs:
    spr = crop_tight_rgba(s6, box)
    save_sprite(spr, paths, lbl, max_dim=mdim)

# 6. SHEET -7: 14 ENVIRONMENT PROPS
s7 = load_sheet(7)
prop_specs = [
    ((15, 10, 465, 290), ["props/bunker_a01.png"], "Bunker A-01", 260),
    ((485, 15, 700, 295), ["props/tall_cryo_tube.png"], "Cryo Tube", 200),
    ((745, 10, 1070, 295), ["props/mutation_tank.png"], "Mutation Tank", 210),
    ((1100, 50, 1410, 290), ["props/computer_console.png"], "Lab Console", 200),
    ((75, 300, 320, 535), ["props/satellite_dish.png"], "Radar Dish", 175),
    ((425, 330, 695, 535), ["props/supply_crate.png"], "Supply Crate", 155),
    ((770, 350, 1075, 525), ["props/metal_case.png"], "Weapon Case", 160),
    ((1165, 305, 1360, 540), ["props/hazard_barrel.png"], "Bio Barrel", 130),
    ((75, 536, 260, 775), ["props/fuel_barrel.png"], "Fuel Barrel", 130),
    ((315, 560, 675, 760), ["props/blast_barricade.png"], "Barricade", 185),
    ((720, 550, 1020, 760), ["props/chain_fence.png"], "Chain Fence", 190),
    ((1055, 575, 1425, 760), ["props/industrial_pipe.png"], "Pipe Arch", 195),
    ((395, 775, 580, 1068), ["props/street_lamp.png"], "Street Lamp", 195),
    ((730, 780, 1055, 1035), ["props/portal_gate.png"], "Portal Gate", 210),
]
for box, paths, lbl, mdim in prop_specs:
    spr = crop_tight_rgba(s7, box)
    save_sprite(spr, paths, lbl, max_dim=mdim)

# 7. SHEET -8: FLOOR TILES FOR ALL 5 BIOMES (128x128 SEAMLESS)
s8 = load_sheet(8)
tile_specs = [
    ((41, 39, 295, 275), ["tiles/concrete_clean.png", "tiles/lab_panel_clean.png"], "Tile: Steel Lab"),
    ((329, 39, 580, 275), ["tiles/cracked_concrete.png"], "Tile: Wasteland"),
    ((610, 37, 855, 274), ["tiles/mossy_concrete.png"], "Tile: Toxic Moss"),
    ((888, 40, 1134, 275), ["tiles/warning_stripes.png"], "Tile: Warning"),
    ((42, 305, 291, 535), ["tiles/metal_grate.png"], "Tile: Fire Grate"),
    ((328, 304, 580, 534), ["tiles/cryo_tile.png"], "Tile: Cryo Neon"),
    ((610, 304, 856, 534), ["tiles/rusted_plate.png"], "Tile: Rusted"),
    ((886, 305, 1137, 534), ["tiles/scorched_floor.png"], "Tile: Scorched"),
    ((43, 559, 294, 782), ["tiles/bolted_tile.png"], "Tile: City Slab"),
    ((328, 559, 580, 781), ["tiles/broken_stone.png"], "Tile: City Road"),
    ((609, 559, 856, 781), ["tiles/reactor_tile.png", "tiles/dark_slab.png"], "Tile: Reactor"),
    ((888, 558, 1136, 780), ["tiles/acid_pit_glow.png"], "Tile: Acid Pit"),
]
for box, paths, lbl in tile_specs:
    # Crop inner square away from rounded outer shadow so 128x128 tiles seamlessly
    x0, y0, x1, y1 = box
    inset = 10
    sub = s8.crop((x0 + inset, y0 + inset, x1 - inset, y1 - inset)).convert("RGB")
    tile_128 = sub.resize((128, 128), Image.Resampling.LANCZOS).convert("RGBA")
    # Add subtle 2px dark industrial bevel frame so grid tiles align cleanly
    t_arr = np.array(tile_128, dtype=np.float32)
    t_arr[0:2, :, :3] *= 0.82
    t_arr[-2:, :, :3] *= 0.76
    t_arr[:, 0:2, :3] *= 0.82
    t_arr[:, -2:, :3] *= 0.76
    tile_out = Image.fromarray(np.clip(t_arr, 0, 255).astype(np.uint8), "RGBA")
    save_sprite(tile_out, paths, lbl, max_dim=128)

# Build Contact Sheet for Visual Audit
cols = 8
rows = (len(saved_previews) + cols - 1) // cols
cell_w, cell_h = 170, 175
sheet_img = Image.new("RGBA", (cols * cell_w + 20, rows * cell_h + 20), (24, 34, 48, 255))
draw = ImageDraw.Draw(sheet_img)

for idx, (lbl, spr) in enumerate(saved_previews):
    r = idx // cols
    c = idx % cols
    cx = 10 + c * cell_w
    cy = 10 + r * cell_h
    draw.rectangle([cx + 3, cy + 3, cx + cell_w - 4, cy + cell_h - 4], fill=(38, 54, 72, 255), outline=(0, 210, 255, 180))
    thumb = spr.copy()
    thumb.thumbnail((cell_w - 20, cell_h - 36), Image.Resampling.LANCZOS)
    tx = cx + (cell_w - thumb.width) // 2
    ty = cy + 8 + (cell_h - 36 - thumb.height) // 2
    sheet_img.alpha_composite(thumb, (tx, ty))
    draw.text((cx + 8, cy + cell_h - 22), lbl[:20], fill=(220, 245, 255, 255))

sheet_img.save(ARTIFACT_SHEET)
print(f"Successfully sliced {len(saved_previews)} HD sprites and saved contact sheet to {ARTIFACT_SHEET}")
