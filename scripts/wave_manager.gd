extends Node

# Struktura: 100 POZIOMÓW (LEVELS)
# Na KAŻDYM poziomie (np. Level 1, Level 2 ... Level 100) jest DOKŁADNIE 10 FAL WROGÓW (Wave 1 do 10)!
# Fala 10 na każdym poziomie to BOSS danego poziomu!

const WAVES_PER_LEVEL: int = 10
const WAVE_DURATION: float = 30.0 # 30 sekund na falę (dynamiczne tempo a la Brotato)

static func get_wave_info(level_num: int, wave_num: int) -> Dictionary:
	var is_boss_wave = (wave_num == WAVES_PER_LEVEL)
	var is_elite_wave = (wave_num == 5)
	
	# Skalowanie poziomu i fali
	var enemy_count = 15 + (wave_num * 4) + (level_num * 2)
	var spawn_rate = max(0.25, 1.2 - (wave_num * 0.08) - (level_num * 0.005))
	
	# Wrogowie:
	var enemies = ["beetle"]
	if wave_num >= 3 or level_num >= 2:
		enemies.append("stalker")
	if wave_num >= 7 or level_num >= 5:
		enemies.append("behemoth")
		
	var title = "BOSS WAVE 10/10" if is_boss_wave else ("ELITE HORDE 5/10" if is_elite_wave else "WAVE %d / 10" % wave_num)
	
	return {
		"level": level_num,
		"wave": wave_num,
		"is_boss": is_boss_wave,
		"is_elite": is_elite_wave,
		"duration": WAVE_DURATION,
		"spawn_interval": spawn_rate,
		"max_enemies": enemy_count,
		"enemy_types": enemies,
		"title": title
	}
