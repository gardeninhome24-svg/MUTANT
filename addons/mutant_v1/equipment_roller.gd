extends RefCounted
class_name MutantV1EquipmentRoller

# RNG is passed by caller for reproducible test seeds; persist the seed or complete item.
static func roll_item(template: Dictionary, affix_catalog: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
    if template.is_empty():
        return {}
    var pool: Array = affix_catalog.get("affixes", []).duplicate(true)
    var rolled: Array = []
    var count: int = mini(int(template.get("affix_slots", 0)), pool.size())
    for _i in range(count):
        var index: int = rng.randi_range(0, pool.size() - 1)
        var affix: Dictionary = pool[index]
        pool.remove_at(index)
        var minimum: float = float(affix.get("min_roll", 0.0))
        var maximum: float = float(affix.get("max_roll", minimum))
        var raw: float = rng.randf_range(minimum, maximum)
        var precision: float = maxf(float(affix.get("roll_precision", 0.01)), 0.001)
        var value: float = roundf(raw / precision) * precision
        rolled.append({"id": str(affix.get("id", "")), "value": snappedf(value, precision)})
    return {"instance_id": _make_id(rng), "template_id": str(template.get("id", "")), "rarity": str(template.get("rarity", "common")), "level": 0, "affixes": rolled}

static func _make_id(rng: RandomNumberGenerator) -> String:
    # Two independent 32-bit samples; backend must issue authoritative unique IDs for paid/online possessions.
    return "%08x%08x" % [rng.randi(), rng.randi()]

static func roll_rarity(weights: Dictionary, rng: RandomNumberGenerator) -> String:
    var n: int = rng.randi_range(1, 10000)
    var total: int = 0
    for rarity in ["common", "rare", "epic", "legendary", "mythic"]:
        total += int(weights.get(rarity, 0))
        if n <= total:
            return rarity
    return "common"
