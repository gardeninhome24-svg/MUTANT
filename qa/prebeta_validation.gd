extends SceneTree

# Headless pre-beta structural checks. Run with:
# godot --headless --path . --script res://qa/prebeta_validation.gd
# These checks validate project data and scene loading, NOT Android usability.

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run_validation")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("PREBETA FAIL: " + message)

func _run_validation() -> void:
	_validate_campaign()
	_validate_runtime_campaign()
	_validate_scenes()
	_validate_app_icon()
	if not failures.is_empty():
		push_error("PREBETA FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)
	else:
		print("PREBETA PASS: %d checks; device playtesting still required" % checks)
		quit(0)

func _validate_app_icon() -> void:
	var icon_path: String = String(ProjectSettings.get_setting("application/config/icon", ""))
	_check(icon_path == "res://assets/ui/target_theme/icon_mutant_survivor.svg", "Branded MUTANT icon must be active in project.godot")
	_check(FileAccess.file_exists(icon_path), "Configured launcher icon file must exist")
	if FileAccess.file_exists(icon_path):
		_check(ResourceLoader.exists(icon_path, "Texture2D"), "Branded icon must import as a Godot Texture2D")


func _validate_campaign() -> void:
	var path := "res://gamedesign/etapy_001_100.json"
	_check(FileAccess.file_exists(path), "Campaign JSON must exist")
	if not FileAccess.file_exists(path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(data is Dictionary, "Campaign must be valid JSON object")
	if not (data is Dictionary):
		return
	var stages: Variant = data.get("stages", [])
	_check(stages is Array, "Campaign stages must be an array")
	if not (stages is Array):
		return
	_check(stages.size() == 100, "Campaign must contain exactly 100 stages")
	var seen: Dictionary = {}
	for entry in stages:
		if not (entry is Dictionary):
			_check(false, "Every stage must be an object")
			continue
		var stage_number := int(entry.get("stage", 0))
		_check(stage_number >= 1 and stage_number <= 100, "Stage number out of range: %d" % stage_number)
		_check(not seen.has(stage_number), "Duplicate stage: %d" % stage_number)
		seen[stage_number] = true
		_check(int(entry.get("waves", -1)) == 10, "Expected 10 waves in stage %d" % stage_number)
		_check(int(entry.get("miniboss_wave", -1)) == 5, "Expected miniboss wave 5 in stage %d" % stage_number)
		_check(int(entry.get("boss_wave", -1)) == 10, "Expected boss wave 10 in stage %d" % stage_number)
	for stage_number in range(1, 101):
		_check(seen.has(stage_number), "Missing stage: %d" % stage_number)

func _validate_scenes() -> void:
	for path in ["res://scenes/ui/main_menu.tscn", "res://scenes/main/main.tscn", "res://scenes/player/player.tscn"]:
		_check(ResourceLoader.exists(path), "Required scene missing: " + path)
		if ResourceLoader.exists(path):
			var scene: PackedScene = load(path) as PackedScene
			_check(scene != null, "Required scene failed to load: " + path)

func _validate_runtime_campaign() -> void:
	# The game uses merged StageDirector data, not the raw v1 campaign JSON.
	# Testing the old boss_id field alone masked missing/incorrect v2 finales.
	var director: Node = root.get_node_or_null("StageDirector")
	_check(director != null, "StageDirector autoload must be available")
	if director == null:
		return
	for number in range(1, 101):
		var cfg: Dictionary = director.get_stage_config(number)
		var boss_id: String = String(cfg.get("boss_id", ""))
		var objective_type: String = String(cfg.get("scene_type", ""))
		var is_finale: bool = number % 10 == 0
		_check(int(cfg.get("stage", -1)) == number, "Merged runtime stage identifier %d" % number)
		_check(int(cfg.get("waves", -1)) == 10, "Merged runtime stage %d has ten waves" % number)
		_check(not String(cfg.get("name", "")).is_empty(), "Merged runtime stage %d has a name" % number)
		_check(not objective_type.is_empty(), "Merged runtime stage %d has an objective" % number)
		_check(not cfg.get("objectives_v2", []).is_empty(), "Merged runtime stage %d has integration objectives" % number)
		_check(not boss_id.is_empty() if is_finale else boss_id.is_empty(),
			"Final boss assignment matches chapter finale rule on stage %d" % number)
		_check((objective_type == "defeat_boss") == is_finale,
			"Boss objective agrees with chapter finale on stage %d" % number)
		var next_stage: Variant = cfg.get("mandatory_stage_unlock", null)
		_check(next_stage == null if number == 100 else int(next_stage) == number + 1,
			"Stage %d unlock progression contract" % number)
