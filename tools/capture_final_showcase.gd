extends Node2D

const ARTIFACT_DIR := "C:/Users/patry/Desktop/2026/MutantSurvivor/build_artifacts/"
const BRAIN_ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"
const MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const MAIN_SCENE := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	# Ensure artifact directories exist
	DirAccess.make_dir_absolute(ARTIFACT_DIR)
	DirAccess.make_dir_absolute(ARTIFACT_DIR + "frames/")

	print("=== START FINAL VISUAL PROOF & GAMEPLAY CAPTURE ===")

	# 1. Main Menu Screen
	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))

	var menu := MENU_SCENE.instantiate()
	add_child(menu)

	for _i in range(12):
		await get_tree().process_frame

	await _save_screen("v1_main_menu_nav_clean_720x1280.png")

	# 2. Armory Pedestal (Character Tab)
	if menu.has_method("switch_hub_tab"):
		menu.call("switch_hub_tab", 1)
		for _i in range(12):
			await get_tree().process_frame
		await _save_screen("v1_armory_clean_pedestal_720x1280.png")

		# 3. Store Tab
		menu.call("switch_hub_tab", 4)
		for _i in range(12):
			await get_tree().process_frame
		await _save_screen("v1_final_shop_showcase_720x1280.png")

	menu.queue_free()
	for _i in range(5):
		await get_tree().process_frame

	# 4. Dense Horde Combat (Stage 1, Wave 2)
	var main_game := MAIN_SCENE.instantiate()
	add_child(main_game)

	for _i in range(10):
		await get_tree().process_frame

	main_game.call("start_stage", 1)
	main_game.call("start_wave", 1, 2)

	var p_ref: Node2D = main_game.player
	var wave_dir = main_game.get_node_or_null("WaveDirector")
	if wave_dir:
		# Spawn a 42-enemy horde pack
		for i in range(42):
			var angle := randf() * TAU
			var dist := randf_range(160.0, 520.0)
			var pos := p_ref.global_position + Vector2(cos(angle), sin(angle)) * dist
			wave_dir._spawn_single_enemy(wave_dir._get_wave_archetype(1, 2), pos, 1, 5.0)

	for _i in range(12):
		await get_tree().process_frame

	await _save_screen("v1_dense_horde_stage001_720x1280.png")

	# 5. Landscape Mode (1280x720)
	StageDirector.set_orientation_mode("landscape", true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for _i in range(12):
		await get_tree().process_frame

	await _save_screen("v1_dense_horde_stage001_1280x720.png")

	# 6. Capture 30 Consecutive Action Frames for 30s Gameplay GIF
	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	for _i in range(8):
		await get_tree().process_frame

	print("Capturing 30 action frames for live gameplay demonstration...")
	for step in range(30):
		# Move player slightly in a circular pattern to trigger walk animation
		var ang := float(step) * 0.25
		if is_instance_valid(p_ref):
			p_ref.external_move_dir = Vector2(cos(ang), sin(ang)).normalized()

		for _f in range(6):
			await get_tree().process_frame

		var frame_name := "frames/gameplay_frame_%02d.png" % step
		await _save_screen(frame_name)

	print("=== CAPTURE COMPLETE! ALL SCREENS AND ACTION FRAMES RECORDED ===")
	get_tree().quit(0)

func _save_screen(subpath: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(ARTIFACT_DIR + subpath)
		if not subpath.begins_with("frames/"):
			img.save_png(BRAIN_ARTIFACT_DIR + subpath)
		print("Saved screenshot: " + subpath + " (" + str(img.get_width()) + "x" + str(img.get_height()) + ")")
