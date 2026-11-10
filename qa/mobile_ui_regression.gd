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

	# Sprint 1: check reusable production components, not hardcoded per-screen colors.
	var sample_button := Button.new()
	SurvivorVisualSystem.decorate_button(sample_button, SurvivorVisualSystem.GOLD)
	_assert(sample_button.custom_minimum_size.y >= 44.0, "Shared UI button meets mobile touch target")
	_assert(sample_button.has_theme_stylebox_override("normal"), "Shared UI has normal button state")
	_assert(sample_button.has_theme_stylebox_override("hover"), "Shared UI has hover button state")
	_assert(sample_button.has_theme_stylebox_override("pressed"), "Shared UI has pressed button state")
	_assert(sample_button.has_theme_stylebox_override("disabled"), "Shared UI has disabled button state")
	var sample_panel := SurvivorVisualSystem.panel(SurvivorVisualSystem.LIME, true)
	_assert(sample_panel.get_border_width(SIDE_TOP) >= 2, "Important card has visible metallic border")
	_assert(SurvivorVisualSystem.rarity_color("legendary") != SurvivorVisualSystem.rarity_color("common"), "Rare gear palette is visually distinct")
	var quick_card := menu.find_child("OperatorQuickActions", true, false)
	_assert(is_instance_valid(quick_card), "Home screen has functional operator shortcuts")
	if is_instance_valid(quick_card):
		var quick_buttons: Array[Node] = quick_card.find_children("*", "Button", true, false)
		_assert(quick_buttons.size() == 3, "Operator dashboard exposes 3 live navigation shortcuts")
		for quick in quick_buttons:
			_assert((quick as Button).pressed.get_connections().size() > 0, "Shortcut has connected action")

	# Package 1: artwork must be wired to actual interactive home controls.
	var production_overlay: Control = menu.find_child("BaseProductionOverlay", true, false) as Control
	_assert(is_instance_valid(production_overlay), "Base production overlay exists")
	if is_instance_valid(production_overlay):
		var logo: TextureRect = production_overlay.find_child("MutantSurvivorLogo", true, false) as TextureRect
		_assert(is_instance_valid(logo) and logo.texture != null, "Real branded MutantSurvivor logo texture is loaded")
		_assert(is_instance_valid(logo) and logo.texture.resource_path.ends_with("logo_reference_exact.png"), "Logo uses approved raster wordmark")
		var logo_letters: HBoxContainer = production_overlay.find_child("BrandedLogoLetters", true, false) as HBoxContainer
		_assert(is_instance_valid(logo_letters) and not logo_letters.visible, "Older duplicate logo lettering is hidden")
		var left_actions: VBoxContainer = production_overlay.find_child("BaseLeftActions", true, false) as VBoxContainer
		var right_actions: VBoxContainer = production_overlay.find_child("BaseRightActions", true, false) as VBoxContainer
		_assert(is_instance_valid(left_actions) and left_actions.get_child_count() == 3, "Three left base actions exist")
		_assert(is_instance_valid(right_actions) and right_actions.get_child_count() == 2, "Two right base actions exist")
		if is_instance_valid(left_actions) and left_actions.get_child_count() == 3:
			var approved_labels := ["POCZTA", "ZADANIA", "PRZEPUSTKA"]
			for i in range(3):
				var shortcut: Button = left_actions.get_child(i) as Button
				_assert(is_instance_valid(shortcut) and String(shortcut.get_meta("full_label", "")) == approved_labels[i],
					"Approved home left shortcut %d has correct live destination label" % i)
				if is_instance_valid(shortcut):
					_assert(shortcut.pressed.get_connections().size() >= 1,
						"Approved shortcut %d remains clickable" % i)

		for actions in [left_actions, right_actions]:
			if is_instance_valid(actions):
				for action in actions.get_children():
					var action_button: Button = action as Button
					_assert(is_instance_valid(action_button), "Base shortcut is a real Button")
					if is_instance_valid(action_button):
						_assert(action_button.pressed.get_connections().size() > 0, "Base shortcut has a live click handler")
						var tile_icon: TextureRect = action_button.find_child("SideActionIcon", true, false) as TextureRect
						var tile_caption: Label = action_button.find_child("SideActionCaption", true, false) as Label
						_assert(is_instance_valid(tile_icon) and tile_icon.texture != null, "Side tile contains real icon art")
						_assert(is_instance_valid(tile_caption) and not tile_caption.text.is_empty(), "Side tile has a readable caption")

	var campaign_continue: Button = menu.find_child("ContinueCampaignButton", true, false) as Button
	_assert(is_instance_valid(campaign_continue), "Home has dedicated Continue Campaign action")
	if is_instance_valid(campaign_continue):
		_assert(campaign_continue.pressed.get_connections().size() > 0, "Continue Campaign has real navigation callback")
		_assert(campaign_continue.custom_minimum_size.y >= 44.0, "Continue Campaign is touch friendly")

	# Approved portrait reference shows four PRIMARY buttons. The fifth
	# internal campaign view is accessed through the functional mission link.
	_assert(ResourceLoader.exists("res://assets/ui/approved/icon_daily_tasks.svg", "Texture2D"), "Tasks icon imports")
	_assert(ResourceLoader.exists("res://assets/ui/approved/icon_battle_pass.svg", "Texture2D"), "Pass icon imports")
	var approved_map_link: Button = menu.find_child("OpenCampaignMap", true, false) as Button
	_assert(is_instance_valid(approved_map_link), "Home mission header links to the full 100-stage campaign")
	if is_instance_valid(approved_map_link):
		_assert(approved_map_link.pressed.get_connections().size() > 0, "Campaign map link has a real callback")
	var decorative_progress: Control = menu.find_child("CampaignProgressCard", true, false) as Control
	_assert(is_instance_valid(decorative_progress) and not decorative_progress.visible, "Old duplicate roadmap is hidden on approved home")
	var navigation_buttons: Array = menu.get("nav_buttons")
	_assert(navigation_buttons.size() == 5, "All five functional game views remain registered")
	if navigation_buttons.size() == 5 and StageDirector.is_portrait_mode():
		_assert(not navigation_buttons[3].visible, "Portrait navigation shows four tabs, not five duplicate campaign buttons")
	if navigation_buttons.size() == 5:
		for tab in navigation_buttons:
			var nav_button: Button = tab as Button
			_assert(not nav_button.flat, "Bottom navigation renders its own highlighted panel")
			_assert(nav_button.has_theme_stylebox_override("normal"), "Bottom tab has actual state-specific style")
			var icon_nodes: Array[Node] = nav_button.find_children("*", "TextureRect", true, false)
			_assert(icon_nodes.size() >= 1, "Bottom navigation has an icon node")
			if not icon_nodes.is_empty():
				var nav_art: TextureRect = icon_nodes[0] as TextureRect
				_assert(is_instance_valid(nav_art) and nav_art.texture != null, "Bottom navigation icon is a real texture")
		menu.call("switch_hub_tab", 2)
		var equipment_button: Button = navigation_buttons[2] as Button
		_assert(equipment_button.has_theme_stylebox_override("normal"), "Selected equipment tab stays visually styled")
		menu.call("switch_hub_tab", 0)

	_assert(ResourceLoader.exists("res://assets/ui/approved/mission_card_frame.svg", "Texture2D"),
		"Approved cyan steel mission frame imports as a real Godot texture")
	var mission_card_panel: PanelContainer = menu.get("stage_card") as PanelContainer
	if is_instance_valid(mission_card_panel):
		_assert(mission_card_panel.has_theme_stylebox_override("panel"),
			"Approved mission art is applied to the live campaign card")
	var card: Control = menu.get("stage_card") as Control
	var play: Button = menu.get("play_big_btn") as Button
	var hero: Control = menu.get("hero_spacer_control") as Control
	var progress: Label = menu.get("campaign_progress_label") as Label
	var progress_bar: ProgressBar = menu.get("campaign_progress_bar") as ProgressBar
	_assert(is_instance_valid(progress), "Menu campaign progress label exists")
	_assert(is_instance_valid(progress_bar), "Menu campaign progress bar exists")
	var milestone_row: HBoxContainer = menu.find_child("CampaignMilestones", true, false) as HBoxContainer
	_assert(is_instance_valid(milestone_row), "Campaign progress has visible stage milestones")
	if is_instance_valid(milestone_row):
		_assert(milestone_row.get_child_count() == 5, "Five progress milestones are shown")
		for marker in milestone_row.get_children():
			var marker_label: Label = marker as Label
			_assert(is_instance_valid(marker_label) and not marker_label.text.is_empty(), "Progress marker contains live level text")

	if is_instance_valid(progress):
		_assert(progress.text.contains("KAMPANIA"), "Campaign progress status uses game data")
	_assert(is_instance_valid(card), "Stage card is instantiated")
	if is_instance_valid(card):
		var reference_frame: StyleBox = card.get_theme_stylebox("panel")
		_assert(reference_frame is StyleBoxTexture, "Mission card renders genuine approved reference art")
		if reference_frame is StyleBoxTexture:
			_assert((reference_frame as StyleBoxTexture).texture != null, "Reference frame has a live imported texture")

	_assert(is_instance_valid(play), "Play CTA is instantiated")
	_assert(is_instance_valid(hero), "Hero spacer is instantiated")
	if is_instance_valid(card):
		_assert(card.custom_minimum_size.x <= 640, "Armored stage card remains responsive")
		_assert(card.custom_minimum_size.y <= 330, "Illustrated stage card remains within mobile vertical budget")
	if is_instance_valid(play):
		_assert(play.custom_minimum_size.x <= 600, "Reference-size play CTA width is bounded")
		_assert(play.custom_minimum_size.y <= 100, "Reference-size play CTA height is bounded")
		_assert(play.pressed.get_connections().size() > 0, "Play CTA has a working signal connection")
	if is_instance_valid(hero):
		_assert(hero.custom_minimum_size.y <= 410, "Hero showcase remains bounded above the mission panel")

	# Exercise the responsive calculations at three portrait sizes without
	# relying on only the default 720px design canvas.
	for test_width in [720.0, 540.0, 420.0]:
		menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
		menu.size = Vector2(test_width, test_width * 16.0 / 9.0)
		menu.call("_apply_responsive_menu_layout")
		if test_width == 420.0:
			var settings_card: PanelContainer = menu.find_child("SettingsCard", true, false) as PanelContainer
			_assert(is_instance_valid(settings_card), "Settings dialog has a real responsive panel")
			if is_instance_valid(settings_card):
				_assert(settings_card.custom_minimum_size.x <= 396.0, "420px settings panel fits with side margins")
				var settings_title: Label = settings_card.find_child("SettingsTitle", true, false) as Label
				_assert(is_instance_valid(settings_title) and settings_title.get_theme_font_size("font_size") <= 13, "420px settings heading is compact")
				var volume_rows: Array[Node] = []
				for item in settings_card.get_child(0).get_children():
					if item is HBoxContainer and item.has_node("SettingsVolumeSlider"):
						volume_rows.append(item)
				_assert(volume_rows.size() == 3, "Settings has all three audio sliders")
				for volume_row in volume_rows:
					var volume_label := volume_row.find_child("SettingsVolumeLabel", false, false) as Label
					var volume_slider := volume_row.find_child("SettingsVolumeSlider", false, false) as HSlider
					_assert(is_instance_valid(volume_label) and volume_label.custom_minimum_size.x <= 104.0, "420px audio label leaves room for slider")
					_assert(is_instance_valid(volume_slider) and volume_slider.custom_minimum_size.x >= 118.0, "420px audio slider remains usable")
				var settings_languages: HBoxContainer = settings_card.find_child("SettingsLanguageRow", true, false) as HBoxContainer
				_assert(is_instance_valid(settings_languages) and settings_languages.get_child_count() == 4, "Settings includes a language label and three options")
				if is_instance_valid(settings_languages):
					for option in settings_languages.get_children():
						if option is Button:
							_assert(option.custom_minimum_size.y >= 44.0, "Language switch remains touch-friendly")
				var close_settings: Button = settings_card.find_child("SettingsCloseButton", true, false) as Button
				_assert(is_instance_valid(close_settings) and close_settings.custom_minimum_size.y >= 48.0, "Settings close control has safe touch size")
			_assert(hero.custom_minimum_size.y <= 220.0, "420px Base switches to compact hero spacing")
			_assert(card.custom_minimum_size.y <= 310.0, "420px Base keeps compact mission card")
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
			for nav_control in nav.get_children():
				if nav_control is Button:
					_assert((nav_control as Button).custom_minimum_size.y >= 44.0, "Campaign navigation meets touch target")
		if is_instance_valid(jumps):
			_assert(jumps.columns == 5, "Five stage shortcuts occupy their own grid")
			_assert(jumps.get_child_count() == 5, "Five quick stage shortcuts remain")
			for stage_shortcut in jumps.get_children():
				if stage_shortcut is Button:
					_assert((stage_shortcut as Button).custom_minimum_size.y >= 44.0, "Stage shortcut meets touch target")
		var campaign_reward_strip: PanelContainer = profile.find_child("CampaignRewardStrip", true, false) as PanelContainer
		_assert(is_instance_valid(campaign_reward_strip), "Campaign displays illustrated reward strip")
		if is_instance_valid(campaign_reward_strip):
			for reward_name in ["Credits", "Scrap", "Equipment"]:
				var reward_icon: TextureRect = campaign_reward_strip.find_child("CampaignRewardIcon" + reward_name, true, false) as TextureRect
				var reward_value: Label = campaign_reward_strip.find_child("CampaignRewardValue" + reward_name, true, false) as Label
				_assert(is_instance_valid(reward_icon) and reward_icon.texture != null, "Campaign reward has actual artwork: " + reward_name)
				_assert(is_instance_valid(reward_value) and not reward_value.text.is_empty(), "Campaign reward shows a real label: " + reward_name)
		var chapters: GridContainer = profile.find_child("CampaignChapterMap", true, false) as GridContainer
		_assert(is_instance_valid(chapters), "Ten-chapter graphical campaign roadmap exists")
		if is_instance_valid(chapters):
			_assert(chapters.get_child_count() == 10, "Campaign roadmap contains all ten chapters")
			var director = root.get_node_or_null("StageDirector")
			if director != null:
				for index in range(10):
					var chapter_button: Button = chapters.get_child(index) as Button
					var required_stage := index * 10 + 1
					_assert(chapter_button.disabled == (required_stage > director.max_unlocked_stage), "Chapter %d enforces stage unlocks" % (index + 1))
		var skins: Dictionary = profile.get("skin_buttons")
		var stage_manager = root.get_node_or_null("StageDirector")
		if stage_manager != null:
			for skin_id in skins.keys():
				var skin_button: Button = skins[skin_id]
				if not stage_manager.unlocked_skins.has(String(skin_id)) and String(skin_id) != "default":
					_assert(skin_button.disabled, "Unowned premium skin %s cannot be selected for free" % String(skin_id))
		var bag: GridContainer = profile.find_child("MetinBackpackGrid", true, false) as GridContainer
		_assert(is_instance_valid(bag), "Metin-style equipment has a real backpack grid")
		if is_instance_valid(bag):
			_assert(bag.columns == 5, "Full-size portrait has five columns of backpack slots")
			_assert(bag.get_child_count() >= 30, "Inventory has at least 30 populated or empty grid cells")
		var quick_equip: Button = profile.find_child("InventoryQuickEquip", true, false) as Button
		var quick_unequip: Button = profile.find_child("InventoryQuickUnequip", true, false) as Button
		var action_row: HBoxContainer = profile.find_child("InventoryQuickActions", true, false) as HBoxContainer
		_assert(is_instance_valid(action_row), "Equip and unequip available in Inventory")
		for action_name in ["InventoryQuickEquip", "InventoryQuickUnequip"]:
			var action: Button = profile.find_child(action_name, true, false) as Button
			_assert(is_instance_valid(action), action_name + " is a native button")
			if is_instance_valid(action):
				_assert(action.pressed.get_connections().size() > 0, action_name + " has a live handler")
				_assert(action.custom_minimum_size.y >= 44.0, action_name + " meets touch target")
		# Inventory v3: 30-cell paging with readable, touch-sized controls.
		var previous_page: Button = profile.find_child("InventoryPagePrevious", true, false) as Button
		var next_page: Button = profile.find_child("InventoryPageNext", true, false) as Button
		var page_label: Label = profile.find_child("InventoryPageLabel", true, false) as Label
		_assert(is_instance_valid(previous_page) and is_instance_valid(next_page), "Inventory has real previous/next page buttons")
		_assert(is_instance_valid(page_label), "Inventory displays current page and page count")
		for page_button in [previous_page, next_page]:
			if is_instance_valid(page_button):
				_assert(page_button.custom_minimum_size.y >= 44.0, "Inventory paging meets 44px touch target")
				_assert(page_button.pressed.get_connections().size() > 0, "Inventory paging button is functional")
		var detail_actions: GridContainer = profile.find_child("InventoryDetailActions", true, false) as GridContainer
		_assert(is_instance_valid(detail_actions), "Inventory has usable action controls")
		if is_instance_valid(detail_actions):
			for action in detail_actions.get_children():
				if action is Button:
					_assert(action.custom_minimum_size.y >= 44.0, "Inventory detail action has a safe touch height")
		# Exercise the page boundary with disposable copies of real equipment.
		if stage_manager != null and is_instance_valid(bag) and is_instance_valid(previous_page) and is_instance_valid(next_page) and is_instance_valid(page_label) and not stage_manager.inventory.is_empty():
			var original_inventory: Array = stage_manager.inventory.duplicate(true)
			var selected_before: String = String(profile.get("selected_bag_instance_id"))
			var original_page: int = int(profile.get("inventory_page"))
			var original_filter: String = String(profile.get("filter_slot"))
			var original_rarity: String = String(profile.get("filter_rarity"))
			stage_manager.inventory = []
			for slot_num in range(35):
				var fake_item: Dictionary = original_inventory[0].duplicate(true)
				fake_item["instance_id"] = "__qa_page_%02d" % slot_num
				stage_manager.inventory.append(fake_item)
			profile.set("filter_slot", "all")
			profile.set("filter_rarity", "all")
			profile.set("selected_bag_instance_id", "")
			profile.set("inventory_page", 0)
			profile.call("_refresh_inventory_tab_ui")
			await process_frame
			_assert(bag.get_child_count() == 30, "Page one renders exactly 30 slots, not all 35 items")
			_assert(page_label.text.contains("1 / 2"), "First page heading matches 35-item fixture")
			_assert(not next_page.disabled and previous_page.disabled, "First page can advance only")
			var page_one_selection: String = String(profile.get("selected_bag_instance_id"))
			profile.set("inventory_page", 1)
			profile.set("selected_bag_instance_id", "")
			profile.call("_refresh_inventory_tab_ui")
			await process_frame
			_assert(bag.get_child_count() == 30, "Last page displays 5 items plus 25 empty slots")
			var empty_slots: int = 0
			for cell in bag.get_children():
				if cell.name.begins_with("BackpackEmpty_"):
					empty_slots += 1
			_assert(empty_slots == 25, "Second page contains precisely 25 empty slots")
			_assert(next_page.disabled and not previous_page.disabled, "Final page can navigate back only")
			_assert(String(page_label.text).contains("2 / 2"), "Page label reflects actual item count")
			_assert(not String(profile.get("selected_bag_instance_id")).is_empty() and String(profile.get("selected_bag_instance_id")) != page_one_selection, "Second page selects a different visible item regardless of sorting")
			_assert(not previous_page.disabled and next_page.disabled, "Page boundaries remain enforced after refresh")
			stage_manager.inventory = original_inventory
			profile.set("filter_slot", original_filter)
			profile.set("filter_rarity", original_rarity)
			profile.set("selected_bag_instance_id", selected_before)
			profile.set("inventory_page", original_page)
			profile.call("_refresh_inventory_tab_ui")
			await process_frame
		# Repeated inventory refresh is synchronous: never retain old active cells.
		if is_instance_valid(bag):
			for repeat_index in range(3):
				profile.call("_refresh_inventory_tab_ui")
				_assert(bag.get_child_count() == 30, "Inventory refresh keeps exactly 30 live slots")
		var empty_state: Label = profile.find_child("InventoryEmptyState", true, false) as Label
		_assert(is_instance_valid(empty_state), "Inventory has an accessible empty-filter message")
		# Filtering to zero matches must clear stale selected items before any
		# equip or unequip action; preserve the user's state after the test.
		if is_instance_valid(bag):
			var prior_slot_filter: String = String(profile.get("filter_slot"))
			var prior_selected_id: String = String(profile.get("selected_bag_instance_id"))
			profile.set("filter_slot", "__qa_no_such_slot__")
			profile.call("_refresh_inventory_tab_ui")
			_assert(String(profile.get("selected_bag_instance_id")).is_empty(), "Empty filter clears selected backpack item")
			_assert(is_instance_valid(empty_state) and empty_state.visible, "Empty filter gives visible feedback")
			_assert(bag.get_child_count() == 30, "Empty filter renders 30 placeholder slots")
			if is_instance_valid(previous_page) and is_instance_valid(next_page):
				_assert(previous_page.disabled and next_page.disabled, "Empty filter disables paging")
			_assert(is_instance_valid(quick_equip) and quick_equip.disabled, "Empty filter disables quick equip")
			_assert(is_instance_valid(quick_unequip) and quick_unequip.disabled, "Empty filter disables quick unequip")
			profile.set("filter_slot", prior_slot_filter)
			profile.set("selected_bag_instance_id", prior_selected_id)
			profile.call("_refresh_inventory_tab_ui")
		if stage_manager != null and is_instance_valid(bag):
			var saved_for_empty: Array = stage_manager.inventory.duplicate(true)
			stage_manager.inventory = []
			profile.set("filter_slot", "all")
			profile.set("selected_bag_instance_id", "")
			profile.call("_refresh_inventory_tab_ui")
			_assert(is_instance_valid(empty_state) and empty_state.visible, "Empty backpack shows explanatory message")
			_assert(String(profile.get("selected_bag_instance_id")).is_empty(), "Empty backpack has no selection")
			stage_manager.inventory = saved_for_empty
			profile.call("_refresh_inventory_tab_ui")
		for slot_id in ["weapon", "chest", "boots", "helmet", "gloves", "amulet"]:
			var paperdoll_slot: Button = profile.find_child("EquipSlot_" + slot_id, true, false) as Button
			_assert(is_instance_valid(paperdoll_slot), "Paperdoll includes " + slot_id)
			if is_instance_valid(paperdoll_slot):
				_assert(paperdoll_slot.pressed.get_connections().size() > 0, "Paperdoll slot is clickable: " + slot_id)
		var inv_grid: GridContainer = profile.get("inv_grid") as GridContainer
		var filter_grid: GridContainer = profile.get("inv_slot_filters_grid") as GridContainer
		_assert(is_instance_valid(inv_grid), "Backpack slot grid exists")
		_assert(is_instance_valid(filter_grid), "Backpack filters are arranged in a grid")
		if is_instance_valid(filter_grid):
			_assert(filter_grid.columns <= 7, "Filters have a bounded column count")

		var rewards_grid: GridContainer = profile.get("daily_grid") as GridContainer
		_assert(is_instance_valid(rewards_grid), "Daily rewards calendar exists")
		if is_instance_valid(rewards_grid):
			_assert(rewards_grid.get_child_count() == 7, "All seven daily rewards have real cards")
			for reward_panel in rewards_grid.get_children():
				_assert(reward_panel.custom_minimum_size.y >= 120.0, "Daily reward card stays usable in compact portrait layout")
				var claim_buttons := reward_panel.find_children("*", "Button", true, false)
				_assert(claim_buttons.size() == 1, "Each daily reward has exactly one claim action")
				if not claim_buttons.is_empty():
					var reward_button: Button = claim_buttons[0] as Button
					_assert(reward_button.custom_minimum_size.y >= 44.0, "Claim reward button is touch friendly")
		var depot: PanelContainer = profile.find_child("StoreDepotBanner", true, false) as PanelContainer
		_assert(is_instance_valid(depot), "Shop has its own production depot illustration")
		if is_instance_valid(depot):
			_assert(depot.custom_minimum_size.y >= 130.0, "Shop artwork retains usable preview height")
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
			for offer in store_cards.get_children():
				var offer_badge: TextureRect = offer.find_child("StoreProductBadge", true, false) as TextureRect
				_assert(is_instance_valid(offer_badge) and offer_badge.texture != null, "Each shop offer has a dedicated category emblem")
				var offer_art: TextureRect = offer.find_child("StoreProductArtwork", true, false) as TextureRect
				var offer_title: Label = offer.find_child("StoreProductTitle", true, false) as Label
				var offer_purchase: Button = offer.find_child("StoreProductPurchase", true, false) as Button
				_assert(is_instance_valid(offer_art) and offer_art.texture != null, "Shop offer uses real item art")
				_assert(is_instance_valid(offer_title) and not offer_title.text.is_empty(), "Shop offer has visible title")
				_assert(is_instance_valid(offer_purchase) and offer_purchase.custom_minimum_size.y >= 44.0, "Shop offer purchase action meets touch target")

		# Repeated profile refreshes must replace, not accumulate, live cards.
		# Godot queue_free() is deferred: child count must be correct immediately,
		# not only after another frame (as happened in the failed build).
		if is_instance_valid(rewards_grid) and is_instance_valid(store_cards):
			for refresh_index in range(3):
				profile.call("refresh_ui")
				_assert(rewards_grid.get_child_count() == 7, "Daily cards stay at seven after refresh %d" % (refresh_index + 1))
				_assert(store_cards.get_child_count() == 6, "Shop cards stay at six after refresh %d" % (refresh_index + 1))
			await process_frame
			_assert(rewards_grid.get_child_count() == 7, "Daily card count stays stable on next frame")
			_assert(store_cards.get_child_count() == 6, "Shop card count stays stable on next frame")

		# Godot headless can preserve its configured 720px root viewport even
		# when root.size is assigned. Drive the SAME production layout function
		# with the requested width explicitly to avoid false test failures.
		var stage_manager_narrow = root.get_node_or_null("StageDirector")
		if stage_manager_narrow != null:
			stage_manager_narrow.orientation_mode = "portrait"
		profile.call("_apply_responsive_metrics", 420.0)
		var map_expander: Button = profile.find_child("CampaignChapterToggle", true, false) as Button
		var chapter_map: GridContainer = profile.find_child("CampaignChapterMap", true, false) as GridContainer
		_assert(is_instance_valid(map_expander) and map_expander.visible, "420px campaign exposes chapter map toggle")
		_assert(is_instance_valid(chapter_map) and not chapter_map.visible, "420px campaign initially collapses long map")
		if is_instance_valid(map_expander) and is_instance_valid(chapter_map):
			map_expander.pressed.emit()
			_assert(chapter_map.visible, "Chapter map expands on tap")
			map_expander.pressed.emit()
			_assert(not chapter_map.visible, "Chapter map collapses on second tap")
		if is_instance_valid(rewards_grid):
			_assert(rewards_grid.columns == 2, "Compact rewards retain two usable columns")
			for reward_panel in rewards_grid.get_children():
				_assert(reward_panel.custom_minimum_size.y <= 124.0, "Compact reward cards do not waste vertical space")
		var pedestal: PanelContainer = profile.get("hero_pedestal") as PanelContainer
		_assert(is_instance_valid(pedestal), "Character showcase has a real illustrated hangar panel")
		if is_instance_valid(pedestal):
			_assert(pedestal.custom_minimum_size.x <= 166.0, "420px character display does not force a 280px pedestal")
			_assert(is_instance_valid(pedestal.get_node_or_null("ArmoryBackdrop")), "Operator hangar art exists within character panel")
		if is_instance_valid(inv_grid):
			_assert(inv_grid.columns == 4, "420px Metin backpack shows four touch-friendly columns")
		for quick_action in [quick_equip, quick_unequip]:
			if is_instance_valid(quick_action):
				_assert(quick_action.custom_minimum_size.x <= 72.0, "420px quick equip buttons fit bordered panel")
		if is_instance_valid(detail_actions):
			_assert(detail_actions.columns == 1, "420px equipment details stack actions vertically")
		if is_instance_valid(filter_grid):
			_assert(filter_grid.columns == 2, "420px gear filters show two columns")
		if is_instance_valid(store_cards):
			_assert(store_cards.columns == 1, "420px shop uses a single product column")
			var small_offer_art: TextureRect = profile.find_child("StoreProductArtwork", true, false) as TextureRect
			if is_instance_valid(small_offer_art):
				_assert(small_offer_art.custom_minimum_size.x <= 90.0, "420px shop art leaves room for legible product text")
			var small_offer_title: Label = profile.find_child("StoreProductTitle", true, false) as Label
			var small_offer_description: Label = profile.find_child("StoreProductDescription", true, false) as Label
			if is_instance_valid(small_offer_title):
				_assert(small_offer_title.get_theme_font_size("font_size") >= 14, "420px product titles use larger typography")
			if is_instance_valid(small_offer_description):
				_assert(small_offer_description.get_theme_font_size("font_size") >= 12, "420px product descriptions remain readable")
		if is_instance_valid(store_categories):
			_assert(store_categories.columns == 2, "420px shop navigation wraps to two columns")
			for category_control in store_categories.get_children():
				if category_control is Button:
					_assert(category_control.custom_minimum_size.y >= 44.0, "420px shop category has a usable tap target")
		profile.call("_apply_responsive_metrics", 720.0)
		if is_instance_valid(inv_grid):
			_assert(inv_grid.columns == 5, "720px Metin backpack returns to five columns")
		_assert(is_instance_valid(profile.find_child("ProfileContentScroll", true, false)), "Profile exposes scroll viewport for real screenshot QA")
		if is_instance_valid(detail_actions):
			_assert(detail_actions.columns == 3, "720px equipment details use compact three-action row")
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
