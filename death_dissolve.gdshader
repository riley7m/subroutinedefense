shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform sampler2D noise_texture;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Sample noise for dissolve pattern
	float noise = texture(noise_texture, UV + vec2(TIME * 0.1, 0.0)).r;

	// Create dissolve threshold
	float threshold = dissolve_amount * 1.2 - 0.1;
	float dissolve = smoothstep(threshold, threshold + 0.1, noise);

	// Edge glow calculation
	float edge = smoothstep(threshold - edge_width, threshold, noise);
	edge -= dissolve;

	// Apply edge color glow
	vec3 final_color = tex.rgb;
	final_color = mix(final_color, edge_color.rgb * 2.0, edge); // HDR emissive edge

	// Output
	COLOR = vec4(final_color, tex.a * dissolve);
}
