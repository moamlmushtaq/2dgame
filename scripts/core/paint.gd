class_name Paint
extends RefCounted
## Shared drawing helpers so every scene has the same soft, rounded look.

static var _boxes := {}


static func ellipse(c: Vector2, rx: float, ry: float, n := 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## A cached rounded box, drawn with CanvasItem.draw_style_box().
static func box(bg: Color, radius := 12, border := Color(0, 0, 0, 0), border_width := 0, shadow := 0) -> StyleBoxFlat:
	var key := "%s|%d|%s|%d|%d" % [bg.to_html(), radius, border.to_html(), border_width, shadow]
	if _boxes.has(key):
		return _boxes[key]
	if _boxes.size() > 256:
		_boxes.clear()  # fading colours create many one-off boxes
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if border_width > 0:
		sb.border_color = border
		sb.set_border_width_all(border_width)
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.18)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, shadow * 0.5)
	_boxes[key] = sb
	return sb


static func text_width(s: String, size: int, bold := true) -> float:
	var f: Font = Game.font_bold if bold else Game.font
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Draws text centred on `center` on both axes, with an optional outline.
static func text(ci: CanvasItem, center: Vector2, s: String, size: int, col: Color, bold := true, outline := 0, outline_col := Color(0, 0, 0, 0.35)) -> void:
	var f: Font = Game.font_bold if bold else Game.font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := Vector2(center.x - w * 0.5, center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	if outline > 0:
		ci.draw_string_outline(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_col)
	ci.draw_string(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## A rounded pill with text inside, centred on `center`.
static func pill(ci: CanvasItem, center: Vector2, s: String, size: int, fg: Color, bg: Color) -> void:
	var w := text_width(s, size) + size * 1.6
	var h := size * 2.0
	ci.draw_style_box(box(bg, int(h * 0.5), Color(0, 0, 0, 0), 0, 6), Rect2(center.x - w * 0.5, center.y - h * 0.5, w, h))
	text(ci, center, s, size, fg)


## A rounded progress bar; `value` is 0..1.
static func bar(ci: CanvasItem, rect: Rect2, value: float, fill: Color, back := Color(1, 1, 1, 0.3)) -> void:
	var r := int(rect.size.y * 0.5)
	ci.draw_style_box(box(back, r), rect)
	var w := rect.size.x * clampf(value, 0.0, 1.0)
	if w >= rect.size.y * 0.6:
		ci.draw_style_box(box(fill, r), Rect2(rect.position, Vector2(w, rect.size.y)))
