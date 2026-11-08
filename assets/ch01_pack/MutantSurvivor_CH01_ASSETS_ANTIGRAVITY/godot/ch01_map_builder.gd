extends Node2D
# Attach to a Node2D test scene. Copy pack to res://assets/mutantsurvivor_ch01/ first.
# Does not replace existing game logic; a reusable test layout.
const ROOT := "res://assets/mutantsurvivor_ch01/"
const TILE := 128
func _ready() -> void:
    var path := ROOT + "maps/ch01_stage001_layout.json"
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (data is Dictionary):
        push_error("Invalid JSON map: " + path)
        return
    var cache := {}
    for yy in range(data.tiles.size()):
        for xx in range(data.tiles[yy].size()):
            var name: String = data.tiles[yy][xx]
            if not cache.has(name):
                cache[name] = load(ROOT + "tiles/" + name + ".png")
            var s := Sprite2D.new()
            s.texture = cache[name]
            s.centered = false
            s.position = Vector2(xx * TILE, yy * TILE)
            s.z_index = -10
            add_child(s)
    for item in data.props:
        var p := Sprite2D.new()
        p.texture = load(ROOT + "props/" + item.id + ".png")
        p.position = Vector2((item.cell[0]+0.5)*TILE, (item.cell[1]+0.5)*TILE)
        p.z_index = int(p.position.y/128.0)
        add_child(p)
        if item.solid:
            var body := StaticBody2D.new()
            var shape := CollisionShape2D.new()
            var rect := RectangleShape2D.new()
            rect.size = Vector2(70, 50)
            shape.shape = rect
            body.add_child(shape)
            body.position = p.position + Vector2(0,25)
            add_child(body)
