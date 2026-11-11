extends SceneTree

# Headless integration regression suite for Android Beta.
# Use a separate temporary save file; never modify real player data.
# Run: godot --headless --path . --script res://qa/gameplay_regression.gd

var failures: Array[String] = []
var checks: int = 0
var stage = null
var battle: Node = null

func _initialize() -> void:
	call_deferred("_run")

func _assert(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("GAMEPLAY FAIL: " + description)

func _run() -> void:
	# Give the autoloads time to complete their _ready() methods.
	await process_frame
	await process_frame
	stage = root.get_node_or_null("StageDirector")
	_assert(stage != null, "StageDirector autoload exists")
	if stage == null:
		_finish()
		return
	stage.get_script().set("save_path_override", "user://qa_gameplay_regression.json")
	var path: String = stage.get_active_save_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	_test_horde_performance_limits()
	_test_character_art_sequences()
	_test_enemy_art_sequences()
	_test_projectile_and_pickup_safety()
	_test_starter_gear()
	_test_equipment_and_save()
	_test_rarity_fusion_protection()
	_test_premium_chest_safety()
	_test_rewards()
	await _test_combat_and_bosses()
	# Test files live only inside the CI runner, never inside an APK.
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		var disposable: String = path + String(suffix)
		if FileAccess.file_exists(disposable):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(disposable))
	_finish()

func _test_character_art_sequences() -> void:
	_assert(AssetRegistry.PLAYER_ANIMATED_CLASSES.size() >= 4 and AssetRegistry.PLAYER_ANIMATED_CLASSES.has("soldier") and AssetRegistry.PLAYER_ANIMATED_CLASSES.has("engineer") and AssetRegistry.PLAYER_ANIMATED_CLASSES.has("medic") and AssetRegistry.PLAYER_ANIMATED_CLASSES.has("scout"), "Four base operator classes remain available alongside optional new operator skins")
	_assert(not String(AssetRegistry.SKIN_SPRITES.get("neon_hunter", "")).is_empty(), "Premium appearance has dedicated non-base artwork")
	_assert(not String(AssetRegistry.SKIN_SPRITES.get("hazmat_trooper", "")).is_empty(), "Hazmat cosmetic appearance has its own texture")
	for cls_id in AssetRegistry.PLAYER_ANIMATED_CLASSES:
		for action in AssetRegistry.PLAYER_ANIMATION_COUNTS.keys():
			var max_frame: int = int(AssetRegistry.PLAYER_ANIMATION_COUNTS[action])
			_assert(AssetRegistry.get_player_animation_frame(String(cls_id), String(action), 1) != null, "Initial %s %s frame exists" % [cls_id, action])
			_assert(AssetRegistry.get_player_animation_frame(String(cls_id), String(action), max_frame) != null, "Final %s %s frame exists" % [cls_id, action])
		_assert(AssetRegistry.get_player_animation_frame(String(cls_id), "shoot", 7) == null, "Invalid shoot frame is rejected")


func _test_enemy_art_sequences() -> void:
	_assert(AssetRegistry.MUTANT_ANIM_FOLDERS.size() >= 8, "At least eight mutant animation families remain available")
	for enemy_id in AssetRegistry.MUTANT_ANIM_FOLDERS.keys():
		var folder: String = String(AssetRegistry.MUTANT_ANIM_FOLDERS[enemy_id])
		_assert(AssetRegistry.get_tex("res://assets/enemies/%s/walk_1.png" % folder) != null, "Mutant walking visuals load: " + String(enemy_id))
		_assert(AssetRegistry.get_tex("res://assets/enemies/%s/attack_4.png" % folder) != null, "Mutant attack visuals load: " + String(enemy_id))
	for folder in ["boss_matka_roju", "boss_goliat", "boss_lewiatan"]:
		_assert(AssetRegistry.get_tex("res://assets/bosses/%s/death_2.png" % folder) != null, "Boss death sprite loads: " + folder)
	_assert(AssetRegistry.BOSS_CHAPTER_FALLBACK_KITS.size() >= 6, "All late chapter boss fallback art routes remain registered")
	_assert(not AssetRegistry.get_candidate_boss_directory("boss_ch04").is_empty(), "Chapter 4 boss uses a registered safe fallback/candidate directory")
	_assert(not AssetRegistry.get_candidate_boss_directory("boss_ch05").is_empty(), "First candidate boss folder is discoverable")
	_assert(AssetRegistry.get_candidate_boss_directory("boss_ch11").is_empty(), "Unknown chapter cannot load candidate art")
	_assert(not AssetRegistry.has_complete_chapter_boss_art("boss_ch11"), "Invalid boss cannot claim the optional artwork")
	_assert(AssetRegistry.get_campaign_boss_portrait("boss_ch11").is_empty(), "Unregistered boss cannot invent a portrait")
	for chapter in range(5, 11):
		var boss_id: String = "boss_ch%02d" % chapter
		_assert(AssetRegistry.BOSS_CHAPTER_FALLBACK_KITS.has(boss_id), "Boss chapter %d has reliable fallback routing" % chapter)
		var test_sprite := Sprite2D.new()
		var data: Dictionary = AssetRegistry.apply_enemy_visual(test_sprite, boss_id)
		var candidate_installed: bool = AssetRegistry.has_complete_chapter_boss_art(boss_id)
		var expected_walk: int = 4 if candidate_installed else 0
		var expected_death: int = 2 if candidate_installed else 0
		_assert(data.get("walk_frames", []).size() == expected_walk, "Boss %d uses complete movement frames or safe still" % chapter)
		_assert(data.get("attack_frames", []).size() == expected_walk, "Boss %d never uses fragmented fallback attacks" % chapter)
		_assert(data.get("death_frames", []).size() == expected_death, "Boss %d never uses fragmented fallback deaths" % chapter)
		_assert(test_sprite.texture != null, "Boss %d has a drawable texture" % chapter)
		_assert(float(data.get("base_scale", Vector2.ONE).x) > 0.30 and float(data.get("base_scale", Vector2.ONE).x) < 1.5, "Boss %d has sane normalized visual size" % chapter)
		_assert(bool(data.get("is_animated", true)) == candidate_installed, "Boss %d accurately reports whether motion is animated" % chapter)
		var expected_status: String = "BOSS_ART_CANDIDATE" if candidate_installed else "BOSS_STATIC_SAFE"
		_assert(String(data.get("status", "")) == expected_status, "Boss %d tracks candidate or fallback art accurately" % chapter)
		var portrait: String = AssetRegistry.get_campaign_boss_portrait(boss_id)
		_assert(ResourceLoader.exists(portrait, "Texture2D"), "Boss %d has a loadable campaign portrait" % chapter)
		test_sprite.free()


func _test_projectile_and_pickup_safety() -> void:
	# Load scripts at runtime to avoid class resolver preload cycles.
	var bolt_script: Script = load("res://scripts/plasma_bolt.gd") as Script
	var xp_script: Script = load("res://scripts/xp_shard.gd") as Script
	var saw_script: Script = load("res://scripts/vibro_saw.gd") as Script
	_assert(bolt_script != null and xp_script != null and saw_script != null, "Projectile, pickup and saw scripts load")
	if bolt_script == null or xp_script == null or saw_script == null:
		return
	var bolt: Node = bolt_script.new()
	_assert(not bool(bolt.get("has_hit")), "New projectile is unconsumed")
	bolt.set("has_hit", true)
	_assert(bool(bolt.get("has_hit")), "Projectile remembers first collision")
	bolt.free()
	var shard: Node = xp_script.new()
	_assert(not bool(shard.get("is_collected")), "XP shard starts unclaimed")
	shard.set("is_collected", true)
	_assert(bool(shard.get("is_collected")), "XP pickup tracks its single claim")
	shard.free()
	_assert(float(saw_script.get_script_constant_map().get("HIT_INTERVAL", 0.0)) >= 0.25, "Saw has a bounded per-target hit cooldown")


func _test_horde_performance_limits() -> void:
	var director_script: Script = load("res://addons/ms_beta/wave_director.gd") as Script
	_assert(director_script != null, "Wave director loads after StageDirector autoload")
	if director_script == null:
		return
	var director: Node = director_script.new()
	root.add_child(director)
	director.adaptive_density_enabled = false
	director.set_performance_profile(0)
	_assert(director.get_max_active_for_wave(1) == 14, "Low performance wave one respects low cap")
	director.set_performance_profile(2)
	_assert(director.get_max_active_for_wave(1) == 22, "High performance wave one retains high cap")
	_assert(director.get_max_active_for_wave(999) == 80, "Wave indexes above ten retain final-wave high cap")
	director.adaptive_density_enabled = true
	director.dynamic_cap_multiplier = 0.55
	director.set_performance_profile(0)
	_assert(director.get_max_active_for_wave(1) <= 14, "Adaptive low mode never exceeds base low-end cap")
	_assert(director._get_wave_archetype(1, 1) in director.EARLY_ARCHETYPES, "Beginner stages use early mutant roster")
	_assert(director._get_wave_archetype(50, 9) in director.LATE_ARCHETYPES, "Late waves use their intended mutant roster")
	director.start_wave(1, -30.0)
	_assert(int(director._last_wave_second) == 0, "Wave cache initializes even with zero duration")
	_assert(int(director.current_wave) == 1, "Wave remains valid after negative duration")
	_assert(director.wave_time_left == 0.0, "Negative wave duration clamps to zero")
	_assert(int(director.MAX_POOLED_PER_ARCHETYPE) == 24, "Inactive pool has 24-per-type ceiling")
	director.spawn_timer = 0.8
	director.recycle_all_enemies()
	_assert(director.spawn_timer == 0.0, "Cleanup resets spawn timer")
	_assert(director.dynamic_cap_multiplier == 1.0, "Cleanup resets performance scaling")
	_assert(director.enemy_pool.is_empty(), "Cleanup empties pool")
	_assert(director._last_wave_second == -1, "Cleanup resets HUD wave cache")
	_assert(director._last_density_count == -1, "Cleanup resets HUD density cache")
	_assert(director.active_enemies.is_empty(), "Cleanup empties active registry")
	# Verify HUD signals are not re-emitted for every 60 FPS update.
	var signal_counts := {"wave": 0, "density": 0}
	director.wave_changed.connect(func(_wave: int, _seconds: float, _max: int):
		signal_counts["wave"] += 1
	)
	director.horde_density_updated.connect(func(_active: int, _cap: int):
		signal_counts["density"] += 1
	)
	var dummy_player := Node2D.new()
	root.add_child(dummy_player)
	var dummy_layer := Node2D.new()
	root.add_child(dummy_layer)
	director.bind_context(null, dummy_layer, null)
	director.start_wave(1, 10.0)
	for frame in range(3):
		director.process_wave(0.05, dummy_player, 1, 0.0)
	_assert(int(signal_counts["wave"]) == 1, "Sub-second updates do not redraw wave text")
	_assert(int(signal_counts["density"]) == 1, "Unchanged enemy density emits once")
	_assert(director.active_enemies.is_empty(), "No enemies spawn without a battle scene registry")
	director.process_wave(1.0, dummy_player, 1, 1.0)
	_assert(int(signal_counts["wave"]) == 2, "Wave counter updates when countdown second changes")
	director.recycle_all_enemies()
	dummy_player.queue_free()
	dummy_layer.queue_free()
	director.queue_free()


func _test_starter_gear() -> void:
	stage.inventory = []
	stage.equipped_items = {}
	stage._ensure_starter_equipment()
	_assert(stage.inventory.size() == 4, "New account receives four basic items, not developer test loot")
	for item in stage.inventory:
		if item is Dictionary:
			_assert(String(item.get("rarity", "")) == "common", "Starter gear must be common rarity")
	_assert(stage.equipped_items.size() == 4, "Starter equipment is automatically equipped")

func _test_equipment_and_save() -> void:
	stage.inventory = [
		{"instance_id": "qa_weapon", "slot": "weapon", "rarity": "common", "name": "QA Weapon", "base_power": 20.0, "level": 0, "affixes": []},
		{"instance_id": "qa_helmet", "slot": "helmet", "rarity": "common", "name": "QA Helmet", "base_power": 10.0, "level": 0, "affixes": []}
	]
	stage.equipped_items = {}
	stage.credits = 300
	stage.scrap_materials = 20
	stage.dark_matter_gems = 25
	stage.character_level = 3
	stage.character_xp = 41
	stage.max_unlocked_stage = 1
	stage.current_stage = 1
	stage.selected_class_id = "soldier"
	stage.is_practice_mode = false
	stage.talent_levels = {}
	stage.cleared_stages = {}
	stage.first_clears_v2 = {}
	stage.daily_missions.clear()
	stage.daily_free_pack_claimed = false
	stage.daily_reset_day = int(Time.get_unix_time_from_system() / 86400)
	stage.equip_item("qa_weapon")
	_assert(String(stage.equipped_items.get("weapon", "")) == "qa_weapon", "Equip weapon assigns correct slot")
	stage.equip_item("qa_helmet")
	_assert(String(stage.equipped_items.get("helmet", "")) == "qa_helmet", "Equip helmet assigns correct slot")
	var old_power: float = stage.get_item_effective_power(stage.get_item_instance("qa_weapon"))
	var credits_before: int = stage.credits
	var scrap_before: int = stage.scrap_materials
	var upgraded: bool = stage.upgrade_item_by_instance("qa_weapon")
	_assert(upgraded, "Upgrade weapon succeeds with sufficient currency")
	_assert(stage.get_item_effective_power(stage.get_item_instance("qa_weapon")) > old_power, "Upgrade increases weapon power")
	_assert(stage.credits < credits_before and stage.scrap_materials < scrap_before, "Upgrade consumes resources")
	_assert(not stage.upgrade_item_by_instance("missing_item"), "Missing equipment cannot be upgraded")
	stage.unequip_slot("helmet")
	_assert(not stage.equipped_items.has("helmet"), "Unequip removes only requested equipment")
	stage.save_campaign_profile()
	_assert(FileAccess.file_exists(stage.get_active_save_path()), "Campaign save file exists")
	stage.credits = 1
	stage.inventory.clear()
	stage.equipped_items.clear()
	stage.load_campaign_profile()
	_assert(stage.credits == credits_before - 45, "Save/load restores credits")
	_assert(not stage.get_item_instance("qa_weapon").is_empty(), "Save/load restores inventory")
	_assert(String(stage.equipped_items.get("weapon", "")) == "qa_weapon", "Save/load restores equipped weapon")
	_assert(int(stage.get_item_instance("qa_weapon").get("level", -1)) == 1, "Save/load restores upgrade level")
	# Preserve a valid .bak, then corrupt only the disposable QA primary file.
	stage.save_campaign_profile()
	var credits_safe: int = stage.credits
	var corrupt_file := FileAccess.open(stage.get_active_save_path(), FileAccess.WRITE)
	_assert(corrupt_file != null, "Can open temporary QA save for corruption test")
	if corrupt_file:
		corrupt_file.store_string("{invalid json")
		corrupt_file.close()
	stage.credits = 0
	stage.load_campaign_profile()
	_assert(stage.credits == credits_safe, "Corrupted save recovers last valid campaign backup")
	# Syntactically valid but incomplete JSON must also restore the backup.
	var incomplete_file := FileAccess.open(stage.get_active_save_path(), FileAccess.WRITE)
	_assert(incomplete_file != null, "Can stage incomplete campaign JSON")
	if incomplete_file:
		incomplete_file.store_string('{"credits": 1, "current_stage": 1}')
		incomplete_file.close()
	_assert(stage._parse_save_dictionary('{"credits": 1, "current_stage": 1}').is_empty(),
		"Incomplete valid JSON is rejected as a campaign profile")
	_assert(stage._parse_save_dictionary('{"current_stage": 3, "max_unlocked_stage": 2, "credits": 20}').is_empty(),
		"Selected stage beyond unlocks is rejected as corrupted save data")
	_assert(stage._parse_save_dictionary('{"current_stage": 1, "max_unlocked_stage": 1, "credits": -500}').is_empty(),
		"Negative wallet values are rejected as corrupted save data")
	stage.credits = 0
	stage.load_campaign_profile()
	_assert(stage.credits == credits_safe, "Incomplete JSON restores verified backup rather than resetting credits")
	_assert(not stage.get_item_instance("qa_weapon").is_empty(), "Backup restores equipment after corruption")
	# Interrupted transactional writes: only .tmp remains valid and the
	# primary is corrupt. Keep real player data untouched (qa override).
	var save_path: String = stage.get_active_save_path()
	var current_valid: String = FileAccess.get_file_as_string(save_path + ".bak")
	_assert(not current_valid.is_empty(), "Backup is populated with a valid previous save")
	stage._remove_save_path(save_path + ".bak")
	var staged_file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	_assert(staged_file != null, "Interrupted-write fixture can be created")
	if staged_file:
		staged_file.store_string(current_valid)
		staged_file.close()
	stage.credits = 0
	stage.load_campaign_profile()
	_assert(stage.credits == credits_safe, "Interrupted write loads complete staged JSON")
	_assert(not stage.get_item_instance("qa_weapon").is_empty(), "Interrupted write recovers equipped item data")
	# Saving again promotes the recovered data to the primary file.
	stage.save_campaign_profile()
	_assert(not stage._parse_save_dictionary(FileAccess.get_file_as_string(save_path)).is_empty(), "Recovery rewrites validated primary save")
	_assert(not FileAccess.file_exists(save_path + ".tmp"), "Successful save consumes pending transaction")
	# Ensure stale .tmp cannot override a valid primary or its backup.
	var stale := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if stale:
		stale.store_string('{ "credits": 1, "current_stage": 1 }')
		stale.close()
	stage.credits = 0
	stage.load_campaign_profile()
	_assert(stage.credits == credits_safe, "Valid primary outranks stale temporary save")
	stage._remove_save_path(save_path + ".tmp")
	# Daily pack can be claimed once per UTC day, then returns after the date changes.
	stage.daily_reset_day = int(Time.get_unix_time_from_system() / 86400)
	stage.daily_free_pack_claimed = false
	var daily_start_credits: int = stage.credits
	_assert(stage.claim_daily_free_shop_pack(), "First daily pack claim succeeds")
	_assert(not stage.claim_daily_free_shop_pack(), "Second daily pack claim same day is rejected")
	_assert(stage.credits == daily_start_credits + 150, "Daily pack cannot pay twice in same UTC day")
	stage.daily_reset_day -= 1
	_assert(stage.claim_daily_free_shop_pack(), "Daily pack resets on a new UTC day")
	_assert(stage.credits == daily_start_credits + 300, "Daily pack pays once after day reset")
	stage.save_campaign_profile()
	stage.daily_free_pack_claimed = false
	stage.load_campaign_profile()
	_assert(stage.daily_free_pack_claimed, "Daily pack claim state survives save/load")

func _test_rarity_fusion_protection() -> void:
	# Rare gear begins at stage 7 and epic gear at 22. Fusion cannot
	# downgrade a guaranteed outcome or destroy inputs at an early stage.
	stage.inventory = [
		{"instance_id": "fuse_a", "slot": "weapon", "rarity": "common", "name": "Fusion A", "base_power": 10.0, "level": 0, "affixes": []},
		{"instance_id": "fuse_b", "slot": "helmet", "rarity": "common", "name": "Fusion B", "base_power": 10.0, "level": 0, "affixes": []},
		{"instance_id": "fuse_c", "slot": "boots", "rarity": "common", "name": "Fusion C", "base_power": 10.0, "level": 0, "affixes": []}
	]
	stage.equipped_items = {"weapon": "fuse_a"}
	stage.max_unlocked_stage = 1
	var count_before: int = stage.inventory.size()
	var forced_result: Dictionary = stage.roll_new_equipment_drop(1, "rare")
	_assert(forced_result.is_empty(), "Forced rare drop unavailable at stage 1 never downgrades")
	_assert(stage.inventory.size() == count_before, "Invalid forced rarity does not add wrong item")
	var result: Dictionary = stage.fuse_equipment_triplet("fuse_a", "fuse_b", "fuse_c")
	_assert(result.is_empty(), "Fusion cannot create an unavailable rare at stage 1")
	_assert(stage.inventory.size() == count_before, "Failed fusion preserves all three components")
	_assert(String(stage.equipped_items.get("weapon", "")) == "fuse_a", "Failed fusion preserves equipped item")
	stage.max_unlocked_stage = 7
	result = stage.fuse_equipment_triplet("fuse_a", "fuse_b", "fuse_c")
	_assert(not result.is_empty(), "Three common items can fuse to rare at stage 7")
	_assert(String(result.get("rarity", "")) == "rare", "Fusion gives exactly rare, never common")
	_assert(stage.inventory.size() == 1, "Successful fusion replaces three inputs with one item")
	_assert(not stage.equipped_items.has("weapon"), "Successful fusion unequips consumed item")

func _test_premium_chest_safety() -> void:
	# A 50th chest at stage 1 cannot contain the guaranteed legendary
	# (legendary templates begin at stage 47). It must cost nothing and
	# keep the pity guarantee for a later eligible stage.
	stage.max_unlocked_stage = 1
	stage.dark_matter_gems = 100
	stage.beta_test_gems_remaining = 0
	stage.pity_chest_counter = 49
	var items_before: int = stage.inventory.size()
	var item: Dictionary = stage.open_purchased_chest(50)
	_assert(item.is_empty(), "Locked guaranteed legendary chest refuses early-stage purchase")
	_assert(stage.dark_matter_gems == 100, "Rejected chest never charges premium currency")
	_assert(stage.pity_chest_counter == 49, "Rejected guaranteed chest preserves pity count")
	_assert(stage.inventory.size() == items_before, "Rejected chest does not add junk loot")
	stage.max_unlocked_stage = 47
	item = stage.open_purchased_chest(50)
	_assert(not item.is_empty(), "Guaranteed legendary chest unlocks on stage 47")
	_assert(String(item.get("rarity", "")) == "legendary", "Pity chest awards promised legendary rarity")
	_assert(stage.dark_matter_gems == 50, "Successful chest charges once")
	_assert(stage.pity_chest_counter == 0, "Successful pity chest resets guarantee")

func _test_rewards() -> void:
	# Practice wins and losses must never grant persistent rewards.
	stage.credits = 500
	stage.dark_matter_gems = 25
	stage.scrap_materials = 20
	stage.character_level = 3
	stage.character_xp = 0
	stage.max_unlocked_stage = 1
	stage.cleared_stages = {}
	stage.first_clears_v2 = {}
	stage.is_practice_mode = true
	var practice_inventory_count: int = stage.inventory.size()
	var practice: Dictionary = stage.complete_stage_run(1, true, 10)
	_assert(int(practice.get("earned_credits", -1)) == 0 and int(practice.get("earned_character_xp", -1)) == 0, "Practice grants no credits or character XP")
	_assert(stage.credits == 500 and stage.character_xp == 0, "Practice leaves persistent rewards unchanged")
	_assert(stage.inventory.size() == practice_inventory_count and stage.max_unlocked_stage == 1, "Practice does not drop equipment or unlock next stage")

	stage.is_practice_mode = false
	var empty_loss: Dictionary = stage.complete_stage_run(1, false, 0)
	_assert(int(empty_loss.get("earned_credits", -1)) == 0 and int(empty_loss.get("earned_character_xp", -1)) == 0, "Zero-wave loss grants zero rewards")
	var victory: Dictionary = stage.complete_stage_run(1, true, 10)
	_assert(bool(victory.get("victory", false)), "Stage win reported as victory")
	_assert(int(victory.get("earned_credits", 0)) > 0, "First clear grants credits")
	_assert(stage.max_unlocked_stage == 2, "First clear unlocks precisely next stage")
	_assert(stage.cleared_stages.has("1"), "First clear is recorded")
	var repeat: Dictionary = stage.complete_stage_run(1, true, 10)
	_assert(not bool(repeat.get("is_first_clear", true)), "Replay does not repeat first-clear entitlement")
	_assert(stage.max_unlocked_stage == 2, "Replay cannot skip further stages")

func _get_daily_progress(mission_id: String) -> int:
	for entry in stage.daily_missions:
		if entry is Dictionary and String(entry.get("id", "")) == mission_id:
			return int(entry.get("progress", 0))
	return 0

func _test_combat_and_bosses() -> void:
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	_assert(packed != null, "Battle scene loads")
	if packed == null:
		return
	stage.is_practice_mode = true
	stage.current_stage = 1
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	_assert(battle.get("wave_director") != null, "Wave director initialized")
	_assert(is_instance_valid(battle.get("player")), "Player initialized in battle")
	_assert(int(battle.get("current_wave_num")) == 1, "Battle starts at wave 1")
	# Avoid eagerly resolving Player during SceneTree --script compilation:
	# Player -> PowerEffects -> MutantEnemy loads StageDirector before autoload
	# singleton registration on clean CI runners.
	var live_player = battle.get("player")
	if is_instance_valid(live_player):
		_assert(not live_player.has_toxic_mines, "Toxic mines start locked")
		battle.call("apply_upgrade", "bio_hazard")
		_assert(live_player.has_toxic_mines and live_player.toxic_mine_tier == 1, "Toxic mine card unlocks real proximity mines")
		battle.call("apply_upgrade", "bio_hazard")
		_assert(live_player.toxic_mine_tier == 2 and live_player.toxic_mine_timer <= 0.7, "Second toxic mine card improves damage and deployment rate")
	_assert(bool(battle.call("_stage_requires_final_boss")), "Tutorial stage one intentionally contains a boss")
	# Stop automatic time progression while exercising deterministic wave transitions.
	battle.set_process(false)
	var kills_before: int = _get_daily_progress("kill_mutants")
	battle.call("spawn_wave_enemy")
	var enemies: Array[Node] = get_nodes_in_group("enemies")
	_assert(not enemies.is_empty(), "Wave spawns a real mutant")
	if not enemies.is_empty():
		var mutant = enemies[0]
		if is_instance_valid(mutant):
			mutant.take_damage(mutant.max_health + 500.0)
			_assert(_get_daily_progress("kill_mutants") == kills_before + 1, "One mutant death counts as exactly one daily kill")
			mutant.take_damage(100.0)
			_assert(_get_daily_progress("kill_mutants") == kills_before + 1, "Dead mutant cannot grant a second kill")
			_assert(mutant.impact_fx_cooldown >= 0.0, "Impact visual cooldown is valid after enemy death")
			_assert(mutant.current_health == 0.0, "Dead mutant health is clamped at zero")
			_assert(not mutant.is_telegraphing, "Death cancels telegraphed attack")
			_assert(int(battle.get("enemies_killed_in_run")) == 1, "Mutant death updates run kill counter")
	battle.call("start_wave", 1, 5)
	_assert(int(battle.get("current_wave_num")) == 5, "Wave 5 can be started")
	_assert(is_instance_valid(battle.get("active_boss")), "Wave 5 spawns a miniboss")
	if is_instance_valid(battle.get("active_boss")):
		_assert(String(battle.get("active_boss").tier) == "miniboss", "Wave 5 enemy has miniboss tier")
	battle.call("start_wave", 1, 10)
	_assert(int(battle.get("current_wave_num")) == 10, "Wave 10 can be started")
	_assert(is_instance_valid(battle.get("active_boss")), "Wave 10 spawns a boss")
	if is_instance_valid(battle.get("active_boss")):
		_assert(String(battle.get("active_boss").tier) == "boss", "Wave 10 enemy has boss tier")
		_assert(battle.get("active_boss").special_cooldown > 0.0, "Boss special attack cooldown remains valid")
		_assert(int(battle.get("active_boss").boss_phase) == 1, "Boss starts in phase one")
		_assert(battle.get("active_boss").max_health > 0.0, "Boss HP has a valid scale")
		_assert(battle.get("active_boss").sheet_fps >= 1.0, "Boss animation frame rate is always valid")
		_assert(battle.get("active_boss").telegraph_duration >= 0.20, "Boss warning provides enough time for mobile controls")
	battle.set("primary_objective_done", true)
	battle.set("wave_time_left", 0.0)
	battle.set("boss_spawned_this_run", true)
	battle.set("boss_killed_this_run", false)
	_assert(not bool(battle.call("_can_claim_victory")), "Cannot win while the final boss lives")
	battle.set("boss_spawned_this_run", false)
	battle.set("boss_killed_this_run", false)
	_assert(not bool(battle.call("_can_claim_victory")), "Missing final boss can never be bypassed")
	battle.call("_on_stage_victory")
	_assert(String(battle.get("run_result_state")) == "active", "No reward transition without spawned boss")
	battle.set("boss_spawned_this_run", true)
	var final_boss = battle.get("active_boss")
	if is_instance_valid(final_boss):
		final_boss.take_damage(final_boss.max_health + 500.0)
	_assert(bool(battle.get("boss_killed_this_run")), "Killing final boss updates victory requirement")
	_assert(bool(battle.call("_can_claim_victory")), "Win is possible after boss and objective completion")
	# Exercise the actual victory screen/state without spending attempts or granting rewards.
	battle.call("_on_stage_victory")
	_assert(String(battle.get("run_result_state")) == "victory", "Victory transitions into victory state")
	_assert((battle.get("win_panel") as Control).visible, "Victory panel becomes visible")
	battle.call("_on_stage_victory")
	_assert(String(battle.get("run_result_state")) == "victory", "Repeated victory callback cannot restart stage completion")
	_assert(not bool(battle.call("_can_claim_victory")), "Victory becomes terminal immediately")
	paused = false
	battle.queue_free()
	await process_frame

	stage.is_practice_mode = true
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.call("_on_player_died")
	_assert(String(battle.get("run_result_state")) == "awaiting_revive", "Defeat transitions into revive state")
	var visible_defeat: Control = battle.get("defeat_overlay_inst") as Control
	if not is_instance_valid(visible_defeat):
		visible_defeat = battle.get("death_panel") as Control
	_assert(is_instance_valid(visible_defeat) and visible_defeat.visible, "Actual production defeat overlay becomes visible")
	battle.call("_on_player_died")
	_assert(String(battle.get("run_result_state")) == "awaiting_revive", "Repeated player death cannot finalize run prematurely")
	battle.call("_finalize_failure_once")
	_assert(String(battle.get("run_result_state")) == "failure_final", "Abandoning revive finalizes defeat exactly once")
	battle.call("_finalize_failure_once")
	_assert(String(battle.get("run_result_state")) == "failure_final", "Repeated failure callback cannot reopen rewards")
	battle.call("_on_player_died")
	_assert(String(battle.get("run_result_state")) == "failure_final", "Dead run cannot re-enter revive state")
	paused = false
	battle.queue_free()
	await process_frame

	# Instantiate the final chapter's real scene and final boss, not only stage 1.
	stage.current_stage = 100
	stage.max_unlocked_stage = 100
	stage.is_practice_mode = true
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	_assert(int(battle.get("current_stage_num")) == 100, "Final campaign stage 100 starts")
	battle.call("start_wave", 100, 10)
	var end_boss = battle.get("active_boss")
	_assert(is_instance_valid(end_boss), "Final stage 100 spawns its boss")
	if is_instance_valid(end_boss):
		_assert(String(end_boss.enemy_id) == "boss_ch10", "Final boss is Architekt Zero archetype")
		_assert(end_boss.max_health > 0.0, "Final boss has positive scaled HP")
	battle.set("primary_objective_done", true)
	battle.set("wave_time_left", 0.0)
	_assert(not bool(battle.call("_can_claim_victory")), "Stage 100 cannot win before final boss defeat")
	battle.set("boss_spawned_this_run", false)
	battle.set("boss_killed_this_run", false)
	_assert(not bool(battle.call("_can_claim_victory")), "Stage 100 cannot skip an unspawned Architekt Zero")
	paused = false
	battle.queue_free()
	await process_frame

func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("GAMEPLAY REGRESSION PASS: %d checks; still requires Android device QA" % checks)
		quit(0)
	else:
		for msg in failures:
			printerr("GAMEPLAY REGRESSION FAIL: " + msg)
		printerr("GAMEPLAY REGRESSION FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)
