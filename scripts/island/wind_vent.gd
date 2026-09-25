class_name WindVent
extends Node2D
## A vent in the ground that blows an updraft while any of its cranks is being turned.
## The origin is the vent's centre on the ground; the column rises to `top_y`.

var cranks: Array[Crank] = []
var width := 90.0
var top_y := 190.0
var powered := false
var _t := 0.0
var _power := 0.0


func _ready() -> void:
	z_index = 1


func _physics_process(delta: float) -> void:
	_t += delta
	var was := powered
	powered = false
	for c in cranks:
		powered = powered or c.turning
	if powered and not was:
		Sound.play("wind", -4.0)
	_power = move_toward(_power, 1.0 if powered else 0.0, delta * 3.0)
	if powered:
		for node in get_tree().get_nodes_in_group("players"):
			var p := node as Player
			var feet := p.global_position
			if p.is_alive() and absf(feet.x - global_position.x) < width * 0.5 \
					and feet.y <= global_position.y + 4.0 and feet.y > top_y:
				p.wind_time = 0.1
	queue_redraw()


func _draw() -> void:
	var h := global_position.y - top_y
	if _power > 0.0:
		draw_rect(Rect2(-width * 0.5, -h, width, h), Color(0.85, 0.97, 1.0, 0.12 * _power))
		for i in 7:
			var x := -width * 0.4 + i * width * 0.8 / 6.0 + sin(_t * 3.0 + i) * 4.0
			var y := -fposmod(_t * 420.0 + i * 97.0, h)
			draw_line(Vector2(x, y), Vector2(x, y - 34.0), Color(1, 1, 1, 0.6 * _power), 3.0, true)
	Paint.ground_shadow(self, Vector2(0, 3), width * 0.6, 0.15)
	draw_style_box(Paint.box(Color("#46425c"), 6), Rect2(-width * 0.5 - 6.0, -8, width + 12.0, 12))
	draw_style_box(Paint.box(Color("#5b5675"), 5), Rect2(-width * 0.5 - 5.0, -8, width + 10.0, 8))
	draw_line(Vector2(-width * 0.5, -7), Vector2(width * 0.5, -7), Color(1, 1, 1, 0.22), 1.5)
	for i in 5:
		var x := -width * 0.5 + 8.0 + i * (width - 16.0) / 4.0
		draw_line(Vector2(x, -6), Vector2(x, 2), Color("#8ff0ff") if powered else Color("#2f2c40"), 3.0)
