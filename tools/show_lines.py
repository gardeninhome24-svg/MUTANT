import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('C:/Users/patry/Desktop/2026/MutantSurvivor/scripts/main.gd', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i in range(920, 965):
    print(f'{i+1}: {lines[i]}', end='')
