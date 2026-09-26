class_name Bird
extends Node2D
## A grumpy storm bird that dives at the deck and pecks a hole in it.
## Art: Bevouliin's flying bird sprites (CC0, see assets/art/CREDITS.md).

const FRAMES := {
	"red": [preload("res://assets/art/birds/red_1.png"), preload("res://assets/art/birds/red_2.png"),
		preload("res://assets/art/birds/red_3.png"), preload("res://assets/art/birds/red_4.png")],
	"grey": [preload("res://assets/art/birds/grey_1.png"), preload("res://assets/art/birds/grey_2.png"),
		preload("res://assets/art/birds/grey_3.png"), preload("res://assets/art/birds/grey_4.png")],
}
## On-screen width of the bird in pixels.
const WIDTH := 76.0

var voyage
var target := Vector2.ZERO
var speed := 140.0
var fleeing := false
var _t := 0.0
var _vel := Vector2.ZERO
var _frames: Array = FRAMES["red"]


func _ready() -> void:
	add_to_group("birds")
	z_index = 8
	_t = randf() * TAU
	_frames = FRAMES["red" if randf() < 0.6 else "grey"]


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
	Sound.play("bird", -2.0)
	var feather := Color("#e8584f") if _frames == FRAMES["red"] else Color("#b9bcc8")
	Fx.burst(get_parent(), global_position, feather, 16, 220.0, 0.45, 260.0, 1.0)
	Fx.smoke(get_parent(), global_position, Color(1, 1, 1, 0.7), 6, 0.7, 0.6, 0.0)
	Fx.flash(get_parent(), global_position, 55.0, Color(1, 0.95, 0.85, 0.6), 0.2)
	queue_free()


func flee() -> void:
	fleeing = true
	target = position + Vector2(randf_range(-400.0, 400.0), -900.0)
	speed = 320.0


func _draw() -> void:
	var f := -1.0 if _vel.x < 0.0 else 1.0
	var tex: Texture2D = _frames[int(_t * (18.0 if fleeing else 12.0)) % _frames.size()]
	var sc := WIDTH / tex.get_width()
	# Tilt into the dive a little.
	var tilt := clampf(_vel.y / maxf(speed, 1.0), -0.6, 0.6) * 0.5 * f
	draw_set_transform(Vector2.ZERO, tilt, Vector2(sc * f, sc))
	draw_texture(tex, -tex.get_size() * 0.5)
	draw_set_transform(Vector2.ZERO)
