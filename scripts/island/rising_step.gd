class_name RisingStep
extends AnimatableBody2D
## A rune stone set into the ground that rises into a step when its lever is pulled.
## The origin is the top-left corner.

var size := Vector2(90, 70)
var rise := 70.0
var _raised := false
var _glow := 0.0


func _ready() -> void:
	collision_layer = Player.LAYER_WORLD
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = size * 0.5
	add_child(cs)
	z_index = -1  # hidden inside the ground until it rises


func raise() -> void:
	if _raised:
		return
	_raised = true
	Sound.play("rumble", -4.0)
	var tw := create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(self, "position:y", position.y - rise, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.smoke(get_parent(), global_position + Vector2(size.x * 0.5, 0), Color(0.9, 0.85, 0.78, 0.8), 12, 1.3, 1.1)
	Fx.debris(get_parent(), global_position + Vector2(size.x * 0.5, 0), Color("#b8b3c9"), 12, 300.0)


func _process(delta: float) -> void:
	_glow = move_toward(_glow, 1.0 if _raised else 0.0, delta)
	queue_redraw()


func _draw() -> void:
	var stone := Color("#b8b3c9")
	draw_style_box(Paint.box(stone.darkened(0.15), 8), Rect2(Vector2.ZERO, size))
	draw_style_box(Paint.box(stone, 7), Rect2(0, 0, size.x - 4.0, size.y - 4.0))
	# Mortar lines between stone blocks.
	for k in int(size.y / 28.0):
		var y := 22.0 + k * 28.0
		if y < size.y - 6.0:
			draw_line(Vector2(4, y), Vector2(size.x - 8.0, y), stone.darkened(0.2), 1.5)
			var jx := size.x * (0.35 if k % 2 == 0 else 0.65)
			draw_line(Vector2(jx, y), Vector2(jx, minf(y + 28.0, size.y - 6.0)), stone.darkened(0.2), 1.5)
	draw_style_box(Paint.box(Color("#d6d1e4"), 6), Rect2(4, 4, size.x - 8.0, 10))
	var rune := Color("#7fe3ff").lerp(Color("#5b5675"), 1.0 - _glow)
	var c := Vector2(size.x * 0.5, 38)
	if _glow > 0.05:
		draw_circle(c, 22.0, Color(0.5, 0.9, 1.0, 0.18 * _glow), true, -1.0, true)
	draw_arc(c, 14.0, 0.0, TAU, 24, rune, 3.0, true)
	draw_line(c + Vector2(0, -10), c + Vector2(0, 10), rune, 3.0, true)
	draw_line(c + Vector2(-8, 2), c + Vector2(8, 2), rune, 3.0, true)
