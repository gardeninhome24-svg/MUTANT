#!/usr/bin/env python3
"""Static Google Play submission preflight. No credentials or network required.

Run: python3 tools/google_play_preflight.py
This is deliberately stricter than debug APK CI. A green APK job is not a Play release.
"""
from __future__ import annotations

import configparser
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
issues: list[tuple[str, str]] = []
passed: list[str] = []

def block(topic: str, detail: str) -> None:
    issues.append((topic, detail))

config = configparser.ConfigParser(interpolation=None)
config.read(ROOT / "export_presets.cfg", encoding="utf-8")
android_presets = []
for section in config.sections():
    if not re.fullmatch(r"preset\.\d+", section):
        continue
    if config.get(section, "platform", fallback="").strip('"') != "Android":
        continue
    opts = section + ".options"
    if config.has_section(opts):
        android_presets.append((section, config[opts]))

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

director = (ROOT / "scripts" / "stage_director.gd").read_text(encoding="utf-8")
if re.search(r"const\s+BETA_TEST_GEMS_ENABLED\s*:\s*bool\s*=\s*true", director):
    block("Test currency", "10,000 beta gems are enabled; disable for public release")
else:
    passed.append("No unconditional beta-gem flag detected")

workflow = ROOT / ".github" / "workflows" / "google-play-aab.yml"
if not workflow.exists():
    block("Release AAB pipeline", "No separate signed Google Play AAB workflow found")
else:
    workflow_text = workflow.read_text(encoding="utf-8")
    if "--export-release" not in workflow_text or "Android Google Play AAB" not in workflow_text or ".aab" not in workflow_text:
        block("Signed AAB", "Google Play workflow does not export the signed Android Google Play AAB preset")
    else:
        passed.append("Isolated signed AAB workflow configured; credentials and output still need verification")

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
    raise SystemExit(1)
print("RESULT: STATIC CHECKS PASSED — still requires human and device approval")
