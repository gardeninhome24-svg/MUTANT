extends Label
class_name DamageNumber

func setup(amount: float, is_crit: bool, start_pos: Vector2) -> void:
	global_position = start_pos + Vector2(randf_range(-15, 15), -25)
	text = str(int(amount))
	
	if is_crit:
		text = "CRIT! " + text
		modulate = Color(1.0, 0.85, 0.2, 1.0)
		scale = Vector2(1.3, 1.3)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		scale = Vector2(1.0, 1.0)
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y - 35.0, 0.55)
	tween.tween_property(self, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(queue_free)
