extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "shock"
	super._ready()

# Shock Drone: Targets the closest enemy to the tower and applies a stun effect

func pick_target() -> Node2D:
	var closest_enemy: Node2D = null
	var min_distance = INF

	# Find the tower in the scene tree (more flexible approach)
	var tower = get_tree().get_first_node_in_group("Tower")
	if not tower:
		# Fallback: try to find node named "tower" in current scene
		tower = get_node_or_null("../tower")

	if not tower:
		print("⚡ Shock Drone: No tower found.")
		return null

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("global_position") and not "global_position" in enemy:
			continue
		if not is_in_range(enemy):  # Only target enemies in horizontal range
			continue
		var distance = tower.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_enemy = enemy

	return closest_enemy

func fire_at(target: Node2D) -> void:
	if target.has_method("apply_stun"):
		target.apply_stun(drone_level)
		#print("⚡ Drone Shock: Applied stun to", target.name)
	else:
		print("⚠️ Drone Shock: Target missing apply_stun()")
