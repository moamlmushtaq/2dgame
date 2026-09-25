class_name Fx
extends RefCounted
## One-shot particle bursts for dust, sparks, feathers and sparkles.

static var _soft: Texture2D


static func soft_texture() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 32
		t.height = 32
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_soft = t
	return _soft


static func burst(parent: Node, pos: Vector2, color: Color, amount := 16, speed := 160.0, size := 0.5, gravity := 200.0, lifetime := 0.7) -> void:
	var p := CPUParticles2D.new()
	p.texture = soft_texture()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = lifetime
	p.spread = 180.0
	p.direction = Vector2.UP
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.damping_min = 40.0
	p.damping_max = 90.0
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	p.position = pos
	p.z_index = 30
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
