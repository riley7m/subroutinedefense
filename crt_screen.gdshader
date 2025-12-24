shader_type canvas_item;

// CRT Screen Effect with Scanlines and Vignette

uniform float scanline_count : hint_range(100.0, 1000.0) = 300.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float distortion_amount : hint_range(0.0, 0.1) = 0.02;
uniform vec3 tint_color : source_color = vec3(0.2, 0.8, 1.0);
uniform float tint_strength : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	// Get UV coordinates
	vec2 uv = UV;

	// Barrel distortion (CRT curve)
	vec2 center = uv - 0.5;
	float dist = length(center);
	uv = uv + center * (dist * distortion_amount);

	// Sample the texture
	vec4 color = texture(TEXTURE, uv);

	// Scanlines
	float scanline = sin(uv.y * scanline_count) * 0.5 + 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);
	color.rgb *= scanline;

	// Vignette
	float vignette = 1.0 - dist * vignette_strength;
	color.rgb *= vignette;

	// Cyan tint
	color.rgb = mix(color.rgb, color.rgb * tint_color, tint_strength);

	COLOR = color;
}
