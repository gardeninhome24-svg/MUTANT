extends RefCounted
class_name MSBalanceModel
## Safe, read-only design goals; never mutate StageDirector before independent QA.
const PATH := "res://addons/ms_balance/data/campaign_100_balance_v1.json"
static func stage_profile(stage_num: int) -> Dictionary:
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        push_warning("MSBalanceModel: missing stage profile file")
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("MSBalanceModel: invalid JSON")
        return {}
    var stages: Array = parsed.get("stages", [])
    var index := clampi(stage_num, 1, 100) - 1
    if stages.size() != 100:
        return {}
    return stages[index].duplicate(true)

static func expected_attempts(profile: Dictionary) -> float:
    var p := clampf(float(profile.get("target_clear_probability_f2p", 0.5)), 0.01, 1.0)
    return 1.0 / p

static func should_reward_stage_winner(waves: int, completed_objectives: bool, boss_spawned: bool, boss_dead: bool) -> bool:
    return waves >= 10 and completed_objectives and (not boss_spawned or boss_dead)
