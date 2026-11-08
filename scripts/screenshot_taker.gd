extends Node2D

func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	var image = get_viewport().get_texture().get_image()
	image.save_png("C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/actual_gameplay_error_check.png")
	print("ERROR_CHECK_SCREENSHOT_CAPTURED")
	get_tree().quit()
