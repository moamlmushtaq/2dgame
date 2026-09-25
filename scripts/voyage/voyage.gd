extends Node2D
## The airship voyage: keep the ship fed, patched and on course until the island is reached.
##
## Jobs on board: shovel coal into the furnace, steer with the helm to dodge rocks,
## shoot storm birds with the two cannons, and hammer holes shut.
## Once every map piece is found, the last voyage is a battle with the pirate flagship.

enum State { SAILING, ARRIVED, WRECKED }

const VOYAGE_TIME := 100.0
const MAX_HOLES := 7

var state := State.SAILING
var hp := 100.0
var fuel := 75.0
var distance := 0.0
var altitude := 0.0
var elapsed := 0.0
var banner := ""
var banner_time := 0.0
var end_time := 0.0

var players: Array[Player] = []
var holes: Array[Hole] = []
var sky: SkyBackdrop
var ship: Ship
var hazards: Node2D
var effects: Node2D
var camera: Camera2D
## The pirate flagship on the final voyage, otherwise null.
var boss: PirateShip = null

var _diff := 0.0
var _rock_timer := 12.0
var _bird_timer := 7.0
var _shake := 0.0
var _tips: Array = []
var _first_hole := true


func _ready() -> void:
	Game.ensure_players()
	_diff = Game.difficulty()
	Sound.play_music("voyage")
	var final := Game.is_final_voyage()

	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	sky = SkyBackdrop.new()
	back.add_child(sky)

	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)

	hazards = Node2D.new()
	hazards.z_index = -1
	add_child(hazards)

	ship = Ship.new()
	add_child(ship)

	_add_station(Furnace.new(), Vector2(262, Ship.DECK_Y))
	_add_station(CoalPile.new(), Vector2(890, Ship.DECK_Y))
	_add_station(Helm.new(), Vector2(345, 420))
	var bow := Cannon.new()
	bow.min_angle = -1.45
	bow.max_angle = 0.45
	bow.angle = -0.25
	_add_station(bow, Vector2(1085, Ship.DECK_Y))
	var mast := Cannon.new()
	mast.min_angle = -PI + 0.25
	mast.max_angle = -0.25
	mast.angle = -PI * 0.5 + 0.3
	mast.sweep_with_x = true
	_add_station(mast, Vector2(690, 400))

	effects = Node2D.new()
	effects.z_index = 8
	add_child(effects)

	for info in Game.players:
		var p := Player.new()
		p.setup(info)
		p.position = Vector2(580.0 + info["slot"] * 50.0, Ship.DECK_Y)
		add_child(p)
		players.append(p)

	if final:
		boss = PirateShip.new()
		boss.voyage = self
		hazards.add_child(boss)

	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var hud := VoyageHud.new()
	hud.voyage = self
	ui.add_child(hud)

	if final:
		_tips = [
			[1.5, "سفينة القراصنة! أسقطوها بالمدافع"],
			[9.0, "القنابل تسقط داخل الدائرة الحمراء، والمدافع تُسقطها في الجو"],
		]
	elif Game.voyage_number == 1:
		_tips = [
			[1.5, "أطعموا المحرك بالفحم كي تبقى السفينة مسرعة!"],
			[10.0, "الدفة ترفع السفينة وتخفضها لتفادي الصخور"],
			[18.0, "المدافع تُسقط طيور العاصفة وتكسر الصخور"],
		]
	else:
		_tips = [[1.5, "الرحلة %d: الرياح أقوى هذه المرة!" % Game.voyage_number]]


func _add_station(node: Node2D, pos: Vector2) -> void:
	if "voyage" in node:
		node.set("voyage", self)
	node.position = pos
	add_child(node)


func is_sailing() -> bool:
	return state == State.SAILING


func is_wrecked() -> bool:
	return state == State.WRECKED


func has_arrived() -> bool:
	return state == State.ARRIVED


func difficulty() -> float:
	return _diff


func speed_factor() -> float:
	if state == State.WRECKED:
		return 0.0
	return 1.0 if fuel > 0.0 else 0.35


func _physics_process(delta: float) -> void:
	elapsed += delta
	banner_time -= delta
	if state == State.SAILING:
		_sail(delta)
	else:
		_ending(delta)
	hazards.position.y = altitude
	sky.scroll_speed = 90.0 * speed_factor()
	sky.parallax = Vector2(0, -altitude)
	ship.prop_speed = speed_factor()
	_shake = maxf(_shake - delta * 18.0, 0.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake + Vector2(0, sin(elapsed * 1.3) * 4.0)


func _sail(delta: float) -> void:
	fuel = maxf(fuel - (2.6 + _diff * 1.4) * delta, 0.0)
	if boss == null:
		distance = minf(distance + delta / VOYAGE_TIME * speed_factor(), 1.0)
	hp -= holes.size() * 0.8 * delta * Game.damage_scale()
	while not _tips.is_empty() and elapsed >= _tips[0][0]:
		show_banner(_tips.pop_front()[1])

	if boss == null:
		_rock_timer -= delta * speed_factor()
		if _rock_timer <= 0.0:
			_rock_timer = randf_range(9.0, 13.0) / (1.0 + _diff)
			_spawn_rock()
		_bird_timer -= delta
		if _bird_timer <= 0.0:
			_bird_timer = randf_range(5.0, 8.0) / (1.0 + _diff * 1.2)
			for i in 1 + int(Game.crew_strength() / 3.0):
				spawn_bird(i)

	if hp <= 0.0:
		_wreck()
	elif distance >= 1.0:
		_arrive()


func _spawn_rock() -> void:
	var r := Rock.new()
	r.voyage = self
	r.radius = randf_range(46.0, 66.0)
	r.speed = 230.0 * (1.0 + _diff * 0.3)
	r.position = Vector2(2300.0, randf_range(500.0, 630.0) - altitude)
	hazards.add_child(r)


func spawn_bird(i: int) -> void:
	var b := Bird.new()
	b.voyage = self
	var from_left := randf() < 0.25
	b.position = Vector2(-150.0 - i * 90.0 if from_left else 1430.0 + i * 90.0, randf_range(90.0, 380.0))
	b.target = Vector2(randf_range(230.0, 1080.0), Ship.DECK_Y - 6.0)
	b.speed = randf_range(120.0, 150.0) * (1.0 + _diff * 0.35)
	effects.add_child(b)


func rock_hit(rock: Rock) -> void:
	hp -= 12.0 * Game.damage_scale()
	add_shake(14.0)
	Sound.play("crash")
	Fx.burst(effects, rock.global_position, Color("#a89bb0"), 30, 320.0, 0.7)
	add_hole()
	add_hole()
	show_banner("اصطدام! أصلحوا الثقوب بسرعة")
	rock.queue_free()


func rock_destroyed(rock: Rock) -> void:
	Fx.burst(effects, rock.global_position, Color("#b8a9c4"), 34, 300.0, 0.8)
	Fx.burst(effects, rock.global_position, Color("#8ff0ff"), 12, 220.0, 0.4)
	add_shake(6.0)
	Sound.play("crash", -5.0, 1.3)
	rock.queue_free()


func bird_hit(bird: Bird) -> void:
	hp -= 3.0 * Game.damage_scale()
	add_shake(5.0)
	add_hole(bird.target.x)
	Fx.burst(effects, bird.global_position, Color("#8e7fc4"), 16, 180.0)
	bird.queue_free()


func spawn_bomb(from: Vector2, target: Vector2) -> void:
	var b := Bomb.new()
	b.voyage = self
	b.start = from
	b.target = target
	effects.add_child(b)


func bomb_landed(bomb: Bomb) -> void:
	hp -= 5.0 * Game.damage_scale()
	add_shake(8.0)
	Sound.play("crash", -4.0, 1.2)
	Fx.burst(effects, bomb.target, Color("#ffb347"), 24, 260.0, 0.6)
	add_hole(bomb.target.x)
	bomb.queue_free()


func boss_defeated() -> void:
	state = State.ARRIVED
	Sound.play("win")
	add_shake(16.0)
	for b in get_tree().get_nodes_in_group("birds"):
		b.flee()
	for b in get_tree().get_nodes_in_group("bombs"):
		b.shoot_down()
	show_banner("هزمتم قراصنة السماء!")


func add_hole(x := -1.0) -> void:
	if holes.size() >= MAX_HOLES or state != State.SAILING:
		return
	if x < 0.0:
		x = randf_range(220.0, 1080.0)
	x = clampf(x, 200.0, 1100.0)
	if x > 430.0 and x < 570.0:
		x = 430.0 if x < 500.0 else 570.0  # never under the cargo crate, where nobody can reach
	var h := Hole.new()
	h.voyage = self
	h.position = Vector2(x, Ship.DECK_Y)
	add_child(h)
	holes.append(h)
	if _first_hole:
		_first_hole = false
		show_banner("ثقب! قفوا بجانبه واضغطوا زر التفاعل باستمرار")


func remove_hole(h: Hole) -> void:
	holes.erase(h)


func spawn_ball(pos: Vector2, vel: Vector2) -> void:
	var b := Cannonball.new()
	b.voyage = self
	b.position = pos
	b.velocity = vel
	effects.add_child(b)


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func show_banner(text: String) -> void:
	banner = text
	banner_time = 4.0


func _wreck() -> void:
	state = State.WRECKED
	hp = 0.0
	banner_time = 0.0
	add_shake(22.0)
	Sound.stop_music()
	Sound.play("wreck")
	for p in players:
		p.leave_station()
		p.frozen = true
	for b in get_tree().get_nodes_in_group("birds"):
		b.flee()
	for b in get_tree().get_nodes_in_group("bombs"):
		b.queue_free()


func _arrive() -> void:
	state = State.ARRIVED
	Sound.play("win")
	for b in get_tree().get_nodes_in_group("birds"):
		b.flee()
	var isle := IslandAhead.new()
	isle.position = Vector2(1700, 560)
	hazards.add_child(isle)
	show_banner("جزيرة في الأفق! استعدوا للنزول")


func _ending(delta: float) -> void:
	end_time += delta
	if state == State.ARRIVED:
		if boss != null and end_time > 4.5:
			Game.story_kind = "ending"
			Game.goto(Game.STORY_SCENE)
		elif boss == null and end_time > 3.5:
			Game.goto(Game.ISLAND_SCENE)
	elif end_time > 1.5:
		for p in players:
			if p.input.pressed("interact"):
				Game.goto(Game.VOYAGE_SCENE)
				return


## The destination island gliding in from the right once the voyage is done.
class IslandAhead:
	extends Node2D

	func _physics_process(delta: float) -> void:
		position.x = move_toward(position.x, 1150.0, 260.0 * delta)
		queue_redraw()

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-180, 0), Vector2(260, 0), Vector2(200, 90),
			Vector2(60, 220), Vector2(-60, 160), Vector2(-150, 70)]), Color("#8a5a48"))
		draw_style_box(Paint.box(Color("#69c96b"), 14), Rect2(-190, -14, 460, 28))
		draw_rect(Rect2(-40, -110, 14, 100), Color("#7a4a2a"))
		for c: Vector3 in [Vector3(-33, -120, 42), Vector3(-70, -95, 30), Vector3(5, -95, 30)]:
			draw_circle(Vector2(c.x, c.y), c.z, Color("#ffb7d0"), true, -1.0, true)
		draw_circle(Vector2(140, -40), 30.0, Color("#6fd08c"), true, -1.0, true)
