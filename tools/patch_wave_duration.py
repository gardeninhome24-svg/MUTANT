# -*- coding: utf-8 -*-
sd_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\stage_director.gd"
with open(sd_path, "r", encoding="utf-8") as f:
    sd = f.read()

if "var wave_duration_sec:" not in sd:
    sd = sd.replace("var pity_chest_counter: int = 0\n", "var pity_chest_counter: int = 0\nvar wave_duration_sec: float = 65.0 # 10 fal * 65s = ~11 minut na pełny etap\n", 1)
    with open(sd_path, "w", encoding="utf-8") as f:
        f.write(sd)
    print("Added wave_duration_sec to stage_director.gd")

main_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\main.gd"
with open(main_path, "r", encoding="utf-8") as f:
    m = f.read()

# Replace hardcoded WAVE_DURATION_SEC in main.gd to read from StageDirector
m = m.replace("const WAVE_DURATION_SEC := 18.0\n", "const WAVE_DURATION_SEC := 65.0\n")
m = m.replace("wave_time_left = WAVE_DURATION_SEC", "wave_time_left = StageDirector.wave_duration_sec")
m = m.replace("wave_timer_bar.max_value = WAVE_DURATION_SEC", "wave_timer_bar.max_value = StageDirector.wave_duration_sec")
m = m.replace("wave_director.start_wave(current_wave_num, WAVE_DURATION_SEC)", "wave_director.start_wave(current_wave_num, StageDirector.wave_duration_sec)")

with open(main_path, "w", encoding="utf-8") as f:
    f.write(m)
print("Updated main.gd to use StageDirector.wave_duration_sec")
