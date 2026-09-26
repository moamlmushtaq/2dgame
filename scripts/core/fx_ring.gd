class_name FxRing
extends Node2D
## An expanding, fading shockwave ring (see Fx.ring). Frees itself when done.

var radius := 60.0
var color := Color.WHITE
var lifetime := 0.45
var width := 6.0
var _t := 0.0


func _ready() -> void:
	z_index = 31
	material = Fx.additive()


func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / lifetime
	var ease_out := 1.0 - pow(1.0 - k, 3.0)
	var r := radius * (0.2 + 0.8 * ease_out)
	var a := color.a * (1.0 - k)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(color, a), width * (1.0 - k * 0.7), true)
	draw_arc(Vector2.ZERO, r * 0.92, 0.0, TAU, 48, Color(color, a * 0.35), width * 2.0 * (1.0 - k), true)
