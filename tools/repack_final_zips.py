import os
import zipfile
import shutil

src_dir = r"C:\Users\patry\Desktop\2026\MutantSurvivor"
out_full = r"C:\Users\patry\Desktop\MutantSurvivor_Aktualny_Projekt.zip"
out_code = r"C:\Users\patry\Desktop\MutantSurvivor_Code_And_Diffs_Only.zip"
artifact_dir = r"C:\Users\patry\.gemini\antigravity\brain\8a050c14-8089-4632-a9b3-1bc6b685f215"

exclude_dirs = {"backups", "build_artifacts", ".git", ".import_cache", ".godot"}
code_extensions = {".gd", ".tscn", ".tres", ".cfg", ".json", ".md", ".txt", ".bat", ".py"}

print("--- Creating MutantSurvivor_Aktualny_Projekt.zip ---")
if os.path.exists(out_full):
    os.remove(out_full)

with zipfile.ZipFile(out_full, 'w', zipfile.ZIP_DEFLATED) as zip_full:
    for root, dirs, files in os.walk(src_dir):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for f in files:
            if f.endswith('.zip') or f.endswith('.tmp'):
                continue
            abs_p = os.path.join(root, f)
            rel_p = os.path.relpath(abs_p, src_dir)
            zip_full.write(abs_p, rel_p)

size_mb = os.path.getsize(out_full) / (1024 * 1024)
print(f"Aktualny Projekt ZIP created: {size_mb:.2f} MB")

print("--- Creating MutantSurvivor_Code_And_Diffs_Only.zip ---")
if os.path.exists(out_code):
    os.remove(out_code)

with zipfile.ZipFile(out_code, 'w', zipfile.ZIP_DEFLATED) as zip_code:
    for root, dirs, files in os.walk(src_dir):
        dirs[:] = [d for d in dirs if d not in exclude_dirs and not d.startswith("assets")]
        for f in files:
            ext = os.path.splitext(f)[1].lower()
            if ext in code_extensions and not f.endswith('.zip'):
                abs_p = os.path.join(root, f)
                rel_p = os.path.relpath(abs_p, src_dir)
                zip_code.write(abs_p, rel_p)

size_code_kb = os.path.getsize(out_code) / 1024
print(f"Code and Diffs Only ZIP created: {size_code_kb:.2f} KB")

# Copy to artifacts directory
shutil.copy2(out_full, os.path.join(artifact_dir, "MutantSurvivor_Aktualny_Projekt.zip"))
shutil.copy2(out_code, os.path.join(artifact_dir, "MutantSurvivor_Code_And_Diffs_Only.zip"))
print("Copied both clean archives to artifacts directory.")
