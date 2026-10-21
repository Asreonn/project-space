shader_type spatial;
// Distant planet impostor on a flat quad (top-down camera): lit sphere,
// soft banding, fresnel atmosphere rim and optional ring. Unshaded, one pass.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color_a : source_color = vec3(0.98, 0.66, 0.46);
uniform vec3 color_b : source_color = vec3(0.80, 0.42, 0.42);
uniform vec3 color_shadow : source_color = vec3(0.16, 0.08, 0.22);
uniform vec3 atmosphere_color : source_color = vec3(1.0, 0.72, 0.55);
uniform float atmosphere_strength : hint_range(0.0, 3.0) = 0.8;
uniform vec2 light_dir = vec2(-0.6, -0.55); // in quad UV space, towards the light
uniform float band_count = 6.0;
uniform bool ring_enabled = true;
uniform vec3 ring_color : source_color = vec3(0.95, 0.75, 0.62);
uniform float ring_tilt = 0.32;
uniform float opacity : hint_range(0.0, 1.0) = 0.85;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 / 0.62; // planet radius = 0.62 of half quad, rest is ring/atmo
	float r = length(p);
	vec4 outc = vec4(0.0);

	// Ring behind (top half) and in front (bottom half) of the sphere.
	float ring_a = 0.0;
	vec3 ring_rgb = vec3(0.0);
	if (ring_enabled) {
		mat2 rot = mat2(vec2(cos(0.35), sin(0.35)), vec2(-sin(0.35), cos(0.35)));
		vec2 rp = rot * p;
		rp.y /= ring_tilt;
		float rr = length(rp);
		float band = smoothstep(1.25, 1.32, rr) * (1.0 - smoothstep(1.52, 1.62, rr));
		band *= 0.65 + 0.35 * sin(rr * 40.0);
		ring_a = band * 0.6;
		ring_rgb = ring_color;
		bool behind = rp.y < 0.0;
		if (behind || r > 1.0) {
			outc = vec4(ring_rgb, ring_a);
		}
	}

	if (r < 1.0) {
		vec3 n = vec3(p, sqrt(1.0 - r * r));
		vec3 l = normalize(vec3(normalize(light_dir), 0.3));
		float ndl = clamp(dot(n, l), 0.0, 1.0);
		float lat = p.y + 0.15 * vn(p * 3.0);
		float bands = 0.5 + 0.5 * sin(lat * band_count * 3.14159);
		vec3 albedo = mix(color_a, color_b, bands * 0.6);
		vec3 lit = mix(color_shadow, albedo, smoothstep(0.0, 0.85, ndl));
		float fres = pow(clamp(1.0 - n.z, 0.0, 1.0), 3.0);
		lit += atmosphere_color * fres * atmosphere_strength * (0.25 + 0.75 * ndl);
		outc = vec4(lit, 1.0);
		if (ring_enabled) {
			mat2 rot = mat2(vec2(cos(0.35), sin(0.35)), vec2(-sin(0.35), cos(0.35)));
			vec2 rp = rot * p;
			if (rp.y >= 0.0) {
				outc.rgb = mix(outc.rgb, ring_rgb * (0.4 + 0.6 * ndl), ring_a);
			}
		}
	} else {
		// Outer atmosphere glow.
		float glow = exp(-(r - 1.0) * 9.0) * atmosphere_strength * 0.55;
		outc.rgb = mix(outc.rgb, atmosphere_color, glow / max(outc.a + glow, 0.001));
		outc.a = max(outc.a, glow);
	}
	ALBEDO = outc.rgb;
	ALPHA = outc.a * opacity;
}
