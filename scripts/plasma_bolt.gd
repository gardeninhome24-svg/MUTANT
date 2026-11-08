extends Area2D
class_name PlasmaBolt

@export var speed: float = 680.0
@export var damage: float = 36.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.2

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	rotation = direction.angle()
	if sprite:
		sprite.material = PowerEffects.get_additive_mat()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	rotation = direction.angle()
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is MutantEnemy:
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("destructibles") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody2D and not body.is_in_group("world_border"):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("destructibles") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
