extends Node2D
## Title screen and crew lobby: press jump to join, press interact to set sail.

const SLOT_W := 150.0
const SLOT_H := 150.0
const SLOT_GAP := 16.0

var _candidates: Array[PlayerInput] = []
var _pop: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _t := 0.0


func _ready() -> void:
	Game.players.clear()
	Game.new_game()
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


func _physics_process(delta: float) -> void:
	_t += delta
	for i in _pop.size():
		_pop[i] = maxf(_pop[i] - delta * 3.0, 0.0)
	_add_new_gamepads()
	for c in _candidates:
		c.poll()
		if Game.has_input(c):
			if c.pressed("interact"):
				Sound.play("join", 0.0, 1.5)
				Game.goto(Game.VOYAGE_SCENE)
				return
		elif c.pressed("jump") and Game.add_player(c):
			var slot := Game.players.size() - 1
			_pop[slot] = 1.0
			Sound.play("join", 0.0, 1.0 + slot * 0.1, 0.0)
			Fx.burst(self, _slot_rect(slot).get_center(), Game.COLORS[slot], 26, 240.0, 0.6)
	queue_redraw()


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


func _draw() -> void:
	var ink := Color("#3b2d6b")
	var bob := sin(_t * 1.4) * 6.0
	var sc := 0.36
	draw_set_transform(Vector2(640, 300 + bob) - Vector2(670, 340) * sc, 0.0, Vector2(sc, sc))
	Ship.paint(self, _t, _t * 10.0)
	draw_set_transform(Vector2.ZERO)

	Paint.text(self, Vector2(640, 72), "سفينة الغيوم", 76, Color.WHITE, true, 12, Color(ink, 0.8))
	Paint.text(self, Vector2(640, 136), "مغامرة تعاونية في السماء، من 2 إلى 6 لاعبين", 22, Color("#fff1f5"), false, 5, Color(ink, 0.5))

	for i in Game.MAX_PLAYERS:
		_draw_slot(i)

	_key_line(630.0, "للانضمام اضغط زر القفز", ["Space", ".", "A"], 1.0)
	var start_alpha := 0.55 + 0.45 * sin(_t * 4.0) if Game.players.size() > 0 else 0.45
	_key_line(672.0, "للإبحار اضغط زر التفاعل", ["E", "/", "X"], start_alpha)
	var notes := ["الحركة: WASD", "أو الأسهم", "أو عصا يد التحكم"]
	for i in notes.size():
		Paint.text(self, Vector2(820.0 - i * 180.0, 708), notes[i], 14, Color(1, 1, 1, 0.8), false, 3, Color(ink, 0.4))


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
	var ink := Color("#3b2d6b")
	var fs := 20
	var lw := Paint.text_width(label, fs)
	var widths: Array[float] = []
	var caps := 0.0
	for k in keys:
		var kw := maxf(Paint.text_width(k, 16) + 18.0, 34.0)
		widths.append(kw)
		caps += kw + 8.0
	var x := 640.0 + (lw + 16.0 + caps) * 0.5
	Paint.text(self, Vector2(x - lw * 0.5, y), label, fs, Color(1, 1, 1, alpha), true, 4, Color(ink, 0.45 * alpha))
	x -= lw + 16.0
	for i in keys.size():
		var rr := Rect2(x - widths[i], y - 16.0, widths[i], 32)
		draw_style_box(Paint.box(Color(1, 1, 1, 0.9 * alpha), 8, Color(0, 0, 0, 0), 0, 4), rr)
		Paint.text(self, rr.get_center(), keys[i], 16, Color(ink, alpha))
		x -= widths[i] + 8.0
