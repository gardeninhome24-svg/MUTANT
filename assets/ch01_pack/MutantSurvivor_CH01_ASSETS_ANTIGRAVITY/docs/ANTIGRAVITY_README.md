# MutantSurvivor — CHAPTER 01 art + Godot handoff

## What this ZIP really contains

- Three full-size STYLE REFERENCES in `reference/`.
- 16 separate floor tile textures, 128×128 PNG, extracted and resized from generated concept artwork (`tiles/`).
- 4 hero/class static sprites, 10+ mutant reference sprites and 1 boss reference (`characters/`, `enemies/`, `bosses/`).
- 12 standalone environmental props, 9 effects, 6 item icon references, 10 UI panel/bar assets.
- 16×16 tile layout in JSON + illustrative PNG preview, independent prop placement.
- Two test GDScript files that load art as nodes with Godot 4.

## Honest limitations — read before use

The original pictures were generated as **illustrated composite atlases**, not as source animation files. Cropped characters, effects and props are **draft assets**; they may contain matte remnants and need transparent edge cleanup or repainting. They DO NOT include actual directional walk/shoot/hurt/die animation frames, so use existing animations where present. Tiles may show seams and are not guaranteed seamless. This is an integration-ready **reference/preproduction pack**, not a production-finished 100-level art set. **Do not claim all sprites or animations are finished.**

## Critical instructions to Antigravity

1. BACK UP active Godot project. Identify its actual path, main scene, and active level scene; don't assume project folder.
2. Copy `characters/ enemies/ bosses/ props/ tiles/ vfx/ ui/ icons/ maps/ reference/` to `res://assets/mutantsurvivor_ch01/`. Keep existing sprites; do not overwrite without comparing.
3. First fix screenshot defect: grey unrendered area below/right, UI placed in wrong canvas, enemies rendered outside the playfield. Use Camera2D + world Node2D, Control HUD inside CanvasLayer, stretch_mode=canvas_items, aspect=expand; verify exact Godot version project supports this. Test 1280x720 and 1920x1080 and window resize.
4. `godot/ch01_map_builder.gd` is a separate test builder. It can place floor sprites and props but needs integration into the existing map, size scaling, physics and Y-sorting. Use it as a reference to learn file names and node setup, not as production code.
5. Gameplay map should use multi-layer actual world nodes: tile ground, collision, props, VFX, player, enemy spawn manager, camera. Do not insert full mockup image as world background and call it a map. The illustrated gameplay reference is visual guidance only.
6. Keep player and enemies within valid world bounds. Spawn only around camera beyond its margins but within a navigable region, avoid spawn on top of props, use object pooling.
7. Implement actual 8-direction animations from the project's existing sprites or newly drawn frames. Never fake completed animations by showing static reference sprites in a loop.
8. HUD: HP, XP, chapter+wave/timer, pause, minimap, two currencies; dynamically compose with Godot Control nodes and use included UI PNG as skins where useful. Anchors and mobile safe areas must resize correctly.
9. Match dark gritty blue-gray concrete, toxic neon-green, cyan industrial lights, amber fire and purple energy as the overarching palette. Maintain contrast so projectiles and hits remain visible.
10. Test stage 001 fully before expansion: no grey areas at window edges; smooth camera follow; player movement + accurate muzzle facing; enemies approach player without clipping; visible projectile collision; pickups; damage/health; 10 waves; boss encounter; restart, save where applicable; stable FPS under 100 enemies. Screenshots at 1280×720 and 1920×1080 from actual running Godot project.

## Suggested work order

A. import -> verify textures -> fix camera/UI -> map collision/spawn -> stage 001 playable -> polish sprite edges -> animations -> weapon and boss visuals -> test -> only then extend chapters.

## Project compatibility

This ZIP contains original generated image references and separately extracted PNGs. No `.godot` cache, no executable, no unsafe scripts or environment-specific file paths. Test scripts are optional. Godot 4 with GDScript.
