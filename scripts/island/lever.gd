class_name Lever
extends Interactable
## A one-shot lever. Pull it once and it emits `pulled`.

signal pulled

var on := false
var _angle := -0.6


func _ready() -> void:
	interact_radius = 56.0
	z_index = 2


func can_interact(_player: Player) -> bool:
	return not on


func interact(_player: Player) -> void:
	on = true
	Sound.play("lever")
	pulled.emit()
	Fx.burst(get_parent(), global_position + Vector2(0, -20), Color("#fff4c2"), 16, 160.0, 0.45)


func hint(_player: Player) -> String:
	return "اسحب الرافعة"


func _process(delta: float) -> void:
	_angle = lerpf(_angle, 0.6 if on else -0.6, minf(10.0 * delta, 1.0))
	queue_redraw()


func _draw() -> void:
	var tip := Vector2(0, -6) + Vector2.from_angle(-PI * 0.5 + _angle) * 34.0
	draw_line(Vector2(0, -6), tip, Color("#6f7389"), 5.0, true)
	draw_circle(tip, 7.0, Color("#5fd49a") if on else Color("#ff6f7d"), true, -1.0, true)
	draw_style_box(Paint.box(Color("#50546b"), 5), Rect2(-18, -10, 36, 10))
