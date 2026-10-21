shader_type spatial;
// Thin expanding ring (billboard, additive) for the collect "pop".
// Particle scale drives the radius; COLOR alpha fades it.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 2.0;
uniform float thickness : hint_range(0.01, 0.5) = 0.12;

void vertex() {
	mat4 bb = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	bb = bb * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float ring = 1.0 - smoothstep(0.0, thickness, abs(d - (1.0 - thickness)));
	float inner = (1.0 - smoothstep(0.0, 0.9, d)) * 0.15;
	float a = (ring + inner) * COLOR.a;
	ALBEDO = tint.rgb * COLOR.rgb * energy * a;
	ALPHA = a;
}
