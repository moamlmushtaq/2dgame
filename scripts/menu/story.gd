extends Node2D
## Story cards: the intro before the first voyage and the ending after the pirates fall.
## Any sailor presses jump or interact to turn the page.

const INTRO := [
	"كانت خريطة السماء ترشد كل السفن بين الجزر العائمة.",
	"لكن عاصفةً غاضبة مزّقتها أربع قطع، وبعثرتها على الجزر البعيدة.",
	"وقراصنة السماء يبحثون عنها أيضًا... هيّا يا طاقم، أحضِروا القطع قبلهم!",
]
const ENDING := [
	"سقطت سفينة القراصنة بين الغيوم، وهربوا بلا عودة!",
	"واكتملت خريطة السماء، فعادت الطرق آمنة لكل السفن.",
	"",
]

var _pages: Array = []
var _page := 0
var _t := 0.0
var _page_t := 0.0
var _ending := false


func _ready() -> void:
	Game.ensure_players()
	_ending = Game.story_kind == "ending"
	_pages = ENDING if _ending else INTRO
	if _ending:
		Game.finish_run()
		Sound.play("win")
	Sound.play_music("island")

	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	var sky := SkyBackdrop.new()
	if _ending:
		sky.top_color = Color("#ff9e7a")
		sky.bottom_color = Color("#ffe6b8")
		sky.sun_pos = Vector2(0.5, 0.55)
	else:
		sky.top_color = Color("#4a4ba8")
		sky.bottom_color = Color("#ffb2c0")
		sky.stars = true
	back.add_child(sky)
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	add_child(Atmosphere.new("sunset" if _ending else "dusk", -5))
	add_child(Ambient.new({"motes": {"count": 30, "color": Color(1.0, 0.9, 0.7, 0.8) if _ending else Color(1.0, 0.85, 0.9, 0.8),
		"drift": Vector2(-4.0, -18.0), "size": Vector2(1.5, 3.5)}}))


func _physics_process(delta: float) -> void:
	_t += delta
	_page_t += delta
	for p in Game.players:
		var input: PlayerInput = p["input"]
		if input.is_bot():
			continue
		input.poll()
		if _page_t > 0.6 and (input.pressed("jump") or input.pressed("interact")):
			_next()
			break
	queue_redraw()


func _next() -> void:
	Sound.play("click")
	_page += 1
	_page_t = 0.0
	if _page >= _pages.size():
		_page = _pages.size() - 1
		Game.goto(Game.MENU_SCENE if _ending else Game.VOYAGE_SCENE)


func _draw() -> void:
	var ink := Color("#3b2d6b")
	if _ending and _page == 2:
		_draw_credits(ink)
	else:
		var spread := 0.0
		if not _ending and _page >= 1:
			spread = minf(_page_t * 0.8, 1.0) if _page == 1 else 1.0
		elif _ending:
			spread = 1.0 - minf(_page_t * 0.6, 1.0) if _page == 1 else 1.0
		if _ending and _page == 0:
			_draw_pirates_falling()
		else:
			_draw_map(Vector2(640, 250), spread)
		if not _ending and _page == 2:
			_draw_crew(Vector2(640, 492))

	var text: String = _pages[_page]
	if text != "":
		var r := Rect2(140, 560, 1000, 90)
		draw_style_box(Paint.box(Color(1, 1, 1, 0.92), 24, Color(0, 0, 0, 0), 0, 10), r)
		Paint.text(self, r.get_center(), text, 24, ink)
	var blink := 0.5 + 0.5 * sin(_t * 4.0)
	Paint.text(self, Vector2(640, 690), "اضغطوا القفز أو التفاعل للمتابعة", 16, Color(1, 1, 1, 0.6 + 0.4 * blink), false, 5, Color(ink, 0.75))
	for i in _pages.size():
		draw_circle(Vector2(640 + (i - (_pages.size() - 1) * 0.5) * 20.0, 540), 5.0, Color.WHITE if i == _page else Color(1, 1, 1, 0.4), true, -1.0, true)


## The sky map in four pieces; `spread` 0 is whole, 1 is torn apart.
func _draw_map(center: Vector2, spread: float, size := 1.0) -> void:
	var w := 380.0
	var h := 250.0
	var glow := 1.0 - spread
	if glow > 0.0:
		for i in 4:
			draw_circle(center, (200.0 + i * 30.0) * size, Color(1, 0.95, 0.7, 0.08 * glow), true, -1.0, true)
	var dirs := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for i in 4:
		var d: Vector2 = dirs[i]
		var off := d * Vector2(170, 90) * spread + Vector2(0, sin(_t * 2.0 + i) * 6.0 * spread)
		var rot := d.x * d.y * 0.25 * spread
		var qc := center + (Vector2(d.x * w * 0.25, d.y * h * 0.25) + off) * size
		draw_set_transform(qc, rot, Vector2(size, size))
		var r := Rect2(-w * 0.25, -h * 0.25, w * 0.5, h * 0.5)
		draw_style_box(Paint.box(Color("#f6e3b4"), 6, Color("#c9a26a"), 3), r)
		# A little island and a dotted route on each piece.
		var isle := Vector2(-d.x * 30.0, -d.y * 10.0)
		draw_circle(isle, 16.0, Color("#8fd49a"), true, -1.0, true)
		draw_circle(isle + Vector2(0, 8), 12.0, Color("#b5876a"), true, -1.0, true)
		for k in 5:
			draw_circle(isle + Vector2(d.x * (24.0 + k * 12.0), d.y * k * 6.0), 2.2, Color("#c9a26a"), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	if spread < 0.05:
		var x := center + Vector2(40, 20) * size
		draw_line(x + Vector2(-10, -10), x + Vector2(10, 10), Color("#e0524f"), 4.0, true)
		draw_line(x + Vector2(10, -10), x + Vector2(-10, 10), Color("#e0524f"), 4.0, true)


func _draw_pirates_falling() -> void:
	var fall := minf(_page_t * 0.25, 1.0)
	var pos := Vector2(820, 180 + fall * 260.0)
	var s := Vector2(-0.3, 0.3)
	draw_set_transform_matrix(Transform2D(-0.2 - fall * 0.4, Vector2.ZERO).translated(pos) * Transform2D(0.0, s, 0.0, -s * PirateShip.SHIP_CENTER))
	Ship.paint(self, _t, _t * 6.0, PirateShip.PALETTE)
	draw_set_transform(Vector2.ZERO)
	var sc := 0.32
	draw_set_transform(Vector2(380, 300 + sin(_t * 1.4) * 6.0) - Vector2(670, 340) * sc, 0.0, Vector2(sc, sc))
	Ship.paint(self, _t, _t * 10.0)
	draw_set_transform(Vector2.ZERO)


func _draw_crew(center: Vector2, name_color := Color.WHITE) -> void:
	var n := Game.players.size()
	for i in n:
		var info: Dictionary = Game.players[i]
		var x := center.x + (i - (n - 1) * 0.5) * 90.0
		var hop := absf(sin(_t * 3.0 + i)) * 6.0
		draw_set_transform(Vector2(x, center.y), 0.0, Vector2(1.5, 1.5))
		Player.paint_sailor(self, Vector2(0, -hop), info["color"], 1 if i % 2 == 0 else -1, Vector2.ONE, _t + i,
			false, "", false, false, (info["input"] as PlayerInput).is_bot())
		draw_set_transform(Vector2.ZERO)
		Paint.text(self, Vector2(x, center.y + 20.0), info["name"], 18, name_color, true, 4 if name_color == Color.WHITE else 0, Color(0.2, 0.15, 0.4, 0.5))


func _draw_credits(ink: Color) -> void:
	var card := Rect2(240, 50, 800, 470)
	draw_style_box(Paint.box(Color(1, 0.98, 0.93, 0.95), 28, Color("#ffd27a"), 5, 12), card)
	Paint.text(self, Vector2(640, 100), "شكرًا لكم يا طاقم سفينة الغيوم!", 36, Color("#e0703a"))
	_draw_map(Vector2(640, 232), 0.0, 0.62)
	_draw_crew(Vector2(640, 415), ink)
	Paint.text(self, Vector2(640, 470), "البلورات: %d    ·    الرحلات: %d    ·    مرّات الفوز: %d" % [Game.gems, Game.voyage_number, Game.stats["runs"]], 18, ink, false)
	Paint.text(self, Vector2(640, 500), "لعبة «سفينة الغيوم» - صُنعت بمحرك Godot", 14, Color(ink, 0.6), false)
