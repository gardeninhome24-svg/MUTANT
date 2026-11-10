extends Node

const CAPTURES_DIR := "res://visual_qa/captures/"
var failed_captures: int = 0
var saved_captures: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	StageDirector.is_practice_mode = true
	StageDirector.save_path_override = "user://visual_qa_test_save.json"
	if FileAccess.file_exists(StageDirector.save_path_override):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(StageDirector.save_path_override))

	print("\n==============================================================")
	print("=== MUTANT SURVIVOR VISUAL QA 2.0 — AUTOMATED CAPTURE RUNNER ===")
	print("==============================================================")

	var capture_target := "all"
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--scenario="):
			capture_target = arg.split("=")[1].strip_edges()

	print("Selected scenario filter: %s" % capture_target)

	if capture_target in ["all", "defeat", "defeat_overlay_16x9"]:
		await _capture_defeat_overlay()

	if capture_target in ["all", "victory", "victory_overlay_16x9"]:
		await _capture_victory_overlay()

	if capture_target in ["all", "hud_16x9", "hud_combat_16x9"]:
		await _capture_hud_combat_16x9()

	if capture_target in ["all", "hud_9x16", "hud_mobile_9x16"]:
		await _capture_hud_mobile_9x16()

	get_tree().paused = false
	StageDirector.save_path_override = ""
	if failed_captures > 0 or saved_captures == 0:
		printerr("[Visual QA] Capture FAILED: %d failed, %d saved" % [failed_captures, saved_captures])
		get_tree().quit(1)
	else:
		print("[Visual QA] CAPTURES PASS: %d real viewport PNGs saved" % saved_captures)
		get_tree().quit(0)

func _capture_defeat_overlay() -> void:
	print("\n[Visual QA] Capturing: Defeat Overlay (1280x720)...")
	var sub := _create_subviewport(Vector2i(1280, 720))
	add_child(sub)

	var overlay_scene := load("res://addons/ms_balance/ui/defeat_overlay.tscn") as PackedScene
	var overlay = overlay_scene.instantiate()
	sub.add_child(overlay)

	# Configure repeatable baseline state matching reference
	overlay.call("configure", {
		"title": "MISJA NIEUDANA",
		"wave": 5,
		"time_seconds": 272, # 04:32
		"kills": 142,
		"reason": "Etap 003: Ulepsz wyposażenie w bazie lub zmień profil obrony.",
		"already_revived": false,
		"gems": 300,
		"ad_available": true
	})

	for frame in range(15):
		await get_tree().process_frame

	await _save_viewport_png(sub, "defeat_overlay_1280x720_actual")
	overlay.queue_free()
	sub.queue_free()
	await get_tree().process_frame

func _capture_victory_overlay() -> void:
	print("\n[Visual QA] Capturing: Victory Overlay (1280x720)...")
	var sub := _create_subviewport(Vector2i(1280, 720))
	add_child(sub)

	StageDirector.current_stage = 2
	StageDirector.is_practice_mode = true
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	var main_inst = main_scene.instantiate()
	sub.add_child(main_inst)
	for frame in range(15):
		await get_tree().process_frame
	# Real victory now verifies wave ten, time and mission objective.
	# Stage two has no chapter boss; finish its objective before capture.
	main_inst.set_process(false)
	main_inst.call("start_wave", 2, 10)
	main_inst.set("primary_objective_done", true)
	main_inst.set("wave_time_left", 0.0)
	main_inst.call("_on_stage_victory")
	if String(main_inst.get("run_result_state")) != "victory":
		failed_captures += 1
		push_error("[Visual QA] Victory state did not activate")
	for frame in range(12):
		await get_tree().process_frame
	await _save_viewport_png(sub, "victory_overlay_1280x720_actual")
	get_tree().paused = false
	main_inst.queue_free()
	sub.queue_free()
	await get_tree().process_frame

func _capture_hud_combat_16x9() -> void:
	print("\n[Visual QA] Capturing: HUD Combat 16:9 (1280x720)...")
	var sub := _create_subviewport(Vector2i(1280, 720))
	add_child(sub)

	StageDirector.selected_class_id = "soldier"
	StageDirector.current_stage = 1
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	var main_inst = main_scene.instantiate()
	sub.add_child(main_inst)

	for frame in range(40):
		await get_tree().process_frame

	var player: Player = main_inst.get_node_or_null("CharactersLayer/Player") as Player
	if is_instance_valid(player):
		main_inst.set_process(false)
		for i in range(10):
			main_inst.call("spawn_wave_enemy")
	else:
		failed_captures += 1
		push_error("[Visual QA] Combat screenshot has no playable hero")

	for frame in range(35):
		await get_tree().process_frame

	await _save_viewport_png(sub, "hud_combat_1280x720_actual")
	main_inst.queue_free()
	sub.queue_free()
	await get_tree().process_frame

func _capture_hud_mobile_9x16() -> void:
	print("\n[Visual QA] Capturing: HUD Mobile 9:16 (720x1280)...")
	var sub := _create_subviewport(Vector2i(720, 1280))
	add_child(sub)

	StageDirector.selected_class_id = "engineer"
	StageDirector.current_stage = 1
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	var main_inst = main_scene.instantiate()
	sub.add_child(main_inst)

	for frame in range(40):
		await get_tree().process_frame

	var player: Player = main_inst.get_node_or_null("CharactersLayer/Player") as Player
	if is_instance_valid(player):
		main_inst.set_process(false)
		for i in range(10):
			main_inst.call("spawn_wave_enemy")
	else:
		failed_captures += 1
		push_error("[Visual QA] Combat screenshot has no playable hero")

	for frame in range(35):
		await get_tree().process_frame

	await _save_viewport_png(sub, "hud_mobile_720x1280_actual")
	main_inst.queue_free()
	sub.queue_free()
	await get_tree().process_frame

func _create_subviewport(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return sub

func _save_viewport_png(sub: SubViewport, file_stem: String) -> void:
	for _f in range(3):
		await get_tree().process_frame
	var img := sub.get_texture().get_image()
	if not img:
		failed_captures += 1
		push_error("[Visual QA] Failed to get viewport image for %s" % file_stem)
		return

	# A successful PNG write alone is not evidence of a rendered frame.
	# Detect single-color/empty off-screen captures (common with a dummy
	# renderer) before claiming visual QA produced usable screenshots.
	var colors: Dictionary = {}
	for sample_y in range(1, 12):
		for sample_x in range(1, 12):
			var pixel_x: int = mini(img.get_width() - 1, int(float(img.get_width()) * float(sample_x) / 12.0))
			var pixel_y: int = mini(img.get_height() - 1, int(float(img.get_height()) * float(sample_y) / 12.0))
			var pixel_color: Color = img.get_pixel(pixel_x, pixel_y)
			colors[pixel_color.to_html()] = true
	if colors.size() < 4:
		failed_captures += 1
		push_error("[Visual QA] Refusing near-blank frame %s (%d sampled colors)" % [file_stem, colors.size()])
		return

	var out_dir := ProjectSettings.globalize_path(CAPTURES_DIR)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var full_path := out_dir.path_join(file_stem + ".png")
	var err := img.save_png(full_path)
	if err == OK:
		saved_captures += 1
		print("[Visual QA] Saved actual screenshot: %s (%dx%d)" % [full_path, img.get_width(), img.get_height()])
	else:
		failed_captures += 1
		push_error("[Visual QA] Error saving PNG: %d" % err)
