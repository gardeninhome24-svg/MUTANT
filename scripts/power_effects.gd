extends Node
class_name PowerEffects

## Wizualne animacje mocy bojowych (Tesla Chain Lightning, Plasma Grenade, Antigravity Vortex, Dash Trail).

const LIGHTNING_BURST_TEX := preload("res://assets/mutantsurvivor_ch01/vfx/lightning_burst.png")
const EXPLOSION_TEX := preload("res://assets/mutantsurvivor_ch01/vfx/explosion_orange.png")
const SMOKE_TEX := preload("res://assets/mutantsurvivor_ch01/vfx/smoke.png")
const PORTAL_TEX := preload("res://assets/mutantsurvivor_ch01/vfx/portal.png")
const PLASMA_PURPLE_TEX := preload("res://assets/mutantsurvivor_ch01/vfx/plasma_purple.png")
const GRENADE_TEX := preload("res://assets/mutantsurvivor_ch01/icons/grenade.png")

static var _shared_add_mat: CanvasItemMaterial = null

static func get_additive_mat() -> CanvasItemMaterial:
	if _shared_add_mat == null:
		_shared_add_mat = CanvasItemMaterial.new()
		_shared_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _shared_add_mat

## 1. Łuk elektryczny Tesla (Chain Lightning pomiędzy graczem a trafionymi wrogami)
static func spawn_chain_lightning(layer: Node, chain_points: PackedVector2Array) -> void:
	if not is_instance_valid(layer) or not layer.is_inside_tree() or chain_points.size() < 2:
		return

	var add_mat := get_additive_mat()

	# Long chains should not saturate mobile GPUs with dozens of line nodes.
	for idx in range(mini(chain_points.size() - 1, 12)):
		var p_start := chain_points[idx]
		var p_end := chain_points[idx + 1]

		# Zewnętrzna poświata błyskawicy
		var glow_line := Line2D.new()
		glow_line.width = 9.0
		glow_line.default_color = Color(0.25, 0.78, 1.0, 0.65)
		glow_line.material = add_mat

		# Jasny rdzeń błyskawicy
		var core_line := Line2D.new()
		core_line.width = 3.2
		core_line.default_color = Color(0.88, 0.98, 1.0, 0.98)
		core_line.material = add_mat

		var steps := 6
		var perp := (p_end - p_start).normalized().orthogonal()
		for s in range(steps + 1):
			var t := float(s) / float(steps)
			var pt := p_start.lerp(p_end, t)
			if s > 0 and s < steps:
				pt += perp * randf_range(-18.0, 18.0)
			glow_line.add_point(pt)
			core_line.add_point(pt)

		layer.add_child(glow_line)
		layer.add_child(core_line)

		# Rozbłysk wyładowania na trafionym celu
		var burst := Sprite2D.new()
		burst.texture = LIGHTNING_BURST_TEX
		burst.global_position = p_end
		burst.scale = Vector2(0.85, 0.85)
		burst.material = add_mat
		layer.add_child(burst)

		var tw := layer.create_tween()
		tw.set_parallel(true)
		tw.tween_property(glow_line, "modulate:a", 0.0, 0.24)
		tw.tween_property(core_line, "modulate:a", 0.0, 0.24)
		tw.tween_property(burst, "scale", Vector2(1.25, 1.25), 0.22)
		tw.tween_property(burst, "modulate:a", 0.0, 0.24)
		tw.chain().tween_callback(func():
			if is_instance_valid(glow_line): glow_line.queue_free()
			if is_instance_valid(core_line): core_line.queue_free()
			if is_instance_valid(burst): burst.queue_free()
		)

## 2. Widmowy ślad Dasha (Afterimage Ghost Trail)
static func spawn_dash_ghost(layer: Node, source_sprite: Sprite2D, world_pos: Vector2) -> void:
	if not is_instance_valid(layer) or not layer.is_inside_tree() or not is_instance_valid(source_sprite) or source_sprite.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = source_sprite.texture
	ghost.hframes = source_sprite.hframes
	ghost.vframes = source_sprite.vframes
	ghost.frame = source_sprite.frame
	ghost.flip_h = source_sprite.flip_h
	ghost.scale = source_sprite.scale
	ghost.global_position = world_pos + source_sprite.position
	ghost.modulate = Color(0.25, 0.92, 1.0, 0.62)
	layer.add_child(ghost)

	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ghost.queue_free)

## 3. Rzut Granatem Plazmowym (parabola lotu + fala uderzeniowa + wybuch + dym)
static func throw_plasma_grenade(layer: Node, start_pos: Vector2, target_pos: Vector2, blast_damage: float, blast_radius: float = 175.0) -> void:
	if not is_instance_valid(layer) or not layer.is_inside_tree():
		return
	blast_radius = maxf(0.0, blast_radius)
	blast_damage = maxf(0.0, blast_damage)
	if blast_damage <= 0.0:
		return

	var gren := Sprite2D.new()
	gren.texture = GRENADE_TEX
	gren.global_position = start_pos
	gren.scale = Vector2(0.58, 0.58)
	layer.add_child(gren)

	var flight_time := 0.38
	var elapsed := 0.0
	while elapsed < flight_time and is_instance_valid(gren) and is_instance_valid(layer) and layer.is_inside_tree():
		var dt := layer.get_process_delta_time()
		elapsed += dt
		var t := clampf(elapsed / flight_time, 0.0, 1.0)
		var ground_pos := start_pos.lerp(target_pos, t)
		var arc_height := sin(t * PI) * 78.0
		gren.global_position = ground_pos + Vector2(0, -arc_height)
		gren.rotation += 14.0 * dt
		await layer.get_tree().process_frame

	if is_instance_valid(gren):
		gren.queue_free()

	if not is_instance_valid(layer) or not layer.is_inside_tree():
		return

	# Zadaj obrażenia obszarowe wrogom w promieniu eksplozji
	var blast_radius_sq := blast_radius * blast_radius
	var enemies := layer.get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var enemy := e as MutantEnemy
		if is_instance_valid(enemy) and not enemy.is_dying and enemy.visible and enemy.global_position.distance_squared_to(target_pos) <= blast_radius_sq:
			enemy.take_damage(blast_damage)

	var add_mat := get_additive_mat()

	# Dym pod wybuchem
	var smoke := Sprite2D.new()
	smoke.texture = SMOKE_TEX
	smoke.global_position = target_pos
	smoke.scale = Vector2(0.8, 0.8)
	smoke.modulate = Color(0.9, 0.9, 0.95, 0.75)
	layer.add_child(smoke)

	# Główna kula ognia (Additive blend -> zero ciemnego tła!)
	var exp_spr := Sprite2D.new()
	exp_spr.texture = EXPLOSION_TEX
	exp_spr.global_position = target_pos
	exp_spr.scale = Vector2(0.5, 0.5)
	exp_spr.material = add_mat
	layer.add_child(exp_spr)

	var tw := layer.create_tween()
	tw.set_parallel(true)
	tw.tween_property(exp_spr, "scale", Vector2(2.1, 2.1), 0.28)
	tw.tween_property(exp_spr, "modulate:a", 0.0, 0.34)
	tw.tween_property(smoke, "scale", Vector2(2.3, 2.3), 0.55)
	tw.tween_property(smoke, "modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(func():
		if is_instance_valid(exp_spr): exp_spr.queue_free()
		if is_instance_valid(smoke): smoke.queue_free()
	)

## Toxic mine is a real proximity-triggered combat upgrade, not a cosmetic card.
## Uses the existing grenade/energy visual assets and an armed green glow.
static func deploy_toxic_mine(layer: Node, world_pos: Vector2, damage: float) -> void:
	if not is_instance_valid(layer) or not layer.is_inside_tree():
		return
	var mine := Sprite2D.new()
	mine.texture = GRENADE_TEX
	mine.global_position = world_pos
	mine.modulate = Color(0.26, 1.0, 0.43, 0.94)
	mine.scale = Vector2(0.35, 0.35)
	mine.z_index = 1
	layer.add_child(mine)
	var elapsed: float = 0.0
	var detonated: bool = false
	while elapsed < 11.0 and is_instance_valid(mine) and mine.is_inside_tree():
		await layer.get_tree().process_frame
		if not is_instance_valid(layer) or not layer.is_inside_tree() or not is_instance_valid(mine):
			return
		elapsed += maxf(0.001, layer.get_process_delta_time())
		mine.modulate.a = 0.78 + 0.18 * sin(elapsed * 5.0)
		if elapsed < 0.35:
			continue
		for actor in layer.get_tree().get_nodes_in_group("enemies"):
			var target := actor as MutantEnemy
			if is_instance_valid(target) and not target.is_dying and target.global_position.distance_squared_to(world_pos) <= 56.0 * 56.0:
				detonated = true
				break
		if detonated:
			break
	if is_instance_valid(mine):
		mine.queue_free()
	if not detonated or not is_instance_valid(layer) or not layer.is_inside_tree():
		return
	for actor in layer.get_tree().get_nodes_in_group("enemies"):
		var enemy := actor as MutantEnemy
		if is_instance_valid(enemy) and not enemy.is_dying and enemy.global_position.distance_squared_to(world_pos) <= 115.0 * 115.0:
			enemy.take_damage(maxf(1.0, damage))
	var bloom := Sprite2D.new()
	bloom.texture = EXPLOSION_TEX
	bloom.global_position = world_pos
	bloom.modulate = Color(0.24, 1.0, 0.42, 0.8)
	bloom.scale = Vector2(0.35, 0.35)
	bloom.material = get_additive_mat()
	layer.add_child(bloom)
	var pulse := bloom.create_tween()
	pulse.set_parallel(true)
	pulse.tween_property(bloom, "scale", Vector2(1.35, 1.35), 0.32)
	pulse.tween_property(bloom, "modulate:a", 0.0, 0.32)
	pulse.chain().tween_callback(bloom.queue_free)


## 4. Osobliwość Antygrawitacyjna / Czarna Dziura (wciąga wrogów i zadaje obrażenia fazowe)
static func spawn_antigravity_vortex(layer: Node, world_pos: Vector2, tick_damage: float, duration: float = 2.8, pull_radius: float = 240.0) -> void:
	if not is_instance_valid(layer) or not layer.is_inside_tree():
		return
	duration = maxf(0.05, duration)
	pull_radius = maxf(0.0, pull_radius)
	tick_damage = maxf(0.0, tick_damage)

	var add_mat := get_additive_mat()

	var vortex := Sprite2D.new()
	vortex.texture = PORTAL_TEX
	vortex.global_position = world_pos
	vortex.scale = Vector2(0.2, 0.2)
	vortex.material = add_mat
	layer.add_child(vortex)

	var core := Sprite2D.new()
	core.texture = PLASMA_PURPLE_TEX
	core.global_position = world_pos
	core.scale = Vector2(0.5, 0.5)
	core.material = add_mat
	layer.add_child(core)

	var tw_in := vortex.create_tween()
	tw_in.tween_property(vortex, "scale", Vector2(1.85, 1.85), 0.25)

	var elapsed := 0.0
	var dmg_accum := 0.0
	var pull_radius_sq := pull_radius * pull_radius
	var damage_radius_sq := pull_radius_sq * 0.7225
	while elapsed < duration and is_instance_valid(vortex) and is_instance_valid(core) and is_instance_valid(layer) and layer.is_inside_tree():
		var dt := layer.get_process_delta_time()
		elapsed += dt
		dmg_accum += dt
		vortex.rotation -= 6.5 * dt
		var pulse := 1.0 + sin(elapsed * 14.0) * 0.15
		core.scale = Vector2(0.95 * pulse, 0.95 * pulse)

		var do_tick := false
		if dmg_accum >= 0.35:
			dmg_accum = 0.0
			do_tick = true

		var enemies := layer.get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			var enemy := e as MutantEnemy
			if is_instance_valid(enemy) and not enemy.is_dying and enemy.visible:
				var dist_sq := enemy.global_position.distance_squared_to(world_pos)
				if dist_sq <= pull_radius_sq and dist_sq > 324.0:
					var pull_dir := (world_pos - enemy.global_position).normalized()
					var pull_strength := 155.0 if enemy.tier != "boss" else 45.0
					enemy.global_position += pull_dir * pull_strength * dt
				if do_tick and dist_sq <= damage_radius_sq:
					enemy.take_damage(tick_damage)

		await layer.get_tree().process_frame

	if is_instance_valid(vortex) and is_instance_valid(core) and is_instance_valid(layer) and layer.is_inside_tree():
		var tw_out := layer.create_tween()
		tw_out.set_parallel(true)
		tw_out.tween_property(vortex, "scale", Vector2(2.6, 2.6), 0.22)
		tw_out.tween_property(vortex, "modulate:a", 0.0, 0.22)
		tw_out.tween_property(core, "scale", Vector2(2.4, 2.4), 0.22)
		tw_out.tween_property(core, "modulate:a", 0.0, 0.22)
		tw_out.chain().tween_callback(func():
			if is_instance_valid(vortex): vortex.queue_free()
			if is_instance_valid(core): core.queue_free()
		)
