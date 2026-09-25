class_name Station
extends Interactable
## An Interactable a player climbs into and then operates with their own controls.

var occupant: Player = null


func can_interact(player: Player) -> bool:
	return occupant == null and player.carrying == ""


func interact(player: Player) -> void:
	player.enter_station(self)


func seat_position() -> Vector2:
	return global_position


## Called every physics frame by the occupant after it has polled its input.
func control(_player: Player, _delta: float) -> void:
	pass
