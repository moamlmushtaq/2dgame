class_name Rock
extends Node2D
## A floating boulder drifting at the ship. Steer around it with the helm,
## or break it with three cannon hits. Each hit leaves a crack.

const TEXTURE := preload("res://assets/art/rocks/boulder.png")

var voyage
var radius := 55.0
var speed := 230.0
var hp := 3
var _flip := false
var _spin := 0.0
var _flash := 0.0


func _ready() -> void:
	add_to_group("rocks")
	_flip = randf() < 0.5
	_spin = randf_range(-0.4, 0.4)


func _physics_process(delta: float) -> void:
	position.x -= speed * voyage.speed_factor() * delta
	_spin += delta * 0.15
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
	var tint := Color(1.9, 1.9, 1.9) if _flash > 0.0 else Color.WHITE
	var sc := radius * 2.25 / TEXTURE.get_width()
	draw_set_transform(Vector2.ZERO, _spin, Vector2(-sc if _flip else sc, sc))
	draw_texture(TEXTURE, -TEXTURE.get_size() * 0.5, tint)
	draw_set_transform(Vector2.ZERO, _spin)
	var crack := Color("#3d4450")
	if hp <= 2:
		draw_polyline(PackedVector2Array([Vector2(-radius * 0.5, -radius * 0.2), Vector2(-radius * 0.15, radius * 0.05),
			Vector2(-radius * 0.25, radius * 0.4)]), crack, 3.0, true)
	if hp <= 1:
		draw_polyline(PackedVector2Array([Vector2(radius * 0.45, -radius * 0.1), Vector2(radius * 0.1, radius * 0.15),
			Vector2(radius * 0.2, radius * 0.5)]), crack, 3.0, true)
	# Sky crystals growing out of the top.
	draw_colored_polygon(PackedVector2Array([Vector2(radius * 0.08, -radius * 0.45),
		Vector2(radius * 0.26, -radius * 0.98), Vector2(radius * 0.44, -radius * 0.42)]), Color("#8ff0ff"))
	draw_colored_polygon(PackedVector2Array([Vector2(-radius * 0.1, -radius * 0.5),
		Vector2(-radius * 0.02, -radius * 0.8), Vector2(radius * 0.12, -radius * 0.46)]), Color("#c8f8ff"))
	draw_line(Vector2(radius * 0.26, -radius * 0.9), Vector2(radius * 0.3, -radius * 0.55), Color(1, 1, 1, 0.7), 2.0, true)
	draw_set_transform(Vector2.ZERO)
