class_name SkyBackdrop
extends Node2D
## Painted sky backdrop: gradient, glowing sun, distant peaks, floating islands and
## parallax clouds. The clouds, islands and peaks are hand-drawn art from the game Glitch
## (CC0, see assets/art/CREDITS.md), tinted to match each scene's colours.
## Put it inside a CanvasLayer so it always fills the screen.

const LAYERS := [
	{"factor": 0.12, "mix": 0.45, "scale": 0.5, "y_min": 0.08, "y_max": 0.5, "count": 7},
	{"factor": 0.3, "mix": 0.72, "scale": 0.8, "y_min": 0.25, "y_max": 0.8, "count": 6},
	{"factor": 0.65, "mix": 0.95, "scale": 1.15, "y_min": 0.55, "y_max": 1.05, "count": 5},
]
## Far clouds are flat, stylised shapes; nearer ones are soft and fluffy.
const FAR_CLOUDS := [
	preload("res://assets/art/sky/cloud_far_1.png"), preload("res://assets/art/sky/cloud_far_2.png"),
	preload("res://assets/art/sky/cloud_far_3.png"), preload("res://assets/art/sky/cloud_far_4.png"),
]
const SOFT_CLOUDS := [preload("res://assets/art/sky/cloud_soft_1.png"), preload("res://assets/art/sky/cloud_soft_2.png")]
const ISLANDS := [
	preload("res://assets/art/sky/island_1.png"), preload("res://assets/art/sky/island_2.png"),
	preload("res://assets/art/sky/island_3.png"),
]
const PEAKS := [preload("res://assets/art/sky/peaks_1.png"), preload("res://assets/art/sky/peaks_2.png")]
## Extra room past the screen edges so wide clouds wrap around out of sight.
const WRAP_MARGIN := 500.0

var top_color := Color("#5ba8ff")
var bottom_color := Color("#ffe4ef")
var sun_color := Color("#fff6c9")
## Sun position as a fraction of the screen.
var sun_pos := Vector2(0.8, 0.2)
var cloud_color := Color.WHITE
var stars := false
## Soft shafts of light fanning out from the sun (drawn additively).
var sun_rays := true
var far_islands := true
var scroll_speed := 14.0
## Camera offset used for parallax.
var parallax := Vector2.ZERO
var scroll := 0.0

var _clouds: Array[Dictionary] = []
var _islands: Array[Dictionary] = []
var _peaks: Array[Dictionary] = []
var _stars := PackedVector3Array()
var _t := 0.0
var _light: Node2D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240611
	for li in LAYERS.size():
		var layer: Dictionary = LAYERS[li]
		for i in int(layer["count"]):
			var far := li == 0
			var textures: Array = FAR_CLOUDS if far else SOFT_CLOUDS
			_clouds.append({
				"layer": li,
				"x": rng.randf_range(0.0, 2400.0),
				"y": rng.randf_range(layer["y_min"], layer["y_max"]),
				"tex": textures[rng.randi() % textures.size()],
				"size": rng.randf_range(0.8, 1.25) * (0.7 if far else 1.0),
				"flip": rng.randf() < 0.5,
			})
	for i in 4:
		_islands.append({"x": rng.randf_range(0.0, 2400.0), "y": rng.randf_range(0.35, 0.6),
			"tex": ISLANDS[i % ISLANDS.size()], "size": rng.randf_range(0.16, 0.28), "flip": rng.randf() < 0.5})
	for i in 3:
		_peaks.append({"x": i * 820.0 + rng.randf_range(0.0, 200.0), "tex": PEAKS[i % PEAKS.size()],
			"size": rng.randf_range(0.9, 1.1)})
	_light = Node2D.new()
	_light.material = Fx.additive()
	_light.draw.connect(_draw_light)
	add_child(_light)
	for i in 70:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.55, rng.randf() * TAU))


func _process(delta: float) -> void:
	_t += delta
	scroll += scroll_speed * delta
	queue_redraw()
	_light.queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)]),
		PackedColorArray([top_color, top_color, bottom_color, bottom_color]))

	if stars:
		for st: Vector3 in _stars:
			var a := 0.35 + 0.35 * sin(_t * 2.0 + st.z)
			draw_circle(Vector2(st.x * s.x, st.y * s.y), 1.6, Color(1, 1, 1, a), true, -1.0, true)

	var sp := _sun_position()
	for i in 6:
		draw_circle(sp, 70.0 + i * 30.0, Color(sun_color, 0.09 - i * 0.013), true, -1.0, true)
	draw_circle(sp, 58.0, sun_color, true, -1.0, true)

	var period := s.x + WRAP_MARGIN * 2.0
	if far_islands:
		# Snowy peaks far below, faded into the haze near the horizon.
		var haze := Color(top_color.lerp(bottom_color, 0.75), 0.5)
		for pk in _peaks:
			var x: float = fposmod(pk["x"] - (scroll + parallax.x) * 0.03, period) - WRAP_MARGIN
			var tex: Texture2D = pk["tex"]
			_sprite(tex, Vector2(x, s.y * 0.93 - parallax.y * 0.03 - tex.get_height() * 0.3), pk["size"], false, haze)
		# Far away, so mostly see-through and tinted by the sky.
		var ic := Color(top_color.lerp(bottom_color, 0.55).lerp(Color.WHITE, 0.4), 0.55)
		for isl in _islands:
			var x: float = fposmod(isl["x"] - (scroll + parallax.x) * 0.06, period) - WRAP_MARGIN
			var y: float = isl["y"] * s.y - parallax.y * 0.05
			_sprite(isl["tex"], Vector2(x, y), isl["size"], isl["flip"], ic)

	# Haze thickening towards the horizon, so far things melt into the sky.
	var haze_top := s.y * 0.45
	draw_polygon(PackedVector2Array([Vector2(0, haze_top), Vector2(s.x, haze_top), s, Vector2(0, s.y)]),
		PackedColorArray([Color(bottom_color, 0.0), Color(bottom_color, 0.0), Color(bottom_color, 0.55), Color(bottom_color, 0.55)]))

	for c in _clouds:
		var layer: Dictionary = LAYERS[c["layer"]]
		var f: float = layer["factor"]
		var x: float = fposmod(c["x"] - (scroll + parallax.x) * f, period) - WRAP_MARGIN
		var y: float = c["y"] * s.y - parallax.y * f * 0.6
		# The cloud art is a soft grey-white; lift it so clouds read as bright white.
		# Nearer layers are a little more see-through so text in front of them stays readable.
		var col := bottom_color.lerp(cloud_color, layer["mix"]) * Color(1.25, 1.25, 1.25, 0.95 - c["layer"] * 0.1)
		_sprite(c["tex"], Vector2(x, y), layer["scale"] * c["size"], c["flip"], col)


## Draws `tex` centred on `pos`, scaled, optionally mirrored and tinted.
func _sprite(tex: Texture2D, pos: Vector2, sc: float, flip: bool, tint: Color) -> void:
	draw_set_transform(pos, 0.0, Vector2(-sc if flip else sc, sc))
	draw_texture(tex, -tex.get_size() * 0.5, tint)
	draw_set_transform(Vector2.ZERO)


func _sun_position() -> Vector2:
	var s := get_viewport_rect().size
	return Vector2(s.x * sun_pos.x, s.y * sun_pos.y) - parallax * 0.02


## Additive light: a wide glow around the sun and slowly breathing light shafts.
func _draw_light() -> void:
	var s := get_viewport_rect().size
	var sp := _sun_position()
	var soft := Fx.soft_texture()
	var halo := 340.0 * (1.0 + 0.03 * sin(_t * 0.8))
	_light.draw_texture_rect(soft, Rect2(sp - Vector2.ONE * halo, Vector2.ONE * halo * 2.0), false, Color(sun_color, 0.1))
	_light.draw_texture_rect(soft, Rect2(sp - Vector2.ONE * 150.0, Vector2.ONE * 300.0), false, Color(sun_color, 0.12))
	if not sun_rays:
		return
	# Shafts point away from the sun, towards the middle of the screen.
	var towards := (Vector2(s.x * 0.5, s.y * 0.9) - sp).angle()
	for i in 7:
		var a := towards + (i - 3) * 0.22 + sin(_t * 0.13 + i * 1.9) * 0.05
		var dir := Vector2.from_angle(a)
		var side := Vector2(-dir.y, dir.x)
		var length := s.length() * (0.75 + 0.2 * sin(i * 2.7))
		var w0 := 10.0 + 6.0 * sin(i * 1.3)
		var w1 := 90.0 + 50.0 * sin(i * 3.1 + 1.0)
		var alpha := (0.05 + 0.025 * sin(_t * 0.5 + i * 1.7)) * (1.0 if i % 2 == 0 else 0.6)
		var near := sp + dir * 40.0
		var far := sp + dir * length
		_light.draw_polygon(PackedVector2Array([near - side * w0, near + side * w0, far + side * w1, far - side * w1]),
			PackedColorArray([Color(sun_color, alpha), Color(sun_color, alpha), Color(sun_color, 0.0), Color(sun_color, 0.0)]))
