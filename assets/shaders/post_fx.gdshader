shader_type canvas_item;
// Light screen post: vignette + very subtle chromatic aberration (+ optional grain).
// Used by scenes/vfx/post_fx.tscn on a full-rect ColorRect. Disable by hiding the layer.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.32;
uniform float vignette_radius : hint_range(0.2, 1.5) = 0.85;
uniform float vignette_softness : hint_range(0.05, 1.0) = 0.55;
uniform vec3 vignette_color : source_color = vec3(0.06, 0.03, 0.10);
uniform float aberration : hint_range(0.0, 0.01) = 0.0012; // in UV at the screen edge
uniform float grain : hint_range(0.0, 0.1) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 ca = c * vec2(aspect, 1.0);
	float d = length(ca);
	vec3 col;
	if (aberration > 0.0) {
		vec2 off = c * aberration * d * 2.0;
		col.r = texture(screen_tex, uv + off).r;
		col.g = texture(screen_tex, uv).g;
		col.b = texture(screen_tex, uv - off).b;
	} else {
		col = texture(screen_tex, uv).rgb;
	}
	float v = (1.0 - smoothstep(vignette_radius - vignette_softness, vignette_radius, d));
	col = mix(vignette_color, col, mix(1.0, v, vignette_strength));
	if (grain > 0.0) {
		float n = fract(sin(dot(uv * 1000.0 + TIME, vec2(12.9898, 78.233))) * 43758.5453);
		col += (n - 0.5) * grain;
	}
	COLOR = vec4(col, 1.0);
}
