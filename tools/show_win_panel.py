import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('C:/Users/patry/Desktop/2026/MutantSurvivor/scenes/main/main.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

pos = text.find('[node name="WinPanel"')
if pos != -1:
    print(text[pos:pos+2500])
