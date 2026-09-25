class_name Lift
extends AnimatableBody2D
## A balloon lift. It only rises while `need` sailors ride it, until its lever
## switches it to automatic, after which it shuttles up and down on its own.
## The origin is the top-left corner of the platform.

var width := 196.0
var top_y := 280.0
var bottom_y := 460.0
var need := 2
var auto := false
var riders := 0
var _going_up := true
var _pause := 0.0
var _t := 0.0


func _ready() -> void:
	collision_layer = Player.LAYER_WORLD
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(width, 18)
	cs.shape = r
	cs.position = Vector2(width * 0.5, 9)
	add_child(cs)
	position.y = bottom_y
	z_index = 1


func set_auto() -> void:
	auto = true


func _physics_process(delta: float) -> void:
	_t += delta
	riders = IslandProps.count_standing(get_tree(), global_position.x - 6.0, global_position.x + width + 6.0, global_position.y)
	if auto:
		if _pause > 0.0:
			_pause -= delta
		else:
			var goal := top_y if _going_up else bottom_y
			position.y = move_toward(position.y, goal, 110.0 * delta)
			if is_equal_approx(position.y, goal):
				_going_up = not _going_up
				_pause = 1.8
	else:
		var up := riders >= need
		position.y = move_toward(position.y, top_y if up else bottom_y, (110.0 if up else 150.0) * delta)
	queue_redraw()


func _draw() -> void:
	var lift_f := (bottom_y - position.y) / (bottom_y - top_y)
	var colors := [Color("#ff8fa3"), Color("#7fd6ff"), Color("#ffd35c")]
	for i in 3:
		var bx := width * (0.2 + i * 0.3)
		var by := -118.0 + sin(_t * 1.8 + i) * 5.0 - i % 2 * 14.0
		var s := 0.85 + 0.3 * lift_f
		draw_line(Vector2(width * (0.1 + i * 0.4), 0), Vector2(bx, by + 30.0 * s), Color("#6b4a2f"), 2.0, true)
		var col: Color = colors[i]
		draw_colored_polygon(Paint.ellipse(Vector2(bx, by), 22.0 * s, 28.0 * s, 28), col)
		draw_colored_polygon(Paint.ellipse(Vector2(bx - 7.0 * s, by - 10.0 * s), 6.0 * s, 9.0 * s, 16), Color(1, 1, 1, 0.45))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 4, by + 28.0 * s + 4.0), Vector2(bx + 4, by + 28.0 * s + 4.0), Vector2(bx, by + 28.0 * s - 2.0)]), col.darkened(0.2))

	draw_style_box(Paint.box(Color("#c98a58"), 6), Rect2(0, 0, width, 18))
	for x in range(20, int(width), 28):
		draw_line(Vector2(x, 2), Vector2(x, 16), Color("#a86d45"), 2.0)

	var panel := Rect2(width * 0.5 - 60.0, 24, 120, 26)
	draw_style_box(Paint.box(Color(1, 1, 1, 0.9), 13, Color("#a86d45"), 2), panel)
	if auto:
		Paint.text(self, panel.get_center(), "تلقائي", 15, Color("#4a8f5a"))
	else:
		for i in need:
			var x := panel.get_center().x + (i - (need - 1) * 0.5) * 18.0
			var filled := i < riders
			draw_circle(Vector2(x, panel.get_center().y), 6.5, Color("#5fd49a") if filled else Color("#ddd6e8"), true, -1.0, true)
