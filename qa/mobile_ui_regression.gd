extends SceneTree

# Headless structural mobile UI regression. It checks real instantiated Godot
# controls and their constraints; it is NOT a screenshot or device usability test.
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _assert(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		printerr("MOBILE UI FAIL: " + msg)

func _run() -> void:
	await process_frame
	var packed: PackedScene = load("res://scenes/ui/main_menu.tscn") as PackedScene
	_assert(packed != null, "Main menu scene loads")
	if packed == null:
		_finish()
		return

	var menu: Control = packed.instantiate() as Control
	root.add_child(menu)
	await process_frame
	await process_frame
	menu.call("_apply_responsive_menu_layout")
	await process_frame

	var card: Control = menu.get("stage_card") as Control
	var play: Button = menu.get("play_big_btn") as Button
	var hero: Control = menu.get("hero_spacer_control") as Control
	var progress: Label = menu.get("campaign_progress_label") as Label
	var progress_bar: ProgressBar = menu.get("campaign_progress_bar") as ProgressBar
	_assert(is_instance_valid(progress), "Menu campaign progress label exists")
	_assert(is_instance_valid(progress_bar), "Menu campaign progress bar exists")
	if is_instance_valid(progress):
		_assert(progress.text.contains("KAMPANIA"), "Campaign progress status uses game data")
	_assert(is_instance_valid(card), "Stage card is instantiated")
	_assert(is_instance_valid(play), "Play CTA is instantiated")
	_assert(is_instance_valid(hero), "Hero spacer is instantiated")
	if is_instance_valid(card):
		_assert(card.custom_minimum_size.x <= 500, "Stage card does not force previous oversized width")
		_assert(card.custom_minimum_size.y <= 220, "Stage card height is bounded")
	if is_instance_valid(play):
		_assert(play.custom_minimum_size.x <= 420, "Play CTA width is bounded")
		_assert(play.custom_minimum_size.y <= 82, "Play CTA height is bounded")
		_assert(play.pressed.get_connections().size() > 0, "Play CTA has a working signal connection")
	if is_instance_valid(hero):
		_assert(hero.custom_minimum_size.y <= 172, "Hero spacer leaves room for navigation")

	# Exercise the responsive calculations at three portrait sizes without
	# relying on only the default 720px design canvas.
	for test_width in [720.0, 540.0, 420.0]:
		menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
		menu.size = Vector2(test_width, test_width * 16.0 / 9.0)
		menu.call("_apply_responsive_menu_layout")
		var limit := maxf(180.0, test_width - 44.0)
		if is_instance_valid(card):
			_assert(card.custom_minimum_size.x <= limit + 0.01, "Stage card fits %dpx mobile width" % int(test_width))
		if is_instance_valid(play):
			_assert(play.custom_minimum_size.x <= limit + 0.01, "Play button fits %dpx mobile width" % int(test_width))

	var profile: Control = menu.get("user_profile_panel") as Control
	_assert(is_instance_valid(profile), "RPG panel exists in hub")
	if is_instance_valid(profile):
		var nav: HBoxContainer = profile.find_child("StageDirectionRow", true, false) as HBoxContainer
		var jumps: GridContainer = profile.find_child("StageJumpGrid", true, false) as GridContainer
		_assert(is_instance_valid(nav), "Campaign navigation direction row exists")
		_assert(is_instance_valid(jumps), "Campaign chapter shortcut grid exists")
		if is_instance_valid(nav):
			_assert(nav.get_child_count() == 4, "Direction row contains only 4 controls")
		if is_instance_valid(jumps):
			_assert(jumps.columns == 5, "Five campaign shortcuts occupy their own grid")
			_assert(jumps.get_child_count() == 5, "Five chapter shortcuts are present")
		var skins: Dictionary = profile.get("skin_buttons")
		var stage_manager = root.get_node_or_null("StageDirector")
		if stage_manager != null:
			for skin_id in skins.keys():
				var skin_button: Button = skins[skin_id]
				if not stage_manager.unlocked_skins.has(String(skin_id)) and String(skin_id) != "default":
					_assert(skin_button.disabled, "Unowned premium skin %s cannot be selected for free" % String(skin_id))
		var inv_grid: GridContainer = profile.get("inv_grid") as GridContainer
		var filter_grid: GridContainer = profile.get("inv_slot_filters_grid") as GridContainer
		_assert(is_instance_valid(inv_grid), "Backpack slot grid exists")
		_assert(is_instance_valid(filter_grid), "Backpack filters are arranged in a grid")
		if is_instance_valid(filter_grid):
			_assert(filter_grid.columns <= 7, "Filters have a bounded column count")

		var store_categories: GridContainer = profile.get("store_categories_grid") as GridContainer
		var store_cards: GridContainer = profile.get("store_cards_grid") as GridContainer
		var confirmation: ConfirmationDialog = profile.get("store_purchase_dialog") as ConfirmationDialog
		_assert(is_instance_valid(store_categories), "Shop category navigation exists")
		_assert(is_instance_valid(store_cards), "Shop product grid exists")
		_assert(is_instance_valid(confirmation), "Premium purchase requires confirmation")
		if is_instance_valid(store_categories):
			_assert(store_categories.get_child_count() == 4, "Shop has four clear customer categories")
		if is_instance_valid(store_cards):
			_assert(store_cards.get_child_count() == 6, "Shop only shows six curated player-facing offers")

		# Godot headless can preserve its configured 720px root viewport even
		# when root.size is assigned. Drive the SAME production layout function
		# with the requested width explicitly to avoid false test failures.
		var stage_manager_narrow = root.get_node_or_null("StageDirector")
		if stage_manager_narrow != null:
			stage_manager_narrow.orientation_mode = "portrait"
		profile.call("_apply_responsive_metrics", 420.0)
		if is_instance_valid(inv_grid):
			_assert(inv_grid.columns == 2, "420px backpack shows two touch-friendly columns")
		if is_instance_valid(filter_grid):
			_assert(filter_grid.columns == 2, "420px gear filters show two columns")
		if is_instance_valid(store_cards):
			_assert(store_cards.columns == 1, "420px shop uses a single product column")
		if is_instance_valid(store_categories):
			_assert(store_categories.columns == 2, "420px shop navigation wraps to two columns")
		profile.call("_apply_responsive_metrics", 720.0)
		if is_instance_valid(inv_grid):
			_assert(inv_grid.columns == 4, "720px backpack returns to four columns")
		if is_instance_valid(store_cards):
			_assert(store_cards.columns == 2, "720px shop returns to two columns")

	menu.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("MOBILE UI PASS: %d structural checks. Screenshots and real touch QA still required." % checks)
		quit(0)
	else:
		printerr("MOBILE UI FAILED: %d / %d structural checks" % [failures.size(), checks])
		quit(1)
