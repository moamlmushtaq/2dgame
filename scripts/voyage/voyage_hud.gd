class_name VoyageHud
extends Control
## Voyage heads-up display: hull, fuel, distance, altitude, rock warnings and banners.

var voyage
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := size
	var shadow := Color(0.15, 0.1, 0.35, 0.45)

	# Distance to the island.
	var track := Rect2(s.x * 0.5 - 250.0, 24, 500, 14)
	Paint.bar(self, track, voyage.distance, Color.WHITE, Color(1, 1, 1, 0.3))
	var isle := Vector2(track.end.x + 26.0, track.get_center().y)
	draw_colored_polygon(PackedVector2Array([isle + Vector2(-16, 0), isle + Vector2(16, 0), isle + Vector2(0, 14)]), Color("#8a5a48"))
	draw_circle(isle + Vector2(0, -3), 9.0, Color("#69c96b"), true, -1.0, true)
	var sx: float = track.position.x + track.size.x * voyage.distance
	draw_colored_polygon(Paint.ellipse(Vector2(sx, track.get_center().y - 12.0), 12.0, 7.0, 20), Ship.STRIPE_B)
	draw_style_box(Paint.box(Ship.WOOD, 3), Rect2(sx - 9.0, track.get_center().y - 3.0, 18, 7))
	Paint.text(self, Vector2(s.x * 0.5, 56), "المسافة إلى الجزيرة", 15, Color.WHITE, true, 4, shadow)

	# Hull (right) and fuel (left).
	_meter(Rect2(s.x - 250.0, 24, 220, 16), voyage.hp / 100.0, Color("#ff6f7d"), "الهيكل")
	_meter(Rect2(30, 24, 220, 16), voyage.fuel / 100.0, Color("#ffb03a"), "الوقود")
	if voyage.holes.size() > 0:
		Paint.text(self, Vector2(s.x - 140.0, 82), "ثقوب: %d" % voyage.holes.size(), 15, Color("#ffe0e3"), true, 4, shadow)
	if voyage.fuel <= 0.0 and voyage.is_sailing():
		Paint.text(self, Vector2(140, 82), "نفد الفحم! السفينة بطيئة", 15, Color("#fff0c2"), true, 4, shadow)

	_altitude_gauge(Rect2(26, s.y * 0.5 - 110.0, 12, 220), shadow)
	_rock_warnings(s)

	if voyage.banner_time > 0.0 and voyage.banner != "":
		var a := clampf(voyage.banner_time * 2.0, 0.0, 1.0)
		Paint.pill(self, Vector2(s.x * 0.5, 110), voyage.banner, 20, Color(0.2, 0.15, 0.35, a), Color(1, 1, 1, 0.9 * a))

	if voyage.is_wrecked():
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.05, 0.2, minf(voyage.end_time, 1.0) * 0.55))
		Paint.text(self, s * 0.5 + Vector2(0, -30), "تحطّمت السفينة!", 64, Color.WHITE, true, 8, shadow)
		if voyage.end_time > 1.5:
			var blink := 0.6 + 0.4 * sin(_t * 4.0)
			Paint.text(self, s * 0.5 + Vector2(0, 40), "اضغطوا زر التفاعل للمحاولة من جديد", 24, Color(1, 1, 1, blink), true, 4, shadow)
	elif voyage.has_arrived():
		var pop := minf(voyage.end_time * 2.0, 1.0)
		Paint.text(self, s * 0.5 + Vector2(0, -60), "وصلنا إلى الجزيرة!", int(30 + 34 * pop), Color("#fff4c2"), true, 8, shadow)


func _meter(r: Rect2, value: float, col: Color, label: String) -> void:
	var low: bool = value < 0.25 and voyage.is_sailing()
	var fill := col.lerp(Color.WHITE, 0.5 + 0.5 * sin(_t * 10.0)) if low else col
	Paint.bar(self, r, value, fill, Color(1, 1, 1, 0.3))
	Paint.text(self, Vector2(r.get_center().x, r.end.y + 16.0), label, 15, Color.WHITE, true, 4, Color(0.15, 0.1, 0.35, 0.45))


func _altitude_gauge(r: Rect2, shadow: Color) -> void:
	draw_style_box(Paint.box(Color(1, 1, 1, 0.3), 6), r)
	var f: float = 0.5 - voyage.altitude / (Helm.MAX_ALTITUDE * 2.0)
	var y := r.position.y + r.size.y * f
	draw_colored_polygon(Paint.ellipse(Vector2(r.get_center().x + 1.0, y - 7.0), 11.0, 7.0, 18), Ship.STRIPE_B)
	draw_style_box(Paint.box(Ship.WOOD, 3), Rect2(r.get_center().x - 7.0, y - 1.0, 16, 6))
	Paint.text(self, Vector2(r.get_center().x + 6.0, r.end.y + 18.0), "الارتفاع", 14, Color.WHITE, true, 4, shadow)


func _rock_warnings(s: Vector2) -> void:
	var xf := get_viewport().get_canvas_transform()
	for node in get_tree().get_nodes_in_group("rocks"):
		var rock := node as Rock
		var p := xf * rock.global_position
		if p.x < s.x - 20.0:
			continue
		var danger := rock.on_collision_course()
		var y := clampf(p.y, 100.0, s.y - 30.0)
		var col := Color("#ff4d5e") if danger else Color(1, 1, 1, 0.7)
		if danger:
			col = col.lerp(Color.WHITE, 0.35 + 0.35 * sin(_t * 12.0))
		var tip := Vector2(s.x - 14.0, y)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-30, -20), tip + Vector2(-30, 20)]), col)
		Paint.text(self, tip + Vector2(-19, 0), "!", 20, Color.WHITE)
