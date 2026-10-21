shader_type spatial;
// Soft engine flame on a flat quad lying in the ship XZ plane.
// UV.y = 0 at the nozzle, 1 at the tail. Set intensity/boost from engine_trail.gd.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color_core : source_color = vec3(0.85, 0.95, 1.0);
uniform vec3 color_outer : source_color = vec3(0.25, 0.55, 1.0);
uniform vec3 color_boost : source_color = vec3(0.55, 0.75, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float boost : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 2.2;
uniform float flicker_speed = 22.0;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void fragment() {
	float x = (UV.x - 0.5) * 2.0;
	float y = UV.y;
	float t = TIME * flicker_speed;
	float fl = 0.88 + 0.12 * mix(hash(floor(t)), hash(floor(t) + 1.0), fract(t));
	// Teardrop: wide near the nozzle, thin at the tail.
	float width = mix(1.0, 0.08, pow(clamp(y, 0.0, 1.0), 0.8));
	float edge = 1.0 - smoothstep(width * 0.45, width, abs(x));
	float along = (1.0 - smoothstep(0.0, 1.0, y)) * smoothstep(0.0, 0.06, y);
	float a = edge * along;
	float core_m = (1.0 - smoothstep(0.0, width * 0.35, abs(x))) * (1.0 - smoothstep(0.0, 0.5, y));
	vec3 outer = mix(color_outer, color_boost, boost);
	vec3 c = outer * a + color_core * core_m * (0.8 + boost * 0.6);
	float e = energy * mix(0.35, 1.0, intensity) * (1.0 + boost * 0.8) * fl;
	ALBEDO = c * e;
	ALPHA = clamp(a, 0.0, 1.0);
}
