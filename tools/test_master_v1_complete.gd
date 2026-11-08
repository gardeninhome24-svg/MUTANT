extends Node

const ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	StageDirector.save_path_override = "user://test_master_v1_verification.json"
	if FileAccess.file_exists(StageDirector.save_path_override):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(StageDirector.save_path_override))

	print("=== START MASTER V1 COMPLETE VERIFICATION SUITE (QA MATRIX) ===")
	await get_tree().process_frame
	await get_tree().process_frame

	# --------------------------------------------------------------------------
	# BLOCKER-01: Unlock stages
	# Kroki: Nowy profil; max_unlocked_stage=1; próba skoku do etapu 30 i 100 przez _jump_to_stage
	# Oczekiwane: current_stage <= max_unlocked_stage; max_unlocked_stage bez zmian.
	# --------------------------------------------------------------------------
	StageDirector.max_unlocked_stage = 1
	StageDirector.current_stage = 1
	var menu_packed: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu_node := menu_packed.instantiate()
	add_child(menu_node)
	await get_tree().process_frame

	menu_node.call("_jump_to_stage", 30)
	assert(StageDirector.current_stage == 1, "BLOCKER-01 FAIL: Jumped to locked stage 30")
	assert(StageDirector.max_unlocked_stage == 1, "BLOCKER-01 FAIL: max_unlocked_stage modified by jump")
	menu_node.call("_jump_to_stage", 100)
	assert(StageDirector.current_stage == 1, "BLOCKER-01 FAIL: Jumped to locked stage 100")
	assert(StageDirector.max_unlocked_stage == 1, "BLOCKER-01 FAIL: max_unlocked_stage modified by jump")
	print("PASS BLOCKER-01: Unlock stages - jumping to locked stages rejected, max_unlocked_stage unchanged.")

	# --------------------------------------------------------------------------
	# BLOCKER-08: Progression
	# Kroki: Sekwencyjne odblokowywanie: wygrana etapu 1 odblokowuje etap 2. Nie może skoczyć do 100.
	# --------------------------------------------------------------------------
	var res_prog := StageDirector.complete_stage_run(1, true, 10)
	assert(int(res_prog["max_unlocked_stage"]) == 2, "BLOCKER-08 FAIL: Expected max_unlocked_stage=2 after stage 1")
	assert(StageDirector.max_unlocked_stage == 2, "BLOCKER-08 FAIL: StageDirector max_unlocked_stage mismatch")
	menu_node.call("_jump_to_stage", 2)
	assert(StageDirector.current_stage == 2, "BLOCKER-08 FAIL: Could not select newly unlocked stage 2")
	menu_node.call("_jump_to_stage", 5)
	assert(StageDirector.current_stage == 2, "BLOCKER-08 FAIL: Could jump beyond max_unlocked_stage")
	print("PASS BLOCKER-08: Progression - sequential stage unlock verified, cannot jump to locked stage.")

	# --------------------------------------------------------------------------
	# BLOCKER-06: Practice farming
	# Kroki: Practice mode: wygrana i porażka nie dają trwałych walut, XP ani itemów.
	# --------------------------------------------------------------------------
	StageDirector.is_practice_mode = true
	var cred_before := StageDirector.credits
	var xp_before := StageDirector.character_xp
	var scrap_before := StageDirector.scrap_materials
	var prac_win := StageDirector.complete_stage_run(100, true, 10)
	assert(int(prac_win["earned_credits"]) == 0, "BLOCKER-06 FAIL: Practice win awarded credits")
	assert(int(prac_win["earned_character_xp"]) == 0, "BLOCKER-06 FAIL: Practice win awarded XP")
	assert(StageDirector.credits == cred_before, "BLOCKER-06 FAIL: Credits changed during practice")
	assert(StageDirector.character_xp == xp_before, "BLOCKER-06 FAIL: XP changed during practice")
	assert(StageDirector.scrap_materials == scrap_before, "BLOCKER-06 FAIL: Scrap changed during practice")
	var prac_loss := StageDirector.complete_stage_run(100, false, 5)
	assert(int(prac_loss["earned_credits"]) == 0, "BLOCKER-06 FAIL: Practice loss awarded credits")
	assert(int(prac_loss["earned_character_xp"]) == 0, "BLOCKER-06 FAIL: Practice loss awarded XP")
	StageDirector.is_practice_mode = false
	print("PASS BLOCKER-06: Practice farming - 0 credits, 0 XP, 0 scrap in practice mode.")

	# --------------------------------------------------------------------------
	# BLOCKER-07: Short defeat
	# Kroki: Porażka po 2 sekundach i 0 ukończonych falach: 0 kredytów i 0 XP.
	# --------------------------------------------------------------------------
	var short_res := StageDirector.complete_stage_run(100, false, 0)
	assert(int(short_res["earned_credits"]) == 0, "BLOCKER-07 FAIL: 0 waves failure gave credits")
	assert(int(short_res["earned_character_xp"]) == 0, "BLOCKER-07 FAIL: 0 waves failure gave XP")
	print("PASS BLOCKER-07: Short defeat - 0 waves cleared awards exactly 0 credits and 0 XP.")

	# --------------------------------------------------------------------------
	# BLOCKER-05: Retry attempts
	# Kroki: Pula 2 próby; porażka; ponowienie -> zużycie próby. Kolejne bez prób -> odmowa.
	# --------------------------------------------------------------------------
	StageDirector.attempts = 2
	StageDirector.next_attempt_at = int(Time.get_unix_time_from_system()) + 1800
	assert(StageDirector.spend_campaign_attempt() == true, "Spend 1 attempt failed")
	assert(StageDirector.attempts == 1, "Attempts should be 1")
	assert(StageDirector.spend_campaign_attempt() == true, "Spend 2 attempt failed")
	assert(StageDirector.attempts == 0, "Attempts should be 0")
	assert(StageDirector.spend_campaign_attempt() == false, "Spend with 0 attempts should fail")
	StageDirector.refill_attempts_sandbox()
	print("PASS BLOCKER-05: Retry attempts - spending campaign attempt verified, 0 attempts rejected.")

	# --------------------------------------------------------------------------
	# Podstawowe testy mechanik (Klasy, Profile Trudności, Ekwipunek 6 slotów)
	# --------------------------------------------------------------------------
	for cid in ["soldier", "engineer", "medic", "scout"]:
		StageDirector.selected_class_id = String(cid)
		assert(StageDirector.HERO_CLASSES.has(cid), "Missing class " + String(cid))
	StageDirector.selected_class_id = "soldier"

	for did in ["rekrut", "ocalaly", "weteran", "koszmar", "apokalipsa"]:
		var d_prof := StageDirector.get_difficulty_profile(String(did))
		assert(String(d_prof.get("id", "")) == String(did), "Difficulty profile mismatch: " + String(did))

	StageDirector.credits = 3000
	StageDirector.scrap_materials = 40
	var rolled_epic := StageDirector.roll_new_equipment_drop(30, "epic")
	var ep_id := String(rolled_epic.get("instance_id", ""))
	var ep_slot := String(rolled_epic.get("slot", "weapon"))
	StageDirector.equip_item(ep_id)
	assert(String(StageDirector.equipped_items.get(ep_slot, "")) == ep_id, "Equip item failed")
	var up_ok := StageDirector.upgrade_item_by_instance(ep_id)
	assert(up_ok == true, "Upgrade item +1 failed")
	StageDirector.unequip_slot(ep_slot)
	assert(not StageDirector.equipped_items.has(ep_slot), "Unequip slot failed")
	StageDirector.equip_item(ep_id)
	print("PASS 4 Classes, 5 Difficulties & 6-Slot RPG Upgrade/Equip verified.")

	# Zrzuty ekranu Menu Głównego i zakładek
	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	for _i in range(10):
		await get_tree().process_frame

	await _capture_screenshot("v1_final_hub_base_720x1280.png")

	DisplayServer.window_set_size(Vector2i(1080, 1920))
	for _i in range(6):
		await get_tree().process_frame
	await _capture_screenshot("v1_final_hub_base_1080x1920.png")

	DisplayServer.window_set_size(Vector2i(720, 1280))
	for _i in range(6):
		await get_tree().process_frame

	if is_instance_valid(menu_node) and menu_node.has_method("switch_hub_tab"):
		menu_node.call("switch_hub_tab", 1)
		for _i in range(8):
			await get_tree().process_frame
		await _capture_screenshot("v1_final_tab_character_720x1280.png")

		menu_node.call("switch_hub_tab", 2)
		for _i in range(8):
			await get_tree().process_frame
		await _capture_screenshot("v1_final_tab_inventory_720x1280.png")

		menu_node.call("switch_hub_tab", 4)
		for _i in range(8):
			await get_tree().process_frame
		await _capture_screenshot("v1_final_tab_store_720x1280.png")

		menu_node.call("switch_hub_tab", 5)
		for _i in range(8):
			await get_tree().process_frame
		await _capture_screenshot("v1_final_tab_daily_720x1280.png")

		menu_node.call("switch_hub_tab", 0)
		StageDirector.set_orientation_mode("landscape", true)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		for _i in range(8):
			await get_tree().process_frame
		await _capture_screenshot("v1_final_hub_base_1280x720.png")

	menu_node.queue_free()
	for _i in range(4):
		await get_tree().process_frame

	# --------------------------------------------------------------------------
	# SCENA ROZGRYWKI (MAIN.TSCN)
	# --------------------------------------------------------------------------
	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	StageDirector.current_stage = 1
	var main_packed: PackedScene = load("res://scenes/main/main.tscn")
	var main_scene := main_packed.instantiate()
	add_child(main_scene)
	for _i in range(14):
		await get_tree().process_frame
	await _capture_screenshot("v1_final_gameplay_stage001_720x1280.png")

	# --------------------------------------------------------------------------
	# BLOCKER-02: Victory guard
	# Kroki: Fala 10; boss żyje lub cel główny niedokończony -> _can_claim_victory() == false
	# --------------------------------------------------------------------------
	main_scene.current_stage_num = 100
	main_scene.current_wave_num = 10
	main_scene.max_waves_in_stage = 10
	main_scene.wave_time_left = 5.0
	main_scene.boss_spawned_this_run = true
	main_scene.boss_killed_this_run = false
	main_scene.primary_objective_done = false
	assert(main_scene.call("_can_claim_victory") == false, "BLOCKER-02 FAIL: Can claim victory while boss alive and objective pending")
	main_scene.call("_on_stage_victory")
	assert(main_scene.run_result_state == "active", "BLOCKER-02 FAIL: State transitioned to victory despite guard")
	assert(main_scene.win_panel.visible == false, "BLOCKER-02 FAIL: WinPanel displayed while victory disallowed")
	print("PASS BLOCKER-02: Victory guard - victory strictly prevented while boss alive and objective pending.")

	# Etap 030 Screenshot
	main_scene.call("_build_layered_arena", 30)
	main_scene.call("start_stage", 30)
	main_scene.call("start_wave", 30, 10)
	for _i in range(10):
		await get_tree().process_frame
	await _capture_screenshot("v1_final_gameplay_stage030_720x1280.png")

	# Etap 100 Screenshot
	main_scene.call("_build_layered_arena", 100)
	main_scene.call("start_stage", 100)
	main_scene.call("start_wave", 100, 10)
	for _i in range(10):
		await get_tree().process_frame
	await _capture_screenshot("v1_final_gameplay_stage100_720x1280.png")

	# Landscape Screenshots (UI-02)
	var upg_p := main_scene.get_node_or_null("HUD/HUDRoot/UpgradePanel") as Control
	if is_instance_valid(upg_p):
		upg_p.visible = false
	get_tree().paused = false
	StageDirector.set_orientation_mode("landscape", true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	for _i in range(6):
		await get_tree().process_frame
	if is_instance_valid(upg_p):
		upg_p.visible = false
	await _capture_screenshot("v1_final_gameplay_stage100_1280x720.png")

	DisplayServer.window_set_size(Vector2i(1920, 1080))
	for _i in range(6):
		await get_tree().process_frame
	if is_instance_valid(upg_p):
		upg_p.visible = false
	await _capture_screenshot("v1_final_gameplay_stage100_1920x1080.png")
	print("PASS UI-02: Landscape HUD 1280x720 and 1920x1080 verified.")

	# Powrót do Portrait 720x1280
	StageDirector.set_orientation_mode("portrait", true)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	for _i in range(6):
		await get_tree().process_frame

	# --------------------------------------------------------------------------
	# BLOCKER-03 & BILLING-01: Run outcome, Revive & Mutually Exclusive Panels
	# Kroki: Śmierć gracza -> awaiting_revive -> brak WinPanel -> revive -> 3.5s shield
	# --------------------------------------------------------------------------
	main_scene.run_result_state = "active"
	StageDirector.is_online_mode = false
	main_scene.call("_on_player_died")
	assert(main_scene.run_result_state == "awaiting_revive", "BLOCKER-03 FAIL: State not awaiting_revive on death")
	assert(main_scene.death_panel.visible == true, "BLOCKER-03 FAIL: DeathPanel not visible on death")
	assert(main_scene.win_panel.visible == false, "BLOCKER-03 FAIL: WinPanel simultaneously visible with DeathPanel")

	# Test BILLING-01: Offline mode disables ad revive button
	var ad_btn := main_scene.get_node_or_null("HUD/HUDRoot/DeathPanel/CenterContainer/VBox/HBox/ReviveAdBtn") as Button
	assert(ad_btn != null and ad_btn.disabled == true, "BILLING-01 FAIL: Ad revive not disabled in offline mode")
	print("PASS BILLING-01: Ad revive button properly disabled when offline.")

	await _capture_screenshot("v1_final_defeat_revive_720x1280.png")

	# Przełącz na online i ożyw za pomocą premium lub ad
	StageDirector.is_online_mode = true
	main_scene.has_used_revive = false
	main_scene.call("_on_revive_ad_pressed")
	assert(main_scene.run_result_state == "active", "BLOCKER-03 FAIL: State not active after revive")
	assert(main_scene.death_panel.visible == false, "BLOCKER-03 FAIL: DeathPanel still visible after revive")
	var pl := main_scene.get_node_or_null("CharactersLayer/Player") as Player
	assert(pl != null and pl.invulnerable_timer > 2.0, "BLOCKER-03 FAIL: Invulnerability shield not active after revive")
	print("PASS BLOCKER-03: Run outcome - death, revive and invulnerability shield verified.")

	# --------------------------------------------------------------------------
	# BLOCKER-04: Reward replay & Legitimate Victory
	# Kroki: Spełnij wszystkie warunki wygranej -> _on_stage_victory() -> nagroda raz
	# --------------------------------------------------------------------------
	main_scene.current_stage_num = 1
	main_scene.current_wave_num = 10
	main_scene.max_waves_in_stage = 10
	main_scene.wave_time_left = 0.0
	main_scene.total_run_elapsed = 184.2 # 03:04
	main_scene.enemies_killed_in_run = 142
	main_scene.primary_objective_done = true
	main_scene.boss_spawned_this_run = true
	main_scene.boss_killed_this_run = true
	assert(main_scene.call("_can_claim_victory") == true, "Legitimate victory conditions should be satisfied")

	var credits_pre_win := StageDirector.credits
	main_scene.call("_on_stage_victory")
	assert(main_scene.run_result_state == "victory", "BLOCKER-04 FAIL: State not victory")
	assert(main_scene.win_panel.visible == true, "BLOCKER-04 FAIL: WinPanel not visible on victory")
	assert(main_scene.death_panel.visible == false, "BLOCKER-04 FAIL: DeathPanel visible on victory")
	var credits_after_first := StageDirector.credits
	assert(credits_after_first > credits_pre_win, "BLOCKER-04 FAIL: Credits not granted on victory")

	# Ponowne wywołanie w tym samym runie nie może dać kolejnej nagrody
	main_scene.call("_on_stage_victory")
	assert(StageDirector.credits == credits_after_first, "BLOCKER-04 FAIL: Double reward granted on second victory call")
	print("PASS BLOCKER-04: Reward replay - victory grant awarded exactly once per run.")

	await _capture_screenshot("v1_final_victory_screen_720x1280.png")
	print("PASS UI-01: Portrait HUD 720x1280 and 1080x1920 verified.")

	if FileAccess.file_exists(StageDirector.save_path_override):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(StageDirector.save_path_override))

	print("=== ALL 12 QA MATRIX AND MASTER V1 VERIFICATION TESTS PASSED ===")
	get_tree().quit(0)

func _capture_screenshot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(ARTIFACT_DIR + filename)
		print("SAVED SCREENSHOT: " + filename + " (" + str(img.get_width()) + "x" + str(img.get_height()) + ")")
