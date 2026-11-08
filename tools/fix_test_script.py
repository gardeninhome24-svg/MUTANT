# -*- coding: utf-8 -*-
p = r"C:\Users\patry\Desktop\2026\MutantSurvivor\tools\test_balance_addon_acceptance.gd"
with open(p, "r", encoding="utf-8") as f:
    c = f.read()

c = c.replace('var signal_received := ""', 'var signal_received := [""]')
c = c.replace('signal_received = "premium"', 'signal_received[0] = "premium"')
c = c.replace('signal_received = "ad"', 'signal_received[0] = "ad"')
c = c.replace('signal_received = "retry"', 'signal_received[0] = "retry"')
c = c.replace('signal_received = "hub"', 'signal_received[0] = "hub"')
c = c.replace('signal_received == "premium"', 'signal_received[0] == "premium"')
c = c.replace('signal_received == "retry"', 'signal_received[0] == "retry"')
c = c.replace('signal_received == "hub"', 'signal_received[0] == "hub"')

with open(p, "w", encoding="utf-8") as f:
    f.write(c)
print("Updated successfully!")
