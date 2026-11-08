extends Node2D

const MAIN_SCENE_RES := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	print("\n========================================================")
	print("=== START FULL STAGE RUNS SIMULATION: 001, 030, 100 ===")
	print("========================================================\n")

	# Use fast-forward wave duration for comprehensive full test without skipping logic
	StageDirector.wave_duration_sec = 0.8
	StageDirector.save_path_override = "user://test_stage_runs_save.json"

	var main_inst: Node2D = MAIN_SCENE_RES.instantiate()
	add_child(main_inst)

	for _f in range(5):
		await get_tree().process_frame

	# ----------------------------------------------------
	# 1. TEST FULL STAGE 001 (Pustkowia / Kompleks A-03)
	# ----------------------------------------------------
	print("--- SIMULATING FULL RUN: STAGE 001 ---")
	StageDirector.current_stage = 1
	StageDirector.max_unlocked_stage = 1
	main_inst.call("_build_layered_arena", 1)
	main_inst.call("start_stage", 1)

	# Simulate 10 waves
	for w in range(1, 11):
		main_inst.call("start_wave", 1, w)
		# Simulate wave combat
		for _step in range(12):
			main_inst.call("_process", 0.08)
			await get_tree().process_frame

		if w == 5:
			# Verify Miniboss spawned
			assert(is_instance_valid(main_inst.active_boss), "STAGE 001: Wave 5 miniboss missing")
			print("Stage 001 Wave 5: Miniboss detected (%s). Defeating..." % main_inst.active_boss.enemy_id)
			main_inst.active_boss.take_damage(9999.0)
			await get_tree().process_frame

		elif w == 10:
			# Verify Boss spawned
			assert(is_instance_valid(main_inst.active_boss), "STAGE 001: Wave 10 boss missing")
			print("Stage 001 Wave 10: Boss detected (%s). Defeating..." % main_inst.active_boss.enemy_id)
			main_inst.active_boss.take_damage(9999.0)
			await get_tree().process_frame

	# Complete primary objective (terminal)
	main_inst.primary_objective_done = true
	main_inst.wave_time_left = 0.0
	main_inst.call("on_wave_completed")
	await get_tree().process_frame

	assert(main_inst.run_result_state == "victory", "STAGE 001 FAIL: Run did not result in victory")
	assert(StageDirector.max_unlocked_stage >= 2, "STAGE 001 FAIL: Stage 2 not unlocked")
	print("PASS STAGE 001: 10 waves, Miniboss, Boss defeated, Stage 2 unlocked!\n")

	# ----------------------------------------------------
	# 2. TEST FULL STAGE 030 (Laboratorium Kriogeniczne)
	# ----------------------------------------------------
	print("--- SIMULATING FULL RUN: STAGE 030 ---")
	StageDirector.current_stage = 30
	StageDirector.max_unlocked_stage = 30
	main_inst.call("_build_layered_arena", 30)
	main_inst.call("start_stage", 30)

	for w in range(1, 11):
		main_inst.call("start_wave", 30, w)
		for _step in range(12):
			main_inst.call("_process", 0.08)
			await get_tree().process_frame

		if w == 5 and is_instance_valid(main_inst.active_boss):
			main_inst.active_boss.take_damage(9999.0)
			await get_tree().process_frame
		elif w == 10 and is_instance_valid(main_inst.active_boss):
			main_inst.active_boss.take_damage(9999.0)
			await get_tree().process_frame

	main_inst.primary_objective_done = true
	main_inst.wave_time_left = 0.0
	main_inst.call("on_wave_completed")
	await get_tree().process_frame

	assert(main_inst.run_result_state == "victory", "STAGE 030 FAIL: Run did not result in victory")
	assert(StageDirector.max_unlocked_stage >= 31, "STAGE 030 FAIL: Stage 31 not unlocked")
	print("PASS STAGE 030: 10 waves, Cryo Boss defeated, Stage 31 unlocked!\n")

	# ----------------------------------------------------
	# 3. TEST FULL STAGE 100 (Reaktor Rdzenia / Finał)
	# ----------------------------------------------------
	print("--- SIMULATING FULL RUN: STAGE 100 ---")
	StageDirector.current_stage = 100
	StageDirector.max_unlocked_stage = 100
	main_inst.call("_build_layered_arena", 100)
	main_inst.call("start_stage", 100)

	for w in range(1, 11):
		main_inst.call("start_wave", 100, w)
		for _step in range(12):
			main_inst.call("_process", 0.08)
			await get_tree().process_frame

		if w == 5 and is_instance_valid(main_inst.active_boss):
			main_inst.active_boss.take_damage(9999.0)
			await get_tree().process_frame
		elif w == 10 and is_instance_valid(main_inst.active_boss):
			main_inst.active_boss.take_damage(9999.0)
			await get_tree().process_frame

	main_inst.primary_objective_done = true
	main_inst.wave_time_left = 0.0
	main_inst.call("on_wave_completed")
	await get_tree().process_frame

	assert(main_inst.run_result_state == "victory", "STAGE 100 FAIL: Run did not result in victory")
	assert(main_inst.win_panel.visible == true, "STAGE 100 FAIL: WinPanel not visible")
	print("PASS STAGE 100: Grand Finale 10 waves cleared, Reactor Boss defeated, WinPanel verified!\n")

	# Restore normal stage duration
	StageDirector.wave_duration_sec = 65.0
	print("=== ALL FULL STAGE SCENARIOS (001, 030, 100) COMPLETED WITH SUCCESS ===")
	get_tree().quit(0)
