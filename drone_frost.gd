extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "frost"
	super._ready()

# Frost Drone: Targets the fastest enemy/enemies and applies a slow effect

func pick_target() -> Node2D:
	# Get fastest enemies (used for single-target version)
	var fastest_enemies = _get_fastest_enemies(1)
	return fastest_enemies[0] if fastest_enemies.size() > 0 else null

func _get_fastest_enemies(max_count: int) -> Array:
	# Get all enemies sorted by speed (descending)
	var enemies = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not "move_speed" in enemy:
			continue
		if not is_in_range(enemy):
			continue
		enemies.append(enemy)

	# Sort by speed (descending)
	enemies.sort_custom(func(a, b): return a.move_speed > b.move_speed)

	# Return top N fastest
	var result = []
	for i in range(min(max_count, enemies.size())):
		result.append(enemies[i])
	return result

func fire_at(target: Node2D) -> void:
	# Get DroneUpgradeManager bonuses
	var max_targets = DroneUpgradeManager.get_frost_max_targets() if DroneUpgradeManager else 1
	var slow_duration = DroneUpgradeManager.get_frost_duration() if DroneUpgradeManager else 2.0

	# Target multiple enemies if AOE is upgraded
	var targets = _get_fastest_enemies(max_targets)
	for t in targets:
		if t.has_method("apply_slow"):
			t.apply_slow(drone_level, slow_duration)
			#print("❄️ Drone Frost: Applied slow to", t.name)
		else:
			print("⚠️ Drone Frost: Target missing apply_slow()")
