extends RefCounted
class_name MutantV1Attempts

const CAPACITY := 5
const REGEN_SECONDS := 1800

static func refresh(profile: Dictionary, now_unix: int) -> Dictionary:
    var count: int = clampi(int(profile.get("attempts", CAPACITY)), 0, CAPACITY)
    var next_at: int = int(profile.get("next_attempt_at", 0))
    if count >= CAPACITY:
        return {"attempts": CAPACITY, "next_attempt_at": 0}
    if next_at <= 0:
        next_at = now_unix + REGEN_SECONDS
    if now_unix >= next_at:
        var added: int = 1 + int((now_unix - next_at) / REGEN_SECONDS)
        count = mini(CAPACITY, count + added)
        next_at = 0 if count == CAPACITY else next_at + added * REGEN_SECONDS
    return {"attempts": count, "next_attempt_at": next_at}

static func spend(profile: Dictionary, now_unix: int) -> Dictionary:
    var fresh: Dictionary = refresh(profile, now_unix)
    if int(fresh.get("attempts", 0)) <= 0:
        return {"ok": false, "state": fresh}
    if int(fresh.get("attempts", CAPACITY)) == CAPACITY:
        fresh["next_attempt_at"] = now_unix + REGEN_SECONDS
    fresh["attempts"] -= 1
    return {"ok": true, "state": fresh}

static func refill(profile: Dictionary) -> Dictionary:
    return {"attempts": CAPACITY, "next_attempt_at": 0}
