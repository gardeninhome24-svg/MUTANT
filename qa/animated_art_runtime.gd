extends SceneTree

# Validate real Texture2D resources and the actual AssetRegistry integration.
# This is NOT a visual approval or a playtest on an Android handset.
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("ANIMATED ART FAIL: " + description)

func _run() -> void:
	await process_frame
	var boss_ids: Array[String] = [
		"boss_ch01", "boss_ch02", "boss_ch03", "boss_ch04",
		"boss_ch05", "boss_ch06", "boss_ch07", "boss_ch08",
		"boss_ch09", "boss_ch10", "miniboss_ch01", "matka_roju"
	]
	for boss_id in boss_ids:
		_check(AssetRegistry.has_complete_chapter_boss_art(boss_id),
			"%s has 11 imported images" % boss_id)
		var actor_sprite: Sprite2D = Sprite2D.new()
		var visual: Dictionary = AssetRegistry.apply_enemy_visual(actor_sprite, boss_id)
		_check(String(visual.get("status", "")) == "BOSS_ART_CANDIDATE",
			"%s uses candidate animation instead of broken static fallback" % boss_id)
		_check(bool(visual.get("is_animated", false)), "%s is flagged animated" % boss_id)
		_check(actor_sprite.texture != null, "%s has active sprite texture" % boss_id)
		_check(visual.get("walk_frames", []).size() == 4, "%s loads four walk frames" % boss_id)
		_check(visual.get("attack_frames", []).size() == 4, "%s loads four attack frames" % boss_id)
		_check(visual.get("death_frames", []).size() == 2, "%s loads two death frames" % boss_id)
		if actor_sprite.texture != null:
			_check(actor_sprite.texture.get_width() == 256 and actor_sprite.texture.get_height() == 256,
				"%s gameplay sprite uses 256x256 frame" % boss_id)
		actor_sprite.free()

	# Instantiate an actual MutantEnemy scene to verify setup_enemy_archetype
	# uses the imported animation frames, not just registry lookups.
	var enemy_scene: PackedScene = load("res://scenes/enemies/mutant_beetle.tscn") as PackedScene
	_check(enemy_scene != null, "MutantEnemy gameplay scene loads")
	if enemy_scene != null:
		for boss_id in boss_ids:
			var enemy: Node = enemy_scene.instantiate()
			root.add_child(enemy)
			enemy.set_physics_process(false)
			enemy.call("setup_enemy_archetype", boss_id, "boss", 60, 0.0)
			var gameplay_sprite: Sprite2D = enemy.get_node_or_null("Sprite2D") as Sprite2D
			_check(is_instance_valid(gameplay_sprite) and gameplay_sprite.texture != null,
				"%s live enemy instance displays an animated frame" % boss_id)
			_check(enemy.get("walk_frames").size() == 4,
				"%s actual MutantEnemy caches walk animation" % boss_id)
			_check(enemy.get("attack_frames").size() == 4,
				"%s actual MutantEnemy caches attack animation" % boss_id)
			_check(enemy.get("death_frames").size() == 2,
				"%s actual MutantEnemy caches death animation" % boss_id)
			enemy.queue_free()
			await process_frame
		var larva: Node = enemy_scene.instantiate()
		root.add_child(larva)
		larva.set_physics_process(false)
		larva.call("setup_enemy_archetype", "czerw", "normal", 5, 0.0)
		_check(larva.get("walk_frames").size() == 4,
			"Actual larva enemy scene caches all walk animation frames")
		_check(larva.get("attack_frames").size() == 4,
			"Actual larva enemy scene caches all attack animation frames")
		larva.queue_free()
		await process_frame

	for action in AssetRegistry.PLAYER_ANIMATION_COUNTS:
		var count: int = int(AssetRegistry.PLAYER_ANIMATION_COUNTS[action])
		for idx in range(1, count + 1):
			var texture: Texture2D = AssetRegistry.get_player_animation_frame("toxic_soldier", action, idx)
			_check(texture != null, "Toxic soldier %s frame %d imported" % [action, idx])

	var mutant: Sprite2D = Sprite2D.new()
	var worm: Dictionary = AssetRegistry.apply_enemy_visual(mutant, "czerw")
	_check(worm.get("walk_frames", []).size() == 4, "Toxic larva has 4 walk frames")
	_check(worm.get("attack_frames", []).size() == 4, "Toxic larva has 4 attack frames")
	_check(mutant.texture != null, "Toxic larva has a gameplay sprite")
	mutant.free()

	if FileAccess.file_exists("res://assets/bosses/ART_CANDIDATE.txt"):
		print("ANIMATED ART REVIEW REQUIRED: assets are transform-generated candidates, NOT final approved animation")
	else:
		_check(false, "Candidate-marker missing; generated artwork must not be silently approved")

	if failures.is_empty():
		print("ANIMATED ART PASS: %d Godot runtime texture/animation assertions" % checks)
		quit(0)
	else:
		printerr("ANIMATED ART FAILED: %d/%d checks" % [failures.size(), checks])
		quit(1)
