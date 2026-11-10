extends Area2D
class_name XPShard

@export var xp_amount: float = 10.0
var target_player: Player = null
var magnet_speed: float = 0.0
var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	if not is_instance_valid(target_player) or not target_player.is_inside_tree() or target_player.current_health <= 0.0:
		target_player = null
		magnet_speed = 0.0
		var players := get_tree().get_nodes_in_group("player")
		for candidate in players:
			if candidate is Player and candidate.is_inside_tree() and candidate.current_health > 0.0:
				var radius_sq: float = candidate.magnet_radius * candidate.magnet_radius
				if global_position.distance_squared_to(candidate.global_position) <= radius_sq:
					target_player = candidate
					break
	if is_instance_valid(target_player):
		magnet_speed = minf(1100.0, magnet_speed + 950.0 * delta)
		var offset := target_player.global_position - global_position
		if offset.length_squared() < 400.0:
			_collect(target_player)
		else:
			global_position += offset.limit_length(magnet_speed * delta)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_collect(body)


func _collect(player: Player) -> void:
	if is_collected or not is_instance_valid(player) or player.current_health <= 0.0:
		return
	is_collected = true
	player.add_xp(xp_amount)
	set_deferred("monitoring", false)
	queue_free()
