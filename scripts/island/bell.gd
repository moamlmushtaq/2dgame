class_name Bell
extends Interactable
## A sky bell. A BellBridge is built when all of its bells ring at nearly the same moment.

var pitch := 1.0
var color := Color("#ffd27a")
var window := 1.2
var rung_at := -100.0
var _swing := 0.0


func _ready() -> void:
	interact_radius = 60.0
	z_index = 2


func interact_point() -> Vector2:
	return global_position + Vector2(0, -50)


func hint(_player: Player) -> String:
	return "اقرع الجرس"


func interact(_player: Player) -> void:
	rung_at = now()
	_swing = 1.0
	Sound.play("bell", -2.0, pitch, 0.0)
	Fx.burst(get_parent(), global_position + Vector2(0, -60), color, 14, 150.0, 0.4, -20.0)


## Seconds since the bell rang, or a large number if it hasn't.
func since_rung() -> float:
	return now() - rung_at


static func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	_swing = move_toward(_swing, 0.0, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	var wood := Color("#8a5436")
	Paint.ground_shadow(self, Vector2.ZERO, 42.0)
	for px: float in [-34.0, 28.0]:
		draw_rect(Rect2(px, -96, 6, 96), wood)
		draw_rect(Rect2(px, -96, 2, 96), wood.lightened(0.18))
	# A little roof over the beam.
	draw_colored_polygon(PackedVector2Array([Vector2(-44, -100), Vector2(0, -122), Vector2(44, -100)]), wood.darkened(0.15))
	draw_line(Vector2(-44, -100), Vector2(0, -122), wood.lightened(0.2), 2.0, true)
	draw_rect(Rect2(-38, -102, 76, 8), wood)
	draw_line(Vector2(-36, -101), Vector2(36, -101), wood.lightened(0.25), 1.5)
	var left := clampf(1.0 - since_rung() / window, 0.0, 1.0)
	if left > 0.0:
		draw_arc(Vector2(0, -60), 40.0, -PI * 0.5, -PI * 0.5 + TAU * left, 32, Color(color, 0.8), 4.0, true)
	draw_set_transform(Vector2(0, -94), sin(Time.get_ticks_msec() / 90.0) * 0.5 * _swing)
	draw_line(Vector2.ZERO, Vector2(0, 8), Color("#50546b"), 3.0)
	var shape := PackedVector2Array([Vector2(-8, 8), Vector2(8, 8), Vector2(14, 34), Vector2(20, 42),
		Vector2(-20, 42), Vector2(-14, 34)])
	# Metal shading: lit on the left, darker on the right and at the lip.
	draw_polygon(shape, PackedColorArray([color.lightened(0.25), color, color.darkened(0.25),
		color.darkened(0.35), color.darkened(0.05), color.lightened(0.1)]))
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 12), Vector2(-1, 12), Vector2(-5, 36), Vector2(-11, 36)]), Color(1, 1, 1, 0.45))
	draw_line(Vector2(-20, 42), Vector2(20, 42), color.darkened(0.4), 2.5, true)
	draw_circle(Vector2(0, 45), 5.0, color.darkened(0.3), true, -1.0, true)
	draw_circle(Vector2(-1.5, 43.5), 1.6, Color(1, 1, 1, 0.5), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
