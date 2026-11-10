# MUTANT — closed Android beta release gate

**Status:** NO-GO until the latest Android APK job is green **and** the on-device checks below are recorded. Debug APK success is not Google Play approval.

## Order of operations

1. Merge/fetch `main` and review **Actions → MutantSurvivor Android APK** for the exact commit SHA.
2. Require all Godot checks to pass, including the complete save/reward scene regression and **10/10 chapter boss integrations**. A synthetic jump to wave 10 does *not* prove that 10 waves are balanced.
3. Download the **MutantSurvivor-Android-APK** artifact and retain the accompanying SHA-256. Verify it matches the workflow summary and archive.
4. Inspect the APK-signature verification and application-ID checks. Use this APK only for an explicitly invited private beta, never as a release-signed Google Play bundle.
5. Install on real devices (at least one lower-end ARM64 handset and one current ARM64 handset), collect device model, Android version, build SHA, FPS, memory, screenshots and `adb logcat` around any crash.
6. Perform the manual matrix below. Do not mark a manual case PASS unless a tester has performed it on an actual Android device.
7. Freeze the beta candidate build SHA, record all failures and retest repairs against the **same** scenarios.
8. After beta fixes and player feedback, run the separate manual **Google Play AAB** workflow. It must pass strict preflight and keystore checks, then be installed through a Google Play testing track before considering production.

## Manual Android test matrix

| ID | Required action | Passing evidence |
|---|---|---|
| B01 | Fresh install, open menu, start first mission | Screenshot, no startup errors or crash |
| B02 | Play a full ordinary mission with **10 real waves** | Wave progression, mission objective, results |
| B03 | Lose a mission, skip revive, retry | No free victory/unlock or duplicated loot |
| B04 | Win once, return to menu, force-close and reopen | Exactly one reward, unlocked stage and items persist |
| B05 | Equip, unequip, upgrade and fuse items, then restart app | No lost/duplicated gear or negative currency |
| B06 | Play chapter finale (stage 10) and defeat the boss | Visible complete sprite, kill recorded, proper victory |
| B07 | Inspect chapter bosses 5–10 in gameplay | Each visually approved; no cut parts, repeated limbs, broken movement |
| B08 | Play at portrait 720×1280 and narrow handset width | HUD, joystick, fire, dash, dialogs and buttons remain usable |
| B09 | Run 20–30 minutes on lower-end handset | Record FPS, thermal throttling, memory and crashes |
| B10 | Update an **existing** beta installation with a newer build | Campaign, currencies, class and equipment survive update |
| B11 | Check offline start, background/resume, interrupted save | No permanent loading screen or profile corruption |
| B12 | Test purchases/ads only if enabled in the beta | No test-only grants leak into public release; billing policies checked |

## Release blockers that must remain visible

- Final 66 boss PNGs for chapters 5–10 must be imported and visually approved. A file-count or image-dimension PASS is not a visual approval.
- Balance, performance and real 10-wave mission completion remain **manual** tests even when CI passes.
- Real Android save-migration testing is mandatory before assigning release status.
- Google Play publication additionally requires: release-signing key, version-code upgrade, 16 KB native page-size compatibility, target SDK compliance, privacy-policy HTTPS URL, Data safety and content-rating declarations, store listing, and any applicable closed-testing/account eligibility.
- **No production upload is automated by the debug APK workflow.**

## Tester report template

```text
Build commit:
APK SHA-256:
Device / Android version:
Test ID:
PASS / FAIL:
Steps to reproduce:
Expected result:
Actual result:
Screenshot/video/logcat:
FPS / memory (if relevant):
```

**Definition of beta-ready:** green CI on a pinned SHA, no known blocking crashes or save corruption, required gameplay and device checks passed, distribution restricted to invited testers. **Definition of Google Play-ready:** beta exit criteria plus successful signed AAB test-track installation and all store/policy checks completed.
