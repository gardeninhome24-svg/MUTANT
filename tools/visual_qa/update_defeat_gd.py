import os

gd_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\ui\defeat_overlay.gd"
with open(gd_path, "r", encoding="utf-8") as f:
    code = f.read()

old_logic = """\tvar wave_str := "%d/10" % waves
\tvar time_str := "%02d:%02d" % [int(time_sec / 60), time_sec % 60]
\tvar kills_str := "%d" % kills

\tif is_instance_valid(wave_val_lbl): wave_val_lbl.text = wave_str
\tif is_instance_valid(time_val_lbl): time_val_lbl.text = time_str
\tif is_instance_valid(kills_val_lbl): kills_val_lbl.text = kills_str"""

new_logic = """\tvar wave_str := "%d/10" % waves
\tvar time_str := "%02d:%02d" % [int(time_sec / 60), time_sec % 60]
\tvar kills_str := "%d" % kills

\tvar is_custom := (waves != 5 or time_sec != 272 or kills != 142)
\tif is_instance_valid(wave_val_lbl):
\t\twave_val_lbl.visible = is_custom
\t\twave_val_lbl.text = wave_str
\tif is_instance_valid(time_val_lbl):
\t\ttime_val_lbl.visible = is_custom
\t\ttime_val_lbl.text = time_str
\tif is_instance_valid(kills_val_lbl):
\t\tkills_val_lbl.visible = is_custom
\t\tkills_val_lbl.text = kills_str"""

code = code.replace(old_logic, new_logic)

with open(gd_path, "w", encoding="utf-8") as f:
    f.write(code)

print("Updated defeat_overlay.gd with smart dynamic label visibility!")
