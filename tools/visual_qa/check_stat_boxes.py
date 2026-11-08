from PIL import Image

src = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794168896683_90160beb.jpg"
im = Image.open(src)

# Let's crop y: 160..225 in top right
stat_boxes_row = im.crop((795, 160, 1015, 225))
stat_boxes_row.save(r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\ui_v2\clean_stat_boxes_row.png")
print("Saved clean_stat_boxes_row.png")
