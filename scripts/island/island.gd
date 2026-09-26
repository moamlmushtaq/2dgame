extends Node2D
## A floating island: a short trail of co-op puzzles leading to a treasure chest.
## Odd voyages land on Blossom Isle, even voyages on Wind Isle.
##
## Blossom Isle
##   1. A wall too tall to jump alone: stack up on each other's heads and pull the lever.
##   2. A gate held open by pressure plates on both sides.
##   3. A balloon lift that needs enough riders, with a lever up top that makes it automatic.
## Wind Isle
##   1. A wind vent that only blows while someone turns a crank, with a second crank up top
##      so the last sailor can be lifted too.
##   2. Bells far apart that must all ring within a second of each other to raise a bridge.
##   3. Drifting cloud platforms across a gap.
## Both end with a chest that only opens when the whole crew has gathered around it.

var players: Array[Player] = []
var camera: Camera2D
var sky: SkyBackdrop
var terrain: IslandTerrain
var checkpoints: Array[Vector2] = []
var gems_found := 0
var gems_total := 0
var island_name := ""
var won := false
var win_time := 0.0
var banner := ""
var banner_time := 0.0


func _ready() -> void:
	Game.ensure_players()
	Sound.play_music("island")
	var n := Game.player_count()

	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	sky = SkyBackdrop.new()
	sky.scroll_speed = 10.0
	back.add_child(sky)

	terrain = IslandTerrain.new()
	add_child(terrain)

	var right_edge: float
	if Game.voyage_number % 2 == 1:
		right_edge = _build_blossom(n)
	else:
		right_edge = _build_wind(n)
	terrain.add_wall(Rect2(-340, -900, 40, 1900))
	terrain.add_wall(Rect2(right_edge, -900, 40, 1900))

	for info in Game.players:
		var p := Player.new()
		p.setup(info)
		p.position = checkpoints[0] + Vector2(info["slot"] * 40.0, 0)
		p.respawn_point = checkpoints[0]
		p.fall_limit = 1150.0
		add_child(p)
		players.append(p)

	camera = Camera2D.new()
	camera.position = checkpoints[0] + Vector2(100, -80)
	camera.limit_left = -340
	camera.limit_right = int(right_edge + 40.0)
	camera.limit_top = -700
	camera.limit_bottom = 1000
	add_child(camera)

	var blossom := Game.voyage_number % 2 == 1
	add_child(Atmosphere.new("blossom" if blossom else "wind"))
	var fireflies := Color(1.0, 0.95, 0.6, 0.85) if blossom else Color(0.7, 1.0, 0.95, 0.85)
	add_child(Ambient.new({"motes": {"count": 34, "color": fireflies, "drift": Vector2(-6.0, -10.0),
		"size": Vector2(1.5, 3.5)}, "petals": 18 if blossom else 0}))
	var front := Foreground.new("silhouettes")
	front.tint = Color(0.14, 0.08, 0.2, 0.93) if blossom else Color(0.12, 0.08, 0.24, 0.93)
	front.add_silhouettes(-500.0, right_edge + 500.0)
	add_child(front)

	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var hud := IslandHud.new()
	hud.island = self
	ui.add_child(hud)

	show_banner("%s: ابحثوا عن قطعة الخريطة!" % island_name)


func _build_blossom(n: int) -> float:
	island_name = "جزيرة الأزهار"
	sky.top_color = Color("#62b6ff")
	sky.bottom_color = Color("#ffe1c4")
	sky.sun_pos = Vector2(0.18, 0.22)

	terrain.add_land([Vector3(-300, 700, 600), Vector3(700, 1500, 460)])
	terrain.add_land([Vector3(1700, 3100, 280)])
	terrain.add_waterfall(Vector2(-262, 640))
	for t: Vector4 in [Vector4(-160, 600, 0, 1.1), Vector4(20, 600, 1, 0.9), Vector4(400, 600, 0, 0.8),
			Vector4(890, 460, 1, 1.0), Vector4(1960, 280, 0, 1.1), Vector4(2230, 280, 1, 0.9),
			Vector4(2470, 280, 0, 1.0), Vector4(3010, 280, 1, 1.2)]:
		terrain.add_tree(Vector2(t.x, t.y), int(t.z), t.w)
	checkpoints = [Vector2(120, 600), Vector2(790, 460), Vector2(1400, 460), Vector2(1820, 280)]
	_gems([Vector2(330, 540), Vector2(470, 400), Vector2(1000, 360), Vector2(1180, 270),
		Vector2(1600, 160), Vector2(2100, 200), Vector2(2350, 90), Vector2(2900, 180)])

	var lift_need := 1 if n == 1 else maxi(2, ceili(n / 2.0))
	_sign(Vector2(150, 600), "أهلًا بكم في جزيرة الأزهار!\nقطعة الخريطة في آخر الطريق")
	_sign(Vector2(530, 600), "الجدار عالٍ؟\nاقفزوا فوق رؤوس بعضكم!")
	_sign(Vector2(960, 460), "الألواح تفتح البوابة\nما دام أحدٌ واقفًا عليها")
	_sign(Vector2(1440, 460), "المصعد يرتفع بـ %d ركّاب\nوالرافعة في الأعلى تشغّله وحده" % lift_need)
	_sign(Vector2(2560, 280), "اجتمعوا كلكم\nحول الصندوق!")

	var step := RisingStep.new()
	step.position = Vector2(610, 600)
	add_child(step)
	var wall_lever := Lever.new()
	wall_lever.position = Vector2(800, 460)
	add_child(wall_lever)
	wall_lever.pulled.connect(step.raise)
	if n == 1:
		step.raise()

	var plate_a := PressurePlate.new()
	plate_a.position = Vector2(1110, 460)
	plate_a.need = 2 if n >= 4 else 1
	add_child(plate_a)
	var plate_b := PressurePlate.new()
	plate_b.position = Vector2(1340, 460)
	add_child(plate_b)
	var gate := Gate.new()
	gate.position = Vector2(1230, 460)
	gate.plates = [plate_a, plate_b]
	add_child(gate)

	var lift := Lift.new()
	lift.position = Vector2(1502, 460)
	lift.need = lift_need
	add_child(lift)
	var lift_lever := Lever.new()
	lift_lever.position = Vector2(1790, 280)
	add_child(lift_lever)
	lift_lever.pulled.connect(lift.set_auto)

	_chest(Vector2(2760, 280))
	return 3100.0


func _build_wind(n: int) -> float:
	island_name = "جزيرة الرياح"
	sky.top_color = Color("#7b86f0")
	sky.bottom_color = Color("#ffd3e2")
	sky.sun_color = Color("#fff0d6")
	sky.sun_pos = Vector2(0.86, 0.15)
	terrain.grass = Color("#5fcfb2")
	terrain.grass_light = Color("#a4f0d9")
	terrain.dirt = Color("#b08270")
	terrain.rock = Color("#6d5878")

	terrain.add_land([Vector3(-300, 800, 600), Vector3(800, 1700, 300)])
	terrain.add_land([Vector3(2100, 2600, 300)])
	terrain.add_land([Vector3(2900, 3600, 300)])
	for t: Vector4 in [Vector4(-150, 600, 2, 1.1), Vector4(60, 600, 1, 0.9), Vector4(380, 600, 2, 0.8),
			Vector4(1250, 300, 1, 1.0), Vector4(2250, 300, 2, 1.0), Vector4(3050, 300, 2, 1.2),
			Vector4(3520, 300, 1, 1.0)]:
		terrain.add_tree(Vector2(t.x, t.y), int(t.z), t.w)
	checkpoints = [Vector2(120, 600), Vector2(900, 300), Vector2(2180, 300), Vector2(2980, 300)]
	_gems([Vector2(300, 530), Vector2(745, 150), Vector2(1150, 210), Vector2(1330, 130),
		Vector2(1900, 240), Vector2(2400, 210), Vector2(2750, 170), Vector2(3250, 110)])

	_sign(Vector2(150, 600), "أهلًا بكم في جزيرة الرياح!\nقطعة الخريطة في آخر الطريق")
	_sign(Vector2(430, 600), "أحدكم يُدير العجلة\nوالباقون يطيرون مع الريح")
	_sign(Vector2(975, 300), "اقرعوا كل الأجراس معًا\nفي اللحظة نفسها!")
	_sign(Vector2(2480, 300), "اقفزوا على الغيوم")
	_sign(Vector2(3180, 300), "اجتمعوا كلكم\nحول الصندوق!")

	# Puzzle 1: the wind vent, with one crank below and one on the ledge for the last sailor.
	var vent := WindVent.new()
	vent.position = Vector2(745, 600)
	var low_crank := Crank.new()
	low_crank.position = Vector2(560, 600)
	low_crank.always_on = n == 1
	add_child(low_crank)
	var high_crank := Crank.new()
	high_crank.position = Vector2(870, 300)
	add_child(high_crank)
	vent.cranks = [low_crank, high_crank]
	add_child(vent)

	# Puzzle 2: bells that must ring together to build the bridge.
	var bell_spots := [Vector2(1150, 300), Vector2(1600, 300), Vector2(1400, 300)]
	var bell_colors := [Color("#ffd27a"), Color("#8ff0ff"), Color("#ffb3d1")]
	var bell_count := 1 if n == 1 else (3 if n >= 4 else 2)
	var bridge := BellBridge.new()
	bridge.position = Vector2(1700, 300)
	bridge.length = 400.0
	for i in bell_count:
		var bell := Bell.new()
		bell.position = bell_spots[i]
		bell.color = bell_colors[i]
		bell.pitch = [1.0, 1.26, 1.5][i]
		add_child(bell)
		bridge.bells.append(bell)
	add_child(bridge)

	# Puzzle 3: drifting clouds over the second gap.
	for i in 2:
		var cloud := MovingCloud.new()
		cloud.from_x = 2660.0
		cloud.to_x = 2840.0
		cloud.phase = i * 0.5
		cloud.period = 5.0
		cloud.position = Vector2(2660.0, 300.0 - i * 90.0)
		add_child(cloud)

	_chest(Vector2(3350, 300))
	return 3600.0


func _gems(spots: Array) -> void:
	gems_total = spots.size()
	for pos: Vector2 in spots:
		var gem := Gem.new()
		gem.position = pos
		gem.collected.connect(_on_gem)
		add_child(gem)


func _chest(pos: Vector2) -> void:
	var chest := Chest.new()
	chest.position = pos
	chest.island = self
	add_child(chest)


func _sign(pos: Vector2, text: String) -> void:
	var s := Signpost.new()
	s.position = pos
	s.text = text
	add_child(s)


func _on_gem() -> void:
	gems_found += 1
	Game.gems += 1


func show_banner(text: String) -> void:
	banner = text
	banner_time = 4.0


func win() -> void:
	won = true
	Game.map_pieces += 1
	Game.voyage_number += 1
	Game.checkpoint_run()
	banner_time = 0.0
	for p in players:
		p.frozen = true


func _physics_process(delta: float) -> void:
	banner_time -= delta
	for p in players:
		if not p.is_alive() or not p.is_on_floor():
			continue
		for i in range(p.checkpoint + 1, checkpoints.size()):
			var cp := checkpoints[i]
			if p.global_position.x >= cp.x - 40.0 and p.global_position.y <= cp.y + 4.0:
				p.checkpoint = i
				p.respawn_point = cp
	_update_camera(delta)
	sky.parallax = camera.get_screen_center_position() - Vector2(640, 360)

	if won:
		win_time += delta
		if win_time > 1.8:
			for p in players:
				if p.input.pressed("interact"):
					Game.goto(Game.VOYAGE_SCENE)
					return


## Keeps the whole crew on one screen, zooming out when they spread apart.
func _update_camera(delta: float) -> void:
	var box := Rect2()
	var any := false
	for p in players:
		if not p.is_alive():
			continue
		if any:
			box = box.expand(p.center())
		else:
			box = Rect2(p.center(), Vector2.ZERO)
			any = true
	if not any:
		return
	var view := get_viewport_rect().size
	var fit := minf(view.x / (box.size.x + 520.0), view.y / (box.size.y + 360.0))
	var z := clampf(fit, 0.55, 1.0)
	camera.zoom = camera.zoom.lerp(Vector2(z, z), minf(3.0 * delta, 1.0))
	camera.position = camera.position.lerp(box.get_center() + Vector2(0, -60), minf(4.0 * delta, 1.0))
