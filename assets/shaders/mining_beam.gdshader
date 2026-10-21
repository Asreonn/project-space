shader_type spatial;
// Mining beam ribbon. Quad length runs along UV.x (0 = origin, 1 = target),
// width along UV.y. Cyan HDR core inside a warm orange sheath, slow scrolling
// ripples and a gentle breathing pulse. The beam never has its own length:
// mining_beam.gd stretches the quad exactly origin -> target and passes
// beam_length (m) only so ripple spacing stays in world units.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color_core : source_color = vec3(0.15, 0.75, 1.0);
uniform vec3 color_glow : source_color = vec3(1.0, 0.52, 0.22);
uniform float core_energy = 1.5;        // HDR: core blooms through the glow pass
uniform float glow_energy = 1.8;
uniform float scroll_speed = 6.0;       // m/s, ripples run origin -> target
uniform float ripple_spacing = 0.9;     // m
uniform float ripple_amount : hint_range(0.0, 1.0) = 0.25;
uniform float pulse_speed = 5.0;        // breathing (rad/s)
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.15;
uniform float beam_length = 5.0;
uniform float fade = 1.0;               // 0..1, start/stop ramp from script
uniform float core_width : hint_range(0.05, 1.0) = 0.3;  // fraction of quad width

void fragment() {
	float w = abs(UV.y - 0.5) * 2.0;
	float m = UV.x * beam_length;
	float breathe = 1.0 - pulse_amount + pulse_amount * (0.5 + 0.5 * sin(TIME * pulse_speed));
	float s = fract((m - TIME * scroll_speed) / ripple_spacing);
	float ripple = 1.0 - ripple_amount + ripple_amount * (1.0 - smoothstep(0.0, 0.5, abs(s - 0.5)));
	float cw = core_width * (0.92 + 0.08 * breathe);
	float core = 1.0 - smoothstep(cw * 0.35, cw, w);
	float hot = 1.0 - smoothstep(0.0, cw * 0.35, w);
	float sheath = clamp(1.0 - w, 0.0, 1.0);
	sheath = sheath * sheath * (1.0 - core * 0.6);
	// Short soft ends so it starts at the nozzle and lands on the hit point.
	float ends = smoothstep(0.0, 0.08, m) * (1.0 - smoothstep(beam_length - 0.04, beam_length, m));
	vec3 c = color_glow * sheath * glow_energy * (0.7 + 0.3 * ripple);
	c += color_core * core * core_energy * ripple;
	c += vec3(1.0) * hot * core_energy * 0.12;
	ALBEDO = c * breathe * ends * fade;
	ALPHA = clamp((core + sheath) * ends * fade, 0.0, 1.0);
}
