extends RefCounted
class_name MSAutoCombatPatterns
## Deterministic target ordering helper for the EXISTING player projectiles.
## Do not call shoot_at_enemy() for every pattern without adjusting cooldown/damage.

static func select_targets(origin: Vector2, enemy_nodes: Array, max_count: int = 1, max_range: float = 600.0) -> Array[Node2D]:
    var valid: Array[Node2D] = []
    for e in enemy_nodes:
        if e is Node2D and is_instance_valid(e):
            if origin.distance_squared_to(e.global_position) <= max_range * max_range:
                valid.append(e)
    valid.sort_custom(func(a: Node2D, b: Node2D) -> bool:
        return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
    )
    return valid.slice(0, mini(max_count, valid.size()))

static func clustered_center(origin: Vector2, enemy_nodes: Array, radius: float = 180.0, max_range: float = 600.0) -> Vector2:
    var targets := select_targets(origin, enemy_nodes, 24, max_range)
    if targets.is_empty():
        return origin
    var best: Node2D = targets[0]
    var score := -1
    for candidate in targets:
        var count := 0
        for other in targets:
            if candidate.global_position.distance_squared_to(other.global_position) < radius * radius:
                count += 1
        if count > score:
            score = count
            best = candidate
    return best.global_position
