# MutantSurvivor — Android beta release gate

This checklist applies to private tests on itch.io, not a public production launch.
No changes should be called "verified" solely because APK export passes.

## Repository and access
- [ ] Confirm the intended project root is `MUTANT/project.godot` and current commit is on `main`.
- [ ] Make the GitHub repository private if source/assets are confidential. It is currently public.
- [ ] Keep `BUTLER_API_KEY` only in GitHub Actions secrets; revoke leaked tokens.
- [ ] Restrict itch.io download access to the two invited testers.

## Automatic checks (every push)
- [ ] Godot asset import succeeds.
- [ ] Main menu starts headlessly without script/resource startup errors.
- [ ] Godot Android export completes and APK artifact exists.
- [ ] Upload artifact is downloadable; publishing to itch.io remains manual opt-in.

## Real Android QA (required before publication)
- [ ] Fresh install works and main menu is readable on the target phone.
- [ ] Portrait HUD: HP, XP, waves, credits, objectives and radar do not overlap.
- [ ] Thumbstick moves in all eight directions; release always stops movement.
- [ ] Multitouch: other UI taps do not hijack the joystick.
- [ ] Launch a stage; enemies spawn; autofire, collisions and damage work.
- [ ] XP pickup/level-up: select an upgrade without clipping or stuck pause.
- [ ] Lose a run: defeat/revive/retry/return-to-menu controls work.
- [ ] Win a run: reward display, next stage and menu return work.
- [ ] Equipment: backpack filters, item selection, equip/unequip and scrolling work.
- [ ] Restart the app: save data and progress persist.
- [ ] Check performance over a full stage: frame drops, heat, crashes and battery usage.
- [ ] Verify app upgrades over a previous signed APK without deleting save data.
- [ ] Run at least one full stage on each tester's Android phone.

## Signed APK release pipeline (manual)
- The normal Android workflow creates **debug** APKs for internal testing.
- The separate `Signed Android Release (manual)` workflow creates a **release-signed** APK. It does not upload to itch.io.
- Before running it, generate a permanent release keystore using Godot's Android signing guide, back up the keystore and its password securely, and add these GitHub Actions secrets:
  - `ANDROID_RELEASE_KEYSTORE_BASE64`: base64-encoded bytes of the *same permanent keystore* for all releases.
  - `ANDROID_RELEASE_KEY_ALIAS`: key alias.
  - `ANDROID_RELEASE_KEY_PASSWORD`: signing password.
- Never add a keystore, key password or generated signing credentials to repository files or chat.
- The first install signed with the release certificate cannot update a different certificate's debug APK in-place. Before sending it to testers, **back up their local game progress**, then test the debug-to-release migration.
- Increase the Android package version code for every release, and keep the application ID/certificate stable. Record SHA-256 of each published APK.
- Complete full device QA before manually distributing a signed APK.

## itch.io release
- [ ] Tester has explicitly approved the APK for private beta distribution.
- [ ] Workflow_dispatch with `publish_to_itch=true` finishes successfully.
- [ ] The published APK is accessible only through the intended restricted itch.io page.
- [ ] Both testers download/install the uploaded APK and report the version/build number.
- [ ] Public launch remains blocked until bugs and product/legal/payment requirements are separately reviewed.

## Notes
The Android workflow produces **debug** APKs for testing. Do not use this as a
public-release signing or app-store pipeline. Android screenshots and gesture
behavior must be checked on devices; headless CI cannot verify visual polish.
