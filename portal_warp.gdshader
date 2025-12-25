shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform float warp_strength = 0.3;

void fragment() {
	vec2 uv = UV;
	vec2 to_center = uv - center;
	float dist = length(to_center);

	// Create expanding circle effect
	float circle = smoothstep(progress, progress + 0.1, dist);

	// Warp/distortion effect
	vec2 warp_offset = normalize(to_center) * warp_strength * (1.0 - progress) * (1.0 - dist);
	vec2 warped_uv = uv + warp_offset * sin(dist * 20.0 - progress * 10.0);

	// Sample texture with warp
	vec4 tex = texture(TEXTURE, warped_uv);

	// Blend with cyan portal color
	vec4 portal_color = vec4(0.2, 0.8, 1.0, 1.0);
	vec4 final_color = mix(tex, portal_color, (1.0 - circle) * 0.5);

	// Add glow at edge
	float edge_glow = smoothstep(0.05, 0.0, abs(dist - progress));
	final_color.rgb += vec3(0.3, 0.9, 1.0) * edge_glow * 2.0;

	COLOR = final_color;
	COLOR.a = circle;
}
