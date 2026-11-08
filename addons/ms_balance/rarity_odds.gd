extends RefCounted
class_name MSRarityOdds
## Transparent proposed chances. All purchased random rewards require verified store compliance.
const ODDS := {"common": 0.52, "rare": 0.30, "epic": 0.135, "legendary": 0.04, "mythic": 0.005}
const GUARANTEE: int = 50
static func odds_are_valid() -> bool:
    var total := 0.0
    for value in ODDS.values():
        total += float(value)
    return absf(total - 1.0) < 0.00001

static func roll_rarity(pity_counter: int, rng: RandomNumberGenerator) -> String:
    ## pity_counter is pre-open count of unsuccessful opens, 49 => 50th guarantees.
    if pity_counter >= GUARANTEE - 1:
        return "legendary"
    var value := rng.randf()
    for rarity in ["common", "rare", "epic", "legendary", "mythic"]:
        value -= float(ODDS[rarity])
        if value <= 0.0:
            return rarity
    return "mythic"

static func next_pity_count(old_counter: int, awarded_rarity: String) -> int:
    return 0 if awarded_rarity in ["legendary", "mythic"] else mini(old_counter + 1, GUARANTEE - 1)
