extends Node

## ScreenEffects - Screen shake, flashes, and transitions

var camera: Camera2D = null
var original_offset: Vector2 = Vector2.ZERO
var shake_amount: float = 0.0
var shake_decay: float = 0.0

func _ready() -> void:
	set_process(false)  # Disable processing until needed
	_find_camera()  # Cache camera reference on startup

# ============================================================================
# SCREEN SHAKE
# ============================================================================

func screen_shake(intensity: float, duration: float = 0.3) -> void:
	shake_amount = intensity
	shake_decay = intensity / duration

	if camera == null:
		_find_camera()

	if camera:
		original_offset = camera.offset
		_start_shake_process()

func _find_camera() -> void:
	# Try to find Camera2D in scene
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		for node in tree.root.get_children():
			camera = _find_camera_recursive(node)
			if camera:
				break

func _find_camera_recursive(node: Node) -> Camera2D:
	if node is Camera2D:
		return node
	for child in node.get_children():
		var result = _find_camera_recursive(child)
		if result:
			return result
	return null

func _start_shake_process() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if shake_amount > 0 and camera:
		shake_amount -= shake_decay * delta
		shake_amount = max(shake_amount, 0.0)

		# Random offset
		var shake_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)

		camera.offset = original_offset + shake_offset

		if shake_amount <= 0:
			camera.offset = original_offset
			set_process(false)

# ============================================================================
# SCREEN FLASH
# ============================================================================

func screen_flash(color: Color, duration: float = 0.2, parent: Node = null) -> void:
	if parent == null:
		parent = _get_main_scene()

	if parent == null:
		return

	var flash_rect = ColorRect.new()
	flash_rect.name = "ScreenFlash"
	flash_rect.color = color
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Full screen
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.z_index = 1000  # On top of everything

	parent.add_child(flash_rect)

	# Fade out
	var tween = flash_rect.create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func():
		if is_instance_valid(flash_rect):
			flash_rect.queue_free()
	)

func _get_main_scene() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		return tree.current_scene
	return null

# ============================================================================
# WAVE TRANSITION
# ============================================================================

func wave_transition(wave_number: int, parent: Node = null) -> void:
	if parent == null:
		parent = _get_main_scene()

	if parent == null:
		return

	# Safety: Remove existing transitions to prevent overlap
	var existing_transition = parent.get_node_or_null("WaveTransition")
	if existing_transition:
		existing_transition.queue_free()

	var existing_portal = parent.get_node_or_null("PortalWarp")
	if existing_portal:
		existing_portal.queue_free()

	# Portal warp effect
	_create_portal_effect(parent)

	# Create transition overlay
	var overlay = Control.new()
	overlay.name = "WaveTransition"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 500

	# Background fade
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.1, 0.15, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	# Wave text
	var label = Label.new()
	label.text = "WAVE %d" % wave_number
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 0.0))
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(label)

	parent.add_child(overlay)

	# Animation sequence
	var tween = overlay.create_tween()

	# Delay for portal effect
	tween.tween_interval(0.4)

	# Fade in background
	tween.tween_property(bg, "color:a", 0.7, 0.2)
	# Fade in text
	tween.parallel().tween_property(label, "theme_override_colors/font_color:a", 1.0, 0.2)
	tween.parallel().tween_property(label, "theme_override_colors/font_outline_color:a", 0.8, 0.2)
	# Scale text
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).from(Vector2(0.5, 0.5))

	# Hold
	tween.tween_interval(0.6)

	# Fade out
	tween.tween_property(bg, "color:a", 0.0, 0.3)
	tween.parallel().tween_property(label, "theme_override_colors/font_color:a", 0.0, 0.3)
	tween.parallel().tween_property(label, "theme_override_colors/font_outline_color:a", 0.0, 0.3)

	# Cleanup
	tween.tween_callback(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	)

func _create_portal_effect(parent: Node) -> void:
	# Create portal overlay with shader
	var portal_rect = ColorRect.new()
	portal_rect.name = "PortalWarp"
	portal_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	portal_rect.z_index = 499
	portal_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portal_material = ShaderMaterial.new()
	var portal_shader = load("res://portal_warp.gdshader")
	portal_material.shader = portal_shader
	portal_material.set_shader_parameter("progress", 0.0)
	portal_material.set_shader_parameter("center", Vector2(0.5, 0.5))
	portal_material.set_shader_parameter("warp_strength", 0.15)

	portal_rect.material = portal_material

	parent.add_child(portal_rect)

	# Animate portal expansion
	var tween = portal_rect.create_tween()
	tween.tween_method(func(val): portal_material.set_shader_parameter("progress", val), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if is_instance_valid(portal_rect):
			portal_rect.queue_free()
	)

# ============================================================================
# BOSS WAVE TRANSITION (Enhanced)
# ============================================================================

func boss_wave_transition(wave_number: int, parent: Node = null) -> void:
	if parent == null:
		parent = _get_main_scene()

	if parent == null:
		return

	# Safety: Remove existing boss transitions to prevent overlap
	var existing_transition = parent.get_node_or_null("BossWaveTransition")
	if existing_transition:
		existing_transition.queue_free()

	var existing_portal = parent.get_node_or_null("PortalWarp")
	if existing_portal:
		existing_portal.queue_free()

	# Screen shake for dramatic effect
	screen_shake(15.0, 0.5)

	# Create transition overlay
	var overlay = Control.new()
	overlay.name = "BossWaveTransition"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 500

	# Background fade
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.0, 0.05, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)

	# Warning text
	var warning_label = Label.new()
	warning_label.text = "⚠ WARNING ⚠"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	warning_label.add_theme_font_size_override("font_size", 32)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 0.0))
	warning_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	warning_label.offset_top = 100
	overlay.add_child(warning_label)

	# Boss wave text
	var label = Label.new()
	label.text = "BOSS WAVE %d" % wave_number
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.7, 0.0))
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 0.5, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(label)

	parent.add_child(overlay)

	# Animation sequence
	var tween = overlay.create_tween()

	# Fade in background
	tween.tween_property(bg, "color:a", 0.85, 0.3)

	# Warning blink
	tween.parallel().tween_property(warning_label, "theme_override_colors/font_color:a", 1.0, 0.1)
	tween.tween_property(warning_label, "theme_override_colors/font_color:a", 0.0, 0.1)
	tween.tween_property(warning_label, "theme_override_colors/font_color:a", 1.0, 0.1)

	# Boss text dramatic entrance
	tween.parallel().tween_property(label, "theme_override_colors/font_color:a", 1.0, 0.3)
	tween.parallel().tween_property(label, "theme_override_colors/font_outline_color:a", 1.0, 0.3)
	tween.parallel().tween_property(label, "scale", Vector2(1.3, 1.3), 0.3).from(Vector2(0.3, 0.3))

	# Hold
	tween.tween_interval(1.0)

	# Pulse warning
	tween.parallel().tween_property(warning_label, "theme_override_colors/font_color:a", 0.0, 0.2)

	# Fade out
	tween.tween_property(bg, "color:a", 0.0, 0.4)
	tween.parallel().tween_property(label, "theme_override_colors/font_color:a", 0.0, 0.4)
	tween.parallel().tween_property(label, "theme_override_colors/font_outline_color:a", 0.0, 0.4)

	# Cleanup
	tween.tween_callback(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	)

# ============================================================================
# DEATH SCREEN TRANSITION
# ============================================================================

func death_transition(parent: Node = null) -> void:
	if parent == null:
		parent = _get_main_scene()

	if parent == null:
		return

	# Heavy screen shake
	screen_shake(25.0, 0.8)

	# Red flash
	screen_flash(Color(1.0, 0.0, 0.0, 0.5), 0.5, parent)
