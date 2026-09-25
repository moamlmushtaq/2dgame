class_name Player
extends CharacterBody2D
## A little sky sailor driven by one PlayerInput. The origin sits at the feet.
## Sailors walk through each other, but each carries a one-way platform on its head,
## so friends can stand on top of each other to reach high places.

const SPEED := 260.0
const ACCEL := 2400.0
const AIR_ACCEL := 1600.0
const FRICTION := 2600.0
const GRAVITY := 1500.0
const MAX_FALL := 950.0
const JUMP_VELOCITY := -590.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const WIND_LIFT := 2700.0
const WIND_MAX_RISE := 340.0
const WIDTH := 26.0
const HEIGHT := 40.0

const LAYER_WORLD := 1
const LAYER_PLAYERS := 2
const LAYER_ONE_WAY := 4
const LAYER_HEADS := 8
const ONE_WAY_LAYER_NUMBER := 3
const BODY_MASK := LAYER_WORLD | LAYER_ONE_WAY | LAYER_HEADS

var input: PlayerInput
var color := Color.WHITE
var player_name := ""
var slot := 0

var facing := 1
var station: Station = null
var carrying := ""
var frozen := false
var respawn_point := Vector2.ZERO
var fall_limit := 1200.0
var checkpoint := 0
## Set by holes while this player is repairing them; drives the hammer animation.
var repair_time := 0.0
## Set by wind vents every frame the sailor is inside an updraft.
var wind_time := 0.0
var target: Interactable = null

var _coyote := 0.0
var _jump_buffer := 0.0
var _drop_time := 0.0
var _squash := Vector2.ONE
var _t := 0.0
var _respawn_time := 0.0
var _head: AnimatableBody2D


func setup(info: Dictionary) -> void:
	input = info["input"]
	if input.is_bot():
		input.brain.player = self

	color = info["color"]
	player_name = info["name"]
	slot = info["slot"]


func _ready() -> void:
	collision_layer = LAYER_PLAYERS
	collision_mask = BODY_MASK
	floor_snap_length = 6.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	shape.shape = rect
	shape.position = Vector2(0, -HEIGHT * 0.5)
	add_child(shape)

	_head = AnimatableBody2D.new()
	_head.sync_to_physics = false
	_head.collision_layer = LAYER_HEADS
	_head.collision_mask = 0
	var head_shape := CollisionShape2D.new()
	var head_rect := RectangleShape2D.new()
	head_rect.size = Vector2(WIDTH - 2.0, 8.0)
	head_shape.shape = head_rect
	head_shape.position = Vector2(0, -HEIGHT + 4.0)
	head_shape.one_way_collision = true
	_head.add_child(head_shape)
	add_child(_head)
	add_collision_exception_with(_head)
	add_to_group("players")
	z_index = 5
	if respawn_point == Vector2.ZERO:
		respawn_point = global_position
	_t = randf() * 10.0


func is_alive() -> bool:
	return _respawn_time <= 0.0


func center() -> Vector2:
	return global_position + Vector2(0, -HEIGHT * 0.5)


func _physics_process(delta: float) -> void:
	input.poll()
	_t += delta
	repair_time = maxf(repair_time - delta, 0.0)
	if _respawn_time > 0.0:
		_respawn_time -= delta
		if _respawn_time <= 0.0:
			_respawn()
		return

	if station != null:
		station.control(self, delta)
		if input.pressed("interact"):
			leave_station()
		_settle(delta)
		return

	var dir := 0.0 if frozen else input.axis_x()
	var accel := ACCEL if is_on_floor() else AIR_ACCEL
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
		facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if wind_time > 0.0:
		wind_time -= delta
		velocity.y = maxf(velocity.y - WIND_LIFT * delta, -WIND_MAX_RISE)
	elif velocity.y < 0.0 and not input.held("jump"):
		velocity.y += GRAVITY * 1.3 * delta  # short hop when jump is released early

	_coyote = COYOTE_TIME if is_on_floor() else _coyote - delta
	_jump_buffer = JUMP_BUFFER if (not frozen and input.pressed("jump")) else _jump_buffer - delta
	if _jump_buffer > 0.0 and _coyote > 0.0:
		_jump_buffer = 0.0
		_coyote = 0.0
		if input.held("down") and _on_one_way():
			_drop_time = 0.25
			set_collision_mask_value(ONE_WAY_LAYER_NUMBER, false)
		else:
			velocity.y = JUMP_VELOCITY
			_squash = Vector2(0.72, 1.3)
			Sound.play("jump", -8.0)
			if is_on_floor():
				_dust(4)

	if _drop_time > 0.0:
		_drop_time -= delta
		if _drop_time <= 0.0:
			set_collision_mask_value(ONE_WAY_LAYER_NUMBER, true)

	var was_airborne := not is_on_floor()
	var fall_speed := velocity.y
	move_and_slide()
	if was_airborne and is_on_floor():
		_squash = Vector2(1.3, 0.75)
		if fall_speed > 350.0:
			_dust(clampi(int(fall_speed / 90.0), 4, 10))

	if frozen:
		target = null
	else:
		_update_target()
		if input.pressed("interact") and target != null:
			target.interact(self)

	if global_position.y > fall_limit:
		fall_out()
	_settle(delta)


## A little puff of dust at the feet (jumping off and landing hard).
func _dust(amount: int) -> void:
	if get_parent() != null:
		Fx.burst(get_parent(), global_position + Vector2(0, -2), Color(1, 0.97, 0.9, 0.85), amount, 110.0, 0.35, -60.0, 0.35)


func _on_one_way() -> bool:
	for i in get_slide_collision_count():
		var body := get_slide_collision(i).get_collider() as CollisionObject2D
		if body != null and body.collision_layer & LAYER_ONE_WAY:
			return true
	return false


func _settle(delta: float) -> void:
	_squash = _squash.lerp(Vector2.ONE, minf(14.0 * delta, 1.0))
	queue_redraw()


func _update_target() -> void:
	target = null
	var best := INF
	for node in get_tree().get_nodes_in_group("interactables"):
		var it := node as Interactable
		if it == null or not it.can_interact(self):
			continue
		var d := center().distance_to(it.interact_point())
		if d < it.interact_radius and d < best:
			best = d
			target = it


func enter_station(st: Station) -> void:
	station = st
	st.occupant = self
	velocity = Vector2.ZERO
	global_position = st.seat_position()
	target = null


func leave_station() -> void:
	if station != null:
		station.occupant = null
	station = null


func fall_out() -> void:
	if not is_alive():
		return
	leave_station()
	carrying = ""
	_respawn_time = 1.3
	velocity = Vector2.ZERO
	Sound.play("fall", -4.0)
	visible = false
	collision_layer = 0
	collision_mask = 0
	_head.collision_layer = 0


func _respawn() -> void:
	global_position = respawn_point + Vector2((slot - 2.5) * 22.0, -4.0)
	velocity = Vector2.ZERO
	visible = true
	collision_layer = LAYER_PLAYERS
	collision_mask = BODY_MASK
	_head.collision_layer = LAYER_HEADS
	_squash = Vector2(0.6, 1.4)
	Sound.play("respawn", -6.0)
	Fx.burst(get_parent(), center(), Color.WHITE, 20, 160.0)


func _draw() -> void:
	if not is_alive():
		return
	var moving := absf(velocity.x) > 30.0 and is_on_floor()
	var airborne := station == null and not is_on_floor()
	paint_sailor(self, Vector2.ZERO, color, facing, _squash, _t, moving, carrying, airborne, repair_time > 0.0, input.is_bot(), velocity.y)

	var top := -HEIGHT * _squash.y - 16.0 - (24.0 if carrying != "" else 0.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, top - 7), Vector2(6, top - 7), Vector2(0, top)]), color)
	var label := ""
	if station != null:
		label = "خروج"
	elif target != null:
		label = target.hint(self)
	if label != "" and not input.is_bot():
		_draw_hint(Vector2(0, top - 24), label)


func _draw_hint(pos: Vector2, label: String) -> void:
	var key := input.interact_name()
	var fs := 15
	var tw := Paint.text_width(label, fs)
	var kw := maxf(Paint.text_width(key, fs) + 12.0, 24.0)
	var w := tw + kw + 22.0
	var r := Rect2(pos.x - w * 0.5, pos.y - 15.0, w, 30.0)
	draw_style_box(Paint.box(Color(1, 1, 1, 0.93), 15, color, 2), r)
	var kr := Rect2(r.end.x - kw - 4.0, r.position.y + 4.0, kw, 22.0)
	draw_style_box(Paint.box(color, 8), kr)
	Paint.text(self, kr.get_center(), key, fs, Color.WHITE)
	Paint.text(self, Vector2(r.position.x + 9.0 + tw * 0.5, r.get_center().y), label, fs, Color("#3a2f4f"))


## Draws a sailor with its feet at `o`. Shared with the menu so both look the same.
## `vy` (vertical speed) picks the jump pose: tucked while rising, arms out while falling.
static func paint_sailor(ci: CanvasItem, o: Vector2, col: Color, facing: int, sq: Vector2, t: float,
		moving := false, carrying := "", airborne := false, hammering := false, robot := false, vy := 0.0) -> void:
	var ink := Color("#2b2340")
	var dark := col.darkened(0.4)
	var phase := t * 14.0
	var rising := airborne and vy < -120.0
	var falling := airborne and vy > 160.0
	if not moving and not airborne:
		var breath := sin(t * 3.0) * 0.02
		sq *= Vector2(1.0 + breath, 1.0 - breath)
	var w := WIDTH * sq.x
	var h := HEIGHT * sq.y
	# Bob on every step, and lean a little into the walk.
	var bob := absf(cos(phase)) * 2.5 if moving else 0.0
	var lean := facing * 2.5 if moving else 0.0
	var body_o := o + Vector2(lean * 0.5, -bob)

	if not airborne:
		ci.draw_colored_polygon(Paint.ellipse(o + Vector2(0, 1), w * 0.62, 3.5, 16), Color(0.1, 0.05, 0.2, 0.18))

	# Feet: stepping arcs when walking, tucked when rising, dangling when falling.
	for side: int in [-1, 1]:
		var foot := Vector2(side * 6.0, -4.0)
		if moving:
			var swing := sin(phase) * side
			foot += Vector2(-swing * 5.0 * facing, -maxf(0.0, cos(phase) * side) * 4.0)
		elif rising:
			foot = Vector2(side * 4.0, -9.0)
		elif falling:
			foot = Vector2(side * 8.5, -1.0 + sin(t * 20.0 + side) * 1.5)
		elif airborne:
			foot.y -= 3.0
		ci.draw_circle(o + foot, 5.0, dark, true, -1.0, true)

	# Body, shaded on the side away from the light, with a soft belly.
	ci.draw_style_box(Paint.box(col.darkened(0.14), int(minf(w, h) * 0.45)), Rect2(body_o.x - w * 0.5, body_o.y - h, w, h - 5.0))
	ci.draw_style_box(Paint.box(col, int(minf(w, h) * 0.42)), Rect2(body_o.x - w * 0.5 + 1.0, body_o.y - h, w - 4.0, h - 7.0))
	ci.draw_circle(body_o + Vector2(facing * 2.0, -h * 0.3), w * 0.28, col.lightened(0.5), true, -1.0, true)
	ci.draw_circle(body_o + Vector2(-w * 0.22, -h * 0.82), 3.0, Color(1, 1, 1, 0.45), true, -1.0, true)

	# Hands (the coal carrier's arms and the hammer are drawn below instead).
	if carrying == "" and not hammering:
		var hand_col := col.darkened(0.18)
		for side: int in [-1, 1]:
			var hand := Vector2(side * (w * 0.5 + 1.5), -h * 0.42)
			if moving:
				hand.x += sin(phase) * side * 4.0 * facing
				hand.y += absf(sin(phase)) * -1.5
			elif rising:
				hand = Vector2(side * (w * 0.5 + 2.0), -h * 0.9)
			elif falling:
				hand = Vector2(side * (w * 0.5 + 6.0), -h * 0.62 + sin(t * 28.0 + side) * 3.0)
			ci.draw_circle(body_o + hand, 4.2, hand_col, true, -1.0, true)

	# Scarf with a tail that flutters behind (harder when running).
	var ny := body_o.y - h * 0.48
	ci.draw_rect(Rect2(body_o.x - w * 0.5 + 1.0, ny - 3.0, w - 2.0, 6.0), Color.WHITE)
	var flap := sin(t * (18.0 if moving else 11.0)) * (4.0 if moving or airborne else 3.0)
	var back := -facing
	var tail := 15.0 if moving else 11.0
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(body_o.x + back * (w * 0.5 - 2.0), ny - 2.0),
		Vector2(body_o.x + back * (w * 0.5 + tail), ny + 3.0 + flap - (4.0 if falling else 0.0)),
		Vector2(body_o.x + back * (w * 0.5 + 4.0), ny + 8.0),
	]), Color.WHITE)

	var ey := body_o.y - h * 0.74
	var ex := body_o.x + facing * 3.5 + lean * 0.4
	var blink := fmod(t, 3.7) < 0.12 and not airborne
	for side: int in [-1, 1]:
		var e := Vector2(ex + side * 5.5, ey)
		if blink:
			ci.draw_line(e + Vector2(-3, 0), e + Vector2(3, 0), ink, 2.0, true)
		else:
			var r := 4.8 if falling else 4.2
			ci.draw_circle(e, r, Color.WHITE, true, -1.0, true)
			var look := Vector2(facing * 1.3, 0.5)
			if rising:
				look.y = -1.2
			elif falling:
				look.y = 1.4
			ci.draw_circle(e + look, 2.3, ink, true, -1.0, true)
			ci.draw_circle(e + look + Vector2(-0.8, -0.9), 0.8, Color.WHITE, true, -1.0, true)
	var blush := Color(1, 0.55, 0.6, 0.55)
	ci.draw_circle(Vector2(ex - 9.5, ey + 6.0), 2.6, blush, true, -1.0, true)
	ci.draw_circle(Vector2(ex + 9.5, ey + 6.0), 2.6, blush, true, -1.0, true)
	# Mouth: a smile, or a little "o" in the air.
	var mouth := Vector2(ex, ey + 5.5)
	if airborne:
		ci.draw_circle(mouth + Vector2(0, 0.5), 2.2 if falling else 1.6, ink, true, -1.0, true)
	else:
		ci.draw_arc(mouth + Vector2(0, -1.5), 2.6, 0.35, PI - 0.35, 8, ink, 1.6, true)

	# Sailor cap with a pompom.
	var hy := body_o.y - h
	ci.draw_style_box(Paint.box(Color.WHITE, 4), Rect2(body_o.x - w * 0.42, hy - 5.0, w * 0.84, 8.0))
	ci.draw_rect(Rect2(body_o.x - w * 0.42, hy + 1.0, w * 0.84, 2.0), col.darkened(0.2))
	if robot:
		# Computer-controlled helpers wear an antenna with a blinking light instead of a pompom.
		ci.draw_line(Vector2(body_o.x, hy - 4.0), Vector2(body_o.x, hy - 16.0), Color("#6f7389"), 2.0, true)
		var blink_light := 0.5 + 0.5 * sin(t * 6.0)
		ci.draw_circle(Vector2(body_o.x, hy - 18.0), 4.0, Color("#7dffa8").lerp(Color.WHITE, blink_light * 0.5), true, -1.0, true)
	else:
		ci.draw_circle(Vector2(body_o.x, hy - 7.0), 3.5, col.lightened(0.25), true, -1.0, true)

	if hammering:
		var a := 1.1 - absf(sin(t * 14.0)) * 1.4
		var hand := body_o + Vector2(facing * (w * 0.5 + 1.0), -h * 0.45)
		var d := Vector2(facing * cos(a), -sin(a))
		var tip := hand + d * 16.0
		var perp := Vector2(-d.y, d.x)
		ci.draw_line(hand, tip, Color("#8a5436"), 3.0, true)
		ci.draw_line(tip - perp * 6.0, tip + perp * 6.0, Color("#6f7389"), 6.0, true)

	if carrying == "coal":
		var c := body_o + Vector2(0, -h - 20.0)
		ci.draw_line(body_o + Vector2(-w * 0.5, -h * 0.6), c + Vector2(-8, 4), col.darkened(0.15), 4.0, true)
		ci.draw_line(body_o + Vector2(w * 0.5, -h * 0.6), c + Vector2(8, 4), col.darkened(0.15), 4.0, true)
		ci.draw_circle(c, 11.0, Color("#3b3440"), true, -1.0, true)
		ci.draw_circle(c + Vector2(-3, -4), 3.5, Color("#6a5f73"), true, -1.0, true)
		ci.draw_circle(c + Vector2(4, 3), 2.2, Color("#ff9a3c"), true, -1.0, true)
