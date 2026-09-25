class_name IslandHud
extends Control
## Island heads-up display: crystals, map pieces, banners and the victory card.

var island
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

	var gem := Vector2(s.x - 40.0, 34)
	draw_colored_polygon(PackedVector2Array([gem + Vector2(0, -13), gem + Vector2(10, -2), gem + Vector2(0, 13), gem + Vector2(-10, -2)]), Color("#56d8f5"))
	Paint.text(self, gem + Vector2(-70, 0), "البلورات %d/%d" % [island.gems_found, island.gems_total], 18, Color.WHITE, true, 4, shadow)
	Paint.text(self, Vector2(150, 30), "خريطة السماء", 16, Color.WHITE, true, 4, shadow)
	Paint.map_pieces(self, Vector2(60, 32), Game.map_pieces, Game.MAP_TOTAL, 18.0)
	Paint.text(self, Vector2(70, s.y - 22.0), "Esc: استراحة", 13, Color(1, 1, 1, 0.75), false, 3, shadow)

	if island.banner_time > 0.0 and island.banner != "":
		var a := clampf(island.banner_time * 2.0, 0.0, 1.0)
		Paint.pill(self, Vector2(s.x * 0.5, 40), island.banner, 20, Color(0.2, 0.15, 0.35, a), Color(1, 1, 1, 0.9 * a))

	if island.won and island.win_time > 0.8:
		var a := minf((island.win_time - 0.8) * 2.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.05, 0.25, 0.45 * a))
		var card := Rect2(s.x * 0.5 - 300.0, s.y * 0.5 - 170.0, 600, 340)
		draw_style_box(Paint.box(Color(1, 0.98, 0.93, a), 26, Color(1, 0.82, 0.48, a), 5, 12), card)
		var ink := Color(0.25, 0.17, 0.4, a)
		Paint.text(self, card.position + Vector2(300, 60), "أحسنتم يا طاقم!", 44, Color(0.9, 0.45, 0.35, a))
		var complete := Game.is_final_voyage()
		var line := "اكتملت خريطة السماء! لكن القراصنة يلحقون بكم..." if complete \
			else "حصلتم على قطعة الخريطة رقم %d من %d" % [Game.map_pieces, Game.MAP_TOTAL]
		Paint.text(self, card.position + Vector2(300, 118), line, 22, ink)
		Paint.map_pieces(self, card.position + Vector2(300, 160), Game.map_pieces, Game.MAP_TOTAL, 28.0)
		Paint.text(self, card.position + Vector2(300, 205), "البلورات: %d/%d" % [island.gems_found, island.gems_total], 20, Color(0.2, 0.6, 0.75, a))
		if island.win_time > 1.8:
			var blink := (0.6 + 0.4 * sin(_t * 4.0)) * a
			var next := "اضغطوا زر التفاعل لمواجهة القراصنة!" if complete else "اضغطوا زر التفاعل للإبحار إلى الجزيرة التالية"
			Paint.text(self, card.position + Vector2(300, 255), next, 20, Color(ink, blink))
			Paint.text(self, card.position + Vector2(300, 292), "تم حفظ تقدّمكم", 15, Color(ink, 0.6 * a), false)
