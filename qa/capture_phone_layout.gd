extends SceneTree

# GUI screenshot probe. Requires DISPLAY / Xvfb, NOT --headless.
# Usage: godot --path . --rendering-method gl_compatibility --script res://qa/capture_phone_layout.gd -- --out /tmp/screens
var output_dir: String = "/tmp/mutantsurvivor-phone-shots"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		if args[i] == "--out":
			output_dir = args[i + 1]
	call_deferred("_capture")

func _shot(filename: String) -> bool:
	# A few rendered frames allow CanvasItem layout, deferred scene setup and
	# imported textures to complete before reading the viewport.
	for i in range(8):
		await process_frame
	var img: Image = root.get_texture().get_image()
	if img == null or img.is_empty():
		printerr("PHONE SHOT ERROR: empty viewport screenshot " + filename)
		return false
	var err := img.save_png(output_dir.path_join(filename))
	if err != OK:
		printerr("PHONE SHOT ERROR: could not save " + filename + " code=" + str(err))
		return false
	print("PHONE SHOT SAVED: " + output_dir.path_join(filename) + " " + str(img.get_size()))
	return true

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(720, 1280)
	var stage = root.get_node_or_null("StageDirector")
	if stage == null:
		printerr("PHONE SHOT ERROR: StageDirector autoload not available")
		quit(1)
		return
	# Never mutate the real user's save in screenshot automation.
	stage.get_script().set("save_path_override", "user://qa_phone_capture.json")
	stage.orientation_mode = "portrait"
	stage.current_stage = 1
	stage.max_unlocked_stage = 1
	stage.is_practice_mode = true

	var menu_packed: PackedScene = load("res://scenes/ui/main_menu.tscn") as PackedScene
	if menu_packed == null:
		printerr("PHONE SHOT ERROR: menu scene missing")
		quit(1)
		return
	var menu: Control = menu_packed.instantiate() as Control
	root.add_child(menu)
	await process_frame
	menu.call("_apply_responsive_menu_layout")
	if not await _shot("01_menu_720x1280.png"):
		quit(1)
		return
	# Capture the real embedded RPG panel tabs.
	for tab in [1, 2, 3]:
		menu.call("switch_hub_tab", tab)
		await process_frame
		if not await _shot("0%d_hub_tab_%d_720x1280.png" % [tab + 1, tab]):
			quit(1)
			return
	menu.queue_free()
	await process_frame
	await process_frame

	var combat_packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	if combat_packed == null:
		printerr("PHONE SHOT ERROR: combat scene missing")
		quit(1)
		return
	var combat: Node = combat_packed.instantiate()
	root.add_child(combat)
	await process_frame
	combat.call("_apply_responsive_hud_layout")
	if not await _shot("05_combat_720x1280.png"):
		quit(1)
		return
	combat.call("_apply_responsive_hud_layout", 420.0)
	if not await _shot("06_compact_hud_simulation_420.png"):
		quit(1)
		return
	paused = false
	combat.queue_free()
	await process_frame
	print("PHONE SHOT CAPTURE COMPLETED")
	quit(0)
