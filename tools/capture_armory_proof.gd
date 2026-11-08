extends Control

const ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"
const MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")

func _ready() -> void:
	StageDirector.set_orientation_mode("portrait", true)
	get_viewport().size = Vector2i(720, 1280)
	DisplayServer.window_set_size(Vector2i(720, 1280))

	var menu: Control = MENU_SCENE.instantiate()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)

	for _i in range(10):
		await get_tree().process_frame

	# Switch to Character tab (Armory)
	if menu.has_method("switch_hub_tab"):
		menu.call("switch_hub_tab", 1)

	for _i in range(15):
		await get_tree().process_frame

	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(ARTIFACT_DIR + "v1_armory_clean_pedestal_720x1280.png")
		print("Saved clean armory proof: (" + str(img.get_width()) + "x" + str(img.get_height()) + ")")

	# Also switch to Inventory tab
	if menu.has_method("switch_hub_tab"):
		menu.call("switch_hub_tab", 2)
	for _i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img_inv := get_viewport().get_texture().get_image()
	if img_inv:
		img_inv.save_png(ARTIFACT_DIR + "v1_final_tab_inventory_clean_720x1280.png")

	# Also switch to Store tab
	if menu.has_method("switch_hub_tab"):
		menu.call("switch_hub_tab", 4)
	for _i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img_shop := get_viewport().get_texture().get_image()
	if img_shop:
		img_shop.save_png(ARTIFACT_DIR + "v1_final_tab_store_clean_720x1280.png")

	print("ARMORY AND TABS PROOF SAVED!")
	get_tree().quit(0)
