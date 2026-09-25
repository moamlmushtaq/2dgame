class_name PressurePlate
extends Node2D
## A stone plate that stays pressed while at least `need` sailors stand on it.

var need := 1
var width := 70.0
var count := 0
var pressed := false


func _physics_process(_delta: float) -> void:
	var gx := global_position.x
	count = IslandProps.count_standing(get_tree(), gx - width * 0.5 - 6.0, gx + width * 0.5 + 6.0, global_position.y)
	var was := pressed
	pressed = count >= need
	if pressed != was:
		Sound.play("click", -4.0, 1.4 if pressed else 1.0)
	queue_redraw()


func _draw() -> void:
	var sink := 4.0 if pressed else 0.0
	Paint.ground_shadow(self, Vector2(0, 1), width * 0.55, 0.15)
	draw_style_box(Paint.box(Color("#55506b"), 6), Rect2(-width * 0.5 - 4.0, -6, width + 8.0, 8))
	draw_line(Vector2(-width * 0.5 - 1.0, -5.0), Vector2(width * 0.5 + 1.0, -5.0), Color(1, 1, 1, 0.18), 1.5)
	var top := Color("#7dffa8") if pressed else Color("#ffcf5c")
	draw_style_box(Paint.box(top.darkened(0.2), 5), Rect2(-width * 0.5, -10.0 + sink, width, 8))
	draw_style_box(Paint.box(top, 4), Rect2(-width * 0.5 + 1.0, -10.0 + sink, width - 2.0, 5))
	draw_line(Vector2(-width * 0.5 + 6.0, -9.0 + sink), Vector2(width * 0.5 - 6.0, -9.0 + sink), Color(1, 1, 1, 0.5), 1.5)
	if pressed:
		draw_circle(Vector2(0, -8), width * 0.6, Color(0.5, 1, 0.7, 0.15), true, -1.0, true)
	for i in need:
		var x := (i - (need - 1) * 0.5) * 16.0
		var filled := i < count
		draw_circle(Vector2(x, -24), 6.0, Color.WHITE if filled else Color(1, 1, 1, 0.35), true, -1.0, true)
		draw_arc(Vector2(x, -24), 6.0, 0.0, TAU, 16, Color("#5a4f7a"), 2.0, true)
