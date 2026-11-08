extends Area2D
class_name VibroSaw

@export var damage: float = 35.0
@export var orbit_speed: float = 3.8
@export var orbit_radius: float = 115.0

var player_ref: Node2D = null
var current_angle: float = 0.0
var spin_angle: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		sprite.material = PowerEffects.get_additive_mat()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
	current_angle += orbit_speed * delta
	spin_angle += 16.0 * delta
	var offset := Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
	global_position = player_ref.global_position + Vector2(0, -18) + offset
	if sprite:
		sprite.rotation = spin_angle
	queue_redraw()

func _draw() -> void:
	# Wirujące ostrza plazmowe i smuga cięcia
	draw_arc(Vector2.ZERO, 24.0, spin_angle, spin_angle + PI * 1.35, 20, Color(0.25, 0.95, 1.0, 0.85), 3.2, true)
	draw_arc(Vector2.ZERO, 18.0, -spin_angle, -spin_angle + PI * 1.1, 16, Color(0.85, 0.98, 1.0, 0.9), 2.0, true)
	for i in range(4):
		var a := spin_angle + float(i) * (TAU / 4.0)
		var p1 := Vector2(cos(a), sin(a)) * 14.0
		var p2 := Vector2(cos(a + 0.35), sin(a + 0.35)) * 28.0
		draw_line(p1, p2, Color(0.4, 0.98, 1.0, 0.92), 2.5, true)

func _on_body_entered(body: Node2D) -> void:
	if body is MutantEnemy:
		body.take_damage(damage)
