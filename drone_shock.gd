extends "res://drone_base.gd"

func _ready():
	drone_type = "shock"
	super._ready()

# Shock Drone: Targets the closest enemy to the tower and applies a stun effect

func pick_target() -> Node2D:
	var closest_enemy: Node2D = null
	var min_distance = INF

	# Find the main tower in the scene
	var tower = get_node("/root/MainHUD/tower")
	if not tower:
		print("⚡ Shock Drone: No tower found.")
		return null

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("global_position") and not "global_position" in enemy:
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
