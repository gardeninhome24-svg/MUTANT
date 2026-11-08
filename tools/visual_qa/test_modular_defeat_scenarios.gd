extends Node

const ARTIFACT_DIR := "C:/Users/patry/.gemini/antigravity/brain/8a050c14-8089-4632-a9b3-1bc6b685f215/"

func _ready() -> void:
	print("\n==============================================================")
	print("=== STARTING DYNAMIC TEST MATRIX FOR MODULAR MSDEFEAT_OVERLAY ===")
	print("==============================================================")

	var overlay_scene := load("res://addons/ms_balance/ui/defeat_overlay.tscn") as PackedScene
	assert(overlay_scene != null, "ERROR: Could not load defeat_overlay.tscn")

	# ---------------------------------------------------------
	# TEST 4 & 5: Node Hierarchy & Signal Test
	# ---------------------------------------------------------
	print("\n--- [TEST 4 & 5] Node Hierarchy & Independent Button Signals ---")
	var overlay = overlay_scene.instantiate()
	add_child(overlay)

	_print_tree_indent(overlay, "")

	var signal_results := {"premium": false, "ad": false, "retry": false, "hub": false}
	overlay.request_revive_premium.connect(func(): signal_results["premium"] = true)
	overlay.request_revive_ad.connect(func(): signal_results["ad"] = true)
	overlay.request_retry.connect(func(): signal_results["retry"] = true)
	overlay.request_return_to_hub.connect(func(): signal_results["hub"] = true)

	var tex_revive: TextureButton = overlay.get_node("CardCenter/ActionRow1/BtnReviveGold")
	var tex_ad: TextureButton = overlay.get_node("CardCenter/ActionRow1/BtnReviveAd")
	var tex_ret: TextureButton = overlay.get_node("CardCenter/ActionRow2/BtnRetry")
	var tex_hub: TextureButton = overlay.get_node("CardCenter/ActionRow2/BtnHub")

	assert(is_instance_valid(tex_revive), "Missing tex_revive button")
	assert(is_instance_valid(tex_ad), "Missing tex_ad button")
	assert(is_instance_valid(tex_ret), "Missing tex_ret button")
	assert(is_instance_valid(tex_hub), "Missing tex_hub button")

	tex_revive.emit_signal("pressed")
	tex_ad.emit_signal("pressed")
	tex_ret.emit_signal("pressed")
	tex_hub.emit_signal("pressed")

	assert(signal_results["premium"] == true, "Signal premium failed")
	assert(signal_results["ad"] == true, "Signal ad failed")
	assert(signal_results["retry"] == true, "Signal retry failed")
	assert(signal_results["hub"] == true, "Signal hub failed")
	print("PASS TEST 5: All 4 TextureButtons emit their respective signals independently!")

	overlay.queue_free()
	await get_tree().process_frame

	# ---------------------------------------------------------
	# TEST SCENARIO A: 16:9 Standard Active (300 gems, Ad visible, attempt x1)
	# ---------------------------------------------------------
	print("\n--- [SCENARIO A] Rendering 16:9 Standard Active State ---")
	var sub_active := SubViewport.new()
	sub_active.size = Vector2i(1280, 720)
	sub_active.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub_active)

	var overlay_act = overlay_scene.instantiate()
	sub_active.add_child(overlay_act)
	overlay_act.configure({
		"title": "MISJA NIEUDANA",
		"wave": 8,
		"time_seconds": 497, # 08:17
		"kills": 387,
		"reason": "Etap 008: Wzmocnij pancerz i broń.",
		"already_revived": false,
		"gems": 300,
		"revive_cost": 300,
		"attempts": 1,
		"ad_available": true
	})
	overlay_act.update_responsive_layout()

	for frame in range(15):
		await get_tree().process_frame

	var img_act := sub_active.get_texture().get_image()
	if img_act:
		img_act.save_png(ARTIFACT_DIR + "test_standard_active_16x9_actual.png")
		print("SAVED PROOF: test_standard_active_16x9_actual.png (1280x720)")

	overlay_act.queue_free()
	sub_active.queue_free()
	await get_tree().process_frame

	# ---------------------------------------------------------
	# TEST SCENARIO B: 16:9 Disabled & Ads Offline (0 gems disabled, no ads hidden)
	# ---------------------------------------------------------
	print("\n--- [SCENARIO B] Rendering 16:9 Disabled / Offline State ---")
	var sub169 := SubViewport.new()
	sub169.size = Vector2i(1280, 720)
	sub169.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub169)

	var overlay169 = overlay_scene.instantiate()
	sub169.add_child(overlay169)
	overlay169.configure({
		"title": "MISJA NIEUDANA",
		"wave": 8,
		"time_seconds": 497, # 08:17
		"kills": 387,
		"reason": "Zwiększ pancerz lub spróbuj innej strategii.",
		"already_revived": false,
		"gems": 0, # 0 gems -> Disabled button
		"revive_cost": 300,
		"attempts": 1,
		"ad_available": false # No ads -> Hidden button
	})
	overlay169.update_responsive_layout()

	for frame in range(15):
		await get_tree().process_frame

	var img169 := sub169.get_texture().get_image()
	if img169:
		img169.save_png(ARTIFACT_DIR + "test_dynamic_stats_16x9_actual.png")
		img169.save_png("res://visual_qa/captures/test_dynamic_stats_16x9_actual.png")
		print("SAVED PROOF: test_dynamic_stats_16x9_actual.png (1280x720)")

	overlay169.queue_free()
	sub169.queue_free()
	await get_tree().process_frame

	# ---------------------------------------------------------
	# TEST SCENARIO C: 9:16 Mobile Portrait (720x1280) Large Touch Targets
	# ---------------------------------------------------------
	print("\n--- [SCENARIO C] Rendering Mobile Portrait 720x1280 Large Buttons ---")
	var sub916 := SubViewport.new()
	sub916.size = Vector2i(720, 1280)
	sub916.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub916)

	var overlay916 = overlay_scene.instantiate()
	sub916.add_child(overlay916)
	overlay916.configure({
		"title": "MISJA NIEUDANA",
		"wave": 8,
		"time_seconds": 497,
		"kills": 387,
		"reason": "Mobilna weryfikacja 9:16",
		"already_revived": false,
		"gems": 300,
		"revive_cost": 300,
		"attempts": 1,
		"ad_available": true
	})
	overlay916.update_responsive_layout()

	for frame in range(15):
		await get_tree().process_frame

	var img916 := sub916.get_texture().get_image()
	if img916:
		img916.save_png(ARTIFACT_DIR + "test_dynamic_stats_9x16_actual.png")
		img916.save_png("res://visual_qa/captures/test_dynamic_stats_9x16_actual.png")
		print("SAVED PROOF: test_dynamic_stats_9x16_actual.png (720x1280)")

	overlay916.queue_free()
	sub916.queue_free()
	await get_tree().process_frame

	print("\n==============================================================")
	print("=== ALL DYNAMIC SCENARIO TESTS EXECUTED SUCCESSFULLY! ===")
	print("==============================================================")
	get_tree().quit(0)

func _print_tree_indent(node: Node, indent: String) -> void:
	print("%s- %s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_tree_indent(child, indent + "  ")
