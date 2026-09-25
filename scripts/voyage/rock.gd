class_name Rock
extends Node2D
## A floating boulder drifting at the ship. Steer around it with the helm,
## or break it with three cannon hits.

var voyage
var radius := 55.0
var speed := 230.0
var hp := 3
var _pts := PackedVector2Array()
var _spin := 0.0
var _flash := 0.0


func _ready() -> void:
	add_to_group("rocks")
	for i in 11:
		var a := TAU * i / 11.0
		var r := radius * randf_range(0.8, 1.08)
		_pts.append(Vector2(cos(a) * r, sin(a) * r * 0.85))


func _physics_process(delta: float) -> void:
	position.x -= speed * voyage.speed_factor() * delta
	_spin += delta * 0.3
	_flash -= delta
	if voyage.is_sailing() and _hits_hull():
		voyage.rock_hit(self)
		return
	if global_position.x < -400.0:
		queue_free()
	queue_redraw()


func _hits_hull() -> bool:
	var r := Ship.HULL_RECT
	var g := global_position
	var closest := Vector2(clampf(g.x, r.position.x, r.end.x), clampf(g.y, r.position.y, r.end.y))
	return g.distance_to(closest) < radius * 0.85


## True when the rock will hit the hull if the ship keeps its current altitude.
func on_collision_course() -> bool:
	var r := Ship.HULL_RECT
	var y := global_position.y
	return y + radius * 0.85 > r.position.y and y - radius * 0.85 < r.end.y


func damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	_flash = 0.12
	Sound.play("coal", -2.0, 0.7)
	if hp <= 0:
		voyage.rock_destroyed(self)


func _draw() -> void:
	var base := Color("#9a8aa6") if _flash <= 0.0 else Color.WHITE
	draw_set_transform(Vector2.ZERO, _spin)
	draw_colored_polygon(_pts, base.darkened(0.3))
	var top := PackedVector2Array()
	for p in _pts:
		top.append(p * 0.8 + Vector2(-radius * 0.1, -radius * 0.12))
	draw_colored_polygon(top, base)
	draw_line(Vector2(-radius * 0.35, -radius * 0.1), Vector2(radius * 0.1, radius * 0.25), base.darkened(0.45), 3.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(radius * 0.2, -radius * 0.5),
		Vector2(radius * 0.36, -radius * 0.98), Vector2(radius * 0.52, -radius * 0.48)]), Color("#8ff0ff"))
	draw_colored_polygon(PackedVector2Array([Vector2(radius * 0.02, -radius * 0.55),
		Vector2(radius * 0.1, -radius * 0.82), Vector2(radius * 0.22, -radius * 0.52)]), Color("#c8f8ff"))
	draw_set_transform(Vector2.ZERO)
