shader_type canvas_item;

// Animated Cyber Grid Background

uniform vec3 grid_color : source_color = vec3(0.2, 0.8, 1.0);
uniform float grid_thickness : hint_range(0.01, 0.1) = 0.02;
uniform float grid_spacing : hint_range(10.0, 100.0) = 50.0;
uniform float grid_alpha : hint_range(0.0, 1.0) = 0.3;
uniform float scan_speed : hint_range(0.0, 2.0) = 0.5;
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 pos = UV * vec2(1920.0, 1080.0); // Adjust to your viewport size

	// Animated scan line
	float scan_line = sin((UV.y + TIME * scan_speed) * 3.14159 * 4.0) * 0.5 + 0.5;
	scan_line = pow(scan_line, 3.0) * 0.3;

	// Grid lines
	vec2 grid_pos = mod(pos, grid_spacing);
	float grid_x = smoothstep(grid_thickness * grid_spacing, 0.0, grid_pos.x);
	float grid_y = smoothstep(grid_thickness * grid_spacing, 0.0, grid_pos.y);
	float grid = max(grid_x, grid_y);

	// Glow effect
	float glow = grid * glow_intensity;

	// Combine
	vec3 final_color = grid_color * (grid + glow + scan_line);
	float final_alpha = grid_alpha * (grid + scan_line * 0.5);

	COLOR = vec4(final_color, final_alpha);
}
