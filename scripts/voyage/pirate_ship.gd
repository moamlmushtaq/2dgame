class_name PirateShip
extends Node2D
## The sky pirates' flagship, the boss of the final voyage. It lobs bombs at the deck and
## sends storm birds; the crew must bring it down with both cannons.

const SCALE := 0.3
const SHIP_CENTER := Vector2(670, 340)
const PALETTE := {
	"wood": Color("#4d3d63"), "wood_dark": Color("#2f2540"), "wood_light": Color("#6f5d8a"),
	"gold": Color("#c9b6ff"), "stripe_a": Color("#3a2f4f"), "stripe_b": Color("#7a6aa0"), "name": "",
}

var voyage
var max_hp := 30
var hp := 30
var sinking := false
var angry := false
var _t := 0.0
var _bomb_timer := 4.0
var _bird_timer := 9.0
var _flash := 0.0
var _prop := 0.0
var _xf := Transform2D.IDENTITY


func _ready() -> void:
	add_to_group("boss")
	var n := Game.crew_strength()
	max_hp = int((34.0 + 11.0 * n) * [0.8, 1.0, 1.25][Game.settings["difficulty"]])
	hp = max_hp
	var s := Vector2(-SCALE, SCALE)  # mirrored so it faces our ship
	_xf = Transform2D(0.0, s, 0.0, -s * SHIP_CENTER)


func _physics_process(delta: float) -> void:
	_t += delta
	_prop += delta * 14.0
	_flash -= delta
	if sinking:
		rotation = move_toward(rotation, -0.5, delta * 0.3)
		position.y += delta * 160.0
		if randf() < 0.2:
			Fx.burst(get_parent(), global_position + Vector2(randf_range(-120, 120), randf_range(-60, 40)), Color("#6a5a85"), 8, 120.0, 0.6, -40.0)
		if global_position.y > 1100.0:
			visible = false  # kept alive: the HUD still reads its health
			set_physics_process(false)
		queue_redraw()
		return

	# Hover in the top-right, half-compensating for the helm so it stays on screen.
	position = Vector2(1190.0 + sin(_t * 0.4) * 40.0, 120.0 + sin(_t * 0.7) * 50.0 - voyage.altitude * 0.5)

	var rage := 1.25 if angry else 1.0
	_bomb_timer -= delta * rage * (1.0 + voyage.difficulty() * 0.4)
	if _bomb_timer <= 0.0:
		_bomb_timer = randf_range(2.6, 3.6)
		for i in 2 if Game.crew_strength() >= 4.0 else 1:
			voyage.spawn_bomb(muzzle(), Vector2(randf_range(220.0, 1080.0), Ship.DECK_Y))
		Sound.play("cannon", -6.0, 0.8)
	_bird_timer -= delta * rage
	if _bird_timer <= 0.0:
		_bird_timer = randf_range(9.0, 12.0)
		for i in 1 + int(Game.crew_strength() / 3.0):
			voyage.spawn_bird(i)
	queue_redraw()


func muzzle() -> Vector2:
	return global_position + Vector2(-150, 40)


## True if a point in world space touches the hull or the balloon.
func hit_test(p: Vector2) -> bool:
	if sinking:
		return false
	var q := (global_transform * _xf).affine_inverse() * p
	if Rect2(118, 460, 1110, 205).has_point(q):
		return true
	return ((q - Vector2(655, 170)) / Vector2(440, 120)).length() <= 1.0


func damage(amount: int) -> void:
	if sinking:
		return
	hp -= amount
	_flash = 0.1
	Sound.play("crack", -3.0, 0.8)
	if not angry and hp <= max_hp / 2:
		angry = true
		voyage.show_banner("القراصنة غاضبون! القنابل أسرع الآن")
	if hp <= 0:
		hp = 0
		sinking = true
		voyage.boss_defeated()


func _draw() -> void:
	modulate = Color(1.8, 1.8, 1.8) if _flash > 0.0 else Color.WHITE
	draw_set_transform_matrix(_xf)
	Ship.paint(self, _t, _prop, PALETTE)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# Storm emblem on the balloon.
	var e := _xf * Vector2(655, 170)
	draw_colored_polygon(PackedVector2Array([e + Vector2(4, -26), e + Vector2(-10, 2), e + Vector2(0, 2),
		e + Vector2(-6, 26), e + Vector2(12, -6), e + Vector2(2, -6)]), Color("#ffd35c"))
	# Angry eyes on the bow.
	var bow := _xf * Vector2(1150, 520)
	draw_line(bow + Vector2(-10, -12), bow + Vector2(4, -6), Color("#ffd35c"), 3.0, true)
	draw_circle(bow + Vector2(-2, -2), 4.0, Color("#ffd35c"), true, -1.0, true)
