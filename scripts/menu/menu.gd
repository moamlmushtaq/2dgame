extends Node2D
## Title screen: the crew lobby (press jump to join), the main menu, settings and a
## how-to-play page. Any keyboard half or gamepad can drive the menu.

enum Page { MAIN, SETTINGS, HOWTO }

const SLOT_W := 150.0
const SLOT_H := 150.0
const SLOT_GAP := 16.0
const INK := Color("#3b2d6b")

var _candidates: Array[PlayerInput] = []
var _pop: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _t := 0.0
var _page := Page.MAIN
var _main: OptionList
var _settings: OptionList
## Whoever pressed last; joins automatically if they start without joining first.
var _actor: PlayerInput


func _ready() -> void:
	Game.players.clear()
	Sound.play_music("island")

	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	var sky := SkyBackdrop.new()
	sky.top_color = Color("#4a4ba8")
	sky.bottom_color = Color("#ffb2c0")
	sky.sun_color = Color("#ffd89e")
	sky.sun_pos = Vector2(0.82, 0.62)
	sky.cloud_color = Color("#ffeef3")
	sky.stars = true
	sky.scroll_speed = 18.0
	back.add_child(sky)

	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)

	_candidates.append(PlayerInput.keyboard(0))
	_candidates.append(PlayerInput.keyboard(1))

	_main = OptionList.new()
	_main.accept_jump = false
	if Game.has_saved_run():
		_main.add(func() -> String: return "متابعة الرحلة (%d/%d)" % [Game.saved_run.get("pieces", 0), Game.MAP_TOTAL], _continue)
	_main.add("رحلة جديدة", _new_game)
	_main.add("كيف تلعب؟", func() -> void: _page = Page.HOWTO)
	_main.add("الإعدادات", func() -> void:
		_page = Page.SETTINGS
		_settings.index = 0)
	if not OS.has_feature("web"):
		_main.add("خروج", func() -> void: get_tree().quit())
	_settings = Game.settings_list(func() -> void: _page = Page.MAIN)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		_page = Page.MAIN


func _physics_process(delta: float) -> void:
	_t += delta
	for i in _pop.size():
		_pop[i] = maxf(_pop[i] - delta * 3.0, 0.0)
	_add_new_gamepads()
	for c in _candidates:
		c.poll()
		_actor = c
		match _page:
			Page.MAIN:
				if c.pressed("jump") and not Game.has_input(c):
					_join(c)
				else:
					_main.handle(c)
			Page.SETTINGS:
				_settings.handle(c)
			Page.HOWTO:
				if c.pressed("jump") or c.pressed("interact"):
					Sound.play("click")
					_page = Page.MAIN
	queue_redraw()


func _join(c: PlayerInput) -> void:
	if not Game.add_player(c):
		return
	var slot := Game.players.size() - 1
	_pop[slot] = 1.0
	Sound.play("join", 0.0, 1.0 + slot * 0.1, 0.0)
	Fx.burst(self, _slot_rect(slot).get_center(), Game.COLORS[slot], 26, 240.0, 0.6)


func _new_game() -> void:
	if Game.players.is_empty():
		_join(_actor)
	Game.new_game()
	Game.story_kind = "intro"
	Game.goto(Game.STORY_SCENE)


func _continue() -> void:
	if Game.players.is_empty():
		_join(_actor)
	Game.continue_run()
	Game.goto(Game.VOYAGE_SCENE)


func _add_new_gamepads() -> void:
	for id in Input.get_connected_joypads():
		var known := false
		for c in _candidates:
			if c.kind == PlayerInput.Kind.GAMEPAD and c.device == id:
				known = true
		if not known:
			_candidates.append(PlayerInput.gamepad(id))


func _slot_rect(i: int) -> Rect2:
	var total := SLOT_W * Game.MAX_PLAYERS + SLOT_GAP * (Game.MAX_PLAYERS - 1)
	return Rect2(640.0 - total * 0.5 + i * (SLOT_W + SLOT_GAP), 440, SLOT_W, SLOT_H)


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	var bob := sin(_t * 1.4) * 6.0
	var sc := 0.3
	draw_set_transform(Vector2(350, 285 + bob) - Vector2(670, 340) * sc, 0.0, Vector2(sc, sc))
	Ship.paint(self, _t, _t * 10.0)
	draw_set_transform(Vector2.ZERO)

	Paint.text(self, Vector2(640, 62), "سفينة الغيوم", 72, Color.WHITE, true, 12, Color(INK, 0.8))
	Paint.text(self, Vector2(640, 120), "مغامرة تعاونية في السماء، من 2 إلى 6 لاعبين", 21, Color("#fff1f5"), false, 5, Color(INK, 0.5))

	_main.draw(self, Vector2(910, 285), 380.0, 50.0, 1.0 if _page == Page.MAIN else 0.3)
	for i in Game.MAX_PLAYERS:
		_draw_slot(i)
	_key_line(630.0, "للانضمام اضغط زر القفز", ["Space", ".", "A"], 1.0)
	_key_line(672.0, "اختر بالأسهم واضغط زر التفاعل", ["E", "/", "X"], 0.85)
	var notes := ["الحركة: WASD", "أو الأسهم", "أو عصا يد التحكم"]
	for i in notes.size():
		Paint.text(self, Vector2(820.0 - i * 180.0, 708), notes[i], 14, Color(1, 1, 1, 0.8), false, 3, Color(INK, 0.4))

	if _page == Page.SETTINGS:
		_draw_settings()
	elif _page == Page.HOWTO:
		_draw_howto()


func _draw_slot(i: int) -> void:
	var r := _slot_rect(i)
	if i < Game.players.size():
		var info: Dictionary = Game.players[i]
		var col: Color = info["color"]
		r = r.grow(_pop[i] * 8.0)
		draw_style_box(Paint.box(Color(1, 1, 1, 0.92), 18, col, 4, 8), r)
		var hop := absf(sin(_t * 3.0 + i)) * 4.0
		draw_set_transform(Vector2(r.get_center().x, r.position.y + 100.0), 0.0, Vector2(1.7, 1.7))
		Player.paint_sailor(self, Vector2(0, -hop), col, 1 if i % 2 == 0 else -1, Vector2.ONE, _t + i)
		draw_set_transform(Vector2.ZERO)
		Paint.text(self, Vector2(r.get_center().x, r.position.y + 118.0), info["name"], 22, col.darkened(0.25))
		Paint.text(self, Vector2(r.get_center().x, r.position.y + 138.0), (info["input"] as PlayerInput).device_name(), 12, Color("#6b6385"), false)
	else:
		draw_style_box(Paint.box(Color(1, 1, 1, 0.16), 18, Color(1, 1, 1, 0.45), 2), r)
		var a := 0.55 + 0.25 * sin(_t * 3.0 + i * 0.7)
		Paint.text(self, r.get_center() + Vector2(0, -14), "+", 48, Color(1, 1, 1, a))
		Paint.text(self, r.get_center() + Vector2(0, 34), "انضم", 18, Color(1, 1, 1, a), false)


## Draws an Arabic label on the right with key caps to its left.
func _key_line(y: float, label: String, keys: Array, alpha: float) -> void:
	var fs := 20
	var lw := Paint.text_width(label, fs)
	var widths: Array[float] = []
	var caps := 0.0
	for k in keys:
		var kw := maxf(Paint.text_width(k, 16) + 18.0, 34.0)
		widths.append(kw)
		caps += kw + 8.0
	var x := 640.0 + (lw + 16.0 + caps) * 0.5
	Paint.text(self, Vector2(x - lw * 0.5, y), label, fs, Color(1, 1, 1, alpha), true, 4, Color(INK, 0.45 * alpha))
	x -= lw + 16.0
	for i in keys.size():
		var rr := Rect2(x - widths[i], y - 16.0, widths[i], 32)
		draw_style_box(Paint.box(Color(1, 1, 1, 0.9 * alpha), 8, Color(0, 0, 0, 0), 0, 4), rr)
		Paint.text(self, rr.get_center(), keys[i], 16, Color(INK, alpha))
		x -= widths[i] + 8.0


func _dim() -> void:
	draw_rect(Rect2(-2000, -2000, 5280, 4720), Color(0.1, 0.06, 0.25, 0.6))


func _draw_settings() -> void:
	_dim()
	var h := _settings.items.size() * 54.0 + 150.0
	var card := Rect2(400, 360 - h * 0.5, 480, h)
	draw_style_box(Paint.box(Color(0.33, 0.3, 0.62, 0.97), 26, Color(1, 1, 1, 0.5), 3, 12), card)
	Paint.text(self, Vector2(640, card.position.y + 44.0), "الإعدادات", 32, Color.WHITE)
	_settings.draw(self, Vector2(640, card.position.y + 80.0 + _settings.items.size() * 27.0), 380.0, 54.0)
	Paint.text(self, Vector2(640, card.end.y - 26.0), "يمين ويسار لتغيير القيمة  ·  F11 ملء الشاشة  ·  M كتم الصوت", 14, Color(1, 1, 1, 0.75), false)


func _draw_howto() -> void:
	_dim()
	var panel := Rect2(70, 30, 1140, 660)
	draw_style_box(Paint.box(Color(1, 0.98, 0.94), 28, Color("#ffd27a"), 4, 12), panel)
	Paint.text(self, Vector2(640, 72), "كيف تلعب؟", 36, Color("#e0703a"))
	var cards := [
		["المحرك", "خذوا الفحم من الصندوق\nوضعوه في المحرك ليبقى مسرعًا"],
		["الدفة", "ارفعوا السفينة واخفضوها\nلتفادي الصخور العائمة"],
		["المدافع", "صوّبوا بالأسهم وأطلقوا بالقفز\nعلى الطيور والصخور والقنابل"],
		["الإصلاح", "اضغطوا التفاعل باستمرار\nبجانب الثقب لإصلاحه"],
		["برج الأصدقاء", "اقفزوا فوق رؤوس بعضكم\nللوصول إلى الأماكن العالية"],
		["الهدف", "اجمعوا 4 قطع من خريطة السماء\nثم واجهوا سفينة القراصنة!"],
	]
	for i in cards.size():
		var col := 2 - i % 3  # right to left
		var row := i / 3
		var r := Rect2(100 + col * 365.0, 110 + row * 250.0, 345, 230)
		draw_style_box(Paint.box(Color("#fff4dc"), 20, Color("#f0d6a4"), 2), r)
		_howto_icon(i, r.position + Vector2(r.size.x * 0.5, 78))
		Paint.text(self, r.position + Vector2(r.size.x * 0.5, 138), cards[i][0], 22, INK)
		var lines: PackedStringArray = (cards[i][1] as String).split("\n")
		for k in lines.size():
			Paint.text(self, r.position + Vector2(r.size.x * 0.5, 174 + k * 26.0), lines[k], 16, Color(INK, 0.8), false)
	Paint.text(self, Vector2(640, 660), "اضغط أي زر للرجوع", 15, Color(INK, 0.7), false)


func _howto_icon(i: int, c: Vector2) -> void:
	match i:
		0:
			draw_style_box(Paint.box(Color("#a8543f"), 8), Rect2(c.x - 30, c.y - 34, 60, 50))
			draw_style_box(Paint.box(Color("#ffb347"), 6), Rect2(c.x - 14, c.y - 18, 28, 20))
			draw_circle(c + Vector2(44, 6), 10.0, Color("#3b3440"), true, -1.0, true)
		1:
			for k in 8:
				var d := Vector2.from_angle(_t + k * TAU / 8.0)
				draw_line(c, c + d * 30.0, Color("#7a4a2a"), 3.0, true)
			draw_arc(c, 22.0, 0.0, TAU, 28, Color("#7a4a2a"), 5.0, true)
			draw_circle(c, 6.0, Ship.GOLD, true, -1.0, true)
		2:
			draw_set_transform(c + Vector2(-10, 10), -0.5)
			draw_style_box(Paint.box(Color("#4b4f68"), 9), Rect2(-10, -10, 56, 20))
			draw_set_transform(Vector2.ZERO)
			draw_circle(c + Vector2(-12, 16), 10.0, Color("#5a3a26"), true, -1.0, true)
			draw_circle(c + Vector2(40, -30), 6.0, Color("#2f2f40"), true, -1.0, true)
		3:
			draw_colored_polygon(Paint.ellipse(c + Vector2(10, 16), 28.0, 9.0, 20), Color("#2a1a14"))
			Player.paint_sailor(self, c + Vector2(-30, 24), Game.COLORS[1], 1, Vector2.ONE, _t, false, "", false, true)
		4:
			Player.paint_sailor(self, c + Vector2(0, 30), Game.COLORS[2], 1, Vector2.ONE, _t)
			Player.paint_sailor(self, c + Vector2(0, -10), Game.COLORS[0], -1, Vector2.ONE, _t + 1.0)
		5:
			Paint.map_pieces(self, c, 4, 4, 30.0)
