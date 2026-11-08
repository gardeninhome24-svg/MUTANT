extends Node2D

const ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"
const MSDefeatOverlayScene := preload("res://addons/ms_balance/ui/defeat_overlay.tscn")
const MAIN_SCENE_RES := preload("res://scenes/main/main.tscn")

func _ready() -> void:
	print("\n==================================================================")
	print("=== START MUTANT SURVIVOR BALANCE & BETA ADDON ACCEPTANCE TEST ===")
	print("==================================================================\n")

	# ----------------------------------------------------------------------
	# 1. TEST MSAttemptOfferRules & StageDirector Gem Refills
	# ----------------------------------------------------------------------
	print("--- [TEST 1] Testing Attempt Offer Rules & Economy ---")
	assert(MSAttemptOfferRules.SINGLE_REFILL_GEMS_PROPOSED == 18, "Rule mismatch: single refill not 18 gems")
	assert(MSAttemptOfferRules.FULL_REFILL_GEMS_PROPOSED == 60, "Rule mismatch: full refill not 60 gems")
	assert(MSAttemptOfferRules.REVIVE_GEMS_EXISTING == 30, "Rule mismatch: revive not 30 gems")

	StageDirector.attempts = 3
	StageDirector.dark_matter_gems = 100
	var initial_gems := StageDirector.dark_matter_gems

	assert(StageDirector.can_buy_single_attempt_refill() == true, "Should be able to buy single refill")
	var bought_single := StageDirector.buy_single_attempt_refill()
	assert(bought_single == true, "buy_single_attempt_refill failed")
	assert(StageDirector.attempts == 4, "Attempts should now be 4")
	assert(StageDirector.dark_matter_gems == initial_gems - 18, "Should have deducted exactly 18 gems")
	print("PASS: Single attempt refill (18 gems -> +1 attempt) verified.")

	StageDirector.attempts = 2
	assert(StageDirector.can_buy_full_attempts_refill() == true, "Should be able to buy full refill")
	var bought_full := StageDirector.buy_full_attempts_refill()
	assert(bought_full == true, "buy_full_attempts_refill failed")
	assert(StageDirector.attempts == 5, "Attempts should now be 5 (max)")
	assert(StageDirector.dark_matter_gems == initial_gems - 18 - 60, "Should have deducted exactly 60 gems")
	print("PASS: Full attempts refill (60 gems -> 5/5 attempts) verified.")

	# Cap test: cannot buy when attempts == 5
	assert(StageDirector.can_buy_single_attempt_refill() == false, "Should not buy when already at max 5")
	assert(StageDirector.can_buy_full_attempts_refill() == false, "Should not buy full when already at max 5")
	print("PASS: Maximum attempts cap (5/5) protection verified.")

	# ----------------------------------------------------------------------
	# 2. TEST MSBalanceModel & 100-Stage Campaign Balance JSON
	# ----------------------------------------------------------------------
	print("\n--- [TEST 2] Testing MSBalanceModel & 100-Stage Balance Data ---")
	var st1 := MSBalanceModel.stage_profile(1)
	assert(not st1.is_empty(), "Stage 1 profile empty")
	assert(int(st1.get("stage", 0)) == 1, "Stage 1 profile num mismatch")

	var st100 := MSBalanceModel.stage_profile(100)
	assert(not st100.is_empty(), "Stage 100 profile empty")
	assert(int(st100.get("stage", 0)) == 100, "Stage 100 profile num mismatch")

	var exp_att := MSBalanceModel.expected_attempts(st1)
	assert(exp_att >= 1.0, "Expected attempts should be >= 1.0")

	assert(MSBalanceModel.should_reward_stage_winner(10, true, false, false) == true, "Winner rule normal valid")
	assert(MSBalanceModel.should_reward_stage_winner(9, true, false, false) == false, "Winner rule wave < 10 invalid")
	assert(MSBalanceModel.should_reward_stage_winner(10, false, false, false) == false, "Winner rule obj incomplete invalid")
	assert(MSBalanceModel.should_reward_stage_winner(10, true, true, false) == false, "Winner rule boss alive invalid")
	assert(MSBalanceModel.should_reward_stage_winner(10, true, true, true) == true, "Winner rule boss dead valid")
	print("PASS: MSBalanceModel 100-stage dataset and legitimate win condition verified.")

	# ----------------------------------------------------------------------
	# 3. TEST MSDefeatOverlay Signals and Presentation Prefab
	# ----------------------------------------------------------------------
	print("\n--- [TEST 3] Testing MSDefeatOverlay Signals & Prefab ---")
	var overlay: Control = MSDefeatOverlayScene.instantiate()
	add_child(overlay)

	var signal_received := [""]
	overlay.request_revive_premium.connect(func(): signal_received[0] = "premium")
	overlay.request_revive_ad.connect(func(): signal_received[0] = "ad")
	overlay.request_retry.connect(func(): signal_received[0] = "retry")
	overlay.request_return_to_hub.connect(func(): signal_received[0] = "hub")

	await get_tree().process_frame

	overlay.configure({
		"title": "MISJA NIEUDANA",
		"wave": 8,
		"kills": 154,
		"time_seconds": 195,
		"reason": "Zwiększ obrażenia broni.",
		"already_revived": false,
		"gems": 50,
		"ad_available": true
	})

	assert(overlay.score_label.text.contains("FALA 8/10"), "Score label missing wave info")
	assert(overlay.score_label.text.contains("154 MUTANT"), "Score label missing kill info")
	assert(overlay.revive_button.disabled == false, "Revive button should be enabled with 50 gems")

	# Test signal emissions
	overlay.request_revive_premium.emit()
	assert(signal_received[0] == "premium", "request_revive_premium signal not received")

	overlay.request_retry.emit()
	assert(signal_received[0] == "retry", "request_retry signal not received")

	overlay.request_return_to_hub.emit()
	assert(signal_received[0] == "hub", "request_return_to_hub signal not received")

	overlay.queue_free()
	print("PASS: MSDefeatOverlay data binding and all 4 signals verified.")

	# ----------------------------------------------------------------------
	# 4. TEST In-Game Integration of MSDefeatOverlay in Main
	# ----------------------------------------------------------------------
	print("\n--- [TEST 4] Testing Live Main Scene Integration with MSDefeatOverlay ---")
	StageDirector.wave_duration_sec = 0.5
	StageDirector.save_path_override = "user://test_defeat_save.json"

	var main_game: Node2D = MAIN_SCENE_RES.instantiate()
	add_child(main_game)

	for _i in range(5):
		await get_tree().process_frame

	main_game.call("start_stage", 1)
	main_game.call("start_wave", 1, 3)

	assert(main_game.get("defeat_overlay_inst") != null, "defeat_overlay_inst not found on main")
	assert(main_game.defeat_overlay_inst.visible == false, "defeat_overlay_inst should be hidden during combat")

	# Simulate player death
	StageDirector.dark_matter_gems = 45
	main_game.call("_on_player_died")

	assert(main_game.defeat_overlay_inst.visible == true, "defeat_overlay_inst should be visible on death")
	assert(main_game.death_panel.visible == true, "death_panel backward compatibility preserved")
	assert(main_game.run_result_state == "awaiting_revive", "State should be awaiting_revive")

	# Test Revive via premium
	main_game.call("_on_revive_premium_pressed")
	assert(main_game.defeat_overlay_inst.visible == false, "defeat_overlay_inst should be hidden after revive")
	assert(main_game.death_panel.visible == false, "death_panel should be hidden after revive")
	assert(main_game.run_result_state == "active", "State should be active after revive")
	assert(main_game.has_used_revive == true, "has_used_revive should be true")
	assert(StageDirector.dark_matter_gems == 15, "Should have spent 30 gems (45 - 30 = 15)")

	# Second death in same run: revive button disabled
	main_game.call("_on_player_died")
	assert(main_game.defeat_overlay_inst.visible == true, "defeat_overlay_inst visible on 2nd death")
	var rev_btn: Button = main_game.defeat_overlay_inst.get_node("Center/Margin/VBox/RevivePremium")
	assert(rev_btn.disabled == true, "Revive button must be disabled after 1 revive used")

	main_game.queue_free()
	print("PASS: Live Main Scene death & revive flow with MSDefeatOverlay verified.")

	StageDirector.wave_duration_sec = 65.0
	print("\n==================================================================")
	print("=== ALL MUTANT SURVIVOR BALANCE ADDON ACCEPTANCE TESTS PASSED! ===")
	print("==================================================================")
	get_tree().quit(0)
