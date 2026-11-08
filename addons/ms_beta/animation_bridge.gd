extends Node
class_name MSAnimationBridge
## Optional Animation Controller. Requires real individual frames from artist / atlas.
## Never infer 'real animation' from a single static hero illustration.
## Attach to Player, bind Sprite2D; disable old transform-based animation before enabling.

@export var idle_frames: Array[Texture2D] = []
@export var walk_frames: Array[Texture2D] = []
@export var shoot_frames: Array[Texture2D] = []
@export var death_frames: Array[Texture2D] = []
@export_range(4.0, 24.0, 0.5) var walk_fps: float = 10.0
@export_range(4.0, 24.0, 0.5) var shoot_fps: float = 12.0
@export var deadzone: float = 8.0

var controlled_sprite: Sprite2D
var subject: CharacterBody2D
var _seconds: float = 0.0
var _is_dead: bool = false
var _shoot_remaining: float = 0.0

func bind_actor(actor: CharacterBody2D, sprite: Sprite2D) -> void:
    subject = actor
    controlled_sprite = sprite

func notify_shot() -> void:
    if not shoot_frames.is_empty():
        _shoot_remaining = float(shoot_frames.size()) / shoot_fps
        _seconds = 0.0

func notify_death() -> void:
    _is_dead = true
    _seconds = 0.0

func _process(delta: float) -> void:
    if not is_instance_valid(subject) or not is_instance_valid(controlled_sprite):
        return
    _seconds += delta
    if _shoot_remaining > 0.0:
        _shoot_remaining = maxf(0.0, _shoot_remaining - delta)
    var frames: Array[Texture2D] = idle_frames
    var fps := walk_fps
    if _is_dead and not death_frames.is_empty():
        frames = death_frames
    elif _shoot_remaining > 0.0 and not shoot_frames.is_empty():
        frames = shoot_frames
        fps = shoot_fps
    elif subject.velocity.length() > deadzone and not walk_frames.is_empty():
        frames = walk_frames
    if frames.is_empty():
        return # Preserve existing image; no pretend frames
    var idx := mini(int(_seconds * fps), frames.size() - 1) if _is_dead else int(_seconds * fps) % frames.size()
    controlled_sprite.texture = frames[idx]
