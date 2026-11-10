extends Node
class_name MSWaveDirector
## Dynamic Wave Director & High-Performance Horde Controller
## Handles 10-wave horde escalation, formation spawning, Object Pooling, and adaptive device scaling.

enum PerfProfile { LOW, MEDIUM, HIGH }

@export var profile: PerfProfile = PerfProfile.MEDIUM
@export var base_wave_duration: float = 30.0
@export var adaptive_density_enabled: bool = true

var main_ref: Node2D = null
var characters_layer: Node2D = null
var effects_layer: Node2D = null

var current_wave: int = 1
var max_waves: int = 10
var wave_time_left: float = 30.0
var spawn_timer: float = 0.0
var perf_sample_timer: float = 0.0
var dynamic_cap_multiplier: float = 1.0
var _last_wave_second: int = -1
var _last_density_count: int = -1
var _last_density_cap: int = -1

# Object Pool for regular mutants to eliminate allocations/freeing GC spikes
var enemy_pool: Dictionary = {} # enemy_id (String) -> Array[MutantEnemy]
var active_enemies: Array[MutantEnemy] = []

# Target caps per wave: [wave 1..10]
const HORDE_TARGETS_MEDIUM := [18, 26, 36, 46, 54, 62, 72, 82, 92, 65]
const HORDE_TARGETS_LOW    := [14, 20, 26, 32, 38, 44, 50, 56, 62, 48]
const HORDE_TARGETS_HIGH   := [22, 32, 44, 56, 68, 78, 88, 98, 108, 80]
const MAX_POOLED_PER_ARCHETYPE: int = 24
const MIN_SPAWN_DELTA: float = 0.0
const MAX_SPAWN_DELTA: float = 0.25
const ALL_ARCHETYPES := ["biegacz", "zracy_pelzacz", "zdziczaly", "zarazony", "plujacy_kwasem", "lowca", "skrzydlaty", "czerw"]
const EARLY_ARCHETYPES := ["biegacz", "zracy_pelzacz", "zarazony"]
const LATE_ARCHETYPES := ["lowca", "skrzydlaty", "plujacy_kwasem", "zdziczaly", "zarazony"]

signal wave_changed(wave_num: int, time_left: float, max_waves: int)
signal wave_completed(wave_num: int)
signal horde_density_updated(active_count: int, target_cap: int)

func bind_context(p_main: Node2D, p_chars_layer: Node2D, p_fx_layer: Node2D) -> void:
	main_ref = p_main
	characters_layer = p_chars_layer
	effects_layer = p_fx_layer

func set_performance_profile(p: PerfProfile) -> void:
	profile = p

func get_max_active_for_wave(w: int) -> int:
	var idx := clampi(w - 1, 0, 9)
	var base_cap: int
	match profile:
		PerfProfile.LOW:
			base_cap = HORDE_TARGETS_LOW[idx]
		PerfProfile.HIGH:
			base_cap = HORDE_TARGETS_HIGH[idx]
		_:
			base_cap = HORDE_TARGETS_MEDIUM[idx]

	if not adaptive_density_enabled:
		return base_cap
	dynamic_cap_multiplier = clampf(dynamic_cap_multiplier, 0.55, 1.0)
	var adapted := int(roundf(float(base_cap) * dynamic_cap_multiplier))
	# Honor low-end profile instead of silently forcing its first wave from 14 to 18.
	return clampi(adapted, maxi(1, int(ceil(float(base_cap) * 0.55))), 105)

func start_wave(w_num: int, duration_sec: float = 30.0) -> void:
	current_wave = clampi(w_num, 1, maxi(1, max_waves))
	wave_time_left = maxf(0.0, duration_sec)
	spawn_timer = 0.0
	perf_sample_timer = 0.0
	_last_wave_second = int(ceil(wave_time_left))
	_last_density_count = -1
	_last_density_cap = -1
	emit_signal("wave_changed", current_wave, wave_time_left, max_waves)

func process_wave(delta: float, player: Node2D, stage_num: int, elapsed_sec: float) -> void:
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	delta = maxf(0.0, delta)
	_update_adaptive_performance(delta)

	if wave_time_left > 0.0:
		wave_time_left = maxf(0.0, wave_time_left - delta)
		# Whole-second display: no need to emit 60 identical HUD updates/s.
		var current_second: int = int(ceil(wave_time_left))
		if current_second != _last_wave_second:
			_last_wave_second = current_second
			emit_signal("wave_changed", current_wave, wave_time_left, max_waves)
		if wave_time_left <= 0.0:
			emit_signal("wave_completed", current_wave)

	# Clean active enemy list
	_prune_active_enemies()

	var target_cap := get_max_active_for_wave(current_wave)
	var current_count := active_enemies.size()
	if current_count != _last_density_count or target_cap != _last_density_cap:
		_last_density_count = current_count
		_last_density_cap = target_cap
		emit_signal("horde_density_updated", current_count, target_cap)

	# Dynamic spawn interval: faster when below cap
	var deficit := target_cap - current_count
	if deficit <= 0:
		spawn_timer = 0.0
		return

	var interval := 0.25 if deficit > 16 else (0.45 if deficit > 6 else 0.75)
	# Limit catch-up burst after the app resumes from background.
	spawn_timer += clampf(delta, MIN_SPAWN_DELTA, MAX_SPAWN_DELTA)
	if spawn_timer >= interval:
		spawn_timer = 0.0
		# Spawn in packs of 2 to 6 for authentic, thrilling swarm feel
		var max_p := 4 if current_wave < 4 else 6
		var pack_size := clampi(mini(deficit, randi_range(2, max_p)), 1, deficit)
		if not is_instance_valid(characters_layer) or not characters_layer.is_inside_tree():
			return
		_spawn_horde_pack(pack_size, player, stage_num, elapsed_sec)

func _update_adaptive_performance(delta: float) -> void:
	if not adaptive_density_enabled:
		return
	perf_sample_timer += minf(maxf(0.0, delta), 0.25)
	if perf_sample_timer >= 0.45:
		perf_sample_timer = 0.0
		var fps := float(Engine.get_frames_per_second())
		if fps > 0.0:
			if fps < 40.0:
				# Low-end mobile load detected -> throttle smoothly
				dynamic_cap_multiplier = maxf(0.55, dynamic_cap_multiplier - 0.08)
			elif fps >= 55.0 and dynamic_cap_multiplier < 1.0:
				# High performance headroom -> restore cap
				dynamic_cap_multiplier = minf(1.0, dynamic_cap_multiplier + 0.04)

func _prune_active_enemies() -> void:
	# Reverse in-place pruning avoids allocating a fresh typed array every frame.
	if active_enemies.is_empty():
		return
	for index in range(active_enemies.size() - 1, -1, -1):
		var e: MutantEnemy = active_enemies[index]
		if not is_instance_valid(e) or e.is_dying or not e.is_inside_tree() or not e.visible:
			active_enemies.remove_at(index)

func _get_wave_archetype(stage_num: int, wave_num: int) -> String:
	if stage_num <= 3 and wave_num <= 2:
		return EARLY_ARCHETYPES[randi() % EARLY_ARCHETYPES.size()]
	if wave_num >= 8:
		return LATE_ARCHETYPES[randi() % LATE_ARCHETYPES.size()]
	return ALL_ARCHETYPES[randi() % ALL_ARCHETYPES.size()]

func _spawn_horde_pack(count: int, player: Node2D, stage_num: int, elapsed_sec: float) -> void:
	if not is_instance_valid(player) or not player.is_inside_tree() or not is_instance_valid(characters_layer) or not characters_layer.is_inside_tree() or count <= 0:
		return
	var center := player.global_position
	var cluster_angle := randf() * TAU
	var cluster_dist := randf_range(380.0, 560.0)
	var cluster_origin := center + Vector2(cos(cluster_angle), sin(cluster_angle)) * cluster_dist
	cluster_origin.x = clampf(cluster_origin.x, -1120.0, 1120.0)
	cluster_origin.y = clampf(cluster_origin.y, -860.0, 860.0)

	var arc := _get_wave_archetype(stage_num, current_wave)
	for i in range(count):
		var offset := Vector2(randf_range(-65.0, 65.0), randf_range(-65.0, 65.0))
		var spawn_pos := cluster_origin + offset
		spawn_pos.x = clampf(spawn_pos.x, -1140.0, 1140.0)
		spawn_pos.y = clampf(spawn_pos.y, -880.0, 880.0)
		# Clamping near arena walls must not spawn an enemy atop the hero.
		if spawn_pos.distance_to(center) < 180.0:
			var away := (spawn_pos - center).normalized()
			if away.is_zero_approx():
				away = Vector2.RIGHT
			var candidate_pos := center + away * 180.0
			candidate_pos.x = clampf(candidate_pos.x, -1140.0, 1140.0)
			candidate_pos.y = clampf(candidate_pos.y, -880.0, 880.0)
			spawn_pos = candidate_pos
		_spawn_single_enemy(arc, spawn_pos, stage_num, elapsed_sec)

func _spawn_single_enemy(arch_id: String, pos: Vector2, stage_num: int, elapsed_sec: float) -> MutantEnemy:
	var enemy: MutantEnemy = null
	var is_elite := (current_wave >= 5) and (randf() < 0.12)
	var tier := "elite" if is_elite else "normal"

	if enemy_pool.has(arch_id):
		while not enemy_pool[arch_id].is_empty():
			var candidate: MutantEnemy = enemy_pool[arch_id].pop_back()
			if is_instance_valid(candidate) and candidate.is_inside_tree() and not candidate.is_queued_for_deletion() and candidate.is_dying:
				enemy = candidate
				break
	if is_instance_valid(enemy):
		enemy.reset_for_respawn(arch_id, tier, stage_num, elapsed_sec, pos)
	else:
		if main_ref and main_ref.get("ENEMY_SCENES") != null:
			var scenes: Dictionary = main_ref.ENEMY_SCENES
			var sc: PackedScene = scenes.get(arch_id, scenes.get("zracy_pelzacz"))
			if sc:
				enemy = sc.instantiate()
				enemy.is_pooled = true
				enemy.wave_director_ref = self
				if characters_layer:
					characters_layer.add_child(enemy)
				enemy.global_position = pos
				enemy.effects_layer = effects_layer
				enemy.setup_enemy_archetype(arch_id, tier, stage_num, elapsed_sec)

	if not is_instance_valid(enemy):
		return null
	enemy.is_pooled = true
	enemy.wave_director_ref = self

	# New and recycled enemies must always use the current battle effects layer.
	enemy.effects_layer = effects_layer
	if not enemy.enemy_died.is_connected(_on_pooled_enemy_died):
		enemy.enemy_died.connect(_on_pooled_enemy_died)

	if not active_enemies.has(enemy):
		active_enemies.append(enemy)
	return enemy

func recycle_enemy(enemy: MutantEnemy) -> void:
	if not is_instance_valid(enemy):
		return
	active_enemies.erase(enemy)
	if enemy.is_queued_for_deletion() or not enemy.is_dying:
		return
	enemy.velocity = Vector2.ZERO
	var aid := enemy.enemy_id
	if not enemy_pool.has(aid):
		enemy_pool[aid] = []
	if enemy_pool[aid].has(enemy):
		return
	# Purge orphan references before checking the cap. Otherwise dead
	# references can block reuse and create needless extra allocations.
	for index in range(enemy_pool[aid].size() - 1, -1, -1):
		var old_enemy: MutantEnemy = enemy_pool[aid][index]
		if not is_instance_valid(old_enemy) or old_enemy.is_queued_for_deletion():
			enemy_pool[aid].remove_at(index)
	if enemy_pool[aid].size() >= MAX_POOLED_PER_ARCHETYPE:
		enemy.queue_free()
		return
	enemy_pool[aid].append(enemy)

func _on_pooled_enemy_died(enemy: MutantEnemy) -> void:
	# A repeated or late event must not grant another run kill.
	if not active_enemies.has(enemy):
		return
	active_enemies.erase(enemy)
	if is_instance_valid(main_ref) and main_ref.is_inside_tree() and main_ref.has_method("_on_enemy_died"):
		main_ref.call("_on_enemy_died", enemy)

func recycle_all_enemies() -> void:
	for e in active_enemies:
		if is_instance_valid(e):
			e.queue_free()
	active_enemies.clear()
	spawn_timer = 0.0
	perf_sample_timer = 0.0
	_last_wave_second = -1
	_last_density_count = -1
	_last_density_cap = -1
	for k in enemy_pool.keys():
		for e in enemy_pool[k]:
			if is_instance_valid(e):
				e.queue_free()
	enemy_pool.clear()
	dynamic_cap_multiplier = 1.0
	wave_time_left = 0.0
