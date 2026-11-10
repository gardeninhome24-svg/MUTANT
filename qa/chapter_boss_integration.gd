extends SceneTree

# Integration gate for all 10 chapter finales in the REAL combat scene.
# Spawn and defeat each configured boss in disposable practice mode.
# This intentionally bypasses the wave timer; it is not a ten-wave playtest.
const SAVE_PATH := "user://qa_chapter_boss_integration.json"
var problems: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        problems.append(message)
        printerr("CHAPTER BOSS FAIL: " + message)

func _run() -> void:
    await process_frame
    var stage: Node = root.get_node_or_null("StageDirector")
    _check(stage != null, "StageDirector autoload exists")
    var scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
    _check(scene != null, "Combat scene resource loads")
    if stage == null or scene == null:
        _done()
        return
    stage.get_script().set("save_path_override", SAVE_PATH)
    stage.is_practice_mode = true
    for chapter in range(1, 11):
        var stage_num: int = chapter * 10
        var cfg: Dictionary = stage.get_stage_config(stage_num)
        var configured_id: String = String(cfg.get("boss_id", ""))
        _check(not configured_id.is_empty(), "Stage %d has a configured boss" % stage_num)
        if configured_id.is_empty():
            continue
        stage.current_stage = stage_num
        stage.max_unlocked_stage = stage_num
        var combat: Node = scene.instantiate()
        root.add_child(combat)
        await process_frame
        combat.set_process(false)
        combat.call("start_wave", stage_num, 10)
        var boss: Node = combat.get("active_boss")
        _check(bool(combat.call("_stage_requires_final_boss")), "Stage %d requires boss" % stage_num)
        _check(is_instance_valid(boss), "Stage %d spawns chapter boss" % stage_num)
        _check(bool(combat.get("boss_spawned_this_run")), "Stage %d records boss spawn" % stage_num)
        if is_instance_valid(boss):
            combat.call("spawn_special_enemy", configured_id, "boss", "QA duplicate callback")
            _check(combat.get("active_boss") == boss,
                "Stage %d ignores duplicate chapter boss spawn callback" % stage_num)
        if is_instance_valid(boss):
            _check(String(boss.get("enemy_id")) == configured_id, "Stage %d boss ID matches campaign data" % stage_num)
            combat.set("primary_objective_done", true)
            combat.set("wave_time_left", 0.0)
            _check(not bool(combat.call("_can_claim_victory")), "Stage %d does not allow victory while boss lives" % stage_num)
            boss.take_damage(float(boss.get("max_health")) + 1000000.0)
            _check(bool(combat.get("boss_killed_this_run")), "Stage %d boss defeat registered" % stage_num)
            _check(bool(combat.call("_can_claim_victory")), "Stage %d can complete after boss defeat" % stage_num)
        paused = false
        combat.queue_free()
        await process_frame
    stage.get_script().set("save_path_override", "")
    for suffix in ["", ".tmp", ".bak", ".bak.tmp"]:
        var path: String = SAVE_PATH + String(suffix)
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    _done()

func _done() -> void:
    paused = false
    if problems.is_empty():
        print("CHAPTER BOSS PASS: %d assertions, 10 chapter finales instantiated" % checks)
        quit(0)
    else:
        printerr("CHAPTER BOSS FAILED: %d of %d assertions" % [problems.size(), checks])
        quit(1)
