extends Area2D
class_name XPShard

@export var xp_amount: float = 10.0
var target_player: Player = null
var magnet_speed: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			var dist = global_position.distance_to(p.global_position)
			if dist < p.magnet_radius:
				target_player = p
	else:
		magnet_speed += 950.0 * delta
		var dir = (target_player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_xp(xp_amount)
		queue_free()
