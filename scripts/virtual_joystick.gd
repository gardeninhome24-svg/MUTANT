extends Control
class_name MobileVirtualJoystick

# Radius scales down with the actual on-screen control; designed for portrait phones.
@export var max_drag_radius: float = 70.0
@export_range(0.0, 0.4, 0.01) var deadzone: float = 0.12

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Knob

var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO

signal direction_changed(dir: Vector2)

func _ready() -> void:
	# Decorative elements must not steal interaction from the movement surface.
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset_knob()
	resized.connect(reset_knob)

func _notification(what: int) -> void:
	# A touch can be interrupted by pause, an Android app switch or hidden HUD.
	# Never leave the player moving after the joystick disappears.
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_EXIT_TREE:
		if not is_visible_in_tree() or what == NOTIFICATION_EXIT_TREE:
			touch_index = -1
			if is_node_ready():
				reset_knob()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		# Convert screen coordinates into local control space. The old code
		# measured touch pickup from the upper-left corner, not the center.
		var local_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed:
			if touch_index != -1:
				return
			var center := size * 0.5
			# Allow a little space around the visible base for comfortable thumbs.
			if local_pos.distance_to(center) <= _radius() * 1.65:
				touch_index = event.index
				update_joystick(event.position)
		elif event.index == touch_index:
			touch_index = -1
			reset_knob()
	elif event is InputEventScreenDrag and event.index == touch_index:
		update_joystick(event.position)

func _radius() -> float:
	return maxf(8.0, minf(max_drag_radius, minf(size.x, size.y) * 0.5 - 8.0))

func update_joystick(touch_pos: Vector2) -> void:
	var local_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * touch_pos
	var center := size * 0.5
	var radius := _radius()
	var diff := (local_pos - center).limit_length(radius)
	knob.position = center + diff - knob.size * 0.5
	var strength := diff.length() / radius
	var adjusted := clampf((strength - deadzone) / maxf(0.01, 1.0 - deadzone), 0.0, 1.0)
	output_vector = diff.normalized() * adjusted if adjusted > 0.0 else Vector2.ZERO
	direction_changed.emit(output_vector)

func cancel_touch() -> void:
	# Explicitly release finger ownership when a modal/pause opens.
	touch_index = -1
	reset_knob()

func reset_knob() -> void:
	if not is_node_ready():
		return
	knob.position = size * 0.5 - knob.size * 0.5
	output_vector = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
