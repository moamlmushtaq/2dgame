class_name Gate
extends AnimatableBody2D
## A portcullis that lifts while any of its pressure plates is pressed.
## The origin is the bottom centre, standing on the ground.

const HEIGHT := 180.0
const LIFT := 170.0

var plates: Array[PressurePlate] = []
var _closed_y := 0.0


func _ready() -> void:
	collision_layer = Player.LAYER_WORLD
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24, HEIGHT)
	cs.shape = r
	cs.position = Vector2(0, -HEIGHT * 0.5)
	add_child(cs)
	_closed_y = position.y
	z_index = 1


func _physics_process(delta: float) -> void:
	var open := false
	for p in plates:
		open = open or p.pressed
	if not open and _someone_underneath():
		open = true
	var goal := _closed_y - LIFT if open else _closed_y
	position.y = move_toward(position.y, goal, (420.0 if open else 300.0) * delta)
	queue_redraw()


func _someone_underneath() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p.is_alive() and absf(p.global_position.x - global_position.x) < 26.0 \
				and p.global_position.y > _closed_y - HEIGHT and p.global_position.y <= _closed_y + 4.0 \
				and p.global_position.y > global_position.y:
			return true
	return false


func _draw() -> void:
	var off := Vector2(0, _closed_y - position.y)
	var stone := Color("#9a9cb8")
	Paint.ground_shadow(self, off, 58.0)
	# Stone pillars built from blocks, lit from the left.
	for px: float in [-44.0, 28.0]:
		draw_rect(Rect2(off.x + px, off.y - 200.0, 16, 200), stone.darkened(0.1))
		draw_rect(Rect2(off.x + px, off.y - 200.0, 6, 200), stone.lightened(0.08))
		for k in 6:
			var y := off.y - 200.0 + k * 34.0 + (17.0 if px > 0.0 else 0.0)
			draw_line(Vector2(off.x + px, y), Vector2(off.x + px + 16.0, y), stone.darkened(0.3), 1.5)
	draw_style_box(Paint.box(stone.lightened(0.15), 6), Rect2(off.x - 52.0, off.y - 216.0, 104, 22))
	draw_line(Vector2(off.x - 48.0, off.y - 213.0), Vector2(off.x + 48.0, off.y - 213.0), Color(1, 1, 1, 0.35), 2.0)
	draw_line(Vector2(off.x - 48.0, off.y - 196.0), Vector2(off.x + 48.0, off.y - 196.0), stone.darkened(0.25), 2.0)

	# Wooden bars with grain, iron bands and rivets.
	var wood := Color("#9b6340")
	for i in 3:
		var x := -12.0 + i * 9.0
		draw_rect(Rect2(x, -HEIGHT, 6, HEIGHT), wood)
		draw_rect(Rect2(x, -HEIGHT, 2, HEIGHT), wood.lightened(0.15))
		draw_line(Vector2(x + 4.0, -HEIGHT + 20.0 + i * 13.0), Vector2(x + 4.0, -HEIGHT + 60.0 + i * 13.0), wood.darkened(0.25), 1.0)
	var iron := Color("#50546b")
	for y: float in [-150.0, -60.0]:
		draw_rect(Rect2(-14, y, 28, 7), iron)
		draw_line(Vector2(-14, y + 1.0), Vector2(14, y + 1.0), Color(1, 1, 1, 0.25), 1.5)
		for rx: float in [-9.0, 0.0, 9.0]:
			draw_circle(Vector2(rx, y + 3.5), 1.6, Color("#9a9fbf"), true, -1.0, true)
	for i in 3:
		var x := -9.0 + i * 9.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3.0, 0), Vector2(x + 3.0, 0), Vector2(x, 8)]), iron)
