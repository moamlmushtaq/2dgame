class_name Cannon
extends Station
## A swivel cannon. Aim with up/down, fire with jump. The mast cannon swings all the way
## round (except straight down through the mast): its barrel tip follows the arrows.

const PIVOT := Vector2(0, -24)
const BALL_SPEED := 860.0
const RELOAD := 0.45
const TURN_SPEED := 1.7
const SWEEP_TURN_SPEED := 2.2
## Seconds of flight shown by the dotted aim line.
const PREVIEW_TIME := 0.9

var voyage
var min_angle := -1.0
var max_angle := 0.45
var angle := -0.25
var sweep_with_x := false
var _cooldown := 0.0
var _recoil := 0.0


func _ready() -> void:
	interact_radius = 60.0
	z_index = 6


func hint(_player: Player) -> String:
	return "المدفع"


func seat_position() -> Vector2:
	return global_position + Vector2(-36, 0)


func control(player: Player, delta: float) -> void:
	if sweep_with_x:
		# Turn so the barrel tip moves the way the arrows point: project the input onto the
		# tip's direction of travel for a growing angle (clockwise on screen).
		var push := Vector2(player.input.axis_x(), player.input.axis_y())
		var turn := clampf(push.dot(Vector2(-sin(angle), cos(angle))) * 3.0, -1.0, 1.0)
		angle = clampf(angle + turn * SWEEP_TURN_SPEED * delta, min_angle, max_angle)
	else:
		angle = clampf(angle + player.input.axis_y() * TURN_SPEED * delta, min_angle, max_angle)
	player.facing = 1 if cos(angle) >= 0.0 else -1
	if player.input.pressed("jump") and _cooldown <= 0.0:
		_fire()


func _fire() -> void:
	_cooldown = RELOAD
	_recoil = 1.0
	var dir := Vector2.from_angle(angle)
	var muzzle := global_position + PIVOT + dir * 46.0
	voyage.spawn_ball(muzzle, dir * BALL_SPEED)
	voyage.add_shake(3.0)
	Sound.play("cannon", -3.0)
	Fx.burst(voyage.effects, muzzle, Color("#fff0c2"), 14, 200.0, 0.55, -40.0, 0.4)


## `a` written inside [min_angle, max_angle] (the mast's range crosses ±PI), or NAN if the
## barrel can't point that way.
func fit_angle(a: float, slack := 0.0) -> float:
	for c in [a, a - TAU, a + TAU]:
		if c >= min_angle - slack and c <= max_angle + slack:
			return clampf(c, min_angle, max_angle)
	return NAN


func _process(delta: float) -> void:
	_cooldown -= delta
	_recoil = move_toward(_recoil, 0.0, delta * 4.0)
	queue_redraw()


func _draw() -> void:
	if occupant != null:
		var dir := Vector2.from_angle(angle)
		var pos := PIVOT + dir * 46.0
		var vel := dir * BALL_SPEED
		var steps := 20
		var step := PREVIEW_TIME / steps
		for i in steps:
			vel.y += Cannonball.GRAVITY * step
			pos += vel * step
			var k := float(i) / steps
			draw_circle(pos, 3.2 - k * 1.6, Color(occupant.color, 0.85 - k * 0.65), true, -1.0, true)

	draw_style_box(Paint.box(Color("#8a5436"), 6), Rect2(-22, -26, 44, 18))
	draw_set_transform(PIVOT, angle)
	var back := -_recoil * 8.0
	draw_style_box(Paint.box(Color("#4b4f68"), 9), Rect2(back - 14.0, -10, 58, 20))
	draw_rect(Rect2(back + 38.0, -12, 8, 24), Color("#383b50"))
	draw_line(Vector2(back - 6.0, -5), Vector2(back + 30.0, -5), Color(1, 1, 1, 0.25), 3.0)
	draw_set_transform(Vector2.ZERO)
	draw_circle(PIVOT, 8.0, Ship.GOLD, true, -1.0, true)
	draw_circle(Vector2(-13, -8), 9.0, Color("#5a3a26"), true, -1.0, true)
	draw_circle(Vector2(13, -8), 9.0, Color("#5a3a26"), true, -1.0, true)
	draw_circle(Vector2(-13, -8), 3.0, Ship.GOLD, true, -1.0, true)
	draw_circle(Vector2(13, -8), 3.0, Ship.GOLD, true, -1.0, true)
