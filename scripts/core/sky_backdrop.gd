class_name SkyBackdrop
extends Node2D
## Painted sky backdrop: gradient, glowing sun, far islands and parallax clouds.
## Put it inside a CanvasLayer so it always fills the screen.

const LAYERS := [
	{"factor": 0.12, "mix": 0.45, "scale": 0.55, "y_min": 0.08, "y_max": 0.5, "count": 7},
	{"factor": 0.3, "mix": 0.72, "scale": 0.8, "y_min": 0.25, "y_max": 0.8, "count": 6},
	{"factor": 0.65, "mix": 0.95, "scale": 1.1, "y_min": 0.55, "y_max": 1.05, "count": 5},
]

var top_color := Color("#5ba8ff")
var bottom_color := Color("#ffe4ef")
var sun_color := Color("#fff6c9")
## Sun position as a fraction of the screen.
var sun_pos := Vector2(0.8, 0.2)
var cloud_color := Color.WHITE
var stars := false
var far_islands := true
var scroll_speed := 14.0
## Camera offset used for parallax.
var parallax := Vector2.ZERO
var scroll := 0.0

var _clouds: Array[Dictionary] = []
var _islands: Array[Dictionary] = []
var _stars := PackedVector3Array()
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240611
	for li in LAYERS.size():
		var layer: Dictionary = LAYERS[li]
		for i in int(layer["count"]):
			var puffs: Array[Vector3] = []
			var n := rng.randi_range(4, 7)
			var width := rng.randf_range(110.0, 220.0)
			for k in n:
				var f := float(k) / float(n - 1)
				var bump := sin(f * PI)
				puffs.append(Vector3((f - 0.5) * width, -bump * rng.randf_range(14.0, 34.0),
					rng.randf_range(24.0, 36.0) * (0.65 + bump * 0.55)))
			_clouds.append({
				"layer": li,
				"x": rng.randf_range(0.0, 2200.0),
				"y": rng.randf_range(layer["y_min"], layer["y_max"]),
				"puffs": puffs,
			})
	for i in 4:
		_islands.append({"x": rng.randf_range(0.0, 2200.0), "y": rng.randf_range(0.35, 0.6), "w": rng.randf_range(90.0, 180.0)})
	for i in 70:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.55, rng.randf() * TAU))


func _process(delta: float) -> void:
	_t += delta
	scroll += scroll_speed * delta
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
		PackedColorArray([top_color, top_color, bottom_color, bottom_color]))

	if stars:
		for st: Vector3 in _stars:
			var a := 0.35 + 0.35 * sin(_t * 2.0 + st.z)
			draw_circle(Vector2(st.x * s.x, st.y * s.y), 1.6, Color(1, 1, 1, a), true, -1.0, true)

	var sp := Vector2(s.x * sun_pos.x, s.y * sun_pos.y) - parallax * 0.02
	for i in 6:
		draw_circle(sp, 70.0 + i * 30.0, Color(sun_color, 0.09 - i * 0.013), true, -1.0, true)
	draw_circle(sp, 58.0, sun_color, true, -1.0, true)

	var period := s.x + 800.0
	if far_islands:
		var ic := top_color.lerp(bottom_color, 0.55).darkened(0.05)
		for isl in _islands:
			var x: float = fposmod(isl["x"] - (scroll + parallax.x) * 0.06, period) - 400.0
			var y: float = isl["y"] * s.y - parallax.y * 0.05
			_far_island(Vector2(x, y), isl["w"], ic)

	for c in _clouds:
		var layer: Dictionary = LAYERS[c["layer"]]
		var f: float = layer["factor"]
		var x: float = fposmod(c["x"] - (scroll + parallax.x) * f, period) - 400.0
		var y: float = c["y"] * s.y - parallax.y * f * 0.6
		_cloud(Vector2(x, y), c["puffs"], layer["scale"], bottom_color.lerp(cloud_color, layer["mix"]))


func _cloud(pos: Vector2, puffs: Array, sc: float, col: Color) -> void:
	var shade := col.darkened(0.1)
	for p: Vector3 in puffs:
		draw_circle(pos + Vector2(p.x, p.y + 7.0) * sc, p.z * sc, shade, true, -1.0, true)
	for p: Vector3 in puffs:
		draw_circle(pos + Vector2(p.x, p.y) * sc, p.z * sc, col, true, -1.0, true)
	var shine := col.lightened(0.2)
	for p: Vector3 in puffs:
		draw_circle(pos + Vector2(p.x - p.z * 0.25, p.y - p.z * 0.3) * sc, p.z * 0.45 * sc, shine, true, -1.0, true)


func _far_island(pos: Vector2, w: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-w * 0.5, 0), pos + Vector2(w * 0.5, 0), pos + Vector2(w * 0.3, w * 0.25),
		pos + Vector2(w * 0.05, w * 0.55), pos + Vector2(-w * 0.2, w * 0.3),
	]), col)
	var grass := col.lerp(Color("#7fd18b"), 0.35)
	draw_rect(Rect2(pos.x - w * 0.5, pos.y - 5.0, w, 7.0), grass)
	draw_circle(pos + Vector2(-w * 0.15, -14.0), 10.0, grass, true, -1.0, true)
	draw_circle(pos + Vector2(w * 0.2, -10.0), 7.0, grass, true, -1.0, true)
