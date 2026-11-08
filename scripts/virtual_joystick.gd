extends Control
class_name MobileVirtualJoystick

@export var max_drag_radius: float = 70.0

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Knob

var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO

signal direction_changed(dir: Vector2)

func _ready() -> void:
	reset_knob()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var local_pos = event.position - global_position
			if local_pos.length() <= max_drag_radius * 1.5:
				touch_index = event.index
				update_joystick(event.position)
		elif event.index == touch_index:
			touch_index = -1
			reset_knob()
			
	elif event is InputEventScreenDrag and event.index == touch_index:
		update_joystick(event.position)

func update_joystick(touch_pos: Vector2) -> void:
	var center = global_position + Vector2(max_drag_radius, max_drag_radius)
	var diff = touch_pos - center
	var dist = diff.length()
	
	if dist > max_drag_radius:
		diff = diff.normalized() * max_drag_radius
		
	knob.position = (center - global_position) + diff - (knob.size / 2.0)
	output_vector = diff / max_drag_radius
	emit_signal("direction_changed", output_vector)

func reset_knob() -> void:
	var center = Vector2(max_drag_radius, max_drag_radius)
	knob.position = center - (knob.size / 2.0)
	output_vector = Vector2.ZERO
	emit_signal("direction_changed", Vector2.ZERO)
