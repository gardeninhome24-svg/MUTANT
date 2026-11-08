extends RefCounted
class_name MutantV1CampaignProgress

static func can_play(mission: Dictionary, save_data: Dictionary) -> bool:
    var stage: int = int(mission.get("stage", 0))
    return stage > 0 and stage <= int(save_data.get("max_unlocked_stage", 1))

static func finish_first_clear(mission: Dictionary, save_data: Dictionary, objectives_complete: bool) -> Dictionary:
    if not objectives_complete or not can_play(mission, save_data):
        return {"ok": false, "save": save_data, "rewards": {}}
    var updated: Dictionary = save_data.duplicate(true)
    var clears: Dictionary = updated.get("first_clears", {}).duplicate(true)
    var key: String = str(mission.get("id", ""))
    if bool(clears.get(key, false)):
        return {"ok": true, "save": updated, "rewards": {}, "first_clear": false}
    clears[key] = true
    updated["first_clears"] = clears
    var unlock: Variant = mission.get("mandatory_stage_unlock", null)
    if unlock != null:
        updated["max_unlocked_stage"] = maxi(int(updated.get("max_unlocked_stage", 1)), int(unlock))
    var rewards: Dictionary = mission.get("rewards", {}).duplicate(true)
    updated["credits"] = int(updated.get("credits", 0)) + int(rewards.get("soft_credits", 0))
    updated["account_xp"] = int(updated.get("account_xp", 0)) + int(rewards.get("account_xp", 0))
    return {"ok": true, "save": updated, "rewards": rewards, "first_clear": true}
