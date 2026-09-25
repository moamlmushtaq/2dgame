class_name BotBrain
extends RefCounted
## Drives a computer-controlled sailor so someone playing alone still has a crew.
##
## Each physics frame it looks at the scene, picks a job and "presses" virtual buttons
## through its PlayerInput, so bots obey exactly the same rules as human players.
##
## On the ship the first bot is a deckhand: it takes the most urgent job nobody else has
## (steering around a rock, patching holes, stoking the furnace), and waits at a cannon
## when all is calm. Any further bots are gunners that stay at the cannons unless the
## ship is in real trouble, so birds are shot down before they can make holes. On an island it follows the
## human leader and lends a hand with each puzzle: standing still as a step at tall walls,
## holding pressure plates and cranks, ringing its bell together with the leader, riding
## lifts and clouds, pulling levers and picking up nearby crystals.

# Ship levels, by the height of what the bot stands on.
const DECK := 0
const CRATE := 1
const QUARTER := 2
const NEST := 3
const LEVEL_Y := [520.0, 465.0, 420.0, 400.0]

var player: Player

var _want := {}
var _last := {}
var _jump_hold := 0.0
var _task := ""
var _task_node: Node = null
var _claim_key := ""
var _rethink := 0.0
var _idle := 0.0
var _wait := 0.0
var _stuck := 0.0
var _last_x := 0.0
var _far_time := 0.0
var _climbing := false
var _vaulting := false
var _steer_rock: Node = null
var _steer_up := false
var _gem: Node = null
var _gem_time := 0.0
var _scene_id := 0
var _cache := {}


## Returns the buttons held this frame, e.g. {"right": true, "jump": true}.
func decide() -> Dictionary:
	_want = {}
	if player == null or not is_instance_valid(player) or not player.is_inside_tree() \
			or not player.is_alive() or player.frozen:
		_last = {}
		return {}
	var scene := player.get_parent()
	var delta := player.get_physics_process_delta_time()
	if scene.get_instance_id() != _scene_id:
		_scene_id = scene.get_instance_id()
		_cache = {}
		_task = ""
		_task_node = null
		_claim_key = ""
	if scene.has_method("is_sailing"):
		if scene.is_sailing():
			_voyage(scene, delta)
		else:
			_release(scene)
	elif "checkpoints" in scene and not scene.won:
		_island(scene, delta)
	_unstick(delta)
	if _jump_hold > 0.0:
		_jump_hold -= delta
		_want["jump"] = true
	_last = _want.duplicate()
	return _want.duplicate()


# --- Button helpers ------------------------------------------------------------

## Presses a button for one frame (never two frames in a row, so it registers as a press).
func _tap(action: String) -> void:
	if not _last.get(action, false):
		_want[action] = true


## Starts a full-height jump by holding jump for a moment.
func _jump() -> void:
	if _jump_hold <= 0.0 and not _last.get("jump", false) and player.is_on_floor():
		_jump_hold = 0.34
		_want["jump"] = true


func _move(dir: float) -> void:
	if dir > 0.0:
		_want["right"] = true
	elif dir < 0.0:
		_want["left"] = true


## Hops when the bot has been pushing against something without moving.
func _unstick(delta: float) -> void:
	var pushing: bool = _want.get("left", false) or _want.get("right", false)
	if pushing and player.station == null and absf(player.global_position.x - _last_x) < 0.5:
		_stuck += delta
		if _stuck > 0.6:
			_stuck = 0.0
			_jump()
	else:
		_stuck = 0.0
	_last_x = player.global_position.x


func _nodes(scene: Node, cls: String) -> Array:
	if not _cache.has(cls):
		var found: Array = []
		for n in scene.get_children():
			var s: Script = n.get_script()
			if s != null and s.get_global_name() == cls:
				found.append(n)
		_cache[cls] = found
	var alive: Array = []
	for n in _cache[cls]:
		if is_instance_valid(n):
			alive.append(n)
	return alive


func _first(scene: Node, cls: String) -> Node:
	var all := _nodes(scene, cls)
	return all[0] if not all.is_empty() else null


# --- Job claims so bots split the work ------------------------------------------

func _claims(scene: Node) -> Dictionary:
	if not scene.has_meta("bot_claims"):
		scene.set_meta("bot_claims", {})
	return scene.get_meta("bot_claims")


func _free(scene: Node, key: String) -> bool:
	var owner = _claims(scene).get(key)
	return owner == null or owner == self or not is_instance_valid(owner.player) or owner._claim_key != key


func _set_task(scene: Node, task: String, key: String, node: Node) -> void:
	var claims := _claims(scene)
	if _claim_key != "" and claims.get(_claim_key) == self:
		claims.erase(_claim_key)
	_task = task
	_task_node = node
	_claim_key = key
	if key != "":
		claims[key] = self


func _release(scene: Node) -> void:
	if _task != "" or _claim_key != "":
		_set_task(scene, "", "", null)


# --- On the ship ---------------------------------------------------------------

func _voyage(v: Node, delta: float) -> void:
	var p := player
	if p.station is Helm:
		_steer(v, p.station, delta)
		return
	if p.station is Cannon:
		_gun(v, p.station, delta)
		return
	if p.carrying == "coal":
		_use(_first(v, "Furnace"))
		return
	_rethink -= delta
	if _rethink <= 0.0 or not _task_still_valid(v):
		_rethink = 0.4
		_choose_voyage_task(v)
	match _task:
		"helm", "cannon":
			_use(_task_node)
		"hole":
			_fix_hole(_task_node)
		"coal":
			_use(_task_node)
		_:
			_nav(Vector2(560.0 + p.slot * 70.0, Ship.DECK_Y))


func _task_still_valid(v: Node) -> bool:
	if _task == "":
		return true
	if not is_instance_valid(_task_node):
		return false
	if _task_node is Station:
		return (_task_node as Station).occupant == null
	if _task == "coal":
		return v.fuel < 92.0
	return true


## 0 for the first bot (the deckhand), 1+ for gunners.
func _rank(v: Node) -> int:
	var r := 0
	for p in v.players:
		if p.input.is_bot() and p.slot < player.slot:
			r += 1
	return r


func _choose_voyage_task(v: Node) -> void:
	if _rank(v) >= 1 and not _needed_elsewhere(v):
		var post := _best_cannon(v, true)
		if post != null:
			_set_task(v, "cannon", "cannon:%d" % post.get_instance_id(), post)
			return
	var helm := _first(v, "Helm") as Helm
	if helm != null and helm.occupant == null and _danger_rock(v) != null and _free(v, "helm"):
		_set_task(v, "helm", "helm", helm)
		return

	var best: Node = null
	var best_d := INF
	for h in v.holes:
		var key := "hole:%d" % h.get_instance_id()
		if not _free(v, key):
			continue
		var d := absf(h.global_position.x - player.global_position.x)
		if d < best_d:
			best_d = d
			best = h
	if best != null:
		_set_task(v, "hole", "hole:%d" % best.get_instance_id(), best)
		return

	var pile := _first(v, "CoalPile")
	if v.fuel < 45.0 and not _someone_carrying(v) and _free(v, "coal"):
		_set_task(v, "coal", "coal", pile)
		return

	var cannon := _best_cannon(v)
	if cannon != null:
		_set_task(v, "cannon", "cannon:%d" % cannon.get_instance_id(), cannon)
		return

	if v.fuel < 70.0 and not _someone_carrying(v) and _free(v, "coal"):
		_set_task(v, "coal", "coal", pile)
		return
	# Nothing urgent: wait at a free cannon, ready for the next wave.
	var idle_cannon := _best_cannon(v, true)
	if idle_cannon != null:
		_set_task(v, "cannon", "cannon:%d" % idle_cannon.get_instance_id(), idle_cannon)
		return
	_set_task(v, "", "", null)


## A gunner hops off when holes need hands or the furnace is nearly out.
func _needed_elsewhere(v: Node) -> bool:
	if _rank(v) >= 1:
		# Gunners leave in an emergency, or to patch a hole while the sky is clear.
		if (v.holes.size() >= 3 and v.hp < 60.0) or (v.fuel < 12.0 and not _someone_carrying(v) and _free(v, "coal")):
			return true
		var post: Cannon = _task_node as Cannon if is_instance_valid(_task_node) and _task_node is Cannon else null
		if not _pick_target(v, post).is_empty():
			return false
		if post != null and not _sky_clear(v):
			return false
		for h in v.holes:
			if _free(v, "hole:%d" % h.get_instance_id()) and not _hole_has_fixer(v, h):
				return true
		return false
	if v.fuel < 30.0 and not _someone_carrying(v) and _free(v, "coal"):
		return true
	var helm := _first(v, "Helm") as Helm
	if helm != null and helm.occupant == null and _danger_rock(v) != null and _free(v, "helm") \
			and _pick_target(v, _task_node as Cannon if is_instance_valid(_task_node) and _task_node is Cannon else null).is_empty():
		return true
	for h in v.holes:
		if _free(v, "hole:%d" % h.get_instance_id()) and not _hole_has_fixer(v, h):
			return true
	return false


## No birds, bombs or pirates around (so a gunner can step away for a moment).
func _sky_clear(v: Node) -> bool:
	for node in v.get_tree().get_nodes_in_group("birds"):
		if not (node as Bird).fleeing:
			return false
	return v.get_tree().get_nodes_in_group("bombs").is_empty() and (v.boss == null or v.boss.sinking)


func _hole_has_fixer(v: Node, hole: Node) -> bool:
	for p in v.players:
		if p != player and p.station == null and absf(p.global_position.x - (hole as Node2D).global_position.x) < Hole.REACH \
				and _level(p.global_position.y) == DECK:
			return true
	return false


func _someone_carrying(v: Node) -> bool:
	for p in v.players:
		if p != player and p.carrying == "coal":
			return true
	return false


func _danger_rock(v: Node) -> Rock:
	var best: Rock = null
	for node in v.get_tree().get_nodes_in_group("rocks"):
		var r := node as Rock
		var x := r.global_position.x
		if r.on_collision_course() and x > 1150.0 and x < 2150.0 and (best == null or x < best.global_position.x):
			best = r
	return best


func _best_cannon(v: Node, even_without_targets := false) -> Cannon:
	var best: Cannon = null
	var best_d := INF
	for c in _nodes(v, "Cannon"):
		var cannon := c as Cannon
		if cannon.occupant != null or not _free(v, "cannon:%d" % cannon.get_instance_id()):
			continue
		if not even_without_targets and _pick_target(v, cannon).is_empty():
			continue
		var d := cannon.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = cannon
	return best


## Walks to a station or prop and presses interact once it is in reach.
func _use(node: Node) -> void:
	if node == null:
		return
	var target := (node as Node2D).global_position
	var arrived := _nav(target + Vector2(-18.0, 0))
	if (arrived or player.target == node) and player.target == node:
		_tap("interact")


func _fix_hole(hole: Node) -> void:
	var hx: float = (hole as Node2D).global_position.x
	var on_deck := _level(player.global_position.y) == DECK and player.is_on_floor()
	if on_deck and absf(player.global_position.x - hx) < Hole.REACH - 8.0:
		_want["interact"] = true
	else:
		_nav(Vector2(hx, Ship.DECK_Y))


func _steer(v: Node, helm: Helm, delta: float) -> void:
	var rock := _danger_rock(v)
	if rock == null:
		_idle += delta
		if _idle > 1.5:
			_idle = 0.0
			_tap("interact")
			_release(v)
		return
	_idle = 0.0
	if rock != _steer_rock:
		# Plan once per rock: the shorter move that stays within the helm's range.
		_steer_rock = rock
		var hull := Ship.HULL_RECT
		var r := rock.radius * 0.85 + 12.0
		var raise_by := hull.end.y - (rock.global_position.y - r)   # climb so it passes below
		var lower_by := (rock.global_position.y + r) - hull.position.y  # dive so it passes above
		var can_raise: bool = v.altitude + raise_by <= Helm.MAX_ALTITUDE
		var can_lower: bool = v.altitude - lower_by >= -Helm.MAX_ALTITUDE
		_steer_up = can_raise and (raise_by < lower_by or not can_lower)
	_want["up" if _steer_up else "down"] = true


func _gun(v: Node, cannon: Cannon, delta: float) -> void:
	if _needed_elsewhere(v):
		_tap("interact")
		_release(v)
		return
	var target := _pick_target(v, cannon)
	if target.is_empty():
		# Nothing to shoot: point the barrel at where birds come from and wait.
		var rest := clampf(-0.5, cannon.min_angle, cannon.max_angle)
		var d := angle_difference(cannon.angle, rest)
		if absf(d) > 0.05:
			_want["down" if d > 0.0 else "up"] = true
		return
	var diff := angle_difference(cannon.angle, target["angle"])
	if diff > 0.03:
		_want["down"] = true
	elif diff < -0.03:
		_want["up"] = true
	if absf(diff) < 0.07 and cannon._cooldown <= 0.0:
		_tap("jump")


## The most urgent thing this cannon can hit: {"angle": float} or empty.
func _pick_target(v: Node, cannon: Cannon) -> Dictionary:
	if cannon == null:
		return {}
	var origin := cannon.global_position + Cannon.PIVOT
	var options: Array = []  # [priority, position, velocity]
	for node in v.get_tree().get_nodes_in_group("bombs"):
		var b := node as Bomb
		var vel := (b.target - b.start) / b.flight + Vector2(0, -b.arc * 4.0 * (1.0 - 2.0 * b._k) / b.flight)
		options.append([0, b.global_position, vel])
	for node in v.get_tree().get_nodes_in_group("birds"):
		var bird := node as Bird
		if not bird.fleeing:
			options.append([1, bird.global_position, bird._vel])
	if v.boss != null and not v.boss.sinking:
		options.append([2, v.boss.global_transform * (v.boss._xf * Vector2(655, 200)), Vector2.ZERO])
	for node in v.get_tree().get_nodes_in_group("rocks"):
		var r := node as Rock
		if r.on_collision_course() and r.global_position.x < 1500.0:
			options.append([3, r.global_position, Vector2(-r.speed * v.speed_factor(), 0)])
	options.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and origin.distance_to(a[1]) < origin.distance_to(b[1])))
	for o in options:
		var pos: Vector2 = o[1]
		if pos.x < -60.0 or pos.x > 1480.0 or pos.y < -40.0:
			continue
		var aim := pos
		for i in 3:
			var t := origin.distance_to(aim) / Cannon.BALL_SPEED
			aim = pos + (o[2] as Vector2) * t + Vector2(0, -0.5 * Cannonball.GRAVITY * t * t)
		var angle := (aim - origin).angle()
		if angle >= cannon.min_angle - 0.02 and angle <= cannon.max_angle + 0.02:
			return {"angle": clampf(angle, cannon.min_angle, cannon.max_angle)}
	return {}


func _level(y: float) -> int:
	for i in LEVEL_Y.size():
		if absf(y - LEVEL_Y[i]) < 12.0:
			return i
	return -1


## Moves around the ship's decks toward `target`. Returns true once there.
func _nav(target: Vector2) -> bool:
	var p := player
	var x := p.global_position.x
	var goal := _level(target.y)
	if not p.is_on_floor():
		_move(signf(target.x - x) if absf(target.x - x) > 8.0 else 0.0)
		return false
	var here := _level(p.global_position.y)
	if here == -1:
		# Standing on someone's head: step off toward the target.
		var dir := signf(target.x - x)
		_move(dir if dir != 0.0 else (1.0 if player.slot % 2 == 0 else -1.0))
		return false
	if here == goal or goal == -1:
		return _walk(target.x, 12.0)
	if here == QUARTER or here == NEST:
		_want["down"] = true
		_tap("jump")
		return false
	if here == CRATE:
		if goal == NEST:
			_want["right"] = true
			if x > 492.0:
				_jump()
		else:
			_move(signf(target.x - x))
		return false
	if goal == QUARTER:
		_walk(target.x, 4.0)
		if absf(target.x - x) < 40.0:
			_jump()
		return false
	# Up to the crate (and on to the crow's nest).
	var from_left := x < 500.0
	var stand := 440.0 if from_left else 560.0
	if absf(x - stand) < 14.0:
		_jump()
		_want["right" if from_left else "left"] = true
	else:
		_walk(stand, 6.0)
	return false


func _walk(x: float, tol: float) -> bool:
	var dx := x - player.global_position.x
	if absf(dx) <= tol:
		return true
	_move(signf(dx))
	return false


# --- On an island --------------------------------------------------------------

func _island(isl: Node, delta: float) -> void:
	var p := player
	var leader := _leader(isl)
	if leader == null:
		return
	# Too far behind (stuck somewhere unexpected): hop back in next to the leader.
	if p.global_position.distance_to(leader.global_position) > 1400.0:
		_far_time += delta
		if _far_time > 6.0:
			_far_time = 0.0
			p.respawn_point = leader.respawn_point
			p.checkpoint = leader.checkpoint
			p.fall_out()
			return
	else:
		_far_time = 0.0

	if not p.is_on_floor():
		# Riding an updraft: once high enough, drift onto the ledge.
		var vent := _first(isl, "WindVent") as WindVent
		if vent != null and absf(p.global_position.x - vent.global_position.x) < 140.0 \
				and p.global_position.y < vent.global_position.y - 250.0:
			_want["right"] = true
			return
	if _bells(isl, leader):
		return
	if _cranks(isl, leader):
		return
	if _gate(isl, leader):
		return
	if _levers(isl):
		return
	if _tall_wall(isl, leader, delta):
		return
	if _gems(isl, leader, delta):
		return
	_follow(leader)


func _leader(isl: Node) -> Player:
	var best: Player = null
	for p in isl.players:
		if p.input.is_bot() or not p.is_alive():
			continue
		if best == null or p.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
			best = p
	return best


func _same_level(a: float, b: float, tol := 30.0) -> bool:
	return absf(a - b) < tol


## True if there is something to stand on a step ahead in direction `dir`.
func _ground_ahead(dir: float) -> bool:
	var from := player.global_position + Vector2(dir * 22.0, -8.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 420), Player.LAYER_WORLD | Player.LAYER_ONE_WAY)
	query.exclude = [player.get_rid()]
	return not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Walks toward x without stepping into a gap; jumps over steps. Returns true once there.
func _iwalk(x: float, tol := 12.0) -> bool:
	var dx := x - player.global_position.x
	if absf(dx) <= tol:
		return true
	var dir := signf(dx)
	if player.is_on_floor() and not _ground_ahead(dir):
		return false
	_move(dir)
	if player.is_on_floor() and player.is_on_wall():
		_jump()
	return false


func _follow(leader: Player) -> void:
	var p := player
	var gap := 55.0 + p.slot * 18.0
	var dx := leader.global_position.x - p.global_position.x
	if absf(dx) < gap:
		return
	_iwalk(leader.global_position.x - signf(dx) * gap * 0.8, 10.0)
	if leader.global_position.y < p.global_position.y - 50.0 and p.is_on_wall():
		_jump()


func _levers(isl: Node) -> bool:
	if not player.is_on_floor():
		return false
	for n in _nodes(isl, "Lever"):
		var lever := n as Lever
		if lever.on or not _same_level(lever.global_position.y, player.global_position.y):
			continue
		if absf(lever.global_position.x - player.global_position.x) > 420.0:
			continue
		if player.target == lever:
			_tap("interact")
		else:
			_iwalk(lever.global_position.x - 16.0, 8.0)
		return true
	return false


## Blossom Isle's tall wall: stand against it so the leader can climb on our head.
## If the leader keeps waiting at the wall, climb on the leader instead.
func _tall_wall(isl: Node, leader: Player, delta: float) -> bool:
	var step := _first(isl, "RisingStep") as RisingStep
	if step == null or step._raised:
		_climbing = false
		return false
	var wall_x := step.global_position.x + step.size.x
	var ground := step.global_position.y
	var p := player
	if p.global_position.x > wall_x:
		_climbing = false
		_vaulting = false
		return false
	# Standing on the leader's head: jump for the top of the wall.
	if p.is_on_floor() and p.global_position.y < ground - 30.0:
		_vaulting = true
		_want["right"] = true
		_jump()
		return true
	if not p.is_on_floor():
		if _vaulting:
			_want["right"] = true
		return _climbing or _vaulting
	_vaulting = false
	var bot_below := _same_level(p.global_position.y, ground, 20.0)
	var leader_near := leader.global_position.x > wall_x - 320.0 and leader.global_position.x < wall_x
	if not bot_below or not (leader_near or leader.global_position.y < ground - 60.0):
		_climbing = false
		return false
	var leader_waiting := leader.is_on_floor() and _same_level(leader.global_position.y, ground, 20.0) \
			and absf(leader.global_position.x - (wall_x - 16.0)) < 110.0
	if _climbing:
		# Stand inside the leader (sailors pass through each other), then hop straight up
		# onto their head.
		if not leader_waiting:
			_climbing = false
		elif absf(leader.global_position.x - p.global_position.x) > 4.0:
			_move(signf(leader.global_position.x - p.global_position.x))
		else:
			_jump()
		return true
	if not _iwalk(wall_x - 16.0, 6.0):
		return true
	_wait = _wait + delta if leader_waiting else 0.0
	if _wait > 5.0:
		_wait = 0.0
		_climbing = true
	return true


func _gate(isl: Node, leader: Player) -> bool:
	var gate := _first(isl, "Gate") as Gate
	if gate == null or gate.plates.size() < 2:
		return false
	var a := gate.plates[0]
	var b := gate.plates[1]
	var p := player
	var x := p.global_position.x
	if x < a.global_position.x - 160.0 or x > b.global_position.x + 160.0 \
			or not _same_level(p.global_position.y, gate._closed_y, 60.0):
		return false
	var gx := gate.global_position.x
	var open := gate.global_position.y < gate._closed_y - 120.0
	var bot_left := x < gx
	var leader_left := leader.global_position.x < gx
	if bot_left:
		if leader_left:
			var leader_on_a := absf(leader.global_position.x - a.global_position.x) < a.width * 0.5 + 6.0
			if leader_on_a and open:
				_iwalk(gx + 70.0)
			else:
				_iwalk(a.global_position.x, 10.0)
		elif open:
			_iwalk(gx + 70.0)
		else:
			_iwalk(gx - 45.0)
		return true
	if leader_left:
		_iwalk(b.global_position.x, 10.0)
		return true
	return false


## Wind Isle's vent: turn a crank for the leader, or ride the updraft ourselves.
func _cranks(isl: Node, leader: Player) -> bool:
	var vent := _first(isl, "WindVent") as WindVent
	if vent == null or vent.cranks.size() < 2:
		return false
	var low := vent.cranks[0]
	var high := vent.cranks[1]
	var p := player
	var bot_low := _same_level(p.global_position.y, low.global_position.y) and p.global_position.x < vent.global_position.x + 60.0
	var bot_high := _same_level(p.global_position.y, high.global_position.y) and p.global_position.x > vent.global_position.x
	var leader_low := leader.global_position.y > high.global_position.y + 40.0
	var leader_high := leader.global_position.y < high.global_position.y + 20.0
	var leader_at_vent := absf(leader.global_position.x - vent.global_position.x) < vent.width * 0.5 + 30.0
	var leader_at_low_crank := absf(leader.global_position.x - low.global_position.x) < 40.0
	if bot_low and leader_low:
		if leader_at_vent:
			_hold_crank(low)
			return true
		if leader_at_low_crank:
			_iwalk(vent.global_position.x, 8.0)
			return true
		return false
	if bot_low and leader_high:
		_iwalk(vent.global_position.x, 8.0)
		return true
	if bot_high and leader_low and (leader_at_vent or leader.wind_time > 0.0):
		_hold_crank(high)
		return true
	if bot_high and not leader_low and leader.wind_time > 0.0:
		_hold_crank(high)
		return true
	return false


func _hold_crank(crank: Crank) -> void:
	if _iwalk(crank.global_position.x - 20.0, 10.0) or absf(player.global_position.x - crank.global_position.x) < Crank.REACH - 6.0:
		_want["interact"] = true


## Wind Isle's bells: wait at a bell and ring the moment another one rings.
func _bells(isl: Node, leader: Player) -> bool:
	var bridge := _first(isl, "BellBridge") as BellBridge
	if bridge == null or bridge.built or bridge.bells.is_empty():
		return false
	var bells: Array[Bell] = bridge.bells
	var lo := INF
	var hi := -INF
	for bell in bells:
		lo = minf(lo, bell.global_position.x)
		hi = maxf(hi, bell.global_position.x)
	var p := player
	if p.global_position.x < lo - 260.0 or p.global_position.x > hi + 120.0 \
			or not _same_level(p.global_position.y, bells[0].global_position.y):
		return false
	if leader.global_position.x < lo - 700.0:
		return false

	# Pick a bell: the one furthest from the leader that nobody else is taking.
	var mine: Bell = null
	var best := -INF
	for bell in bells:
		var key := "bell:%d" % bell.get_instance_id()
		if not _free(isl, key):
			continue
		var d := absf(bell.global_position.x - leader.global_position.x)
		if d > best:
			best = d
			mine = bell
	if mine == null:
		return false
	if _claim_key != "bell:%d" % mine.get_instance_id():
		_set_task(isl, "bell", "bell:%d" % mine.get_instance_id(), mine)
	if player.target != mine:
		_iwalk(mine.global_position.x, 14.0)
		return true
	for bell in bells:
		if bell != mine and bell.since_rung() < 0.5:
			_tap("interact")
			return true
	# With no human at any bell, the first bot starts and the others echo it.
	var everyone_there := true
	var human_there := false
	for bell in bells:
		var attended := false
		for q in isl.players:
			if absf(q.global_position.x - bell.global_position.x) < 45.0 and _same_level(q.global_position.y, bell.global_position.y):
				attended = true
				human_there = human_there or not q.input.is_bot()
		everyone_there = everyone_there and attended
	if everyone_there and not human_there and mine == bells[0] and mine.since_rung() > 2.5:
		_tap("interact")
	return true


func _gems(isl: Node, leader: Player, delta: float) -> bool:
	var p := player
	if not p.is_on_floor() and _gem == null:
		return false
	if _gem != null and (not is_instance_valid(_gem) or _gem_time > 4.0):
		_gem = null
	if _gem == null:
		_gem_time = 0.0
		for n in _nodes(isl, "Gem"):
			var g := n as Node2D
			var dx := absf(g.global_position.x - p.global_position.x)
			var dy := p.global_position.y - g.global_position.y
			if dx < 170.0 and dy > -20.0 and dy < 130.0 and leader.global_position.distance_to(g.global_position) < 600.0:
				_gem = g
				break
	if _gem == null:
		return false
	_gem_time += delta
	var gx: float = (_gem as Node2D).global_position.x
	var close := _iwalk(gx, 10.0)
	if (close or absf(gx - p.global_position.x) < 40.0) and (_gem as Node2D).global_position.y < p.global_position.y - 30.0:
		_jump()
	return true
