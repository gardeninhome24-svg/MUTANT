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
