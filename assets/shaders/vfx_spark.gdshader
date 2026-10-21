shader_type spatial;
// Stretched spark streak. Use with ParticleProcessMaterial transform_align
// "Z billboard + Y to velocity" so the quad's Y axis follows the velocity.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 3.0;

void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float y = UV.y;
	float a = (1.0 - smoothstep(0.2, 1.0, x)) * smoothstep(0.0, 0.25, y) * (1.0 - smoothstep(0.6, 1.0, y));
	ALBEDO = COLOR.rgb * tint.rgb * energy * a;
	ALPHA = a * COLOR.a;
}
