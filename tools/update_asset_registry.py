import os, sys

path = 'C:/Users/patry/Desktop/2026/MutantSurvivor/scripts/asset_registry.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '\t"hazard_barrel": {"path": CH01_ROOT + "props/hazard_barrel.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_STATIC_RGBA"}\n}'

new_entries = '''\t"hazard_barrel": {"path": CH01_ROOT + "props/hazard_barrel.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_STATIC_RGBA"},
\t"prop_wreck_sedan": {"path": "res://assets/environment/props/prop_wreck_sedan.png", "solid": true, "collision": Vector2(120, 60), "offset": Vector2(0, 15), "status": "HD_PROP_V2"},
\t"prop_wreck_suv": {"path": "res://assets/environment/props/prop_wreck_suv.png", "solid": true, "collision": Vector2(130, 65), "offset": Vector2(0, 15), "status": "HD_PROP_V2"},
\t"prop_wreck_pickup": {"path": "res://assets/environment/props/prop_wreck_pickup.png", "solid": true, "collision": Vector2(125, 60), "offset": Vector2(0, 15), "status": "HD_PROP_V2"},
\t"prop_wreck_tanker": {"path": "res://assets/environment/props/prop_wreck_tanker.png", "solid": true, "collision": Vector2(160, 75), "offset": Vector2(0, 20), "status": "HD_PROP_V2"},
\t"prop_barrier_hazard": {"path": "res://assets/environment/props/prop_barrier_hazard.png", "solid": true, "collision": Vector2(90, 40), "offset": Vector2(0, 12), "status": "HD_PROP_V2"},
\t"prop_sandbags": {"path": "res://assets/environment/props/prop_sandbags.png", "solid": true, "collision": Vector2(90, 36), "offset": Vector2(0, 10), "status": "HD_PROP_V2"},
\t"prop_concrete_block": {"path": "res://assets/environment/props/prop_concrete_block.png", "solid": true, "collision": Vector2(80, 44), "offset": Vector2(0, 12), "status": "HD_PROP_V2"},
\t"prop_crate_military": {"path": "res://assets/environment/props/prop_crate_military.png", "solid": true, "collision": Vector2(64, 48), "offset": Vector2(0, 12), "status": "HD_PROP_V2"},
\t"prop_barrel_oil": {"path": "res://assets/environment/props/prop_barrel_oil.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_PROP_V2"},
\t"prop_barrel_toxic": {"path": "res://assets/environment/props/prop_barrel_toxic.png", "solid": true, "explosive": true, "collision": Vector2(44, 44), "offset": Vector2(0, 10), "status": "HD_PROP_V2"},
\t"prop_pipes_industrial": {"path": "res://assets/environment/props/prop_pipes_industrial.png", "solid": true, "collision": Vector2(85, 48), "offset": Vector2(0, 14), "status": "HD_PROP_V2"},
\t"prop_tank_boiler": {"path": "res://assets/environment/props/prop_tank_boiler.png", "solid": true, "collision": Vector2(100, 64), "offset": Vector2(0, 18), "status": "HD_PROP_V2"},
\t"prop_flag_biohazard_red": {"path": "res://assets/environment/props/prop_flag_biohazard_red.png", "solid": false, "collision": Vector2.ZERO, "offset": Vector2.ZERO, "status": "HD_PROP_V2"},
\t"prop_flag_biohazard_yellow": {"path": "res://assets/environment/props/prop_flag_biohazard_yellow.png", "solid": false, "collision": Vector2.ZERO, "offset": Vector2.ZERO, "status": "HD_PROP_V2"}
}'''

if 'prop_wreck_sedan' not in content:
    assert target in content, "target not found"
    content = content.replace(target, new_entries, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Successfully added all 14 props to PROP_ASSETS in asset_registry.gd!")
else:
    print("Props already in PROP_ASSETS.")
