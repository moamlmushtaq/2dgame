// Full-screen finishing pass drawn above the game world and below the HUD:
// soft bloom around bright areas, a two-tone colour grade, a saturation and
// contrast lift, and a gentle vignette. Works on the Compatibility renderer.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_strength = 0.4;
uniform float bloom_threshold = 0.7;
uniform float bloom_radius = 9.0;
uniform vec3 shadow_tint = vec3(0.94, 0.96, 1.08);
uniform vec3 highlight_tint = vec3(1.05, 1.02, 0.95);
uniform float saturation = 1.08;
uniform float contrast = 1.04;
uniform float vignette = 0.35;
uniform vec3 vignette_color = vec3(0.16, 0.08, 0.28);

vec3 bright_at(vec2 uv) {
	vec3 c = textureLod(screen_tex, uv, 1.5).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return c * smoothstep(bloom_threshold, 1.0, l);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = textureLod(screen_tex, uv, 0.0).rgb;

	// Bloom: two rings of taps around the pixel, keeping only what is bright.
	vec2 px = SCREEN_PIXEL_SIZE * bloom_radius;
	vec3 bloom = vec3(0.0);
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398 + 0.39;
		vec2 d = vec2(cos(a), sin(a));
		bloom += bright_at(uv + d * px);
		bloom += bright_at(uv + d * px * 2.4) * 0.6;
	}
	col += bloom / 12.8 * bloom_strength;

	// Grade: cool the shadows, warm the highlights, then lift saturation and contrast.
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col *= mix(shadow_tint, highlight_tint, smoothstep(0.15, 0.85, l));
	col = mix(vec3(l), col, saturation);
	col = (col - 0.5) * contrast + 0.5;

	// Vignette, stretched to the screen's shape.
	vec2 q = (uv - 0.5) * vec2(1.0, 0.8);
	float v = smoothstep(0.28, 0.75, length(q)) * vignette;
	col = mix(col, col * vignette_color * 2.2, v);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
