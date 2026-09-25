class_name PlayerInput
extends RefCounted
## Reads one player's controls: half of the keyboard, or one gamepad.
## Keys are read by physical position, so any keyboard layout (Arabic too) works.

enum Kind { KEYBOARD, GAMEPAD }

const ACTIONS := ["left", "right", "up", "down", "jump", "interact"]
const KEYBOARD_SCHEMES := [
	{
		"left": [KEY_A], "right": [KEY_D], "up": [KEY_W], "down": [KEY_S],
		"jump": [KEY_SPACE], "interact": [KEY_E],
		"jump_name": "Space", "interact_name": "E", "name": "كيبورد - WASD",
	},
	{
		"left": [KEY_LEFT], "right": [KEY_RIGHT], "up": [KEY_UP], "down": [KEY_DOWN],
		"jump": [KEY_PERIOD, KEY_ENTER, KEY_KP_ENTER, KEY_KP_0],
		"interact": [KEY_SLASH, KEY_KP_1, KEY_KP_PERIOD],
		"jump_name": ".", "interact_name": "/", "name": "كيبورد - الأسهم",
	},
]
const STICK_DEADZONE := 0.3

var kind := Kind.KEYBOARD
var device := 0

var _now := {}
var _prev := {}


static func keyboard(scheme: int) -> PlayerInput:
	var i := PlayerInput.new()
	i.kind = Kind.KEYBOARD
	i.device = scheme
	return i


static func gamepad(id: int) -> PlayerInput:
	var i := PlayerInput.new()
	i.kind = Kind.GAMEPAD
	i.device = id
	return i


func same_as(other: PlayerInput) -> bool:
	return other != null and other.kind == kind and other.device == device


## Call exactly once per physics frame, before reading pressed()/held().
func poll() -> void:
	_prev = _now
	_now = {}
	for a in ACTIONS:
		_now[a] = _raw(a)


func held(action: String) -> bool:
	return _now.get(action, false)


func pressed(action: String) -> bool:
	return _now.get(action, false) and not _prev.get(action, false)


func axis_x() -> float:
	if kind == Kind.GAMEPAD:
		var v := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		if absf(v) > STICK_DEADZONE:
			return clampf(v * 1.2, -1.0, 1.0)
	return float(held("right")) - float(held("left"))


func axis_y() -> float:
	if kind == Kind.GAMEPAD:
		var v := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		if absf(v) > STICK_DEADZONE:
			return clampf(v * 1.2, -1.0, 1.0)
	return float(held("down")) - float(held("up"))


func device_name() -> String:
	if kind == Kind.KEYBOARD:
		return KEYBOARD_SCHEMES[device]["name"]
	return "يد تحكم %d" % (device + 1)


func jump_name() -> String:
	return KEYBOARD_SCHEMES[device]["jump_name"] if kind == Kind.KEYBOARD else "A"


func interact_name() -> String:
	return KEYBOARD_SCHEMES[device]["interact_name"] if kind == Kind.KEYBOARD else "X"


func _raw(action: String) -> bool:
	if kind == Kind.KEYBOARD:
		for key in KEYBOARD_SCHEMES[device][action]:
			if Input.is_physical_key_pressed(key):
				return true
		return false
	match action:
		"left":
			return Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT) \
				or Input.get_joy_axis(device, JOY_AXIS_LEFT_X) < -0.5
		"right":
			return Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT) \
				or Input.get_joy_axis(device, JOY_AXIS_LEFT_X) > 0.5
		"up":
			return Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP) \
				or Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) < -0.5
		"down":
			return Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN) \
				or Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) > 0.5
		"jump":
			return Input.is_joy_button_pressed(device, JOY_BUTTON_A)
		"interact":
			return Input.is_joy_button_pressed(device, JOY_BUTTON_X) \
				or Input.is_joy_button_pressed(device, JOY_BUTTON_B)
	return false
