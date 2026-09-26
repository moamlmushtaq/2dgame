class_name Furnace
extends Interactable
## The engine's firebox. Coal keeps the propeller spinning and the ship at full speed.

const COAL_FUEL := 28.0

var voyage
var _t := 0.0
var _smoke: CPUParticles2D
var _embers: CPUParticles2D
var _fire_glow: Sprite2D
var _mouth_glow: Sprite2D


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
	_smoke.scale_amount_min = 0.4
	_smoke.scale_amount_max = 0.8
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.5))
	grow.add_point(Vector2(1, 1.6))
	_smoke.scale_amount_curve = grow
	_smoke.angle_max = 360.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.95, 0.93, 0.98, 0.75))
	ramp.add_point(0.5, Color(0.85, 0.83, 0.92, 0.4))
	ramp.set_color(1, Color(0.8, 0.78, 0.9, 0.0))
	_smoke.color_ramp = ramp
	add_child(_smoke)
	# Embers spat out of the chimney, glowing as they drift back.
	_embers = CPUParticles2D.new()
	_embers.texture = Fx.soft_texture()
	_embers.material = Fx.additive()
	_embers.position = Vector2(-28, -182)
	_embers.amount = 8
	_embers.lifetime = 1.4
	_embers.direction = Vector2(-0.2, -1)
	_embers.spread = 30.0
	_embers.initial_velocity_min = 50.0
	_embers.initial_velocity_max = 110.0
	_embers.gravity = Vector2(-70, 30)
	_embers.scale_amount_min = 0.05
	_embers.scale_amount_max = 0.1
	var ember_ramp := Gradient.new()
	ember_ramp.set_color(0, Color(1, 0.85, 0.4, 1))
	ember_ramp.add_point(0.6, Color(1, 0.45, 0.15, 0.8))
	ember_ramp.set_color(1, Color(0.8, 0.2, 0.1, 0.0))
	_embers.color_ramp = ember_ramp
	add_child(_embers)
	# Firelight spilling out of the firebox onto the deck.
	_fire_glow = Fx.glow(self, Vector2(0, -32), 95.0, Color(1, 0.55, 0.2, 0.5))
	_fire_glow.z_index = 1
	_mouth_glow = Fx.glow(self, Vector2(0, -31), 34.0, Color(1, 0.75, 0.35, 0.8))
	_mouth_glow.z_index = 1


func interact(player: Player) -> void:
	if player.carrying != "coal":
		return
	player.carrying = ""
	voyage.fuel = minf(voyage.fuel + COAL_FUEL, 100.0)
	Sound.play("feed")
	Fx.burst(get_parent(), global_position + Vector2(0, -34), Color("#ffb347"), 22, 220.0, 0.6, -60.0, 0.7, true)
	Fx.sparks(get_parent(), global_position + Vector2(0, -40), Color("#ffb347"), 16, 320.0, 400.0)
	Fx.flash(get_parent(), global_position + Vector2(0, -32), 90.0, Color(1, 0.7, 0.3, 0.8), 0.4)


func hint(player: Player) -> String:
	return "أطعم المحرك" if player.carrying == "coal" else "المحرك يحتاج فحمًا"


func _process(delta: float) -> void:
	_t += delta
	_smoke.emitting = voyage.fuel > 0.0
	var fuel: float = voyage.fuel / 100.0
	_embers.emitting = fuel > 0.25
	var flicker := 0.8 + 0.2 * sin(_t * 17.0) * sin(_t * 7.0) + randf_range(-0.05, 0.05)
	var heat := clampf(fuel * 1.4, 0.0, 1.0) * flicker
	_fire_glow.modulate.a = 0.55 * heat
	_mouth_glow.modulate.a = 0.9 * heat
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
