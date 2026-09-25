extends Node2D
## The floating island: a short trail of co-op puzzles leading to a treasure chest.
##
## 1. A wall too tall to jump alone: stack up on each other's heads and pull the lever.
## 2. A gate held open by pressure plates on both sides.
## 3. A balloon lift that needs enough riders, with a lever up top that makes it automatic.
## 4. A chest that only opens when the whole crew is gathered around it.

# Landmasses as Vector3(x_start, x_end, top_y) segments.
const LAND_WEST := [Vector3(-300, 700, 600), Vector3(700, 1500, 460)]
const LAND_EAST := [Vector3(1700, 3100, 280)]
const CHECKPOINTS := [Vector2(120, 600), Vector2(790, 460), Vector2(1400, 460), Vector2(1820, 280)]
const GEMS := [
	Vector2(330, 540), Vector2(470, 400), Vector2(1000, 360), Vector2(1180, 270),
	Vector2(1600, 160), Vector2(2100, 200), Vector2(2350, 90), Vector2(2900, 180),
]

var players: Array[Player] = []
var camera: Camera2D
var sky: SkyBackdrop
var gems_found := 0
var gems_total := GEMS.size()
var won := false
var win_time := 0.0
var banner := ""
var banner_time := 0.0


func _ready() -> void:
	Game.ensure_players()
	var n := Game.player_count()

	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	sky = SkyBackdrop.new()
	sky.top_color = Color("#62b6ff")
	sky.bottom_color = Color("#ffe1c4")
	sky.sun_pos = Vector2(0.18, 0.22)
	sky.scroll_speed = 10.0
	back.add_child(sky)

	var terrain := IslandTerrain.new()
	terrain.add_land(LAND_WEST)
	terrain.add_land(LAND_EAST)
	terrain.add_wall(Rect2(-340, -900, 40, 1900))
	terrain.add_wall(Rect2(3100, -900, 40, 1900))
	terrain.add_waterfall(Vector2(-262, 640))
	terrain.add_tree(Vector2(-160, 600), 0, 1.1)
	terrain.add_tree(Vector2(20, 600), 1, 0.9)
	terrain.add_tree(Vector2(400, 600), 0, 0.8)
	terrain.add_tree(Vector2(890, 460), 1, 1.0)
	terrain.add_tree(Vector2(1960, 280), 0, 1.1)
	terrain.add_tree(Vector2(2230, 280), 1, 0.9)
	terrain.add_tree(Vector2(2470, 280), 0, 1.0)
	terrain.add_tree(Vector2(3010, 280), 1, 1.2)
	add_child(terrain)

	var lift_need := 1 if n == 1 else maxi(2, ceili(n / 2.0))
	_sign(Vector2(150, 600), "أهلًا بكم في الجزيرة العائمة!\nقطعة الخريطة في آخر الطريق")
	_sign(Vector2(530, 600), "الجدار عالٍ؟\nاقفزوا فوق رؤوس بعضكم!")
	_sign(Vector2(960, 460), "الألواح تفتح البوابة\nما دام أحدٌ واقفًا عليها")
	_sign(Vector2(1440, 460), "المصعد يرتفع بـ %d ركّاب\nوالرافعة في الأعلى تشغّله وحده" % lift_need)
	_sign(Vector2(2560, 280), "اجتمعوا كلكم\nحول الصندوق!")

	# Puzzle 1: the tall wall.
	var step := RisingStep.new()
	step.position = Vector2(610, 600)
	add_child(step)
	var wall_lever := Lever.new()
	wall_lever.position = Vector2(800, 460)
	add_child(wall_lever)
	wall_lever.pulled.connect(step.raise)
	if n == 1:
		step.raise()

	# Puzzle 2: the gate between two plates.
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

	# Puzzle 3: the balloon lift.
	var lift := Lift.new()
	lift.position = Vector2(1502, 460)
	lift.need = lift_need
	add_child(lift)
	var lift_lever := Lever.new()
	lift_lever.position = Vector2(1790, 280)
	add_child(lift_lever)
	lift_lever.pulled.connect(lift.set_auto)

	for pos in GEMS:
		var gem := Gem.new()
		gem.position = pos
		gem.collected.connect(_on_gem)
		add_child(gem)

	var chest := Chest.new()
	chest.position = Vector2(2760, 280)
	chest.island = self
	add_child(chest)

	for info in Game.players:
		var p := Player.new()
		p.setup(info)
		p.position = CHECKPOINTS[0] + Vector2(info["slot"] * 40.0, 0)
		p.respawn_point = CHECKPOINTS[0]
		p.fall_limit = 1150.0
		add_child(p)
		players.append(p)

	camera = Camera2D.new()
	camera.position = CHECKPOINTS[0] + Vector2(100, -80)
	camera.limit_left = -340
	camera.limit_right = 3140
	camera.limit_top = -700
	camera.limit_bottom = 1000
	add_child(camera)

	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var hud := IslandHud.new()
	hud.island = self
	ui.add_child(hud)

	show_banner("ابحثوا عن قطعة الخريطة، والبلورات مكافأة!")


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
	banner_time = 0.0
	for p in players:
		p.frozen = true


func _physics_process(delta: float) -> void:
	banner_time -= delta
	for p in players:
		if not p.is_alive() or not p.is_on_floor():
			continue
		for i in range(p.checkpoint + 1, CHECKPOINTS.size()):
			var cp: Vector2 = CHECKPOINTS[i]
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
					Game.voyage_number += 1
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
