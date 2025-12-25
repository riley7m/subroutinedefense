extends Node

## AdvancedVisuals - AAA-Level Visual Polish
## Adds dynamic lighting, trails, damage numbers, and holographic effects

# ============================================================================
# DYNAMIC LIGHTING SYSTEM
# ============================================================================

func add_dynamic_light(parent: Node2D, color: Color, energy: float = 1.0, radius: float = 100.0) -> PointLight2D:
	var light = PointLight2D.new()
	light.enabled = true
	light.color = color
	light.energy = energy
	light.texture_scale = radius / 100.0
	light.blend_mode = Light2D.BLEND_MODE_ADD

	# Create procedural gradient texture for soft falloff
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1))
	gradient.add_point(0.5, Color(1, 1, 1, 0.5))
	gradient.add_point(1.0, Color(1, 1, 1, 0))

	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.width = 128
	gradient_texture.height = 128

	light.texture = gradient_texture

	parent.add_child(light)
	return light

func add_pulsing_light(parent: Node2D, color: Color, base_energy: float = 1.0, pulse_speed: float = 2.0) -> PointLight2D:
	var light = add_dynamic_light(parent, color, base_energy, 120.0)

	# Pulse animation
	var tween = light.create_tween()
	tween.set_loops()
	tween.tween_property(light, "energy", base_energy * 1.5, pulse_speed / 2.0)
	tween.tween_property(light, "energy", base_energy * 0.7, pulse_speed / 2.0)

	# Auto-cleanup tween when node is removed
	light.tree_exiting.connect(func():
		if is_instance_valid(tween):
			tween.kill()
	)

	return light

# ============================================================================
# PROJECTILE TRAIL SYSTEM
# ============================================================================

func create_projectile_trail(parent: Node2D, color: Color = Color(0.6, 1.0, 1.0)) -> Line2D:
	var trail = Line2D.new()
	trail.name = "ProjectileTrail"
	trail.width = 3.0
	trail.default_color = color
	trail.z_index = -1  # Behind projectile

	# Gradient for fade effect
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.3, Color(color.r, color.g, color.b, 0.5))
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 1.0))

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	trail.gradient = gradient_texture

	# Glow effect
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND

	parent.add_child(trail)
	return trail

func update_trail(trail: Line2D, position: Vector2, max_points: int = 15) -> void:
	if not is_instance_valid(trail):
		return

	# Add new point at front
	trail.add_point(position, 0)

	# Remove old points
	if trail.get_point_count() > max_points:
		trail.remove_point(trail.get_point_count() - 1)

# ============================================================================
# FLOATING DAMAGE NUMBERS
# ============================================================================

func create_damage_number(damage: int, position: Vector2, is_crit: bool, parent: Node) -> void:
	var label = Label.new()
	label.text = str(damage)
	label.position = position
	label.z_index = 100

	# Styling
	if is_crit:
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # Gold for crits
		label.add_theme_color_override("font_outline_color", Color(1.0, 0.4, 0.0, 0.8))
		label.add_theme_constant_override("outline_size", 6)
		label.scale = Vector2(1.2, 1.2)
	else:
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		label.add_theme_color_override("font_outline_color", Color(0.2, 0.8, 1.0, 0.6))
		label.add_theme_constant_override("outline_size", 4)

	parent.add_child(label)

	# Physics-based float animation
	var tween = label.create_tween()
	tween.set_parallel(true)

	# Float up with deceleration
	var float_distance = 40.0 if is_crit else 30.0
	var float_time = 1.2 if is_crit else 0.8
	tween.tween_property(label, "position:y", position.y - float_distance, float_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Slight horizontal drift
	var drift = randf_range(-15.0, 15.0)
	tween.tween_property(label, "position:x", position.x + drift, float_time).set_ease(Tween.EASE_OUT)

	# Scale punch
	if is_crit:
		tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.15)

	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(float_time - 0.4)

	# Cleanup
	await tween.finished
	if is_instance_valid(label):
		label.queue_free()

# ============================================================================
# CHARGING/TELEGRAPH EFFECTS
# ============================================================================

func create_charge_indicator(parent: Node2D, duration: float, color: Color = Color(0.2, 0.8, 1.0)) -> Node2D:
	var container = Node2D.new()
	container.name = "ChargeIndicator"

	# Outer growing ring
	var outer_ring = Line2D.new()
	outer_ring.width = 3.0
	outer_ring.default_color = color
	container.add_child(outer_ring)

	# Create circle points
	for i in range(33):
		var angle = (i * TAU) / 32
		var point = Vector2(cos(angle), sin(angle)) * 20.0
		outer_ring.add_point(point)

	# Inner pulsing core
	var core = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(16):
		var angle = (i * TAU) / 16
		points.append(Vector2(cos(angle), sin(angle)) * 5)
	core.polygon = points
	core.color = Color(color.r, color.g, color.b, 0.6)
	container.add_child(core)

	parent.add_child(container)

	# Animate charge up
	var tween = container.create_tween()
	tween.set_parallel(true)

	# Ring expands
	tween.tween_property(outer_ring, "scale", Vector2(2.0, 2.0), duration).from(Vector2(0.5, 0.5))
	tween.tween_property(outer_ring, "modulate:a", 0.0, duration).from(1.0)

	# Core pulses
	tween.tween_property(core, "scale", Vector2(1.5, 1.5), duration / 4.0)
	tween.tween_property(core, "scale", Vector2(1.0, 1.0), duration / 4.0).set_delay(duration / 4.0)
	tween.tween_property(core, "scale", Vector2(1.5, 1.5), duration / 4.0).set_delay(duration / 2.0)
	tween.tween_property(core, "scale", Vector2(0.5, 0.5), duration / 4.0).set_delay(duration * 0.75)

	# Rotation
	tween.tween_property(container, "rotation_degrees", 360, duration)

	# Cleanup
	await tween.finished
	if is_instance_valid(container):
		container.queue_free()

	return container

# ============================================================================
# STATUS EFFECT ICONS (Orbiting)
# ============================================================================

func create_status_icon(effect_type: String, parent: Node2D) -> Node2D:
	var container = Node2D.new()
	container.name = "StatusIcon_" + effect_type

	# Icon background
	var bg = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(6):
		var angle = (i * TAU) / 6
		points.append(Vector2(cos(angle), sin(angle)) * 10)
	bg.polygon = points
	bg.color = Color(0.1, 0.1, 0.1, 0.8)
	container.add_child(bg)

	# Icon symbol
	var symbol_color: Color
	match effect_type:
		"burn":
			symbol_color = Color(1.0, 0.3, 0.1)
			_add_burn_symbol(container)
		"poison":
			symbol_color = Color(0.6, 0.1, 0.9)
			_add_poison_symbol(container)
		"slow":
			symbol_color = Color(0.2, 0.7, 1.0)
			_add_slow_symbol(container)
		"stun":
			symbol_color = Color(1.0, 1.0, 0.3)
			_add_stun_symbol(container)

	# Border
	var border = Polygon2D.new()
	border.polygon = points
	border.color = Color(symbol_color.r, symbol_color.g, symbol_color.b, 0.0)
	var outline = border.duplicate()
	outline.polygon = points
	outline.color = symbol_color
	# Note: Godot 4 uses different outline method
	container.add_child(outline)

	parent.add_child(container)

	# Orbit animation
	var radius = 35.0
	var orbit_speed = 3.0
	var tween = container.create_tween()
	tween.set_loops()

	# Circular orbit
	for i in range(36):
		var angle = (i * TAU) / 36
		var target_pos = Vector2(cos(angle), sin(angle)) * radius
		tween.tween_property(container, "position", target_pos, orbit_speed / 36.0)

	# Auto-cleanup tween when node is removed
	container.tree_exiting.connect(func():
		if is_instance_valid(tween):
			tween.kill()
	)

	return container

func _add_burn_symbol(parent: Node2D) -> void:
	# Flame triangle
	var flame = Polygon2D.new()
	flame.polygon = PackedVector2Array([
		Vector2(0, -6),
		Vector2(-4, 4),
		Vector2(4, 4)
	])
	flame.color = Color(1.0, 0.5, 0.1)
	parent.add_child(flame)

func _add_poison_symbol(parent: Node2D) -> void:
	# Droplet shape
	var drop = Polygon2D.new()
	drop.polygon = PackedVector2Array([
		Vector2(0, -6),
		Vector2(-3, 0),
		Vector2(-3, 3),
		Vector2(0, 6),
		Vector2(3, 3),
		Vector2(3, 0)
	])
	drop.color = Color(0.7, 0.2, 1.0)
	parent.add_child(drop)

func _add_slow_symbol(parent: Node2D) -> void:
	# Snowflake
	var line1 = Line2D.new()
	line1.add_point(Vector2(0, -6))
	line1.add_point(Vector2(0, 6))
	line1.width = 2
	line1.default_color = Color(0.4, 0.9, 1.0)
	parent.add_child(line1)

	var line2 = Line2D.new()
	line2.add_point(Vector2(-5, -3))
	line2.add_point(Vector2(5, 3))
	line2.width = 2
	line2.default_color = Color(0.4, 0.9, 1.0)
	parent.add_child(line2)

	var line3 = Line2D.new()
	line3.add_point(Vector2(-5, 3))
	line3.add_point(Vector2(5, -3))
	line3.width = 2
	line3.default_color = Color(0.4, 0.9, 1.0)
	parent.add_child(line3)

func _add_stun_symbol(parent: Node2D) -> void:
	# Lightning bolt
	var bolt = Polygon2D.new()
	bolt.polygon = PackedVector2Array([
		Vector2(0, -7),
		Vector2(-3, 0),
		Vector2(0, 1),
		Vector2(3, 0),
		Vector2(0, 7),
		Vector2(2, 2),
		Vector2(-2, 2)
	])
	bolt.color = Color(1.0, 1.0, 0.4)
	parent.add_child(bolt)

func remove_status_icon(effect_type: String, parent: Node2D) -> void:
	var icon = parent.get_node_or_null("StatusIcon_" + effect_type)
	if icon:
		icon.queue_free()
