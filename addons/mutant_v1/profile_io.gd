extends RefCounted
class_name MutantV1ProfileIO

const PATH := "user://mutant_v1_profile.json"
const VERSION := 1

static func new_profile() -> Dictionary:
    return {"save_version": VERSION, "class_id": "soldier", "credits": 0, "account_xp": 0, "max_unlocked_stage": 1, "attempts": 5, "next_attempt_at": 0, "first_clears": {}, "inventory": [], "equipment": {}, "talents": {}, "settings": {}}

static func read_profile() -> Dictionary:
    if not FileAccess.file_exists(PATH):
        return new_profile()
    var file := FileAccess.open(PATH, FileAccess.READ)
    if file == null:
        return new_profile()
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary and int(parsed.get("save_version", -1)) == VERSION:
        return parsed
    push_warning("MutantV1: unknown profile version; leaving old data untouched")
    return {}

static func write_profile(data: Dictionary) -> bool:
    if int(data.get("save_version", -1)) != VERSION:
        return false
    # Transaction-safe behavior needs platform-specific atomic replace and backup at integration.
    var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    file.close()
    var abs_tmp: String = ProjectSettings.globalize_path(PATH + ".tmp")
    var abs_dst: String = ProjectSettings.globalize_path(PATH)
    var err: Error = DirAccess.rename_absolute(abs_tmp, abs_dst)
    return err == OK
