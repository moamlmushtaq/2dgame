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
	Fx.sparks(get_parent(), global_position + Vector2(0, -20), Color("#ffe08a"), 14, 300.0, 500.0)
	Fx.flash(get_parent(), global_position + Vector2(0, -20), 60.0, Color(1, 0.95, 0.7, 0.7), 0.25)


func hint(_player: Player) -> String:
	return "اسحب الرافعة"


func _process(delta: float) -> void:
	_angle = lerpf(_angle, 0.6 if on else -0.6, minf(10.0 * delta, 1.0))
	queue_redraw()


func _draw() -> void:
	Paint.ground_shadow(self, Vector2(0, 0), 24.0)
	var pivot := Vector2(0, -6)
	var tip := pivot + Vector2.from_angle(-PI * 0.5 + _angle) * 34.0
	var knob := Color("#5fd49a") if on else Color("#ff6f7d")
	draw_line(pivot, tip, Color("#4b4f68"), 6.0, true)
	draw_line(pivot + Vector2(-1, 0), tip + Vector2(-1, 0), Color("#9a9fbf"), 2.0, true)
	draw_circle(tip, 8.0, knob.darkened(0.25), true, -1.0, true)
	draw_circle(tip + Vector2(-0.5, -0.5), 7.0, knob, true, -1.0, true)
	draw_circle(tip + Vector2(-2.5, -2.5), 2.4, Color(1, 1, 1, 0.7), true, -1.0, true)
	# Stone base with a lit top edge.
	draw_style_box(Paint.box(Color("#3f4257"), 6), Rect2(-20, -11, 40, 12))
	draw_style_box(Paint.box(Color("#50546b"), 5), Rect2(-19, -11, 38, 9))
	draw_line(Vector2(-15, -10), Vector2(15, -10), Color(1, 1, 1, 0.25), 2.0)
	draw_circle(pivot, 4.0, Color("#ffd27a"), true, -1.0, true)
