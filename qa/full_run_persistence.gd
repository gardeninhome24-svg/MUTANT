extends SceneTree

# Headless full scene integration: stage two boss victory -> persisted
# rewards/unlock -> reloaded profile -> next-stage defeat without duplications.
# Uses a unique disposable user:// file and never touches a player's save.
const SAVE_PATH := "user://qa_full_run_persistence.json"
var problems: Array[String] = []
var checks: int = 0
var stage: Node = null
var battle: Node = null

func _initialize() -> void:
	call_deferred("_execute")

func _check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		problems.append(description)
		printerr("FULL RUN FAIL: " + description)

func _remove_fixtures() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		var target: String = SAVE_PATH + String(suffix)
		if FileAccess.file_exists(target):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(target))

func _execute() -> void:
	await process_frame
	await process_frame
	stage = root.get_node_or_null("StageDirector")
	_check(stage != null, "StageDirector autoload is available")
	if stage == null:
		_done()
		return
	stage.get_script().set("save_path_override", SAVE_PATH)
	_remove_fixtures()
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	_check(packed != null, "Real combat scene resource loads")
	if packed == null:
		_done()
		return
	stage.is_practice_mode = false
	stage.current_stage = 2
	stage.max_unlocked_stage = 2
	stage.selected_class_id = "soldier"
	stage.selected_skin_id = "default"
	stage.character_level = 1
	stage.character_xp = 0
	stage.credits = 300
	stage.scrap_materials = 20
	stage.dark_matter_gems = 0
	stage.cleared_stages = {}
	stage.first_clears_v2 = {}
	stage.class_progression = {"soldier": {"level": 1, "xp": 0, "max_stage": 2,
		"talents": {}, "equipped_items": {}, "first_clears": {}}}
	stage.inventory = []
	stage.equipped_items = {}
	stage.daily_missions = []
	stage.daily_reset_day = int(Time.get_unix_time_from_system() / 86400)
	stage.save_campaign_profile()
	_check(FileAccess.file_exists(SAVE_PATH), "New profile persists before the run")

	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	_check(int(battle.get("current_stage_num")) == 2, "Actual stage 2 loads")
	_check(int(battle.get("current_wave_num")) == 1, "Actual stage starts at wave one")
	_check(String(battle.get("run_result_state")) == "active", "Run state starts active")
	var wallet_initial: int = int(stage.credits)
	var xp_initial: int = int(stage.character_xp)
	battle.call("start_wave", 2, 10)
	_check(int(battle.get("current_wave_num")) == 10, "Final wave ten enters actual combat")
	var final_wave_label: Label = battle.get("wave_label") as Label
	_check(final_wave_label != null and not final_wave_label.text.contains("BOSS"), "Ordinary stage final wave does not falsely announce a boss")
	var boss: Node = battle.get("active_boss")
	_check(not is_instance_valid(boss), "Stage two is an ordinary mission without a chapter boss")
	_check(not bool(battle.get("boss_spawned_this_run")), "Nonfinal chapter stage does not spawn a chapter boss")
	_check(not bool(battle.call("_stage_requires_final_boss")), "Stage two campaign data does not require a boss")
	battle.set("primary_objective_done", false)
	battle.set("wave_time_left", 0.0)
	_check(not bool(battle.call("_can_claim_victory")), "Incomplete mission objective still blocks victory")
	battle.set("primary_objective_done", true)
	_check(bool(battle.call("_can_claim_victory")), "Nonboss mission can finish after wave ten and objective completion")
	battle.call("_on_stage_victory")
	_check(String(battle.get("run_result_state")) == "victory", "Victory state is terminal")
	_check(int(stage.max_unlocked_stage) == 3, "Stage 2 unlocks stage 3 only")
	_check(int(stage.credits) > wallet_initial, "Earned real credits are applied")
	_check(int(stage.character_xp) > xp_initial or int(stage.character_level) > 1, "Character receives earned progression")
	_check(stage.cleared_stages.has("2"), "First-clear flag is persisted in memory")
	_check(not stage.inventory.is_empty(), "First-clear equipment is actually awarded")
	var wallet_after: int = int(stage.credits)
	var inventory_after: int = stage.inventory.size()
	var level_after: int = int(stage.character_level)
	battle.call("_on_stage_victory")
	_check(int(stage.credits) == wallet_after, "Double victory never doubles currency")
	_check(stage.inventory.size() == inventory_after, "Double victory never doubles loot")
	_check(int(stage.character_level) == level_after, "Double victory never doubles level")
	_check(FileAccess.file_exists(SAVE_PATH), "Real victory produces primary save file")
	stage.credits = 0
	stage.max_unlocked_stage = 1
	stage.inventory.clear()
	stage.load_campaign_profile()
	_check(int(stage.credits) == wallet_after, "Victory credits survive process-style reload")
	_check(int(stage.max_unlocked_stage) == 3, "Campaign unlock survives profile reload")
	_check(stage.inventory.size() == inventory_after, "Awarded loot survives profile reload")
	_check(stage.cleared_stages.has("2"), "Completed mission survives profile reload")
	_check(stage.current_stage <= stage.max_unlocked_stage, "Selected stage cannot exceed unlocked progression")
	paused = false
	battle.queue_free()
	await process_frame

	stage.current_stage = 3
	stage.is_practice_mode = false
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	_check(int(battle.get("current_stage_num")) == 3, "Next unlocked stage can start")
	_check(String(battle.get("run_result_state")) == "active", "Next run state resets")
	var before_loss: int = int(stage.credits)
	var before_loss_items: int = stage.inventory.size()
	battle.call("_on_player_died")
	_check(String(battle.get("run_result_state")) == "awaiting_revive", "Real death waits for revive decision")
	battle.call("_on_player_died")
	_check(String(battle.get("run_result_state")) == "awaiting_revive", "Duplicate death callback is ignored")
	battle.call("toggle_premium_shop")
	_check(paused, "Opening premium shop while dead keeps combat paused")
	battle.call("toggle_premium_shop")
	_check(paused, "Closing premium shop while dead does not resume combat")
	var death_shop: Control = battle.get("premium_shop_panel") as Control
	_check(is_instance_valid(death_shop) and not death_shop.visible, "Closing premium shop restores death overlay")
	battle.call("_finalize_failure_once")
	_check(String(battle.get("run_result_state")) == "failure_final", "Giving up revive settles defeat")
	_check(int(stage.credits) == before_loss, "Zero-wave defeat grants no farming currency")
	_check(stage.inventory.size() == before_loss_items, "Zero-wave defeat grants no equipment")
	battle.call("_finalize_failure_once")
	_check(int(stage.credits) == before_loss, "Double failure does not pay a second time")
	_check(int(stage.max_unlocked_stage) == 3, "Failed next stage never unlocks stage four")
	battle.call("_on_revive_premium_pressed")
	_check(String(battle.get("run_result_state")) == "failure_final", "Finished failure cannot be revived for gems")
	paused = false
	battle.queue_free()
	await process_frame

	stage.load_campaign_profile()
	_check(int(stage.credits) == before_loss, "Failure settlement remains consistent after reload")
	_check(int(stage.max_unlocked_stage) == 3, "Unlocked stage remains three after failed operation")
	# A player can die on wave 10 without completing the objective.
	# Surviving the timer does not grant a victory or stage unlock.
	stage.current_stage = 3
	stage.is_practice_mode = false
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.call("start_wave", 3, 10)
	battle.set("wave_time_left", 0.0)
	battle.set("primary_objective_done", false)
	_check(not bool(battle.call("_can_claim_victory")), "Wave ten alone cannot bypass missing objective")
	var credits_before_final_loss: int = int(stage.credits)
	battle.call("_on_player_died")
	battle.call("_finalize_failure_once")
	_check(String(battle.get("run_result_state")) == "failure_final", "Final-wave death ends in failure")
	_check(int(stage.max_unlocked_stage) == 3, "Final-wave loss never unlocks stage four")
	var credits_after_final_loss: int = int(stage.credits)
	_check(credits_after_final_loss >= credits_before_final_loss, "Final-wave failure cannot subtract earned credits")
	battle.call("_finalize_failure_once")
	_check(int(stage.credits) == credits_after_final_loss, "Repeated final-wave failure does not duplicate rewards")
	paused = false
	battle.queue_free()
	await process_frame

	# Successful premium revive must close the shop rather than leaving
	# interactive combat running underneath an obstructing store overlay.
	stage.is_practice_mode = true
	stage.dark_matter_gems = 50
	stage.current_stage = 3
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.call("_on_player_died")
	battle.call("toggle_premium_shop")
	var revive_shop: Control = battle.get("premium_shop_panel") as Control
	_check(is_instance_valid(revive_shop) and revive_shop.visible, "Revive shop opens on death screen")
	battle.call("_on_revive_premium_pressed")
	_check(String(battle.get("run_result_state")) == "active", "Premium revive resumes active combat")
	_check(not paused, "Successful premium revive unpauses combat")
	_check(is_instance_valid(revive_shop) and not revive_shop.visible, "Successful revive closes premium shop")
	_check(int(stage.dark_matter_gems) == 20, "Premium revive costs exactly 30 gems")
	battle.call("_on_revive_premium_pressed")
	_check(int(stage.dark_matter_gems) == 20, "Repeat revive callback cannot charge twice")
	paused = false
	battle.queue_free()
	await process_frame

	# Destroyed defense objectives cannot be repaired by paid hero revives.
	# Billing must be prevented even when an old UI callback is invoked.
	stage.is_practice_mode = true
	stage.dark_matter_gems = 50
	stage.current_stage = 2
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.set("primary_objective_hp", 0.0)
	battle.call("_on_player_died")
	var defense_revive_button: Button = battle.get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox/ReviveDMBtn") as Button
	if is_instance_valid(defense_revive_button):
		_check(defense_revive_button.disabled, "Destroyed defense target disables premium revive button")
	battle.call("_on_revive_premium_pressed")
	_check(int(stage.dark_matter_gems) == 50, "Destroyed defense objective cannot charge premium revive gems")
	_check(String(battle.get("run_result_state")) == "awaiting_revive", "Destroyed defense objective remains failed after attempted paid revive")
	paused = false
	battle.queue_free()
	await process_frame

	# Chapter 1 finale is a REAL boss encounter, unlike ordinary stage 2.
	# Practice ensures this separately tests combat without awarding currency.
	stage.current_stage = 10
	stage.max_unlocked_stage = 10
	stage.is_practice_mode = true
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.call("start_wave", 10, 10)
	var chapter_boss: Node = battle.get("active_boss")
	_check(bool(battle.call("_stage_requires_final_boss")), "Chapter 1 finale requires a real boss")
	var boss_wave_label: Label = battle.get("wave_label") as Label
	_check(boss_wave_label != null and boss_wave_label.text.contains("BOSS"), "Chapter finale final wave announces the boss")
	_check(is_instance_valid(chapter_boss), "Stage ten actually spawns boss_ch01")
	_check(bool(battle.get("boss_spawned_this_run")), "Chapter finale boss spawn is registered")
	battle.set("primary_objective_done", true)
	battle.set("wave_time_left", 0.0)
	_check(not bool(battle.call("_can_claim_victory")), "Chapter boss must be defeated before victory")
	battle.set("boss_spawned_this_run", false)
	_check(not bool(battle.call("_can_claim_victory")), "Required chapter boss cannot be bypassed")
	battle.set("boss_spawned_this_run", true)
	if is_instance_valid(chapter_boss):
		_check(String(chapter_boss.enemy_id) == "boss_ch01", "Actual chapter one boss matches mission")
		chapter_boss.take_damage(chapter_boss.max_health + 1000.0)
	_check(bool(battle.get("boss_killed_this_run")), "Chapter boss death updates victory gate")
	_check(bool(battle.call("_can_claim_victory")), "Chapter boss kill allows the final wave to finish")
	battle.call("_on_stage_victory")
	_check(String(battle.get("run_result_state")) == "victory", "Chapter finale can reach victory state")
	_check(int(stage.credits) == credits_after_final_loss, "Practice boss clear does not mint credits beyond final-wave defeat settlement")
	paused = false
	battle.queue_free()
	await process_frame

	# Stage 3: real DNA pickups, rather than holding the generic terminal,
	# are the only way to complete the primary collection objective.
	stage.is_practice_mode = true
	stage.current_stage = 3
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	_check(String(battle.get("primary_objective_type")) == "collect_item", "Stage 3 requires collecting DNA")
	_check(not bool(battle.get("primary_objective_done")), "Stage 3 starts with collection incomplete")
	var expected_core_positions: Array[Vector2] = [
		Vector2(-380, 120), Vector2(290, -110), Vector2(-120, -290)
	]
	var pickup_area_count: int = 0
	var pickup_layer: Node2D = battle.get("decorations_layer") as Node2D
	var pickup_player: Node2D = battle.get("player") as Node2D
	for child in pickup_layer.get_children():
		if child is Area2D:
			for core_pos in expected_core_positions:
				if child.position.distance_to(core_pos) < 0.1:
					pickup_area_count += 1
					child.body_entered.emit(pickup_player)
					break
	_check(pickup_area_count == 3, "Stage 3 spawns three collectable DNA samples")
	_check(int(battle.get("data_cores_collected")) == 3, "Stage 3 DNA pickups increment collection count")
	_check(bool(battle.get("primary_objective_done")), "Stage 3 finishes collection objective after three pickups")
	paused = false
	battle.queue_free()
	await process_frame

	# Stage 7: two real chapter elites must die; merely visiting the
	# generic objective marker must not finish the elite clearance.
	stage.current_stage = 7
	battle = packed.instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	_check(String(battle.get("primary_objective_type")) == "clear_elites", "Stage 7 uses elite-kill objective")
	battle.call("start_wave", 7, 5)
	var mandatory_elites: Array[Node] = []
	for enemy in get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is MutantEnemy:
			if enemy.tier == "miniboss" and enemy.enemy_id == "elite_ch01_stage07":
				mandatory_elites.append(enemy)
	_check(mandatory_elites.size() == 2, "Stage 7 spawns two mandatory chapter elites")
	if mandatory_elites.size() == 2:
		mandatory_elites[0].take_damage(float(mandatory_elites[0].max_health) + 1000000.0)
		_check(not bool(battle.get("primary_objective_done")), "One elite kill cannot finish stage 7 objective")
		mandatory_elites[1].take_damage(float(mandatory_elites[1].max_health) + 1000000.0)
		_check(bool(battle.get("primary_objective_done")), "Two elite kills finish stage 7 objective")
	paused = false
	battle.queue_free()
	await process_frame

	_remove_fixtures()
	_done()

func _done() -> void:
	paused = false
	if problems.is_empty():
		print("FULL RUN PASS: %d assertions across real combat, 10th wave, boss, rewards and reload" % checks)
		quit(0)
	else:
		printerr("FULL RUN FAILED: %d of %d assertions" % [problems.size(), checks])
		quit(1)
