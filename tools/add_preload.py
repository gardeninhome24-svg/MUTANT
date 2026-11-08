path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\scripts\main.gd"
with open(path, "r", encoding="utf-8") as f:
    c = f.read()

const_decl = "const MSWaveDirector := preload(\"res://addons/ms_beta/wave_director.gd\")\n"
if const_decl not in c:
    c = c.replace("const LIGHT_COOKIE :=", const_decl + "const LIGHT_COOKIE :=", 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(c)
print("Preload added successfully!")
