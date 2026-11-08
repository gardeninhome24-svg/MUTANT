from PIL import Image

src_path = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215\.user_uploaded\media_1794160635468_0e2ecceb.jpg"
bg_path = r"C:\Users\patry\Desktop\2026\MutantSurvivor\addons\ms_balance\assets\defeat_background_landscape.png"

# Save unpatched high-res 1280x720 image
im = Image.open(src_path).convert("RGB").resize((1280, 720), Image.Resampling.LANCZOS)
im.save(bg_path)
print("Saved clean unpatched defeat_background_landscape.png!")
