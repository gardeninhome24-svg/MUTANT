import sys, re
sys.stdout.reconfigure(encoding='utf-8')
with open('C:/Users/patry/Desktop/2026/MutantSurvivor/scripts/main.gd', 'r', encoding='utf-8') as f:
    text = f.read()

m = re.search(r'func (?:_on_stage_completed|_trigger_stage_victory|complete_stage)[\s\S]*?(?=\nfunc |\Z)', text)
if m:
    print(m.group(0)[:1500])
else:
    # search where win_summary_label is set
    for line in text.split('\n'):
        if 'win_summary_label' in line:
            print(line)
