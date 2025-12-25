extends CanvasLayer

## HolographicUI - Scanning overlays, targeting reticles, and data readouts

var scan_lines: Array = []
var target_reticles: Array = []

func _ready() -> void:
	# Create corner brackets
	_create_corner_brackets()

	# Create scanning line that moves across screen
	_create_scan_line()

	# Add data stream overlay
	_create_data_stream()

	print("✅ Holographic UI overlays active")

# ============================================================================
# CORNER BRACKETS
# ============================================================================

func _create_corner_brackets() -> void:
	var bracket_size = 60
	var bracket_thickness = 3
	var margin = 20

	# Top-left
	_draw_bracket(Vector2(margin, margin), bracket_size, bracket_thickness, 0)

	# Top-right
	_draw_bracket(Vector2(1920 - margin - bracket_size, margin), bracket_size, bracket_thickness, 90)

	# Bottom-right
	_draw_bracket(Vector2(1920 - margin - bracket_size, 1080 - margin - bracket_size), bracket_size, bracket_thickness, 180)

	# Bottom-left
	_draw_bracket(Vector2(margin, 1080 - margin - bracket_size), bracket_size, bracket_thickness, 270)

func _draw_bracket(pos: Vector2, size: int, thickness: int, rotation: float) -> void:
	var bracket = Control.new()
	bracket.position = pos
	bracket.rotation_degrees = rotation

	# Horizontal line
	var h_line = ColorRect.new()
	h_line.color = Color(0.2, 0.8, 1.0, 0.6)
	h_line.size = Vector2(size, thickness)
	bracket.add_child(h_line)

	# Vertical line
	var v_line = ColorRect.new()
	v_line.color = Color(0.2, 0.8, 1.0, 0.6)
	v_line.size = Vector2(thickness, size)
	bracket.add_child(v_line)

	add_child(bracket)

	# Pulse animation
	var tween = bracket.create_tween()
	tween.set_loops()
	tween.tween_property(bracket, "modulate:a", 0.4, 2.0)
	tween.tween_property(bracket, "modulate:a", 0.8, 2.0)

# ============================================================================
# SCANNING LINE
# ============================================================================

func _create_scan_line() -> void:
	var scan_line = ColorRect.new()
	scan_line.name = "ScanLine"
	scan_line.color = Color(0.2, 0.8, 1.0, 0.15)
	scan_line.size = Vector2(1920, 2)
	scan_line.position = Vector2(0, 0)
	scan_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scan_line)

	# Vertical scan animation
	var tween = scan_line.create_tween()
	tween.set_loops()
	tween.tween_property(scan_line, "position:y", 1080, 4.0)
	tween.tween_property(scan_line, "position:y", 0, 4.0)

# ============================================================================
# DATA STREAM OVERLAY
# ============================================================================

func _create_data_stream() -> void:
	var stream_container = VBoxContainer.new()
	stream_container.name = "DataStream"
	stream_container.position = Vector2(20, 200)
	stream_container.modulate = Color(0.2, 0.8, 1.0, 0.3)
	stream_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stream_container)

	# Add data lines
	var data_lines = [
		"SYSTEM: ONLINE",
		"DEFENSE: ACTIVE",
		"UPLINK: STABLE",
		"THREAT LEVEL: ???"
	]

	for line in data_lines:
		var label = Label.new()
		label.text = line
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0, 0.5))
		stream_container.add_child(label)

	# Flicker animation
	var tween = stream_container.create_tween()
	tween.set_loops()
	tween.tween_property(stream_container, "modulate:a", 0.2, 0.5)
	tween.tween_property(stream_container, "modulate:a", 0.5, 0.3)
	tween.tween_property(stream_container, "modulate:a", 0.3, 0.2)

# ============================================================================
# TARGET RETICLE (for enemy highlighting)
# ============================================================================

func create_target_reticle(target_position: Vector2) -> Control:
	var reticle = Control.new()
	reticle.name = "TargetReticle"
	reticle.position = target_position - Vector2(30, 30)  # Center on target

	# Outer ring
	var outer = _create_reticle_ring(30, Color(1.0, 0.3, 0.3, 0.7))
	reticle.add_child(outer)

	# Inner crosshair
	var h_line = ColorRect.new()
	h_line.color = Color(1.0, 0.3, 0.3, 0.8)
	h_line.size = Vector2(40, 2)
	h_line.position = Vector2(10, 29)
	reticle.add_child(h_line)

	var v_line = ColorRect.new()
	v_line.color = Color(1.0, 0.3, 0.3, 0.8)
	v_line.size = Vector2(2, 40)
	v_line.position = Vector2(29, 10)
	reticle.add_child(v_line)

	add_child(reticle)

	# Pulse animation
	var tween = reticle.create_tween()
	tween.set_loops()
	tween.tween_property(outer, "rotation_degrees", 360, 2.0)

	# Fade in
	reticle.modulate.a = 0.0
	var fade_tween = reticle.create_tween()
	fade_tween.tween_property(reticle, "modulate:a", 1.0, 0.3)

	return reticle

func _create_reticle_ring(radius: float, color: Color) -> Control:
	var ring = Control.new()

	# Draw 4 arc segments
	for i in range(4):
		var arc = ColorRect.new()
		arc.color = color
		arc.size = Vector2(radius * 0.4, 2)
		arc.pivot_offset = Vector2(0, 0)

		var angle = i * 90
		arc.rotation_degrees = angle
		arc.position = Vector2(
			radius + cos(deg_to_rad(angle)) * radius * 0.7,
			radius + sin(deg_to_rad(angle)) * radius * 0.7
		)

		ring.add_child(arc)

	return ring
