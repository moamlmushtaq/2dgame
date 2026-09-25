class_name MovingCloud
extends AnimatableBody2D
## A fluffy cloud platform drifting back and forth. You can jump up through it, and
## down + jump drops through it. The origin is the centre of its top surface.

var from_x := 0.0
var to_x := 0.0
var period := 5.0
var phase := 0.0
var width := 120.0
var _t := 0.0


func _ready() -> void:
	collision_layer = Player.LAYER_ONE_WAY
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(width, 14)
	cs.shape = r
	cs.position = Vector2(0, 7)
	cs.one_way_collision = true
	add_child(cs)
	z_index = 1


func _physics_process(delta: float) -> void:
	_t += delta
	var k := 0.5 - 0.5 * cos(TAU * (_t / period + phase))
	position.x = lerpf(from_x, to_x, k)
	queue_redraw()


func _draw() -> void:
	# Tinted and given a face so it reads as a platform, not a background cloud.
	var shade := Color("#b9b0ec")
	var body := Color("#f6f3ff")
	for p: Vector3 in [Vector3(-40, 12, 20), Vector3(0, 14, 24), Vector3(40, 12, 20)]:
		draw_circle(Vector2(p.x, p.y + 6.0), p.z, shade, true, -1.0, true)
	for p: Vector3 in [Vector3(-44, 8, 18), Vector3(-18, 2, 24), Vector3(14, 0, 26), Vector3(44, 8, 18)]:
		draw_circle(Vector2(p.x, p.y), p.z, body, true, -1.0, true)
	draw_style_box(Paint.box(body, 10), Rect2(-width * 0.5, 0, width, 20))
	draw_line(Vector2(-width * 0.5 + 6.0, 0), Vector2(width * 0.5 - 6.0, 0), Color(1, 1, 1, 0.9), 3.0)
	var ink := Color("#4a3f6b")
	var blink := fmod(_t + phase * 3.0, 4.0) < 0.12
	for side: int in [-1, 1]:
		var e := Vector2(side * 13.0, 10.0)
		if blink:
			draw_line(e + Vector2(-3, 0), e + Vector2(3, 0), ink, 2.0, true)
		else:
			draw_circle(e, 3.2, ink, true, -1.0, true)
			draw_circle(e + Vector2(-1, -1), 1.0, Color.WHITE, true, -1.0, true)
		draw_circle(Vector2(side * 22.0, 15.0), 3.5, Color(1, 0.6, 0.7, 0.6), true, -1.0, true)
	draw_arc(Vector2(0, 13), 4.0, 0.3, PI - 0.3, 8, ink, 2.0, true)
