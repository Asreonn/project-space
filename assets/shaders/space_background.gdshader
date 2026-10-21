shader_type spatial;
// Space background for the near top-down camera (single pass, unshaded).
// Draw on a large quad that follows the camera (see scripts/vfx/space_background.gd).
// Parallax: each layer samples world space offset by camera_xz * layer factor,
// so the far layers drift slower than the play plane.
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

// Palette (starter preset: purple-peach-orange). All values are LDR on purpose:
// only the brightest star cores go slightly above 1.0 for a soft glow.
uniform vec3 color_void : source_color = vec3(0.045, 0.035, 0.10);
uniform vec3 color_deep : source_color = vec3(0.20, 0.12, 0.36);
uniform vec3 color_mid : source_color = vec3(0.62, 0.30, 0.55);
uniform vec3 color_warm : source_color = vec3(0.98, 0.62, 0.45);
uniform vec3 color_hot : source_color = vec3(1.0, 0.78, 0.50);
uniform vec3 star_tint : source_color = vec3(1.0, 0.93, 0.86);

uniform float nebula_density : hint_range(0.0, 2.0) = 1.0;
uniform float nebula_scale = 0.018;       // 1 / world meters
uniform float nebula_warp : hint_range(0.0, 3.0) = 1.2;
uniform float nebula_brightness : hint_range(0.0, 2.0) = 0.85;
uniform float star_density : hint_range(0.0, 1.0) = 0.22;
uniform float star_brightness : hint_range(0.0, 4.0) = 1.35;
uniform float twinkle_speed = 1.3;
// Cost knobs: fewer octaves / no dust lanes for low-end GPUs.
uniform int fbm_octaves : hint_range(2, 5) = 4;
uniform bool dust_lanes = true;

// Parallax factors: 0 = locked to the world, 1 = locked to the screen.
uniform float parallax_nebula_far = 0.92;
uniform float parallax_nebula_near = 0.80;
uniform float parallax_stars_far = 0.95;
uniform float parallax_stars_near = 0.86;

// Set by space_background.gd every frame.
uniform vec2 camera_xz = vec2(0.0);
uniform float drift_speed = 0.15;          // slow ambient drift (m/s)

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < fbm_octaves; i++) {
		v += a * vnoise(p);
		p = r * p * 2.03 + 17.1;
		a *= 0.5;
	}
	return v;
}

// One cell-based star layer: at most one star per cell, round soft core.
float star_layer(vec2 p, float cell, float density, float t) {
	vec2 g = p / cell;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash12(id);
	if (h > density) {
		return 0.0;
	}
	vec2 o = (hash22(id) - 0.5) * 0.7;
	float d = length(f - o);
	float size = mix(0.035, 0.11, hash12(id + 7.3) * hash12(id + 7.3) * hash12(id + 7.3));
	float core = (1.0 - smoothstep(0.0, size, d));
	float halo = (1.0 - smoothstep(0.0, size * 3.5, d)) * 0.25;
	float tw = 0.7 + 0.3 * sin(t * twinkle_speed * (0.6 + h * 2.0) + h * 40.0);
	return (core + halo) * tw * mix(0.5, 1.0, hash12(id + 3.1));
}

void fragment() {
	vec2 drift = vec2(TIME * drift_speed, TIME * drift_speed * 0.35);
	vec2 p_far = world_xz - camera_xz * parallax_nebula_far + drift * 0.5;
	vec2 p_near = world_xz - camera_xz * parallax_nebula_near + drift;

	// Nebula: domain-warped fbm, two depths.
	vec2 q = p_far * nebula_scale;
	vec2 w = vec2(fbm(q + vec2(0.0, 1.7)), fbm(q + vec2(5.2, 1.3)));
	float n_far = fbm(q + nebula_warp * w);
	float n_near = fbm(p_near * nebula_scale * 1.9 + w * 0.8 + 3.7);

	float body = smoothstep(0.32, 0.85, n_far) * nebula_density;
	float wisp = smoothstep(0.5, 0.9, n_near) * nebula_density;
	vec3 col = color_void;
	col = mix(col, color_deep, clamp(body * 1.2, 0.0, 1.0));
	col = mix(col, color_mid, clamp(body * body * 1.1, 0.0, 1.0) * 0.8);
	col = mix(col, color_warm, clamp(wisp * (0.35 + body) * 1.2, 0.0, 1.0) * 0.7);
	float hot = clamp(wisp * body, 0.0, 1.0);
	col += color_hot * hot * hot * hot * 0.35;
	col = mix(color_void, col, nebula_brightness);

	// Dust lanes darken the nebula a little for depth.
	if (dust_lanes) {
		float lanes = smoothstep(0.55, 0.75, fbm(p_near * nebula_scale * 4.0 + 11.0));
		col *= 1.0 - lanes * 0.25 * body;
	}

	// Stars: far small dense, near sparse brighter.
	vec2 s_far = world_xz - camera_xz * parallax_stars_far;
	vec2 s_near = world_xz - camera_xz * parallax_stars_near;
	float stars = star_layer(s_far, 0.9, star_density, TIME) * 0.6;
	stars += star_layer(s_near, 2.3, star_density * 0.7, TIME + 3.0);
	// Fewer stars inside dense nebula, keeps the clouds soft.
	stars *= 1.0 - body * 0.45;
	col += star_tint * stars * star_brightness;

	ALBEDO = col;
}
