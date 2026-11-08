# -*- coding: utf-8 -*-
path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_beta\wave_director.gd"

code = """extends Node
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

# Object Pool for regular mutants to eliminate allocations/freeing GC spikes
var enemy_pool: Dictionary = {} # enemy_id (String) -> Array[MutantEnemy]
var active_enemies: Array[MutantEnemy] = []

# Target caps per wave: [wave 1..10]
const HORDE_TARGETS_MEDIUM := [18, 26, 36, 46, 54, 62, 72, 82, 92, 65]
const HORDE_TARGETS_LOW    := [14, 20, 26, 32, 38, 44, 50, 56, 62, 48]
const HORDE_TARGETS_HIGH   := [22, 32, 44, 56, 68, 78, 88, 98, 108, 80]

signal wave_changed(wave_num: int, time_left: float, max_waves: int)
signal wave_completed(wave_num: int)
signal horde_density_updated(active_count: int, target_cap: int)

func bind_context(p_main: Node2D, p_chars_layer: Node2D, p_fx_layer: Node2D) -> void:
\tmain_ref = p_main
\tcharacters_layer = p_chars_layer
\teffects_layer = p_fx_layer

func set_performance_profile(p: PerfProfile) -> void:
\tprofile = p

func get_max_active_for_wave(w: int) -> int:
\tvar idx := clampi(w - 1, 0, 9)
\tvar base_cap: int
\tmatch profile:
\t\tPerfProfile.LOW:
\t\t\tbase_cap = HORDE_TARGETS_LOW[idx]
\t\tPerfProfile.HIGH:
\t\t\tbase_cap = HORDE_TARGETS_HIGH[idx]
\t\t_:
\t\t\tbase_cap = HORDE_TARGETS_MEDIUM[idx]

\tif not adaptive_density_enabled:
\t\treturn base_cap
\tvar adapted := int(roundf(float(base_cap) * dynamic_cap_multiplier))
\t# Floor at 18 so the battlefield is never deserted, cap at 105
\treturn clampi(adapted, 18, 105)

func start_wave(w_num: int, duration_sec: float = 30.0) -> void:
\tcurrent_wave = clampi(w_num, 1, max_waves)
\twave_time_left = duration_sec
\tspawn_timer = 0.0
\temit_signal("wave_changed", current_wave, wave_time_left, max_waves)

func process_wave(delta: float, player: Node2D, stage_num: int, elapsed_sec: float) -> void:
\t_update_adaptive_performance(delta)

\tif wave_time_left > 0.0:
\t\twave_time_left = maxf(0.0, wave_time_left - delta)
\t\temit_signal("wave_changed", current_wave, wave_time_left, max_waves)
\t\tif wave_time_left <= 0.0:
\t\t\temit_signal("wave_completed", current_wave)

\t# Clean active enemy list
\t_prune_active_enemies()

\tvar target_cap := get_max_active_for_wave(current_wave)
\tvar current_count := active_enemies.size()
\temit_signal("horde_density_updated", current_count, target_cap)

\t# Dynamic spawn interval: faster when below cap
\tvar deficit := target_cap - current_count
\tif deficit <= 0:
\t\treturn

\tvar interval := 0.25 if deficit > 16 else (0.45 if deficit > 6 else 0.75)
\tspawn_timer += delta
\tif spawn_timer >= interval:
\t\tspawn_timer = 0.0
\t\t# Spawn in packs of 2 to 6 for authentic, thrilling swarm feel
\t\tvar max_p := 4 if current_wave < 4 else 6
\t\tvar pack_size := clampi(mini(deficit, randi_range(2, max_p)), 1, deficit)
\t\t_spawn_horde_pack(pack_size, player, stage_num, elapsed_sec)

func _update_adaptive_performance(delta: float) -> void:
\tif not adaptive_density_enabled:
\t\treturn
\tperf_sample_timer += delta
\tif perf_sample_timer >= 0.45:
\t\tperf_sample_timer = 0.0
\t\tvar fps := float(Engine.get_frames_per_second())
\t\tif fps > 0.0:
\t\t\tif fps < 40.0:
\t\t\t\t# Low-end mobile load detected -> throttle smoothly
\t\t\t\tdynamic_cap_multiplier = maxf(0.55, dynamic_cap_multiplier - 0.08)
\t\t\telif fps >= 55.0 and dynamic_cap_multiplier < 1.0:
\t\t\t\t# High performance headroom -> restore cap
\t\t\t\tdynamic_cap_multiplier = minf(1.0, dynamic_cap_multiplier + 0.04)

func _prune_active_enemies() -> void:
\tvar valid: Array[MutantEnemy] = []
\tfor e in active_enemies:
\t\tif is_instance_valid(e) and not e.is_dying and e.is_inside_tree() and e.visible:
\t\t\tvalid.append(e)
\tactive_enemies = valid

func _get_wave_archetype(stage_num: int, wave_num: int) -> String:
\tvar pool := ["biegacz", "zracy_pelzacz", "zdziczaly", "zarazony", "plujacy_kwasem", "lowca", "skrzydlaty", "czerw"]
\tif stage_num <= 3 and wave_num <= 2:
\t\tvar early := ["biegacz", "zracy_pelzacz", "zarazony"]
\t\treturn early[randi() % early.size()]
\tif wave_num >= 8:
\t\tvar late := ["lowca", "skrzydlaty", "plujacy_kwasem", "zdziczaly", "zarazony"]
\t\treturn late[randi() % late.size()]
\treturn pool[randi() % pool.size()]

func _spawn_horde_pack(count: int, player: Node2D, stage_num: int, elapsed_sec: float) -> void:
\tif not is_instance_valid(player):
\t\treturn
\tvar center := player.global_position
\tvar cluster_angle := randf() * TAU
\tvar cluster_dist := randf_range(380.0, 560.0)
\tvar cluster_origin := center + Vector2(cos(cluster_angle), sin(cluster_angle)) * cluster_dist
\tcluster_origin.x = clampf(cluster_origin.x, -1120.0, 1120.0)
\tcluster_origin.y = clampf(cluster_origin.y, -860.0, 860.0)

\tvar arc := _get_wave_archetype(stage_num, current_wave)
\tfor i in range(count):
\t\tvar offset := Vector2(randf_range(-65.0, 65.0), randf_range(-65.0, 65.0))
\t\tvar spawn_pos := cluster_origin + offset
\t\tspawn_pos.x = clampf(spawn_pos.x, -1140.0, 1140.0)
\t\tspawn_pos.y = clampf(spawn_pos.y, -880.0, 880.0)
\t\t_spawn_single_enemy(arc, spawn_pos, stage_num, elapsed_sec)

func _spawn_single_enemy(arch_id: String, pos: Vector2, stage_num: int, elapsed_sec: float) -> MutantEnemy:
\tvar enemy: MutantEnemy = null
\tvar is_elite := (current_wave >= 5) and (randf() < 0.12)
\tvar tier := "elite" if is_elite else "normal"

\tif enemy_pool.has(arch_id) and enemy_pool[arch_id].size() > 0:
\t\tenemy = enemy_pool[arch_id].pop_back()
\t\tif is_instance_valid(enemy):
\t\t\tenemy.reset_for_respawn(arch_id, tier, stage_num, elapsed_sec, pos)
\telse:
\t\tif main_ref and main_ref.get("ENEMY_SCENES") != null:
\t\t\tvar scenes: Dictionary = main_ref.ENEMY_SCENES
\t\t\tvar sc: PackedScene = scenes.get(arch_id, scenes.get("zracy_pelzacz"))
\t\t\tif sc:
\t\t\t\tenemy = sc.instantiate()
\t\t\t\tenemy.is_pooled = true
\t\t\t\tenemy.wave_director_ref = self
\t\t\t\tif characters_layer:
\t\t\t\t\tcharacters_layer.add_child(enemy)
\t\t\t\tenemy.global_position = pos
\t\t\t\tenemy.effects_layer = effects_layer
\t\t\t\tenemy.setup_enemy_archetype(arch_id, tier, stage_num, elapsed_sec)

\tif not is_instance_valid(enemy):
\t\treturn null

\tif not enemy.enemy_died.is_connected(_on_pooled_enemy_died):
\t\tenemy.enemy_died.connect(_on_pooled_enemy_died)

\tif not active_enemies.has(enemy):
\t\tactive_enemies.append(enemy)
\treturn enemy

func recycle_enemy(enemy: MutantEnemy) -> void:
\tif not is_instance_valid(enemy):
\t\treturn
\tactive_enemies.erase(enemy)
\tvar aid := enemy.enemy_id
\tif not enemy_pool.has(aid):
\t\tenemy_pool[aid] = []
\tif not enemy_pool[aid].has(enemy):
\t\tenemy_pool[aid].append(enemy)

func _on_pooled_enemy_died(enemy: MutantEnemy) -> void:
\tactive_enemies.erase(enemy)
\tif is_instance_valid(main_ref) and main_ref.has_method("_on_enemy_died"):
\t\tmain_ref.call("_on_enemy_died", enemy)

func recycle_all_enemies() -> void:
\tfor e in active_enemies:
\t\tif is_instance_valid(e):
\t\t\te.queue_free()
\tactive_enemies.clear()
\tfor k in enemy_pool.keys():
\t\tfor e in enemy_pool[k]:
\t\t\tif is_instance_valid(e):
\t\t\t\te.queue_free()
\tenemy_pool.clear()
"""

with open(path, "w", encoding="utf-8") as f:
    f.write(code)
print("SUCCESSFULLY UPGRADED wave_director.gd WITH ADAPTIVE PERFORMANCE AND SAFE RECYCLING!")
