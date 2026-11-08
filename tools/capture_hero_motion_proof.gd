extends Node

const ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	StageDirector.save_path_override = "user://test_motion_capture.json"

	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main_inst = main_packed.instantiate()
	add_child(main_inst)
	await get_tree().process_frame
	await get_tree().process_frame

	var p = main_inst.player
	p.position = Vector2(360, 640)

	var classes := ["soldier", "engineer", "medic", "scout"]
	for cls in classes:
		StageDirector.switch_class(cls)
		p.apply_class_and_talents(false)
		p.velocity = Vector2(160.0, 0.0)
		for f in range(5):
			p.anim_timer = float(f) * 1.25 + 0.1
			p.sprite.texture = p.walk_frames[f]
			await get_tree().process_frame
			await get_tree().process_frame
			var img := get_viewport().get_texture().get_image()
			if img and f == 2: # Capture frame 3 of walk cycle for each class
				var fname := "v1_motion_%s_walk_cycle.png" % cls
				img.save_png(ARTIFACT_DIR + fname)
				print("Saved motion capture: " + fname)

	# Capture final move-only combat with auto-shooting
	StageDirector.switch_class("soldier")
	StageDirector.character_level = 30
	p.apply_class_and_talents(false)
	await get_tree().process_frame
	await get_tree().process_frame
	var combat_img := get_viewport().get_texture().get_image()
	if combat_img:
		combat_img.save_png(ARTIFACT_DIR + "v1_move_only_gameplay_live.png")
		print("Saved live gameplay capture: v1_move_only_gameplay_live.png")

	print("MOTION CAPTURE COMPLETED SUCCESSFULLY")
	get_tree().quit(0)
