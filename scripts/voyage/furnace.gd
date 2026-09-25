class_name Furnace
extends Interactable
## The engine's firebox. Coal keeps the propeller spinning and the ship at full speed.

const COAL_FUEL := 28.0

var voyage
var _t := 0.0
var _smoke: CPUParticles2D


func _ready() -> void:
	interact_radius = 62.0
	z_index = 2
	_smoke = CPUParticles2D.new()
	_smoke.texture = Fx.soft_texture()
	_smoke.position = Vector2(-28, -178)
	_smoke.amount = 14
	_smoke.lifetime = 2.2
	_smoke.direction = Vector2(-0.3, -1)
	_smoke.spread = 18.0
	_smoke.initial_velocity_min = 30.0
	_smoke.initial_velocity_max = 60.0
	_smoke.gravity = Vector2(-40, -10)
	_smoke.scale_amount_min = 0.8
	_smoke.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.7))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	_smoke.color_ramp = ramp
	add_child(_smoke)


func interact(player: Player) -> void:
	if player.carrying != "coal":
		return
	player.carrying = ""
	voyage.fuel = minf(voyage.fuel + COAL_FUEL, 100.0)
	Sound.play("feed")
	Fx.burst(get_parent(), global_position + Vector2(0, -34), Color("#ffb347"), 22, 220.0, 0.6, -60.0)


func hint(player: Player) -> String:
	return "أطعم المحرك" if player.carrying == "coal" else "المحرك يحتاج فحمًا"


func _process(delta: float) -> void:
	_t += delta
	_smoke.emitting = voyage.fuel > 0.0
	queue_redraw()


func _draw() -> void:
	var fuel: float = voyage.fuel / 100.0
	draw_rect(Rect2(-36, -178, 16, 110), Color("#5c5f73"))
	draw_rect(Rect2(-40, -185, 24, 10), Color("#474a5c"))

	draw_circle(Vector2(0, -30), 30.0 + 22.0 * fuel, Color(1, 0.7, 0.3, 0.12 * fuel), true, -1.0, true)
	draw_style_box(Paint.box(Color("#a8543f"), 10), Rect2(-42, -72, 84, 72))
	for row in 3:
		var y := -60.0 + row * 20.0
		draw_line(Vector2(-40, y), Vector2(40, y), Color("#8a4031"), 2.0)
	var flicker := 0.8 + 0.2 * sin(_t * 17.0) * sin(_t * 7.0)
	var glow := Color("#3a2320").lerp(Color("#ffb347"), clampf(fuel * 1.4, 0.0, 1.0) * flicker)
	draw_style_box(Paint.box(Color("#2b1a18"), 10), Rect2(-22, -48, 44, 32))
	draw_style_box(Paint.box(glow, 8), Rect2(-18, -44, 36, 26))

	# Fuel dial.
	var dial := Vector2(28, -60)
	draw_circle(dial, 9.0, Color("#fff4e6"), true, -1.0, true)
	var a := lerpf(PI * 0.2, PI * 0.8, fuel) + PI
	draw_line(dial, dial + Vector2.from_angle(a) * 7.0, Color("#d64545"), 2.0, true)
