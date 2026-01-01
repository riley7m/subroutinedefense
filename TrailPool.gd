extends Node

## TrailPool - Object pool for Line2D trail effects
## Prevents GC pressure from creating/destroying trails every frame

var _available_trails: Array[Line2D] = []
var _active_trails: Array[Line2D] = []
const INITIAL_POOL_SIZE: int = 100  # Pre-allocate 100 trails (50 projectiles + 50 enemies)

func _ready() -> void:
	# Pre-allocate trail objects
	for i in range(INITIAL_POOL_SIZE):
		var trail = _create_trail()
		trail.visible = false
		_available_trails.append(trail)

func _create_trail() -> Line2D:
	"""Create a new trail with default settings"""
	var trail = Line2D.new()
	trail.name = "PooledTrail"
	trail.width = 3.0
	trail.z_index = -1
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	return trail

func get_trail(parent: Node2D, color: Color, width: float = 3.0) -> Line2D:
	"""Get a trail from pool or create new one if pool is empty"""
	var trail: Line2D

	if _available_trails.size() > 0:
		# Reuse from pool
		trail = _available_trails.pop_back()
	else:
		# Pool exhausted, create new trail
		trail = _create_trail()
		print("⚠️ TrailPool exhausted, creating new trail (total active: %d)" % _active_trails.size())

	# Configure trail
	trail.default_color = color
	trail.width = width
	trail.clear_points()
	trail.visible = true

	# Setup gradient for fade effect
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(color.r, color.g, color.b, 0.0))
	gradient.add_point(0.3, Color(color.r, color.g, color.b, 0.5))
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 1.0))

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	trail.gradient = gradient_texture

	# Add to parent and track
	parent.add_child(trail)
	_active_trails.append(trail)

	return trail

func recycle_trail(trail: Line2D) -> void:
	"""Return a trail to the pool for reuse"""
	if not is_instance_valid(trail):
		return

	# Remove from active tracking
	var idx = _active_trails.find(trail)
	if idx != -1:
		_active_trails.remove_at(idx)

	# Reset state
	trail.clear_points()
	trail.visible = false

	# Remove from parent
	if trail.get_parent():
		trail.get_parent().remove_child(trail)

	# Return to pool
	_available_trails.append(trail)

func update_trail(trail: Line2D, position: Vector2, max_points: int = 15) -> void:
	"""Update trail position (same as AdvancedVisuals.update_trail)"""
	if not is_instance_valid(trail):
		return

	# Add new point at front
	trail.add_point(position, 0)

	# Remove old points
	if trail.get_point_count() > max_points:
		trail.remove_point(trail.get_point_count() - 1)

func get_pool_stats() -> Dictionary:
	"""Debug info about pool usage"""
	return {
		"available": _available_trails.size(),
		"active": _active_trails.size(),
		"total": _available_trails.size() + _active_trails.size()
	}
