extends Node

func _ready() -> void:
	print("--- ROZPOCZECIE SYMULACJI PROGRESJI DO 30 LVL ---")
	
	var total_runs = 100
	var wins = 0
	
	for run_id in range(total_runs):
		var player_level = 1
		var player_hp = 120.0
		var player_max_hp = 120.0
		var player_dps = 40.0
		var run_time = 0.0 # sekundy
		var is_alive = true
		
		# Symulacja pętli biegu do 30 poziomu (ok. 15-18 minut)
		while player_level < 30 and is_alive:
			run_time += 1.0
			var scaling = GameProgression.get_enemy_scaling(run_time, player_level)
			
			# Otrzymane i zadawane obrażenia w sekundzie
			var enemy_dps_to_player = (scaling["hp_multiplier"] * 8.0) * (0.85 if player_level > 10 else 0.5)
			# Redukcja obrażeń przez ewolucje i pozycjonowanie gracza
			var player_damage_taken = max(0.0, enemy_dps_to_player - (player_level * 0.45))
			
			player_hp -= player_damage_taken * 0.15 # uwzględnienie unikania (kiting)
			
			# Zabijanie wrogów i zbieranie XP
			var xp_gained = player_dps * 0.4
			var needed_xp = GameProgression.get_xp_for_level(player_level)
			if xp_gained >= (needed_xp / 25.0):
				player_level += 1
				player_dps *= 1.15
				player_max_hp += 10.0
				player_hp = min(player_max_hp, player_hp + 30.0) # leczenie przy awansie
				
			if player_hp <= 0:
				is_alive = false
				
		if is_alive and player_level >= 30:
			wins += 1
			
	var win_rate = (float(wins) / float(total_runs)) * 100.0
	print("WYNIK SYMULACJI 100 BIEGÓW:")
	print("Wygrane (Level 30 osiągnięty): %d / %d" % [wins, total_runs])
	print("Wskaźnik ukończenia (Win Rate): %.1f%%" % win_rate)
	print("Cel projektowy (80%%): %s" % ("ZALICZONY" if abs(win_rate - 80.0) <= 5.0 else "DO KOREKTY"))
	get_tree().quit()
