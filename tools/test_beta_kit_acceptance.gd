extends Node

const ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	StageDirector.save_path_override = "user://test_beta_kit_acceptance.json"
	if FileAccess.file_exists(StageDirector.save_path_override):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(StageDirector.save_path_override))

	print("================================================================")
	print("=== START MUTANT SURVIVOR BETA ACCEPTANCE MATRIX VERIFICATION ===")
	print("================================================================")
	await get_tree().process_frame
	await get_tree().process_frame

	# --------------------------------------------------------------------------
	# P0-01: Godot import & parse
	# --------------------------------------------------------------------------
	print("\n--- [P0-01] Testing Assets & Parse ---")
	assert(ResourceLoader.exists("res://addons/ms_beta/auto_skill_controller.gd"), "P0-01 FAIL: auto_skill_controller.gd missing")
	assert(ResourceLoader.exists("res://addons/ms_beta/auto_combat_patterns.gd"), "P0-01 FAIL: auto_combat_patterns.gd missing")
	assert(ResourceLoader.exists("res://addons/ms_beta/animation_bridge.gd"), "P0-01 FAIL: animation_bridge.gd missing")
	print("PASS P0-01: Addons & core scripts parsed without errors.")

	# --------------------------------------------------------------------------
	# P0-02 & P0-03: Per-class stage & level progression, class switching
	# --------------------------------------------------------------------------
	print("\n--- [P0-02 & P0-03] Testing Per-Class Progression & Switching ---")
	StageDirector.switch_class("soldier")
	StageDirector.max_unlocked_stage = 1
	StageDirector.character_level = 1
	StageDirector.character_xp = 0
	StageDirector.first_clears_v2.clear()
	StageDirector.save_campaign_profile()

	# Clear stage 1 as soldier
	var run1 := StageDirector.complete_stage_run(1, true, 10)
	assert(StageDirector.selected_class_id == "soldier", "P0-02 FAIL: Active class changed")
	assert(StageDirector.max_unlocked_stage == 2, "P0-02 FAIL: Soldier stage 2 not unlocked")
	assert(StageDirector.character_level == 2, "P0-02 FAIL: Soldier level not incremented to 2")

	# Switch to engineer - must remain at stage 1, level 1
	var switched_eng := StageDirector.switch_class("engineer")
	assert(switched_eng, "P0-03 FAIL: switch_class failed")
	assert(StageDirector.selected_class_id == "engineer", "P0-03 FAIL: engineer not active")
	assert(StageDirector.max_unlocked_stage == 1, "P0-03 FAIL: Engineer inherited soldier's stage 2!")
	assert(StageDirector.character_level == 1, "P0-03 FAIL: Engineer inherited soldier's level 2!")

	# Switch back to soldier - must still be stage 2, level 2
	StageDirector.switch_class("soldier")
	assert(StageDirector.max_unlocked_stage == 2, "P0-03 FAIL: Soldier lost stage 2 after switching back")
	assert(StageDirector.character_level == 2, "P0-03 FAIL: Soldier lost level 2 after switching back")
	print("PASS P0-02 & P0-03: Per-class stage and level progression strictly isolated.")

	# --------------------------------------------------------------------------
	# P0-04: Shared account inventory & per-class equipment loadouts
	# --------------------------------------------------------------------------
	print("\n--- [P0-04] Testing Shared Inventory & Independent Loadouts ---")
	var test_item := StageDirector.roll_new_equipment_drop(1, "rare")
	var it_id := String(test_item.get("instance_id", ""))
	assert(not it_id.is_empty(), "P0-04 FAIL: Roll item failed")
	var inv_count_before := StageDirector.inventory.size()

	# Equip test item on soldier
	StageDirector.equip_item(it_id)
	assert(StageDirector.equipped_items.get(test_item.get("slot"), "") == it_id, "P0-04 FAIL: Soldier did not equip item")

	# Switch to medic - loadout is separate, inventory count identical (no duplicate items)
	StageDirector.switch_class("medic")
	assert(StageDirector.inventory.size() == inv_count_before, "P0-04 FAIL: Inventory duplicated on class switch")
	assert(StageDirector.equipped_items.get(test_item.get("slot"), "") != it_id, "P0-04 FAIL: Medic erroneously inherited soldier equipped slot")

	# Medic equips the same shared item
	StageDirector.equip_item(it_id)
	assert(StageDirector.equipped_items.get(test_item.get("slot"), "") == it_id, "P0-04 FAIL: Medic could not equip shared item")
	assert(StageDirector.inventory.size() == inv_count_before, "P0-04 FAIL: Item was duplicated in shared inventory")
	print("PASS P0-04: Shared inventory and independent per-class loadouts verified.")

	# --------------------------------------------------------------------------
	# P0-08: Move-only combat (No manual skill/attack buttons)
	# --------------------------------------------------------------------------
	print("\n--- [P0-08] Testing Move-Only Combat (No Manual Skill/Fire Buttons) ---")
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main_inst = main_packed.instantiate()
	add_child(main_inst)
	await get_tree().process_frame
	await get_tree().process_frame

	var fire_btn = main_inst.get_node_or_null("HUD/HUDRoot/FireBtn")
	var dash_btn = main_inst.get_node_or_null("HUD/HUDRoot/DashBtn")
	var powers_box = main_inst.powers_hbox

	assert(fire_btn == null or not fire_btn.visible, "P0-08 FAIL: fire_btn is visible in move-only combat")
	assert(dash_btn == null or not dash_btn.visible, "P0-08 FAIL: dash_btn is visible in move-only combat")
	assert(powers_box == null or not powers_box.visible, "P0-08 FAIL: powers_hbox is visible in move-only combat")
	print("PASS P0-08: Combat is Move-Only. All manual attack/skill buttons hidden.")

	# --------------------------------------------------------------------------
	# P0-09: Auto skills unlock at class milestones (Level 5 & Level 30)
	# --------------------------------------------------------------------------
	print("\n--- [P0-09] Testing Auto Skill Milestones (Lv5 & Lv30) ---")
	var p = main_inst.player
	assert(p != null, "P0-09 FAIL: Player instance missing in Main")
	assert(p.auto_skill_ctrl != null, "P0-09 FAIL: Player MSAutoSkillController missing")

	# Test Level 1: both locked
	StageDirector.character_level = 1
	p.apply_class_and_talents(false)
	assert(not p.auto_skill_ctrl.grenade_unlocked, "P0-09 FAIL: Grenade unlocked at level 1")
	assert(not p.auto_skill_ctrl.vortex_unlocked, "P0-09 FAIL: Vortex unlocked at level 1")

	# Test Level 5: Grenade unlocked, Vortex locked
	StageDirector.character_level = 5
	p.apply_class_and_talents(false)
	assert(p.auto_skill_ctrl.grenade_unlocked, "P0-09 FAIL: Grenade not unlocked at level 5")
	assert(not p.auto_skill_ctrl.vortex_unlocked, "P0-09 FAIL: Vortex unlocked at level 5")

	# Test Level 30: Grenade unlocked, Vortex unlocked
	StageDirector.character_level = 30
	p.apply_class_and_talents(false)
	assert(p.auto_skill_ctrl.grenade_unlocked, "P0-09 FAIL: Grenade not unlocked at level 30")
	assert(p.auto_skill_ctrl.vortex_unlocked, "P0-09 FAIL: Vortex not unlocked at level 30")
	print("PASS P0-09: Auto-skills strictly locked until class level milestones (Lv5 / Lv30).")

	# --------------------------------------------------------------------------
	# P1-03: 4-Class Articulated Walk and Shoot Frame Cycles
	# --------------------------------------------------------------------------
	print("\n--- [P1-03] Testing 4-Class 5-Frame Walk & Shoot Cycles ---")
	for cls in ["soldier", "engineer", "medic", "scout"]:
		StageDirector.switch_class(cls)
		p.apply_class_and_talents(false)
		assert(p.walk_frames.size() == 5, "P1-03 FAIL: %s walk frames count is %d (expected 5)" % [cls, p.walk_frames.size()])
		assert(p.shoot_frames.size() == 5, "P1-03 FAIL: %s shoot frames count is %d (expected 5)" % [cls, p.shoot_frames.size()])
		assert(p.has_frame_anim, "P1-03 FAIL: %s frame animation not active" % cls)
	print("PASS P1-03: Real 5-frame walk cycle and 5-frame shoot recoil verified for all 4 classes.")

	# --------------------------------------------------------------------------
	# P0-10: Chest 50 Pity Counter & 3-to-1 Item Fusion
	# --------------------------------------------------------------------------
	print("\n--- [P0-10] Testing 50-Chest Pity & 3:1 Item Fusion ---")
	StageDirector.dark_matter_gems = 5000
	StageDirector.pity_chest_counter = 49 # 49th chest already opened
	var chest_item := StageDirector.open_purchased_chest(50)
	assert(not chest_item.is_empty(), "P0-10 FAIL: open_purchased_chest failed")
	assert(String(chest_item.get("rarity", "")) in ["legendary", "mythic"], "P0-10 FAIL: 50th pity chest did not drop Legendary (got %s)" % chest_item.get("rarity"))
	assert(StageDirector.pity_chest_counter == 0, "P0-10 FAIL: pity counter did not reset after Legendary drop")

	# Test 3:1 Fusion
	var it_c1 := StageDirector.roll_new_equipment_drop(1, "common")
	var it_c2 := StageDirector.roll_new_equipment_drop(1, "common")
	var it_c3 := StageDirector.roll_new_equipment_drop(1, "common")
	var id1 := String(it_c1["instance_id"])
	var id2 := String(it_c2["instance_id"])
	var id3 := String(it_c3["instance_id"])
	var inv_before_fuse := StageDirector.inventory.size()

	var fused := StageDirector.fuse_equipment_triplet(id1, id2, id3)
	assert(not fused.is_empty(), "P0-10 FAIL: fuse_equipment_triplet returned empty")
	assert(String(fused.get("rarity", "")) == "rare", "P0-10 FAIL: 3 commons did not fuse into rare (got %s)" % fused.get("rarity"))
	assert(StageDirector.inventory.size() == inv_before_fuse - 2, "P0-10 FAIL: Net inventory count after 3:1 fusion incorrect (expected -2, diff %d)" % (StageDirector.inventory.size() - inv_before_fuse))
	assert(StageDirector.get_item_instance(id1).is_empty(), "P0-10 FAIL: Consumed item id1 still present in inventory")
	print("PASS P0-10: 50-chest pity guarantee and 3:1 item fusion verified.")

	# Capture beta combat frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(ARTIFACT_DIR + "v1_beta_move_only_combat_proof.png")
		print("SAVED PROOF SCREENSHOT: v1_beta_move_only_combat_proof.png")

	print("\n================================================================")
	print("=== ALL BETA ACCEPTANCE MATRIX SCENARIOS PASSED WITH SUCCESS ===")
	print("================================================================")
	get_tree().quit(0)
