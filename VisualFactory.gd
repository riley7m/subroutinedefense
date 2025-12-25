extends Node

## VisualFactory - Runtime Procedural Graphics Generator
## Creates all game visuals using pure GDScript (Polygon2D, Line2D, etc.)

# ============================================================================
# ENEMY VISUALS
# ============================================================================

func create_enemy_visual(enemy_type: String, parent: Node2D) -> Node2D:
	var container = Node2D.new()
	container.name = "VisualContainer"

	match enemy_type:
		"breacher":
			_create_breacher_visual(container)
		"slicer":
			_create_slicer_visual(container)
		"sentinel":
			_create_sentinel_visual(container)
		"null_walker":
			_create_null_walker_visual(container)
		"override":
			_create_override_visual(container)
		"signal_runner":
			_create_signal_runner_visual(container)
		_:
			_create_default_enemy_visual(container)

	parent.add_child(container)
	return container

func _create_breacher_visual(container: Node2D) -> void:
	# Diamond shape - aggressive unit
	var glow = _create_polygon_shape([
		Vector2(-20, 0), Vector2(0, -20), Vector2(20, 0), Vector2(0, 20)
	], Color(1.0, 0.2, 0.2, 0.3))
	glow.scale = Vector2(1.3, 1.3)
	container.add_child(glow)

	var main = _create_polygon_shape([
		Vector2(-15, 0), Vector2(0, -15), Vector2(15, 0), Vector2(0, 15)
	], Color(1.0, 0.3, 0.3))
	container.add_child(main)

	var core = _create_polygon_shape([
		Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0), Vector2(0, 5)
	], Color(1.0, 0.8, 0.8))
	container.add_child(core)

func _create_slicer_visual(container: Node2D) -> void:
	# Triangle - fast attack unit
	var glow = _create_polygon_shape([
		Vector2(0, -22), Vector2(-19, 19), Vector2(19, 19)
	], Color(0.8, 0.8, 0.2, 0.3))
	glow.scale = Vector2(1.3, 1.3)
	container.add_child(glow)

	var main = _create_polygon_shape([
		Vector2(0, -16), Vector2(-14, 14), Vector2(14, 14)
	], Color(0.9, 0.9, 0.3))
	container.add_child(main)

	var core = _create_polygon_shape([
		Vector2(0, -6), Vector2(-5, 5), Vector2(5, 5)
	], Color(1.0, 1.0, 0.8))
	container.add_child(core)

func _create_sentinel_visual(container: Node2D) -> void:
	# Hexagon - tank/defender
	var glow = _create_hexagon(20, Color(0.2, 0.6, 1.0, 0.3))
	glow.scale = Vector2(1.3, 1.3)
	container.add_child(glow)

	var main = _create_hexagon(15, Color(0.3, 0.7, 1.0))
	container.add_child(main)

	var core = _create_hexagon(6, Color(0.8, 0.9, 1.0))
	container.add_child(core)

func _create_null_walker_visual(container: Node2D) -> void:
	# Octagon - special unit
	var glow = _create_regular_polygon(8, 20, Color(0.6, 0.2, 0.8, 0.3))
	glow.scale = Vector2(1.3, 1.3)
	container.add_child(glow)

	var main = _create_regular_polygon(8, 15, Color(0.7, 0.3, 0.9))
	container.add_child(main)

	var core = _create_regular_polygon(8, 6, Color(0.9, 0.7, 1.0))
	container.add_child(core)

func _create_override_visual(container: Node2D) -> void:
	# Square with rotation - hacker unit
	var glow = _create_polygon_shape([
		Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)
	], Color(0.2, 1.0, 0.6, 0.3))
	glow.scale = Vector2(1.3, 1.3)
	glow.rotation_degrees = 45
	container.add_child(glow)

	var main = _create_polygon_shape([
		Vector2(-15, -15), Vector2(15, -15), Vector2(15, 15), Vector2(-15, 15)
	], Color(0.3, 1.0, 0.7))
	main.rotation_degrees = 45
	container.add_child(main)

	var core = _create_polygon_shape([
		Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
	], Color(0.8, 1.0, 0.9))
	core.rotation_degrees = 45
	container.add_child(core)

func _create_signal_runner_visual(container: Node2D) -> void:
	# Elongated diamond - speed unit
	var glow = _create_polygon_shape([
		Vector2(-12, 0), Vector2(0, -24), Vector2(12, 0), Vector2(0, 24)
	], Color(1.0, 0.6, 0.2, 0.3))
	glow.scale = Vector2(1.3, 1.3)
	container.add_child(glow)

	var main = _create_polygon_shape([
		Vector2(-9, 0), Vector2(0, -18), Vector2(9, 0), Vector2(0, 18)
	], Color(1.0, 0.7, 0.3))
	container.add_child(main)

	var core = _create_polygon_shape([
		Vector2(-4, 0), Vector2(0, -8), Vector2(4, 0), Vector2(0, 8)
	], Color(1.0, 0.9, 0.8))
	container.add_child(core)

func _create_default_enemy_visual(container: Node2D) -> void:
	# Circle - generic enemy
	var glow = _create_circle(20, Color(0.8, 0.2, 0.8, 0.3))
	glow.scale = Vector2(1.3, 1.3)
	container.add_child(glow)

	var main = _create_circle(15, Color(0.9, 0.3, 0.9))
	container.add_child(main)

	var core = _create_circle(6, Color(1.0, 0.8, 1.0))
	container.add_child(core)

# ============================================================================
# TOWER VISUALS
# ============================================================================

func create_tower_visual(parent: Node2D) -> Node2D:
	var container = Node2D.new()
	container.name = "TowerVisual"

	# Outer glow ring
	var glow_ring = _create_ring(60, 55, Color(0.2, 0.8, 1.0, 0.2))
	container.add_child(glow_ring)

	# Main rings
	for i in range(4):
		var radius = 50 - (i * 10)
		var inner_radius = radius - 3
		var alpha = 0.6 + (i * 0.1)
		var ring = _create_ring(radius, inner_radius, Color(0.3, 0.9, 1.0, alpha))
		container.add_child(ring)

	# Core
	var core = _create_circle(15, Color(0.8, 1.0, 1.0))
	container.add_child(core)

	# Center dot
	var center = _create_circle(5, Color(1.0, 1.0, 1.0))
	container.add_child(center)

	parent.add_child(container)
	return container

# ============================================================================
# DRONE VISUALS
# ============================================================================

func create_drone_visual(drone_type: String, parent: Node2D) -> Node2D:
	var container = Node2D.new()
	container.name = "DroneVisual"

	var color: Color
	var symbol: String

	match drone_type:
		"flame":
			color = Color(1.0, 0.4, 0.1)  # Orange-red
			symbol = "▲"
		"poison":
			color = Color(0.5, 0.1, 0.8)  # Purple
			symbol = "◆"
		"frost":
			color = Color(0.2, 0.7, 1.0)  # Cyan
			symbol = "❄"
		"shock":
			color = Color(1.0, 1.0, 0.3)  # Yellow
			symbol = "⚡"
		_:
			color = Color(0.7, 0.7, 0.7)
			symbol = "●"

	# Glow layer
	var glow = _create_circle(18, Color(color.r, color.g, color.b, 0.3))
	glow.scale = Vector2(1.2, 1.2)
	container.add_child(glow)

	# Main body
	var body = _create_circle(12, color)
	container.add_child(body)

	# Inner core
	var core = _create_circle(6, Color(color.r * 1.5, color.g * 1.5, color.b * 1.5))
	container.add_child(core)

	# Type indicator (small shape)
	var indicator = _create_type_indicator(drone_type, color)
	container.add_child(indicator)

	parent.add_child(container)
	return container

func _create_type_indicator(drone_type: String, color: Color) -> Node2D:
	var indicator = Node2D.new()

	match drone_type:
		"flame":
			# Small upward triangle
			var tri = _create_polygon_shape([
				Vector2(0, -4), Vector2(-3, 2), Vector2(3, 2)
			], Color(color.r * 1.8, color.g * 1.8, color.b * 1.8))
			indicator.add_child(tri)
		"poison":
			# Small diamond
			var dia = _create_polygon_shape([
				Vector2(0, -4), Vector2(-3, 0), Vector2(0, 4), Vector2(3, 0)
			], Color(color.r * 1.8, color.g * 1.8, color.b * 1.8))
			indicator.add_child(dia)
		"frost":
			# Small plus/cross
			var h_line = Line2D.new()
			h_line.add_point(Vector2(-4, 0))
			h_line.add_point(Vector2(4, 0))
			h_line.width = 2
			h_line.default_color = Color(color.r * 1.8, color.g * 1.8, color.b * 1.8)
			indicator.add_child(h_line)

			var v_line = Line2D.new()
			v_line.add_point(Vector2(0, -4))
			v_line.add_point(Vector2(0, 4))
			v_line.width = 2
			v_line.default_color = Color(color.r * 1.8, color.g * 1.8, color.b * 1.8)
			indicator.add_child(v_line)
		"shock":
			# Small lightning bolt shape
			var bolt = _create_polygon_shape([
				Vector2(0, -5), Vector2(-2, 0), Vector2(0, 1), Vector2(2, 0)
			], Color(color.r * 1.8, color.g * 1.8, color.b * 1.8))
			indicator.add_child(bolt)

	return indicator

# ============================================================================
# PROJECTILE VISUALS
# ============================================================================

func create_projectile_visual(parent: Node2D) -> Node2D:
	var container = Node2D.new()
	container.name = "ProjectileVisual"

	# Glow trail
	var glow = _create_circle(8, Color(0.4, 0.9, 1.0, 0.4))
	glow.scale = Vector2(1.5, 1.0)
	container.add_child(glow)

	# Main body (elongated)
	var body = _create_circle(5, Color(0.6, 1.0, 1.0))
	body.scale = Vector2(1.8, 1.0)
	container.add_child(body)

	# Core
	var core = _create_circle(2, Color(1.0, 1.0, 1.0))
	container.add_child(core)

	parent.add_child(container)
	return container

# ============================================================================
# STATUS EFFECT OVERLAYS
# ============================================================================

func create_status_effect_overlay(effect_type: String, parent: Node2D) -> Node2D:
	var container = Node2D.new()
	container.name = "StatusEffect_" + effect_type

	match effect_type:
		"burn":
			_create_burn_effect(container)
		"poison":
			_create_poison_effect(container)
		"slow":
			_create_slow_effect(container)
		"stun":
			_create_stun_effect(container)
		_:
			_create_default_effect(container)

	parent.add_child(container)
	return container

func _create_burn_effect(container: Node2D) -> void:
	# Pulsing orange/red ring
	var ring = _create_ring(25, 20, Color(1.0, 0.3, 0.1, 0.7))
	container.add_child(ring)

	# Add flame particles
	for i in range(6):
		var flame = ColorRect.new()
		flame.size = Vector2(4, 6)
		flame.color = Color(1.0, 0.5, 0.0, 0.8)
		var angle = (i / 6.0) * TAU
		flame.position = Vector2(cos(angle), sin(angle)) * 20
		container.add_child(flame)

		# Animate flames upward
		var tween = flame.create_tween()
		tween.set_loops()
		tween.tween_property(flame, "position:y", flame.position.y - 10, 0.5)
		tween.tween_property(flame, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func():
			flame.position.y += 10
			flame.modulate.a = 0.8
		)

	# Pulse ring
	var ring_tween = container.create_tween()
	ring_tween.set_loops()
	ring_tween.tween_property(ring, "scale", Vector2(1.15, 1.15), 0.4)
	ring_tween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.4)

func _create_poison_effect(container: Node2D) -> void:
	# Purple pulsing ring
	var ring = _create_ring(25, 20, Color(0.6, 0.1, 0.9, 0.7))
	container.add_child(ring)

	# Add bubbling poison particles
	for i in range(8):
		var bubble = _create_circle(3, Color(0.5, 0.0, 0.8, 0.6))
		var angle = (i / 8.0) * TAU
		bubble.position = Vector2(cos(angle), sin(angle)) * 15
		container.add_child(bubble)

		# Float upward and fade
		var tween = bubble.create_tween()
		tween.set_loops()
		var delay = i * 0.1
		tween.tween_interval(delay)
		tween.tween_property(bubble, "position:y", bubble.position.y - 15, 0.8)
		tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.8)
		tween.tween_callback(func():
			bubble.position.y += 15
			bubble.modulate.a = 0.6
		)

	# Pulse ring
	var ring_tween = container.create_tween()
	ring_tween.set_loops()
	ring_tween.tween_property(ring, "scale", Vector2(1.2, 1.2), 0.6)
	ring_tween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.6)

func _create_slow_effect(container: Node2D) -> void:
	# Ice blue rings
	var ring1 = _create_ring(30, 25, Color(0.2, 0.6, 1.0, 0.5))
	var ring2 = _create_ring(22, 18, Color(0.4, 0.8, 1.0, 0.6))
	container.add_child(ring1)
	container.add_child(ring2)

	# Add frost particles
	for i in range(12):
		var frost = _create_polygon_shape(
			PackedVector2Array([Vector2(-2, -3), Vector2(2, -3), Vector2(0, 3)]),
			Color(0.6, 0.9, 1.0, 0.7)
		)
		var angle = (i / 12.0) * TAU
		frost.position = Vector2(cos(angle), sin(angle)) * 22
		frost.rotation = angle
		container.add_child(frost)

		# Rotate slowly
		var tween = frost.create_tween()
		tween.set_loops()
		tween.tween_property(frost, "rotation", frost.rotation + TAU, 3.0)

	# Pulse rings
	var tween1 = container.create_tween()
	tween1.set_loops()
	tween1.tween_property(ring1, "scale", Vector2(1.1, 1.1), 0.8)
	tween1.tween_property(ring1, "scale", Vector2(1.0, 1.0), 0.8)

	var tween2 = container.create_tween()
	tween2.set_loops()
	tween2.tween_property(ring2, "scale", Vector2(0.9, 0.9), 0.6)
	tween2.tween_property(ring2, "scale", Vector2(1.0, 1.0), 0.6)

func _create_stun_effect(container: Node2D) -> void:
	# Yellow/white electric ring
	var ring = _create_ring(25, 20, Color(1.0, 1.0, 0.3, 0.8))
	container.add_child(ring)

	# Add electric sparks
	for i in range(8):
		var spark = ColorRect.new()
		spark.size = Vector2(6, 2)
		spark.color = Color(1.0, 1.0, 0.5, 1.0)
		var angle = (i / 8.0) * TAU
		spark.position = Vector2(cos(angle), sin(angle)) * 25
		spark.rotation = angle
		container.add_child(spark)

		# Flicker effect
		var tween = spark.create_tween()
		tween.set_loops()
		tween.tween_property(spark, "modulate:a", 0.2, 0.1)
		tween.tween_property(spark, "modulate:a", 1.0, 0.1)

	# Fast pulse for electric effect
	var ring_tween = container.create_tween()
	ring_tween.set_loops()
	ring_tween.tween_property(ring, "scale", Vector2(1.3, 1.3), 0.2)
	ring_tween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.2)

func _create_default_effect(container: Node2D) -> void:
	var ring = _create_ring(25, 20, Color(1.0, 1.0, 1.0, 0.5))
	container.add_child(ring)

	var tween = container.create_tween()
	tween.set_loops()
	tween.tween_property(ring, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(ring, "scale", Vector2(1.0, 1.0), 0.5)

func remove_status_effect_overlay(effect_type: String, parent: Node2D) -> void:
	var overlay = parent.get_node_or_null("StatusEffect_" + effect_type)
	if overlay:
		# Kill all running tweens to prevent leaks
		for child in overlay.get_children():
			# Stop tweens on overlay children
			var child_tweens = child.get_tree().get_processed_tweens() if child.get_tree() else []
			for tween in child_tweens:
				if tween.is_valid():
					tween.kill()

		# Stop tweens on the overlay itself
		if overlay.get_tree():
			var overlay_tweens = overlay.get_tree().get_processed_tweens()
			for tween in overlay_tweens:
				if tween.is_valid():
					tween.kill()

		overlay.queue_free()

# ============================================================================
# HELPER FUNCTIONS - PRIMITIVE SHAPES
# ============================================================================

func _create_polygon_shape(points: PackedVector2Array, color: Color) -> Polygon2D:
	var poly = Polygon2D.new()
	poly.polygon = points
	poly.color = color
	return poly

func _create_circle(radius: float, color: Color, segments: int = 32) -> Polygon2D:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = (i * TAU) / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return _create_polygon_shape(points, color)

func _create_ring(outer_radius: float, inner_radius: float, color: Color, segments: int = 32) -> Polygon2D:
	var points = PackedVector2Array()

	# Outer circle
	for i in range(segments):
		var angle = (i * TAU) / segments
		points.append(Vector2(cos(angle), sin(angle)) * outer_radius)

	# Inner circle (reversed)
	for i in range(segments):
		var angle = ((segments - 1 - i) * TAU) / segments
		points.append(Vector2(cos(angle), sin(angle)) * inner_radius)

	return _create_polygon_shape(points, color)

func _create_hexagon(radius: float, color: Color) -> Polygon2D:
	return _create_regular_polygon(6, radius, color)

func _create_regular_polygon(sides: int, radius: float, color: Color) -> Polygon2D:
	var points = PackedVector2Array()
	for i in range(sides):
		var angle = (i * TAU) / sides - (TAU / 4)  # Start at top
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return _create_polygon_shape(points, color)

# ============================================================================
# ANIMATION HELPERS
# ============================================================================

func add_rotation_animation(node: Node2D, speed: float = 1.0) -> void:
	# Continuous rotation
	var tween = node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "rotation_degrees", 360, 2.0 / speed)
	tween.tween_callback(func(): node.rotation_degrees = 0)

func add_pulse_animation(node: Node2D, scale_min: float = 0.9, scale_max: float = 1.1, duration: float = 1.0) -> void:
	var tween = node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "scale", Vector2(scale_max, scale_max), duration / 2)
	tween.tween_property(node, "scale", Vector2(scale_min, scale_min), duration / 2)
