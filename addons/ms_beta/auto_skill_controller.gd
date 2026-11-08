extends Node
class_name MSAutoSkillController
## Add as child of Player. Bind player from Main after instancing.
## Existing Player already auto-shoots. This module only automates unlocked skills.
## IMPORTANT: This is a new optional component, not a replacement for player.gd.

@export var enable_grenade: bool = true
@export var enable_vortex: bool = true
@export var min_enemy_count_for_vortex: int = 3
@export var activation_radius: float = 510.0
@export var scan_interval_sec: float = 0.18

var player: Node2D
var grenade_unlocked: bool = false
var vortex_unlocked: bool = false
var _scan_remaining: float = 0.0

func bind_to_player(p: Node2D) -> void:
    player = p

func set_unlocks(grenade: bool, vortex: bool) -> void:
    grenade_unlocked = grenade
    vortex_unlocked = vortex

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    if get_tree().paused or not player.is_inside_tree():
        return
    if player.get("current_health") != null and float(player.get("current_health")) <= 0.0:
        return
    _scan_remaining -= delta
    if _scan_remaining > 0.0:
        return
    _scan_remaining = scan_interval_sec
    var nearby := 0
    for unit in get_tree().get_nodes_in_group("enemies"):
        if unit is Node2D and is_instance_valid(unit):
            if player.global_position.distance_squared_to(unit.global_position) <= activation_radius * activation_radius:
                nearby += 1
    if nearby == 0:
        return
    if grenade_unlocked and enable_grenade and player.has_method("use_plasma_grenade"):
        player.call("use_plasma_grenade")  # Player enforces its own cooldown
    if vortex_unlocked and enable_vortex and nearby >= min_enemy_count_for_vortex and player.has_method("use_antigravity_vortex"):
        player.call("use_antigravity_vortex")
