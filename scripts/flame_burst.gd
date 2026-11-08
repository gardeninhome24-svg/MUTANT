extends Area2D
class_name FlameBurst

@export var speed: float = 380.0
@export var damage: float = 22.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.85

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	scale += Vector2(1.2, 1.2) * delta # Płomień rośnie w miarę lotu
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is MutantEnemy:
		body.take_damage(damage)
