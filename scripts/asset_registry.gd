extends Node
class_name AssetRegistry

## Centralny rejestr grafik HD (z pakietu 123.rar / 67676), 5 biomów, 10 bossów, 4 klas, NPC oraz ikon RPG.
## Jawnie oznacza status każdego assetu:
## - "HD_STATIC_RGBA": wyizolowany sprite HD w natywnym RGBA z arkuszy 123.rar (wymaga docelowego wieloklatkowego spritesheetu do pełnej animacji poklatkowej).
## - "ANIMATED_ATLAS": wieloklatkowy arkusz animacji (spritesheet).

const CH01_ROOT := "res://assets/mutantsurvivor_ch01/"
# Cached alpha-based enemy silhouette dimensions (graphics-only scale).
static var _enemy_visual_extents: Dictionary = {}

const CHARACTER_ASSETS := {
	"soldier": {
		"sheet_path": "",
		"fallback_path": CH01_ROOT + "characters/soldier_idle.png",
		"ref_path": CH01_ROOT + "characters/soldier_idle.png",
		"hframes": 1,
		"vframes": 1,
		"fps": 0.0,
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.54, 0.54)
	},
	"engineer": {
		"sheet_path": "",
		"fallback_path": CH01_ROOT + "characters/engineer_idle.png",
		"ref_path": CH01_ROOT + "characters/engineer_idle.png",
		"hframes": 1,
		"vframes": 1,
		"fps": 0.0,
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.54, 0.54)
	},
	"medic": {
		"sheet_path": "",
		"fallback_path": CH01_ROOT + "characters/medic_idle.png",
		"ref_path": CH01_ROOT + "characters/medic_idle.png",
		"hframes": 1,
		"vframes": 1,
		"fps": 0.0,
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.54, 0.54)
	},
	"scout": {
		"sheet_path": "",
		"fallback_path": CH01_ROOT + "characters/scout_idle.png",
		"ref_path": CH01_ROOT + "characters/scout_idle.png",
		"hframes": 1,
		"vframes": 1,
		"fps": 0.0,
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.54, 0.54)
	},
	"toxic_soldier": {
		"sheet_path": "",
		"fallback_path": CH01_ROOT + "characters/hazmat_trooper.png",
		"ref_path": CH01_ROOT + "characters/hazmat_trooper.png",
		"hframes": 1,
		"vframes": 1,
		"fps": 0.0,
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.54, 0.54)
	}
}

const NPC_PORTRAITS := {
	"Mara": CH01_ROOT + "characters/commander_mara.png",
	"Iwo": CH01_ROOT + "characters/engineer_idle.png",
	"Nina": CH01_ROOT + "characters/crimson_medic.png",
	"Kira": CH01_ROOT + "characters/void_sniper.png",
	"Ocalały": CH01_ROOT + "characters/soldier_idle.png"
}

const EQUIPMENT_SLOT_ICONS := {
	"weapon": "res://assets/ui/gear_slot/weapon.svg",
	"helmet": "res://assets/ui/gear_slot/helmet.svg",
	"chest": "res://assets/ui/gear_slot/chest.svg",
	"gloves": "res://assets/ui/gear_slot/gloves.svg",
	"boots": "res://assets/ui/gear_slot/boots.svg",
	"amulet": "res://assets/ui/gear_slot/amulet.svg"
}

const BOSS_CAMPAIGN_PORTRAITS := {
	"boss_ch01": "res://assets/ui/boss_campaign/boss_ch01.svg",
	"boss_ch02": "res://assets/ui/boss_campaign/boss_ch02.svg",
	"boss_ch03": "res://assets/ui/boss_campaign/boss_ch03.svg",
	"boss_ch04": "res://assets/ui/boss_campaign/boss_ch04.svg",
	"boss_ch05": "res://assets/ui/boss_campaign/boss_ch05.svg",
	"boss_ch06": "res://assets/ui/boss_campaign/boss_ch06.svg",
	"boss_ch07": "res://assets/ui/boss_campaign/boss_ch07.svg",
	"boss_ch08": "res://assets/ui/boss_campaign/boss_ch08.svg",
	"boss_ch09": "res://assets/ui/boss_campaign/boss_ch09.svg",
	"boss_ch10": "res://assets/ui/boss_campaign/boss_ch10.svg"
}

const SKIN_SPRITES := {
	"default": "",
	"gold_veteran": CH01_ROOT + "characters/wasteland_raider.png",
	"neon_hunter": CH01_ROOT + "characters/cyber_ronin.png",
	"crimson_storm": CH01_ROOT + "characters/crimson_medic.png",
	"hazmat_trooper": CH01_ROOT + "characters/hazmat_trooper.png",
	"void_sniper": CH01_ROOT + "characters/void_sniper.png"
}

const PLAYER_ANIMATION_COUNTS := {"idle": 4, "walk": 6, "shoot": 6, "hurt": 3, "death": 6}
# Animation imports may arrive as opaque white-matted PNGs. Extract only
# BORDER-CONNECTED near-white pixels, preserving isolated white highlights
# inside armor and weapons. Cache per original texture for all live enemies
# and the player; each imported frame is processed at most once.
static var _hero_alpha_cache: Dictionary = {}

static func _hero_frame_without_white_matte(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var key: String = tex.resource_path
	if key.is_empty():
		key = str(tex.get_instance_id())
	if _hero_alpha_cache.has(key):
		return _hero_alpha_cache[key]
	var source: Image = tex.get_image()
	if source == null or source.is_empty():
		return tex
	var width: int = source.get_width()
	var height: int = source.get_height()
	if width < 4 or height < 4:
		return tex

	# Existing art imports include an off-white/blue studio background.
	# The old algorithm returned the original PNG whenever just two
	# CORNERS were not pure white. Detect the surrounding matte from
	# the whole border and flood-fill only background-connected pixels.
	var image: Image = source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	var border_samples: int = 0
	var matte_samples: int = 0
	for x in range(0, width, maxi(1, int(width / 32))):
		for y in [0, height - 1]:
			border_samples += 1
			if _is_light_character_matte(image.get_pixel(x, y)):
				matte_samples += 1
	for y in range(0, height, maxi(1, int(height / 32))):
		for x in [0, width - 1]:
			border_samples += 1
			if _is_light_character_matte(image.get_pixel(x, y)):
				matte_samples += 1
	if float(matte_samples) / float(maxi(1, border_samples)) < 0.32:
		_hero_alpha_cache[key] = tex
		return tex

	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in range(width):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, height - 1))
	for y in range(1, height - 1):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(width - 1, y))
	var front: int = 0
	var erased: int = 0
	while front < queue.size():
		var pos: Vector2i = queue[front]
		front += 1
		var index: int = pos.y * width + pos.x
		if visited[index] != 0:
			continue
		visited[index] = 1
		var c: Color = image.get_pixelv(pos)
		if not _is_light_character_matte(c):
			continue
		c.a = 0.0
		image.set_pixelv(pos, c)
		erased += 1
		if pos.x > 0:
			queue.append(Vector2i(pos.x - 1, pos.y))
		if pos.x + 1 < width:
			queue.append(Vector2i(pos.x + 1, pos.y))
		if pos.y > 0:
			queue.append(Vector2i(pos.x, pos.y - 1))
		if pos.y + 1 < height:
			queue.append(Vector2i(pos.x, pos.y + 1))
	# Guard against accidental removal of a mostly pale character frame.
	if erased < width * height / 8 or erased > width * height * 9 / 10:
		_hero_alpha_cache[key] = tex
		return tex
	var result: Texture2D = ImageTexture.create_from_image(image)
	_hero_alpha_cache[key] = result
	return result


static func _is_light_character_matte(c: Color) -> bool:
	if c.a < 0.90:
		return false
	# The actual white card around the engineer is pale blue-gray, not
	# RGB(255,255,255). Limit removal to neutral/light backgrounds.
	var lowest: float = minf(c.r, minf(c.g, c.b))
	var highest: float = maxf(c.r, maxf(c.g, c.b))
	return lowest > 0.70 and highest - lowest < 0.25


const PLAYER_ANIMATED_CLASSES := ["soldier", "engineer", "medic", "scout", "toxic_soldier"]

static func get_player_animation_frame(class_id: String, action: String, frame: int) -> Texture2D:
	if not PLAYER_ANIMATION_COUNTS.has(action) or frame < 1 or frame > int(PLAYER_ANIMATION_COUNTS[action]):
		return null
	if PLAYER_ANIMATED_CLASSES.has(class_id):
		var production_path := "res://assets/characters/%s/%s_%d.png" % [class_id, action, frame]
		var prod_frame: Texture2D = get_tex(production_path)
		if prod_frame != null:
			return _hero_frame_without_white_matte(prod_frame)
	return _hero_frame_without_white_matte(get_tex(CH01_ROOT + "characters/%s_%s_%d.png" % [class_id, action, frame]))


static func get_hero_skin_sprite(class_id: String, skin_id: String) -> String:
	var skin_path := String(SKIN_SPRITES.get(skin_id, ""))
	if not skin_path.is_empty() and ResourceLoader.exists(skin_path):
		return skin_path
	var spec: Dictionary = CHARACTER_ASSETS.get(class_id, CHARACTER_ASSETS["soldier"])
	return String(spec.get("ref_path", CH01_ROOT + "characters/soldier_idle.png"))

static func get_item_icon_path(item: Dictionary) -> String:
	if item.is_empty():
		return EQUIPMENT_SLOT_ICONS["weapon"]
	var slot := String(item.get("slot", "weapon"))
	var tpl_id := String(item.get("id", item.get("template_id", item.get("name", ""))))
	var h := absi(tpl_id.hash())
	match slot:
		"weapon":
			var w_idx := 1 + (h % 12)
			return CH01_ROOT + "weapons/weapon_%d.png" % w_idx
		"helmet":
			var h_icons := [
				CH01_ROOT + "icons/drone_cpu.png",
				CH01_ROOT + "icons/shield_orb.png"
			]
			return h_icons[h % h_icons.size()]
		"chest":
			var c_icons := [
				CH01_ROOT + "icons/skill_shield.png",
				CH01_ROOT + "icons/medkit.png",
				CH01_ROOT + "icons/shield_orb.png"
			]
			return c_icons[h % c_icons.size()]
		"gloves":
			var g_icons := [
				CH01_ROOT + "icons/skill_crit.png",
				CH01_ROOT + "weapons/weapon_10.png"
			]
			return g_icons[h % g_icons.size()]
		"boots":
			var b_icons := [
				CH01_ROOT + "icons/energy_cell.png",
				CH01_ROOT + "icons/keycard_icon.png"
			]
			return b_icons[h % b_icons.size()]
		"amulet":
			var a_icons := [
				CH01_ROOT + "icons/dna_tablet.png",
				CH01_ROOT + "icons/purple_crystal.png",
				CH01_ROOT + "icons/star_badge.png",
				CH01_ROOT + "icons/data_chip.png"
			]
			return a_icons[h % a_icons.size()]
	return String(EQUIPMENT_SLOT_ICONS.get(slot, EQUIPMENT_SLOT_ICONS["weapon"]))

const BIOME_PALETTES := {
	"wasteland": {
		"name": "Pustkowia Poza Kompleksem",
		"tiles": ["cracked_concrete", "concrete_clean", "rusted_plate", "scorched_floor"],
		"border_tile": "warning_stripes",
		"ambient_tint": Color(1.0, 0.97, 0.92, 1.0),
		"props": ["bunker_a01", "blast_barricade", "chain_fence", "supply_crate", "satellite_dish", "fuel_barrel", "hazard_barrel"]
	},
	"cryo_lab": {
		"name": "Laboratorium Kriogeniczne",
		"tiles": ["cryo_tile", "concrete_clean", "bolted_tile", "cryo_tile"],
		"border_tile": "warning_stripes",
		"ambient_tint": Color(0.86, 0.96, 1.05, 1.0),
		"props": ["tall_cryo_tube", "computer_console", "bunker_a01", "metal_case", "industrial_pipe", "portal_gate"]
	},
	"toxic_sewers": {
		"name": "Toksyczne Kanały",
		"tiles": ["mossy_concrete", "acid_pit_glow", "rusted_plate", "metal_grate"],
		"border_tile": "warning_stripes",
		"ambient_tint": Color(0.90, 1.04, 0.88, 1.0),
		"props": ["mutation_tank", "industrial_pipe", "hazard_barrel", "chain_fence", "supply_crate"]
	},
	"abandoned_city": {
		"name": "Opuszczony Sektor Miejski",
		"tiles": ["broken_stone", "scorched_floor", "bolted_tile", "cracked_concrete"],
		"border_tile": "warning_stripes",
		"ambient_tint": Color(0.96, 0.93, 0.98, 1.0),
		"props": ["blast_barricade", "chain_fence", "street_lamp", "supply_crate", "fuel_barrel", "satellite_dish"]
	},
	"reactor": {
		"name": "Rdzeń Obcego Reaktora",
		"tiles": ["reactor_tile", "cryo_tile", "metal_grate", "reactor_tile"],
		"border_tile": "warning_stripes",
		"ambient_tint": Color(0.98, 0.88, 1.08, 1.0),
		"props": ["portal_gate", "tall_cryo_tube", "mutation_tank", "computer_console", "bunker_a01"]
	}
}

const ENEMY_ASSETS := {
	"biegacz": {
		"display_name": "Skażony Ogar (Toxic Hound)",
		"texture_path": CH01_ROOT + "enemies/hound_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.52, 0.52)
	},
	"zracy_pelzacz": {
		"display_name": "Żrący Chrząszcz (Acid Beetle)",
		"texture_path": CH01_ROOT + "enemies/beetle_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.52, 0.52)
	},
	"zdziczaly": {
		"display_name": "Zdziczały Brutal (Heavy Brute)",
		"texture_path": CH01_ROOT + "enemies/brute_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.58, 0.58)
	},
	"zarazony": {
		"display_name": "Zakażony Biegacz (Feral Runner)",
		"texture_path": CH01_ROOT + "enemies/infected_human_variant.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.52, 0.52)
	},
	"plujacy_kwasem": {
		"display_name": "Plujący Mutant (Acid Spitter)",
		"texture_path": CH01_ROOT + "enemies/spitter_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.54, 0.54)
	},
	"lowca": {
		"display_name": "Kosiarz Cienia (Claw Stalker)",
		"texture_path": CH01_ROOT + "enemies/stalker_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.54, 0.54)
	},
	"skrzydlaty": {
		"display_name": "Skrzydlaty Pomiot (Mutant Bat)",
		"texture_path": CH01_ROOT + "enemies/winged_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.52, 0.52)
	},
	"czerw": {
		"display_name": "Toksyczny Czerw (Toxic Larva)",
		"texture_path": CH01_ROOT + "enemies/larva_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.52, 0.52)
	},
	"miniboss_ch01": {
		"display_name": "Elitarny Niszczyciel",
		"texture_path": CH01_ROOT + "enemies/elite_brute_idle_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.72, 0.72)
	},
	"matka_roju": {
		"display_name": "Matka Roju (Boss Rozdziału 1)",
		"texture_path": CH01_ROOT + "bosses/hive_mother_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.82, 0.82)
	},
	"boss_ch01": {
		"display_name": "Matka Roju",
		"texture_path": CH01_ROOT + "bosses/hive_mother_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.82, 0.82)
	},
	"boss_ch02": {
		"display_name": "Nadzorca Skażenia",
		"texture_path": CH01_ROOT + "bosses/behemoth_boss_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.84, 0.84)
	},
	"boss_ch03": {
		"display_name": "Król Kriostazy",
		"texture_path": CH01_ROOT + "bosses/cryo_king_boss.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.86, 0.86)
	},
	"boss_ch04": {
		"display_name": "Doktor Szron",
		"texture_path": CH01_ROOT + "bosses/cryo_king_boss.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.86, 0.86)
	},
	"boss_ch05": {
		"display_name": "Lewiatan Kwaśny",
		"texture_path": CH01_ROOT + "bosses/hive_mother_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.86, 0.86)
	},
	"boss_ch06": {
		"display_name": "Serce Zarazy",
		"texture_path": CH01_ROOT + "bosses/hive_mother_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.88, 0.88)
	},
	"boss_ch07": {
		"display_name": "Król Martwego Miasta",
		"texture_path": CH01_ROOT + "bosses/behemoth_boss_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.88, 0.88)
	},
	"boss_ch08": {
		"display_name": "Egzekutor Omega",
		"texture_path": CH01_ROOT + "bosses/behemoth_boss_reference.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.90, 0.90)
	},
	"boss_ch09": {
		"display_name": "Strażnik Rdzenia",
		"texture_path": CH01_ROOT + "bosses/architect_zero_boss.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.88, 0.88)
	},
	"boss_ch10": {
		"display_name": "Architekt Zero",
		"texture_path": CH01_ROOT + "bosses/architect_zero_boss.png",
		"status": "HD_STATIC_RGBA",
		"scale": Vector2(0.94, 0.94)
	}
}

const PROP_ASSETS := {
	"bunker_a01": {"path": CH01_ROOT + "props/bunker_a01.png", "solid": true, "collision": Vector2(160, 95), "offset": Vector2(0, 22), "status": "HD_STATIC_RGBA"},
	"tall_cryo_tube": {"path": CH01_ROOT + "props/tall_cryo_tube.png", "solid": true, "collision": Vector2(68, 56), "offset": Vector2(0, 48), "status": "HD_STATIC_RGBA", "glow_color": Color(0.2, 0.95, 1.0, 0.8)},
	"mutation_tank": {"path": CH01_ROOT + "props/mutation_tank.png", "solid": true, "collision": Vector2(64, 52), "offset": Vector2(0, 38), "status": "HD_STATIC_RGBA", "glow_color": Color(0.2, 1.0, 0.35, 0.7)},
	"computer_console": {"path": CH01_ROOT + "props/computer_console.png", "solid": true, "collision": Vector2(88, 54), "offset": Vector2(0, 24), "status": "HD_STATIC_RGBA", "glow_color": Color(0.15, 0.8, 1.0, 0.65)},
	"supply_crate": {"path": CH01_ROOT + "props/supply_crate.png", "solid": true, "collision": Vector2(64, 46), "offset": Vector2(0, 14), "status": "HD_STATIC_RGBA"},
	"metal_case": {"path": CH01_ROOT + "props/metal_case.png", "solid": true, "collision": Vector2(64, 46), "offset": Vector2(0, 14), "status": "HD_STATIC_RGBA"},
	"chain_fence": {"path": CH01_ROOT + "props/chain_fence.png", "solid": true, "collision": Vector2(110, 32), "offset": Vector2(0, 18), "status": "HD_STATIC_RGBA"},
	"blast_barricade": {"path": CH01_ROOT + "props/blast_barricade.png", "solid": true, "collision": Vector2(96, 40), "offset": Vector2(0, 16), "status": "HD_STATIC_RGBA"},
	"satellite_dish": {"path": CH01_ROOT + "props/satellite_dish.png", "solid": true, "collision": Vector2(72, 54), "offset": Vector2(0, 20), "status": "HD_STATIC_RGBA"},
	"industrial_pipe": {"path": CH01_ROOT + "props/industrial_pipe.png", "solid": true, "collision": Vector2(76, 48), "offset": Vector2(0, 16), "status": "HD_STATIC_RGBA"},
	"portal_gate": {"path": CH01_ROOT + "props/portal_gate.png", "solid": true, "collision": Vector2(88, 52), "offset": Vector2(0, 20), "status": "HD_STATIC_RGBA", "glow_color": Color(0.25, 0.82, 1.0, 0.85)},
	"street_lamp": {"path": CH01_ROOT + "props/street_lamp.png", "solid": false, "collision": Vector2.ZERO, "offset": Vector2.ZERO, "status": "HD_STATIC_RGBA", "glow_color": Color(1.0, 0.78, 0.35, 0.75)},
	"fuel_barrel": {"path": CH01_ROOT + "props/fuel_barrel.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_STATIC_RGBA"},
	"hazard_barrel": {"path": CH01_ROOT + "props/hazard_barrel.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_STATIC_RGBA"},
	"prop_wreck_sedan": {"path": "res://assets/environment/props/prop_wreck_sedan.png", "solid": true, "collision": Vector2(120, 60), "offset": Vector2(0, 15), "status": "HD_PROP_V2"},
	"prop_wreck_suv": {"path": "res://assets/environment/props/prop_wreck_suv.png", "solid": true, "collision": Vector2(130, 65), "offset": Vector2(0, 15), "status": "HD_PROP_V2"},
	"prop_wreck_pickup": {"path": "res://assets/environment/props/prop_wreck_pickup.png", "solid": true, "collision": Vector2(125, 60), "offset": Vector2(0, 15), "status": "HD_PROP_V2"},
	"prop_wreck_tanker": {"path": "res://assets/environment/props/prop_wreck_tanker.png", "solid": true, "collision": Vector2(160, 75), "offset": Vector2(0, 20), "status": "HD_PROP_V2"},
	"prop_barrier_hazard": {"path": "res://assets/environment/props/prop_barrier_hazard.png", "solid": true, "collision": Vector2(90, 40), "offset": Vector2(0, 12), "status": "HD_PROP_V2"},
	"prop_sandbags": {"path": "res://assets/environment/props/prop_sandbags.png", "solid": true, "collision": Vector2(90, 36), "offset": Vector2(0, 10), "status": "HD_PROP_V2"},
	"prop_concrete_block": {"path": "res://assets/environment/props/prop_concrete_block.png", "solid": true, "collision": Vector2(80, 44), "offset": Vector2(0, 12), "status": "HD_PROP_V2"},
	"prop_crate_military": {"path": "res://assets/environment/props/prop_crate_military.png", "solid": true, "collision": Vector2(64, 48), "offset": Vector2(0, 12), "status": "HD_PROP_V2"},
	"prop_barrel_oil": {"path": "res://assets/environment/props/prop_barrel_oil.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_PROP_V2"},
	"prop_barrel_toxic": {"path": "res://assets/environment/props/prop_barrel_toxic.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_PROP_V2"},
	"prop_pipes_industrial": {"path": "res://assets/environment/props/prop_pipes_industrial.png", "solid": true, "collision": Vector2(85, 48), "offset": Vector2(0, 14), "status": "HD_PROP_V2"},
	"prop_tank_boiler": {"path": "res://assets/environment/props/prop_tank_boiler.png", "solid": true, "collision": Vector2(100, 64), "offset": Vector2(0, 18), "status": "HD_PROP_V2"},
	"prop_flag_biohazard_red": {"path": "res://assets/environment/props/prop_flag_biohazard_red.png", "solid": false, "collision": Vector2.ZERO, "offset": Vector2.ZERO, "status": "HD_PROP_V2"},
	"prop_flag_biohazard_yellow": {"path": "res://assets/environment/props/prop_flag_biohazard_yellow.png", "solid": false, "collision": Vector2.ZERO, "offset": Vector2.ZERO, "status": "HD_PROP_V2"}
}

static var _tex_cache: Dictionary = {}

static func get_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _tex_cache.has(path):
		return _tex_cache[path]
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		_tex_cache[path] = t
		return t
	return null

static func apply_player_visual(sprite: Sprite2D, class_id: String, skin_id: String = "") -> void:
	if not is_instance_valid(sprite):
		return
	var spec: Dictionary = CHARACTER_ASSETS.get(class_id, CHARACTER_ASSETS["soldier"])
	var p := get_hero_skin_sprite(class_id, skin_id)
	if not ResourceLoader.exists(p):
		p = CH01_ROOT + "characters/soldier_idle.png"
	var tex := get_tex(p)
	if tex != null:
		sprite.texture = tex
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.scale = spec.get("scale", Vector2(0.54, 0.54))

const MUTANT_ANIM_FOLDERS := {
	"biegacz": "mutant_stalker", "plujacy_kwasem": "mutant_spitter",
	"lowca": "mutant_leaper", "zarazony": "mutant_viral",
	"zdziczaly": "mutant_tank", "zracy_pelzacz": "mutant_armored",
	"skrzydlaty": "mutant_gargoyle", "wybuchowy": "mutant_boomer",
	"czerw": "mutant_worm"
}
const BOSS_ANIM_FOLDERS := {
	"boss_ch01": "boss_matka_roju", "matka_roju": "boss_matka_roju",
	"boss_ch02": "boss_goliat", "miniboss_ch01": "boss_goliat", "boss_goliat": "boss_goliat",
	"boss_ch03": "boss_lewiatan", "boss_ch04": "boss_lewiatan", "boss_lewiatan": "boss_lewiatan"
}
# Six distinct generated concepts are distributed as an optional verified art pack.
# Until its PNG files have been copied and imported, use existing HD boss frames.
const BOSS_CHAPTER_FALLBACK_KITS := {
	"boss_ch01": "boss_matka_roju",
	"boss_ch02": "boss_goliat",
	"boss_ch03": "boss_lewiatan",
	"boss_ch04": "boss_lewiatan",
	"miniboss_ch01": "boss_goliat",
	"matka_roju": "boss_matka_roju",
	"boss_ch05": "boss_lewiatan",
	"boss_ch06": "boss_matka_roju",
	"boss_ch07": "boss_goliat",
	"boss_ch08": "boss_goliat",
	"boss_ch09": "boss_lewiatan",
	"boss_ch10": "boss_matka_roju"
}

static func get_candidate_boss_directory(boss_id: String) -> String:
	if not BOSS_CHAPTER_FALLBACK_KITS.has(boss_id):
		return ""
	return "res://assets/bosses/" + boss_id + "/"

static func has_complete_chapter_boss_art(boss_id: String) -> bool:
	var root_path: String = get_candidate_boss_directory(boss_id)
	if root_path.is_empty():
		return false
	if not ResourceLoader.exists(root_path + "boss_portrait.png", "Texture2D"):
		return false
	for frame in range(1, 5):
		if not ResourceLoader.exists(root_path + "phase1_anim_%d.png" % frame, "Texture2D"):
			return false
		if not ResourceLoader.exists(root_path + "phase2_attack_%d.png" % frame, "Texture2D"):
			return false
	for frame in range(1, 3):
		if not ResourceLoader.exists(root_path + "death_%d.png" % frame, "Texture2D"):
			return false
	return true

static func get_campaign_boss_portrait(boss_id: String) -> String:
	if has_complete_chapter_boss_art(boss_id):
		return get_candidate_boss_directory(boss_id) + "boss_portrait.png"
	return String(BOSS_CAMPAIGN_PORTRAITS.get(boss_id, ""))

static func enemy_frame_scale(tex: Texture2D, enemy_id: String) -> Vector2:
	if tex == null:
		return Vector2.ONE
	# Use the SAME scale target for every walk/attack/death frame.
	# The actual visible silhouette is measured per frame and cached.
	var cache_key: String = tex.resource_path
	if cache_key.is_empty():
		cache_key = str(tex.get_instance_id())
	var extent: float = float(maxi(tex.get_width(), tex.get_height()))
	if _enemy_visual_extents.has(cache_key):
		extent = float(_enemy_visual_extents[cache_key])
	else:
		var image_data: Image = tex.get_image()
		if image_data != null and not image_data.is_empty():
			var used: Rect2i = image_data.get_used_rect()
			if used.size.x > 8 and used.size.y > 8:
				extent = float(maxi(used.size.x, used.size.y))
		_enemy_visual_extents[cache_key] = extent
	var is_boss: bool = BOSS_ANIM_FOLDERS.has(enemy_id) or BOSS_CHAPTER_FALLBACK_KITS.has(enemy_id)
	var is_large: bool = enemy_id in ["zdziczaly", "miniboss_ch01", "matka_roju"]
	var target_extent: float = 282.0 if is_boss else (205.0 if is_large else 156.0)
	var normalized: float = clampf(target_extent / maxf(1.0, extent), 0.35, 4.40)
	return Vector2(normalized, normalized)


static func apply_enemy_visual(sprite: Sprite2D, enemy_id: String) -> Dictionary:
	var spec: Dictionary = {}
	var walk_frames: Array[Texture2D] = []
	var attack_frames: Array[Texture2D] = []
	var death_frames: Array[Texture2D] = []

	# Complete optional boss folders override the legacy sprite families.
	# A missing/partially copied chapter pack MUST NOT crash the game.
	if BOSS_ANIM_FOLDERS.has(enemy_id) or BOSS_CHAPTER_FALLBACK_KITS.has(enemy_id):
		var candidate_ready: bool = has_complete_chapter_boss_art(enemy_id)
		var folder: String = String(BOSS_ANIM_FOLDERS.get(enemy_id, BOSS_CHAPTER_FALLBACK_KITS.get(enemy_id, "boss_goliat")))
		var root_path: String = get_candidate_boss_directory(enemy_id) if candidate_ready else "res://assets/bosses/" + folder + "/"
		# Audit proved legacy animation PNGs are fragmented slices of larger
		# portraits; do not animate broken body parts during gameplay.
		# Optional 11-frame chapter packs restore animation when fully imported.
		if candidate_ready:
			for idx in range(1, 5):
				var w: Texture2D = get_tex(root_path + "phase1_anim_%d.png" % idx)
				var a: Texture2D = get_tex(root_path + "phase2_attack_%d.png" % idx)
				if w != null: walk_frames.append(w)
				if a != null: attack_frames.append(a)
			for idx in range(1, 3):
				var d: Texture2D = get_tex(root_path + "death_%d.png" % idx)
				if d != null: death_frames.append(d)
		spec = {
			"texture_path": root_path + "boss_portrait.png",
			"scale": Vector2(1.0, 1.0),
			"status": "BOSS_ART_CANDIDATE" if candidate_ready else "BOSS_STATIC_SAFE"
		}
	else:
		var mutant_id: String = enemy_id
		var aliases := {"stalker":"biegacz","spitter":"plujacy_kwasem","leaper":"lowca","viral":"zarazony","tank":"zdziczaly","boomer":"wybuchowy","pancerny":"zracy_pelzacz","beetle":"zracy_pelzacz","gargoyle":"skrzydlaty"}
		if aliases.has(mutant_id):
			mutant_id = String(aliases[mutant_id])
		var folder: String = String(MUTANT_ANIM_FOLDERS.get(mutant_id, ""))
		if not folder.is_empty():
			var root_path := "res://assets/enemies/" + folder + "/"
			for idx in range(1, 5):
				var w: Texture2D = get_tex(root_path + "walk_%d.png" % idx)
				var a: Texture2D = get_tex(root_path + "attack_%d.png" % idx)
				if w != null: walk_frames.append(w)
				if a != null: attack_frames.append(a)
			spec = {"texture_path": root_path + "portrait.png", "scale": Vector2(0.60, 0.60), "status": "HD_MUTANT_V2"}
		elif ENEMY_ASSETS.has(enemy_id):
			spec = ENEMY_ASSETS[enemy_id]
		else:
			spec = ENEMY_ASSETS["biegacz"]

	var tex := get_tex(String(spec.get("texture_path", "")))
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.texture = walk_frames[0] if not walk_frames.is_empty() else tex
	sprite.scale = spec.get("scale", Vector2(0.54, 0.54))
	# Normalize based on the visible body, not the PNG canvas.
	sprite.scale = enemy_frame_scale(sprite.texture, enemy_id)
	return {
		"is_animated": (walk_frames.size() > 0),
		"fps": 8.0,
		"walk_frames": walk_frames,
		"attack_frames": attack_frames,
		"death_frames": death_frames,
		"status": String(spec.get("status", "HD_STATIC_RGBA")),
		"base_scale": sprite.scale
	}
