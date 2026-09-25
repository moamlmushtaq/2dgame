class_name Signpost
extends Node2D
## A wooden sign with a hint. Use "\n" for line breaks.
## Board art: Glitch `sign_blank_wide` (CC0, see assets/art/CREDITS.md).

const BOARD := preload("res://assets/art/island/signboard.png")
const POST_H := 50.0

var text := ""


func _draw() -> void:
	var lines := text.split("\n")
	var fs := 16
	var w := 0.0
	for l in lines:
		w = maxf(w, Paint.text_width(l, fs, false))
	var h := 24.0 * lines.size() + 14.0
	# The board art (rows 0-98) stretches to fit the text; its posts keep their height.
	var bw := w + 44.0
	var bh := h + 26.0
	Paint.ground_shadow(self, Vector2(0, 0), bw * 0.45)
	draw_texture_rect_region(BOARD, Rect2(-bw * 0.5, -POST_H, bw, POST_H), Rect2(0, 98, BOARD.get_width(), BOARD.get_height() - 98))
	draw_texture_rect_region(BOARD, Rect2(-bw * 0.5, -POST_H - bh, bw, bh), Rect2(0, 0, BOARD.get_width(), 99))
	for i in lines.size():
		Paint.text(self, Vector2(0, -POST_H - bh + 13.0 + 19.0 + i * 24.0), lines[i], fs, Color("#4a2e1c"), false)
