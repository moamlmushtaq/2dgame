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
	Fx.burst(get_parent(), global_position + Vector2(size.x * 0.5, 0), Color("#d8c9b0"), 24, 200.0, 0.6)


func _process(delta: float) -> void:
	_glow = move_toward(_glow, 1.0 if _raised else 0.0, delta)
	queue_redraw()


func _draw() -> void:
	draw_style_box(Paint.box(Color("#b8b3c9"), 8), Rect2(Vector2.ZERO, size))
	draw_style_box(Paint.box(Color("#d6d1e4"), 6), Rect2(4, 4, size.x - 8.0, 10))
	var rune := Color("#7fe3ff").lerp(Color("#5b5675"), 1.0 - _glow)
	var c := Vector2(size.x * 0.5, 38)
	draw_arc(c, 14.0, 0.0, TAU, 24, rune, 3.0, true)
	draw_line(c + Vector2(0, -10), c + Vector2(0, 10), rune, 3.0, true)
	draw_line(c + Vector2(-8, 2), c + Vector2(8, 2), rune, 3.0, true)
