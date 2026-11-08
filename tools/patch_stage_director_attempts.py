# -*- coding: utf-8 -*-
sd_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\stage_director.gd"
with open(sd_path, "r", encoding="utf-8") as f:
    sd = f.read()

refill_code = """const SINGLE_ATTEMPT_REFILL_GEMS := 18
const FULL_ATTEMPTS_REFILL_GEMS := 60

func can_buy_single_attempt_refill() -> bool:
\treturn attempts < 5 and dark_matter_gems >= SINGLE_ATTEMPT_REFILL_GEMS

func buy_single_attempt_refill() -> bool:
\tif not can_buy_single_attempt_refill():
\t\treturn false
\tdark_matter_gems -= SINGLE_ATTEMPT_REFILL_GEMS
\tattempts = mini(5, attempts + 1)
\tif attempts >= 5:
\t\tnext_attempt_at = 0
\tsave_campaign_profile()
\temit_signal("profile_data_changed")
\treturn true

func can_buy_full_attempts_refill() -> bool:
\treturn attempts < 5 and dark_matter_gems >= FULL_ATTEMPTS_REFILL_GEMS

func buy_full_attempts_refill() -> bool:
\tif not can_buy_full_attempts_refill():
\t\treturn false
\tdark_matter_gems -= FULL_ATTEMPTS_REFILL_GEMS
\tattempts = 5
\tnext_attempt_at = 0
\tsave_campaign_profile()
\temit_signal("profile_data_changed")
\treturn true

"""

if "func buy_single_attempt_refill" not in sd:
    sd = sd.replace("func refill_attempts_sandbox() -> void:", refill_code + "func refill_attempts_sandbox() -> void:", 1)
    with open(sd_path, "w", encoding="utf-8") as f:
        f.write(sd)
    print("Added gem attempt refill methods to stage_director.gd")
else:
    print("Methods already present in stage_director.gd")
