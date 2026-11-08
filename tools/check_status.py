import os, sys
sys.stdout.reconfigure(encoding='utf-8')

project_dir = 'C:/Users/patry/Desktop/2026/MutantSurvivor'

print("=== Checking MutantSurvivor Status ===")

# Check main/main.tscn for WinPanel
with open(os.path.join(project_dir, 'scenes/main/main.tscn'), 'r', encoding='utf-8') as f:
    main_tscn = f.read()

pos = main_tscn.find('[node name="WinPanel"')
if pos != -1:
    print("Found WinPanel in scenes/main/main.tscn:\n", main_tscn[pos:pos+1500])
else:
    print("WinPanel NOT found in scenes/main/main.tscn")
