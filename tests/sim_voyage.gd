extends Node
## Headless voyage simulation: one idle human plus BOTS helpers sail a voyage
## (or the pirate battle when PIECES=4) and the result is printed.
## Run with tests/run.sh voyage — see CLAUDE.md.

var f := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(_delta: float) -> void:
	f += 1
	if f == 2:
		Game.players.clear()
		Game.add_player(PlayerInput.keyboard(0))
		Game.settings["bots"] = int(OS.get_environment("BOTS")) if OS.get_environment("BOTS") != "" else 2
		Game.fill_bots()
		Game.map_pieces = int(OS.get_environment("PIECES"))
		Game.voyage_number = 1 + Game.map_pieces
		get_tree().change_scene_to_file("res://scenes/voyage.tscn")
		return
	var v := get_tree().current_scene
	if f < 10 or v == null or not v.has_method("is_sailing"):
		return
	if f % 1200 == 0:
		var boss: String = ("%d/%d" % [v.boss.hp, v.boss.max_hp]) if v.boss else "-"
		print("t=%ds hp=%.0f fuel=%.0f dist=%.2f holes=%d boss=%s" % [f / 60, v.hp, v.fuel, v.distance, v.holes.size(), boss])
	if not v.is_sailing():
		print("RESULT: %s at t=%ds hp=%.0f" % ["WRECKED" if v.is_wrecked() else "WON", f / 60, v.hp])
		get_tree().quit()
	elif f > 60 * 200:
		print("RESULT: TIMEOUT")
		get_tree().quit()
