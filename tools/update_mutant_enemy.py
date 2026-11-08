import os, sys

path = 'C:/Users/patry/Desktop/2026/MutantSurvivor/scripts/mutant_enemy.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add variable declarations
var_marker = 'var is_animated_sheet: bool = false\n'
new_vars = ('var is_animated_sheet: bool = false\n'
            'var walk_frames: Array[Texture2D] = []\n'
            'var attack_frames: Array[Texture2D] = []\n'
            'var death_frames: Array[Texture2D] = []\n')

if 'var walk_frames:' not in content:
    assert var_marker in content, "var_marker not found"
    content = content.replace(var_marker, new_vars, 1)

# 2. In setup_enemy_archetype, assign frames from vis_info
setup_marker = 'base_scale = vis_info.get("base_scale", Vector2(0.56, 0.56))\n'
setup_add = ('base_scale = vis_info.get("base_scale", Vector2(0.56, 0.56))\n'
             '\t\twalk_frames.clear()\n'
             '\t\tfor f in vis_info.get("walk_frames", []):\n'
             '\t\t\tif f is Texture2D: walk_frames.append(f)\n'
             '\t\tattack_frames.clear()\n'
             '\t\tfor f in vis_info.get("attack_frames", []):\n'
             '\t\t\tif f is Texture2D: attack_frames.append(f)\n'
             '\t\tdeath_frames.clear()\n'
             '\t\tfor f in vis_info.get("death_frames", []):\n'
             '\t\t\tif f is Texture2D: death_frames.append(f)\n')

if 'walk_frames.clear()' not in content:
    assert setup_marker in content, "setup_marker not found"
    content = content.replace(setup_marker, setup_add, 1)

# 3. In _physics_process, animate with attack_frames and walk_frames
anim_old = '''\tanim_timer += delta
\tif is_animated_sheet and sprite.hframes > 1:
\t\tsprite.frame = int(anim_timer * sheet_fps) % sprite.hframes
\t\tsprite.scale = base_scale
\telse:
\t\t# Subtelny ruch kroku dla tymczasowych statycznych grafik referencyjnych
\t\tvar step := sin(anim_timer * 12.0) * 0.032
\t\tsprite.scale = Vector2(base_scale.x + step, base_scale.y - step)'''

anim_new = '''\tanim_timer += delta
\tif is_telegraphing and not attack_frames.is_empty():
\t\tvar af_idx := int(anim_timer * sheet_fps) % attack_frames.size()
\t\tsprite.texture = attack_frames[af_idx]
\t\tsprite.scale = base_scale
\telif not walk_frames.is_empty():
\t\tvar wf_idx := int(anim_timer * sheet_fps) % walk_frames.size()
\t\tsprite.texture = walk_frames[wf_idx]
\t\tsprite.scale = base_scale
\telif is_animated_sheet and sprite.hframes > 1:
\t\tsprite.frame = int(anim_timer * sheet_fps) % sprite.hframes
\t\tsprite.scale = base_scale
\telse:
\t\t# Subtelny ruch kroku dla tymczasowych statycznych grafik referencyjnych
\t\tvar step := sin(anim_timer * 12.0) * 0.032
\t\tsprite.scale = Vector2(base_scale.x + step, base_scale.y - step)'''

if 'elif not walk_frames.is_empty():' not in content:
    assert anim_old in content, "anim_old not found"
    content = content.replace(anim_old, anim_new, 1)

# 4. In die(), set death frame if available
die_old = '''func die() -> void:
\tif is_dying:
\t\treturn
\tis_dying = true'''

die_new = '''func die() -> void:
\tif is_dying:
\t\treturn
\tis_dying = true
\tif not death_frames.is_empty() and sprite:
\t\tsprite.texture = death_frames[0]'''

if 'sprite.texture = death_frames[0]' not in content:
    assert die_old in content, "die_old not found"
    content = content.replace(die_old, die_new, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Successfully updated mutant_enemy.gd with animated walk, attack, and death frame cycles!")
