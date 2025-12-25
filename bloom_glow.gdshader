shader_type canvas_item;

// Advanced Bloom and Glow Post-Processing

uniform float bloom_intensity : hint_range(0.0, 3.0) = 1.2;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.6;
uniform float bloom_radius : hint_range(1.0, 10.0) = 3.0;
uniform vec3 bloom_tint : source_color = vec3(0.2, 0.8, 1.0);

// Simple box blur for bloom effect
vec4 blur_sample(sampler2D tex, vec2 uv, vec2 pixel_size, float radius) {
	vec4 color = vec4(0.0);
	float total = 0.0;

	for (float x = -radius; x <= radius; x += 1.0) {
		for (float y = -radius; y <= radius; y += 1.0) {
			vec2 offset = vec2(x, y) * pixel_size;
			color += texture(tex, uv + offset);
			total += 1.0;
		}
	}

	return color / total;
}

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));

	// Sample original color
	vec4 original = texture(TEXTURE, UV);

	// Extract bright areas
	float brightness = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec4 bright_color = vec4(0.0);

	if (brightness > bloom_threshold) {
		bright_color = original * ((brightness - bloom_threshold) / (1.0 - bloom_threshold));
	}

	// Blur bright areas
	vec4 bloom = blur_sample(TEXTURE, UV, pixel_size, bloom_radius);
	bloom *= bloom_intensity;
	bloom.rgb *= bloom_tint;

	// Combine
	vec4 final_color = original + bloom * bright_color.a;

	COLOR = final_color;
}
