extends Node2D
# Attach as temporary scene script to inspect images after copying the pack under res://assets/mutantsurvivor_ch01/
const ROOT = "res://assets/mutantsurvivor_ch01/"
func _ready() -> void:
    var dirs = ["characters", "enemies", "bosses", "props", "vfx", "icons"]
    var x := 60.0
    var y := 80.0
    for dir_name in dirs:
        var dir := DirAccess.open(ROOT + dir_name)
        if dir == null:
            push_warning("Missing: " + dir_name)
            continue
        dir.list_dir_begin()
        while true:
            var file := dir.get_next()
            if file.is_empty():
                break
            if dir.current_is_dir() or not file.ends_with(".png"):
                continue
            var sprite := Sprite2D.new()
            sprite.texture = load(ROOT + dir_name + "/" + file)
            sprite.position = Vector2(x, y)
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
            add_child(sprite)
            x += 190
            if x > 1250:
                x = 60
                y += 230
        dir.list_dir_end()
        y += 230
        x = 60
