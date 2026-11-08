from PIL import Image

src = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794168896683_90160beb.jpg"
im = Image.open(src)
w, h = im.size
print(f"Master Sheet Dimensions: {w} x {h}")

# In 1024 x 682:
# 1. MSDEFEAT OVERLAY - 16:9 (Top Left):
# Box starts at x: 6, y: 15 to x: 575, y: 360
overlay_169 = im.crop((6, 20, 575, 360))
print("16:9 crop size:", overlay_169.size)

# 2. MSDEFEAT OVERLAY - 9:16 (Top Center):
# Box starts at x: 580, y: 15 to x: 785, y: 380
overlay_916 = im.crop((580, 20, 785, 380))
print("9:16 crop size:", overlay_916.size)

# 3. ELEMENTY UI / RAMKI / PANELE (Top Right):
# x: 795, y: 20 to x: 1015, y: 380
ui_elements = im.crop((795, 20, 1015, 380))
print("UI elements crop size:", ui_elements.size)

# 4. STANY PRZYCISKÓW (PRZYKŁAD: WSKRZEŚ) (Middle Left):
# x: 15, y: 395 to x: 485, y: 470
btn_states = im.crop((15, 395, 485, 470))
print("Button states crop size:", btn_states.size)

# 5. KAFELKI STATYSTYK (Middle Right):
# x: 505, y: 395 to x: 885, y: 460
stat_tiles = im.crop((505, 395, 885, 460))
print("Stat tiles crop size:", stat_tiles.size)

# 6. IKONY SYSTEMOWE (Row below buttons):
# x: 15, y: 480 to x: 525, y: 525
system_icons = im.crop((15, 480, 525, 525))
print("System icons crop size:", system_icons.size)
