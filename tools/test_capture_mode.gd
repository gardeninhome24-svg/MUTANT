extends SceneTree

func _init() -> void:
	print("Test runner initialized. Testing window & viewport...")
	var r := get_root()
	var sub := SubViewport.new()
	sub.size = Vector2i(1280, 720)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	r.add_child(sub)
	
	var cr := ColorRect.new()
	cr.size = Vector2(1280, 720)
	cr.color = Color(0.1, 0.5, 0.9, 1.0)
	sub.add_child(cr)
	
	var lbl := Label.new()
	lbl.text = "TEST VIEWPORT CAPTURE"
	lbl.position = Vector2(400, 300)
	sub.add_child(lbl)
	
	for i in range(5):
		await process_frame
	
	var img := sub.get_texture().get_image()
	if img:
		print("SubViewport get_image size:", img.get_size(), "format:", img.get_format())
		img.save_png("res://tools/test_subviewport.png")
		print("Saved test_subviewport.png successfully!")
	else:
		print("SubViewport img is NULL")
	quit(0)
