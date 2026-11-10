extends SceneTree

# Structural art/HUD QA against real instantiated Godot scenes.
# Does NOT prove image quality, touch response or Android frame rate.
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("VISUAL GATE FAIL: " + message)

func _rect(node: Control) -> Rect2:
	return node.get_global_rect()

func _not_overlapping(a: Control, b: Control, label: String) -> void:
	if not is_instance_valid(a) or not is_instance_valid(b):
		_check(false, label + " nodes missing")
		return
	# Hidden auto-combat skill buttons do not reserve clickable space.
	if not a.is_visible_in_tree() or not b.is_visible_in_tree():
		_check(true, label + " (one control intentionally hidden)")
		return
	# A small touch between borders should not be treated as overlap.
	var ar: Rect2 = _rect(a).grow(-1)
	var br: Rect2 = _rect(b).grow(-1)
	_check(not ar.intersects(br), label)

func _check_texture(path: String) -> void:
	_check(ResourceLoader.exists(path, "Texture2D"), "Required UI texture exists: " + path)
	if ResourceLoader.exists(path, "Texture2D"):
		var tex: Texture2D = load(path) as Texture2D
		_check(tex != null and tex.get_width() > 0 and tex.get_height() > 0, "UI texture has visible dimensions: " + path)

func _run() -> void:
	await process_frame
	for path in [
		"res://assets/ui/target_theme/bg_clean_soldier_ruins.png",
		"res://assets/ui/target_theme/card_stage_clean.png",
		"res://assets/ui/target_theme/btn_play_gold_clean.png",
		"res://assets/ui/joystick_base.png",
		"res://assets/ui/joystick_knob.png",
		"res://assets/ui/fire_button.png",
		"res://assets/ui/dash_button.png",
		"res://assets/mutantsurvivor_ch01/characters/soldier_idle.png"
	]:
		_check_texture(path)

	# The approved visual language must be backed by imported actual art,
	# not just test markers or non-functional placeholder illustrations.
	for skin in [
		"res://assets/ui/approved/combat_objectives_frame.svg",
		"res://assets/ui/approved/combat_wave_frame.svg",
		"res://assets/ui/approved/combat_radar_frame.svg",
		"res://assets/ui/approved/combat_inventory_frame.svg"
	]:
		_check_texture(skin)

	var stage = root.get_node_or_null("StageDirector")
	_check(stage != null, "StageDirector autoload is present")
	if stage == null:
		_finish()
		return
	stage.get_script().set("save_path_override", "user://qa_visual_gate.json")
	stage.current_stage = 1
	stage.is_practice_mode = true
	stage.orientation_mode = "portrait"

	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	_check(packed != null, "Combat scene loads for HUD inspection")
	if packed == null:
		_finish()
		return
	var combat: Node = packed.instantiate()
	root.add_child(combat)
	await process_frame
	await process_frame
	combat.call("_apply_responsive_hud_layout")
	await process_frame

	var wave_frame: Panel = combat.get_node_or_null("HUD/HUDRoot/WaveFrame") as Panel
	_check(is_instance_valid(wave_frame), "Actual HUD has a live wave artwork panel")
	if is_instance_valid(wave_frame):
		var wave_style: StyleBox = wave_frame.get_theme_stylebox("panel")
		_check(wave_style is StyleBoxTexture, "Live wave panel uses nine-slice artwork")
		_check(wave_frame.size.y <= 118.0, "Wave artwork does not expand to a giant blank rectangle")
		_check(wave_frame.size.x <= 390.0, "Wave artwork does not spread across the entire mobile HUD")
	for node_name in ["objectives_panel", "radar_panel", "bottom_weapons_panel"]:
		var rendered_panel: PanelContainer = combat.get(node_name) as PanelContainer
		_check(is_instance_valid(rendered_panel) and rendered_panel.get_theme_stylebox("panel") is StyleBoxTexture,
			"Live %s uses approved nine-slice combat artwork" % node_name)

	var stats: Control = combat.get("stats_card") as Control
	var currencies: Control = combat.get("currency_bar") as Control
	var wave: Control = combat.get("wave_progress_box") as Control
	var goals: Control = combat.get("objectives_panel") as Control
	var radar: Control = combat.get("radar_panel") as Control
	var weapons: Control = combat.get("bottom_weapons_panel") as Control
	var powers: Control = combat.get("powers_hbox") as Control
	var joystick: Control = combat.get("joystick") as Control
	var fire: Control = combat.get("fire_btn") as Control
	var dash: Control = combat.get("dash_btn") as Control

	_not_overlapping(stats, currencies, "Top-left stats vs top-right currency")
	_not_overlapping(stats, wave, "Stats vs wave timer")
	_not_overlapping(goals, radar, "Mission objectives vs radar")
	_not_overlapping(goals, wave, "Mission objectives vs wave timer")
	_not_overlapping(weapons, powers, "Bottom weapon and skill panels")
	_not_overlapping(joystick, weapons, "Joystick vs weapon bar")
	_not_overlapping(joystick, dash, "Joystick vs dash")
	_not_overlapping(joystick, fire, "Joystick vs fire")
	_not_overlapping(dash, fire, "Dash vs fire")

	# Test the narrow mobile layout branch, which is different from 720x1280.
	# This is a structural offset check; a physical Android device still needs QA.
	combat.call("_apply_responsive_hud_layout", 420.0)
	await process_frame
	var safe_top: float = stage.get_safe_top_margin()
	if is_instance_valid(wave):
		_check(absf(wave.offset_top - (210.0 + safe_top)) < 0.1, "Narrow portrait wave timer stays below currencies")
	if is_instance_valid(radar):
		_check(absf(radar.offset_top - (75.0 + safe_top)) < 0.1, "Narrow portrait radar stays beside objectives")
	if is_instance_valid(currencies):
		_check(absf(currencies.offset_left - (-395.0)) < 0.1, "Narrow portrait currency bar gets a dedicated full-width row")
	if is_instance_valid(currencies) and is_instance_valid(wave):
		_check(currencies.offset_bottom + 2.0 <= wave.offset_top, "420px currency and wave rows do not overlap")
	var avatar: TextureRect = combat.get_node_or_null("HUD/HUDRoot/PlayerStatsCard/Margin/HBoxRoot/AvatarBox/Avatar") as TextureRect
	var hp: ProgressBar = combat.get("hp_bar") as ProgressBar
	var xp: ProgressBar = combat.get("xp_bar") as ProgressBar
	var wave_title: Label = combat.get("wave_label") as Label
	var objectives_title: Label = combat.get("obj_header") as Label
	var weapon_row: HBoxContainer = combat.get("weapon_slots_hbox") as HBoxContainer
	if is_instance_valid(avatar):
		_check(avatar.custom_minimum_size.x <= 32.0, "420px HUD avatar uses compact dimensions")
	if is_instance_valid(hp) and is_instance_valid(xp):
		_check(hp.custom_minimum_size.x == 110.0 and xp.custom_minimum_size.x == 110.0, "420px HP and XP bars fit compact stat card")
	if is_instance_valid(wave_title):
		_check(wave_title.get_theme_font_size("font_size") == 18, "420px wave label is readable without truncation")
	if is_instance_valid(objectives_title):
		_check(objectives_title.get_theme_font_size("font_size") == 14, "420px objectives header has legible text")
		_check(objectives_title.text.begins_with("CELE • ETAP"), "420px objective title avoids clipped decoration")
	if is_instance_valid(weapon_row):
		_check(weapon_row.get_theme_constant("separation") == 3, "420px weapon row uses reduced separation")
	var radio_text: Label = combat.get("npc_text_lbl") as Label
	if is_instance_valid(radio_text):
		_check(radio_text.get_theme_font_size("font_size") == 14, "420px radio message uses readable font")
	if is_instance_valid(weapons) and is_instance_valid(powers):
		_check(weapons.offset_bottom <= powers.offset_top - 2.0, "Narrow portrait weapon and power bars occupy separate rows")
	if is_instance_valid(joystick) and is_instance_valid(weapons):
		_check(joystick.offset_bottom <= weapons.offset_top - 2.0, "Narrow portrait joystick stays above weapon bar")
	var dialogue: Control = combat.get("npc_dialogue_panel") as Control
	if is_instance_valid(dialogue):
		_check(dialogue.offset_right - dialogue.offset_left <= 420.0, "Narrow portrait NPC dialogue fits viewport width")
	combat.call("_apply_responsive_hud_layout")
	await process_frame

	for pair in [
		["Joystick", joystick], ["Fire", fire], ["Dash", dash],
		["Objectives", goals], ["Stats", stats]
	]:
		var c: Control = pair[1]
		if is_instance_valid(c):
			_check(c.size.x > 0.0 and c.size.y > 0.0, String(pair[0]) + " has nonzero size")

	paused = false
	combat.queue_free()
	await process_frame
	var path: String = stage.get_active_save_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_finish()

func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("VISUAL GATE PASS: %d resource and HUD geometry checks (not screenshot QA)" % checks)
		quit(0)
	else:
		printerr("VISUAL GATE FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)
