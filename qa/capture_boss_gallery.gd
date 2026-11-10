extends SceneTree

# Render ACTUAL Godot-imported combat animation textures for chapters 5-10.
# Captures fallbacks too, but reports each one explicitly rather than
# incorrectly claiming the unbundled generated PNGs were tested.
var output_dir: String = "/tmp/mutantsurvivor-phone-shots"
var rows: Array[Dictionary] = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		if args[i] == "--out":
			output_dir = args[i + 1]
	call_deferred("_capture")

func _build_label(value: String, text_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", text_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _image_column(tex: Texture2D, caption: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 132.0
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 5)
	var img := TextureRect.new()
	img.custom_minimum_size = Vector2(132, 190)
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(img)
	col.add_child(_build_label(caption, 11, Color(0.83, 0.92, 0.97)))
	return col

func _boss_row(chapter: int) -> PanelContainer:
	var boss_id := "boss_ch%02d" % chapter
	var sprite := Sprite2D.new()
	var info: Dictionary = AssetRegistry.apply_enemy_visual(sprite, boss_id)
	var walk: Array = info.get("walk_frames", [])
	var attacks: Array = info.get("attack_frames", [])
	var deaths: Array = info.get("death_frames", [])
	var candidate: bool = AssetRegistry.has_complete_chapter_boss_art(boss_id)
	var status: String = "NOWE PNG (kandydat)" if candidate else "FALLBACK / stare PNG"
	var source_dir: String = AssetRegistry.get_candidate_boss_directory(boss_id) if candidate else "res://assets/bosses/" + String(AssetRegistry.BOSS_CHAPTER_FALLBACK_KITS[boss_id]) + "/"
	var fallback_portrait: Texture2D = AssetRegistry.get_tex(source_dir + "boss_portrait.png")
	# Export three representative source families for offline pixel-level audit.
	# This is QA evidence, not art that is added to the shipped APK.
	if chapter in [5, 6, 7]:
		var source_dump: String = output_dir.path_join("raw_boss_sources")
		DirAccess.make_dir_recursive_absolute(source_dump)
		for file_name in ["boss_portrait.png", "phase1_anim_1.png", "phase2_attack_3.png"]:
			var original: Texture2D = AssetRegistry.get_tex(source_dir + file_name)
			if original != null:
				var image_data: Image = original.get_image()
				if image_data != null and not image_data.is_empty():
					image_data.save_png(source_dump.path_join("boss_ch%02d_%s" % [chapter, file_name]))

	rows.append({"chapter": chapter, "candidate": candidate, "status": status,
		"walk": walk.size(), "attack": attacks.size(), "death": deaths.size(),
		"portrait": fallback_portrait != null})
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 314.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.14, 0.19)
	style.border_color = Color(0.54, 0.86, 0.24) if candidate else Color(0.93, 0.65, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	stack.add_child(_build_label("BOSS %02d — %s" % [chapter, status], 17, style.border_color))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	stack.add_child(row)
	if walk.size() != 4 or attacks.size() != 4 or deaths.size() != 2:
		printerr("BOSS GALLERY ERROR: incomplete frames " + boss_id)
		row.add_child(_build_label("BRAK KOMPLETU KLATEK", 19, Color.RED))
	else:
		row.add_child(_image_column(fallback_portrait, "Portret"))
		row.add_child(_image_column(walk[0], "Ruch 1"))
		row.add_child(_image_column(attacks[2], "Atak 3"))
		row.add_child(_image_column(deaths[1], "Smierc 2"))
	sprite.free()
	return panel

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(720, 1280)
	root.content_scale_size = Vector2i(720, 1280)
	for group_index in range(2):
		var bg := ColorRect.new()
		bg.color = Color(0.035, 0.060, 0.085)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_left = 12.0
		column.offset_right = -12.0
		column.offset_top = 12.0
		column.offset_bottom = -12.0
		column.add_theme_constant_override("separation", 12)
		bg.add_child(column)
		column.add_child(_build_label("MUTANT SURVIVOR — BOSS 5–10", 23, Color(0.77, 0.95, 0.32)))
		column.add_child(_build_label("PRAWDZIWY RENDER GODOT • ruch / atak / smierc", 12, Color(0.75, 0.87, 0.96)))
		for chapter in range(5 + group_index * 3, 8 + group_index * 3):
			column.add_child(_boss_row(chapter))
		for frame in range(12):
			await process_frame
		var pixels: Image = root.get_texture().get_image()
		var filename: String = "17_bosses_05_07_720x1280.png" if group_index == 0 else "18_bosses_08_10_720x1280.png"
		if pixels == null or pixels.is_empty() or pixels.get_size() != Vector2i(720, 1280):
			printerr("BOSS GALLERY ERROR: missing or invalid Godot viewport")
			quit(1)
			return
		if pixels.save_png(output_dir.path_join(filename)) != OK:
			printerr("BOSS GALLERY ERROR: PNG write failed")
			quit(1)
			return
		print("BOSS GALLERY SAVED: " + filename)
		bg.queue_free()
		await process_frame
	var candidates: int = 0
	var report := FileAccess.open(output_dir.path_join("boss_art_status.txt"), FileAccess.WRITE)
	if report == null:
		printerr("BOSS GALLERY ERROR: cannot save actual art status")
		quit(1)
		return
	for item in rows:
		if item["candidate"]:
			candidates += 1
		report.store_line("boss_ch%02d: %s, portrait=%s movement=%d attack=%d death=%d" % [
			item["chapter"], item["status"], str(item["portrait"]), item["walk"], item["attack"], item["death"]])
	report.store_line("NEW_BOSS_PACKS_ACTIVE=%d/6" % candidates)
	report.store_line("NOTE: Godot render / Xvfb, not physical phone or 97%% style verification.")
	report.close()
	print("BOSS GALLERY RESULT: new art %d/6, fallback %d/6" % [candidates, 6-candidates])
	quit()
