extends SceneTree

# Headless integration regression suite for Android Beta.
# Use a separate temporary save file; never modify real player data.
# Run: godot --headless --path . --script res://qa/gameplay_regression.gd

var failures: Array[String] = []
var checks: int = 0
var stage: Node = null
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
	StageDirector.save_path_override = "user://qa_gameplay_regression.json"
	var path: String = StageDirector.get_active_save_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	_test_equipment_and_save()
	_test_rewards()
	await _test_combat_and_bosses()
	# Test files live only inside the CI runner, never inside an APK.
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_finish()

func _test_equipment_and_save() -> void:
	StageDirector.inventory = [
		{"instance_id": "qa_weapon", "slot": "weapon", "rarity": "common", "name": "QA Weapon", "base_power": 20.0, "level": 0, "affixes": []},
		{"instance_id": "qa_helmet", "slot": "helmet", "rarity": "common", "name": "QA Helmet", "base_power": 10.0, "level": 0, "affixes": []}
	]
	StageDirector.equipped_items = {}
	StageDirector.credits = 300
	StageDirector.scrap_materials = 20
	StageDirector.dark_matter_gems = 25
	StageDirector.character_level = 3
	StageDirector.character_xp = 41
	StageDirector.max_unlocked_stage = 1
	StageDirector.current_stage = 1
	StageDirector.selected_class_id = "soldier"
	StageDirector.is_practice_mode = false
	StageDirector.talent_levels = {}
	StageDirector.cleared_stages = {}
	StageDirector.first_clears_v2 = {}
	StageDirector.daily_missions.clear()
	StageDirector.daily_free_pack_claimed = false
	StageDirector.daily_reset_day = int(Time.get_unix_time_from_system() / 86400)
	StageDirector.equip_item("qa_weapon")
	_assert(String(StageDirector.equipped_items.get("weapon", "")) == "qa_weapon", "Equip weapon assigns correct slot")
	StageDirector.equip_item("qa_helmet")
	_assert(String(StageDirector.equipped_items.get("helmet", "")) == "qa_helmet", "Equip helmet assigns correct slot")
	var old_power: float = StageDirector.get_item_effective_power(StageDirector.get_item_instance("qa_weapon"))
	var credits_before: int = StageDirector.credits
	var scrap_before: int = StageDirector.scrap_materials
	var upgraded: bool = StageDirector.upgrade_item_by_instance("qa_weapon")
	_assert(upgraded, "Upgrade weapon succeeds with sufficient currency")
	_assert(StageDirector.get_item_effective_power(StageDirector.get_item_instance("qa_weapon")) > old_power, "Upgrade increases weapon power")
	_assert(StageDirector.credits < credits_before and StageDirector.scrap_materials < scrap_before, "Upgrade consumes resources")
	_assert(not StageDirector.upgrade_item_by_instance("missing_item"), "Missing equipment cannot be upgraded")
	StageDirector.unequip_slot("helmet")
	_assert(not StageDirector.equipped_items.has("helmet"), "Unequip removes only requested equipment")
	StageDirector.save_campaign_profile()
	_assert(FileAccess.file_exists(StageDirector.get_active_save_path()), "Campaign save file exists")
	StageDirector.credits = 1
	StageDirector.inventory.clear()
	StageDirector.equipped_items.clear()
	StageDirector.load_campaign_profile()
	_assert(StageDirector.credits == credits_before - 45, "Save/load restores credits")
	_assert(not StageDirector.get_item_instance("qa_weapon").is_empty(), "Save/load restores inventory")
	_assert(String(StageDirector.equipped_items.get("weapon", "")) == "qa_weapon", "Save/load restores equipped weapon")
	_assert(int(StageDirector.get_item_instance("qa_weapon").get("level", -1)) == 1, "Save/load restores upgrade level")

func _test_rewards() -> void:
	# Practice wins and losses must never grant persistent rewards.
	StageDirector.credits = 500
	StageDirector.dark_matter_gems = 25
	StageDirector.scrap_materials = 20
	StageDirector.character_level = 3
	StageDirector.character_xp = 0
	StageDirector.max_unlocked_stage = 1
	StageDirector.cleared_stages = {}
	StageDirector.first_clears_v2 = {}
	StageDirector.is_practice_mode = true
	var practice_inventory_count: int = StageDirector.inventory.size()
	var practice: Dictionary = StageDirector.complete_stage_run(1, true, 10)
	_assert(int(practice.get("earned_credits", -1)) == 0 and int(practice.get("earned_character_xp", -1)) == 0, "Practice grants no credits or character XP")
	_assert(StageDirector.credits == 500 and StageDirector.character_xp == 0, "Practice leaves persistent rewards unchanged")
	_assert(StageDirector.inventory.size() == practice_inventory_count and StageDirector.max_unlocked_stage == 1, "Practice does not drop equipment or unlock next stage")

	StageDirector.is_practice_mode = false
	var empty_loss: Dictionary = StageDirector.complete_stage_run(1, false, 0)
	_assert(int(empty_loss.get("earned_credits", -1)) == 0 and int(empty_loss.get("earned_character_xp", -1)) == 0, "Zero-wave loss grants zero rewards")
	var victory: Dictionary = StageDirector.complete_stage_run(1, true, 10)
	_assert(bool(victory.get("victory", false)), "Stage win reported as victory")
	_assert(int(victory.get("earned_credits", 0)) > 0, "First clear grants credits")
	_assert(StageDirector.max_unlocked_stage == 2, "First clear unlocks precisely next stage")
	_assert(StageDirector.cleared_stages.has("1"), "First clear is recorded")
	var repeat: Dictionary = StageDirector.complete_stage_run(1, true, 10)
	_assert(not bool(repeat.get("is_first_clear", true)), "Replay does not repeat first-clear entitlement")
	_assert(StageDirector.max_unlocked_stage == 2, "Replay cannot skip further stages")

func _test_combat_and_bosses() -> void:
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	_assert(packed != null, "Battle scene loads")
	if packed == null:
		return
	StageDirector.is_practice_mode = true
	StageDirector.current_stage = 1
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	_assert(battle.get("wave_director") != null, "Wave director initialized")
	_assert(is_instance_valid(battle.get("player")), "Player initialized in battle")
	_assert(int(battle.get("current_wave_num")) == 1, "Battle starts at wave 1")
	# Stop automatic time progression while exercising deterministic wave transitions.
	battle.set_process(false)
	battle.call("start_wave", 1, 5)
	_assert(int(battle.get("current_wave_num")) == 5, "Wave 5 can be started")
	_assert(is_instance_valid(battle.get("active_boss")), "Wave 5 spawns a miniboss")
	if is_instance_valid(battle.get("active_boss")):
		_assert(String((battle.get("active_boss") as MutantEnemy).tier) == "miniboss", "Wave 5 enemy has miniboss tier")
	battle.call("start_wave", 1, 10)
	_assert(int(battle.get("current_wave_num")) == 10, "Wave 10 can be started")
	_assert(is_instance_valid(battle.get("active_boss")), "Wave 10 spawns a boss")
	if is_instance_valid(battle.get("active_boss")):
		_assert(String((battle.get("active_boss") as MutantEnemy).tier) == "boss", "Wave 10 enemy has boss tier")
	battle.set("primary_objective_done", true)
	battle.set("wave_time_left", 0.0)
	battle.set("boss_spawned_this_run", true)
	battle.set("boss_killed_this_run", false)
	_assert(not bool(battle.call("_can_claim_victory")), "Cannot win while the final boss lives")
	battle.set("boss_killed_this_run", true)
	_assert(bool(battle.call("_can_claim_victory")), "Win is possible after boss and objective completion")
	# Exercise the actual victory screen/state without spending attempts or granting rewards.
	battle.call("_on_stage_victory")
	_assert(String(battle.get("run_result_state")) == "victory", "Victory transitions into victory state")
	_assert((battle.get("win_panel") as Control).visible, "Victory panel becomes visible")
	paused = false
	battle.queue_free()
	await process_frame

	StageDirector.is_practice_mode = true
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.call("_on_player_died")
	_assert(String(battle.get("run_result_state")) == "awaiting_revive", "Defeat transitions into revive state")
	_assert((battle.get("death_panel") as Control).visible, "Defeat panel becomes visible")
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
