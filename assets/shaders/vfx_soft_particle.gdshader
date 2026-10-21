shader_type spatial;
// Shared soft round particle / sprite (billboard, unshaded, additive).
// Colour comes from the particle COLOR (colour ramp) times tint * energy.
// energy > 1 pushes the core into HDR so the WorldEnvironment glow picks it up.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 1.5;
uniform float softness : hint_range(0.05, 1.0) = 0.6;   // edge falloff
uniform float core : hint_range(0.0, 1.0) = 0.35;        // hot centre amount
uniform bool billboard = true;
uniform bool pulse = false;                               // idle pulsing (single sprites)
uniform float pulse_speed = 3.0;

void vertex() {
	if (billboard) {
		mat4 bb = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		bb = bb * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = VIEW_MATRIX * bb;
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float a = 1.0 - smoothstep(1.0 - softness, 1.0, d);
	a *= a;
	float hot = (1.0 - smoothstep(0.0, 0.35, d)) * core;
	float p = 1.0;
	if (pulse) {
		p = 0.75 + 0.25 * sin(TIME * pulse_speed + NODE_POSITION_WORLD.x * 3.0);
	}
	vec3 c = COLOR.rgb * tint.rgb * energy * p;
	ALBEDO = c * a + vec3(hot) * energy * COLOR.a * p;
	ALPHA = a * COLOR.a * tint.a;
}
