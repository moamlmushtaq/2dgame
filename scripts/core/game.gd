extends Node
## Global state shared by every scene: the crew, fonts, progress and fades.

const MAX_PLAYERS := 6
const COLORS: Array[Color] = [
	Color("#ff6f7d"), Color("#46b3ff"), Color("#4fd69c"),
	Color("#ffc53d"), Color("#a987ff"), Color("#ff9448"),
]
const NAMES: Array[String] = ["مرجان", "سماء", "نعناع", "عسل", "خزامى", "مشمش"]

const MENU_SCENE := "res://scenes/menu.tscn"
const VOYAGE_SCENE := "res://scenes/voyage.tscn"
const ISLAND_SCENE := "res://scenes/island.tscn"

## Each entry: {input: PlayerInput, color: Color, name: String, slot: int}
var players: Array[Dictionary] = []
var voyage_number := 1
var map_pieces := 0
var gems := 0

var font: Font
var font_bold: Font

var _fade: ColorRect
var _changing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var base: FontFile = load("res://assets/fonts/Cairo.ttf")
	font = _weight(base, 600)
	font_bold = _weight(base, 900)

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.12, 0.1, 0.25, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _weight(base: Font, weight: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {"wght": weight}
	return v


func _unhandled_input(event: InputEvent) -> void:
	var back := false
	if event is InputEventKey and event.pressed and not event.echo:
		back = (event as InputEventKey).physical_keycode == KEY_ESCAPE
	elif event is InputEventJoypadButton and event.pressed:
		back = (event as InputEventJoypadButton).button_index == JOY_BUTTON_BACK
	var scene := get_tree().current_scene
	if back and scene != null and scene.scene_file_path != MENU_SCENE:
		goto(MENU_SCENE)


func player_count() -> int:
	return maxi(players.size(), 1)


## 0 on the first voyage with two sailors; grows with crew size and with each voyage.
func difficulty() -> float:
	return maxf(0.0, (player_count() - 2) * 0.12 + (voyage_number - 1) * 0.18)


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


func new_game() -> void:
	voyage_number = 1
	map_pieces = 0
	gems = 0


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
