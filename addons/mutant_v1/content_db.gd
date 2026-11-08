extends RefCounted
class_name MutantV1ContentDB

const DATA_DIR := "res://mutant_v1/data/"
var documents: Dictionary = {}

func load_all() -> bool:
    for spec in ["campaign_100_INTEGRATION.json", "equipment_catalog_v2.json", "affixes_and_drops_v2.json", "classes_v2.json", "talents_v2.json", "boss_and_elite_roster_v2.json", "shop_catalog_INTEGRATION.json", "stage_mutators.json"]:
        var file := FileAccess.open(DATA_DIR + spec, FileAccess.READ)
        if file == null:
            push_error("MutantV1: missing " + DATA_DIR + spec)
            return false
        var parsed: Variant = JSON.parse_string(file.get_as_text())
        if not (parsed is Dictionary):
            push_error("MutantV1: invalid JSON " + spec)
            return false
        documents[spec] = parsed
    return true

func stage(id: int) -> Dictionary:
    var camp: Dictionary = documents.get("campaign_100_INTEGRATION.json", {})
    for entry in camp.get("missions", []):
        if int(entry.get("stage", -1)) == id:
            return entry
    return {}

func item_by_id(item_id: String) -> Dictionary:
    var catalog: Dictionary = documents.get("equipment_catalog_v2.json", {})
    for item in catalog.get("items", []):
        if str(item.get("id", "")) == item_id:
            return item
    return {}

func class_by_id(class_id: String) -> Dictionary:
    var catalog: Dictionary = documents.get("classes_v2.json", {})
    for player_class in catalog.get("classes", []):
        if str(player_class.get("id", "")) == class_id:
            return player_class
    return {}
