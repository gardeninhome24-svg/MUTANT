extends Node2D

const ARTIFACT_DIR := "C:/Users/patry/Desktop/2026/MutantSurvivor/build_artifacts/"
const BRAIN_ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"
const MAIN_SCENE := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	DirAccess.make_dir_absolute(ARTIFACT_DIR + "frames_60s/")

	print("=== START EXTENDED 60-FRAME (60-90s) COMBAT CAPTURE ===")
	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))

	var main_game := MAIN_SCENE.instantiate()
	add_child(main_game)

	for _i in range(8):
		await get_tree().process_frame

	main_game.call("start_stage", 1)
	main_game.call("start_wave", 1, 3)

	var p_ref: Node2D = main_game.player
	var wave_dir = main_game.get_node_or_null("WaveDirector")
	if wave_dir:
		# Seed an intense 55-enemy swarm
		for i in range(55):
			var angle := randf() * TAU
			var dist := randf_range(160.0, 560.0)
			var pos := p_ref.global_position + Vector2(cos(angle), sin(angle)) * dist
			wave_dir._spawn_single_enemy(wave_dir._get_wave_archetype(1, 3), pos, 1, 15.0)

	for _i in range(10):
		await get_tree().process_frame

	print("Recording 60 high-action frames...")
	for step in range(60):
		# Circular evasive tactical motion
		var ang := float(step) * 0.18
		if is_instance_valid(p_ref):
			p_ref.external_move_dir = Vector2(cos(ang), sin(ang)).normalized()

		for _f in range(5):
			await get_tree().process_frame

		var frame_path := ARTIFACT_DIR + "frames_60s/frame_%02d.png" % step
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		if img:
			img.save_png(frame_path)

	print("=== 60-FRAME CAPTURE COMPLETED SUCCESSFULLY! ===")
	get_tree().quit(0)
