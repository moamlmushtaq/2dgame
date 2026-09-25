class_name Interactable
extends Node2D
## Base for things a player can use by pressing the interact button nearby.

var interact_radius := 60.0


func _enter_tree() -> void:
	add_to_group("interactables")


func can_interact(_player: Player) -> bool:
	return true


func interact(_player: Player) -> void:
	pass


## Short action label shown in the player's hint bubble.
func hint(_player: Player) -> String:
	return ""


func interact_point() -> Vector2:
	return global_position + Vector2(0, -20)
