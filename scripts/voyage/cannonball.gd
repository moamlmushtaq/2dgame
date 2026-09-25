class_name Cannonball
extends Node2D
## A cannonball that pops storm birds and chips floating rocks.

const GRAVITY := 260.0

var voyage
var velocity := Vector2.ZERO
var _life := 3.0


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	_life -= delta
	for node in get_tree().get_nodes_in_group("birds"):
		var b := node as Bird
		if not b.fleeing and b.global_position.distance_to(global_position) < 28.0:
			b.kill()
			_pop()
			return
	for node in get_tree().get_nodes_in_group("rocks"):
		var r := node as Rock
		if r.global_position.distance_to(global_position) < r.radius + 6.0:
			r.damage(1)
			_pop()
			return
	if _life <= 0.0 or position.y > 900.0:
		queue_free()
	queue_redraw()


func _pop() -> void:
	Fx.burst(get_parent(), global_position, Color("#fff0c2"), 12, 180.0, 0.45)
	queue_free()


func _draw() -> void:
	var back := -velocity.normalized()
	for i in 4:
		draw_circle(back * (8.0 + i * 7.0), 5.0 - i, Color(1, 1, 1, 0.35 - i * 0.08), true, -1.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color("#2f2f40"), true, -1.0, true)
	draw_circle(Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.6), true, -1.0, true)
