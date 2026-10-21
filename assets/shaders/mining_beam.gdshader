shader_type spatial;
// Mining beam ribbon. Quad length runs along UV.x (0 = origin, 1 = target),
// width along UV.y. Scrolling pulses in the core, soft glow sheath.
// beam_length (meters) is set by mining_beam.gd to keep the pulse spacing in world units.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color_core : source_color = vec3(1.0, 0.95, 0.85);
uniform vec3 color_glow : source_color = vec3(1.0, 0.55, 0.25);
uniform float energy = 3.0;
uniform float scroll_speed = 9.0;      // m/s
uniform float pulse_spacing = 0.6;      // m
uniform float beam_length = 5.0;
uniform float fade = 1.0;               // 0..1, start/stop ramp from script
uniform float core_width : hint_range(0.02, 1.0) = 0.22;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void fragment() {
	float w = abs(UV.y - 0.5) * 2.0;
	float m = UV.x * beam_length;
	float wob = 0.06 * sin(m * 7.0 - TIME * 13.0);
	float cw = core_width * (1.0 + wob);
	float core = 1.0 - smoothstep(cw * 0.4, cw, w);
	float sheath = pow(clamp(1.0 - w, 0.0, 1.0), 2.5);
	float s = fract((m - TIME * scroll_speed) / pulse_spacing);
	float pulse = 0.65 + 0.35 * smoothstep(0.0, 0.3, s) * (1.0 - smoothstep(0.5, 1.0, s));
	// Taper at both ends (short ends in meters).
	float ends = smoothstep(0.0, 0.12, m) * (1.0 - smoothstep(beam_length - 0.05, beam_length, m));
	float flick = 0.9 + 0.1 * hash(floor(TIME * 30.0));
	vec3 c = color_core * core * pulse * 1.2 + color_glow * sheath * (0.55 + 0.45 * pulse);
	ALBEDO = c * energy * ends * fade * flick;
	ALPHA = clamp((core + sheath) * ends * fade, 0.0, 1.0);
}
