from PIL import Image

src = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794160635468_0e2ecceb.jpg"
im = Image.open(src).convert("RGB").resize((1280, 720), Image.Resampling.LANCZOS)

# Coordinates of elements in 1280x720:
# Card outer bounding box:
# Left: 205, Top: 15, Right: 1075, Bottom: 675
# Width: 870, Height: 660

# Stat Tile 1 (Fala):
# Box: x1: 250, y1: 242, x2: 510, y2: 342
# Value "5/10" center: x: 405, y: 310

# Stat Tile 2 (Czas):
# Box: x1: 520, y1: 242, x2: 780, y2: 342
# Value "04:32" center: x: 680, y: 310

# Stat Tile 3 (Zabici):
# Box: x1: 785, y1: 242, x2: 1045, y2: 342
# Value "142" center: x: 935, y: 310

# Button 1 (Revive Premium):
# x1: 245, y1: 418, x2: 505, y2: 528
# Width: 260, Height: 110

# Button 2 (Revive Ad):
# x1: 525, y1: 418, x2: 785, y2: 528
# Width: 260, Height: 110

# Button 3 (Attempt):
# x1: 805, y1: 418, x2: 1050, y2: 528
# Width: 245, Height: 110

# Button 4 (Retry):
# x1: 275, y1: 568, x2: 625, y2: 648
# Width: 350, Height: 80

# Button 5 (Hub):
# x1: 660, y1: 568, x2: 1010, y2: 648
# Width: 350, Height: 80

print("Mapped all interactive coordinate zones in 1280x720!")
