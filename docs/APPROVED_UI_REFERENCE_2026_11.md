# MUTANT — approved visual direction (11 November 2026)

**Status: user-approved** for both the portrait combat HUD and the portrait home menu. These references are visual targets; AI-produced composites are **not** screenshots of the working Godot UI. Do not claim 95–97% similarity without actual Godot screenshot comparison.

## Home / Campaign

- Vertical 9:16 game menu, same actual ruined-city/armored-soldier backdrop already used by the project.
- Dark steel/navy with thin bright cyan modular outlines; lime green active states; amber/gold primary CTA. Avoid repeated chunky frames, unreadable miniature text and empty placeholder zones.
- Compact top: character portrait, account level and real XP progress; credits, crystals, and attempt count. Values must be read from StageDirector, never baked into the art.
- Hero dominates upper half. Only **one** campaign mission card with large environment preview, full title, stage selector arrows, recommended power, actual rewards. Link to all 100 levels remains reachable via the card.
- Only one prominent gold **GRAJ** action; do not add duplicated continue/roadmap panels underneath.
- Four primary **visible** portrait navigation tiles: KAMPANIA, POSTAĆ, EKWIPUNEK, SKLEP. The 100-stage details, rewards and settings remain available through real routes.
- All controls must respond to touch and reflow from 420px logical width through 720px and landscape.

## Combat HUD

- Avatar + live HP/XP + level at top left; compact real wallet top right; center wave + countdown; visible objective checklist left and enemy radar right.
- Larger, high contrast readable text and real status bars; cyan outlines with dark navy backgrounds; health green, XP bright blue, boss red and wave gold.
- Keep real combat arena visible. Enemies must look proportional to hero (compare **opaque body size**, not padded PNG canvas).
- Four/five ability slots centered at bottom, depending actual unlocked inventory. Joystick left. No fake consumables, grenade or manual fire button: MUTANT's actual mobile input is MOVE-ONLY + AUTO-FIRE.
- Functional panels must remain inside safe areas, not overlap status bar, joystick or screen edge.

## Other screens

- Equipment / character: use the same cyan-on-navy steel trim as home and combat, not a new theme. Preserve six RPG slots and equip/unequip state.
- Campaign, store, rewards and upgrade choice: scale typography for phones and use the same 3 visual accent colors. Controls remain data-bound.
- Defeat: **one** functional overlay over a dimmed live arena; no screenshot of a second defeat card in the background. Match revive price to actual game charge.

## Release acceptance

1. Godot project loads and compiles after each UI change.
2. UI regression passes for 420, 540, 720 portrait widths and landscape; all buttons remain clickable.
3. Capture actual 720×1280 and 1280×720 Godot PNGs for home, combat, upgrade, defeat, campaign, equipment and store.
4. Compare each with the approved reference; log concrete mismatches and fix; never substitute a generated mockup for in-game evidence.
5. Test APK on Android and verify touch targets, readability, FPS and absence of overlap.

Any subsequent UI/graphics work should reinforce this single reference style rather than starting over.
