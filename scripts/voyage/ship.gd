class_name Ship
extends Node2D
## The airship: a painted hull and striped balloon plus the decks the crew runs around on.

const DECK_Y := 520.0
## Part of the hull that floating rocks can crash into.
const HULL_RECT := Rect2(140, 470, 1080, 180)

const WOOD := Color("#b9774b")
const WOOD_DARK := Color("#8a5436")
const WOOD_LIGHT := Color("#dca46e")
const GOLD := Color("#ffd27a")
const STRIPE_A := Color("#fff4e6")
const STRIPE_B := Color("#ff8e8e")
## Glitch lantern (CC0, see assets/art/CREDITS.md), hung under the decks.
const LANTERN := preload("res://assets/art/props/lantern.png")
const BALLOON_CENTER := Vector2(655, 170)
const HULL := [Vector2(128, 512), Vector2(1150, 512), Vector2(1228, 468), Vector2(1200, 560),
	Vector2(1095, 650), Vector2(310, 662), Vector2(170, 618), Vector2(118, 548)]

## Shapes that never change, built once: balloon shading and hull plank lines.
static var _shapes := {}

var prop_speed := 1.0
var _prop := 0.0
var _t := 0.0


func _ready() -> void:
	_solid(Rect2(150, DECK_Y, 1000, 30))    # main deck
	_solid(Rect2(470, 465, 60, 55))         # cargo crate, a step up to the crow's nest
	_solid(Rect2(138, 120, 22, 410))        # stern wall
	_solid(Rect2(1150, 120, 22, 410))       # bow wall
	_one_way(Rect2(175, 420, 255, 14))      # quarterdeck with the helm
	_one_way(Rect2(565, 400, 180, 14))      # crow's nest with the mast cannon


func _solid(r: Rect2, layer := Player.LAYER_WORLD) -> CollisionShape2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.get_center()
	body.add_child(cs)
	add_child(body)
	return cs


func _one_way(r: Rect2) -> void:
	_solid(r, Player.LAYER_ONE_WAY).one_way_collision = true


func _process(delta: float) -> void:
	_t += delta
	_prop += delta * (3.0 + 16.0 * prop_speed)
	queue_redraw()


func _draw() -> void:
	paint(self, _t, _prop)


## Paints the whole ship in its own coordinates. The menu reuses it at a smaller scale,
## and the pirate flagship reuses it with a darker palette (`pal` overrides the colours
## and the painted name).
static func paint(ci: CanvasItem, t: float, prop: float, pal := {}) -> void:
	var wood: Color = pal.get("wood", WOOD)
	var wood_dark: Color = pal.get("wood_dark", WOOD_DARK)
	var wood_light: Color = pal.get("wood_light", WOOD_LIGHT)
	var gold: Color = pal.get("gold", GOLD)
	var stripe_a: Color = pal.get("stripe_a", STRIPE_A)
	var stripe_b: Color = pal.get("stripe_b", STRIPE_B)
	var title: String = pal.get("name", "سفينة الغيوم")
	var rope := Color("#6b4a2f")
	for pair in [
		[Vector2(300, 250), Vector2(200, 420)], [Vector2(470, 285), Vector2(420, 420)],
		[Vector2(850, 285), Vector2(900, 480)], [Vector2(1010, 250), Vector2(1120, 480)],
	]:
		ci.draw_line(pair[0], pair[1], rope, 3.0, true)

	# Tail fin, then the balloon: nested ellipses of the same height make the stripes.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(260, 130), Vector2(165, 70), Vector2(190, 170),
		Vector2(165, 270), Vector2(260, 210)]), stripe_b.darkened(0.1))
	var bc := BALLOON_CENTER
	var n := 7
	for i in n:
		var k := 1.0 - float(i) / n
		ci.draw_colored_polygon(Paint.ellipse(bc, 440.0 * k, 120.0), stripe_a if i % 2 == 0 else stripe_b)
	var outline := Paint.ellipse(bc, 440.0, 120.0, 64)
	outline.append(outline[0])
	ci.draw_polyline(outline, stripe_b.darkened(0.25), 3.0, true)
	var shapes := _static_shapes()
	for band in shapes["balloon_shade"]:
		ci.draw_colored_polygon(band, Color(0.55, 0.1, 0.2, 0.07))
	ci.draw_colored_polygon(Paint.ellipse(bc + Vector2(-110, -58), 210.0, 30.0), Color(1, 1, 1, 0.28))
	ci.draw_colored_polygon(Paint.ellipse(bc + Vector2(-190, -40), 70.0, 14.0), Color(1, 1, 1, 0.3))

	var wave := sin(t * 5.0) * 5.0
	ci.draw_line(Vector2(655, 52), Vector2(655, 14), wood_dark, 3.0, true)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(656, 14), Vector2(696, 22 + wave), Vector2(656, 32)]), gold)

	# Mast and crow's nest.
	ci.draw_rect(Rect2(647, 285, 16, 235), wood_dark)
	ci.draw_line(Vector2(572, 414), Vector2(647, 470), wood_dark, 5.0, true)
	ci.draw_line(Vector2(738, 414), Vector2(663, 470), wood_dark, 5.0, true)
	ci.draw_rect(Rect2(565, 400, 180, 14), wood_light)
	ci.draw_rect(Rect2(565, 410, 180, 4), wood_dark)

	# Quarterdeck and its supports.
	ci.draw_rect(Rect2(185, 434, 10, 80), wood_dark)
	ci.draw_rect(Rect2(415, 434, 10, 80), wood_dark)
	ci.draw_rect(Rect2(175, 420, 255, 14), wood_light)
	ci.draw_rect(Rect2(175, 430, 255, 4), wood_dark)

	# Railing.
	ci.draw_line(Vector2(150, 478), Vector2(1150, 478), wood_dark, 5.0, true)
	for x in range(160, 1151, 50):
		ci.draw_line(Vector2(x, 478), Vector2(x, 512), wood_dark, 4.0, true)

	# Hull: lit from above, planked, with a darker keel band.
	var hull := PackedVector2Array(HULL)
	var hull_cols := PackedColorArray()
	for pt in hull:
		hull_cols.append(wood.lightened(0.1).lerp(wood.darkened(0.12), inverse_lerp(468.0, 662.0, pt.y)))
	ci.draw_polygon(hull, hull_cols)
	var keel := PackedVector2Array([Vector2(142, 580), Vector2(1176, 580), Vector2(1095, 650),
		Vector2(310, 662), Vector2(170, 618)])
	ci.draw_polygon(keel, PackedColorArray([wood_dark, wood_dark, wood_dark.darkened(0.25),
		wood_dark.darkened(0.25), wood_dark.darkened(0.15)]))
	for seam in shapes["planks"]:
		ci.draw_polyline(seam, Color(wood_dark.darkened(0.3), 0.45), 2.0, true)
	for grain in shapes["grain"]:
		ci.draw_polyline(grain, Color(wood_dark, 0.35), 1.5, true)
	for joint: Vector2 in shapes["joints"]:
		ci.draw_line(joint, joint + Vector2(0, 20), Color(wood_dark.darkened(0.3), 0.45), 2.0)
		ci.draw_circle(joint + Vector2(5, 5), 1.8, Color(gold, 0.7), true, -1.0, true)
		ci.draw_circle(joint + Vector2(5, 15), 1.8, Color(gold, 0.7), true, -1.0, true)
	ci.draw_line(Vector2(122, 545), Vector2(1203, 545), Color(wood_dark, 0.5), 2.0)
	ci.draw_line(Vector2(172, 615), Vector2(1134, 615), wood_dark.darkened(0.2), 2.0)
	ci.draw_rect(Rect2(128, 506, 1022, 16), wood_light)
	ci.draw_polyline(PackedVector2Array([Vector2(128, 512), Vector2(1150, 512), Vector2(1228, 468)]), gold, 6.0, true)
	ci.draw_line(Vector2(142, 580), Vector2(1176, 580), Color(gold, 0.6), 3.0)
	for x in range(330, 1100, 140):
		ci.draw_circle(Vector2(x, 548), 12.0, gold, true, -1.0, true)
		ci.draw_circle(Vector2(x, 548), 8.5, Color("#a6e4ff"), true, -1.0, true)
		ci.draw_circle(Vector2(x - 3, 545), 2.5, Color(1, 1, 1, 0.9), true, -1.0, true)
	Paint.text(ci, Vector2(700, 622), title, 22, gold)
	ci.draw_circle(Vector2(1228, 468), 7.0, gold, true, -1.0, true)

	# Cargo crate.
	ci.draw_rect(Rect2(470, 465, 60, 55), wood_light)
	ci.draw_rect(Rect2(470, 465, 60, 55), wood_dark, false, 3.0)
	ci.draw_line(Vector2(472, 467), Vector2(528, 518), wood_dark, 3.0)
	ci.draw_line(Vector2(528, 467), Vector2(472, 518), wood_dark, 3.0)

	# Lanterns under the quarterdeck and the crow's nest, with a soft flickering glow.
	for i in 4:
		var hook: Vector2 = [Vector2(205, 434), Vector2(405, 434), Vector2(585, 414), Vector2(725, 414)][i]
		var glow := 0.16 + 0.05 * sin(t * 7.0 + i * 1.7)
		ci.draw_circle(hook + Vector2(0, 38), 24.0, Color(1.0, 0.8, 0.3, glow * 0.6), true, -1.0, true)
		ci.draw_circle(hook + Vector2(0, 38), 13.0, Color(1.0, 0.85, 0.4, glow), true, -1.0, true)
		ci.draw_texture(LANTERN, hook + Vector2(-LANTERN.get_width() * 0.5, 0))

	# Propeller: the blades foreshorten as they spin.
	ci.draw_line(Vector2(118, 560), Vector2(94, 560), Color("#6f7389"), 6.0)
	for k in 2:
		var l := 46.0 * cos(prop + k * PI * 0.5)
		ci.draw_line(Vector2(90, 560 - l), Vector2(90, 560 + l), Color("#ece4d4"), 9.0, true)
	ci.draw_circle(Vector2(90, 560), 7.0, gold, true, -1.0, true)


static func _static_shapes() -> Dictionary:
	if not _shapes.is_empty():
		return _shapes
	var balloon := Paint.ellipse(BALLOON_CENTER, 440.0, 120.0, 64)
	var shade: Array = []
	# Two overlapping crescents along the underside give the balloon its roundness.
	for off in [Vector2(0, 55), Vector2(0, 85)]:
		shade.append_array(Geometry2D.intersect_polygons(balloon, Paint.ellipse(BALLOON_CENTER + off, 470.0, 120.0, 64)))
	var hull := PackedVector2Array(HULL)
	var planks: Array = []
	var grain: Array = []
	for y in [528.0, 562.0, 598.0, 632.0]:
		for part in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([Vector2(0, y), Vector2(1400, y)]), hull):
			planks.append(part)
	var joints: Array = []
	var row := 0
	for y in [528.0, 562.0, 598.0]:
		var x := 240.0 + row * 110.0
		while x < 1120.0:
			if Geometry2D.is_point_in_polygon(Vector2(x, y + 10.0), hull):
				joints.append(Vector2(x, y + 7.0))
			x += 260.0
		row += 1
	# A few long, gently wavy grain lines inside the planks.
	for i in 9:
		var y := 518.0 + i * 15.0 + 4.0 * sin(i * 2.3)
		var line := PackedVector2Array()
		var x0 := 200.0 + fposmod(i * 173.0, 320.0)
		for k in 12:
			var x := x0 + k * 45.0
			line.append(Vector2(x, y + 2.0 * sin(x * 0.02 + i)))
		for part in Geometry2D.intersect_polyline_with_polygon(line, hull):
			grain.append(part)
	_shapes = {"balloon_shade": shade, "planks": planks, "grain": grain, "joints": joints}
	return _shapes
