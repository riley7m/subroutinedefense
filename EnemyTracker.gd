extends Node

## EnemyTracker - Maintains active enemy list for efficient targeting
## Eliminates O(n) get_nodes_in_group() calls and array allocations

var _active_enemies: Array[Node2D] = []

func register_enemy(enemy: Node2D) -> void:
	"""Called when an enemy spawns"""
	if not enemy in _active_enemies:
		_active_enemies.append(enemy)

func unregister_enemy(enemy: Node2D) -> void:
	"""Called when an enemy dies or is recycled"""
	var idx = _active_enemies.find(enemy)
	if idx != -1:
		_active_enemies.remove_at(idx)

func get_active_enemies() -> Array[Node2D]:
	"""Returns the active enemy list without allocating new array"""
	# Clean up any invalid references (safety check)
	_active_enemies = _active_enemies.filter(func(e): return is_instance_valid(e))
	return _active_enemies

func get_enemy_count() -> int:
	"""Fast enemy count without iteration"""
	return _active_enemies.size()

func clear() -> void:
	"""Clear all tracked enemies (called on run reset)"""
	_active_enemies.clear()

func get_closest_to_position(pos: Vector2) -> Node2D:
	"""Find closest enemy to a position (optimized for single tower)"""
	var closest: Node2D = null
	var closest_dist := INF

	for enemy in _active_enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = pos.distance_squared_to(enemy.global_position)  # Use squared distance (faster)
		if dist < closest_dist:
			closest = enemy
			closest_dist = dist

	return closest

func get_nearest_to_position(pos: Vector2, count: int) -> Array[Node2D]:
	"""Get N nearest enemies to a position (for multi-target)"""
	# Create array of enemies with distances
	var enemies_with_dist: Array = []
	for enemy in _active_enemies:
		if not is_instance_valid(enemy):
			continue
		var dist_sq = pos.distance_squared_to(enemy.global_position)
		enemies_with_dist.append({"enemy": enemy, "dist": dist_sq})

	# Sort by distance (ascending)
	enemies_with_dist.sort_custom(func(a, b): return a.dist < b.dist)

	# Extract just the enemies
	var result: Array[Node2D] = []
	for i in range(min(count, enemies_with_dist.size())):
		result.append(enemies_with_dist[i].enemy)

	return result
