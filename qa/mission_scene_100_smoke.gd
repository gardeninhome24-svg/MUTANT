extends SceneTree

# Real 100-stage scene smoke gate. This instantiates the Godot combat scene
# for every campaign mission (not a simulated ten-wave player playthrough).
# Each run is disposable and uses its own QA-only save path.
const QA_SAVE_PATH := "user://qa_mission_scene_100_smoke.json"
const COMBAT_SCENE_PATH := "res://scenes/main/main.tscn"

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("MISSION SCENE FAIL: " + message)

func _run() -> void:
	await process_frame
	var stage: Node = root.get_node_or_null("StageDirector")
	_check(stage != null, "StageDirector autoload exists")
	if stage == null:
		_done()
		return
	stage.get_script().set("save_path_override", QA_SAVE_PATH)
	stage.is_practice_mode = true
	# Loading a combat PackedScene as a top-level const runs before the
	# SceneTree autoload registry is initialized with --script; the dependent
	# Player/Enemy scripts then fail to resolve the StageDirector singleton.
	var combat_scene: PackedScene = load(COMBAT_SCENE_PATH) as PackedScene
	_check(combat_scene != null, "Combat scene loads after StageDirector initialization")
	if combat_scene == null:
		stage.get_script().set("save_path_override", "")
		_done()
		return

	for stage_num in range(1, 101):
		var cfg: Dictionary = stage.get_stage_config(stage_num)
		stage.current_stage = stage_num
		stage.max_unlocked_stage = stage_num
		var combat: Node = combat_scene.instantiate()
		_check(combat != null, "Combat scene instantiates stage %d" % stage_num)
		if combat == null:
			continue
		root.add_child(combat)
		combat.set_process(false)
		await process_frame

		var scene_type: String = String(cfg.get("scene_type", ""))
		_check(int(combat.get("current_stage_num")) == stage_num,
			"Stage %d initializes correct number" % stage_num)
		_check(int(combat.get("current_wave_num")) == 1,
			"Stage %d begins at wave one" % stage_num)
		_check(String(combat.get("primary_objective_type")) == scene_type,
			"Stage %d loads actual objective type %s" % [stage_num, scene_type])
		_check(not bool(combat.get("primary_objective_done")),
			"Stage %d does not start with a completed objective" % stage_num)
		var goal_area: Area2D = combat.get("primary_objective_area") as Area2D
		_check(is_instance_valid(goal_area), "Stage %d creates objective scene" % stage_num)

		match scene_type:
			"defend_node", "survive_hazard":
				_check(float(combat.get("primary_objective_required_sec")) >= 90.0,
					"Stage %d has a 90-second mission duration" % stage_num)
			"collect_item":
				_check(int(combat.get("data_cores_total")) == 3,
					"Stage %d creates three DNA pickups" % stage_num)
			"clear_elites":
				_check(int(combat.get("objective_elites_required")) == 2,
					"Stage %d requires two named elites" % stage_num)
			"destroy_target":
				var targets: int = 0
				var obstacle_layer: Node2D = combat.get("obstacles_layer") as Node2D
				if is_instance_valid(obstacle_layer):
					for candidate in obstacle_layer.get_children():
						if candidate is ExplosiveBarrel and candidate.has_meta("mission_target"):
							targets += 1
				_check(targets == 2, "Stage %d spawns two real shootable incubators" % stage_num)
			"repair_generator":
				_check(int(combat.get("objective_steps_required")) == 2,
					"Stage %d requires two repairs" % stage_num)
			"rescue_npc":
				_check(not bool(combat.get("rescue_npc_freed")),
					"Stage %d survivor begins captive" % stage_num)
			"escort":
				_check(float(combat.get("primary_objective_required_sec")) > 350.0,
					"Stage %d escort must traverse the arena" % stage_num)
			"defeat_boss":
				_check(bool(combat.call("_stage_requires_final_boss")),
					"Stage %d requires chapter boss" % stage_num)

		# Test the actual configured wave-five and wave-ten boss spawns.
		# The final-wave kill/victory behavior is separately tested for all
		# ten finales by chapter_boss_integration.gd.
		if stage_num % 10 == 0:
			combat.call("start_wave", stage_num, 10)
			var boss: Node = combat.get("active_boss")
			_check(is_instance_valid(boss), "Stage %d boss appears in real combat scene" % stage_num)
			_check(bool(combat.get("boss_spawned_this_run")),
				"Stage %d boss is registered in run state" % stage_num)
		elif scene_type == "clear_elites":
			combat.call("start_wave", stage_num, 5)
			var required_id: String = "elite_ch%02d_stage07" % int(cfg.get("chapter", 1))
			var count: int = 0
			var characters: Node2D = combat.get("characters_layer") as Node2D
			if is_instance_valid(characters):
				for enemy in characters.get_children():
					if enemy is MutantEnemy and enemy.enemy_id == required_id and not enemy.is_dying:
						count += 1
			_check(count == 2, "Stage %d spawns two contracted elites on wave five" % stage_num)

		paused = false
		combat.queue_free()
		await process_frame
		# Ensure previous combat nodes have actually left the scene tree.
		# The next stage must not see stale actors or mission objects.
		_check(not is_instance_valid(combat),
			"Stage %d combat scene is disposed after QA" % stage_num)
		if stage_num % 10 == 0:
			print("MISSION SCENE PROGRESS: %d/100 stages checked" % stage_num)

	stage.get_script().set("save_path_override", "")
	for suffix in ["", ".tmp", ".bak", ".bak.tmp"]:
		var filename: String = QA_SAVE_PATH + suffix
		if FileAccess.file_exists(filename):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(filename))
	_done()

func _done() -> void:
	paused = false
	if failures.is_empty():
		print("MISSION SCENE PASS: 100 real stage scenes instantiated; %d assertions" % checks)
		quit(0)
	else:
		printerr("MISSION SCENE FAILED: %d of %d assertions" % [failures.size(), checks])
		quit(1)
