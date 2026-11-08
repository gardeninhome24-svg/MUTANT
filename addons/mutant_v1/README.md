# Mutant V1 Godot modules (integration helpers, not an installed game)

To avoid overwriting the existing `StageDirector`, `Player`, `HUD`, `UserProfilePanel`, and other project scripts, copy `addons/mutant_v1` into `res://addons/mutant_v1` and copy `data/` to `res://mutant_v1/data/`. The loader has exact `res://mutant_v1/data/` paths.

Usage from existing scripts:

```gdscript
var db = MutantV1ContentDB.new()
assert(db.load_all())
var stage_data = db.stage(1)
var rng = RandomNumberGenerator.new()
rng.randomize()
var rolled = MutantV1EquipmentRoller.roll_item(db.item_by_id("weapon_common_01"), db.documents["affixes_and_drops_v2.json"], rng)
var profile = MutantV1ProfileIO.read_profile()
var can_start = MutantV1Attempts.spend(profile, int(Time.get_unix_time_from_system()))
```

**Integration warnings**
- Keep profile saving centralized; do not make an independent competing profile if the game already saves account progression. `profile_io.gd` is a reference adapter only.
- Attempts are wall-clock based and client clock may be changed; real-money refills/entitlements require verified receipts and authoritative balances, not local storage alone.
- Only grant first-clear rewards once, after all objective progress and boss wave completion are validated. Run-based XP is separate from account XP.
- JSON files are UTF-8 (Polish); import paths are file-based and need include patterns for mobile exports.
- No payments, ads, legal compliance, full animations, enemies, or full scenes are implemented by these helpers. Test in the actual Godot version.
