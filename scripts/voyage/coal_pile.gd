class_name CoalPile
extends Interactable
## A bin of coal. Grab a lump and carry it to the furnace.

const LUMPS := [
	Vector3(-30, -30, 11), Vector3(-10, -36, 13), Vector3(12, -34, 12), Vector3(30, -29, 10),
	Vector3(-18, -46, 11), Vector3(4, -50, 12), Vector3(20, -44, 10), Vector3(-4, -60, 10),
]


func _ready() -> void:
	interact_radius = 62.0
	z_index = 2


func can_interact(player: Player) -> bool:
	return player.carrying == ""


func interact(player: Player) -> void:
	player.carrying = "coal"
	Sound.play("coal")
	Fx.burst(get_parent(), player.center() + Vector2(0, -30), Color("#6a5f73"), 8, 90.0, 0.35)


func hint(_player: Player) -> String:
	return "خذ فحمًا"


func _draw() -> void:
	for l: Vector3 in LUMPS:
		draw_circle(Vector2(l.x, l.y), l.z, Color("#3b3440"), true, -1.0, true)
		draw_circle(Vector2(l.x - l.z * 0.3, l.y - l.z * 0.35), l.z * 0.35, Color("#5d5468"), true, -1.0, true)
	draw_style_box(Paint.box(Color("#8a5436"), 6), Rect2(-48, -30, 96, 30))
	draw_rect(Rect2(-48, -30, 96, 5), Color("#dca46e"))
	draw_line(Vector2(-16, -24), Vector2(-16, -2), Color("#6d412a"), 3.0)
	draw_line(Vector2(16, -24), Vector2(16, -2), Color("#6d412a"), 3.0)
