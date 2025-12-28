extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "shock"
	super._ready()

# Shock Drone: Targets the closest enemy/enemies to the tower and applies a stun effect

func pick_target() -> Node2D:
	# Get closest enemies (used for single-target version)
	var closest_enemies = _get_closest_enemies(1)
	return closest_enemies[0] if closest_enemies.size() > 0 else null

func _get_closest_enemies(max_count: int) -> Array:
	# Find the tower
	var tower = get_tree().get_first_node_in_group("Tower")
	if not tower:
		tower = get_node_or_null("../tower")
	if not tower:
		print("⚡ Shock Drone: No tower found.")
		return []

	# Get all enemies sorted by distance to tower (ascending)
	var enemies = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("global_position") and not "global_position" in enemy:
			continue
		if not is_in_range(enemy):
			continue
		var distance = tower.global_position.distance_to(enemy.global_position)
		enemies.append({"enemy": enemy, "distance": distance})

	# Sort by distance (ascending)
	enemies.sort_custom(func(a, b): return a["distance"] < b["distance"])

	# Return top N closest
	var result = []
	for i in range(min(max_count, enemies.size())):
		result.append(enemies[i]["enemy"])
	return result

func fire_at(target: Node2D) -> void:
	# Get DroneUpgradeManager bonuses
	var max_targets = DroneUpgradeManager.get_shock_max_targets() if DroneUpgradeManager else 1
	var duration_bonus = DroneUpgradeManager.get_shock_duration_bonus() if DroneUpgradeManager else 0.0

	# Target multiple enemies if chain is upgraded
	var targets = _get_closest_enemies(max_targets)
	for t in targets:
		if t.has_method("apply_stun"):
			t.apply_stun(drone_level, duration_bonus)
			#print("⚡ Drone Shock: Applied stun to", t.name)
		else:
			print("⚠️ Drone Shock: Target missing apply_stun()")
