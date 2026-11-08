extends Node

const SCREENSHOT_PATH := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/v1_target_main_menu_720x1280.png"

func _ready() -> void:
	print("STARTING CAPTURE OF TARGET MAIN MENU 9:16")
	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))

	# Ustaw przykładowy stan jak w referencji: Etap 30, Kredyty 2450, Kryształy 185, Próby 5/5
	StageDirector.current_stage = 30
	StageDirector.max_unlocked_stage = 35
	StageDirector.character_level = 12
	StageDirector.credits = 2450
	StageDirector.dark_matter_gems = 185
	StageDirector.attempts = 5

	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu: Node = menu_scene.instantiate()
	add_child(menu)

	# Odczekaj kilka klatek na pełny render i layout
	for _i in range(12):
		await get_tree().process_frame

	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(SCREENSHOT_PATH)
		print("SUCCESS: SAVED SCREENSHOT TO " + SCREENSHOT_PATH + " (" + str(img.get_width()) + "x" + str(img.get_height()) + ")")
	get_tree().quit(0)
