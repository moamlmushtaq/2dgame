class_name Ambient
extends CanvasLayer
## Life in the air, drawn over the world: glowing motes and fireflies that drift and
## twinkle, wind streaks rushing past the ship, and falling petals. Screen-space, with
## parallax against the camera so near motes slide faster than far ones.
##
##   motes:   {"count", "color", "drift": Vector2, "size": Vector2(min, max)}
##   streaks: number of wind lines (voyage)
##   petals:  number of falling petals (Blossom Isle)

var motes := {}
var streaks := 0
var petals := 0
## Multiplies the wind streaks' speed (the voyage sets it from the ship's speed).
var speed_scale := 1.0

var _glow_layer: Node2D
var _plain_layer: Node2D
var _motes: Array[Dictionary] = []
var _streaks: Array[Dictionary] = []
var _petals: Array[Dictionary] = []
var _cam_last := Vector2.ZERO
var _t := 0.0


func _init(config := {}) -> void:
	layer = 1
	motes = config.get("motes", {})
	streaks = config.get("streaks", 0)
	petals = config.get("petals", 0)


func _ready() -> void:
	_plain_layer = Node2D.new()
	_plain_layer.draw.connect(_draw_plain)
	add_child(_plain_layer)
	_glow_layer = Node2D.new()
	_glow_layer.material = Fx.additive()
	_glow_layer.draw.connect(_draw_glow)
	add_child(_glow_layer)
	var s := _size()
	for i in int(motes.get("count", 0)):
		_motes.append(_new_mote(Vector2(randf() * s.x, randf() * s.y)))
	for i in streaks:
		_streaks.append(_new_streak(randf() * s.x))
	for i in petals:
		_petals.append(_new_petal(Vector2(randf() * s.x, randf() * s.y)))
	_cam_last = _camera_center()


func _size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _camera_center() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	return cam.get_screen_center_position() if cam != null else Vector2.ZERO


func _new_mote(pos: Vector2) -> Dictionary:
	var sz: Vector2 = motes.get("size", Vector2(2.0, 5.0))
	return {"pos": pos, "depth": randf_range(0.3, 1.3), "r": randf_range(sz.x, sz.y),
		"phase": randf() * TAU, "wobble": randf_range(8.0, 22.0), "speed": randf_range(0.6, 1.4)}


func _new_streak(x: float) -> Dictionary:
	return {"x": x, "y": randf() * _size().y, "len": randf_range(70.0, 220.0),
		"speed": randf_range(900.0, 1500.0), "a": randf_range(0.12, 0.3)}


func _new_petal(pos: Vector2) -> Dictionary:
	return {"pos": pos, "spin": randf() * TAU, "rate": randf_range(-3.0, 3.0), "phase": randf() * TAU,
		"fall": randf_range(35.0, 70.0), "size": randf_range(3.0, 5.0)}


func _process(delta: float) -> void:
	_t += delta
	var s := _size()
	var cam := _camera_center()
	var cam_move := cam - _cam_last
	_cam_last = cam
	var drift: Vector2 = motes.get("drift", Vector2(-8.0, -12.0))
	var margin := 30.0
	for m in _motes:
		var p: Vector2 = m["pos"]
		p += drift * float(m["speed"]) * delta - cam_move * float(m["depth"])
		p.x += cos(_t * 0.7 + float(m["phase"])) * float(m["wobble"]) * delta
		p.x = fposmod(p.x + margin, s.x + margin * 2.0) - margin
		p.y = fposmod(p.y + margin, s.y + margin * 2.0) - margin
		m["pos"] = p
	for st in _streaks:
		st["x"] = float(st["x"]) - float(st["speed"]) * speed_scale * delta
		if float(st["x"]) + float(st["len"]) < 0.0:
			var fresh := _new_streak(s.x + randf() * 300.0)
			st.merge(fresh, true)
	for pt in _petals:
		var p: Vector2 = pt["pos"]
		p += Vector2(-20.0 + sin(_t * 1.5 + float(pt["phase"])) * 30.0, float(pt["fall"])) * delta - cam_move * 0.9
		pt["spin"] = float(pt["spin"]) + float(pt["rate"]) * delta
		p.x = fposmod(p.x + margin, s.x + margin * 2.0) - margin
		p.y = fposmod(p.y + margin, s.y + margin * 2.0) - margin
		pt["pos"] = p
	_glow_layer.queue_redraw()
	_plain_layer.queue_redraw()


func _draw_glow() -> void:
	if _motes.is_empty():
		return
	var tex := Fx.soft_texture()
	var col: Color = motes.get("color", Color(1.0, 0.95, 0.75))
	# Low graphics quality draws a third of the motes.
	var step := 1 if Game.settings.get("fancy", true) else 3
	for mi in range(0, _motes.size(), step):
		var m: Dictionary = _motes[mi]
		var twinkle := 0.55 + 0.45 * sin(_t * 2.2 * float(m["speed"]) + float(m["phase"]))
		var r: float = m["r"] * (0.7 + 0.6 * float(m["depth"]))
		var a := col.a * twinkle * clampf(float(m["depth"]), 0.35, 1.0)
		_glow_layer.draw_texture_rect(tex, Rect2(m["pos"] - Vector2.ONE * r * 3.0, Vector2.ONE * r * 6.0), false, Color(col, a * 0.5))
		_glow_layer.draw_circle(m["pos"], r * 0.45, Color(col.lightened(0.5), a), true, -1.0, true)


func _draw_plain() -> void:
	for st in _streaks:
		var x: float = st["x"]
		var y: float = st["y"]
		var l: float = st["len"]
		var a: float = st["a"]
		_plain_layer.draw_polygon(PackedVector2Array([Vector2(x, y - 1.2), Vector2(x + l, y - 0.4), Vector2(x + l, y + 0.4), Vector2(x, y + 1.2)]),
			PackedColorArray([Color(1, 1, 1, a), Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, a)]))
	for pt in _petals:
		var c: Vector2 = pt["pos"]
		var sz: float = pt["size"]
		var spin: float = pt["spin"]
		var squash := absf(cos(spin * 0.7))  # flips as it tumbles
		_plain_layer.draw_set_transform(c, spin, Vector2(1.0, 0.35 + 0.65 * squash))
		_plain_layer.draw_colored_polygon(Paint.ellipse(Vector2.ZERO, sz * 1.4, sz, 10), Color("#ffc9dc", 0.9))
		_plain_layer.draw_set_transform(Vector2.ZERO)
