shader_type canvas_item;

// Chromatic Aberration Effect (RGB split on impacts)

uniform float aberration_amount : hint_range(0.0, 0.05) = 0.005;
uniform vec2 aberration_center = vec2(0.5, 0.5);
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 direction = UV - aberration_center;
	float distance = length(direction);
	vec2 dir_normalized = normalize(direction);

	// Apply distortion based on distance from center
	float distortion = distortion_strength * distance;

	// Sample each color channel at different offsets
	float r = texture(TEXTURE, UV + dir_normalized * aberration_amount * distortion).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, UV - dir_normalized * aberration_amount * distortion).b;
	float a = texture(TEXTURE, UV).a;

	COLOR = vec4(r, g, b, a);
}
