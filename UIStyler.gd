extends Node

## UIStyler - Applies cyber-themed styling to UI elements at runtime

const CYBER_CYAN = Color(0.2, 0.8, 1.0)
const CYBER_CYAN_BRIGHT = Color(0.4, 0.9, 1.0)
const CYBER_DARK = Color(0.05, 0.1, 0.15)
const CYBER_MEDIUM = Color(0.1, 0.2, 0.3)
const CYBER_ACCENT = Color(0.0, 0.6, 0.8)

# ============================================================================
# PANEL STYLING
# ============================================================================

func style_panel(panel: Panel) -> void:
	# Create custom StyleBox for cyber panels
	var style = StyleBoxFlat.new()

	# Background
	style.bg_color = Color(CYBER_DARK.r, CYBER_DARK.g, CYBER_DARK.b, 0.9)

	# Border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = CYBER_CYAN

	# Corner radius
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	# Inner glow effect
	style.shadow_color = Color(CYBER_CYAN.r, CYBER_CYAN.g, CYBER_CYAN.b, 0.3)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 0)

	panel.add_theme_stylebox_override("panel", style)

func style_panel_dark(panel: Panel) -> void:
	# Darker variant for nested panels
	var style = StyleBoxFlat.new()

	style.bg_color = Color(0.02, 0.05, 0.08, 0.95)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = CYBER_ACCENT

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	panel.add_theme_stylebox_override("panel", style)

# ============================================================================
# BUTTON STYLING
# ============================================================================

func style_button(button: Button) -> void:
	# Normal state
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = CYBER_MEDIUM
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = CYBER_CYAN
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4

	# Hover state
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(CYBER_MEDIUM.r * 1.3, CYBER_MEDIUM.g * 1.3, CYBER_MEDIUM.b * 1.3)
	style_hover.border_color = CYBER_CYAN_BRIGHT
	style_hover.shadow_color = Color(CYBER_CYAN.r, CYBER_CYAN.g, CYBER_CYAN.b, 0.5)
	style_hover.shadow_size = 5

	# Pressed state
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = CYBER_ACCENT
	style_pressed.border_color = CYBER_CYAN_BRIGHT

	# Disabled state
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.1, 0.1, 0.1)
	style_disabled.border_color = Color(0.3, 0.3, 0.3)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)

	# Text color
	button.add_theme_color_override("font_color", CYBER_CYAN_BRIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

func style_button_accent(button: Button) -> void:
	# Highlighted button variant (for important actions)
	style_button(button)

	var style_normal = button.get_theme_stylebox("normal").duplicate()
	style_normal.bg_color = Color(CYBER_ACCENT.r * 0.8, CYBER_ACCENT.g * 0.8, CYBER_ACCENT.b * 0.8)
	style_normal.border_color = CYBER_CYAN_BRIGHT

	button.add_theme_stylebox_override("normal", style_normal)

# ============================================================================
# LABEL STYLING
# ============================================================================

func style_label(label: Label, size: int = -1) -> void:
	label.add_theme_color_override("font_color", CYBER_CYAN_BRIGHT)

	# Add subtle glow outline
	label.add_theme_color_override("font_outline_color", Color(CYBER_CYAN.r, CYBER_CYAN.g, CYBER_CYAN.b, 0.5))
	label.add_theme_constant_override("outline_size", 2)

	if size > 0:
		label.add_theme_font_size_override("font_size", size)

func style_label_header(label: Label) -> void:
	style_label(label, 24)
	label.add_theme_color_override("font_color", Color.WHITE)

func style_label_title(label: Label) -> void:
	style_label(label, 18)

# ============================================================================
# PROGRESS BAR STYLING
# ============================================================================

func style_progress_bar(progress_bar: ProgressBar, fill_color: Color = CYBER_CYAN) -> void:
	# Background
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = CYBER_DARK
	style_bg.border_width_left = 1
	style_bg.border_width_top = 1
	style_bg.border_width_right = 1
	style_bg.border_width_bottom = 1
	style_bg.border_color = CYBER_MEDIUM
	style_bg.corner_radius_top_left = 3
	style_bg.corner_radius_top_right = 3
	style_bg.corner_radius_bottom_left = 3
	style_bg.corner_radius_bottom_right = 3

	# Fill
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = fill_color
	style_fill.corner_radius_top_left = 3
	style_fill.corner_radius_top_right = 3
	style_fill.corner_radius_bottom_left = 3
	style_fill.corner_radius_bottom_right = 3

	# Glow
	style_fill.shadow_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.5)
	style_fill.shadow_size = 3

	progress_bar.add_theme_stylebox_override("background", style_bg)
	progress_bar.add_theme_stylebox_override("fill", style_fill)

# ============================================================================
# CONTAINER STYLING
# ============================================================================

func style_vbox_container(vbox: VBoxContainer) -> void:
	vbox.add_theme_constant_override("separation", 8)

func style_hbox_container(hbox: HBoxContainer) -> void:
	hbox.add_theme_constant_override("separation", 8)

# ============================================================================
# AUTO-STYLE HELPERS
# ============================================================================

func auto_style_children(node: Node) -> void:
	# Recursively style all UI elements in a tree
	for child in node.get_children():
		if child is Panel:
			style_panel(child)
		elif child is Button:
			style_button(child)
		elif child is Label:
			style_label(child)
		elif child is ProgressBar:
			style_progress_bar(child)
		elif child is VBoxContainer:
			style_vbox_container(child)
		elif child is HBoxContainer:
			style_hbox_container(child)

		# Recurse
		if child.get_child_count() > 0:
			auto_style_children(child)

func apply_theme_to_node(node: Node) -> void:
	# Convenience function to style a node and all its children
	auto_style_children(node)
	print("✅ Applied cyber theme to:", node.name)
