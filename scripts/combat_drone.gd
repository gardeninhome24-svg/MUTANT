extends Node2D
class_name CombatDrone

var player_ref: Node2D = null
var current_angle: float = 0.0
var shoot_timer: float = 0.0
var shoot_interval: float = 0.55
var damage: float = 24.0

@onready var sprite: Sprite2D = $Sprite2D

const PLASMA_BOLT_SCENE = preload("res://scenes/projectiles/plasma_bolt.tscn")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref) or not player_ref.is_inside_tree():
		queue_free()
		return
	current_angle += 2.0 * delta
	var target_pos = player_ref.global_position + Vector2(cos(current_angle), sin(current_angle)) * 85.0
	global_position = lerp(global_position, target_pos, clampf(8.0 * delta, 0.0, 1.0))
	
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot_nearest()

func shoot_nearest() -> void:
	var target: Node2D = null
	var nearest_sq: float = 500.0 * 500.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is MutantEnemy and not enemy.is_dying and enemy.visible and enemy.is_inside_tree():
			var distance_sq: float = global_position.distance_squared_to(enemy.global_position)
			if distance_sq < nearest_sq:
				nearest_sq = distance_sq
				target = enemy
	if is_instance_valid(target) and is_instance_valid(get_parent()):
		var aim := target.global_position - global_position
		if aim.length_squared() < 1.0:
			return
		var bolt = PLASMA_BOLT_SCENE.instantiate()
		get_parent().add_child(bolt)
		bolt.global_position = global_position
		bolt.direction = aim.normalized()
		bolt.damage = damage
		bolt.speed = 520.0
