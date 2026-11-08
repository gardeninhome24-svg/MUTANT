import os
import sys
import json
import numpy as np
from PIL import Image, ImageOps, ImageDraw, ImageFont
from skimage.metrics import structural_similarity as ssim

def compare_pair(ref_path: str, actual_path: str, out_dir: str, scenario_id: str, tolerance_ssim: float = 0.65) -> dict:
    os.makedirs(out_dir, exist_ok=True)

    if not os.path.exists(ref_path):
        return {"scenario": scenario_id, "status": "ERROR", "error": f"Reference not found: {ref_path}"}
    if not os.path.exists(actual_path):
        return {"scenario": scenario_id, "status": "ERROR", "error": f"Actual capture not found: {actual_path}"}

    img_ref = Image.open(ref_path).convert("RGB")
    img_act = Image.open(actual_path).convert("RGB")

    # Ensure identical dimensions
    if img_ref.size != img_act.size:
        img_ref = img_ref.resize(img_act.size, Image.Resampling.LANCZOS)

    w, h = img_act.size

    arr_ref = np.array(img_ref, dtype=np.float32)
    arr_act = np.array(img_act, dtype=np.float32)

    # 1. 50/50 Overlay Blend
    arr_overlay = (arr_ref * 0.5 + arr_act * 0.5).astype(np.uint8)
    img_overlay = Image.fromarray(arr_overlay)
    overlay_path = os.path.join(out_dir, f"{scenario_id}_overlay_50.png")
    img_overlay.save(overlay_path)

    # 2. Absolute Difference Image (amplified for visibility)
    diff_arr = np.abs(arr_ref - arr_act)
    diff_gray = np.mean(diff_arr, axis=2)
    diff_amp = np.clip(diff_gray * 2.8, 0, 255).astype(np.uint8)
    img_diff = Image.fromarray(diff_amp)
    diff_path = os.path.join(out_dir, f"{scenario_id}_difference.png")
    img_diff.save(diff_path)

    # 3. Heatmap Image (Custom Color Map: dark blue -> cyan -> yellow -> bright red)
    norm_diff = diff_gray / 255.0
    heatmap_rgb = np.zeros((h, w, 3), dtype=np.uint8)
    # R channel: high difference
    heatmap_rgb[..., 0] = np.clip((norm_diff - 0.25) * 4.0 * 255, 0, 255).astype(np.uint8)
    # G channel: medium difference
    heatmap_rgb[..., 1] = np.clip((1.0 - np.abs(norm_diff - 0.5) * 2.5) * 255, 0, 255).astype(np.uint8)
    # B channel: low difference / background
    heatmap_rgb[..., 2] = np.clip((0.6 - norm_diff * 1.5) * 255, 30, 255).astype(np.uint8)
    img_heatmap = Image.fromarray(heatmap_rgb)
    heatmap_path = os.path.join(out_dir, f"{scenario_id}_heatmap.png")
    img_heatmap.save(heatmap_path)

    # 4. Metrics: SSIM, MSE, PSNR
    gray_ref = np.mean(arr_ref, axis=2).astype(np.float32) / 255.0
    gray_act = np.mean(arr_act, axis=2).astype(np.float32) / 255.0

    score_ssim, ssim_full = ssim(gray_ref, gray_act, full=True, data_range=1.0)
    mse = float(np.mean((arr_ref - arr_act) ** 2))
    psnr = float(10 * np.log10(255.0 ** 2 / max(1e-5, mse)))

    # Detect high mismatch clusters / bounding boxes
    mismatch_threshold = 55.0
    mismatch_mask = diff_gray > mismatch_threshold
    mismatch_pct = float(np.sum(mismatch_mask) / (w * h) * 100.0)

    # 5. Composite Comparison Image (2x2 grid: Reference | Actual / Diff | Overlay)
    comp_w = w // 2
    comp_h = h // 2
    r_thumb = img_ref.resize((comp_w, comp_h))
    a_thumb = img_act.resize((comp_w, comp_h))
    d_thumb = img_diff.resize((comp_w, comp_h)).convert("RGB")
    o_thumb = img_overlay.resize((comp_w, comp_h))

    composite = Image.new("RGB", (comp_w * 2, comp_h * 2 + 60), color=(18, 22, 28))
    composite.paste(r_thumb, (0, 30))
    composite.paste(a_thumb, (comp_w, 30))
    composite.paste(d_thumb, (0, comp_h + 45))
    composite.paste(o_thumb, (comp_w, comp_h + 45))

    draw = ImageDraw.Draw(composite)
    draw.text((10, 8), f"REFERENCE (DESIGN)", fill=(220, 220, 220))
    draw.text((comp_w + 10, 8), f"ACTUAL (GODOT 4.7.2)", fill=(100, 255, 140))
    draw.text((10, comp_h + 32), f"DIFFERENCE MAP (AMPLIFIED)", fill=(255, 140, 100))
    draw.text((comp_w + 10, comp_h + 32), f"OVERLAY 50/50 (SSIM: {score_ssim:.3f})", fill=(120, 200, 255))

    comp_path = os.path.join(out_dir, f"{scenario_id}_comparison.png")
    composite.save(comp_path)

    # Copy raw reference and actual to diffs directory for local standalone viewing
    ref_copy_path = os.path.join(out_dir, f"{scenario_id}_reference.png")
    act_copy_path = os.path.join(out_dir, f"{scenario_id}_actual.png")
    img_ref.save(ref_copy_path)
    img_act.save(act_copy_path)

    # Status classification
    if score_ssim >= tolerance_ssim and mismatch_pct < 35.0:
        status = "ZATWIERDZONE"
    elif score_ssim >= (tolerance_ssim * 0.8):
        status = "DO AKCEPTACJI"
    else:
        status = "DO POPRAWY"

    report = {
        "scenario_id": scenario_id,
        "status": status,
        "resolution": [w, h],
        "ssim": round(float(score_ssim), 4),
        "tolerance_ssim": tolerance_ssim,
        "mse": round(mse, 2),
        "psnr_db": round(psnr, 2),
        "mismatch_area_pct": round(mismatch_pct, 2),
        "files": {
            "reference": os.path.relpath(ref_copy_path, os.path.dirname(out_dir)),
            "actual": os.path.relpath(act_copy_path, os.path.dirname(out_dir)),
            "overlay_50": os.path.relpath(overlay_path, os.path.dirname(out_dir)),
            "difference": os.path.relpath(diff_path, os.path.dirname(out_dir)),
            "heatmap": os.path.relpath(heatmap_path, os.path.dirname(out_dir)),
            "comparison": os.path.relpath(comp_path, os.path.dirname(out_dir))
        }
    }

    report_path = os.path.join(out_dir, f"{scenario_id}_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    return report

def main():
    root = r"C:\Users\patry\Desktop\2026\MutantSurvivor"
    manifest_p = os.path.join(root, "visual_qa", "references", "manifest.json")
    diffs_dir = os.path.join(root, "visual_qa", "diffs")

    with open(manifest_p, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    all_reports = []
    print("=== STARTING VISUAL QA COMPARISON SUITE ===")
    for sc in manifest.get("scenarios", []):
        sc_id = sc["id"]
        ref_path = os.path.join(root, sc["reference_image"])
        act_path = os.path.join(root, sc["actual_capture"])
        tol = sc.get("tolerance_ssim", 0.65)

        print(f"\nProcessing scenario: {sc_id}")
        rep = compare_pair(ref_path, act_path, diffs_dir, sc_id, tol)
        all_reports.append(rep)
        print(f" -> Status: {rep.get('status')} | SSIM: {rep.get('ssim')} | Diff Area: {rep.get('mismatch_area_pct')}%")

    # Global summary report
    summary_path = os.path.join(diffs_dir, "summary_report.json")
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(all_reports, f, indent=2)
    print(f"\nSaved summary report: {summary_path}")

if __name__ == "__main__":
    main()
