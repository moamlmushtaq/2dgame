class_name IslandProps
extends RefCounted
## Helpers shared by island puzzle pieces.


## Counts living players standing (directly or stacked on each other) above a span of ground.
static func count_standing(tree: SceneTree, x_min: float, x_max: float, ground_y: float) -> int:
	var n := 0
	for node in tree.get_nodes_in_group("players"):
		var p := node as Player
		var feet := p.global_position
		if p.is_alive() and p.is_on_floor() and feet.x > x_min and feet.x < x_max \
				and feet.y <= ground_y + 6.0 and feet.y > ground_y - 170.0:
			n += 1
	return n
