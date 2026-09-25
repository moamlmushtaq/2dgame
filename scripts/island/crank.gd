class_name Crank
extends Interactable
## A wheel that works only while someone keeps turning it (holding interact nearby).

const REACH := 50.0

var turning := false
## When true the crank counts as always turning (used when playing alone).
var always_on := false
var _angle := 0.0


func _ready() -> void:
	interact_radius = 56.0
	z_index = 2


func hint(_player: Player) -> String:
	return "أدِر العجلة (باستمرار)"


func _physics_process(delta: float) -> void:
	turning = always_on
	for node in get_tree().get_nodes_in_group("players"):
		var p := node as Player
		if p.station == null and p.is_alive() and p.input.held("interact") \
				and absf(p.global_position.x - global_position.x) < REACH \
				and absf(p.global_position.y - global_position.y) < 40.0:
			turning = true
			p.facing = 1 if global_position.x > p.global_position.x else -1
	if turning:
		_angle += delta * 6.0
	queue_redraw()


func _draw() -> void:
	Paint.ground_shadow(self, Vector2.ZERO, 22.0)
	draw_style_box(Paint.box(Color("#50546b"), 5), Rect2(-16, -8, 32, 9))
	draw_rect(Rect2(-5, -44, 10, 40), Color("#6f7389"))
	draw_rect(Rect2(-5, -44, 3, 40), Color("#9a9fbf"))
	var c := Vector2(0, -48)
	var metal := Color("#50546b")
	draw_arc(c, 18.0, 0.0, TAU, 28, metal, 5.0, true)
	draw_arc(c, 19.5, PI * 0.9, PI * 1.6, 12, Color(1, 1, 1, 0.3), 1.5, true)
	for i in 4:
		draw_line(c, c + Vector2.from_angle(_angle + i * TAU / 4.0) * 18.0, metal, 3.0, true)
	var handle := c + Vector2.from_angle(_angle) * 18.0
	draw_circle(handle, 5.5, Color("#d9a63a"), true, -1.0, true)
	draw_circle(handle + Vector2(-1, -1), 4.5, Color("#ffcf5c"), true, -1.0, true)
	draw_circle(c, 5.0, Color("#ffcf5c") if turning else Color("#9a9cb8"), true, -1.0, true)
	draw_circle(c + Vector2(-1.5, -1.5), 1.6, Color(1, 1, 1, 0.6), true, -1.0, true)
