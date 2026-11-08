extends Control
class_name MiniRadar

@export var map_size: Vector2 = Vector2(2560, 2048)
var radar_size: Vector2 = Vector2(144, 112)

var player_ref: Node2D = null
var beacon_world_pos: Vector2 = Vector2.ZERO
var show_beacon: bool = false

func _ready() -> void:
	custom_minimum_size = radar_size

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, radar_size), Color(0.05, 0.08, 0.12, 0.88), true)
	draw_rect(Rect2(Vector2.ZERO, radar_size), Color(0.18, 0.82, 0.96, 0.92), false, 2.0)

	draw_line(Vector2(radar_size.x * 0.5, 0), Vector2(radar_size.x * 0.5, radar_size.y), Color(0.2, 0.5, 0.65, 0.28), 1.0)
	draw_line(Vector2(0, radar_size.y * 0.5), Vector2(radar_size.x, radar_size.y * 0.5), Color(0.2, 0.5, 0.65, 0.28), 1.0)

	if show_beacon:
		var b_norm: Vector2 = (beacon_world_pos + (map_size * 0.5)) / map_size
		var b_pos: Vector2 = (b_norm * radar_size).clamp(Vector2(4, 4), radar_size - Vector2(4, 4))
		draw_circle(b_pos, 4.2, Color(0.2, 1.0, 0.55, 0.95))

	if is_instance_valid(player_ref):
		var p_norm: Vector2 = (player_ref.global_position + (map_size * 0.5)) / map_size
		var p_pos: Vector2 = (p_norm * radar_size).clamp(Vector2(3, 3), radar_size - Vector2(3, 3))
		draw_circle(p_pos, 3.8, Color(0.35, 0.95, 1.0))

	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var e_node := e as Node2D
		if is_instance_valid(e_node) and not (e_node is Player):
			var e_norm: Vector2 = (e_node.global_position + (map_size * 0.5)) / map_size
			var e_pos: Vector2 = e_norm * radar_size
			if Rect2(Vector2.ZERO, radar_size).has_point(e_pos):
				var is_boss: bool = ("tier" in e_node) and (e_node.get("tier") == "boss" or e_node.get("tier") == "miniboss")
				var dot_r: float = 4.0 if is_boss else 2.2
				var dot_col: Color = Color(1.0, 0.75, 0.15, 1.0) if is_boss else Color(1.0, 0.22, 0.22, 0.9)
				draw_circle(e_pos, dot_r, dot_col)
