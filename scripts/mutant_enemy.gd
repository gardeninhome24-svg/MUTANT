extends CharacterBody2D
class_name MutantEnemy

@export var enemy_id: String = "biegacz"
@export var tier: String = "normal" # "normal", "elite", "miniboss", "boss"
@export var move_speed: float = 125.0
@export var max_health: float = 55.0
@export var damage: float = 14.0
@export var xp_value: float = 14.0

var current_health: float = 55.0
var target: Node2D = null
var anim_timer: float = 0.0
var base_scale: Vector2 = Vector2(0.55, 0.55)
var is_animated_sheet: bool = false
var walk_frames: Array[Texture2D] = []
var attack_frames: Array[Texture2D] = []
var death_frames: Array[Texture2D] = []
var sheet_fps: float = 9.0
var asset_status: String = "HD_MUTANT_V2"
var effects_layer: Node2D = null

# Mechanika telegrafowanego ataku dla Bossa / Minibossa (0.95s ostrzeżenia na ziemi) + strzały dystansowe i fazy Bossa
var special_cooldown: float = 5.5
var special_timer: float = 2.0
var ranged_spit_timer: float = 2.6
var boss_phase: int = 1
var current_stage_context: int = 1
var is_telegraphing: bool = false
var telegraph_duration: float = 0.95
var telegraph_elapsed: float = 0.0
var telegraph_world_pos: Vector2 = Vector2.ZERO
var telegraph_radius: float = 120.0
var is_dying: bool = false
var is_pooled: bool = false
var has_dropped_loot: bool = false
var wave_director_ref: Node = null

signal enemy_damaged(enemy: MutantEnemy)
signal enemy_died(enemy: MutantEnemy)

@onready var sprite: Sprite2D = $Sprite2D

const XP_SHARD_SCENE = preload("res://scenes/environment/xp_shard.tscn")
const TOXIC_SPLASH_TEX = preload("res://assets/mutantsurvivor_ch01/vfx/toxic_splash.png")
const IMPACT_BURST_TEX = preload("res://assets/mutantsurvivor_ch01/vfx/impact_burst.png")

func _ready() -> void:
	add_to_group("enemies")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	setup_enemy_archetype(enemy_id, tier, 1, 0.0)

func reset_for_respawn(p_enemy_id: String, p_tier: String, stage_num: int, elapsed_sec: float, spawn_pos: Vector2) -> void:
	is_dying = false
	has_dropped_loot = false
	global_position = spawn_pos
	visible = true
	set_physics_process(true)
	velocity = Vector2.ZERO
	anim_timer = 0.0
	special_timer = 2.0
	ranged_spit_timer = 2.6
	is_telegraphing = false
	telegraph_elapsed = 0.0
	boss_phase = 1

	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

	if sprite:
		sprite.modulate = Color.WHITE

	setup_enemy_archetype(p_enemy_id, p_tier, stage_num, elapsed_sec)
	queue_redraw()

func setup_enemy_archetype(p_enemy_id: String, p_tier: String, stage_num: int, elapsed_sec: float) -> void:
	enemy_id = p_enemy_id
	tier = p_tier
	current_stage_context = stage_num
	boss_phase = 1
	if sprite:
		var vis_info := AssetRegistry.apply_enemy_visual(sprite, enemy_id)
		is_animated_sheet = bool(vis_info.get("is_animated", false))
		sheet_fps = float(vis_info.get("fps", 9.0))
		asset_status = String(vis_info.get("status", "HD_MUTANT_V2"))
		base_scale = vis_info.get("base_scale", Vector2(0.56, 0.56))
		walk_frames.clear()
		for f in vis_info.get("walk_frames", []):
			if f is Texture2D: walk_frames.append(f)
		attack_frames.clear()
		for f in vis_info.get("attack_frames", []):
			if f is Texture2D: attack_frames.append(f)
		death_frames.clear()
		for f in vis_info.get("death_frames", []):
			if f is Texture2D: death_frames.append(f)

	if Engine.has_singleton("StageDirector") or get_node_or_null("/root/StageDirector") != null:
		var scaled := StageDirector.get_enemy_scaled_stats(enemy_id, stage_num, elapsed_sec, tier)
		max_health = float(scaled["max_hp"])
		damage = float(scaled["damage"])
		move_speed = float(scaled["speed"])
		xp_value = float(scaled["xp_reward"])
		var bracket := StageDirector.get_stage_bracket_info(stage_num)
		telegraph_duration = float(bracket.get("telegraph_sec", 0.95))
	current_health = max_health
	if tier == "boss":
		telegraph_radius = 135.0
		special_cooldown = 5.0
	elif tier == "miniboss":
		telegraph_radius = 95.0
		special_cooldown = 6.5
	queue_redraw()

func apply_scaling(hp_mult: float, speed_mult: float) -> void:
	max_health *= hp_mult
	current_health = max_health
	move_speed *= speed_mult
	queue_redraw()

func _draw() -> void:
	# Pierścień pod elitą / minibossem / bossem
	if tier == "boss":
		draw_arc(Vector2(0, 6), 54.0, 0.0, TAU, 40, Color(1.0, 0.22, 0.18, 0.78), 3.0, true)
	elif tier == "miniboss" or tier == "elite":
		draw_arc(Vector2(0, 4), 38.0, 0.0, TAU, 32, Color(1.0, 0.65, 0.15, 0.68), 2.5, true)

	# Telegrafowany obszar uderzenia na ziemi (0.95s przed wybuchem)
	if is_telegraphing:
		var local_t_pos := to_local(telegraph_world_pos)
		var prog := clampf(telegraph_elapsed / telegraph_duration, 0.0, 1.0)
		draw_circle(local_t_pos, telegraph_radius, Color(0.95, 0.18, 0.12, 0.16 + 0.22 * prog))
		draw_circle(local_t_pos, telegraph_radius * prog, Color(1.0, 0.42, 0.15, 0.28))
		draw_arc(local_t_pos, telegraph_radius, 0.0, TAU, 44, Color(1.0, 0.25, 0.15, 0.92), 3.0, true)

	# Pasek HP nad głową wroga (styl z referencji target_gameplay_visual.png)
	var bar_w := 52.0 if tier == "normal" else (78.0 if tier != "boss" else 110.0)
	var bar_h := 6.0 if tier == "normal" else 8.0
	var y_off := -72.0 if tier == "normal" else (-96.0 if tier != "boss" else -118.0)
	var bar_pos := Vector2(-bar_w * 0.5, y_off)
	draw_rect(Rect2(bar_pos - Vector2(1, 1), Vector2(bar_w + 2, bar_h + 2)), Color(0.05, 0.06, 0.08, 0.92))
	var ratio := clampf(current_health / maxf(1.0, max_health), 0.0, 1.0)
	var fill_col := Color(0.92, 0.20, 0.18, 0.96) if tier != "boss" else Color(0.95, 0.18, 0.45, 0.98)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, bar_h)), fill_col)

func _physics_process(delta: float) -> void:
	if is_dying or not is_instance_valid(target):
		return

	# Wielofazowość Bossa (Faza 2 poniżej 55% HP, Faza 3 poniżej 25% HP od etapu 50+)
	if tier == "boss":
		var hp_pct := current_health / maxf(1.0, max_health)
		if boss_phase == 1 and hp_pct <= 0.55 and current_stage_context >= 11:
			boss_phase = 2
			move_speed *= 1.18
			special_cooldown = 3.8
			_fire_radial_acid_burst(4)
		elif boss_phase == 2 and hp_pct <= 0.25 and current_stage_context >= 50:
			boss_phase = 3
			move_speed *= 1.15
			special_cooldown = 3.0
			_fire_radial_acid_burst(6)

	# Dystansowe plucie kwasem dla "plujacy_kwasem" oraz Elit/Bossów od etapu 11+
	if (enemy_id == "plujacy_kwasem" or tier == "boss" or (tier == "elite" and current_stage_context >= 15)) and current_stage_context >= 5:
		ranged_spit_timer -= delta
		if ranged_spit_timer <= 0.0 and global_position.distance_to(target.global_position) <= 440.0:
			ranged_spit_timer = 3.2 if enemy_id == "plujacy_kwasem" else 4.2
			_fire_acid_glob(target.global_position)

	# Obsługa telegrafowanego ataku obszarowego dla Bossa i Minibossa
	if tier == "boss" or tier == "miniboss":
		if is_telegraphing:
			telegraph_elapsed += delta
			queue_redraw()
			if telegraph_elapsed >= telegraph_duration:
				_execute_telegraphed_slam()
			return
		else:
			special_timer -= delta
			if special_timer <= 0.0 and global_position.distance_to(target.global_position) < 420.0:
				is_telegraphing = true
				telegraph_elapsed = 0.0
				telegraph_world_pos = target.global_position
				special_timer = special_cooldown
				queue_redraw()
				return

	var dir := (target.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()
	global_position.x = clampf(global_position.x, -1220.0, 1220.0)
	global_position.y = clampf(global_position.y, -960.0, 960.0)

	anim_timer += delta
	if is_telegraphing and not attack_frames.is_empty():
		var af_idx := int(anim_timer * sheet_fps) % attack_frames.size()
		sprite.texture = attack_frames[af_idx]
		sprite.scale = base_scale
	elif not walk_frames.is_empty():
		var wf_idx := int(anim_timer * sheet_fps) % walk_frames.size()
		sprite.texture = walk_frames[wf_idx]
		sprite.scale = base_scale
	elif is_animated_sheet and sprite.hframes > 1:
		sprite.frame = int(anim_timer * sheet_fps) % sprite.hframes
		sprite.scale = base_scale
	else:
		# Subtelny ruch kroku dla tymczasowych statycznych grafik referencyjnych
		var step := sin(anim_timer * 12.0) * 0.032
		sprite.scale = Vector2(base_scale.x + step, base_scale.y - step)

	if dir.x != 0.0:
		sprite.flip_h = dir.x > 0.0

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Player:
			collider.take_damage(damage * delta)

func _execute_telegraphed_slam() -> void:
	is_telegraphing = false
	queue_redraw()
	if is_instance_valid(target) and target.global_position.distance_to(telegraph_world_pos) <= telegraph_radius:
		if target.has_method("take_damage"):
			target.take_damage(damage * 1.65)

	# Wizualny rozbłysk toksyczny w miejscu uderzenia
	var vfx := Sprite2D.new()
	vfx.texture = TOXIC_SPLASH_TEX
	vfx.material = PowerEffects.get_additive_mat()
	vfx.global_position = telegraph_world_pos
	vfx.scale = Vector2(1.4, 1.4) if tier == "boss" else Vector2(1.0, 1.0)
	var parent_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
	parent_layer.add_child(vfx)
	var tw := vfx.create_tween()
	tw.tween_property(vfx, "modulate:a", 0.0, 0.55)
	tw.tween_callback(vfx.queue_free)

func take_damage(amount: float) -> void:
	current_health -= amount
	queue_redraw()
	emit_signal("enemy_damaged", self)

	var parent_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
	var dmg_lbl := DamageNumber.new()
	parent_layer.add_child(dmg_lbl)
	dmg_lbl.setup(amount, amount > 45.0, global_position + Vector2(0, -36))

	# Krótki efekt trafienia (impact_burst)
	var hit_fx := Sprite2D.new()
	hit_fx.texture = IMPACT_BURST_TEX
	hit_fx.material = PowerEffects.get_additive_mat()
	hit_fx.global_position = global_position + Vector2(randf_range(-10, 10), -28)
	hit_fx.scale = Vector2(0.42, 0.42)
	parent_layer.add_child(hit_fx)
	var tw_fx := hit_fx.create_tween()
	tw_fx.tween_property(hit_fx, "modulate:a", 0.0, 0.14)
	tw_fx.tween_callback(hit_fx.queue_free)

	var tween := create_tween()
	sprite.modulate = Color(2.5, 0.45, 0.45, 1.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

	if current_health <= 0.0:
		die()

func _fire_acid_glob(target_pos: Vector2) -> void:
	var parent_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
	if not is_instance_valid(parent_layer):
		return
	var glob := Sprite2D.new()
	glob.texture = TOXIC_SPLASH_TEX
	glob.material = PowerEffects.get_additive_mat()
	glob.global_position = global_position + Vector2(0, -24)
	glob.scale = Vector2(0.38, 0.38)
	glob.modulate = Color(0.45, 1.0, 0.25, 0.92)
	parent_layer.add_child(glob)
	var tw := glob.create_tween()
	tw.tween_property(glob, "global_position", target_pos, 0.55)
	tw.tween_callback(func():
		if is_instance_valid(target) and target.global_position.distance_to(target_pos) <= 58.0:
			if target.has_method("take_damage"):
				target.take_damage(damage * 0.85)
		glob.scale = Vector2(0.85, 0.85)
	)
	tw.tween_property(glob, "modulate:a", 0.0, 0.25)
	tw.tween_callback(glob.queue_free)

func _fire_radial_acid_burst(count: int) -> void:
	for i in range(count):
		var ang := (TAU / float(maxi(1, count))) * float(i)
		var dest := global_position + Vector2(cos(ang), sin(ang)) * 210.0
		_fire_acid_glob(dest)

func die() -> void:
	if is_dying:
		return
	is_dying = true
	if not death_frames.is_empty() and sprite:
		sprite.texture = death_frames[0]

	if not has_dropped_loot:
		has_dropped_loot = true
		StageDirector.record_daily_mission_progress("kill_mutants", 1)
		emit_signal("enemy_died", self)
		var shard := XP_SHARD_SCENE.instantiate()
		shard.global_position = global_position
		shard.xp_amount = xp_value
		get_parent().call_deferred("add_child", shard)

	# Animacja śmierci wroga (rozbłysk toksyczny)
	var parent_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
	if is_instance_valid(parent_layer):
		var death_fx := Sprite2D.new()
		death_fx.texture = TOXIC_SPLASH_TEX
		death_fx.material = PowerEffects.get_additive_mat()
		death_fx.global_position = global_position + Vector2(0, -18)
		death_fx.scale = Vector2(0.55, 0.55)
		parent_layer.add_child(death_fx)
		var tw := death_fx.create_tween()
		tw.tween_property(death_fx, "scale", Vector2(0.95, 0.95), 0.22)
		tw.parallel().tween_property(death_fx, "modulate:a", 0.0, 0.22)
		tw.tween_callback(death_fx.queue_free)

	if is_pooled and is_instance_valid(wave_director_ref):
		for child in get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
		visible = false
		set_physics_process(false)
		velocity = Vector2.ZERO
		wave_director_ref.recycle_enemy(self)
	else:
		queue_free()
