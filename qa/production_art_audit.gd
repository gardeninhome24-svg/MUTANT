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
	for item_id in AssetRegistry.EQUIPMENT_SLOT_ICONS:
		_check(String(AssetRegistry.EQUIPMENT_SLOT_ICONS[item_id]), "Gear placeholder " + String(item_id))
	for boss_id in AssetRegistry.BOSS_CAMPAIGN_PORTRAITS:
		_check(String(AssetRegistry.BOSS_CAMPAIGN_PORTRAITS[boss_id]), "Boss campaign emblem " + String(boss_id))
	for key in AssetRegistry.CHARACTER_ASSETS.keys():
		var item: Dictionary = AssetRegistry.CHARACTER_ASSETS[key]
		_check(String(item.get("fallback_path", "")), "Operator %s" % key)
		if String(item.get("sheet_path", "")).is_empty():
			static_references.append("Operator %s: no animated atlas" % key)

	for key in AssetRegistry.ENEMY_ASSETS.keys():
		var item: Dictionary = AssetRegistry.ENEMY_ASSETS[key]
		_check(String(item.get("texture_path", "")), "Enemy %s" % key)
		if String(item.get("status", "")) == "HD_STATIC_RGBA":
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
