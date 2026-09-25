class_name Bird
extends Node2D
## A grumpy storm bird that dives at the deck and pecks a hole in it.

var voyage
var target := Vector2.ZERO
var speed := 140.0
var fleeing := false
var _t := 0.0
var _vel := Vector2.ZERO


func _ready() -> void:
	add_to_group("birds")
	z_index = 8
	_t = randf() * TAU


func _physics_process(delta: float) -> void:
	_t += delta
	var to := target - position
	if not fleeing and to.length() < 18.0:
		voyage.bird_hit(self)
		return
	_vel = _vel.lerp(to.normalized() * speed, minf(2.0 * delta, 1.0))
	position += _vel * delta + Vector2(0, sin(_t * 6.0) * 30.0 * delta)
	if fleeing and (position.y < -200.0 or position.x > 1700.0 or position.x < -400.0):
		queue_free()
	queue_redraw()


func kill() -> void:
	Fx.burst(get_parent(), global_position, Color("#8e7fc4"), 18, 200.0, 0.5, 300.0)
	queue_free()


func flee() -> void:
	fleeing = true
	target = position + Vector2(randf_range(-400.0, 400.0), -900.0)
	speed = 320.0


func _draw() -> void:
	var f := -1.0 if _vel.x < 0.0 else 1.0
	var flap := sin(_t * 14.0)
	var ink := Color("#1d1530")
	draw_colored_polygon(PackedVector2Array([Vector2(-4 * f, -4), Vector2(-18 * f, -18 - flap * 14.0), Vector2(8 * f, -6)]), Color("#43356e"))
	draw_colored_polygon(PackedVector2Array([Vector2(-16 * f, -2), Vector2(-30 * f, -10), Vector2(-28 * f, 6)]), Color("#43356e"))
	draw_colored_polygon(Paint.ellipse(Vector2.ZERO, 20.0, 15.0, 24), Color("#5b4b8a"))
	draw_colored_polygon(Paint.ellipse(Vector2(4 * f, 5), 11.0, 8.0, 18), Color("#8e7fc4"))
	draw_colored_polygon(PackedVector2Array([Vector2(17 * f, -3), Vector2(29 * f, 1), Vector2(17 * f, 5)]), Color("#ffc53d"))
	draw_circle(Vector2(9 * f, -5), 4.5, Color.WHITE, true, -1.0, true)
	draw_circle(Vector2(10.5 * f, -4.5), 2.2, ink, true, -1.0, true)
	draw_line(Vector2(4 * f, -11), Vector2(14 * f, -8), ink, 2.5, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-6 * f, -2), Vector2(-14 * f, -14 + flap * 10.0), Vector2(8 * f, -2)]), Color("#6d5ca3"))
