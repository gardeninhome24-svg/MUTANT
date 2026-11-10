#!/usr/bin/env python3
"""Static Google Play submission preflight. No credentials or network required.

Run: python3 tools/google_play_preflight.py
This is deliberately stricter than debug APK CI. A green APK job is not a Play release.
"""
from __future__ import annotations

import argparse
import configparser
import re
import xml.etree.ElementTree as ET
from pathlib import Path

PARSER = argparse.ArgumentParser(description="Audit Google Play readiness without publishing")
PARSER.add_argument("--report-only", action="store_true", help="Report blockers without failing private debug APK CI")
ARGS = PARSER.parse_args()

ROOT = Path(__file__).resolve().parents[1]
issues: list[tuple[str, str]] = []
passed: list[str] = []

def block(topic: str, detail: str) -> None:
    issues.append((topic, detail))

config = configparser.ConfigParser(interpolation=None)
config.read(ROOT / "export_presets.cfg", encoding="utf-8")
android_presets = []
release_presets = []
package_names: set[str] = set()
missing_package_names: list[str] = []
for section in config.sections():
    if not re.fullmatch(r"preset\.\d+", section):
        continue
    if config.get(section, "platform", fallback="").strip('"') != "Android":
        continue
    opts = section + ".options"
    if config.has_section(opts):
        android_presets.append((section, config[opts]))
        pkg = config.get(opts, "package/unique_name", fallback="").strip('"')
        if pkg:
            package_names.add(pkg)
        else:
            missing_package_names.append(section)
        if "google play" in config.get(section, "name", fallback="").lower():
            release_presets.append((section, config[opts]))

if not android_presets:
    block("Android preset", "No Android export preset found")
else:
    compliant = False
    for name, opts in android_presets:
        gradle = opts.get("gradle_build/use_gradle_build", "false") == "true"
        app_bundle = opts.get("gradle_build/export_format", "0") == "1"
        target = opts.get("gradle_build/target_sdk", "").strip('"')
        if gradle and app_bundle and target.isdigit() and int(target) >= 36:
            compliant = True
        if opts.get("architectures/arm64-v8a", "false") == "true":
            passed.append(name + ": arm64-v8a enabled")
    if not compliant:
        block("AAB / target SDK", "Need a release Android Gradle preset with AAB export_format=1 and target_sdk>=36")
    else:
        passed.append("Google Play preset uses Gradle, AAB and target API 36+")
    if missing_package_names or len(package_names) != 1:
        block("Application ID", "Android beta and Play release must use the same stable, non-empty package identifier")
    elif not re.fullmatch(r"[a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*){2,}", next(iter(package_names))):
        block("Application ID", "Invalid Android application ID syntax")
    else:
        passed.append("Android package ID consistent across presets")
    if len(release_presets) != 1:
        block("Play preset", "Exactly one Google Play AAB preset must exist")
    else:
        release_name, release_opts = release_presets[0]
        if config.get(release_name, "runnable", fallback="false") != "false":
            block("Play release", "Play AAB preset must not be runnable as debug")
        code = release_opts.get("version/code", "").strip('"')
        if not code.isdigit() or int(code) <= 0:
            block("Play version code", "Google Play preset must specify a positive integer version/code")
        else:
            passed.append("Play release has explicit positive version code")
        version = release_opts.get("version/name", "").strip('"')
        if not version or re.search(r"[^0-9A-Za-z._+-]", version):
            block("Play version name", "Missing or malformed version/name")
        if release_opts.get("package/signed", "false") != "true":
            block("Play signing", "AAB preset must require a signed package")
        if release_opts.get("architectures/arm64-v8a", "false") != "true":
            block("Play ABI", "Release must include arm64-v8a")
        if release_opts.get("architectures/x86", "false") == "true" or release_opts.get("architectures/x86_64", "false") == "true":
            block("Play ABI", "Review unexpected emulator x86 ABI in production release")
        minimum = release_opts.get("gradle_build/min_sdk", "").strip('"')
        if not minimum.isdigit() or int(minimum) < 23:
            block("Play minimum SDK", "Explicit Android minimum SDK must be 23 or higher; verify device support")

director = (ROOT / "scripts" / "stage_director.gd").read_text(encoding="utf-8")
if not re.search(r"(?m)^const\s+BETA_TEST_GEMS_ENABLED\s*:\s*bool\s*=\s*false\s*$", director):
    block("Test currency", "Release requires explicit BETA_TEST_GEMS_ENABLED = false")
else:
    passed.append("Beta test premium grants explicitly disabled")

project = (ROOT / "project.godot").read_text(encoding="utf-8")
icon_match = re.search(r'(?m)^config/icon\s*=\s*"res://([^"]+)"\s*$', project)
if not icon_match:
    block("Launcher icon", "Missing config/icon asset path in project.godot")
else:
    icon_path = icon_match.group(1)
    if icon_path.endswith("purple_crystal.png") or "currency" in icon_path.lower():
        block("Launcher icon", "Currency icon used as app icon; replace with branded launcher art")
    elif not (ROOT / icon_path).is_file():
        block("Launcher icon", "Configured launcher icon does not exist: " + icon_path)
    else:
        passed.append("Branded launcher icon path configured (manual adaptive icon check still required)")
        if icon_path.lower().endswith(".svg"):
            try:
                icon_xml = ET.parse(ROOT / icon_path).getroot()
                viewbox = icon_xml.attrib.get("viewBox", "").split()
                if icon_xml.tag != "{http://www.w3.org/2000/svg}svg" or len(viewbox) != 4:
                    block("Launcher vector", "Icon must contain a valid SVG root and viewBox")
                else:
                    width, height = float(viewbox[2]), float(viewbox[3])
                    if width <= 0 or height <= 0 or abs(width - height) > 0.01:
                        block("Launcher shape", "Google Play icon artwork must have square geometry")
                    else:
                        passed.append("Launcher SVG has square viewBox")
                if any(tag in (ROOT / icon_path).read_text(encoding="utf-8") for tag in ("http://www.w3.org/1999/xlink", "<image", "foreignObject")):
                    block("Launcher security", "Icon must not reference embedded or external image resources")
            except (ET.ParseError, OSError, ValueError) as error:
                block("Launcher vector", "Invalid branded SVG: " + str(error))

# Production must not silently ship the repeated/fragmented placeholder boss
# animation art. This is a release-only blocker, not a private debug APK gate.
# Reuse the same PNG contract as the standalone boss importer. File existence
# alone cannot establish that a release contains valid and distinct animation art.
from boss_art_pack import FRAMES, CHAPTERS, inspect_png
from boss_art_geometry import alpha_bounds

boss_total = 0
missing_boss_frames: list[str] = []
invalid_boss_frames: list[str] = []
for chapter in CHAPTERS:
    directory = ROOT / "assets" / "bosses" / f"boss_ch{chapter:02d}"
    digests: list[str] = []
    complete = True
    for name in FRAMES:
        path = directory / name
        relative = f"boss_ch{chapter:02d}/{name}"
        if not path.is_file():
            missing_boss_frames.append(relative)
            complete = False
            continue
        try:
            data = path.read_bytes()
            if len(data) < 150:
                raise ValueError("empty or truncated PNG")
            digests.append(inspect_png(data, name))
            if name != "boss_portrait.png":
                shape = alpha_bounds(data, relative)
                if shape["feet"] < 0.88:
                    raise ValueError("actor feet do not reach the lower frame anchor")
        except (OSError, ValueError) as error:
            invalid_boss_frames.append(f"{relative} ({error})")
            complete = False
    # A repeated portrait pasted into each frame is not animation.
    if complete and len(set(digests)) < 6:
        invalid_boss_frames.append(f"boss_ch{chapter:02d}: fewer than 6 distinct frames")
        complete = False
    if complete:
        boss_total += 1

if missing_boss_frames or invalid_boss_frames:
    block("Final boss assets",
          f"{boss_total}/6 chapter 5–10 sprite sets pass PNG validation; "
          f"{len(missing_boss_frames)} files missing, "
          f"{len(invalid_boss_frames)} invalid files or sprite sets. "
          "Commit 66 validated images before signing the public AAB. "
          f"Examples: {(missing_boss_frames + invalid_boss_frames)[:4]}")
else:
    passed.append("All 66 chapter 5–10 boss sprites pass dimensions, PNG and duplicate-frame checks; visual review still required")

workflow = ROOT / ".github" / "workflows" / "google-play-aab.yml"
if not workflow.exists():
    block("Release AAB pipeline", "No separate signed Google Play AAB workflow found")
else:
    workflow_text = workflow.read_text(encoding="utf-8")
    if "--export-release" not in workflow_text or "Android Google Play AAB" not in workflow_text or ".aab" not in workflow_text:
        block("Signed AAB", "Google Play workflow does not export the signed Android Google Play AAB preset")
    else:
        passed.append("Isolated signed AAB workflow configured; credentials and output still need verification")
    if not re.search(r"(?m)^\s+workflow_dispatch:\s*$", workflow_text) or re.search(r"(?m)^\s+push:\s*$", workflow_text):
        block("Manual release trigger", "Google Play upload must be manual-only, never triggered on push")
    if "python3 tools/google_play_preflight.py" not in workflow_text:
        block("Release gate", "Play workflow must run the strict preflight before signing")
    if "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" not in workflow_text or "ANDROID_RELEASE_KEYSTORE_BASE64" not in workflow_text:
        block("Upload signing", "Release must use protected signing credentials")
    if "actions/upload-artifact@" not in workflow_text:
        block("AAB artifact", "Release workflow must preserve the signed bundle for manual inspection")
    if "jarsigner -verify -strict" not in workflow_text:
        block("AAB signature validation", "Signed AAB must pass strict jarsigner verification")
    if "unzip -tqq" not in workflow_text:
        block("AAB archive validation", "AAB workflow must validate ZIP archive integrity")

print("MutantSurvivor — Google Play static preflight")
for detail in passed:
    print("PASS:", detail)
for topic, detail in issues:
    print("BLOCK:", topic, "-", detail)
print("MANUAL: privacy-policy HTTPS URL in app and Play Console; Data safety, IARC")
print("MANUAL: billing / refunds if monetized, version codes, Play App Signing")
print("MANUAL: 16 KB native page size, real Android performance / gestures / save migration")
print("MANUAL: developer-account closed testing eligibility (12 testers / 14 days if applicable)")
if issues:
    print("RESULT: NO-GO; %d technical blockers" % len(issues))
    if not ARGS.report_only:
        raise SystemExit(1)
    print("REPORT ONLY: debug APK testing can continue; release remains blocked")
else:
    print("RESULT: STATIC CHECKS PASSED — still requires human and device approval")
