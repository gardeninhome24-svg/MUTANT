extends Node

# Baza danych 10 Rozdziałów po 10 Poziomów (łącznie 100 poziomów)
const CHAPTERS_DB = [
	{
		"chapter": 1,
		"name": "Wasteland Outskirts",
		"start_lvl": 1,
		"end_lvl": 10,
		"boss_name": "Acid Brood Queen",
		"ambient_color": Color(0.9, 0.85, 0.7, 1.0)
	},
	{
		"chapter": 2,
		"name": "Chemical Swamp",
		"start_lvl": 11,
		"end_lvl": 20,
		"boss_name": "Toxic Leviathan",
		"ambient_color": Color(0.6, 0.95, 0.6, 1.0)
	},
	{
		"chapter": 3,
		"name": "Ruined Metro",
		"start_lvl": 21,
		"end_lvl": 30,
		"boss_name": "Cyber-Ghoulish Colossus",
		"ambient_color": Color(0.65, 0.7, 0.85, 1.0)
	},
	{
		"chapter": 4,
		"name": "Automaton Scrap Depot",
		"start_lvl": 31,
		"end_lvl": 40,
		"boss_name": "Mecha-Goliath Tank",
		"ambient_color": Color(0.85, 0.75, 0.6, 1.0)
	},
	{
		"chapter": 5,
		"name": "Irradiated Caldera",
		"start_lvl": 41,
		"end_lvl": 50,
		"boss_name": "Radioactive Behemoth",
		"ambient_color": Color(0.8, 1.0, 0.5, 1.0)
	},
	{
		"chapter": 6,
		"name": "Dark Matter Mine",
		"start_lvl": 51,
		"end_lvl": 60,
		"boss_name": "Void Devourer",
		"ambient_color": Color(0.7, 0.5, 0.9, 1.0)
	},
	{
		"chapter": 7,
		"name": "Cryo Mutation Lab",
		"start_lvl": 61,
		"end_lvl": 70,
		"boss_name": "Sub-Zero Stalker",
		"ambient_color": Color(0.5, 0.8, 1.0, 1.0)
	},
	{
		"chapter": 8,
		"name": "Burning Reactor Ruins",
		"start_lvl": 71,
		"end_lvl": 80,
		"boss_name": "Infernal Meltdown Titan",
		"ambient_color": Color(1.0, 0.6, 0.4, 1.0)
	},
	{
		"chapter": 9,
		"name": "Bio-Dome Omega",
		"start_lvl": 81,
		"end_lvl": 90,
		"boss_name": "Genetic Hive Archon",
		"ambient_color": Color(0.9, 0.6, 0.85, 1.0)
	},
	{
		"chapter": 10,
		"name": "The Mutation Core",
		"start_lvl": 91,
		"end_lvl": 100,
		"boss_name": "Apex Hivemind God",
		"ambient_color": Color(1.0, 0.3, 0.3, 1.0)
	}
]

# Obliczanie XP na kolejne poziomy do 100 poziomu
static func get_xp_for_level(lvl: int) -> float:
	var chapter = int((lvl - 1) / 10) + 1
	var base = 20.0 + (chapter * 15.0)
	return base + (lvl * 14.0)

# Obliczanie balansu wrogów do 100 poziomu (trudność wzrasta co rozdział)
static func get_enemy_scaling(game_time: float, current_lvl: int) -> Dictionary:
	var minute = game_time / 60.0
	var chapter = int((current_lvl - 1) / 10) + 1
	var hp_mult = 1.0 + (chapter * 0.45) + (minute * 0.15)
	var speed_mult = min(1.85, 1.0 + (chapter * 0.04) + (minute * 0.02))
	var spawn_rate = max(0.22, 1.4 - (chapter * 0.08) - (minute * 0.04))
	
	return {
		"hp_multiplier": hp_mult,
		"speed_multiplier": speed_mult,
		"spawn_interval": spawn_rate,
		"chapter": chapter
	}

# Pełna baza 12 synergii i broni
const UPGRADES_DB = [
	{
		"id": "plasma_dmg",
		"name": "Cewki przeciążeniowe",
		"desc": "+25% obrażeń działa plazmowego",
		"max_tier": 5
	},
	{
		"id": "plasma_cooldown",
		"name": "Nadprzewodniki",
		"desc": "Krótszy odstęp między strzałami o 18%",
		"max_tier": 5
	},
	{
		"id": "vibro_saws",
		"name": "Ostrza wibracyjne",
		"desc": "Wirujące ostrza bronią bohatera z bliska",
		"max_tier": 5
	},
	{
		"id": "tesla_coil",
		"name": "Wyładowanie Tesli",
		"desc": "Pioruny rażą mutanty i zwiększają obrażenia Tesli",
		"max_tier": 5
	},
	{
		"id": "titanium_skin",
		"name": "Tytanowy egzoszkielet",
		"desc": "+35 maks. HP i +1,5 HP regeneracji na sekundę",
		"max_tier": 5
	},
	{
		"id": "bionic_speed",
		"name": "Serwomechanizmy",
		"desc": "+18% prędkości poruszania się",
		"max_tier": 5
	},
	{
		"id": "magnetic_drone",
		"name": "Dron magnetyczny",
		"desc": "+45% zasięgu zbierania doświadczenia",
		"max_tier": 5
	},
	{
		"id": "critical_focus",
		"name": "Celownik neuronowy",
		"desc": "+12 p.p. szansy na krytyk i +35% mnożnika",
		"max_tier": 5
	},
	{
		"id": "bio_hazard",
		"name": "Miny toksyczne",
		"desc": "Miny kwasowe eksplodują po kontakcie z wrogiem",
		"max_tier": 5
	},
	{
		"id": "energy_shield",
		"name": "Tarcza energetyczna Aegis",
		"desc": "Tarcza pochłania dwa trafienia przeciwników",
		"max_tier": 5
	}
]
