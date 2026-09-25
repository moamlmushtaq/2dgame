class_name IslandTerrain
extends Node2D
## Floating landmasses: rectangle colliders plus painted grassy tops, rocky roots,
## blossom trees, flowers and a waterfall.
##
## A landmass is a list of Vector3(x_start, x_end, top_y) segments laid left to right.

var grass := Color("#69c96b")
var grass_light := Color("#9be58c")
var dirt := Color("#a8704f")
var rock := Color("#7a4a3a")

var _lands: Array[Dictionary] = []
var _trees: Array[Vector4] = []
var _flowers: Array[Vector3] = []
var _waterfalls: Array[Vector2] = []
var _t := 0.0


func add_land(segs: Array) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Player.LAYER_WORLD
	body.collision_mask = 0
	for seg: Vector3 in segs:
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(seg.y - seg.x, 300)
		cs.shape = r
		cs.position = Vector2((seg.x + seg.y) * 0.5, seg.z + 150.0)
		body.add_child(cs)
	add_child(body)

	var top := PackedVector2Array()
	var lowest := -INF
	for seg: Vector3 in segs:
		top.append(Vector2(seg.x, seg.z))
		top.append(Vector2(seg.y, seg.z))
		lowest = maxf(lowest, seg.z)
	var x0: float = segs[0].x
	var x1: float = segs[-1].y
	var w := x1 - x0
	var base_y := lowest + 90.0
	var depth := minf(w * 0.32, 420.0)
	var steps := 10
	for i in steps + 1:
		var f := 1.0 - float(i) / steps
		top.append(Vector2(x0 + w * f, base_y + sin(f * PI) * depth * (0.82 + 0.18 * sin(i * 2.3))))
	_lands.append({"segs": segs, "poly": top, "base": base_y, "depth": depth, "x0": x0, "x1": x1})

	var rng := RandomNumberGenerator.new()
	rng.seed = int(x0 * 7.0 + 13.0)
	for seg: Vector3 in segs:
		var x := seg.x + 20.0
		while x < seg.y - 20.0:
			_flowers.append(Vector3(x, seg.z, rng.randi_range(0, 4)))
			x += rng.randf_range(40.0, 90.0)


## Invisible wall so nobody walks off the edge of the world.
func add_wall(r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Player.LAYER_WORLD
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.get_center()
	body.add_child(cs)
	add_child(body)


## kind: 0 = pink blossom tree, 1 = round green tree, 2 = lavender tree.
func add_tree(pos: Vector2, kind: int, scale_amount := 1.0) -> void:
	_trees.append(Vector4(pos.x, pos.y, kind, scale_amount))


func add_waterfall(top: Vector2) -> void:
	_waterfalls.append(top)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for wf in _waterfalls:
		_draw_waterfall(wf)
	for land in _lands:
		_draw_land(land)
	for tree in _trees:
		_draw_tree(tree)
	for fl in _flowers:
		_draw_flower(fl)


func _draw_land(land: Dictionary) -> void:
	var poly: PackedVector2Array = land["poly"]
	draw_colored_polygon(poly, rock)
	# Rock strata on the underside, kept inside its tapering outline.
	var base: float = land["base"]
	var depth: float = land["depth"]
	var x0: float = land["x0"]
	var x1: float = land["x1"]
	for i in 3:
		var dy := 40.0 + i * 55.0
		var f := asin(clampf(dy / (depth * 0.8), 0.0, 1.0)) / PI
		var a := x0 + (x1 - x0) * f + 30.0
		var b := x1 - (x1 - x0) * f - 30.0
		if b - a > 40.0:
			draw_line(Vector2(a, base + dy), Vector2(b, base + dy + 6.0), rock.darkened(0.2), 4.0, true)
	for seg: Vector3 in land["segs"]:
		var w := seg.y - seg.x
		draw_rect(Rect2(seg.x, seg.z, w, 70.0), dirt)
		draw_rect(Rect2(seg.x, seg.z + 64.0, w, 6.0), dirt.darkened(0.15))
	for seg: Vector3 in land["segs"]:
		var w := seg.y - seg.x
		var x := seg.x + 6.0
		while x < seg.y - 4.0:
			draw_circle(Vector2(x, seg.z + 12.0), 8.0, grass, true, -1.0, true)
			x += 22.0
		draw_style_box(Paint.box(grass, 10), Rect2(seg.x - 8.0, seg.z - 10.0, w + 16.0, 24.0))
		draw_style_box(Paint.box(grass_light, 5), Rect2(seg.x - 4.0, seg.z - 10.0, w + 8.0, 7.0))


func _draw_tree(tree: Vector4) -> void:
	var base := Vector2(tree.x, tree.y)
	var s := tree.w
	var sway := sin(_t * 1.3 + tree.x * 0.01) * 2.0 * s
	var trunk := Color("#8a5a3c")
	draw_colored_polygon(PackedVector2Array([base + Vector2(-7, 0) * s, base + Vector2(7, 0) * s,
		base + Vector2(4 + sway, -70) * s, base + Vector2(-4 + sway, -70) * s]), trunk)
	var lights := [Color("#ffc3d8"), Color("#7fdc8f"), Color("#d4c4ff")]
	var darks := [Color("#f59bbd"), Color("#56b872"), Color("#a98cf0")]
	var light: Color = lights[int(tree.z)]
	var dark: Color = darks[int(tree.z)]
	var puffs := [Vector3(0, -86, 34), Vector3(-30, -70, 26), Vector3(30, -70, 26), Vector3(-16, -108, 24), Vector3(18, -106, 24)]
	for p: Vector3 in puffs:
		draw_circle(base + (Vector2(p.x + sway, p.y + 6.0)) * s, p.z * s, dark, true, -1.0, true)
	for p: Vector3 in puffs:
		draw_circle(base + Vector2(p.x + sway, p.y) * s, p.z * s * 0.92, light, true, -1.0, true)
	if tree.z == 0.0:
		for i in 6:
			var a := i * 1.7 + tree.x
			var fall := fposmod(_t * 18.0 + i * 23.0, 120.0)
			var petal := base + Vector2(cos(a) * 40.0 * s + sin(_t + i) * 8.0, -60.0 * s + fall)
			draw_circle(petal, 2.5, Color("#ffd6e4", 1.0 - fall / 120.0), true, -1.0, true)


func _draw_flower(fl: Vector3) -> void:
	var colors := [Color("#ff8fa3"), Color("#ffd35c"), Color("#b69cff"), Color("#ffffff"), Color("#7fd6ff")]
	var base := Vector2(fl.x, fl.y - 8.0)
	var sway := sin(_t * 2.0 + fl.x) * 2.0
	var head := base + Vector2(sway, -12)
	draw_line(base, head, Color("#4fa85a"), 2.0, true)
	var col: Color = colors[int(fl.z)]
	for i in 5:
		draw_circle(head + Vector2.from_angle(i * TAU / 5.0) * 4.0, 3.0, col, true, -1.0, true)
	draw_circle(head, 2.2, Color("#ffb347"), true, -1.0, true)


func _draw_waterfall(top: Vector2) -> void:
	var h := 700.0
	draw_rect(Rect2(top.x - 14.0, top.y, 28, h), Color(0.75, 0.92, 1.0, 0.55))
	for i in 4:
		var y := fposmod(_t * 260.0 + i * 170.0, h)
		draw_line(Vector2(top.x - 8.0 + i * 5.0, top.y + y), Vector2(top.x - 8.0 + i * 5.0, top.y + minf(y + 60.0, h)), Color(1, 1, 1, 0.7), 3.0)
	for i in 5:
		var r := 10.0 + fposmod(_t * 20.0 + i * 7.0, 14.0)
		draw_circle(top + Vector2(-16.0 + i * 8.0, -4.0), r * 0.5, Color(1, 1, 1, 0.5), true, -1.0, true)
