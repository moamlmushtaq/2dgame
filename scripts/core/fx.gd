class_name Fx
extends RefCounted
## One-shot visual effects: particle bursts, glowing sparks, smoke, debris, flashes and
## shockwave rings, plus soft additive glows that make lights feel like light.
## Everything here is built from two generated textures, so no image files are needed.

static var _soft: Texture2D
static var _streak: Texture2D
static var _chunk: Texture2D
static var _add: CanvasItemMaterial


## A round, soft-edged white dot (alpha fades to the rim).
static func soft_texture() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 64
		t.height = 64
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_soft = t
	return _soft


## A thin vertical streak, bright in the middle; particles align it to their motion.
static func streak_texture() -> Texture2D:
	if _streak == null:
		var img := Image.create(8, 40, false, Image.FORMAT_RGBA8)
		for y in 40:
			var fy := 1.0 - absf(y - 20.0) / 20.0
			for x in 8:
				var fx := 1.0 - absf(x - 3.5) / 4.0
				img.set_pixel(x, y, Color(1, 1, 1, clampf(fx * fy * 1.6, 0.0, 1.0)))
		_streak = ImageTexture.create_from_image(img)
	return _streak


## A small chunky shard for debris.
static func chunk_texture() -> Texture2D:
	if _chunk == null:
		var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		var poly := PackedVector2Array([Vector2(2, 1), Vector2(10, 3), Vector2(11, 9), Vector2(5, 11), Vector2(1, 7)])
		for y in 12:
			for x in 12:
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
					var shade := 1.0 if x + y < 11 else 0.75
					img.set_pixel(x, y, Color(shade, shade, shade, 1))
		_chunk = ImageTexture.create_from_image(img)
	return _chunk


## Shared additive blend: colours add up and glow instead of covering what is behind.
static func additive() -> CanvasItemMaterial:
	if _add == null:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add


static func _particles(parent: Node, pos: Vector2, color: Color, amount: int, lifetime: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = soft_texture()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = maxi(amount, 1)
	p.lifetime = lifetime
	p.spread = 180.0
	p.direction = Vector2.UP
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	p.position = pos
	p.z_index = 30
	return p


static func _start(parent: Node, p: CPUParticles2D) -> void:
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Soft puffs flying out and fading (dust, feathers, sparkles). `glow` adds light.
static func burst(parent: Node, pos: Vector2, color: Color, amount := 16, speed := 160.0, size := 0.5, gravity := 200.0, lifetime := 0.7, glow := false) -> void:
	if parent == null:
		return
	var p := _particles(parent, pos, color, amount, lifetime)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.damping_min = 40.0
	p.damping_max = 90.0
	# The dot texture is 64 px (it used to be 32), so halve the scale to keep sizes.
	p.scale_amount_min = size * 0.25
	p.scale_amount_max = size * 0.5
	if glow:
		p.material = additive()
	_start(parent, p)


## Hot sparks: thin glowing streaks that fly out along their direction and fall.
static func sparks(parent: Node, pos: Vector2, color: Color, amount := 14, speed := 380.0, gravity := 500.0, lifetime := 0.55, direction := Vector2.UP, spread := 180.0) -> void:
	if parent == null:
		return
	var p := _particles(parent, pos, color, amount, lifetime)
	p.texture = streak_texture()
	p.material = additive()
	p.particle_flag_align_y = true
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = speed * 0.45
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.damping_min = 30.0
	p.damping_max = 60.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.8
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.lightened(0.5), 1.0))
	ramp.add_point(0.35, color)
	ramp.set_color(1, Color(color.darkened(0.3), 0.0))
	p.color_ramp = ramp
	_start(parent, p)


## Billowing smoke: soft puffs that grow, drift up and fade.
static func smoke(parent: Node, pos: Vector2, color: Color, amount := 8, size := 1.0, lifetime := 1.2, rise := -40.0) -> void:
	if parent == null:
		return
	var p := _particles(parent, pos, color, amount, lifetime)
	p.explosiveness = 0.85
	p.initial_velocity_min = 30.0 * size
	p.initial_velocity_max = 110.0 * size
	p.gravity = Vector2(0, rise)
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.scale_amount_min = 0.5 * size
	p.scale_amount_max = 1.0 * size
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.45))
	grow.add_point(Vector2(1, 1.3))
	p.scale_amount_curve = grow
	p.angle_min = 0.0
	p.angle_max = 360.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color, color.a * 0.9))
	ramp.add_point(0.4, Color(color, color.a * 0.55))
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	p.z_index = 29
	_start(parent, p)


## Tumbling shards (wood splinters, rock chips) that fall with gravity.
static func debris(parent: Node, pos: Vector2, color: Color, amount := 12, speed := 360.0, size := 1.0, lifetime := 0.9) -> void:
	if parent == null:
		return
	var p := _particles(parent, pos, color, amount, lifetime)
	p.texture = chunk_texture()
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 900.0)
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.scale_amount_min = 0.6 * size
	p.scale_amount_max = 1.4 * size
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.add_point(0.75, color)
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	_start(parent, p)


## A short, bright additive flash of light that swells and fades.
static func flash(parent: Node, pos: Vector2, radius: float, color: Color, lifetime := 0.3) -> void:
	if parent == null:
		return
	var s := Sprite2D.new()
	s.texture = soft_texture()
	s.material = additive()
	s.position = pos
	s.z_index = 31
	s.modulate = color
	var base := radius * 2.0 / 64.0
	s.scale = Vector2.ONE * base * 0.6
	parent.add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale", Vector2.ONE * base, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)


## An expanding shockwave ring.
static func ring(parent: Node, pos: Vector2, radius: float, color: Color, lifetime := 0.45, width := 6.0) -> void:
	if parent == null:
		return
	var r := FxRing.new()
	r.position = pos
	r.radius = radius
	r.color = color
	r.lifetime = lifetime
	r.width = width
	parent.add_child(r)


## A cannon-style blast: flash, shockwave, sparks and smoke.
static func explosion(parent: Node, pos: Vector2, color: Color, size := 1.0) -> void:
	flash(parent, pos, 110.0 * size, Color(color.lightened(0.4), 0.9), 0.35)
	ring(parent, pos, 70.0 * size, Color(color.lightened(0.3), 0.8), 0.4, 5.0 * size)
	sparks(parent, pos, color, int(18 * size), 480.0 * size)
	smoke(parent, pos, Color(0.42, 0.38, 0.48, 0.7), int(9 * size), size, 1.1)


## A soft light that stays on a node (lanterns, fire, crystals). Animate its
## `modulate` or `scale` to flicker or pulse.
static func glow(parent: Node, pos: Vector2, radius: float, color: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = soft_texture()
	s.material = additive()
	s.position = pos
	s.scale = Vector2.ONE * radius * 2.0 / 64.0
	s.modulate = color
	parent.add_child(s)
	return s
