extends Node2D

const ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"
const MAIN_SCENE_RES := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	print("=== START DEFEAT OVERLAY REDESIGN CAPTURE ===")

	# -------------------------------------------------------------
	# 1. Capture Defeat Overlay in Landscape (1280x720) - Full Options
	# -------------------------------------------------------------
	StageDirector.set_orientation_mode("landscape", true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	StageDirector.wave_duration_sec = 65.0
	StageDirector.dark_matter_gems = 60
	StageDirector.is_online_mode = true

	var main_inst: Node2D = MAIN_SCENE_RES.instantiate()
	add_child(main_inst)

	for _f in range(8):
		await get_tree().process_frame

	main_inst.call("start_stage", 1)
	main_inst.call("start_wave", 1, 5)
	main_inst.total_run_elapsed = 272.0 # 04:32
	main_inst.enemies_killed_in_run = 142

	# Trigger death
	main_inst.call("_on_player_died")

	for _f in range(12):
		await get_tree().process_frame

	await _save_screenshot("v1_defeat_redesign_1280x720.png")

	# -------------------------------------------------------------
	# 2. Capture Defeat Overlay in Landscape (1280x720) - No Gems / No Ads
	# -------------------------------------------------------------
	if is_instance_valid(main_inst.defeat_overlay_inst):
		var no_gems_data := {
			"title": "MISJA NIEUDANA",
			"wave": 5,
			"kills": 142,
			"time_seconds": 272,
			"reason": "Etap 001: Ulepsz wyposażenie lub spróbuj innej strategii.",
			"already_revived": false,
			"gems": 0,
			"ad_available": false
		}
		main_inst.defeat_overlay_inst.call("configure", no_gems_data)

	for _f in range(10):
		await get_tree().process_frame

	await _save_screenshot("v1_defeat_no_gems_1280x720.png")

	# -------------------------------------------------------------
	# 3. Capture Defeat Overlay in Portrait (720x1280) - Mobile Layout
	# -------------------------------------------------------------
	main_inst.queue_free()
	for _f in range(5):
		await get_tree().process_frame

	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	StageDirector.dark_matter_gems = 50
	StageDirector.is_online_mode = true

	var port_inst: Node2D = MAIN_SCENE_RES.instantiate()
	add_child(port_inst)

	for _f in range(8):
		await get_tree().process_frame

	port_inst.call("start_stage", 1)
	port_inst.call("start_wave", 1, 5)
	port_inst.total_run_elapsed = 272.0
	port_inst.enemies_killed_in_run = 142
	port_inst.call("_on_player_died")

	for _f in range(12):
		await get_tree().process_frame

	await _save_screenshot("v1_defeat_redesign_720x1280.png")

	port_inst.queue_free()
	print("=== DEFEAT REDESIGN CAPTURE COMPLETE! ===")
	get_tree().quit(0)

func _save_screenshot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(ARTIFACT_DIR + filename)
		print("Saved screenshot: " + filename + " (" + str(img.get_width()) + "x" + str(img.get_height()) + ")")
