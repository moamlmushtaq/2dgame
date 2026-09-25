extends Node
## Headless island puzzle checks: a scripted human and one bot walk through every
## puzzle of an island and each step prints PASS or FAIL.
## VOYAGE=1 tests Blossom Isle, VOYAGE=2 Wind Isle. Run with tests/run.sh islands.

var f := 0
var phase := 0
var phase_t := 0.0
var isl: Node
var failures := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(delta: float) -> void:
	f += 1
	phase_t += delta
	if f == 2:
		Game.players.clear()
		Game.add_player(PlayerInput.keyboard(0))
		Game.settings["bots"] = 1
		Game.fill_bots()
		Game.voyage_number = int(OS.get_environment("VOYAGE")) if OS.get_environment("VOYAGE") != "" else 1
		get_tree().change_scene_to_file("res://scenes/island.tscn")
		return
	if f < 10:
		return
	isl = get_tree().current_scene
	if Game.voyage_number % 2 == 1:
		_blossom()
	else:
		_wind()


func _key(code: int, down: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = down
	Input.parse_input_event(e)


func _human() -> Player:
	for p in isl.players:
		if not p.input.is_bot():
			return p
	return null


func _bot() -> Player:
	for p in isl.players:
		if p.input.is_bot():
			return p
	return null


func _node(cls: String) -> Node:
	for c in isl.get_children():
		if c.get_script() and c.get_script().get_global_name() == cls:
			return c
	return null


func _put(p: Player, pos: Vector2) -> void:
	p.global_position = pos
	p.velocity = Vector2.ZERO
	p.respawn_point = pos


func _next() -> void:
	phase += 1
	phase_t = 0.0


func _check(label: String, ok: bool, timeout: float) -> void:
	if ok:
		print("PASS %s (%.1fs)" % [label, phase_t])
		_next()
	elif phase_t > timeout:
		failures += 1
		var b := _bot()
		print("FAIL %s  bot=%s task=%s want=%s" % [label, b.global_position, b.input.brain._task, b.input.brain._last])
		_next()


func _finish() -> void:
	print("RESULT: %s" % ("ALL PASSED" if failures == 0 else "%d FAILED" % failures))
	get_tree().quit()


func _blossom() -> void:
	match phase:
		0:
			_put(_human(), Vector2(650, 600))
			_next()
		1:
			_check("wall: bot climbs on the human and pulls the lever", _node("RisingStep")._raised, 25)
		2:
			_node("RisingStep").raise()
			for c in isl.get_children():
				if c is Lever and c.global_position.x < 1000:
					c.on = true
			_put(_human(), Vector2(1110, 460))
			_put(_bot(), Vector2(1000, 460))
			_next()
		3:
			_check("gate: bot crosses while the human holds plate A", _bot().global_position.x > 1260, 12)
		4:
			_put(_human(), Vector2(1180, 460))
			_next()
		5:
			_check("gate: bot holds plate B for the human",
				_node("Gate").global_position.y < 400 and absf(_bot().global_position.x - 1340) < 45, 12)
		6:
			_put(_human(), Vector2(1600, 460))
			_put(_bot(), Vector2(1420, 460))
			_next()
		7:
			_check("lift: bot boards and the lift rises", _node("Lift").position.y < 300, 15)
		8:
			_put(_human(), Vector2(1950, 280))
			_next()
		9:
			_check("lift: bot steps off at the top", _bot().global_position.x > 1720 and _bot().global_position.y < 300, 12)
		10:
			_finish()


func _wind() -> void:
	match phase:
		0:
			_put(_human(), Vector2(745, 600))
			_put(_bot(), Vector2(400, 600))
			_next()
		1:
			_check("vent: bot turns the low crank and the human flies", _human().global_position.y < 360, 15)
		2:
			_put(_human(), Vector2(850, 300))
			_key(KEY_E, true)
			_next()
		3:
			_check("vent: bot flies up to the ledge",
				_bot().global_position.y < 310 and _bot().global_position.x > 800 and _bot().is_on_floor(), 25)
		4:
			_key(KEY_E, false)
			_put(_human(), Vector2(1150, 300))
			_put(_bot(), Vector2(1000, 300))
			_next()
		5:
			if phase_t > 6.0 and phase_t < 6.05:
				_key(KEY_E, true)
			if phase_t > 6.1 and phase_t < 6.15:
				_key(KEY_E, false)
			_check("bells: bot rings together with the human", _node("BellBridge").built, 12)
		6:
			_put(_human(), Vector2(3000, 300))
			_put(_bot(), Vector2(2300, 300))
			_next()
		7:
			_check("clouds: bot rides the clouds across", _bot().global_position.x > 2900 and _bot().global_position.y < 310, 40)
		8:
			_finish()
