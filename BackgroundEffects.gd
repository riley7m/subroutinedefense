extends CanvasLayer

## Programmatically adds background grid and CRT effects to the scene

func _ready() -> void:
	# Create background grid (renders behind everything)
	var grid_rect = ColorRect.new()
	grid_rect.name = "CyberGridBackground"
	grid_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid_rect.z_index = -100

	# Create shader material for grid
	var grid_material = ShaderMaterial.new()
	var grid_shader = load("res://cyber_grid.gdshader")
	grid_material.shader = grid_shader

	# Set shader parameters
	grid_material.set_shader_parameter("grid_color", Vector3(0.2, 0.8, 1.0))
	grid_material.set_shader_parameter("grid_thickness", 0.02)
	grid_material.set_shader_parameter("grid_spacing", 50.0)
	grid_material.set_shader_parameter("grid_alpha", 0.3)
	grid_material.set_shader_parameter("scan_speed", 0.5)
	grid_material.set_shader_parameter("glow_intensity", 1.0)

	grid_rect.material = grid_material
	add_child(grid_rect)
	move_child(grid_rect, 0)  # Ensure it's the first child (renders first/behind)

	# Create CRT screen effect overlay (renders on top)
	var crt_rect = ColorRect.new()
	crt_rect.name = "CRTScreenEffect"
	crt_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt_rect.z_index = 100
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse clicks

	# Create shader material for CRT
	var crt_material = ShaderMaterial.new()
	var crt_shader = load("res://crt_screen.gdshader")
	crt_material.shader = crt_shader

	# Set shader parameters
	crt_material.set_shader_parameter("scanline_count", 300.0)
	crt_material.set_shader_parameter("scanline_intensity", 0.15)
	crt_material.set_shader_parameter("vignette_strength", 0.3)
	crt_material.set_shader_parameter("distortion_amount", 0.02)
	crt_material.set_shader_parameter("tint_color", Vector3(0.2, 0.8, 1.0))
	crt_material.set_shader_parameter("tint_strength", 0.1)

	crt_rect.material = crt_material
	add_child(crt_rect)

	print("✅ Background grid and CRT effects loaded")
