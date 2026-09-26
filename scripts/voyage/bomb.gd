class_name Bomb
extends Node2D
## A pirate bomb lobbed at the deck. A red ring shows where it will land; a cannonball
## can knock it out of the sky first.

var voyage
var start := Vector2.ZERO
var target := Vector2.ZERO
var flight := 2.4
var arc := 260.0
var _k := 0.0


func _ready() -> void:
	var fuse := Fx.glow(self, Vector2(8, -15), 16.0, Color(1.0, 0.7, 0.3, 0.8))
	fuse.create_tween().set_loops().tween_property(fuse, "modulate:a", 0.35, 0.08).from(0.9)
	add_to_group("bombs")
	z_index = 9
	position = start


func _physics_process(delta: float) -> void:
	_k += delta / flight
	if _k >= 1.0:
		voyage.bomb_landed(self)
		return
	position = start.lerp(target, _k) + Vector2(0, -arc * 4.0 * _k * (1.0 - _k))
	queue_redraw()


func shoot_down() -> void:
	Sound.play("bird", -3.0, 0.7)
	Fx.explosion(get_parent(), global_position, Color("#ffb347"), 0.7)
	queue_free()


func _draw() -> void:
	var mark := target - position
	var a := 0.3 + 0.6 * _k
	draw_arc(mark, 28.0 - _k * 10.0, 0.0, TAU, 24, Color(1, 0.3, 0.35, a), 3.0, true)
	draw_circle(mark, 5.0, Color(1, 0.3, 0.35, a), true, -1.0, true)
	draw_circle(Vector2.ZERO, 11.0, Color("#3a2f4f"), true, -1.0, true)
	draw_circle(Vector2(-3, -4), 3.5, Color(1, 1, 1, 0.35), true, -1.0, true)
	var spark := 3.0 + sin(_k * 90.0) * 1.5
	draw_line(Vector2(5, -8), Vector2(8, -14), Color("#8a5436"), 2.0)
	draw_circle(Vector2(8, -15), spark, Color("#ffb347"), true, -1.0, true)
