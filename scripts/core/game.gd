extends Node
## Global state shared by every scene: the crew, fonts, story progress, settings,
## the save file, scene fades and the pause menu.

const MAX_PLAYERS := 6
const MAP_TOTAL := 4
const COLORS: Array[Color] = [
	Color("#ff6f7d"), Color("#46b3ff"), Color("#4fd69c"),
	Color("#ffc53d"), Color("#a987ff"), Color("#ff9448"),
]
const NAMES: Array[String] = ["مرجان", "سماء", "نعناع", "عسل", "خزامى", "مشمش"]
const DIFFICULTY_NAMES: Array[String] = ["سهل", "عادي", "صعب"]

const MENU_SCENE := "res://scenes/menu.tscn"
const STORY_SCENE := "res://scenes/story.tscn"
const VOYAGE_SCENE := "res://scenes/voyage.tscn"
const ISLAND_SCENE := "res://scenes/island.tscn"
const SAVE_PATH := "user://cloud_ship.cfg"

## Each entry: {input: PlayerInput, color: Color, name: String, slot: int}
var players: Array[Dictionary] = []
var voyage_number := 1
var map_pieces := 0
var gems := 0
## "intro" or "ending": which story the story scene tells.
var story_kind := "intro"

var settings := {"music": 7, "sfx": 8, "fullscreen": false, "difficulty": 1}
var stats := {"runs": 0, "best_gems": 0}
## The run in progress, saved after every island: {voyage, pieces, gems}.
var saved_run := {}

var font: Font
var font_bold: Font
var paused := false

var _fade: ColorRect
var _changing := false
var _pause_view: Overlay
var _pause_main: OptionList
var _pause_settings: OptionList
var _pause_page := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var base: FontFile = load("res://assets/fonts/Cairo.ttf")
	font = _weight(base, 600)
	font_bold = _weight(base, 900)

	var pause_layer := CanvasLayer.new()
	pause_layer.layer = 90
	add_child(pause_layer)
	_pause_view = Overlay.new()
	_pause_view.paint = _draw_pause
	_pause_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_view.visible = false
	pause_layer.add_child(_pause_view)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.12, 0.1, 0.25, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)

	_pause_main = OptionList.new()
	_pause_main.add("متابعة اللعب", resume)
	_pause_main.add("إعادة المرحلة", func() -> void:
		resume()
		goto(get_tree().current_scene.scene_file_path))
	_pause_main.add("الإعدادات", func() -> void:
		_pause_page = "settings"
		_pause_settings.index = 0)
	_pause_main.add("القائمة الرئيسية", func() -> void:
		resume()
		goto(MENU_SCENE))
	_pause_settings = settings_list(func() -> void: _pause_page = "main")

	load_save()
	apply_settings.call_deferred()


func _weight(base: Font, weight: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {"wght": weight}
	return v


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		if key == KEY_ESCAPE:
			_on_pause_button()
		elif key == KEY_F11:
			settings["fullscreen"] = not settings["fullscreen"]
			apply_settings()
			save()
	elif event is InputEventJoypadButton and event.pressed:
		var button := (event as InputEventJoypadButton).button_index
		if button == JOY_BUTTON_START or button == JOY_BUTTON_BACK:
			_on_pause_button()


func _on_pause_button() -> void:
	if paused:
		if _pause_page == "settings":
			_pause_page = "main"
		else:
			resume()
	else:
		pause()


func _process(_delta: float) -> void:
	if not paused:
		return
	var list := _pause_settings if _pause_page == "settings" else _pause_main
	for p in players:
		var input: PlayerInput = p["input"]
		input.poll()
		list.handle(input)
		if not paused:
			return


# --- Crew ----------------------------------------------------------------------

func player_count() -> int:
	return maxi(players.size(), 1)


## Grows with crew size and with each voyage, shifted by the chosen difficulty.
func difficulty() -> float:
	var base := (player_count() - 2) * 0.12 + (voyage_number - 1) * 0.15
	return maxf(-0.4, base + [-0.3, 0.0, 0.35][settings["difficulty"]])


## Multiplier for damage the ship takes.
func damage_scale() -> float:
	return [0.6, 1.0, 1.35][settings["difficulty"]]


func has_input(input: PlayerInput) -> bool:
	for p in players:
		if (p["input"] as PlayerInput).same_as(input):
			return true
	return false


func add_player(input: PlayerInput) -> bool:
	if players.size() >= MAX_PLAYERS or has_input(input):
		return false
	var slot := players.size()
	players.append({"input": input, "color": COLORS[slot], "name": NAMES[slot], "slot": slot})
	return true


## Lets a scene be launched directly from the editor (F6) with two keyboard sailors.
func ensure_players() -> void:
	if players.is_empty():
		add_player(PlayerInput.keyboard(0))
		add_player(PlayerInput.keyboard(1))


# --- Story progress ------------------------------------------------------------

func new_game() -> void:
	voyage_number = 1
	map_pieces = 0
	gems = 0
	saved_run = {}
	save()


## The last voyage, against the pirate flagship, comes once every map piece is found.
func is_final_voyage() -> bool:
	return map_pieces >= MAP_TOTAL


func has_saved_run() -> bool:
	return not saved_run.is_empty()


func continue_run() -> void:
	voyage_number = saved_run.get("voyage", 1)
	map_pieces = saved_run.get("pieces", 0)
	gems = saved_run.get("gems", 0)


## Called after each island so the crew can pick up from the next voyage.
func checkpoint_run() -> void:
	saved_run = {"voyage": voyage_number, "pieces": map_pieces, "gems": gems}
	save()


func finish_run() -> void:
	stats["runs"] += 1
	stats["best_gems"] = maxi(stats["best_gems"], gems)
	saved_run = {}
	save()


# --- Settings and save file ----------------------------------------------------

func load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	for k in settings.keys():
		settings[k] = cf.get_value("settings", k, settings[k])
	for k in stats.keys():
		stats[k] = cf.get_value("stats", k, stats[k])
	saved_run = cf.get_value("run", "state", {})


func save() -> void:
	var cf := ConfigFile.new()
	for k in settings:
		cf.set_value("settings", k, settings[k])
	for k in stats:
		cf.set_value("stats", k, stats[k])
	cf.set_value("run", "state", saved_run)
	cf.save(SAVE_PATH)


func apply_settings() -> void:
	Sound.set_volumes(settings["music"] / 10.0, settings["sfx"] / 10.0)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode and not OS.has_feature("web"):
		DisplayServer.window_set_mode(mode)


## Builds the settings menu used by both the title screen and the pause menu.
func settings_list(back: Callable) -> OptionList:
	var l := OptionList.new()
	l.add(func() -> String: return "الموسيقى: %d" % settings["music"], Callable(),
		func(d: int) -> void: _bump("music", d, 0, 10))
	l.add(func() -> String: return "المؤثرات: %d" % settings["sfx"], Callable(),
		func(d: int) -> void: _bump("sfx", d, 0, 10))
	if not OS.has_feature("web"):
		l.add(func() -> String: return "ملء الشاشة: %s" % ("نعم" if settings["fullscreen"] else "لا"), Callable(),
			func(_d: int) -> void: _bump("fullscreen", 0, 0, 0))
	l.add(func() -> String: return "الصعوبة: %s" % DIFFICULTY_NAMES[settings["difficulty"]], Callable(),
		func(d: int) -> void: _bump("difficulty", d, 0, 2))
	l.add("رجوع", back)
	return l


func _bump(key: String, d: int, lo: int, hi: int) -> void:
	if settings[key] is bool:
		settings[key] = not settings[key]
	else:
		settings[key] = clampi(settings[key] + d, lo, hi)
	apply_settings()
	save()


# --- Pause and scene changes ---------------------------------------------------

func pause() -> void:
	var scene := get_tree().current_scene
	if _changing or scene == null or not scene.scene_file_path in [VOYAGE_SCENE, ISLAND_SCENE]:
		return
	paused = true
	get_tree().paused = true
	_pause_page = "main"
	_pause_main.index = 0
	_pause_view.visible = true
	for p in players:
		(p["input"] as PlayerInput).poll()
	Sound.play("click", -2.0)


func resume() -> void:
	paused = false
	get_tree().paused = false
	_pause_page = ""
	_pause_view.visible = false


func _draw_pause(ci: Control) -> void:
	var s := ci.size
	ci.draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.06, 0.25, 0.55))
	var settings_page := _pause_page == "settings"
	var list := _pause_settings if settings_page else _pause_main
	var h := list.items.size() * 54.0 + 130.0
	var card := Rect2(s.x * 0.5 - 240.0, s.y * 0.5 - h * 0.5, 480, h)
	ci.draw_style_box(Paint.box(Color(0.33, 0.3, 0.62, 0.96), 26, Color(1, 1, 1, 0.5), 3, 12), card)
	Paint.text(ci, Vector2(s.x * 0.5, card.position.y + 44.0), "الإعدادات" if settings_page else "استراحة قصيرة", 32, Color.WHITE)
	list.draw(ci, Vector2(s.x * 0.5, card.position.y + 80.0 + list.items.size() * 27.0), 380.0, 54.0)
	Paint.text(ci, Vector2(s.x * 0.5, card.end.y - 22.0), "الأسهم للتنقل، والتفاعل للاختيار", 14, Color(1, 1, 1, 0.7), false)


func goto(path: String) -> void:
	if _changing:
		return
	_changing = true
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, 0.35)
	await out.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, 0.45)
	_changing = false


## A full-screen Control that draws itself with a callback.
class Overlay:
	extends Control

	var paint: Callable

	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		if paint.is_valid():
			paint.call(self)
