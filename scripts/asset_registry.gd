extends Node
class_name AssetRegistry

## Centralny rejestr grafik HD (z pakietu 123.rar / 67676), 5 biomów, 10 bossów, 4 klas, NPC oraz ikon RPG.
## Jawnie oznacza status każdego assetu:
## - "HD_STATIC_RGBA": wyizolowany sprite HD w natywnym RGBA z arkuszy 123.rar (wymaga docelowego wieloklatkowego spritesheetu do pełnej animacji poklatkowej).
## - "ANIMATED_ATLAS": wieloklatkowy arkusz animacji (spritesheet).

const CH01_ROOT := "res://assets/mutantsurvivor_ch01/"

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
const PLAYER_ANIMATED_CLASSES := ["soldier", "engineer", "medic", "scout"]

static func get_player_animation_frame(class_id: String, action: String, frame: int) -> Texture2D:
	if not PLAYER_ANIMATION_COUNTS.has(action) or frame < 1 or frame > int(PLAYER_ANIMATION_COUNTS[action]):
		return null
	if PLAYER_ANIMATED_CLASSES.has(class_id):
		var production_path := "res://assets/characters/%s/%s_%d.png" % [class_id, action, frame]
		var prod_frame: Texture2D = get_tex(production_path)
		if prod_frame != null:
			return prod_frame
	return get_tex(CH01_ROOT + "characters/%s_%s_%d.png" % [class_id, action, frame])


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

static func apply_enemy_visual(sprite: Sprite2D, enemy_id: String) -> Dictionary:
	var spec: Dictionary = {}
	var walk_frames: Array[Texture2D] = []
	var attack_frames: Array[Texture2D] = []
	var death_frames: Array[Texture2D] = []

	# Boss Multi-Phase Sprites
	if enemy_id in ["boss_ch01", "matka_roju"]:
		var b_path := "res://assets/bosses/boss_matka_roju/"
		for fi in range(1, 5):
			var w := get_tex(b_path + "phase1_anim_%d.png" % fi)
			var a := get_tex(b_path + "phase2_attack_%d.png" % fi)
			if w: walk_frames.append(w)
			if a: attack_frames.append(a)
		for di in range(1, 3):
			var d := get_tex(b_path + "death_%d.png" % di)
			if d: death_frames.append(d)
		spec = {"texture_path": b_path + "boss_portrait.png", "scale": Vector2(0.88, 0.88), "status": "HD_BOSS_V2"}
	elif enemy_id in ["boss_ch02", "miniboss_ch01", "boss_goliat"]:
		var b_path := "res://assets/bosses/boss_goliat/"
		for fi in range(1, 5):
			var w := get_tex(b_path + "phase1_anim_%d.png" % fi)
			var a := get_tex(b_path + "phase2_attack_%d.png" % fi)
			if w: walk_frames.append(w)
			if a: attack_frames.append(a)
		for di in range(1, 3):
			var d := get_tex(b_path + "death_%d.png" % di)
			if d: death_frames.append(d)
		spec = {"texture_path": b_path + "boss_portrait.png", "scale": Vector2(0.88, 0.88), "status": "HD_BOSS_V2"}
	elif enemy_id in ["boss_ch03", "boss_ch04", "boss_lewiatan"]:
		var b_path := "res://assets/bosses/boss_lewiatan/"
		for fi in range(1, 5):
			var w := get_tex(b_path + "phase1_anim_%d.png" % fi)
			var a := get_tex(b_path + "phase2_attack_%d.png" % fi)
			if w: walk_frames.append(w)
			if a: attack_frames.append(a)
		for di in range(1, 3):
			var d := get_tex(b_path + "death_%d.png" % di)
			if d: death_frames.append(d)
		spec = {"texture_path": b_path + "boss_portrait.png", "scale": Vector2(0.88, 0.88), "status": "HD_BOSS_V2"}
	else:
		# 8 Mutant Enemy Types
		var mutant_folder := ""
		if enemy_id in ["biegacz", "stalker"]: mutant_folder = "mutant_stalker"
		elif enemy_id in ["plujacy_kwasem", "spitter"]: mutant_folder = "mutant_spitter"
		elif enemy_id in ["lowca", "leaper"]: mutant_folder = "mutant_leaper"
		elif enemy_id in ["zarazony", "viral"]: mutant_folder = "mutant_viral"
		elif enemy_id in ["zdziczaly", "tank"]: mutant_folder = "mutant_tank"
		elif enemy_id in ["wybuchowy", "boomer"]: mutant_folder = "mutant_boomer"
		elif enemy_id in ["zracy_pelzacz", "pancerny", "beetle"]: mutant_folder = "mutant_armored"
		elif enemy_id in ["skrzydlaty", "gargoyle"]: mutant_folder = "mutant_gargoyle"

		if mutant_folder != "":
			var m_path := "res://assets/enemies/" + mutant_folder + "/"
			for fi in range(1, 5):
				var w := get_tex(m_path + "walk_%d.png" % fi)
				var a := get_tex(m_path + "attack_%d.png" % fi)
				if w: walk_frames.append(w)
				if a: attack_frames.append(a)
			spec = {"texture_path": m_path + "portrait.png", "scale": Vector2(0.60, 0.60), "status": "HD_MUTANT_V2"}
		elif ENEMY_ASSETS.has(enemy_id):
			spec = ENEMY_ASSETS[enemy_id]
		else:
			spec = ENEMY_ASSETS["biegacz"]

	var tex := get_tex(String(spec.get("texture_path", "")))
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.texture = tex
	sprite.scale = spec.get("scale", Vector2(0.54, 0.54))
	return {
		"is_animated": (walk_frames.size() > 0),
		"fps": 8.0,
		"walk_frames": walk_frames,
		"attack_frames": attack_frames,
		"death_frames": death_frames,
		"status": String(spec.get("status", "HD_STATIC_RGBA")),
		"base_scale": sprite.scale
	}
