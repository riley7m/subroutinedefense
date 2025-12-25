shader_type canvas_item;

// Impact Distortion Wave Effect

uniform float wave_strength : hint_range(0.0, 0.1) = 0.02;
uniform vec2 wave_center = vec2(0.5, 0.5);
uniform float wave_radius : hint_range(0.0, 2.0) = 0.3;
uniform float wave_thickness : hint_range(0.01, 0.2) = 0.05;
uniform float time_offset = 0.0;

void fragment() {
	vec2 direction = UV - wave_center;
	float distance = length(direction);

	// Create expanding ring
	float wave = abs(distance - (time_offset * 0.5));
	wave = smoothstep(wave_thickness, 0.0, wave);

	// Distort UVs at wave position
	vec2 distortion = normalize(direction) * wave * wave_strength;
	vec4 color = texture(TEXTURE, UV + distortion);

	// Add glow to wave
	color.rgb += vec3(0.2, 0.8, 1.0) * wave * 0.5;

	COLOR = color;
}
