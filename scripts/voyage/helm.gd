class_name Helm
extends Station
## The ship's wheel. Up/down raises or lowers the ship to dodge floating rocks.

const CLIMB_SPEED := 190.0
const MAX_ALTITUDE := 260.0

var voyage
var _wheel := 0.0


func _ready() -> void:
	interact_radius = 56.0
	z_index = 6


func hint(_player: Player) -> String:
	return "الدفة"


func seat_position() -> Vector2:
	return global_position + Vector2(-28, 0)


func control(player: Player, delta: float) -> void:
	var climb := -player.input.axis_y()
	voyage.altitude = clampf(voyage.altitude + climb * CLIMB_SPEED * delta, -MAX_ALTITUDE, MAX_ALTITUDE)
	_wheel += climb * 4.0 * delta
	player.facing = 1


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var wood := Color("#7a4a2a")
	draw_rect(Rect2(-5, -40, 10, 40), Color("#8a5436"))
	var c := Vector2(0, -46)
	for i in 8:
		var d := Vector2.from_angle(_wheel + i * TAU / 8.0)
		draw_line(c, c + d * 28.0, wood, 3.0, true)
		draw_circle(c + d * 30.0, 3.5, wood, true, -1.0, true)
	draw_arc(c, 21.0, 0.0, TAU, 32, wood, 5.0, true)
	draw_circle(c, 6.0, Ship.GOLD, true, -1.0, true)
	if occupant != null:
		var col := Color(occupant.color, 0.9)
		draw_colored_polygon(PackedVector2Array([Vector2(34, -70), Vector2(44, -56), Vector2(24, -56)]), col)
		draw_colored_polygon(PackedVector2Array([Vector2(34, -26), Vector2(44, -40), Vector2(24, -40)]), col)
