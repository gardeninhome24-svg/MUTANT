extends RefCounted
## Optional asset lookup for MutantSurvivor v1 supplementary assets.
## Does not replace existing project registry and never performs purchases.
const MANIFEST_PATH = "res://assets/mutant_v1_addon/manifest.json"
static func load_registry() -> Dictionary:
    if not FileAccess.file_exists(MANIFEST_PATH):
        push_warning("Mutant V1 asset manifest missing: " + MANIFEST_PATH)
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return parsed
static func texture_for(asset_path: String) -> Texture2D:
    if not asset_path.begins_with("res://") or not asset_path.ends_with(".png"):
        return null
    if not ResourceLoader.exists(asset_path):
        return null
    return load(asset_path) as Texture2D
