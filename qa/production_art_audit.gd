extends SceneTree

# Sprint 4 / 5: catch genuinely missing renderable art and report all sprites
# that are still static references rather than production animations.
# A PASS here means resources exist, NOT that art is launch-quality.
var checks: int = 0
var missing: Array[String] = []
var static_references: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(path: String, label: String) -> void:
	checks += 1
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		missing.append("%s: %s" % [label, path])
		printerr("ART FAIL: " + label + ": " + path)

func _run() -> void:
	await process_frame
	_check("res://assets/ui/target_theme/icon_mutant_survivor.svg", "Branded project icon")
	for talent_id in ["vitality", "firepower", "scanner", "armor_plating"]:
		_check("res://assets/ui/talents/%s.svg" % talent_id, "Illustrated talent " + talent_id)
	for product_id in ["skin_neon_hunter", "skin_hazmat_trooper", "skin_crimson_storm", "skin_void_sniper", "attempts_refill_full", "crystals_pack_500"]:
		_check("res://assets/ui/store_emblems/%s.svg" % product_id, "Illustrated store emblem " + product_id)
	for item_id in AssetRegistry.EQUIPMENT_SLOT_ICONS:
		_check(String(AssetRegistry.EQUIPMENT_SLOT_ICONS[item_id]), "Gear placeholder " + String(item_id))
	for boss_id in AssetRegistry.BOSS_CAMPAIGN_PORTRAITS:
		_check(String(AssetRegistry.BOSS_CAMPAIGN_PORTRAITS[boss_id]), "Boss campaign emblem " + String(boss_id))
	for key in AssetRegistry.CHARACTER_ASSETS.keys():
		var item: Dictionary = AssetRegistry.CHARACTER_ASSETS[key]
		_check(String(item.get("fallback_path", "")), "Operator %s" % key)
		if AssetRegistry.PLAYER_ANIMATED_CLASSES.has(String(key)):
			for action in AssetRegistry.PLAYER_ANIMATION_COUNTS.keys():
				for frame in range(1, int(AssetRegistry.PLAYER_ANIMATION_COUNTS[action]) + 1):
					_check("res://assets/characters/%s/%s_%d.png" % [key, action, frame], "%s %s frame %d" % [key, action, frame])
		else:
			static_references.append("Operator %s: missing dedicated animated sequence" % key)

	for enemy_id in AssetRegistry.MUTANT_ANIM_FOLDERS.keys():
		var folder: String = String(AssetRegistry.MUTANT_ANIM_FOLDERS[enemy_id])
		for idx in range(1, 5):
			_check("res://assets/enemies/%s/walk_%d.png" % [folder, idx], "%s walking %d" % [enemy_id, idx])
			_check("res://assets/enemies/%s/attack_%d.png" % [folder, idx], "%s attacking %d" % [enemy_id, idx])
	for chapter in range(5, 11):
		var boss_id: String = "boss_ch%02d" % chapter
		if AssetRegistry.has_complete_chapter_boss_art(boss_id):
			var root_path: String = AssetRegistry.get_candidate_boss_directory(boss_id)
			_check(root_path + "boss_portrait.png", boss_id + " portrait")
			for frame in range(1, 5):
				_check(root_path + "phase1_anim_%d.png" % frame, boss_id + " walk")
				_check(root_path + "phase2_attack_%d.png" % frame, boss_id + " attack")
			for frame in range(1, 3):
				_check(root_path + "death_%d.png" % frame, boss_id + " death")
		else:
			static_references.append(boss_id + ": generated character art not installed; stable HD fallback active")
	static_references.append("Legacy chapter 1–4 boss motion PNGs are fragmented: static full-portrait safety mode active")
	for boss_folder in ["boss_matka_roju", "boss_goliat", "boss_lewiatan"]:
		for idx in range(1, 5):
			_check("res://assets/bosses/%s/phase1_anim_%d.png" % [boss_folder, idx], "%s movement %d" % [boss_folder, idx])
			_check("res://assets/bosses/%s/phase2_attack_%d.png" % [boss_folder, idx], "%s attack %d" % [boss_folder, idx])
		for idx in range(1, 3):
			_check("res://assets/bosses/%s/death_%d.png" % [boss_folder, idx], "%s death %d" % [boss_folder, idx])
	for key in AssetRegistry.ENEMY_ASSETS.keys():
		var item: Dictionary = AssetRegistry.ENEMY_ASSETS[key]
		_check(String(item.get("texture_path", "")), "Enemy %s" % key)
		if String(item.get("status", "")) == "HD_STATIC_RGBA":
			# A static fallback in ENEMY_ASSETS does not imply gameplay is
			# static: several mutants already use a complete animated folder.
			var animated: bool = false
			if AssetRegistry.MUTANT_ANIM_FOLDERS.has(String(key)):
				var folder: String = String(AssetRegistry.MUTANT_ANIM_FOLDERS[key])
				animated = true
				for frame in range(1, 5):
					animated = animated and ResourceLoader.exists("res://assets/enemies/%s/walk_%d.png" % [folder, frame], "Texture2D")
					animated = animated and ResourceLoader.exists("res://assets/enemies/%s/attack_%d.png" % [folder, frame], "Texture2D")
			elif AssetRegistry.BOSS_CHAPTER_FALLBACK_KITS.has(String(key)):
				animated = AssetRegistry.has_complete_chapter_boss_art(String(key))
			if not animated:
				static_references.append("Enemy %s: still a static reference sprite" % key)

	for biome in AssetRegistry.BIOME_PALETTES.keys():
		var palette: Dictionary = AssetRegistry.BIOME_PALETTES[biome]
		for tile in palette.get("tiles", []):
			_check("res://assets/mutantsurvivor_ch01/tiles/%s.png" % String(tile), "%s floor %s" % [biome, tile])

	print("PRODUCTION ART AUDIT: %d renderable paths checked, %d absent assets, %d static art/animation blockers" % [checks, missing.size(), static_references.size()])
	for issue in static_references:
		print("ART NOT FINAL: " + issue)
	if missing.is_empty():
		print("ART RESOURCES PASS: no missing referenced art; static references still require replacement.")
		quit(0)
	else:
		printerr("ART RESOURCES FAILED: %d missing assets" % missing.size())
		quit(1)
