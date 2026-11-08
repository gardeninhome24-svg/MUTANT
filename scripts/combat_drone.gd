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
	if not is_instance_valid(player_ref):
		return
	current_angle += 2.0 * delta
	var target_pos = player_ref.global_position + Vector2(cos(current_angle), sin(current_angle)) * 85.0
	global_position = lerp(global_position, target_pos, 8.0 * delta)
	
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		shoot_nearest()

func shoot_nearest() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var target: Node2D = null
	var min_d = 500.0
	for e in enemies:
		if is_instance_valid(e):
			var d = global_position.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				target = e
	if target:
		var bolt = PLASMA_BOLT_SCENE.instantiate()
		bolt.global_position = global_position
		bolt.direction = (target.global_position - global_position).normalized()
		bolt.damage = damage
		bolt.speed = 520.0
		get_parent().add_child(bolt)
