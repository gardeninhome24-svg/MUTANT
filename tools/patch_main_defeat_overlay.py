# -*- coding: utf-8 -*-
path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\main.gd"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Preload defeat overlay scene
preload_anchor = "const MSWaveDirector := preload(\"res://addons/ms_beta/wave_director.gd\")\n"
new_preload = preload_anchor + "const DEFEAT_OVERLAY_SCENE := preload(\"res://addons/ms_balance/ui/defeat_overlay.tscn\")\n"
if "const DEFEAT_OVERLAY_SCENE" not in content and preload_anchor in content:
    content = content.replace(preload_anchor, new_preload, 1)

# Property declaration
prop_anchor = "var death_summary_lbl: Label = null\n"
new_prop = prop_anchor + "var defeat_overlay_inst: Control = null\n"
if "var defeat_overlay_inst:" not in content and prop_anchor in content:
    content = content.replace(prop_anchor, new_prop, 1)

# 2. In _setup_extended_hud_and_profile, instantiate and wire defeat_overlay
inst_code = """\t# 8. Nakładka Porażki z Balance Addon (MSDefeatOverlay)
\tdefeat_overlay_inst = DEFEAT_OVERLAY_SCENE.instantiate()
\tdefeat_overlay_inst.visible = false
\tdefeat_overlay_inst.request_revive_premium.connect(_on_revive_premium_pressed)
\tdefeat_overlay_inst.request_revive_ad.connect(_on_revive_ad_pressed)
\tdefeat_overlay_inst.request_retry.connect(restart_current_stage)
\tdefeat_overlay_inst.request_return_to_hub.connect(_return_to_main_menu)
\thud_root.add_child(defeat_overlay_inst)
"""

hud_anchor = "\thud_root.add_child(npc_journal_modal)\n"
if "defeat_overlay_inst = DEFEAT_OVERLAY_SCENE.instantiate()" not in content and hud_anchor in content:
    content = content.replace(hud_anchor, hud_anchor + "\n" + inst_code, 1)

# 3. In _on_player_died, configure and show defeat_overlay_inst
old_died_end = "\tget_tree().paused = true\n\tdeath_panel.visible = true"
new_died_end = """\tget_tree().paused = true
\tdeath_panel.visible = true

\tif is_instance_valid(defeat_overlay_inst):
\t\tvar cfg_data := {
\t\t\t"title": "MISJA NIEUDANA",
\t\t\t"wave": current_wave_num,
\t\t\t"kills": enemies_killed_in_run,
\t\t\t"time_seconds": int(total_run_elapsed),
\t\t\t"reason": "Etap %03d: Ulepsz wyposażenie lub spróbuj innej strategii." % current_stage_num,
\t\t\t"already_revived": has_used_revive,
\t\t\t"gems": StageDirector.dark_matter_gems,
\t\t\t"ad_available": StageDirector.is_online_mode
\t\t}
\t\tdefeat_overlay_inst.call("configure", cfg_data)
\t\tvar bdrop := defeat_overlay_inst.get_node_or_null("Backdrop") as TextureRect
\t\tif is_instance_valid(bdrop):
\t\t\tif StageDirector.is_portrait_mode():
\t\t\t\tbdrop.texture = load("res://addons/ms_balance/assets/defeat_background_portrait.png")
\t\t\telse:
\t\t\t\tbdrop.texture = load("res://addons/ms_balance/assets/defeat_background_landscape.png")
\t\tdefeat_overlay_inst.visible = true"""

if old_died_end in content and "defeat_overlay_inst.call(\"configure\"" not in content:
    content = content.replace(old_died_end, new_died_end, 1)

# 4. Hide defeat_overlay_inst on revive / victory / restart
content = content.replace(
    "death_panel.visible = false\n\tget_tree().paused = false\n\tplayer.revive(0.65)",
    "death_panel.visible = false\n\tif is_instance_valid(defeat_overlay_inst): defeat_overlay_inst.visible = false\n\tget_tree().paused = false\n\tplayer.revive(0.65)"
)

content = content.replace(
    "death_panel.visible = false\n\t\tget_tree().paused = false\n\t\tplayer.revive(1.0)",
    "death_panel.visible = false\n\t\tif is_instance_valid(defeat_overlay_inst): defeat_overlay_inst.visible = false\n\t\tget_tree().paused = false\n\t\tplayer.revive(1.0)"
)

content = content.replace(
    "win_panel.visible = false\n\tdeath_panel.visible = false\n\tget_tree().paused = false\n\tget_tree().reload_current_scene()",
    "win_panel.visible = false\n\tdeath_panel.visible = false\n\tif is_instance_valid(defeat_overlay_inst): defeat_overlay_inst.visible = false\n\tget_tree().paused = false\n\tget_tree().reload_current_scene()"
)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("SUCCESSFULLY WIRED MSDefeatOverlay INTO main.gd!")
