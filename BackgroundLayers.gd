extends Node2D

## BackgroundLayers - Creates parallax background with depth and environmental details

func _ready() -> void:
	z_index = -200  # Render behind everything

	# Layer 1: Far background - slow moving stars
	_create_starfield(0.1, 50, Vector2(0.5, 0.5))

	# Layer 2: Medium depth - larger glowing nodes
	_create_network_nodes(0.3, 15, Vector2(1.0, 1.0))

	# Layer 3: Near background - floating data fragments
	_create_data_fragments(0.5, 20, Vector2(1.5, 1.5))

	print("✅ Background layers created")

# ============================================================================
# STARFIELD LAYER
# ============================================================================

func _create_starfield(parallax_speed: float, star_count: int, scale_range: Vector2) -> void:
	var layer = Node2D.new()
	layer.name = "StarfieldLayer"
	add_child(layer)

	for i in range(star_count):
		var star = _create_star()
		star.position = Vector2(
			randf() * 1920,
			randf() * 1080
		)
		star.scale = Vector2.ONE * randf_range(scale_range.x, scale_range.y)
		layer.add_child(star)

	# Gentle drift animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(layer, "position:x", -50, 20.0 / parallax_speed)
	tween.tween_property(layer, "position:x", 50, 20.0 / parallax_speed)

func _create_star() -> Node2D:
	var container = Node2D.new()

	# Outer glow
	var glow = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(4):
		var angle = (i * TAU / 4)
		points.append(Vector2(cos(angle), sin(angle)) * 3)
	glow.polygon = points
	glow.color = Color(0.4, 0.9, 1.0, 0.3)
	container.add_child(glow)

	# Core
	var core = Polygon2D.new()
	points = PackedVector2Array()
	for i in range(4):
		var angle = (i * TAU / 4)
		points.append(Vector2(cos(angle), sin(angle)) * 1.5)
	core.polygon = points
	core.color = Color(0.6, 1.0, 1.0, 0.8)
	container.add_child(core)

	# Pulse animation
	var tween = container.create_tween()
	tween.set_loops()
	var pulse_duration = randf_range(2.0, 4.0)
	tween.tween_property(glow, "scale", Vector2.ONE * 1.2, pulse_duration)
	tween.tween_property(glow, "scale", Vector2.ONE, pulse_duration)

	return container

# ============================================================================
# NETWORK NODES LAYER
# ============================================================================

func _create_network_nodes(parallax_speed: float, node_count: int, scale_range: Vector2) -> void:
	var layer = Node2D.new()
	layer.name = "NetworkNodesLayer"
	add_child(layer)

	var nodes: Array = []

	for i in range(node_count):
		var node = _create_network_node()
		node.position = Vector2(
			randf() * 1920,
			randf() * 1080
		)
		node.scale = Vector2.ONE * randf_range(scale_range.x, scale_range.y)
		layer.add_child(node)
		nodes.append(node)

	# Draw connecting lines between nearby nodes
	_connect_nearby_nodes(layer, nodes, 300.0)

	# Drift animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(layer, "position:y", -30, 15.0 / parallax_speed)
	tween.tween_property(layer, "position:y", 30, 15.0 / parallax_speed)

func _create_network_node() -> Node2D:
	var container = Node2D.new()

	# Hexagon shape
	var hex = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(6):
		var angle = (i * TAU / 6) - (TAU / 4)
		points.append(Vector2(cos(angle), sin(angle)) * 8)
	hex.polygon = points
	hex.color = Color(0.2, 0.7, 0.9, 0.4)
	container.add_child(hex)

	# Inner core
	var core = Polygon2D.new()
	points = PackedVector2Array()
	for i in range(32):
		var angle = (i * TAU / 32)
		points.append(Vector2(cos(angle), sin(angle)) * 3)
	core.polygon = points
	core.color = Color(0.4, 0.9, 1.0, 0.6)
	container.add_child(core)

	# Rotation animation
	var tween = container.create_tween()
	tween.set_loops()
	tween.tween_property(container, "rotation_degrees", 360, randf_range(10.0, 20.0))
	tween.tween_callback(func(): container.rotation_degrees = 0)

	return container

func _connect_nearby_nodes(layer: Node2D, nodes: Array, max_distance: float) -> void:
	for i in range(nodes.size()):
		for j in range(i + 1, nodes.size()):
			var node_a = nodes[i]
			var node_b = nodes[j]
			var distance = node_a.position.distance_to(node_b.position)

			if distance < max_distance:
				var line = Line2D.new()
				line.add_point(node_a.position)
				line.add_point(node_b.position)
				line.width = 1
				line.default_color = Color(0.2, 0.6, 0.8, 0.2)
				layer.add_child(line)
				layer.move_child(line, 0)  # Lines render behind nodes

# ============================================================================
# DATA FRAGMENTS LAYER
# ============================================================================

func _create_data_fragments(parallax_speed: float, fragment_count: int, scale_range: Vector2) -> void:
	var layer = Node2D.new()
	layer.name = "DataFragmentsLayer"
	add_child(layer)

	for i in range(fragment_count):
		var fragment = _create_data_fragment()
		fragment.position = Vector2(
			randf() * 1920,
			randf() * 1080
		)
		fragment.scale = Vector2.ONE * randf_range(scale_range.x, scale_range.y)
		layer.add_child(fragment)

	# Faster drift
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(layer, "position:x", 80, 10.0 / parallax_speed)
	tween.tween_property(layer, "position:y", -40, 10.0 / parallax_speed)
	tween.tween_property(layer, "position:x", -80, 10.0 / parallax_speed)
	tween.tween_property(layer, "position:y", 40, 10.0 / parallax_speed)

func _create_data_fragment() -> Node2D:
	var container = Node2D.new()

	# Random shape: triangle, square, or line
	var shape_type = randi() % 3

	match shape_type:
		0:  # Triangle
			var tri = Polygon2D.new()
			tri.polygon = PackedVector2Array([
				Vector2(0, -6),
				Vector2(-5, 4),
				Vector2(5, 4)
			])
			tri.color = Color(0.3, 0.8, 1.0, 0.3)
			container.add_child(tri)
		1:  # Square
			var square = Polygon2D.new()
			square.polygon = PackedVector2Array([
				Vector2(-4, -4),
				Vector2(4, -4),
				Vector2(4, 4),
				Vector2(-4, 4)
			])
			square.color = Color(0.2, 0.7, 0.9, 0.3)
			container.add_child(square)
		2:  # Line
			var line = Line2D.new()
			line.add_point(Vector2(-8, 0))
			line.add_point(Vector2(8, 0))
			line.width = 2
			line.default_color = Color(0.4, 0.9, 1.0, 0.4)
			container.add_child(line)

	# Rotation
	var tween = container.create_tween()
	tween.set_loops()
	var rotation_speed = randf_range(5.0, 15.0)
	if randf() > 0.5:
		tween.tween_property(container, "rotation_degrees", 360, rotation_speed)
	else:
		tween.tween_property(container, "rotation_degrees", -360, rotation_speed)
	tween.tween_callback(func(): container.rotation_degrees = 0)

	# Fade pulse
	var fade_tween = container.create_tween()
	fade_tween.set_loops()
	fade_tween.tween_property(container, "modulate:a", 0.5, randf_range(1.0, 3.0))
	fade_tween.tween_property(container, "modulate:a", 1.0, randf_range(1.0, 3.0))

	return container
