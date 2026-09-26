class_name Atmosphere
extends CanvasLayer
## The finishing pass over each scene: bloom, colour grade and vignette (see
## assets/shaders/atmosphere.gdshader). Sits above the world and below the HUD, so the
## HUD and text stay crisp. Pick a look with one of the PRESETS. Scenes that draw their
## text in the world layer (menu, story) pass a layer below 0 so only the sky is graded.

const SHADER := preload("res://assets/shaders/atmosphere.gdshader")
const PRESETS := {
	"day": {"shadow_tint": Vector3(0.93, 0.97, 1.1), "highlight_tint": Vector3(1.06, 1.02, 0.94),
		"saturation": 1.1, "contrast": 1.05, "vignette": 0.32, "vignette_color": Vector3(0.2, 0.14, 0.34),
		"bloom_strength": 0.27, "bloom_threshold": 0.84},
	"blossom": {"shadow_tint": Vector3(0.96, 0.95, 1.08), "highlight_tint": Vector3(1.07, 1.02, 0.93),
		"saturation": 1.12, "contrast": 1.05, "vignette": 0.34, "vignette_color": Vector3(0.24, 0.12, 0.3),
		"bloom_strength": 0.30, "bloom_threshold": 0.82},
	"wind": {"shadow_tint": Vector3(0.95, 0.93, 1.12), "highlight_tint": Vector3(1.05, 1.0, 0.98),
		"saturation": 1.1, "contrast": 1.05, "vignette": 0.36, "vignette_color": Vector3(0.18, 0.12, 0.36),
		"bloom_strength": 0.30, "bloom_threshold": 0.82},
	"dusk": {"shadow_tint": Vector3(0.95, 0.92, 1.12), "highlight_tint": Vector3(1.08, 1.0, 0.94),
		"saturation": 1.12, "contrast": 1.04, "vignette": 0.4, "vignette_color": Vector3(0.16, 0.08, 0.3),
		"bloom_strength": 0.36, "bloom_threshold": 0.78},
	"sunset": {"shadow_tint": Vector3(0.98, 0.93, 1.05), "highlight_tint": Vector3(1.08, 1.0, 0.9),
		"saturation": 1.1, "contrast": 1.04, "vignette": 0.36, "vignette_color": Vector3(0.28, 0.12, 0.2),
		"bloom_strength": 0.36, "bloom_threshold": 0.78},
	"battle": {"shadow_tint": Vector3(0.92, 0.94, 1.12), "highlight_tint": Vector3(1.08, 1.0, 0.92),
		"saturation": 1.08, "contrast": 1.08, "vignette": 0.45, "vignette_color": Vector3(0.18, 0.08, 0.28),
		"bloom_strength": 0.30, "bloom_threshold": 0.82},
}

var _rect: ColorRect
var _mat: ShaderMaterial


func _init(preset := "day", on_layer := 5) -> void:
	layer = on_layer
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	use(preset)


func _process(_delta: float) -> void:
	# "Low" graphics quality in the settings skips this full-screen pass.
	_rect.visible = Game.settings.get("fancy", true)


func use(preset: String) -> void:
	var p: Dictionary = PRESETS.get(preset, PRESETS["day"])
	for key: String in p:
		_mat.set_shader_parameter(key, p[key])
