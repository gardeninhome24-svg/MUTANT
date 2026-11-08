extends CharacterBody2D
class_name Player

@export var move_speed: float = 255.0
@export var max_health: float = 160.0
var current_health: float = 160.0
var health_regen: float = 0.5
var armor_reduction: float = 0.0

# Poziom w runie (tymczasowy na czas etapu)
var level: int = 1
var max_level: int = 100
var current_xp: float = 0.0
var xp_to_next_level: float = 30.0
var free_rerolls: int = 1

# Broń główna: Karabin Plazmowy A-03
var attack_cooldown: float = 0.52
var attack_timer: float = 0.0
var attack_damage: float = 36.0
var projectile_speed: float = 680.0
var crit_chance: float = 0.10
var crit_multiplier: float = 1.65

# Bronie dodatkowe i gadżety pasywne
var has_vibro_saws: bool = false
var saw_count: int = 0
var saw_damage: float = 42.0

var has_tesla: bool = false
var tesla_timer: float = 0.0
var tesla_cooldown: float = 1.5
var tesla_damage: float = 52.0

var has_shield: bool = false
var shield_charges: int = 0
var shield_recharge_timer: float = 0.0
var shield_sprite: Sprite2D = null

# Aktywne Moce Bojowe (Granat Plazmowy [Q] oraz Wir Antygrawitacji [E])
var grenade_cooldown: float = 6.5
var grenade_timer: float = 0.0
var grenade_damage: float = 145.0

var vortex_cooldown: float = 10.5
var vortex_timer: float = 0.0
var vortex_damage: float = 42.0

var magnet_radius: float = 230.0
var external_move_dir: Vector2 = Vector2.ZERO
var projectiles_layer: Node2D = null
var effects_layer: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_point: Marker2D = $ShootPoint
@onready var muzzle_flash: Sprite2D = $ShootPoint/MuzzleFlash

var anim_timer: float = 0.0
var dash_ghost_timer: float = 0.0
var shoot_anim_timer: float = 0.0
var invulnerable_timer: float = 0.0
var base_skin_tint: Color = Color.WHITE
var equipped_rarity_color: Color = Color(0.18, 0.98, 0.38, 0.72)
var walk_frames: Array[Texture2D] = []
var shoot_frames: Array[Texture2D] = []
var soldier_walk_frames: Array[Texture2D] = []
var soldier_shoot_frames: Array[Texture2D] = []
var idle_frames: Array[Texture2D] = []
var hurt_frames: Array[Texture2D] = []
var death_frames: Array[Texture2D] = []
var base_idle_tex: Texture2D = null
var has_frame_anim: bool = false
var use_soldier_frame_anim: bool = false
var auto_skill_ctrl: MSAutoSkillController = null

signal health_changed(curr, max_val)
signal xp_changed(curr, needed, lvl)
signal leveled_up(new_lvl)
signal player_died()
signal game_won()

const PLASMA_BOLT_SCENE = preload("res://scenes/projectiles/plasma_bolt.tscn")
const VIBRO_SAW_SCENE = preload("res://scenes/projectiles/vibro_saw.tscn")
const SHIELD_TEX = preload("res://assets/mutantsurvivor_ch01/vfx/shield.png")

# Dash / Unik [Spacja]
var dash_speed: float = 660.0
var dash_duration: float = 0.22
var dash_cooldown: float = 2.2
var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_setup_shield_vfx()
	apply_class_and_talents(true)
	xp_to_next_level = float(StageDirector.get_run_xp_needed(level))
	if muzzle_flash:
		muzzle_flash.visible = false
		muzzle_flash.material = PowerEffects.get_additive_mat()
	emit_signal("health_changed", current_health, max_health)
	emit_signal("xp_changed", current_xp, xp_to_next_level, level)
	queue_redraw()

func _setup_shield_vfx() -> void:
	shield_sprite = Sprite2D.new()
	shield_sprite.texture = SHIELD_TEX
	shield_sprite.material = PowerEffects.get_additive_mat()
	shield_sprite.position = Vector2(0, -30)
	shield_sprite.scale = Vector2(0.82, 0.82)
	shield_sprite.modulate = Color(0.45, 0.92, 1.0, 0.72)
	shield_sprite.visible = false
	add_child(shield_sprite)

func apply_class_and_talents(reset_full_hp: bool = false) -> void:
	var hp_ratio := clampf(current_health / maxf(1.0, max_health), 0.1, 1.0)
	if Engine.has_singleton("StageDirector") or get_node_or_null("/root/StageDirector") != null:
		var cls_id := StageDirector.selected_class_id
		var cls_cfg: Dictionary = StageDirector.HERO_CLASSES.get(cls_id, StageDirector.HERO_CLASSES["soldier"])
		var skin_cfg: Dictionary = StageDirector.HERO_SKINS.get(StageDirector.selected_skin_id, StageDirector.HERO_SKINS["default"])
		base_skin_tint = skin_cfg.get("tint", Color.WHITE)
		if sprite:
			AssetRegistry.apply_player_visual(sprite, cls_id, StageDirector.selected_skin_id)
			sprite.modulate = base_skin_tint
			base_idle_tex = sprite.texture
			walk_frames.clear()
			shoot_frames.clear()
			soldier_walk_frames.clear()
			soldier_shoot_frames.clear()
			for fi in range(1, 7):
				var wt := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_walk_%d.png" % [cls_id, fi])
				var st := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_shoot_%d.png" % [cls_id, fi])
				if wt:
					walk_frames.append(wt)
					soldier_walk_frames.append(wt)
				if st:
					shoot_frames.append(st)
					soldier_shoot_frames.append(st)
			has_frame_anim = (walk_frames.size() > 0)
			use_soldier_frame_anim = has_frame_anim
			idle_frames.clear()
			hurt_frames.clear()
			death_frames.clear()
			for fi in range(1, 5):
				var it := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_idle_%d.png" % [cls_id, fi])
				if it: idle_frames.append(it)
			for fi in range(1, 4):
				var ht := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_hurt_%d.png" % [cls_id, fi])
				if ht: hurt_frames.append(ht)
			for fi in range(1, 7):
				var dt := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_death_%d.png" % [cls_id, fi])
				if dt: death_frames.append(dt)

		if not is_instance_valid(auto_skill_ctrl):
			auto_skill_ctrl = MSAutoSkillController.new()
			auto_skill_ctrl.name = "AutoSkillController"
			add_child(auto_skill_ctrl)
			auto_skill_ctrl.bind_to_player(self)
		var clvl := StageDirector.get_class_level(cls_id)
		auto_skill_ctrl.set_unlocks(clvl >= 5, clvl >= 30)

		# Kolor taktycznego pierścienia pod stopami dopasowany do najwyższej rzadkości założonego pancerza/broni
		var w_inst := String(StageDirector.equipped_items.get("weapon", ""))
		var c_inst := String(StageDirector.equipped_items.get("chest", ""))
		var check_item := StageDirector.get_item_instance(c_inst if not c_inst.is_empty() else w_inst)
		if not check_item.is_empty():
			var rar := String(check_item.get("rarity", "common"))
			var r_col: Color = StageDirector.RARITY_COLORS.get(rar, Color(0.18, 0.98, 0.38))
			equipped_rarity_color = Color(r_col.r, r_col.g, r_col.b, 0.78)
		else:
			equipped_rarity_color = Color(0.18, 0.98, 0.38, 0.72)

		var vit_lvl := int(StageDirector.talent_levels.get("vitality", 1))
		var fire_lvl := int(StageDirector.talent_levels.get("firepower", 1))
		var scan_lvl := int(StageDirector.talent_levels.get("scanner", 0))
		var arm_lvl := int(StageDirector.talent_levels.get("armor_plating", 0))
		var eq_bonuses := StageDirector.get_total_equipment_bonuses()

		var base_hp := (150.0 + float(eq_bonuses.get("flat_hp", 0.0))) * float(cls_cfg.get("hp_mult", 1.0))
		var base_dmg := (35.0 + float(eq_bonuses.get("flat_damage", 0.0))) * float(cls_cfg.get("dmg_mult", 1.0))
		var spd_pct := 1.0 + float(eq_bonuses.get("move_speed_pct", 0.0)) * 0.01
		move_speed = 255.0 * float(cls_cfg.get("speed_mult", 1.0)) * spd_pct
		health_regen = 0.5 + float(cls_cfg.get("regen_bonus", 0.0))

		var hp_mult_total := 1.0 + 0.06 * float(vit_lvl) + float(eq_bonuses.get("hp_pct", 0.0)) * 0.01
		var dmg_mult_total := 1.0 + 0.05 * float(fire_lvl) + float(eq_bonuses.get("attack_pct", 0.0)) * 0.01
		max_health = roundf(base_hp * hp_mult_total)
		attack_damage = roundf(base_dmg * dmg_mult_total)
		magnet_radius = (220.0 + 18.0 * float(scan_lvl)) * (1.25 if cls_id == "engineer" else 1.0) * (1.0 + float(eq_bonuses.get("pickup_radius_pct", 0.0)) * 0.01)
		armor_reduction = clampf(0.03 * float(arm_lvl) + float(eq_bonuses.get("flat_armor", 0.0)) * 0.008, 0.0, 0.45)
		crit_chance = (0.22 if cls_id == "scout" else 0.10) + float(eq_bonuses.get("crit_chance_pct", 0.0)) * 0.01
		crit_multiplier = 1.65 + float(eq_bonuses.get("crit_damage_pct", 0.0)) * 0.01
		if cls_id == "engineer" and not has_tesla:
			has_tesla = true

	if reset_full_hp:
		current_health = max_health
	else:
		current_health = clampf(max_health * hp_ratio, 1.0, max_health)
	emit_signal("health_changed", current_health, max_health)
	queue_redraw()

func _draw() -> void:
	# Taktyczny pierścień pod stopami bohatera + pierścień rzadkości założonego pancerza RPG
	draw_arc(Vector2(0, 4), 28.0, 0.0, TAU, 36, Color(0.18, 0.98, 0.38, 0.72), 2.5, true)
	draw_arc(Vector2(0, 4), 34.0, 0.0, TAU, 36, equipped_rarity_color, 1.8, true)
	draw_arc(Vector2(0, 4), 22.0, 0.0, TAU, 32, Color(0.18, 0.98, 0.38, 0.28), 1.5, true)
	if has_shield and shield_charges > 0:
		draw_arc(Vector2(0, -30), 46.0, 0.0, TAU, 36, Color(0.25, 0.88, 1.0, 0.65), 2.2, true)

	# Pasek HP bezpośrednio nad głową postaci (zgodny z referencją)
	var bar_w := 54.0
	var bar_h := 6.0
	var bar_pos := Vector2(-bar_w * 0.5, -104.0)
	draw_rect(Rect2(bar_pos - Vector2(1, 1), Vector2(bar_w + 2, bar_h + 2)), Color(0.05, 0.08, 0.1, 0.9))
	var hp_ratio := clampf(current_health / maxf(1.0, max_health), 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_ratio, bar_h)), Color(0.25, 0.95, 0.32, 0.95))

func perform_dash() -> void:
	if dash_timer > 0.0 or is_dashing:
		return
	is_dashing = true
	dash_timer = dash_cooldown
	dash_ghost_timer = 0.0
	dash_direction = velocity.normalized() if velocity.length() > 0.1 else (Vector2.LEFT if sprite.flip_h else Vector2.RIGHT)

	var fx_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
	PowerEffects.spawn_dash_ghost(fx_layer, sprite, global_position)

	var tween := create_tween()
	sprite.modulate = Color(0.45, 1.8, 2.2, 0.9)
	tween.tween_property(sprite, "modulate", base_skin_tint, dash_duration)

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

func use_plasma_grenade() -> bool:
	if grenade_timer > 0.0:
		return false
	grenade_timer = grenade_cooldown
	var target := find_nearest_enemy()
	var target_pos: Vector2
	if is_instance_valid(target):
		target_pos = target.global_position
	else:
		var facing := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		target_pos = global_position + facing * 240.0
	var fx_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
	PowerEffects.throw_plasma_grenade(fx_layer, global_position + Vector2(0, -24), target_pos, grenade_damage + attack_damage * 1.4, 175.0)
	return true

func use_antigravity_vortex() -> bool:
	if vortex_timer > 0.0:
		return false
	vortex_timer = vortex_cooldown
	var target := find_nearest_enemy()
	var target_pos: Vector2
	if is_instance_valid(target):
		target_pos = target.global_position
	else:
		var facing := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		target_pos = global_position + facing * 220.0
	var fx_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
	PowerEffects.spawn_antigravity_vortex(fx_layer, target_pos, vortex_damage + attack_damage * 0.65, 2.8, 230.0)
	return true

func _physics_process(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
	if grenade_timer > 0.0:
		grenade_timer = maxf(0.0, grenade_timer - delta)
	if vortex_timer > 0.0:
		vortex_timer = maxf(0.0, vortex_timer - delta)
	if invulnerable_timer > 0.0:
		invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	if shoot_anim_timer > 0.0:
		shoot_anim_timer = maxf(0.0, shoot_anim_timer - delta)

	if shield_sprite:
		var show_sh := (has_shield and shield_charges > 0) or (invulnerable_timer > 0.0)
		shield_sprite.visible = show_sh
		if show_sh:
			shield_sprite.rotation += 2.2 * delta
			var s_pulse := 0.80 + sin(anim_timer * 3.0) * 0.05
			shield_sprite.scale = Vector2(s_pulse, s_pulse)

	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		_clamp_to_arena()
		dash_ghost_timer += delta
		if dash_ghost_timer >= 0.045:
			dash_ghost_timer = 0.0
			var fx_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
			PowerEffects.spawn_dash_ghost(fx_layer, sprite, global_position)
		return

	if health_regen > 0.0 and current_health < max_health:
		current_health = minf(max_health, current_health + health_regen * delta)
		emit_signal("health_changed", current_health, max_health)
		queue_redraw()

	if Input.is_action_just_pressed("ui_accept"):
		perform_dash()

	var keyboard_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var final_input := keyboard_input
	if external_move_dir != Vector2.ZERO:
		final_input = external_move_dir

	velocity = final_input * move_speed
	move_and_slide()
	_clamp_to_arena()

	if velocity.length() > 10.0:
		anim_timer += delta * 14.0
		var bob := sin(anim_timer) * 0.045
		var tilt := clampf(velocity.x * 0.0005, -0.12, 0.12)
		sprite.scale = Vector2(0.52 + bob, 0.52 - bob)
		sprite.rotation = tilt
		if has_frame_anim and shoot_anim_timer <= 0.0 and walk_frames.size() > 0:
			var f_idx := int(anim_timer * 0.8) % walk_frames.size()
			sprite.texture = walk_frames[f_idx]
	else:
		anim_timer += delta * 3.5
		var breathe := sin(anim_timer) * 0.018
		sprite.scale = Vector2(0.52, 0.52 + breathe)
		sprite.rotation = lerpf(sprite.rotation, 0.0, 10.0 * delta)
		if not idle_frames.is_empty() and shoot_anim_timer <= 0.0:
			var i_idx := int(anim_timer * 1.5) % idle_frames.size()
			sprite.texture = idle_frames[i_idx]
		elif has_frame_anim and shoot_anim_timer <= 0.0 and base_idle_tex != null:
			sprite.texture = base_idle_tex
	if has_frame_anim and shoot_anim_timer > 0.0 and shoot_frames.size() > 0:
		var s_idx := clampi(int((1.0 - shoot_anim_timer / 0.18) * float(shoot_frames.size())), 0, shoot_frames.size() - 1)
		sprite.texture = shoot_frames[s_idx]

	if final_input.x != 0.0:
		sprite.flip_h = final_input.x < 0.0
		shoot_point.position.x = -28.0 if sprite.flip_h else 28.0

	attack_timer += delta
	if attack_timer >= attack_cooldown:
		var target := find_nearest_enemy()
		if target:
			shoot_at_enemy(target)
			attack_timer = 0.0

	if has_tesla:
		tesla_timer += delta
		if tesla_timer >= tesla_cooldown:
			fire_tesla()
			tesla_timer = 0.0

	if has_shield and shield_charges < 2:
		shield_recharge_timer += delta
		if shield_recharge_timer >= 12.0:
			shield_charges += 1
			shield_recharge_timer = 0.0
			queue_redraw()

func _clamp_to_arena() -> void:
	global_position.x = clampf(global_position.x, -1210.0, 1210.0)
	global_position.y = clampf(global_position.y, -950.0, 950.0)

func find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node2D = null
	var min_dist := 720.0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_enemy = enemy

	return nearest_enemy

func shoot_at_enemy(target: Node2D) -> void:
	var bolt := PLASMA_BOLT_SCENE.instantiate()
	var dir := (target.global_position - shoot_point.global_position).normalized()
	if dir.x != 0.0:
		sprite.flip_h = dir.x < 0.0
		shoot_point.position.x = -28.0 if sprite.flip_h else 28.0

	bolt.global_position = shoot_point.global_position
	bolt.direction = dir

	var is_crit := randf() < crit_chance
	var final_dmg := attack_damage * (crit_multiplier if is_crit else 1.0)
	bolt.damage = final_dmg
	bolt.speed = projectile_speed

	var container: Node = projectiles_layer if is_instance_valid(projectiles_layer) else get_parent()
	container.add_child(bolt)

	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.rotation = dir.angle()
		var tween_m := create_tween()
		tween_m.tween_property(muzzle_flash, "scale", Vector2(0.65, 0.65), 0.05).from(Vector2(0.2, 0.2))
		tween_m.tween_property(muzzle_flash, "visible", false, 0.03)

	var tween_recoil := create_tween()
	sprite.position.x = -dir.x * 5.0
	tween_recoil.tween_property(sprite, "position:x", 0.0, 0.10)
	shoot_anim_timer = 0.18
	StageDirector.play_sfx("shoot")

func fire_tesla() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var valid_enemies: Array = []
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 520.0:
			valid_enemies.append(e)
	if valid_enemies.size() > 0:
		valid_enemies.shuffle()
		var count := mini(4, valid_enemies.size())
		var chain_pts: Array[Vector2] = [global_position + Vector2(0, -32)]
		for i in range(count):
			var e_node := valid_enemies[i] as Node2D
			if is_instance_valid(e_node):
				chain_pts.append(e_node.global_position + Vector2(0, -24))
				if e_node.has_method("take_damage"):
					e_node.take_damage(tesla_damage)
		var fx_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
		PowerEffects.spawn_chain_lightning(fx_layer, chain_pts)

func enable_vibro_saws() -> void:
	has_vibro_saws = true
	saw_count += 1
	var saw := VIBRO_SAW_SCENE.instantiate()
	saw.player_ref = self
	saw.damage = saw_damage
	saw.current_angle = (TAU / float(maxi(1, saw_count))) * float(saw_count - 1)
	var container: Node = projectiles_layer if is_instance_valid(projectiles_layer) else get_parent()
	container.add_child(saw)

func heal(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)
	queue_redraw()

func take_damage(amount: float) -> void:
	if is_dashing or invulnerable_timer > 0.0:
		return
	if has_shield and shield_charges > 0:
		shield_charges -= 1
		queue_redraw()
		var tween_s := create_tween()
		sprite.modulate = Color(0.2, 0.8, 2.5, 1.0)
		tween_s.tween_property(sprite, "modulate", base_skin_tint, 0.2)
		return

	var reduced := maxf(1.0, amount * (1.0 - armor_reduction))
	current_health = maxf(0.0, current_health - reduced)
	StageDirector.play_sfx("hit")
	emit_signal("health_changed", current_health, max_health)
	queue_redraw()

	var tween := create_tween()
	sprite.modulate = Color(2.6, 0.35, 0.35, 1.0)
	if not hurt_frames.is_empty():
		sprite.texture = hurt_frames[0]
	tween.tween_property(sprite, "modulate", base_skin_tint, 0.15)

	if current_health <= 0.0:
		if not death_frames.is_empty():
			sprite.texture = death_frames[0]
		emit_signal("player_died")

func revive(restore_percent: float = 0.65) -> void:
	current_health = max_health * restore_percent
	invulnerable_timer = 3.5 # 3.5s tymczasowej ochrony po wskrzeszeniu
	StageDirector.play_sfx("level_up")
	emit_signal("health_changed", current_health, max_health)
	queue_redraw()
	var tween := create_tween()
	sprite.modulate = Color(0.4, 1.6, 2.2, 0.85)
	tween.tween_property(sprite, "modulate", base_skin_tint, 3.5)

func add_xp(amount: float) -> void:
	if level >= max_level:
		return

	current_xp += amount
	while current_xp >= xp_to_next_level and level < max_level:
		current_xp -= xp_to_next_level
		level += 1
		if level % 3 == 0:
			free_rerolls += 1
		xp_to_next_level = float(StageDirector.get_run_xp_needed(level))
		emit_signal("leveled_up", level)

	emit_signal("xp_changed", current_xp, xp_to_next_level, level)
