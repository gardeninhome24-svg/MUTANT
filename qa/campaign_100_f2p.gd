extends SceneTree

# Non-interactive 100-stage *progression/economy* regression for Android beta.
# Does not pretend to play actual encounters or model player victory probability.
# No sandbox top-ups, premium refills or real money. Uses a disposable save.
var stage = null
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("F2P FAIL: " + message)

func _run() -> void:
	await process_frame
	await process_frame
	stage = root.get_node_or_null("StageDirector")
	_check(stage != null, "StageDirector is loaded")
	if stage == null:
		_finish()
		return
	stage.get_script().set("save_path_override", "user://qa_campaign_100_f2p.json")
	var path: String = stage.get_active_save_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	_check(stage.stages_data.size() == 100, "100 base stage definitions loaded at runtime")
	var configured_bosses: int = 0
	for stage_number in range(1, 101):
		var stage_cfg: Dictionary = stage.get_stage_config(stage_number)
		var expected_boss: bool = stage_number % 10 == 0
		var has_boss: bool = not String(stage_cfg.get("boss_id", "")).is_empty()
		_check(has_boss == expected_boss, "Boss appears exactly on each chapter finale %03d" % stage_number)
		_check(int(stage_cfg.get("waves", 0)) == 10, "Stage %03d has ten waves" % stage_number)
		if has_boss:
			configured_bosses += 1
	_check(configured_bosses == 10, "All ten chapter final boss configurations are present")
	_check(stage.v2_missions.size() == 100, "100 runtime campaign missions loaded")
	_check(stage.v2_contracts.size() == 100, "100 objective contracts loaded")

	# Start with ordinary first-launch resources, without store purchases.
	stage.selected_class_id = "soldier"
	stage.character_level = 1
	stage.character_xp = 0
	stage.current_stage = 1
	stage.max_unlocked_stage = 1
	stage.credits = 350
	stage.dark_matter_gems = 0
	stage.scrap_materials = 12
	stage.battle_pass_xp = 0
	stage.inventory = []
	stage.equipped_items = {}
	stage.first_clears_v2 = {}
	stage.cleared_stages = {}
	stage.class_progression = {"soldier": {"level": 1, "xp": 0, "max_stage": 1, "talents": {}, "equipped_items": {}, "first_clears": {}}}
	stage.talent_levels = {}
	stage.is_practice_mode = false
	stage.purchased_sandbox_packs = {}
	stage.vip_sandbox_active = false
	stage.battle_pass_premium_unlocked = false
	stage.daily_missions = []
	stage.daily_reset_day = int(Time.get_unix_time_from_system() / 86400)

	var earned_credits: int = 0
	var earned_xp: int = 0
	var dropped_count: int = 0
	for n in range(1, 101):
		stage.current_stage = n
		_check(int(stage.max_unlocked_stage) == n, "Stage %03d accessible sequentially without purchases" % n)
		var cfg: Dictionary = stage.get_stage_config(n)
		_check(int(cfg.get("stage", n)) == n, "Stage %03d config resolves" % n)
		_check(int(cfg.get("waves", 0)) == 10, "Stage %03d has 10 waves" % n)
		_check(not String(cfg.get("scene_type", "")).is_empty(), "Stage %03d has main objective" % n)
		var regular_stats: Dictionary = stage.get_enemy_scaled_stats("biegacz", n, 650.0, "normal")
		_check(float(regular_stats.get("max_hp", 0.0)) > 0.0 and float(regular_stats.get("damage", 0.0)) > 0.0, "Stage %03d has valid enemy HP and damage" % n)
		if String(cfg.get("scene_type", "")) == "defeat_boss":
			_check(not String(cfg.get("boss_id", "")).is_empty(), "Defeat-boss objective has a boss on stage %03d" % n)
		if n % 10 == 0:
			_check(not String(cfg.get("boss_id", "")).is_empty(), "Chapter boss available at stage %03d" % n)
		var result: Dictionary = stage.complete_stage_run(n, true, 10)
		earned_credits += int(result.get("earned_credits", 0))
		earned_xp += int(result.get("earned_character_xp", 0))
		if not (result.get("dropped_item", {}) as Dictionary).is_empty():
			dropped_count += 1
		_check(bool(result.get("victory", false)), "Victory result at stage %03d" % n)
		_check(bool(result.get("is_first_clear", false)), "First-clear recorded at stage %03d" % n)
		_check(int(stage.max_unlocked_stage) == mini(100, n + 1), "Stage %03d unlocks next stage only" % n)
		_check(int(result.get("earned_credits", 0)) > 0, "Stage %03d gives F2P credits" % n)
		_check(int(result.get("earned_character_xp", 0)) > 0, "Stage %03d gives F2P account XP" % n)
		_check(stage.credits >= 0 and stage.dark_matter_gems == 0, "All 100 stages playable with zero premium balance after stage %03d" % n)
		_check(stage.purchased_sandbox_packs.is_empty(), "No test-store top-ups after stage %03d" % n)
		if n == 1 or n == 50 or n == 100:
			print("F2P CHECKPOINT stage=%d unlocked=%d credits=%d XP=%d gear=%d" % [
				n, stage.max_unlocked_stage, stage.credits, earned_xp, stage.inventory.size()
			])

	_check(int(stage.max_unlocked_stage) == 100, "All 100 stages reachable without purchase-based stage gates")
	_check(dropped_count >= 100, "Each first-clear provides equipment")
	_check(stage.credits >= 350, "Winning progression remains credit-positive without purchases")
	_check(not bool(stage.vip_sandbox_active) and not bool(stage.battle_pass_premium_unlocked), "All levels cleared with premium features disabled")
	_check(stage.purchased_sandbox_packs.is_empty(), "No sandbox store package was purchased")

	# Save and reload at max progress; ensure class-specific unlocks persist.
	stage.save_campaign_profile()
	stage.current_stage = 1
	stage.max_unlocked_stage = 1
	stage.credits = 0
	stage.inventory = []
	stage.load_campaign_profile()
	_check(int(stage.max_unlocked_stage) == 100, "All 100 stage unlocks survive save/load")
	_check(stage.credits > 0, "F2P credit balance survives save/load")
	_check(stage.inventory.size() >= 100, "Earned first-clear gear survives save/load")
	_check(stage.purchased_sandbox_packs.is_empty(), "F2P-only state survives save/load")

	print("F2P SUMMARY: 100 synthetic first-clear victories, %d earned credits, %d earned XP, %d drops; NO STORE PURCHASES. This is not a real full-game playtest." % [earned_credits, earned_xp, dropped_count])
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("F2P PASS: %d logical checks (NOT combat balance or Android performance)" % checks)
		quit(0)
	else:
		printerr("F2P FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)
