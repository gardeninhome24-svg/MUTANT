# -*- coding: utf-8 -*-
path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\mutant_enemy.gd"
with open(path, "r", encoding="utf-8") as f:
    c = f.read()

# 1. Add pool properties
old_prop = "var is_dying: bool = false\n"
new_prop = """var is_dying: bool = false
var is_pooled: bool = false
var has_dropped_loot: bool = false
var wave_director_ref: Node = null
"""
if "var is_pooled: bool = false" not in c and old_prop in c:
    c = c.replace(old_prop, new_prop, 1)

# 2. Add reset_for_respawn method
reset_code = """func reset_for_respawn(p_enemy_id: String, p_tier: String, stage_num: int, elapsed_sec: float, spawn_pos: Vector2) -> void:
\tis_dying = false
\thas_dropped_loot = false
\tglobal_position = spawn_pos
\tvisible = true
\tset_physics_process(true)
\tvelocity = Vector2.ZERO
\tanim_timer = 0.0
\tspecial_timer = 2.0
\tranged_spit_timer = 2.6
\tis_telegraphing = false
\ttelegraph_elapsed = 0.0
\tboss_phase = 1

\tfor child in get_children():
\t\tif child is CollisionShape2D:
\t\t\tchild.set_deferred("disabled", false)

\tvar players := get_tree().get_nodes_in_group("player")
\tif players.size() > 0:
\t\ttarget = players[0]

\tif sprite:
\t\tsprite.modulate = Color.WHITE

\tsetup_enemy_archetype(p_enemy_id, p_tier, stage_num, elapsed_sec)
\tqueue_redraw()

"""

if "func reset_for_respawn" not in c:
    c = c.replace("func setup_enemy_archetype", reset_code + "func setup_enemy_archetype", 1)

# 3. Update die() method
die_old_start = "func die() -> void:\n\tif is_dying:\n\t\treturn\n\tis_dying = true\n"
die_idx = c.find(die_old_start)
if die_idx != -1:
    # Find the end of die()
    qf_idx = c.find("\tqueue_free()", die_idx)
    if qf_idx != -1:
        qf_idx += len("\tqueue_free()")
        new_die = """func die() -> void:
\tif is_dying:
\t\treturn
\tis_dying = true

\tif not has_dropped_loot:
\t\thas_dropped_loot = true
\t\tStageDirector.record_daily_mission_progress("kill_mutants", 1)
\t\temit_signal("enemy_died", self)
\t\tvar shard := XP_SHARD_SCENE.instantiate()
\t\tshard.global_position = global_position
\t\tshard.xp_amount = xp_value
\t\tget_parent().call_deferred("add_child", shard)

\t# Animacja śmierci wroga (rozbłysk toksyczny)
\tvar parent_layer: Node = effects_layer if is_instance_valid(effects_layer) else get_parent()
\tif is_instance_valid(parent_layer):
\t\tvar death_fx := Sprite2D.new()
\t\tdeath_fx.texture = TOXIC_SPLASH_TEX
\t\tdeath_fx.material = PowerEffects.get_additive_mat()
\t\tdeath_fx.global_position = global_position + Vector2(0, -18)
\t\tdeath_fx.scale = Vector2(0.55, 0.55)
\t\tparent_layer.add_child(death_fx)
\t\tvar tw := death_fx.create_tween()
\t\ttw.tween_property(death_fx, "scale", Vector2(0.95, 0.95), 0.22)
\t\ttw.parallel().tween_property(death_fx, "modulate:a", 0.0, 0.22)
\t\ttw.tween_callback(death_fx.queue_free)

\tif is_pooled and is_instance_valid(wave_director_ref):
\t\tfor child in get_children():
\t\t\tif child is CollisionShape2D:
\t\t\t\tchild.set_deferred("disabled", true)
\t\tvisible = false
\t\tset_physics_process(false)
\t\tvelocity = Vector2.ZERO
\t\twave_director_ref.recycle_enemy(self)
\telse:
\t\tqueue_free()"""
        c = c[:die_idx] + new_die + c[qf_idx:]

with open(path, "w", encoding="utf-8") as f:
    f.write(c)
print("SUCCESSFULLY PATCHED mutant_enemy.gd FOR BULLETPROOF OBJECT POOLING!")
