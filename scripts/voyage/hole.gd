class_name Hole
extends Interactable
## A breach in the deck that leaks the hull's strength. Hold interact nearby to patch it;
## several sailors hammering together fix it faster.

const REPAIR_TIME := 1.6
const REACH := 46.0

var voyage
var progress := 0.0
var _t := 0.0
var _shape := PackedVector2Array()
var _wind: CPUParticles2D
var _knock := 0.0


func _ready() -> void:
	interact_radius = 50.0
	z_index = 3
	for i in 12:
		var a := TAU * i / 12.0
		var r := randf_range(0.7, 1.1)
		_shape.append(Vector2(cos(a) * 26.0 * r, sin(a) * 8.0 * r - 2.0))
	_wind = CPUParticles2D.new()
	_wind.texture = Fx.soft_texture()
	_wind.amount = 10
	_wind.lifetime = 0.9
	_wind.direction = Vector2.UP
	_wind.spread = 25.0
	_wind.initial_velocity_min = 60.0
	_wind.initial_velocity_max = 120.0
	_wind.gravity = Vector2(-60, 0)
	_wind.scale_amount_min = 0.12
	_wind.scale_amount_max = 0.25
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.8))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	_wind.color_ramp = ramp
	add_child(_wind)
	Fx.debris(get_parent(), global_position, Ship.WOOD_LIGHT, 16, 320.0)
	Sound.play("crack")


func hint(_player: Player) -> String:
	return "أصلح (اضغط باستمرار)"


func interact_point() -> Vector2:
	return global_position + Vector2(0, -16)


func _physics_process(delta: float) -> void:
	_t += delta
	var fixers := 0
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p.station == null and p.is_alive() and p.input.held("interact") \
				and absf(p.global_position.x - global_position.x) < REACH \
				and absf(p.global_position.y - global_position.y) < 60.0:
			fixers += 1
			p.repair_time = 0.12
			p.facing = 1 if global_position.x > p.global_position.x else -1
	if fixers > 0:
		progress += delta * fixers / REPAIR_TIME
		_knock -= delta
		if _knock <= 0.0:
			_knock = 0.2
			Sound.play("hammer", -6.0, 1.0, 0.15)
	else:
		progress = maxf(progress - delta * 0.3, 0.0)
	if progress >= 1.0:
		Sound.play("fixed", -2.0)
		Fx.burst(get_parent(), global_position + Vector2(0, -10), Color("#fff4c2"), 20, 200.0, 0.5, 200.0, 0.7, true)
		Fx.ring(get_parent(), global_position + Vector2(0, -6), 50.0, Color(1, 0.95, 0.7, 0.7), 0.35, 4.0)
		voyage.remove_hole(self)
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(_shape, Color("#2a1a14"))
	for i in 3:
		var a := -2.6 + i * 1.0
		var from := Vector2(cos(a) * 20.0, -2.0)
		draw_line(from, from + Vector2.from_angle(a) * 14.0, Ship.WOOD_LIGHT, 4.0, true)
	var bubble := Vector2(0, -64 + sin(_t * 5.0) * 4.0)
	if progress > 0.0:
		draw_circle(bubble, 16.0, Color(0, 0, 0, 0.35), true, -1.0, true)
		draw_arc(bubble, 14.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color.WHITE, 5.0, true)
	else:
		draw_circle(bubble, 13.0, Color("#ff5a67"), true, -1.0, true)
		Paint.text(self, bubble, "!", 20, Color.WHITE)
