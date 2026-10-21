shader_type spatial;
// Soft alpha-blended dust puff (billboard, unshaded). Not additive, so it reads
// as matter against the bright nebula instead of more light.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float softness : hint_range(0.05, 1.0) = 0.9;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.35;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

varying float seed;

void vertex() {
	seed = float(INSTANCE_ID) * 0.37 + INSTANCE_CUSTOM.y * 0.6;
	mat4 bb = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	bb = bb * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 c = UV - 0.5;
	float n = vn(UV * 4.0 + vec2(seed, seed * 1.7) * 3.0);
	float d = length(c) * 2.0 + (n - 0.5) * noise_amount;
	float a = 1.0 - smoothstep(1.0 - softness, 1.0, d);
	ALBEDO = COLOR.rgb * tint.rgb;
	ALPHA = a * COLOR.a * tint.a;
}
