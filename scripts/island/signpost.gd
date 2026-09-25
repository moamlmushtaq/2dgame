class_name Signpost
extends Node2D
## A wooden sign with a hint. Use "\n" for line breaks.

var text := ""


func _draw() -> void:
	var lines := text.split("\n")
	var fs := 16
	var w := 0.0
	for l in lines:
		w = maxf(w, Paint.text_width(l, fs, false))
	var h := 24.0 * lines.size() + 14.0
	draw_rect(Rect2(-4, -60, 8, 60), Color("#8a5436"))
	var r := Rect2(-w * 0.5 - 14.0, -60.0 - h, w + 28.0, h)
	draw_style_box(Paint.box(Color("#f6dfb2"), 8, Color("#a8704f"), 3, 4), r)
	for i in lines.size():
		Paint.text(self, Vector2(0, r.position.y + 19.0 + i * 24.0), lines[i], fs, Color("#5a3a26"), false)
