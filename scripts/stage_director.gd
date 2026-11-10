extends Node

## StageDirector — Centralny menedżer kampanii 1-100, RPG (6 slotów ekwipunku + afiksy),
## prób kampanii (5/5 + darmowy trening), 5 biomów, dialogów NPC, codziennych nagród i orientacji ekranu (9:16 / 16:9).
## Zachowuje pełną kompatybilność wsteczną z dotychczasowymi zapisami (`user://mutant_campaign_save.json`).

signal orientation_changed(is_portrait: bool)
signal profile_data_changed()

const STAGES_JSON_PATH := "res://gamedesign/etapy_001_100.json"
const DIFFICULTY_JSON_PATH := "res://gamedesign/PROFILE_TRUDNOSCI.json"
const V1_DATA_DIR := "res://mutant_v1/data/"
const DEFAULT_SAVE_PATH := "user://mutant_campaign_save.json"
# Public-release safety: do not grant temporary closed-beta currency.
# _grant_beta_test_gems_once() also revokes tracked unspent beta currency
# and test-funded cosmetics when migrating an existing beta save.
const BETA_TEST_GEMS_ENABLED: bool = false
const BETA_TEST_GEMS_AMOUNT: int = 10000

static var save_path_override: String = ""

var content_db: MutantV1ContentDB = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var stages_data: Array = []
var difficulty_profiles: Array = []
var v2_missions: Dictionary = {} # stage_num (int) -> Dictionary
var v2_bosses: Dictionary = {}   # id (String) -> Dictionary
var v2_mutators: Dictionary = {} # stage_num (int) -> Array
var v2_contracts: Dictionary = {} # stage_num (int) -> Dictionary
var v2_dialogues: Dictionary = {} # stage_num (int) -> Dictionary

# Tryb orientacji: "auto", "portrait" (9:16 Android/iOS), "landscape" (16:9 PC)
var orientation_mode: String = "portrait"

# Stan kampanii i profilu gracza (zapisywany w pliku)
var current_stage: int = 1
var max_unlocked_stage: int = 1
var selected_difficulty_id: String = "ocalaly"
var selected_class_id: String = "soldier"
var selected_skin_id: String = "default"
var character_level: int = 1
var character_xp: int = 0
var credits: int = 350
var dark_matter_gems: int = 0
var beta_test_gems_granted: bool = false
var beta_test_gems_remaining: int = 0
var beta_test_skins_purchased: Array = []
var scrap_materials: int = 12
var cleared_stages: Dictionary = {} # stage_num (String) -> best_stars (int)
var first_clears_v2: Dictionary = {} # mission_id (String) -> bool
var pity_chest_counter: int = 0
var wave_duration_sec: float = 65.0 # 10 fal * 65s = ~11 minut na pełny etap

# Rozwój niezależny per klasa (zgodny z data/class_progression_contract.json)
var class_progression: Dictionary = {
	"soldier": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}},
	"engineer": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}},
	"medic": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}},
	"scout": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}}
}

# System Prób Kampanii (5/5, regeneracja 1 co 30 min + darmowy tryb treningowy)
var attempts: int = 5
var next_attempt_at: int = 0
var is_practice_mode: bool = false

# Ekwipunek RPG (6 slotów: weapon, helmet, chest, gloves, boots, amulet)
const GEAR_SLOTS := ["weapon", "helmet", "chest", "gloves", "boots", "amulet"]
const GEAR_SLOT_NAMES := {
	"weapon": "Broń",
	"helmet": "Hełm",
	"chest": "Pancerz",
	"gloves": "Rękawice",
	"boots": "Buty",
	"amulet": "Artefakt"
}
const RARITY_COLORS := {
	"common": Color(0.75, 0.80, 0.86),
	"rare": Color(0.25, 0.72, 1.0),
	"epic": Color(0.75, 0.38, 1.0),
	"legendary": Color(1.0, 0.72, 0.18),
	"mythic": Color(1.0, 0.28, 0.42)
}
const RARITY_NAMES := {
	"common": "Zwykła",
	"rare": "Rzadka",
	"epic": "Epicka",
	"legendary": "Legendarna",
	"mythic": "Mityczna"
}
const RARITY_ORDER := {
	"common": 1,
	"rare": 2,
	"epic": 3,
	"legendary": 4,
	"mythic": 5
}

const HERO_SKINS := {
	"default": {"name": "Pancerz A-03", "tint": Color(1.0, 1.0, 1.0, 1.0), "bonus": "Bazowy pancerz operatora"},
	"gold_veteran": {"name": "Weteran Pustkowi", "tint": Color(1.08, 1.02, 0.90, 1.0), "bonus": "Ilustracja HD: Weteran Pustkowi"},
	"neon_hunter": {"name": "Cyber Ronin X-9", "tint": Color(0.92, 1.06, 1.12, 1.0), "bonus": "Ilustracja HD: Cyber Ronin"},
	"crimson_storm": {"name": "Karmazynowy Medyk", "tint": Color(1.08, 0.92, 0.95, 1.0), "bonus": "Ilustracja HD: Karmazynowy Korpus"},
	"hazmat_trooper": {"name": "Bio-Hazmat", "tint": Color(0.95, 1.08, 0.92, 1.0), "bonus": "Ilustracja HD: Oddział Skażeń"},
	"void_sniper": {"name": "Snajper Otchłani", "tint": Color(0.96, 0.92, 1.10, 1.0), "bonus": "Ilustracja HD: Zwiadowca Otchłani"}
}

var unlocked_skins: Array = ["default", "gold_veteran"]
var purchased_sandbox_packs: Dictionary = {}
var inbox_claimed: Dictionary = {}
var sfx_enabled: bool = true
var music_enabled: bool = true
var screen_shake_enabled: bool = true
var vol_music: float = 0.75
var vol_sfx: float = 0.85
var vol_ui: float = 0.90
var lang: String = "pl" # "pl", "en", "de"
var is_online_mode: bool = true
var last_known_unix_time: int = 0
var daily_free_pack_claimed: bool = false
var daily_reset_day: int = -1 # UTC day index; preserve existing daily claims when upgrading saves.
var last_daily_calendar_claim_day: int = -1
var daily_missions: Array = []

var _sfx_player: AudioStreamPlayer = null
var _sfx_playback: AudioStreamGeneratorPlayback = null
var _wav_sfx_player: AudioStreamPlayer = null
var _ambience_player: AudioStreamPlayer = null
var _sfx_cache: Dictionary = {}

const SFX_WAV_MAP := {
	"ui_click": "res://audio/sfx/ui_click.wav",
	"ui_confirm": "res://audio/sfx/ui_confirm.wav",
	"ui_error": "res://audio/sfx/ui_error.wav",
	"shoot": "res://audio/sfx/weapon_plasma.wav",
	"hit": "res://audio/sfx/enemy_hurt.wav",
	"enemy_death": "res://audio/sfx/enemy_death.wav",
	"level_up": "res://audio/sfx/ui_level_up.wav",
	"victory": "res://audio/sfx/stage_victory.wav",
	"defeat": "res://audio/sfx/stage_defeat.wav",
	"reward": "res://audio/sfx/reward_claim.wav",
	"revive": "res://audio/sfx/revive.wav",
	"boss_warning": "res://audio/sfx/boss_warning.wav",
	"grenade": "res://audio/sfx/grenade_blast.wav"
}
const AMBIENCE_WAV_MAP := {
	"wasteland": "res://audio/ambience/wasteland_loop_8s.wav",
	"cryo_lab": "res://audio/ambience/cryo_lab_loop_8s.wav",
	"sewers": "res://audio/ambience/toxic_sewers_loop_8s.wav",
	"toxic_sewers": "res://audio/ambience/toxic_sewers_loop_8s.wav",
	"hive": "res://audio/ambience/dead_city_loop_8s.wav",
	"dead_city": "res://audio/ambience/dead_city_loop_8s.wav",
	"reactor": "res://audio/ambience/reactor_loop_8s.wav"
}

const DEFAULT_DAILY_MISSIONS := [
	{"id": "kill_mutants", "title_pl": "Pokonaj 30 mutantów", "title_en": "Defeat 30 mutants", "title_de": "Besiege 30 Mutanten", "progress": 0, "target": 30, "claimed": false, "credits": 150, "gems": 0, "scrap": 5},
	{"id": "complete_stage", "title_pl": "Ukończ 1 operację", "title_en": "Complete 1 operation", "title_de": "Schließe 1 Operation ab", "progress": 0, "target": 1, "claimed": false, "credits": 220, "gems": 0, "scrap": 8},
	{"id": "upgrade_gear", "title_pl": "Ulepsz przedmiot RPG", "title_en": "Upgrade RPG gear", "title_de": "Verbessere RPG-Ausrüstung", "progress": 0, "target": 1, "claimed": false, "credits": 180, "gems": 0, "scrap": 6}
]

const OBJECTIVE_NAMES_PL := {
	"activate_terminal": "Aktywuj terminal nadawczy",
	"defeat_boss": "Pokonaj Bossa operacji",
	"rescue_npc": "Uratuj ocalałego operatora",
	"escort": "Eskortuj drona badawczego",
	"destroy_target": "Zniszcz gniazdo mutacji",
	"defend_node": "Obroń węzeł zasilania",
	"repair_generator": "Napraw generator polowy"
}
const OBJECTIVE_NAMES_EN := {
	"activate_terminal": "Activate Uplink Terminal",
	"defeat_boss": "Defeat Operation Boss",
	"rescue_npc": "Rescue Stranded Operator",
	"escort": "Escort Research Drone",
	"destroy_target": "Destroy Mutation Nest",
	"defend_node": "Defend Power Node",
	"repair_generator": "Repair Field Generator"
}
const OBJECTIVE_NAMES_DE := {
	"activate_terminal": "Sendeterminal aktivieren",
	"defeat_boss": "Operations-Boss besiegen",
	"rescue_npc": "Überlebenden Operator retten",
	"escort": "Forschungsdrohne eskortieren",
	"destroy_target": "Mutationsnest zerstören",
	"defend_node": "Energieknoten verteidigen",
	"repair_generator": "Feldgenerator reparieren"
}

const HAZARD_NAMES_PL := {
	"acid_spots": "Plamy żrącego kwasu",
	"cryo_vent": "Wycieki kriogeniczne",
	"sewer_gas": "Chmury toksycznego gazu",
	"falling_debris": "Wstrząsy i odłamki stropu",
	"radiation_pulse": "Impulsy promieniowania A-03",
	"spore_cloud": "Zarodniki biomasy",
	"electric_arc": "Wyładowania łukowe"
}
const HAZARD_NAMES_EN := {
	"acid_spots": "Corrosive Acid Pools",
	"cryo_vent": "Cryogenic Vents",
	"sewer_gas": "Toxic Gas Clouds",
	"falling_debris": "Ceiling Tremors & Debris",
	"radiation_pulse": "A-03 Radiation Pulses",
	"spore_cloud": "Biomass Spore Clouds",
	"electric_arc": "Arc Discharges"
}
const HAZARD_NAMES_DE := {
	"acid_spots": "Ätzende Säurelachen",
	"cryo_vent": "Kryogene Lecks",
	"sewer_gas": "Giftgaswolken",
	"falling_debris": "Erschütterungen & Trümmer",
	"radiation_pulse": "A-03 Strahlungsimpulse",
	"spore_cloud": "Biomasse-Sporen",
	"electric_arc": "Lichtbogenentladungen"
}

const AFFIX_NAMES_PL := {
	"attack_pct": "Atak %",
	"hp_pct": "Zdrowie %",
	"armor_flat": "Pancerz",
	"crit_chance_pct": "Szansa kryt. %",
	"crit_damage_pct": "Obrażenia kryt. %",
	"move_speed_pct": "Prędkość ruchu %",
	"attack_speed_pct": "Szybkostrzelność %",
	"cooldown_reduction_pct": "Czas odnowienia %",
	"pickup_radius_pct": "Zasięg zbierania %",
	"lifesteal_pct": "Kradzież życia %",
	"poison_resistance_pct": "Odporność na toksyny %",
	"freeze_resistance_pct": "Odporność na mróz %"
}

const MUTATOR_NAMES_PL := {
	"dense_swarm": "Gęsty rój (+20% liczebności)",
	"armored_elites": "Opancerzone elity",
	"toxic_mist": "Toksyczna mgła",
	"overcharged_boss": "Przeciążony Boss",
	"fast_mutants": "Przyspieszone mutanty",
	"low_visibility": "Burza pyłowa"
}

func tr_text(pl_txt: String, en_txt: String, de_txt: String) -> String:
	match lang:
		"en":
			return en_txt
		"de":
			return de_txt
		_:
			return pl_txt

func set_language(new_lang: String) -> void:
	if new_lang in ["pl", "en", "de"]:
		lang = new_lang
		save_campaign_profile()

func translate_objective(obj_id: String) -> String:
	if lang == "en":
		return String(OBJECTIVE_NAMES_EN.get(obj_id, obj_id.replace("_", " ").capitalize()))
	elif lang == "de":
		return String(OBJECTIVE_NAMES_DE.get(obj_id, obj_id.replace("_", " ").capitalize()))
	return String(OBJECTIVE_NAMES_PL.get(obj_id, obj_id.replace("_", " ").capitalize()))

func translate_hazard(haz_id: String) -> String:
	if lang == "en":
		return String(HAZARD_NAMES_EN.get(haz_id, haz_id.replace("_", " ").capitalize()))
	elif lang == "de":
		return String(HAZARD_NAMES_DE.get(haz_id, haz_id.replace("_", " ").capitalize()))
	return String(HAZARD_NAMES_PL.get(haz_id, haz_id.replace("_", " ").capitalize()))

func translate_affix(af_id: String) -> String:
	return String(AFFIX_NAMES_PL.get(af_id, af_id.replace("_pct", " %").replace("_", " ")))

func translate_mutator(mut_id: String) -> String:
	return String(MUTATOR_NAMES_PL.get(mut_id, mut_id.replace("_", " ").capitalize()))

func get_safe_top_margin() -> float:
	if DisplayServer.get_name() == "headless":
		return 0.0
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS":
		var safe_rect := DisplayServer.get_display_safe_area()
		var win_size := DisplayServer.window_get_size()
		if win_size.y > 0 and safe_rect.position.y > 0:
			var scale_y := (1280.0 if is_portrait_mode() else 720.0) / float(win_size.y)
			return clampf(float(safe_rect.position.y) * scale_y, 0.0, 56.0)
	return 0.0

var inventory: Array = []          # Array[Dictionary] (instancje przedmiotów z unikalnym instance_id i afiksami)
var equipped_items: Dictionary = {} # slot (String) -> instance_id (String)

# Codzienne Nagrody (7 dni) + Przepustka Bitewna (Sezon 1: Mutacje) + Sandbox VIP
var daily_login_day: int = 1
var daily_claimed_days: Array = []
var battle_pass_xp: int = 450
var battle_pass_premium_unlocked: bool = false
var vip_sandbox_active: bool = false

const DAILY_REWARDS_TABLE := [
	{"day": 1, "title": "Dzień 1", "credits": 120, "gems": 0, "scrap": 4, "chest": false},
	{"day": 2, "title": "Dzień 2", "credits": 160, "gems": 0, "scrap": 5, "chest": false},
	{"day": 3, "title": "Dzień 3", "credits": 220, "gems": 0, "scrap": 6, "chest": false},
	{"day": 4, "title": "Dzień 4", "credits": 180, "gems": 0, "scrap": 8, "chest": false},
	{"day": 5, "title": "Dzień 5", "credits": 250, "gems": 0, "scrap": 10, "chest": true},
	{"day": 6, "title": "Dzień 6", "credits": 320, "gems": 0, "scrap": 14, "chest": false},
	{"day": 7, "title": "Dzień 7", "credits": 500, "gems": 0, "scrap": 24, "chest": true}
]

const HERO_CLASSES := {
	"soldier": {
		"id": "soldier",
		"name": "Żołnierz Szturmowy",
		"sprite": "res://assets/mutantsurvivor_ch01/characters/soldier_idle.png",
		"bonus_desc": "Ogień zaporowy: +15% Obrażeń, +10% Odrzutu pocisków (NPC: Mara)",
		"hp_mult": 1.08,
		"dmg_mult": 1.15,
		"speed_mult": 1.0,
		"regen_bonus": 0.2
	},
	"engineer": {
		"id": "engineer",
		"name": "Inżynier Bojowy",
		"sprite": "res://assets/mutantsurvivor_ch01/characters/engineer_idle.png",
		"bonus_desc": "Wieżyczka impulsowa: Start z Cewką Tesli, +25% Zasięgu Skanera (NPC: Iwo)",
		"hp_mult": 1.0,
		"dmg_mult": 1.05,
		"speed_mult": 0.98,
		"regen_bonus": 0.4
	},
	"medic": {
		"id": "medic",
		"name": "Medyk Polowy",
		"sprite": "res://assets/mutantsurvivor_ch01/characters/medic_idle.png",
		"bonus_desc": "Impuls ratunkowy: +25% Maks. HP, +2.2 HP/s Regeneracji (NPC: Nina)",
		"hp_mult": 1.25,
		"dmg_mult": 0.96,
		"speed_mult": 1.02,
		"regen_bonus": 2.2
	},
	"scout": {
		"id": "scout",
		"name": "Zwiadowca Cienia",
		"sprite": "res://assets/mutantsurvivor_ch01/characters/scout_idle.png",
		"bonus_desc": "Cień i błysk: +18% Prędkości Ruchu, +15% Szansy Krytycznej (NPC: Kira)",
		"hp_mult": 0.94,
		"dmg_mult": 1.10,
		"speed_mult": 1.18,
		"regen_bonus": 0.3
	}
}

# Trwałe talenty konta (poziomy 0..10)
var talent_levels: Dictionary = {
	"vitality": 1,
	"firepower": 1,
	"scanner": 0,
	"armor_plating": 0
}

func _ready() -> void:
	rng.randomize()
	_setup_audio_synthesizer()
	_load_static_json_data()
	load_campaign_profile()
	_grant_beta_test_gems_once()
	_ensure_starter_equipment()
	_ensure_daily_missions()
	refresh_attempts()
	_refresh_daily_progress()
	call_deferred("set_orientation_mode", orientation_mode, true)

func _setup_audio_synthesizer() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_wav_sfx_player = AudioStreamPlayer.new()
	add_child(_wav_sfx_player)
	_ambience_player = AudioStreamPlayer.new()
	add_child(_ambience_player)

	_sfx_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.25
	_sfx_player.stream = gen
	add_child(_sfx_player)
	_sfx_player.play()
	_sfx_playback = _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback

func play_biome_ambience(biome_id: String) -> void:
	if not music_enabled or DisplayServer.get_name() == "headless" or not is_instance_valid(_ambience_player):
		return
	var path: String = String(AMBIENCE_WAV_MAP.get(biome_id, "res://audio/ambience/wasteland_loop_8s.wav"))
	if ResourceLoader.exists(path):
		var st := load(path) as AudioStream
		if st:
			_ambience_player.stream = st
			_ambience_player.volume_db = linear_to_db(maxf(0.001, vol_music * 0.55))
			_ambience_player.play()

func play_sfx(sfx_id: String) -> void:
	if not sfx_enabled or DisplayServer.get_name() == "headless":
		return
	var vol := vol_ui if sfx_id.begins_with("ui_") else vol_sfx
	if vol <= 0.01:
		return
	var wav_path: String = String(SFX_WAV_MAP.get(sfx_id, ""))
	if not wav_path.is_empty() and is_instance_valid(_wav_sfx_player):
		if not _sfx_cache.has(wav_path) and ResourceLoader.exists(wav_path):
			_sfx_cache[wav_path] = load(wav_path)
		if _sfx_cache.has(wav_path) and _sfx_cache[wav_path] != null:
			_wav_sfx_player.stream = _sfx_cache[wav_path]
			_wav_sfx_player.volume_db = linear_to_db(maxf(0.001, vol * 0.75))
			_wav_sfx_player.play()
			return
	if _sfx_playback == null and is_instance_valid(_sfx_player):
		if not _sfx_player.playing:
			_sfx_player.play()
		_sfx_playback = _sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if _sfx_playback == null:
		return
	var frames := mini(_sfx_playback.get_frames_available(), 1800)
	if frames < 200:
		return
	var freq_start := 520.0
	var freq_end := 240.0
	var dur_frames := mini(frames, 1100)
	match sfx_id:
		"ui_click":
			freq_start = 780.0
			freq_end = 980.0
			dur_frames = mini(frames, 650)
		"shoot":
			freq_start = 640.0
			freq_end = 190.0
			dur_frames = mini(frames, 750)
		"hit":
			freq_start = 280.0
			freq_end = 110.0
			dur_frames = mini(frames, 600)
		"level_up", "victory":
			freq_start = 440.0
			freq_end = 880.0
			dur_frames = mini(frames, 1600)
		"defeat":
			freq_start = 320.0
			freq_end = 120.0
			dur_frames = mini(frames, 1600)
	var phase := 0.0
	for i in range(dur_frames):
		var t := float(i) / float(maxi(1, dur_frames))
		var freq := lerpf(freq_start, freq_end, t)
		phase = fmod(phase + freq / 22050.0, 1.0)
		var env := (1.0 - t) * 0.18 * vol
		var sample := sin(phase * TAU) * env
		_sfx_playback.push_frame(Vector2(sample, sample))

func _load_static_json_data() -> void:
	if FileAccess.file_exists(STAGES_JSON_PATH):
		var raw_stages := FileAccess.get_file_as_string(STAGES_JSON_PATH)
		var parsed: Variant = JSON.parse_string(raw_stages)
		if parsed is Array:
			stages_data = parsed
		elif parsed is Dictionary and parsed.get("stages") is Array:
			stages_data = parsed["stages"]
	if FileAccess.file_exists(DIFFICULTY_JSON_PATH):
		var raw_diff := FileAccess.get_file_as_string(DIFFICULTY_JSON_PATH)
		var parsed_diff: Variant = JSON.parse_string(raw_diff)
		if parsed_diff is Dictionary and parsed_diff.has("profiles"):
			difficulty_profiles = parsed_diff["profiles"]

	content_db = MutantV1ContentDB.new()
	if content_db.load_all():
		var camp_doc: Dictionary = content_db.documents.get("campaign_100_INTEGRATION.json", {})
		for m in camp_doc.get("missions", []):
			if m is Dictionary:
				v2_missions[int(m.get("stage", 0))] = m

		var boss_doc: Dictionary = content_db.documents.get("boss_and_elite_roster_v2.json", {})
		for b in boss_doc.get("bosses_and_elites", []):
			if b is Dictionary:
				v2_bosses[String(b.get("id", ""))] = b

		var mut_doc: Dictionary = content_db.documents.get("stage_mutators.json", {})
		for sm in mut_doc.get("stages", []):
			if sm is Dictionary:
				v2_mutators[int(sm.get("stage", 0))] = sm.get("mutators", [])

	if FileAccess.file_exists(V1_DATA_DIR + "objective_scene_contracts.json"):
		var raw_c := FileAccess.get_file_as_string(V1_DATA_DIR + "objective_scene_contracts.json")
		var parsed_c: Variant = JSON.parse_string(raw_c)
		if parsed_c is Dictionary:
			for mc in parsed_c.get("missions", []):
				if mc is Dictionary:
					v2_contracts[int(mc.get("stage", 0))] = mc

	if FileAccess.file_exists(V1_DATA_DIR + "npc_dialogues_v2.json"):
		var raw_d := FileAccess.get_file_as_string(V1_DATA_DIR + "npc_dialogues_v2.json")
		var parsed_d: Variant = JSON.parse_string(raw_d)
		if parsed_d is Dictionary:
			for dl in parsed_d.get("dialogue_lines", []):
				if dl is Dictionary:
					v2_dialogues[int(dl.get("stage", 0))] = dl

func is_portrait_mode() -> bool:
	if orientation_mode == "portrait":
		return true
	if orientation_mode == "landscape":
		return false
	var win_size := DisplayServer.window_get_size()
	return win_size.y > win_size.x

func set_orientation_mode(mode: String, resize_window: bool = true) -> void:
	orientation_mode = mode
	var portrait := is_portrait_mode()
	if get_tree() and get_tree().root:
		get_tree().root.content_scale_size = Vector2i(720, 1280) if portrait else Vector2i(1280, 720)
	if resize_window and DisplayServer.get_name() != "headless":
		var os_name := OS.get_name()
		if os_name == "Android" or os_name == "iOS":
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT if portrait else DisplayServer.SCREEN_LANDSCAPE)
		else:
			if portrait:
				DisplayServer.window_set_size(Vector2i(720, 1280))
			else:
				DisplayServer.window_set_size(Vector2i(1280, 720))
	emit_signal("orientation_changed", portrait)

func toggle_orientation_mode() -> void:
	if is_portrait_mode():
		set_orientation_mode("landscape", true)
	else:
		set_orientation_mode("portrait", true)
	save_campaign_profile()

func get_active_save_path() -> String:
	return save_path_override if not save_path_override.is_empty() else DEFAULT_SAVE_PATH

func _grant_beta_test_gems_once() -> bool:
	if not BETA_TEST_GEMS_ENABLED:
		_revoke_unspent_beta_gems()
		return false
	if beta_test_gems_granted:
		return false
	dark_matter_gems += BETA_TEST_GEMS_AMOUNT
	beta_test_gems_remaining += BETA_TEST_GEMS_AMOUNT
	beta_test_gems_granted = true
	save_campaign_profile()
	return true

func _revoke_unspent_beta_gems() -> void:
	if beta_test_gems_remaining <= 0 and beta_test_skins_purchased.is_empty():
		return
	# Release cleanup affects test-funded cosmetics and unspent beta credits,
	# not the user's ordinary free-to-play progress or independently owned skins.
	dark_matter_gems = maxi(0, dark_matter_gems - beta_test_gems_remaining)
	beta_test_gems_remaining = 0
	for skin_id in beta_test_skins_purchased:
		if unlocked_skins.has(skin_id):
			unlocked_skins.erase(skin_id)
		if selected_skin_id == String(skin_id):
			selected_skin_id = "default"
	beta_test_skins_purchased.clear()
	save_campaign_profile()

func spend_premium_gems(amount: int) -> bool:
	if amount <= 0 or dark_matter_gems < amount:
		return false
	dark_matter_gems -= amount
	beta_test_gems_remaining = maxi(0, beta_test_gems_remaining - mini(beta_test_gems_remaining, amount))
	return true

func _sync_active_class_to_dict() -> void:
	if not class_progression.has(selected_class_id):
		class_progression[selected_class_id] = {}
	class_progression[selected_class_id]["level"] = character_level
	class_progression[selected_class_id]["xp"] = character_xp
	class_progression[selected_class_id]["max_stage"] = max_unlocked_stage
	class_progression[selected_class_id]["talents"] = talent_levels.duplicate(true)
	class_progression[selected_class_id]["equipped_items"] = equipped_items.duplicate(true)
	class_progression[selected_class_id]["first_clears"] = first_clears_v2.duplicate(true)

func _sync_active_class_from_dict() -> void:
	if not class_progression.has(selected_class_id):
		class_progression[selected_class_id] = {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}}
	var p: Dictionary = class_progression[selected_class_id]
	character_level = clampi(int(p.get("level", 1)), 1, 100)
	character_xp = maxi(0, int(p.get("xp", 0)))
	max_unlocked_stage = clampi(int(p.get("max_stage", 1)), 1, 100)
	if p.get("talents") is Dictionary:
		talent_levels = (p["talents"] as Dictionary).duplicate(true)
	else:
		talent_levels = {}
	if p.get("equipped_items") is Dictionary:
		equipped_items = (p["equipped_items"] as Dictionary).duplicate(true)
	else:
		equipped_items = {}
	if p.get("first_clears") is Dictionary:
		first_clears_v2 = (p["first_clears"] as Dictionary).duplicate(true)
	else:
		first_clears_v2 = {}

func switch_class(target_class_id: String) -> bool:
	if not HERO_CLASSES.has(target_class_id):
		return false
	_sync_active_class_to_dict()
	selected_class_id = target_class_id
	_sync_active_class_from_dict()
	save_campaign_profile()
	emit_signal("profile_data_changed")
	return true

func get_class_level(cls_id: String) -> int:
	if cls_id == selected_class_id:
		return character_level
	var p: Dictionary = class_progression.get(cls_id, {})
	return clampi(int(p.get("level", 1)), 1, 100)

func get_class_max_stage(cls_id: String) -> int:
	if cls_id == selected_class_id:
		return max_unlocked_stage
	var p: Dictionary = class_progression.get(cls_id, {})
	return clampi(int(p.get("max_stage", 1)), 1, 100)

func _parse_save_dictionary(raw: String) -> Dictionary:
	# JSON.parse_string prints engine-level ERROR lines for intentionally
	# corrupted QA files. The low-level parser returns a status without
	# alarming players or making a recoverable backup look like a crash.
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return {}
	var data: Variant = parser.data
	return data if data is Dictionary else {}

func save_campaign_profile() -> void:
	_sync_active_class_to_dict()
	var data := {
		"save_version": 3,
		"current_stage": current_stage,
		"max_unlocked_stage": max_unlocked_stage,
		"selected_difficulty_id": selected_difficulty_id,
		"selected_class_id": selected_class_id,
		"selected_skin_id": selected_skin_id,
		"orientation_mode": orientation_mode,
		"lang": lang,
		"vol_music": vol_music,
		"vol_sfx": vol_sfx,
		"vol_ui": vol_ui,
		"character_level": character_level,
		"character_xp": character_xp,
		"credits": credits,
		"dark_matter_gems": dark_matter_gems,
		"beta_test_gems_granted": beta_test_gems_granted,
		"beta_test_gems_remaining": beta_test_gems_remaining,
		"beta_test_skins_purchased": beta_test_skins_purchased,
		"scrap_materials": scrap_materials,
		"cleared_stages": cleared_stages,
		"first_clears_v2": first_clears_v2,
		"talent_levels": talent_levels,
		"attempts": attempts,
		"next_attempt_at": next_attempt_at,
		"last_known_unix_time": last_known_unix_time,
		"inventory": inventory,
		"equipped_items": equipped_items,
		"daily_login_day": daily_login_day,
		"daily_claimed_days": daily_claimed_days,
		"daily_free_pack_claimed": daily_free_pack_claimed,
		"daily_reset_day": daily_reset_day,
		"last_daily_calendar_claim_day": last_daily_calendar_claim_day,
		"daily_missions": daily_missions,
		"battle_pass_xp": battle_pass_xp,
		"battle_pass_premium_unlocked": battle_pass_premium_unlocked,
		"vip_sandbox_active": vip_sandbox_active,
		"unlocked_skins": unlocked_skins,
		"purchased_sandbox_packs": purchased_sandbox_packs,
		"inbox_claimed": inbox_claimed,
		"class_progression": class_progression,
		"pity_chest_counter": pity_chest_counter
	}
	var path := get_active_save_path()
	# Preserve the last valid save before replacing the primary file.
	# This lets beta users recover from interrupted writes/corrupt JSON.
	if FileAccess.file_exists(path):
		var previous_raw := FileAccess.get_file_as_string(path)
		if not _parse_save_dictionary(previous_raw).is_empty():
			var backup_file := FileAccess.open(path + ".bak", FileAccess.WRITE)
			if backup_file:
				backup_file.store_string(previous_raw)
				backup_file.flush()
				backup_file.close()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.flush()
		f.close()
	else:
		push_error("Cannot write campaign save file: " + path)
	emit_signal("profile_data_changed")

func load_campaign_profile() -> void:
	var path := get_active_save_path()
	var data: Variant = null
	if FileAccess.file_exists(path):
		data = _parse_save_dictionary(FileAccess.get_file_as_string(path))
	if (not (data is Dictionary) or data.is_empty()) and FileAccess.file_exists(path + ".bak"):
		data = _parse_save_dictionary(FileAccess.get_file_as_string(path + ".bak"))
		if data is Dictionary and not data.is_empty():
			push_warning("Restored valid campaign save from backup")
	if data is Dictionary and not data.is_empty():
		max_unlocked_stage = clampi(int(data.get("max_unlocked_stage", 1)), 1, 100)
		current_stage = clampi(int(data.get("current_stage", 1)), 1, max_unlocked_stage)
		selected_difficulty_id = String(data.get("selected_difficulty_id", "ocalaly"))
		selected_class_id = String(data.get("selected_class_id", "soldier"))
		selected_skin_id = String(data.get("selected_skin_id", "default"))
		orientation_mode = String(data.get("orientation_mode", "portrait"))
		lang = String(data.get("lang", "pl"))
		vol_music = clampf(float(data.get("vol_music", 0.75)), 0.0, 1.0)
		vol_sfx = clampf(float(data.get("vol_sfx", 0.85)), 0.0, 1.0)
		vol_ui = clampf(float(data.get("vol_ui", 0.90)), 0.0, 1.0)
		character_level = clampi(int(data.get("character_level", 1)), 1, 100)
		character_xp = maxi(0, int(data.get("character_xp", 0)))
		credits = maxi(0, int(data.get("credits", 350)))
		# Existing accounts retain their balance; new accounts start at 0 before
		# the one-time beta grant. The legacy 180 fallback only covers old saves.
		dark_matter_gems = maxi(0, int(data.get("dark_matter_gems", 180)))
		beta_test_gems_granted = bool(data.get("beta_test_gems_granted", false))
		beta_test_gems_remaining = maxi(0, int(data.get("beta_test_gems_remaining", mini(dark_matter_gems, BETA_TEST_GEMS_AMOUNT) if beta_test_gems_granted else 0)))
		beta_test_skins_purchased = data.get("beta_test_skins_purchased", []) if data.get("beta_test_skins_purchased", []) is Array else []
		scrap_materials = maxi(0, int(data.get("scrap_materials", 12)))
		attempts = clampi(int(data.get("attempts", 5)), 0, 5)
		next_attempt_at = int(data.get("next_attempt_at", 0))
		last_known_unix_time = int(data.get("last_known_unix_time", 0))
		daily_login_day = clampi(int(data.get("daily_login_day", 1)), 1, 7)
		daily_free_pack_claimed = bool(data.get("daily_free_pack_claimed", false))
		daily_reset_day = int(data.get("daily_reset_day", -1))
		# Legacy saves already containing calendar claims must not receive another
		# reward on the same migration day.
		last_daily_calendar_claim_day = int(data.get("last_daily_calendar_claim_day", int(Time.get_unix_time_from_system() / 86400) if not data.get("daily_claimed_days", []).is_empty() else -1))
		battle_pass_xp = maxi(0, int(data.get("battle_pass_xp", 450)))
		battle_pass_premium_unlocked = bool(data.get("battle_pass_premium_unlocked", false))
		vip_sandbox_active = bool(data.get("vip_sandbox_active", false))
		pity_chest_counter = int(data.get("pity_chest_counter", 0))

		if data.get("cleared_stages") is Dictionary:
			cleared_stages = data["cleared_stages"]
		if data.get("first_clears_v2") is Dictionary:
			first_clears_v2 = data["first_clears_v2"]
		if data.get("talent_levels") is Dictionary:
			talent_levels = data["talent_levels"]
		if data.get("inventory") is Array:
			inventory = data["inventory"]
		if data.get("equipped_items") is Dictionary:
			equipped_items = data["equipped_items"]
		if data.get("daily_claimed_days") is Array:
			daily_claimed_days = data["daily_claimed_days"]
		if data.get("daily_missions") is Array:
			daily_missions = data["daily_missions"]
		if data.get("unlocked_skins") is Array:
			unlocked_skins = data["unlocked_skins"]
		if data.get("purchased_sandbox_packs") is Dictionary:
			purchased_sandbox_packs = data["purchased_sandbox_packs"]
		if data.get("inbox_claimed") is Dictionary:
			inbox_claimed = data["inbox_claimed"]

		if data.get("class_progression") is Dictionary:
			class_progression = data["class_progression"]
			_sync_active_class_from_dict()
		else:
			# Migracja starego zapisu (soldier otrzymuje obecny poziom, pozostałe startują z 1)
			class_progression = {
				"soldier": {"level": character_level, "xp": character_xp, "max_stage": max_unlocked_stage, "talents": talent_levels.duplicate(true), "equipped_items": equipped_items.duplicate(true), "first_clears": first_clears_v2.duplicate(true)},
				"engineer": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}},
				"medic": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}},
				"scout": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}}
			}
			_sync_active_class_from_dict()

func _refresh_daily_progress() -> void:
	# Advance only when the effective clock moves forward; never reward clock rollback.
	var effective_now := maxi(int(Time.get_unix_time_from_system()), last_known_unix_time)
	var today := int(effective_now / 86400)
	if daily_reset_day < 0:
		# Existing saves may have a claimed pack: do not grant it a second time on migration.
		daily_reset_day = today
		save_campaign_profile()
	elif today > daily_reset_day:
		daily_reset_day = today
		daily_free_pack_claimed = false
		daily_missions.clear()
		_ensure_daily_missions()
		save_campaign_profile()

func _ensure_daily_missions() -> void:
	if daily_missions.is_empty():
		for m in DEFAULT_DAILY_MISSIONS:
			daily_missions.append((m as Dictionary).duplicate(true))

func record_daily_mission_progress(mission_id: String, amount: int = 1) -> void:
	_refresh_daily_progress()
	_ensure_daily_missions()
	for i in range(daily_missions.size()):
		var m: Dictionary = daily_missions[i]
		if String(m.get("id", "")) == mission_id and not bool(m.get("claimed", false)):
			var target := int(m.get("target", 1))
			m["progress"] = mini(target, int(m.get("progress", 0)) + amount)
			daily_missions[i] = m

func claim_daily_mission(mission_id: String) -> bool:
	_refresh_daily_progress()
	_ensure_daily_missions()
	for i in range(daily_missions.size()):
		var m: Dictionary = daily_missions[i]
		if String(m.get("id", "")) == mission_id:
			var prog := int(m.get("progress", 0))
			var target := int(m.get("target", 1))
			if prog >= target and not bool(m.get("claimed", false)):
				m["claimed"] = true
				daily_missions[i] = m
				credits += int(m.get("credits", 100))
				# Legacy saved missions may contain pre-release gem rewards.
				# Never mint premium currency from a free mission.
				scrap_materials += int(m.get("scrap", 3))
				play_sfx("victory")
				save_campaign_profile()
				return true
	return false

func claim_daily_free_shop_pack() -> bool:
	_refresh_daily_progress()
	if daily_free_pack_claimed:
		return false
	daily_free_pack_claimed = true
	credits += 150
	# The daily supply pack is free-to-play credits/materials, not paid gems.
	scrap_materials += 5
	play_sfx("victory")
	save_campaign_profile()
	return true

func get_daily_reset_countdown_str() -> String:
	_refresh_daily_progress()
	var now_u := int(Time.get_unix_time_from_system())
	var sec_in_day := 86400
	var rem := sec_in_day - (now_u % sec_in_day)
	var hh := int(rem / 3600)
	var mm := int((rem % 3600) / 60)
	var ss := int(rem % 60)
	return "%02d:%02d:%02d" % [hh, mm, ss]

func get_drop_probabilities_text() -> String:
	return (
		"UJAWNIENIE SZANS LOSOWANIA (DROP ODDS V1):\n" +
		"• Zwykła (Common): 68.00%\n" +
		"• Rzadka (Rare): 24.00%\n" +
		"• Epicka (Epic): 6.50%\n" +
		"• Legendarna (Legendary): 1.30%\n" +
		"• Mityczna (Mythic): 0.20%\n" +
		"• Sukces ulepszenia przedmiotu (+1..+10): 100.00% (Gwarantowany)"
	)

func _ensure_starter_equipment() -> void:
	if inventory.is_empty() and content_db != null:
		var starter_ids := ["weapon_common_01", "helmet_common_01", "chest_common_01", "boots_common_01"]
		var affix_doc: Dictionary = content_db.documents.get("affixes_and_drops_v2.json", {})
		for tpl_id in starter_ids:
			var tpl := content_db.item_by_id(tpl_id)
			if not tpl.is_empty():
				var item := MutantV1EquipmentRoller.roll_item(tpl, affix_doc, rng)
				item["name"] = String(tpl.get("name", tpl_id))
				item["slot"] = String(tpl.get("slot", "weapon"))
				item["base_power"] = float(tpl.get("base_power", 10.0))
				inventory.append(item)
				equipped_items[String(item["slot"])] = String(item["instance_id"])
		# Only starter-tier gear is granted for free. Rare/epic equipment must be
		# earned through play, not injected for developer demonstrations.

func roll_new_equipment_drop(stage_num: int, forced_rarity: String = "", persist: bool = true) -> Dictionary:
	if content_db == null:
		return {}
	var affix_doc: Dictionary = content_db.documents.get("affixes_and_drops_v2.json", {})
	var weights: Dictionary = affix_doc.get("rarity_roll_weights_basis_points", {"common": 6800, "rare": 2400, "epic": 650, "legendary": 130, "mythic": 20})
	var rarity := forced_rarity if not forced_rarity.is_empty() else MutantV1EquipmentRoller.roll_rarity(weights, rng)

	var catalog: Dictionary = content_db.documents.get("equipment_catalog_v2.json", {})
	var candidates: Array = []
	for it in catalog.get("items", []):
		if it is Dictionary and String(it.get("rarity", "")) == rarity:
			if int(it.get("min_stage", 1)) <= clampi(stage_num, 1, 100):
				candidates.append(it)
	if candidates.is_empty() and forced_rarity.is_empty():
		# Only randomly rolled equipment may downgrade to a stage-eligible
		# common item. A forced rarity (fusion, guaranteed prize, paid chest)
		# must NEVER silently downgrade or consume valuable ingredients.
		for it in catalog.get("items", []):
			if it is Dictionary and String(it.get("rarity", "")) == "common" and int(it.get("min_stage", 1)) <= clampi(stage_num, 1, 100):
				candidates.append(it)
	if candidates.is_empty():
		return {}

	var tpl: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var rolled := MutantV1EquipmentRoller.roll_item(tpl, affix_doc, rng)
	rolled["name"] = String(tpl.get("name", "Moduł Bojowy"))
	rolled["slot"] = String(tpl.get("slot", "weapon"))
	rolled["base_power"] = float(tpl.get("base_power", 10.0))
	inventory.append(rolled)
	if persist:
		save_campaign_profile()
	return rolled

const RARITY_TIERS := ["common", "rare", "epic", "legendary", "mythic"]

func open_purchased_chest(cost_gems: int = 50) -> Dictionary:
	if cost_gems <= 0 or dark_matter_gems < cost_gems:
		return {}
	var previous_pity := pity_chest_counter
	pity_chest_counter += 1
	var forced_r := ""
	if pity_chest_counter >= 50:
		forced_r = "legendary"
		pity_chest_counter = 0
	var item := roll_new_equipment_drop(max_unlocked_stage, forced_r, false)
	if item.is_empty():
		# Never charge currency OR erase guaranteed-chest pity on unavailable loot.
		pity_chest_counter = previous_pity
		return {}
	if not spend_premium_gems(cost_gems):
		inventory.erase(item)
		pity_chest_counter = previous_pity
		return {}
	if not forced_r.is_empty() or String(item.get("rarity", "")) in ["legendary", "mythic"]:
		pity_chest_counter = 0
	save_campaign_profile()
	return item

func fuse_equipment_triplet(id1: String, id2: String, id3: String) -> Dictionary:
	if id1 == id2 or id1 == id3 or id2 == id3:
		return {}
	var it1 := get_item_instance(id1)
	var it2 := get_item_instance(id2)
	var it3 := get_item_instance(id3)
	if it1.is_empty() or it2.is_empty() or it3.is_empty():
		return {}
	var r1 := String(it1.get("rarity", "common"))
	var r2 := String(it2.get("rarity", "common"))
	var r3 := String(it3.get("rarity", "common"))
	if r1 != r2 or r2 != r3:
		return {}
	var tier_idx := RARITY_TIERS.find(r1)
	if tier_idx == -1 or tier_idx >= RARITY_TIERS.size() - 1:
		return {}
	var target_rarity: String = RARITY_TIERS[tier_idx + 1]
	# Obtain a valid result before consuming the three inputs; if there is no
	# eligible loot at this stage, the player keeps every source item.
	var fused_item := roll_new_equipment_drop(max_unlocked_stage, target_rarity, false)
	if fused_item.is_empty():
		return {}

	for slot in equipped_items.keys():
		if equipped_items[slot] in [id1, id2, id3]:
			equipped_items.erase(slot)

	var to_remove := [id1, id2, id3]
	var new_inv: Array = []
	for it in inventory:
		if it is Dictionary and String(it.get("instance_id", "")) in to_remove:
			continue
		new_inv.append(it)
	inventory = new_inv

	save_campaign_profile()
	emit_signal("profile_data_changed")
	return fused_item

func get_item_instance(instance_id: String) -> Dictionary:
	for it in inventory:
		if it is Dictionary and String(it.get("instance_id", "")) == instance_id:
			return it
	return {}

func equip_item(instance_id: String) -> void:
	var item := get_item_instance(instance_id)
	if item.is_empty():
		return
	var slot := String(item.get("slot", "weapon"))
	equipped_items[slot] = instance_id
	save_campaign_profile()

func unequip_slot(slot: String) -> void:
	if equipped_items.has(slot):
		equipped_items.erase(slot)
		save_campaign_profile()

func get_item_effective_power(item: Dictionary) -> float:
	if item.is_empty():
		return 0.0
	var base_p := float(item.get("base_power", 10.0))
	var lvl := int(item.get("level", 0))
	return base_p * (1.0 + 0.12 * float(lvl))

func get_total_combat_power() -> int:
	var pwr := 250.0 + float(character_level) * 35.0
	for slot in GEAR_SLOTS:
		var inst_id := String(equipped_items.get(slot, ""))
		if not inst_id.is_empty():
			var it := get_item_instance(inst_id)
			if not it.is_empty():
				pwr += get_item_effective_power(it) * 6.5
				pwr += float((it.get("affixes", []) as Array).size()) * 28.0
	for t_key in talent_levels.keys():
		pwr += float(int(talent_levels[t_key])) * 24.0
	return int(roundf(pwr))

func upgrade_item_by_instance(inst_id: String) -> bool:
	if inst_id.is_empty():
		return false
	for i in range(inventory.size()):
		var it: Dictionary = inventory[i]
		if String(it.get("instance_id", "")) == inst_id:
			var lvl := int(it.get("level", 0))
			if lvl >= 10:
				return false
			var cost_credits := 45 + lvl * 30
			var cost_scrap := 1 + int(lvl / 3)
			if credits < cost_credits or scrap_materials < cost_scrap:
				return false
			credits -= cost_credits
			scrap_materials -= cost_scrap
			it["level"] = lvl + 1
			inventory[i] = it
			record_daily_mission_progress("upgrade_gear", 1)
			play_sfx("ui_click")
			save_campaign_profile()
			return true
	return false

func upgrade_equipped_item(slot: String) -> bool:
	var inst_id := String(equipped_items.get(slot, ""))
	return upgrade_item_by_instance(inst_id)

func get_total_equipment_bonuses() -> Dictionary:
	var bonuses := {
		"flat_damage": 0.0,
		"flat_hp": 0.0,
		"flat_armor": 0.0,
		"attack_pct": 0.0,
		"hp_pct": 0.0,
		"crit_chance_pct": 0.0,
		"crit_damage_pct": 0.0,
		"move_speed_pct": 0.0,
		"attack_speed_pct": 0.0,
		"pickup_radius_pct": 0.0
	}
	for slot in GEAR_SLOTS:
		var inst_id := String(equipped_items.get(slot, ""))
		if inst_id.is_empty():
			continue
		var item := get_item_instance(inst_id)
		if item.is_empty():
			continue
		var base_p := float(item.get("base_power", 10.0))
		var lvl := int(item.get("level", 0))
		var scaled_p := base_p * (1.0 + 0.12 * float(lvl))
		match slot:
			"weapon":
				bonuses["flat_damage"] += scaled_p
			"helmet", "chest":
				bonuses["flat_hp"] += scaled_p * 2.5
			"gloves":
				bonuses["flat_damage"] += scaled_p * 0.45
			"boots":
				bonuses["move_speed_pct"] += 3.0 + float(lvl) * 0.6
			"amulet":
				bonuses["flat_hp"] += scaled_p * 1.5
				bonuses["flat_damage"] += scaled_p * 0.35

		for af in item.get("affixes", []):
			if af is Dictionary:
				var af_id := String(af.get("id", ""))
				var af_val := float(af.get("value", 0.0))
				if bonuses.has(af_id):
					bonuses[af_id] = float(bonuses[af_id]) + af_val
				elif af_id == "armor_flat":
					bonuses["flat_armor"] += af_val
	return bonuses

func refresh_attempts() -> void:
	var now_u := int(Time.get_unix_time_from_system())
	# Ochrona przed cofaniem zegara: jeśli czas systemowy jest mniejszy niż ostatni zapisany,
	# używamy ostatniego znanego czasu monotonicznego (nie odbieramy graczowi prób, ale nie naliczamy fałszywego czasu)
	var effective_now := maxi(now_u, last_known_unix_time)
	last_known_unix_time = effective_now
	var state := MutantV1Attempts.refresh({"attempts": attempts, "next_attempt_at": next_attempt_at}, effective_now)
	attempts = int(state.get("attempts", 5))
	next_attempt_at = int(state.get("next_attempt_at", 0))

func get_attempt_cooldown_text() -> String:
	refresh_attempts()
	if attempts >= 5 or next_attempt_at <= 0:
		return tr_text("PEŁNE (5/5)", "FULL (5/5)", "VOLL (5/5)")
	var rem := maxi(0, next_attempt_at - last_known_unix_time)
	var mm := int(rem / 60)
	var ss := int(rem % 60)
	return "%02d:%02d" % [mm, ss]

func spend_campaign_attempt() -> bool:
	refresh_attempts()
	var res := MutantV1Attempts.spend({"attempts": attempts, "next_attempt_at": next_attempt_at}, last_known_unix_time)
	if not bool(res.get("ok", false)):
		return false
	var st: Dictionary = res["state"]
	attempts = int(st.get("attempts", 0))
	next_attempt_at = int(st.get("next_attempt_at", 0))
	save_campaign_profile()
	return true

const SINGLE_ATTEMPT_REFILL_GEMS := 18
const FULL_ATTEMPTS_REFILL_GEMS := 60

const SKIN_GEM_PRICES := {
	"neon_hunter": 120,
	"hazmat_trooper": 120,
	"crimson_storm": 120,
	"void_sniper": 150
}

func buy_skin_with_gems(skin_id: String) -> bool:
	if not SKIN_GEM_PRICES.has(skin_id):
		return false
	if unlocked_skins.has(skin_id):
		return false
	var price := int(SKIN_GEM_PRICES[skin_id])
	if dark_matter_gems < price:
		return false
	# Payment and ownership are changed together, then persisted.
	var paid_with_beta_gems := beta_test_gems_remaining >= price
	if not spend_premium_gems(price):
		return false
	unlocked_skins.append(skin_id)
	if paid_with_beta_gems and not beta_test_skins_purchased.has(skin_id):
		beta_test_skins_purchased.append(skin_id)
	selected_skin_id = skin_id
	save_campaign_profile()
	emit_signal("profile_data_changed")
	return true

func can_buy_single_attempt_refill() -> bool:
	return attempts < 5 and dark_matter_gems >= SINGLE_ATTEMPT_REFILL_GEMS

func buy_single_attempt_refill() -> bool:
	if not can_buy_single_attempt_refill():
		return false
	if not spend_premium_gems(SINGLE_ATTEMPT_REFILL_GEMS):
		return false
	attempts = mini(5, attempts + 1)
	if attempts >= 5:
		next_attempt_at = 0
	save_campaign_profile()
	emit_signal("profile_data_changed")
	return true

func can_buy_full_attempts_refill() -> bool:
	return attempts < 5 and dark_matter_gems >= FULL_ATTEMPTS_REFILL_GEMS

func buy_full_attempts_refill() -> bool:
	if not can_buy_full_attempts_refill():
		return false
	if not spend_premium_gems(FULL_ATTEMPTS_REFILL_GEMS):
		return false
	attempts = 5
	next_attempt_at = 0
	save_campaign_profile()
	emit_signal("profile_data_changed")
	return true

func refill_attempts_sandbox() -> void:
	var st := MutantV1Attempts.refill({})
	attempts = int(st.get("attempts", 5))
	next_attempt_at = int(st.get("next_attempt_at", 0))
	save_campaign_profile()

func claim_daily_reward(day_num: int) -> Dictionary:
	# Day seven rewards must never be accessible on the first login.
	# One reward per UTC day, strictly in order; persist the claim timestamp.
	_refresh_daily_progress()
	var today: int = int(maxi(int(Time.get_unix_time_from_system()), last_known_unix_time) / 86400)
	if day_num != daily_login_day or daily_claimed_days.has(day_num) or last_daily_calendar_claim_day >= today:
		return {"ok": false}
	if daily_claimed_days.has(day_num):
		return {"ok": false}
	for r in DAILY_REWARDS_TABLE:
		if int(r["day"]) == day_num:
			daily_claimed_days.append(day_num)
			last_daily_calendar_claim_day = today
			credits += int(r["credits"])
			# Premium currency is not awarded by normal calendar login.
			scrap_materials += int(r["scrap"])
			var dropped_item := {}
			if bool(r["chest"]):
				dropped_item = roll_new_equipment_drop(current_stage) # Guaranteed stage-appropriate item, rarity per normal loot odds
			if day_num >= daily_login_day and daily_login_day < 7:
				daily_login_day = day_num + 1
			save_campaign_profile()
			return {"ok": true, "reward": r, "item": dropped_item}
	return {"ok": false}

func get_stage_config(stage_num: int = -1) -> Dictionary:
	var s := current_stage if stage_num < 1 else clampi(stage_num, 1, 100)
	var base_cfg: Dictionary = {}
	var idx := s - 1
	if idx >= 0 and idx < stages_data.size():
		base_cfg = (stages_data[idx] as Dictionary).duplicate(true)

	# Połącz z danymi v2 (campaign_100_INTEGRATION.json + objective_scene_contracts.json)
	if v2_missions.has(s):
		var m2: Dictionary = v2_missions[s]
		base_cfg["id"] = String(m2.get("id", "MS_STORY_%03d" % s))
		base_cfg["stage"] = s
		base_cfg["chapter"] = int(m2.get("chapter", ceil(float(s) / 10.0)))
		base_cfg["name"] = String(m2.get("name", base_cfg.get("name", "Operacja %03d" % s)))
		base_cfg["npc"] = String(m2.get("npc", "Mara"))
		base_cfg["biome"] = String(m2.get("biome", "wasteland"))
		base_cfg["hazard"] = String(m2.get("hazard", "acid_spots"))
		base_cfg["waves"] = int(m2.get("waves", 10))
		base_cfg["objectives_v2"] = m2.get("objectives", [])
		base_cfg["intro_dialogue"] = m2.get("intro_dialogue", [])
		base_cfg["progress_dialogue"] = m2.get("progress_dialogue", [])
		base_cfg["completion_dialogue"] = m2.get("completion_dialogue", [])
		base_cfg["rewards_v2"] = m2.get("rewards", {})
		base_cfg["replay_credits_multiplier"] = m2.get("replay_credits_multiplier", 0.35)
		base_cfg["mandatory_stage_unlock"] = m2.get("mandatory_stage_unlock", s + 1)

		var w5: Dictionary = m2.get("wave5", {})
		var w10: Dictionary = m2.get("wave10", {})
		base_cfg["elite_id"] = "" if w5.get("elite_id") == null else String(w5.get("elite_id"))
		base_cfg["boss_id"] = "" if w10.get("boss_id") == null else String(w10.get("boss_id"))

	if v2_contracts.has(s):
		var ct: Dictionary = v2_contracts[s]
		base_cfg["scene_type"] = String(ct.get("scene_type", "activate_terminal"))
		base_cfg["interaction_target"] = String(ct.get("interaction_target", "terminal"))

	if v2_mutators.has(s):
		base_cfg["mutators"] = v2_mutators[s]
	else:
		base_cfg["mutators"] = []

	var biome_id := String(base_cfg.get("biome", "wasteland"))
	var biome_info: Dictionary = AssetRegistry.BIOME_PALETTES.get(biome_id, AssetRegistry.BIOME_PALETTES["wasteland"])
	base_cfg["chapter_name"] = String(biome_info.get("name", "Pustkowia"))

	return base_cfg

func get_difficulty_profile(diff_id: String = "") -> Dictionary:
	var target := selected_difficulty_id if diff_id.is_empty() else diff_id
	var defaults := {
		"rekrut": {"id": "rekrut", "name": "Rekrut", "enemy_hp": 0.75, "enemy_dmg": 0.70, "spawn_rate": 0.80, "elite_chance": 0.85, "xp_gain": 1.0, "reward": 1.0, "revives": 1},
		"ocalaly": {"id": "ocalaly", "name": "Ocalały", "enemy_hp": 1.00, "enemy_dmg": 1.00, "spawn_rate": 1.00, "elite_chance": 1.00, "xp_gain": 1.15, "reward": 1.25, "revives": 1},
		"weteran": {"id": "weteran", "name": "Weteran", "enemy_hp": 1.25, "enemy_dmg": 1.20, "spawn_rate": 1.25, "elite_chance": 1.25, "xp_gain": 1.35, "reward": 1.60, "revives": 1},
		"koszmar": {"id": "koszmar", "name": "Koszmar", "enemy_hp": 1.60, "enemy_dmg": 1.40, "spawn_rate": 1.45, "elite_chance": 1.50, "xp_gain": 1.65, "reward": 2.10, "revives": 1},
		"apokalipsa": {"id": "apokalipsa", "name": "Apokalipsa", "enemy_hp": 2.00, "enemy_dmg": 1.65, "spawn_rate": 1.70, "elite_chance": 1.85, "xp_gain": 2.00, "reward": 2.80, "revives": 1}
	}
	if defaults.has(target):
		return defaults[target]
	return defaults["ocalaly"]

func calc_time_hp_mult(elapsed_sec: float) -> float:
	var m := maxf(0.0, elapsed_sec) / 60.0
	return 1.0 + 0.075 * m + 0.018 * (m * m)

func calc_time_dmg_mult(elapsed_sec: float) -> float:
	var m := maxf(0.0, elapsed_sec) / 60.0
	return 1.0 + 0.045 * m + 0.008 * (m * m)

func get_stage_bracket_info(stage_num: int) -> Dictionary:
	var s := clampi(stage_num, 1, 100)
	if s <= 10:
		return {"bracket": "1-10", "title": "Wdrożenie taktyczne", "allow_ranged": false, "elite_wave": 5, "telegraph_sec": 1.05, "hazard_interval": 8.0, "boss_phases": 1}
	elif s <= 29:
		return {"bracket": "11-29", "title": "Jednostki dystansowe i elity", "allow_ranged": true, "elite_wave": 4, "telegraph_sec": 0.95, "hazard_interval": 6.8, "boss_phases": 2}
	elif s <= 49:
		return {"bracket": "30-49", "title": "Strefy skażenia i ataki obszarowe", "allow_ranged": true, "elite_wave": 3, "telegraph_sec": 0.90, "hazard_interval": 5.5, "boss_phases": 2}
	elif s <= 69:
		return {"bracket": "50-69", "title": "Wielofazowe starcia i opancerzone roje", "allow_ranged": true, "elite_wave": 3, "telegraph_sec": 0.85, "hazard_interval": 4.8, "boss_phases": 3}
	elif s <= 89:
		return {"bracket": "70-89", "title": "Zaawansowane mutatory i presja taktyczna", "allow_ranged": true, "elite_wave": 2, "telegraph_sec": 0.80, "hazard_interval": 4.2, "boss_phases": 3}
	else:
		return {"bracket": "90-100", "title": "Finałowe starcia o Rdzeń A-03", "allow_ranged": true, "elite_wave": 2, "telegraph_sec": 0.75, "hazard_interval": 3.8, "boss_phases": 3}

func calc_stage_hp_mult(stage_num: int) -> float:
	var s := float(clampi(stage_num, 1, 100))
	var ch_steps := floorf((s - 1.0) / 10.0)
	var bracket_spike := 1.15 if stage_num >= 30 else 1.0
	if stage_num >= 60:
		bracket_spike = 1.28
	return (1.0 + 0.052 * (s - 1.0)) * pow(1.13, ch_steps) * bracket_spike

func calc_stage_dmg_mult(stage_num: int) -> float:
	var s := float(clampi(stage_num, 1, 100))
	var ch_steps := floorf((s - 1.0) / 10.0)
	var bracket_spike := 1.12 if stage_num >= 30 else 1.0
	if stage_num >= 60:
		bracket_spike = 1.22
	return (1.0 + 0.034 * (s - 1.0)) * pow(1.075, ch_steps) * bracket_spike

func get_enemy_scaled_stats(enemy_id: String, stage_num: int, elapsed_sec: float, tier: String = "normal") -> Dictionary:
	var archetypes := {
		"biegacz": {"hp": 22.0, "dmg": 8.0, "speed": 142.0, "xp": 10},
		"zracy_pelzacz": {"hp": 32.0, "dmg": 10.0, "speed": 96.0, "xp": 14},
		"zdziczaly": {"hp": 62.0, "dmg": 15.0, "speed": 74.0, "xp": 24},
		"zarazony": {"hp": 26.0, "dmg": 9.0, "speed": 130.0, "xp": 12},
		"plujacy_kwasem": {"hp": 38.0, "dmg": 12.0, "speed": 88.0, "xp": 18},
		"lowca": {"hp": 48.0, "dmg": 15.0, "speed": 136.0, "xp": 20},
		"skrzydlaty": {"hp": 20.0, "dmg": 8.0, "speed": 152.0, "xp": 12},
		"czerw": {"hp": 44.0, "dmg": 11.0, "speed": 84.0, "xp": 16}
	}
	var base: Dictionary = archetypes.get(enemy_id, {"hp": 42.0, "dmg": 12.0, "speed": 100.0, "xp": 18})

	var diff := get_difficulty_profile()
	var t_hp := calc_time_hp_mult(elapsed_sec)
	var t_dmg := calc_time_dmg_mult(elapsed_sec)
	var s_hp := calc_stage_hp_mult(stage_num)
	var s_dmg := calc_stage_dmg_mult(stage_num)

	# Jeśli enemy_id jest w boss_and_elite_roster_v2.json, użyj jego oficjalnego base_hp i szablonów ataków!
	if v2_bosses.has(enemy_id):
		var b_spec: Dictionary = v2_bosses[enemy_id]
		var b_hp := float(b_spec.get("base_hp", 1800.0)) * float(diff.get("enemy_hp", 1.0)) * t_hp
		var b_dmg := roundf(16.0 * s_dmg * float(diff.get("enemy_dmg", 1.0)))
		return {
			"max_hp": maxf(120.0, roundf(b_hp)),
			"damage": maxf(8.0, b_dmg),
			"speed": 76.0 if tier == "boss" else 92.0,
			"xp_reward": 260 if tier == "boss" else 110,
			"tier": tier,
			"display_name": String(b_spec.get("name", enemy_id)),
			"attack_templates": b_spec.get("attack_templates", []),
			"phases": b_spec.get("phases", [1.0, 0.45])
		}

	var tier_hp := 1.0
	var tier_dmg := 1.0
	if tier == "elite":
		tier_hp = 3.2
		tier_dmg = 1.45
	elif tier == "miniboss":
		tier_hp = 8.5
		tier_dmg = 1.65
	elif tier == "boss":
		tier_hp = 24.0
		tier_dmg = 2.0

	var final_hp := roundf(float(base["hp"]) * t_hp * s_hp * float(diff.get("enemy_hp", 1.0)) * tier_hp)
	var final_dmg := roundf(float(base["dmg"]) * t_dmg * s_dmg * float(diff.get("enemy_dmg", 1.0)) * tier_dmg)
	var final_xp := int(roundf(float(base["xp"]) * float(diff.get("xp_gain", 1.0))))

	return {
		"max_hp": maxf(10.0, final_hp),
		"damage": maxf(2.0, final_dmg),
		"speed": float(base["speed"]),
		"xp_reward": maxi(5, final_xp),
		"tier": tier,
		"display_name": enemy_id,
		"attack_templates": [],
		"phases": [1.0]
	}

static func get_run_xp_needed(run_level: int) -> int:
	var l := maxi(1, run_level)
	return 20 + 8 * l + 2 * l * l

static func get_character_xp_needed(char_level: int) -> int:
	var c := float(maxi(1, char_level))
	return int(roundf(100.0 * pow(c, 1.35) + 40.0 * c))

func complete_stage_run(stage_num: int, victory: bool, waves_cleared: int) -> Dictionary:
	var diff := get_difficulty_profile()
	var reward_mult := float(diff.get("reward", 1.0))
	var cfg := get_stage_config(stage_num)
	var rewards_v2: Dictionary = cfg.get("rewards_v2", {}) if cfg.get("rewards_v2") is Dictionary else {}
	var raw_sc = rewards_v2.get("soft_credits")
	var raw_xp = rewards_v2.get("account_xp")
	var materials_v2: Dictionary = rewards_v2.get("materials", {}) if rewards_v2.get("materials") is Dictionary else {}
	var base_credits := float(raw_sc if (raw_sc is int or raw_sc is float) else (80 + 18 * stage_num)) * reward_mult
	var base_char_xp := float(raw_xp if (raw_xp is int or raw_xp is float) else (35 + 8 * stage_num)) * reward_mult

	var stage_key := str(stage_num)
	var mission_id := String(cfg.get("id", "MS_STORY_%03d" % stage_num))
	var class_first_clear_key := "%s_%03d" % [selected_class_id, stage_num]
	var is_class_first_clear := victory and (not first_clears_v2.has(class_first_clear_key))
	var is_first_clear := victory and (not cleared_stages.has(stage_key)) and (not bool(first_clears_v2.get(mission_id, false)))

	var earned_credits := 0
	var earned_xp := 0
	var earned_scrap := 0
	var unlocked_next := false
	var dropped_item: Dictionary = {}

	if is_practice_mode:
		# Practice costs 0 attempts and awards no persistent currency, XP or equipment.
		earned_credits = 0
		earned_xp = 0
	elif victory:
		var raw_rep = cfg.get("replay_credits_multiplier")
		var rep_mult := float(raw_rep) if (raw_rep is int or raw_rep is float) else 0.35
		var mult := 1.0 if is_first_clear else rep_mult
		earned_credits = int(roundf(base_credits * mult))
		earned_xp = int(roundf(base_char_xp * mult))
		earned_scrap = maxi(0, int(materials_v2.get("scrap", 2 + int(stage_num / 10)))) if is_first_clear else 1
		cleared_stages[stage_key] = 3
		first_clears_v2[mission_id] = true
		if is_class_first_clear:
			first_clears_v2[class_first_clear_key] = true
			if character_level < 100:
				character_level += 1

		var raw_unlock = cfg.get("mandatory_stage_unlock")
		var unlock_target := int(raw_unlock) if (raw_unlock is int or raw_unlock is float) else (stage_num + 1)
		unlock_target = mini(stage_num + 1, unlock_target) # sequential progression; never jump several stages
		if stage_num <= max_unlocked_stage and unlock_target > max_unlocked_stage and max_unlocked_stage < 100:
			max_unlocked_stage = mini(100, unlock_target)
			unlocked_next = true

		# Gwarantowany zrzut ekwipunku przy pierwszym ukończeniu lub losowy przy powtórce
		if is_first_clear or rng.randf() < 0.45:
			var forced_r := "rare" if (stage_num % 10 == 0) else ""
			dropped_item = roll_new_equipment_drop(stage_num, forced_r)
	else:
		# A failed run rewards only actually completed waves; zero-wave restarts pay zero.
		var wave_ratio := clampf(float(waves_cleared) / 10.0, 0.0, 1.0)
		earned_credits = int(roundf(base_credits * 0.10 * wave_ratio))
		earned_xp = int(roundf(base_char_xp * 0.10 * wave_ratio))

	if victory and not is_practice_mode:
		record_daily_mission_progress("complete_stage", 1)
	credits += earned_credits
	scrap_materials += earned_scrap
	battle_pass_xp += earned_xp
	add_character_xp(earned_xp)
	save_campaign_profile()

	return {
		"victory": victory,
		"stage": stage_num,
		"earned_credits": earned_credits,
		"earned_character_xp": earned_xp,
		"earned_scrap": earned_scrap,
		"is_first_clear": is_first_clear,
		"unlocked_next_stage": unlocked_next,
		"max_unlocked_stage": max_unlocked_stage,
		"character_level": character_level,
		"dropped_item": dropped_item
	}

func add_character_xp(amount: int) -> void:
	character_xp += maxi(0, amount)
	while character_level < 100:
		var req := get_character_xp_needed(character_level)
		if character_xp >= req:
			character_xp -= req
			character_level += 1
		else:
			break
