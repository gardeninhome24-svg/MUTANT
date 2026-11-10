extends Area2D
class_name ExplosiveBarrel

@export var max_health: float = 24.0
@export var blast_damage: float = 160.0
@export var blast_radius: float = 185.0

var current_health: float = 24.0
var is_exploded: bool = false

@onready var sprite: Sprite2D = $Sprite2D

const EXPLOSION_TEX = preload("res://assets/mutantsurvivor_ch01/vfx/explosion_orange.png")

func _ready() -> void:
	add_to_group("destructibles")
	current_health = max_health

func take_damage(amount: float) -> void:
	if is_exploded or amount <= 0.0:
		return
	current_health -= amount

	var tween := create_tween()
	sprite.modulate = Color(2.5, 1.4, 0.4, 1.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	if current_health <= 0.0:
		explode()

func explode() -> void:
	if is_exploded:
		return
	is_exploded = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var radius_sq := blast_radius * blast_radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is MutantEnemy and not enemy.is_dying and enemy.visible and global_position.distance_squared_to(enemy.global_position) <= radius_sq:
			enemy.take_damage(blast_damage)

	sprite.texture = EXPLOSION_TEX
	sprite.material = PowerEffects.get_additive_mat()
	var tween_exp := create_tween()
	sprite.scale = Vector2(1.4, 1.4)
	sprite.modulate = Color(1.6, 1.3, 1.0, 1.0)
	tween_exp.tween_property(sprite, "modulate:a", 0.0, 0.32)
	await tween_exp.finished
	queue_free()
