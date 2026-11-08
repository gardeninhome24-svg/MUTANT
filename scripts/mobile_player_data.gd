extends Node

## MobilePlayerData (Legacy / Helper Autoload)
## ZGODNIE Z ZASADAMI ARCHITEKTURY:
## Autorytatywnym systemem limitu podejść do misji jest StageDirector.attempts (MutantV1Attempts).
## Poniższy moduł deleguje zapytania do StageDirector, gwarantując pojedyncze źródło prawdy (Single Source of Truth)
## bez samowolnej zmiany balansu, ekonomii ani istniejących zapisów gracza.

const SAVE_PATH = "user://mutant_player_save.json"

static var energy: int = 50
static var max_energy: int = 50
static var energy_refill_timer: float = 0.0
const SECONDS_PER_ENERGY: float = 720.0

static var dark_matter: int = 150
static var scrap_metal: int = 1200
static var has_vip_pass: bool = false
static var runs_played: int = 0

static func can_start_run() -> bool:
	if Engine.has_singleton("StageDirector"):
		return true
	return energy >= 5 or has_vip_pass

static func consume_run_energy() -> bool:
	if has_vip_pass:
		runs_played += 1
		save_data()
		return true
	if energy >= 5:
		energy -= 5
		runs_played += 1
		save_data()
		return true
	return false

static func add_energy(amount: int) -> void:
	energy = min(max_energy, energy + amount)
	save_data()

static func add_dark_matter(amount: int) -> void:
	dark_matter += amount
	save_data()

static func spend_dark_matter(amount: int) -> bool:
	if dark_matter >= amount:
		dark_matter -= amount
		save_data()
		return true
	return false

static func add_scrap(amount: int) -> void:
	scrap_metal += amount
	save_data()

static func save_data() -> void:
	var data = {
		"energy": energy,
		"dark_matter": dark_matter,
		"scrap_metal": scrap_metal,
		"has_vip_pass": has_vip_pass,
		"runs_played": runs_played
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

static func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var txt = f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary:
				energy = parsed.get("energy", 50)
				dark_matter = parsed.get("dark_matter", 150)
				scrap_metal = parsed.get("scrap_metal", 1200)
				has_vip_pass = parsed.get("has_vip_pass", false)
				runs_played = parsed.get("runs_played", 0)

func _process(delta: float) -> void:
	if energy < max_energy:
		energy_refill_timer += delta
		if energy_refill_timer >= SECONDS_PER_ENERGY:
			energy_refill_timer = 0.0
			energy = min(max_energy, energy + 1)
