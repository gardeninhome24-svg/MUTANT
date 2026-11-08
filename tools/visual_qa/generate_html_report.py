import os
import json

def generate_report():
    root = r"C:\Users\patry\Desktop\2026\MutantSurvivor"
    manifest_p = os.path.join(root, "visual_qa", "references", "manifest.json")
    diffs_dir = os.path.join(root, "visual_qa", "diffs")
    reports_dir = os.path.join(root, "visual_qa", "reports")
    os.makedirs(reports_dir, exist_ok=True)

    with open(manifest_p, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    summary_p = os.path.join(diffs_dir, "summary_report.json")
    summary = []
    if os.path.exists(summary_p):
        with open(summary_p, "r", encoding="utf-8") as f:
            summary = json.load(f)

    rep_by_id = {r.get("scenario_id"): r for r in summary}

    cards_html = ""
    for sc in manifest.get("scenarios", []):
        sc_id = sc["id"]
        rep = rep_by_id.get(sc_id, {})
        status = rep.get("status", "NIEZNANY")
        ssim_val = rep.get("ssim", "N/A")
        diff_pct = rep.get("mismatch_area_pct", "N/A")
        res = rep.get("resolution", sc.get("resolution", [1280, 720]))

        status_class = "status-fix"
        if status == "ZATWIERDZONE":
            status_class = "status-approved"
        elif status == "DO AKCEPTACJI":
            status_class = "status-review"

        key_elems_li = "".join([f"<li>{el}</li>" for el in sc.get("key_elements", [])])

        card = f"""
        <div class="qa-card" id="{sc_id}">
            <div class="qa-header">
                <div>
                    <h2>{sc.get("name")}</h2>
                    <span class="scene-path"><code>{sc.get("scene_path")}</code> ({res[0]}x{res[1]})</span>
                </div>
                <div class="status-badge {status_class}">{status}</div>
            </div>

            <div class="metrics-row">
                <div class="metric-box">
                    <span class="m-val">{ssim_val}</span>
                    <span class="m-lbl">SSIM (Wskaźnik podobieństwa)</span>
                </div>
                <div class="metric-box">
                    <span class="m-val">{diff_pct}%</span>
                    <span class="m-lbl">Obszar różnicy pikseli</span>
                </div>
                <div class="metric-box">
                    <span class="m-val">{sc.get("tolerance_ssim")}</span>
                    <span class="m-lbl">Próg akceptacji SSIM</span>
                </div>
            </div>

            <div class="image-grid">
                <div class="img-panel">
                    <h4>1. REFERENCJA PROJEKTOWA</h4>
                    <img src="../diffs/{sc_id}_reference.png" alt="Reference" />
                </div>
                <div class="img-panel">
                    <h4>2. SCREENSHOT GODOT 4.7.2</h4>
                    <img src="../diffs/{sc_id}_actual.png" alt="Actual" />
                </div>
                <div class="img-panel">
                    <h4>3. NAKŁADKA 50/50</h4>
                    <img src="../diffs/{sc_id}_overlay_50.png" alt="Overlay 50/50" />
                </div>
                <div class="img-panel">
                    <h4>4. HEATMAPA RÓŻNIC</h4>
                    <img src="../diffs/{sc_id}_heatmap.png" alt="Heatmap" />
                </div>
            </div>

            <div class="details-box">
                <h4>Kluczowe kryteria weryfikacji:</h4>
                <ul>{key_elems_li}</ul>
            </div>
        </div>
        """
        cards_html += card

    html_content = f"""<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mutant Survivor — Visual QA 2.0 Dashboard</title>
    <style>
        :root {{
            --bg-main: #0c0f14;
            --bg-card: #151a23;
            --bg-panel: #1e2430;
            --border-color: #2b3545;
            --text-main: #e2e8f0;
            --text-muted: #8b9bb4;
            --accent-green: #10b981;
            --accent-yellow: #f59e0b;
            --accent-red: #ef4444;
            --accent-blue: #3b82f6;
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }}
        body {{ background: var(--bg-main); color: var(--text-main); padding: 30px; }}
        header {{ margin-bottom: 30px; border-bottom: 1px solid var(--border-color); padding-bottom: 20px; display: flex; justify-content: space-between; align-items: center; }}
        h1 {{ font-size: 26px; color: #fff; letter-spacing: 0.5px; }}
        .header-desc {{ color: var(--text-muted); font-size: 14px; margin-top: 4px; }}
        .qa-card {{ background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 12px; padding: 24px; margin-bottom: 30px; box-shadow: 0 4px 14px rgba(0,0,0,0.4); }}
        .qa-header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; }}
        h2 {{ font-size: 20px; color: #f8fafc; }}
        .scene-path {{ font-size: 12px; color: var(--text-muted); display: block; margin-top: 4px; }}
        .status-badge {{ font-size: 12px; font-weight: 700; padding: 6px 14px; border-radius: 6px; text-transform: uppercase; letter-spacing: 0.5px; }}
        .status-approved {{ background: rgba(16, 185, 129, 0.2); color: var(--accent-green); border: 1px solid var(--accent-green); }}
        .status-review {{ background: rgba(245, 158, 11, 0.2); color: var(--accent-yellow); border: 1px solid var(--accent-yellow); }}
        .status-fix {{ background: rgba(239, 68, 68, 0.2); color: var(--accent-red); border: 1px solid var(--accent-red); }}
        .metrics-row {{ display: flex; gap: 16px; margin-bottom: 20px; }}
        .metric-box {{ background: var(--bg-panel); border: 1px solid var(--border-color); border-radius: 8px; padding: 12px 18px; flex: 1; }}
        .m-val {{ font-size: 22px; font-weight: bold; color: #fff; display: block; }}
        .m-lbl {{ font-size: 11px; color: var(--text-muted); text-transform: uppercase; }}
        .image-grid {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; margin-bottom: 20px; }}
        .img-panel {{ background: #000; border: 1px solid var(--border-color); border-radius: 8px; overflow: hidden; padding: 10px; }}
        .img-panel h4 {{ font-size: 11px; color: var(--text-muted); margin-bottom: 8px; letter-spacing: 0.5px; }}
        .img-panel img {{ width: 100%; height: auto; display: block; border-radius: 4px; }}
        .details-box {{ background: var(--bg-panel); border-radius: 8px; padding: 14px 18px; font-size: 13px; }}
        .details-box h4 {{ color: #cbd5e1; margin-bottom: 8px; font-size: 13px; }}
        .details-box ul {{ list-style-position: inside; color: var(--text-muted); line-height: 1.6; }}
    </style>
</head>
<body>
    <header>
        <div>
            <h1>MUTANT SURVIVOR — VISUAL QA 2.0 PANEL RAPORTOWY</h1>
            <div class="header-desc">Automatyczna weryfikacja wizualna: Referencja Projektowa vs Rzeczywisty Screenshot Godot 4.7.2</div>
        </div>
        <div>
            <span style="font-size: 12px; color: var(--text-muted);">Silnik: Godot 4.7.2 Forward+ Vulkan | Biblioteki: Pillow + NumPy + scikit-image 0.26.0</span>
        </div>
    </header>

    <div class="dashboard-body">
        {cards_html}
    </div>
</body>
</html>
"""
    out_html = os.path.join(reports_dir, "index.html")
    with open(out_html, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"HTML Report Dashboard successfully generated: {out_html}")

if __name__ == "__main__":
    generate_report()
