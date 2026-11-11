shader_type spatial;
render_mode unshaded, depth_draw_never;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
// Inner edges: how different two surface directions must be to count as an edge
// Lower = more highlights. Higher = only sharp corners
uniform float normal_threshold = 0.2;
// How bright the highlight on convex corners is. 0 = no highlight
uniform float line_highlight = 0.4;
// Two pixels closer than this (in meters) count as the same surface
// Lower = less highlight leaking onto the floor next to objects
uniform float same_surface_depth = 0.2;

vec3 get_normal(vec2 uv) {
	return texture(normal_tex, uv).rgb * 2.0 - 1.0;
}

// Outer edges: how much deeper a neighbor pixel must be to draw a dark line
// Lower = more lines. Higher = only big edges
uniform float edge_threshold = 0.25;
// How dark the outline is. 1 = pure black, 0 = no outline
uniform float line_darkness = 0.9;

float get_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).x;
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
	vec4 view = inv_proj * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 texel = 1.0 / VIEWPORT_SIZE;
	float depth = get_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 normal = get_normal(SCREEN_UV);

	vec2 offsets[4] = vec2[](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0));

	float diff = 0.0;
	float normal_diff = 0.0;
	for (int i = 0; i < 4; i++) {
		vec2 uv = SCREEN_UV + offsets[i] * texel;
		float neighbor = get_depth(uv, INV_PROJECTION_MATRIX);
		diff += clamp(neighbor - depth, 0.0, 1.0);


		float same_surface = step(abs(neighbor - depth), same_surface_depth);
		vec3 n = get_normal(uv);
		float convex = step(0.0, dot(normal - n, vec3(1.0)));
		normal_diff += (1.0 - dot(normal, n)) * same_surface * convex;
	}

	float edge = step(edge_threshold, diff);
	float normal_edge = step(normal_threshold, normal_diff);

	vec3 color = texture(screen_tex, SCREEN_UV).rgb;
	color += normal_edge * (1.0 - edge) * line_highlight;
	ALBEDO = color * (1.0 - edge * line_darkness);
}