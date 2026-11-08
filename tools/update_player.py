import os, sys

path = 'C:/Users/patry/Desktop/2026/MutantSurvivor/scripts/player.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add variable declarations
var_marker = 'var soldier_shoot_frames: Array[Texture2D] = []\n'
new_vars = ('var soldier_shoot_frames: Array[Texture2D] = []\n'
            'var idle_frames: Array[Texture2D] = []\n'
            'var hurt_frames: Array[Texture2D] = []\n'
            'var death_frames: Array[Texture2D] = []\n')

if 'var idle_frames:' not in content:
    assert var_marker in content, "var_marker not found"
    content = content.replace(var_marker, new_vars, 1)

# 2. In apply_class_and_talents, load idle, hurt, death frames
load_marker = '\t\t\tuse_soldier_frame_anim = has_frame_anim\n'
load_add = ('\t\t\tuse_soldier_frame_anim = has_frame_anim\n'
            '\t\t\tidle_frames.clear()\n'
            '\t\t\thurt_frames.clear()\n'
            '\t\t\tdeath_frames.clear()\n'
            '\t\t\tfor fi in range(1, 5):\n'
            '\t\t\t\tvar it := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_idle_%d.png" % [cls_id, fi])\n'
            '\t\t\t\tif it: idle_frames.append(it)\n'
            '\t\t\tfor fi in range(1, 4):\n'
            '\t\t\t\tvar ht := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_hurt_%d.png" % [cls_id, fi])\n'
            '\t\t\t\tif ht: hurt_frames.append(ht)\n'
            '\t\t\tfor fi in range(1, 7):\n'
            '\t\t\t\tvar dt := AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/characters/%s_death_%d.png" % [cls_id, fi])\n'
            '\t\t\t\tif dt: death_frames.append(dt)\n')

if 'idle_frames.clear()' not in content:
    assert load_marker in content, "load_marker not found"
    content = content.replace(load_marker, load_add, 1)

# 3. In idle branch, cycle idle frames if present
idle_old = '''\t\tif has_frame_anim and shoot_anim_timer <= 0.0 and base_idle_tex != null:
\t\t\tsprite.texture = base_idle_tex'''

idle_new = '''\t\tif not idle_frames.is_empty() and shoot_anim_timer <= 0.0:
\t\t\tvar i_idx := int(anim_timer * 1.5) % idle_frames.size()
\t\t\tsprite.texture = idle_frames[i_idx]
\t\telif has_frame_anim and shoot_anim_timer <= 0.0 and base_idle_tex != null:
\t\t\tsprite.texture = base_idle_tex'''

if 'if not idle_frames.is_empty() and shoot_anim_timer <= 0.0:' not in content:
    assert idle_old in content, "idle_old not found"
    content = content.replace(idle_old, idle_new, 1)

# 4. In take_damage, flash hurt frame and death frame
dmg_old = '''\tvar tween := create_tween()
\tsprite.modulate = Color(2.6, 0.35, 0.35, 1.0)
\ttween.tween_property(sprite, "modulate", base_skin_tint, 0.15)

\tif current_health <= 0.0:
\t\temit_signal("player_died")'''

dmg_new = '''\tvar tween := create_tween()
\tsprite.modulate = Color(2.6, 0.35, 0.35, 1.0)
\tif not hurt_frames.is_empty():
\t\tsprite.texture = hurt_frames[0]
\ttween.tween_property(sprite, "modulate", base_skin_tint, 0.15)

\tif current_health <= 0.0:
\t\tif not death_frames.is_empty():
\t\t\tsprite.texture = death_frames[0]
\t\temit_signal("player_died")'''

if 'if not hurt_frames.is_empty():' not in content:
    assert dmg_old in content, "dmg_old not found"
    content = content.replace(dmg_old, dmg_new, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Successfully updated player.gd with idle, hurt, and death animation support!")
