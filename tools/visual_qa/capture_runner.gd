extends Node

const CAPTURES_DIR := "res://visual_qa/captures/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

	print("\n[Visual QA] All requested screen captures successfully rendered!")
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

	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	var main_inst = main_scene.instantiate()
	sub.add_child(main_inst)

	for frame in range(25):
		await get_tree().process_frame

	if main_inst.has_method("_on_stage_victory"):
		main_inst.call("_on_stage_victory")
		for frame in range(20):
			await get_tree().process_frame

	await _save_viewport_png(sub, "victory_overlay_1280x720_actual")
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

	var player = main_inst.get_node_or_null("Player")
	var spawner = main_inst.get_node_or_null("EnemySpawner")
	if is_instance_valid(player) and is_instance_valid(spawner) and spawner.has_method("spawn_enemy"):
		var enemies := ["biegacz", "tank", "plujacy_kwasem", "skoczek", "pancerny"]
		for i in range(10):
			var angle := float(i) * (TAU / 10.0)
			var offset := Vector2(cos(angle) * 220.0, sin(angle) * 160.0)
			spawner.spawn_enemy(player.global_position + offset, enemies[i % enemies.size()], "normal")

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

	var player = main_inst.get_node_or_null("Player")
	var spawner = main_inst.get_node_or_null("EnemySpawner")
	if is_instance_valid(player) and is_instance_valid(spawner) and spawner.has_method("spawn_enemy"):
		var enemies := ["biegacz", "wirusowy", "tank", "skrzydlaty", "wybuchowy"]
		for i in range(10):
			var angle := float(i) * (TAU / 10.0)
			var offset := Vector2(cos(angle) * 160.0, sin(angle) * 230.0)
			spawner.spawn_enemy(player.global_position + offset, enemies[i % enemies.size()], "normal")

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
		push_error("[Visual QA] Failed to get viewport image for %s" % file_stem)
		return

	var out_dir := ProjectSettings.globalize_path(CAPTURES_DIR)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var full_path := out_dir.path_join(file_stem + ".png")
	var err := img.save_png(full_path)
	if err == OK:
		print("[Visual QA] Saved actual screenshot: %s (%dx%d)" % [full_path, img.get_width(), img.get_height()])
	else:
		push_error("[Visual QA] Error saving PNG: %d" % err)
