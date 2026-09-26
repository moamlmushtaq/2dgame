class_name Foreground
extends CanvasLayer
## A layer in front of the gameplay that sells depth, the way Ori frames its scenes:
##   "clouds":      big soft cloud wisps rushing past the ship's edges (voyage).
##   "silhouettes": dark foliage along the bottom edge, sliding faster than the camera
##                  (islands), set up with add_silhouettes() over the level's width.

const PLANTS := [
	preload("res://assets/art/island/bush_1.png"), preload("res://assets/art/island/bush_2.png"),
	preload("res://assets/art/island/grass_1.png"), preload("res://assets/art/island/grass_2.png"),
	preload("res://assets/art/island/bush_3.png"),
]
## How much faster than the camera the foreground slides.
const PARALLAX := 1.4

var mode := "clouds"
## Multiplies how fast the cloud wisps rush past.
var speed_scale := 1.0
var tint := Color(0.12, 0.08, 0.2, 0.92)

var _canvas: Node2D
var _wisps: Array[Dictionary] = []
var _plants: Array[Dictionary] = []


func _init(kind := "clouds") -> void:
	layer = 3
	mode = kind


func _ready() -> void:
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_layer)
	add_child(_canvas)
	if mode == "clouds":
		for i in 5:
			_wisps.append(_new_wisp(randf() * 1800.0))


## Scatters silhouettes along the level from x0 to x1 (world coordinates).
func add_silhouettes(x0: float, x1: float) -> void:
	var x := x0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	while x < x1:
		_plants.append({"x": x, "tex": PLANTS[rng.randi() % PLANTS.size()], "scale": rng.randf_range(1.5, 2.2),
			"flip": rng.randf() < 0.5, "drop": rng.randf_range(20.0, 60.0)})
		x += rng.randf_range(260.0, 620.0)


func _new_wisp(x: float) -> Dictionary:
	var s := _size()
	var low := randf() < 0.7
	return {"x": x, "y": s.y * randf_range(0.97, 1.1) if low else s.y * randf_range(-0.12, -0.03),
		"tex": SkyBackdrop.SOFT_CLOUDS[randi() % SkyBackdrop.SOFT_CLOUDS.size()], "scale": randf_range(1.8, 2.8),
		"speed": randf_range(380.0, 620.0), "a": randf_range(0.18, 0.32)}


func _size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _process(delta: float) -> void:
	for w in _wisps:
		w["x"] = float(w["x"]) - float(w["speed"]) * speed_scale * delta
		var tex: Texture2D = w["tex"]
		if float(w["x"]) + tex.get_width() * float(w["scale"]) * 0.5 < 0.0:
			w.merge(_new_wisp(_size().x + tex.get_width() * 2.0 + randf() * 900.0), true)
	_canvas.queue_redraw()


func _draw_layer() -> void:
	var s := _size()
	for w in _wisps:
		var tex: Texture2D = w["tex"]
		var sc: float = w["scale"]
		_canvas.draw_set_transform(Vector2(w["x"], w["y"]), 0.0, Vector2(sc, sc * 0.8))
		_canvas.draw_texture(tex, -tex.get_size() * 0.5, Color(1.3, 1.3, 1.35, float(w["a"])))
		_canvas.draw_set_transform(Vector2.ZERO)
	if _plants.is_empty():
		return
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x if cam != null else s.x * 0.5
	for pl in _plants:
		var x := (float(pl["x"]) - cx) * PARALLAX + s.x * 0.5
		var tex: Texture2D = pl["tex"]
		var sc: float = pl["scale"]
		if x < -tex.get_width() * sc or x > s.x + tex.get_width() * sc:
			continue
		_canvas.draw_set_transform(Vector2(x, s.y + float(pl["drop"])), 0.0, Vector2(-sc if pl["flip"] else sc, sc))
		_canvas.draw_texture(tex, Vector2(-tex.get_width() * 0.5, -tex.get_height()), tint)
		_canvas.draw_set_transform(Vector2.ZERO)
