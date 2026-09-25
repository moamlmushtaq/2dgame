class_name BellBridge
extends Node2D
## A plank bridge that unrolls across a gap once every bell has rung within its window.
## The origin is the left end of the bridge deck.

var bells: Array[Bell] = []
var length := 400.0
var built := false
var _progress := 0.0


func _physics_process(delta: float) -> void:
	if not built and not bells.is_empty():
		var together := true
		for b in bells:
			together = together and b.since_rung() <= b.window
		if together:
			_build()
	if built:
		_progress = move_toward(_progress, 1.0, delta * 0.9)
	queue_redraw()


func _build() -> void:
	built = true
	Sound.play("win", -3.0)
	var body := StaticBody2D.new()
	body.collision_layer = Player.LAYER_WORLD
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(length, 16)
	cs.shape = r
	cs.position = Vector2(length * 0.5, 8)
	body.add_child(cs)
	add_child(body)
	for b in bells:
		Fx.burst(get_parent(), b.global_position + Vector2(0, -60), b.color, 24, 220.0, 0.5)


func _draw() -> void:
	if _progress <= 0.0:
		draw_line(Vector2(0, 2), Vector2(0, -40), Color("#8a5436"), 6.0)
		draw_line(Vector2(length, 2), Vector2(length, -40), Color("#8a5436"), 6.0)
		return
	var reach := length * _progress
	var rope := Color("#6b4a2f")
	var planks := int(reach / 22.0)
	for i in planks:
		var x := i * 22.0
		var sag := sin(x / length * PI) * 10.0
		draw_style_box(Paint.box(Color("#c98a58"), 3), Rect2(x + 1.0, sag, 20, 12))
	var pts := PackedVector2Array()
	for i in 21:
		var x := reach * i / 20.0
		pts.append(Vector2(x, -30.0 + sin(x / length * PI) * 14.0))
	draw_polyline(pts, rope, 3.0, true)
	draw_line(Vector2(0, 2), Vector2(0, -40), Color("#8a5436"), 6.0)
	draw_line(Vector2(length, 2), Vector2(length, -40), Color("#8a5436"), 6.0)
