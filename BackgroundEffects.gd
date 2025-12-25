extends CanvasLayer

## Programmatically adds background grid, CRT, bloom, and advanced shader effects

var distortion_enabled: bool = false
var distortion_center: Vector2 = Vector2(0.5, 0.5)
var distortion_time: float = 0.0

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

	# Create bloom/glow effect overlay
	var bloom_rect = ColorRect.new()
	bloom_rect.name = "BloomEffect"
	bloom_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bloom_rect.z_index = 101
	bloom_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bloom_material = ShaderMaterial.new()
	var bloom_shader = load("res://bloom_glow.gdshader")
	bloom_material.shader = bloom_shader

	bloom_material.set_shader_parameter("bloom_intensity", 1.2)
	bloom_material.set_shader_parameter("bloom_threshold", 0.6)
	bloom_material.set_shader_parameter("bloom_radius", 3.0)
	bloom_material.set_shader_parameter("bloom_tint", Vector3(0.2, 0.8, 1.0))

	bloom_rect.material = bloom_material
	add_child(bloom_rect)

	# Create chromatic aberration effect (subtle, always on)
	var chroma_rect = ColorRect.new()
	chroma_rect.name = "ChromaticAberration"
	chroma_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	chroma_rect.z_index = 102
	chroma_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var chroma_material = ShaderMaterial.new()
	var chroma_shader = load("res://chromatic_aberration.gdshader")
	chroma_material.shader = chroma_shader

	chroma_material.set_shader_parameter("aberration_amount", 0.002)  # Subtle
	chroma_material.set_shader_parameter("aberration_center", Vector2(0.5, 0.5))
	chroma_material.set_shader_parameter("distortion_strength", 0.3)

	chroma_rect.material = chroma_material
	add_child(chroma_rect)

	print("✅ Advanced shader effects loaded: Grid, CRT, Bloom, ChromaticAberration")

# ============================================================================
# IMPACT DISTORTION EFFECT
# ============================================================================

func trigger_impact_distortion(screen_position: Vector2) -> void:
	# Create temporary distortion wave effect
	var distort_rect = ColorRect.new()
	distort_rect.name = "ImpactDistortion"
	distort_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	distort_rect.z_index = 103
	distort_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var distort_material = ShaderMaterial.new()
	var distort_shader = load("res://distortion_wave.gdshader")
	distort_material.shader = distort_shader

	# Convert screen position to UV coordinates
	var uv_pos = screen_position / Vector2(1920, 1080)
	distort_material.set_shader_parameter("wave_center", uv_pos)
	distort_material.set_shader_parameter("wave_strength", 0.03)
	distort_material.set_shader_parameter("wave_radius", 0.3)
	distort_material.set_shader_parameter("wave_thickness", 0.05)
	distort_material.set_shader_parameter("time_offset", 0.0)

	distort_rect.material = distort_material
	add_child(distort_rect)

	# Animate the wave expanding
	var duration = 0.8
	var tween = distort_rect.create_tween()

	# Expand wave radius over time
	for t in range(0, int(duration * 60)):  # 60 fps
		var time_val = t / 60.0
		tween.tween_callback(func():
			if is_instance_valid(distort_rect):
				distort_material.set_shader_parameter("time_offset", time_val)
		).set_delay(time_val)

	# Fade out and cleanup
	tween.tween_property(distort_rect, "modulate:a", 0.0, 0.2).set_delay(duration - 0.2)
	tween.tween_callback(distort_rect.queue_free)
