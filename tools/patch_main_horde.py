# -*- coding: utf-8 -*-
import os

path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\main.gd"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add wave_director property
old_prop = "var hazard_timer: float = 0.0\n"
new_prop = "var hazard_timer: float = 0.0\nvar wave_director: MSWaveDirector = null\n"
if old_prop in content and "var wave_director:" not in content:
    content = content.replace(old_prop, new_prop, 1)

# 2. In _ready(), instantiate wave_director
old_ready = "\tcurrent_stage_num = StageDirector.current_stage\n\t_build_layered_arena(current_stage_num)"
new_ready = "\twave_director = MSWaveDirector.new()\n\twave_director.name = \"WaveDirector\"\n\tadd_child(wave_director)\n\twave_director.bind_context(self, characters_layer, effects_layer)\n\n\tcurrent_stage_num = StageDirector.current_stage\n\t_build_layered_arena(current_stage_num)"
if old_ready in content and "wave_director = MSWaveDirector.new()" not in content:
    content = content.replace(old_ready, new_ready, 1)

# 3. Replace _build_layered_arena tile generation with 55/20/15/10 ratio and rich tiles
arena_old_start = "\tvar cols := 26\n\tvar rows := 22"
arena_old_end = "\t\t\tground_layer.add_child(tile_spr)"
if arena_old_start in content:
    idx1 = content.find(arena_old_start)
    idx2 = content.find(arena_old_end, idx1)
    if idx2 != -1:
        idx2 += len(arena_old_end)
        old_arena_block = content[idx1:idx2]
        new_arena_block = """\tvar base_tiles := ["concrete_clean", "dark_slab", "floor_dark", "floor_grid"]
\tvar cracked_tiles := ["cracked_concrete", "concrete_fracture", "concrete_rubble", "broken_stone", "floor_cracks"]
\tvar grate_tiles := ["metal_grate", "steel_grate", "rusted_plate", "rust_plates", "bolted_tile"]
\tvar hazard_tiles := ["warning_stripes", "acid_pit_glow", "toxic_pool", "scorched_floor", "reactor_tile"]

\tif biome_id == "cryo_lab":
\t\tbase_tiles = ["cryo_tile", "concrete_clean", "lab_panel_clean"]
\t\tcracked_tiles = ["broken_stone", "floor_cracks"]
\t\tgrate_tiles = ["bolted_tile", "metal_grate"]
\t\thazard_tiles = ["cryo_tile", "warning_stripes"]
\telif biome_id == "toxic_sewers":
\t\tbase_tiles = ["mossy_concrete", "dark_slab"]
\t\tcracked_tiles = ["cracked_concrete", "concrete_fracture"]
\t\tgrate_tiles = ["rusted_plate", "metal_grate"]
\t\thazard_tiles = ["acid_pit_glow", "toxic_pool"]

\tvar cols := 26
\tvar rows := 22
\tvar start_x := -int(cols / 2) * TILE_SIZE
\tvar start_y := -int(rows / 2) * TILE_SIZE

\tfor r in range(rows):
\t\tfor c in range(cols):
\t\t\tvar tile_name: String
\t\t\tvar is_edge := (r == 0 or r == rows - 1 or c == 0 or c == cols - 1)
\t\t\tvar is_near_edge := (r == 1 or r == rows - 2 or c == 1 or c == cols - 2)

\t\t\tif is_edge:
\t\t\t\ttile_name = "warning_stripes" if (r + c) % 3 == 0 else "rusted_plate"
\t\t\telif is_near_edge and (r + c) % 4 == 0:
\t\t\t\ttile_name = "warning_stripes"
\t\t\telse:
\t\t\t\tvar h := absi((r * 73 + c * 47 + stage_num * 101 + (r ^ c) * 19)) % 100
\t\t\t\tif h < 55:
\t\t\t\t\ttile_name = base_tiles[(r * 3 + c * 5) % base_tiles.size()]
\t\t\t\telif h < 75:
\t\t\t\t\ttile_name = cracked_tiles[(r * 7 + c * 11) % cracked_tiles.size()]
\t\t\t\telif h < 90:
\t\t\t\t\ttile_name = grate_tiles[(r * 13 + c * 3) % grate_tiles.size()]
\t\t\t\telse:
\t\t\t\t\ttile_name = hazard_tiles[(r * 17 + c * 7) % hazard_tiles.size()]

\t\t\tvar tile_spr := Sprite2D.new()
\t\t\ttile_spr.texture = AssetRegistry.get_tex("res://assets/mutantsurvivor_ch01/tiles/" + tile_name + ".png")
\t\t\ttile_spr.centered = false
\t\t\ttile_spr.modulate = tint
\t\t\ttile_spr.position = Vector2(start_x + c * TILE_SIZE, start_y + r * TILE_SIZE)
\t\t\tground_layer.add_child(tile_spr)"""
        content = content[:idx1] + new_arena_block + content[idx2:]

# 4. In start_wave, call wave_director.start_wave
start_wave_old = """\tvar initial_count := 4 + mini(6, current_wave_num)
\tfor i in range(initial_count):
\t\tspawn_wave_enemy()"""
start_wave_new = """\tif is_instance_valid(wave_director):
\t\twave_director.start_wave(current_wave_num, WAVE_DURATION_SEC)
\telse:
\t\tvar initial_count := 4 + mini(6, current_wave_num)
\t\tfor i in range(initial_count):
\t\t\tspawn_wave_enemy()"""
if start_wave_old in content:
    content = content.replace(start_wave_old, start_wave_new, 1)

# 5. In _process, call wave_director.process_wave
proc_spawn_old = """\tvar diff := StageDirector.get_difficulty_profile()
\tvar spawn_rate_mult := float(diff.get("spawn_rate", 1.0))
\tvar interval := maxf(0.32, (1.25 - float(current_wave_num) * 0.065) / maxf(0.5, spawn_rate_mult))
\tvar max_active := 16 + current_wave_num * 4

\tspawn_timer += delta
\tif spawn_timer >= interval:
\t\tspawn_timer = 0.0
\t\tvar enemies_count := get_tree().get_nodes_in_group("enemies").size()
\t\tif enemies_count < max_active:
\t\t\tspawn_wave_enemy()"""

proc_spawn_new = """\tif is_instance_valid(wave_director):
\t\twave_director.process_wave(delta, player, current_stage_num, total_run_elapsed)
\telse:
\t\tvar diff := StageDirector.get_difficulty_profile()
\t\tvar spawn_rate_mult := float(diff.get("spawn_rate", 1.0))
\t\tvar interval := maxf(0.32, (1.25 - float(current_wave_num) * 0.065) / maxf(0.5, spawn_rate_mult))
\t\tvar max_active := 16 + current_wave_num * 4

\t\tspawn_timer += delta
\t\tif spawn_timer >= interval:
\t\t\tspawn_timer = 0.0
\t\t\tvar enemies_count := get_tree().get_nodes_in_group("enemies").size()
\t\t\tif enemies_count < max_active:
\t\t\t\tspawn_wave_enemy()"""

if proc_spawn_old in content:
    content = content.replace(proc_spawn_old, proc_spawn_new, 1)

# 6. Wave banner formatting
banner_anchor = "func _update_wave_banner() -> void:\n"
if banner_anchor in content:
    b_idx1 = content.find(banner_anchor)
    b_idx2 = content.find("\nfunc ", b_idx1)
    if b_idx2 != -1:
        new_banner_func = """func _update_wave_banner() -> void:
\tvar mins := int(wave_time_left / 60.0)
\tvar secs := int(wave_time_left) % 60
\tif current_wave_num == 5:
\t\twave_label.text = "FALA 5/10 — ELITA! • %02d:%02d" % [mins, secs]
\telif current_wave_num == 10:
\t\twave_label.text = "FALA 10/10 — BOSS! • %02d:%02d" % [mins, secs]
\telse:
\t\twave_label.text = "FALA %d / %d • %02d:%02d" % [current_wave_num, max_waves_in_stage, mins, secs]
"""
        content = content[:b_idx1] + new_banner_func + content[b_idx2:]

# 7. NPC comms auto-hide timer to 3.2
content = content.replace("npc_hide_timer = 5.5", "npc_hide_timer = 3.2")

# 8. Clean recycling on victory & completion
if "wave_director.recycle_all_enemies()" not in content:
    content = content.replace("StageDirector.play_sfx(\"victory\")", "if is_instance_valid(wave_director):\n\t\twave_director.recycle_all_enemies()\n\tStageDirector.play_sfx(\"victory\")")

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("SUCCESSFULLY APPLIED HORDE & ARENA UPDATES TO main.gd")
