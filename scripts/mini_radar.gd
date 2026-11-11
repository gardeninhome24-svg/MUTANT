extends Control
class_name MiniRadar

@export var map_size: Vector2 = Vector2(2560, 2048)
@export var tracking_diameter: float = 850.0
var radar_size: Vector2 = Vector2(144, 112)

var player_ref: Node2D = null
var beacon_world_pos: Vector2 = Vector2.ZERO
var show_beacon: bool = false

func _ready() -> void:
	custom_minimum_size = radar_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _radar_pos(world_pos: Vector2) -> Vector2:
	var origin: Vector2 = player_ref.global_position if is_instance_valid(player_ref) else Vector2.ZERO
	var relative := (world_pos - origin) / maxf(300.0, tracking_diameter)
	return (Vector2(0.5, 0.5) + relative) * radar_size

func _draw() -> void:
	var full := Rect2(Vector2.ZERO, radar_size)
	draw_rect(full, Color(0.015, 0.046, 0.072, 0.94), true)
	draw_rect(full.grow(-3.0), Color(0.12, 0.55, 0.65, 0.32), false, 1.0)
	for fraction in [0.25, 0.5, 0.75]:
		var xx: float = radar_size.x * float(fraction)
		var yy: float = radar_size.y * float(fraction)
		draw_line(Vector2(xx, 3), Vector2(xx, radar_size.y - 3), Color(0.15, 0.49, 0.58, 0.18), 1)
		draw_line(Vector2(3, yy), Vector2(radar_size.x - 3, yy), Color(0.15, 0.49, 0.58, 0.18), 1)
	if show_beacon:
		var beacon := _radar_pos(beacon_world_pos)
		if full.grow(-5.0).has_point(beacon):
			draw_circle(beacon, 4.5, Color(0.21, 1.0, 0.51))
	var center := radar_size * 0.5
	draw_circle(center, 6.0, Color(0.04, 0.20, 0.23))
	draw_circle(center, 4.0, Color(0.21, 1.0, 0.65))
	for actor in get_tree().get_nodes_in_group("enemies"):
		# Avoid loading Player/MutantEnemy classes while compiling this UI
		# component; clean Godot --script runs load the StageDirector autoload
		# after some typed class dependencies, causing circular parse errors.
		if not (actor is Node2D):
			continue
		var enemy := actor as Node2D
		if not is_instance_valid(enemy):
			continue
		var point: Vector2 = _radar_pos(enemy.global_position)
		if not full.grow(-5.0).has_point(point):
			continue
		var elite: bool = String(enemy.get("tier")) in ["boss", "miniboss"]
		draw_circle(point, 4.4 if elite else 2.6, Color(1.0, 0.70, 0.17) if elite else Color(1.0, 0.24, 0.26))
