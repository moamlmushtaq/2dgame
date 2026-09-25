class_name OptionList
extends RefCounted
## A vertical menu driven by any PlayerInput: up/down moves, left/right changes a value,
## interact (and optionally jump) chooses.

var items: Array[Dictionary] = []
var index := 0
var accept_jump := true


## `label` is a String or a Callable returning one. `choose` runs on select;
## `change` receives -1 or +1 for left/right.
func add(label, choose := Callable(), change := Callable()) -> OptionList:
	items.append({"label": label, "choose": choose, "change": change})
	return self


func label_of(i: int) -> String:
	var l = items[i]["label"]
	return l.call() if l is Callable else str(l)


func handle(input: PlayerInput) -> void:
	if items.is_empty():
		return
	if input.pressed("up"):
		index = wrapi(index - 1, 0, items.size())
		Sound.play("click", -6.0)
	elif input.pressed("down"):
		index = wrapi(index + 1, 0, items.size())
		Sound.play("click", -6.0)
	var item: Dictionary = items[index]
	var change: Callable = item["change"]
	var choose: Callable = item["choose"]
	if change.is_valid():
		if input.pressed("left"):
			change.call(-1)
			Sound.play("click", -4.0, 0.9)
		elif input.pressed("right"):
			change.call(1)
			Sound.play("click", -4.0, 1.1)
	if input.pressed("interact") or (accept_jump and input.pressed("jump")):
		if choose.is_valid():
			Sound.play("join", -4.0, 1.4)
			choose.call()
		elif change.is_valid():
			change.call(1)
			Sound.play("click", -4.0, 1.1)


func draw(ci: CanvasItem, center: Vector2, width := 380.0, row := 50.0, alpha := 1.0) -> void:
	var top := center.y - row * items.size() * 0.5
	for i in items.size():
		var selected := i == index
		var r := Rect2(center.x - width * 0.5, top + i * row + 4.0, width, row - 8.0)
		var bg := Color(1, 1, 1, 0.94 * alpha) if selected else Color(0.22, 0.17, 0.45, 0.55 * alpha)
		var radius := int((row - 8.0) * 0.5)
		if selected:
			ci.draw_style_box(Paint.box(bg, radius, Color(0, 0, 0, 0), 0, 6), r)
			# Glossy top half so the chosen button looks raised.
			ci.draw_style_box(Paint.box(Color(1, 1, 1, 0.55 * alpha), radius), Rect2(r.position + Vector2(6, 3), Vector2(r.size.x - 12.0, r.size.y * 0.42)))
		else:
			ci.draw_style_box(Paint.box(bg, radius, Color(1, 1, 1, 0.22 * alpha), 2), r)
		var fg := Color(0.23, 0.18, 0.42, alpha) if selected else Color(1, 1, 1, alpha)
		Paint.text(ci, r.get_center(), label_of(i), 20, fg)
		if selected and (items[i]["change"] as Callable).is_valid():
			for side: int in [-1, 1]:
				var tip := Vector2(r.get_center().x + side * (width * 0.5 - 18.0), r.get_center().y)
				ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(side * 7.0, 0), tip + Vector2(-side * 3.0, -7),
					tip + Vector2(-side * 3.0, 7)]), fg)
