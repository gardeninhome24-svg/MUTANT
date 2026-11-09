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
	var expected_size := Vector2i(420, 933) if filename.contains("420x933") else Vector2i(720, 1280)
	if img.get_size() != expected_size:
		printerr("PHONE SHOT ERROR: unexpected viewport size for %s: %s expected %s" % [filename, img.get_size(), expected_size])
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
	# Capture actual player-facing tabs: hero, equipment, campaign, shop
	# and rewards. These are rendered Godot frames, not visual mockups.
	var tab_names := ["character", "equipment", "campaign", "shop", "rewards"]
	for tab in range(1, 6):
		menu.call("switch_hub_tab", tab)
		await process_frame
		if not await _shot("0%d_%s_720x1280.png" % [tab + 1, tab_names[tab - 1]]):
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
	if not await _shot("07_combat_720x1280.png"):
		quit(1)
		return
	# Actually resize the GUI window; passing 420 to a layout function while
	# keeping a 720px viewport produced a misleading screenshot previously.
	var compact_size := Vector2i(420, 933)
	# The configured portrait canvas is 720 logical pixels. Override its
	# content scale here too: otherwise 420 physical pixels merely show a
	# shrunken 720px UI and do not exercise true narrow layouts.
	root.content_scale_size = compact_size
	root.size = compact_size
	DisplayServer.window_set_size(compact_size)
	for i in range(6):
		await process_frame
	combat.call("_apply_responsive_hud_layout")
	for i in range(4):
		await process_frame
	var stats: Control = combat.get("stats_card") as Control
	var currency: Control = combat.get("currency_bar") as Control
	var wave: Control = combat.get("wave_progress_box") as Control
	if is_instance_valid(stats) and is_instance_valid(currency):
		if stats.get_global_rect().intersects(currency.get_global_rect()):
			printerr("PHONE SHOT ERROR: phone stats and wallet overlap")
			quit(1)
			return
	if is_instance_valid(currency) and is_instance_valid(wave):
		if currency.get_global_rect().intersects(wave.get_global_rect()):
			printerr("PHONE SHOT ERROR: phone wallet and wave counter overlap")
			quit(1)
			return
	if not await _shot("08_combat_420x933.png"):
		quit(1)
		return
	paused = false
	combat.queue_free()
	await process_frame
	await process_frame
	# Also render the narrow phone store and equipment. The prior workflow
	# only showed combat at 420px, so responsive item-card issues were hidden.
	var compact_menu: Control = menu_packed.instantiate() as Control
	root.add_child(compact_menu)
	await process_frame
	compact_menu.call("_apply_responsive_menu_layout")
	compact_menu.call("switch_hub_tab", 4)
	for i in range(4):
		await process_frame
	# Check real rendered geometry, not only minimum sizes or mocked offsets.
	var settings: Control = compact_menu.get("settings_btn") as Control
	if is_instance_valid(settings):
		var settings_rect := settings.get_global_rect()
		if settings_rect.position.x < 0.0 or settings_rect.end.x > 420.0:
			printerr("PHONE SHOT ERROR: settings clipped in 420px hub: " + str(settings_rect))
			quit(1)
			return
	if not await _shot("09_shop_420x933.png"):
		quit(1)
		return
	compact_menu.call("switch_hub_tab", 2)
	if not await _shot("10_equipment_420x933.png"):
		quit(1)
		return
	compact_menu.queue_free()
	await process_frame
	print("PHONE SHOT CAPTURE COMPLETED")
	quit(0)
