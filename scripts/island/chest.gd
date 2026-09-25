class_name Chest
extends Interactable
## The treasure chest holding a piece of the sky map. It only opens when the whole crew
## has gathered around it.

const GATHER_RADIUS := 260.0

var island
var opened := false
var _lid := 0.0
var _piece := 0.0
var _t := 0.0


func _ready() -> void:
	interact_radius = 70.0
	z_index = 2


func gathered() -> Vector2i:
	var near := 0
	var total := 0
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if not p.is_alive():
			continue
		total += 1
		if absf(p.global_position.x - global_position.x) < GATHER_RADIUS and absf(p.global_position.y - global_position.y) < 200.0:
			near += 1
	return Vector2i(near, total)


func can_interact(_player: Player) -> bool:
	return not opened


func hint(_player: Player) -> String:
	var g := gathered()
	return "افتح الصندوق" if g.x >= g.y else "اجتمعوا (%d/%d)" % [g.x, g.y]


func interact(_player: Player) -> void:
	var g := gathered()
	if g.x < g.y:
		island.show_banner("يجب أن يجتمع الطاقم كله حول الصندوق!")
		return
	opened = true
	Fx.burst(get_parent(), global_position + Vector2(0, -40), Color("#ffd27a"), 40, 320.0, 0.7)
	island.win()


func _process(delta: float) -> void:
	_t += delta
	if opened:
		_lid = move_toward(_lid, 1.0, delta * 3.0)
		_piece = move_toward(_piece, 1.0, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	var gold := Color("#ffd27a")
	if not opened:
		for i in 4:
			var a := _t * 0.8 + i * TAU / 4.0
			var p := Vector2(cos(a) * 52.0, -30.0 + sin(a * 1.7) * 20.0)
			draw_circle(p, 2.0 + sin(_t * 4.0 + i) * 1.2, Color(1, 0.95, 0.7, 0.8), true, -1.0, true)
	if opened:
		draw_circle(Vector2(0, -50), 60.0 * _piece, Color(1, 0.9, 0.5, 0.25), true, -1.0, true)

	draw_style_box(Paint.box(Color("#a8643c"), 8), Rect2(-36, -44, 72, 44))
	draw_rect(Rect2(-36, -40, 72, 6), gold)
	draw_rect(Rect2(-26, -44, 6, 44), gold)
	draw_rect(Rect2(20, -44, 6, 44), gold)

	draw_set_transform(Vector2(-36, -44), -_lid * 1.9)
	draw_style_box(Paint.box(Color("#bf7446"), 10), Rect2(0, -22, 72, 24))
	draw_rect(Rect2(0, -2, 72, 4), gold)
	draw_set_transform(Vector2.ZERO)
	if not opened:
		draw_circle(Vector2(0, -38), 7.0, gold, true, -1.0, true)
		draw_rect(Rect2(-2, -39, 4, 6), Color("#5a3a26"))

	if _piece > 0.0:
		var y := -60.0 - _piece * 80.0
		draw_set_transform(Vector2(0, y), sin(_t * 2.0) * 0.1)
		draw_style_box(Paint.box(Color("#f6e3b4"), 4, Color("#c9a26a"), 2), Rect2(-30, -22, 60, 44))
		draw_line(Vector2(-20, -8), Vector2(6, 4), Color("#c9a26a"), 2.0, true)
		draw_line(Vector2(6, 4), Vector2(18, -10), Color("#c9a26a"), 2.0, true)
		draw_line(Vector2(12, 6), Vector2(22, 16), Color("#e0524f"), 3.0, true)
		draw_line(Vector2(22, 6), Vector2(12, 16), Color("#e0524f"), 3.0, true)
		draw_set_transform(Vector2.ZERO)
