class_name Gem
extends Node2D
## A floating sky crystal. Some hang so high that only a tower of friends can reach them.

signal collected

var _t := 0.0
var _glow: Sprite2D


func _ready() -> void:
	_t = randf() * TAU
	z_index = 4
	_glow = Fx.glow(self, Vector2.ZERO, 46.0, Color(0.5, 0.95, 1.0, 0.5))


func _physics_process(delta: float) -> void:
	_t += delta
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if not p.is_alive():
			continue
		var feet := p.global_position
		var g := global_position
		var closest := Vector2(clampf(g.x, feet.x - 13.0, feet.x + 13.0), clampf(g.y, feet.y - Player.HEIGHT, feet.y))
		if closest.distance_to(g) < 14.0:
			collected.emit()
			Sound.play("gem", -3.0)
			Fx.burst(get_parent(), g, Color("#9ff7ff"), 22, 200.0, 0.5, 60.0, 0.8, true)
			Fx.flash(get_parent(), g, 90.0, Color(0.6, 0.95, 1.0, 0.9), 0.35)
			Fx.ring(get_parent(), g, 60.0, Color(0.7, 1.0, 1.0, 0.9), 0.4, 4.0)
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var o := Vector2(0, sin(_t * 2.0) * 4.0)
	_glow.position = o
	_glow.modulate.a = 0.4 + 0.15 * sin(_t * 3.0)
	draw_circle(o, 20.0, Color(0.6, 0.95, 1.0, 0.18 + 0.08 * sin(_t * 3.0)), true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([o + Vector2(0, -14), o + Vector2(11, -2), o + Vector2(0, 14), o + Vector2(-11, -2)]), Color("#56d8f5"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(0, 14), o + Vector2(11, -2), o + Vector2(0, -2)]), Color("#2fb6dc"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(0, -14), o + Vector2(11, -2), o + Vector2(0, -2)]), Color("#c8f8ff"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(0, -14), o + Vector2(0, -2), o + Vector2(-11, -2)]), Color("#8eeaff"))
	# A twinkle that sweeps across every couple of seconds.
	var k := fposmod(_t * 0.6, 1.0)
	if k < 0.25:
		var a := sin(k / 0.25 * PI)
		var sp := o + Vector2(-5, -7)
		draw_line(sp + Vector2(-6, 0) * a, sp + Vector2(6, 0) * a, Color(1, 1, 1, a), 2.0, true)
		draw_line(sp + Vector2(0, -6) * a, sp + Vector2(0, 6) * a, Color(1, 1, 1, a), 2.0, true)
