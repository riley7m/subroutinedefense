extends "res://drone_base.gd"

func _ready():
	drone_type = "frost"
	super._ready()

# Frost Drone: Targets the enemy with the highest speed and applies a slow effect

func pick_target() -> Node2D:
	var slowest_enemy: Node2D = null
	var max_speed = -INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not "move_speed" in enemy:
			continue
		var speed = enemy.move_speed
		if speed > max_speed:
			max_speed = speed
			slowest_enemy = enemy
	return slowest_enemy


func fire_at(target: Node2D) -> void:
	if target.has_method("apply_slow"):
		target.apply_slow(drone_level)
		#print("❄️ Drone Frost: Applied slow to", target.name)
	else:
		print("⚠️ Drone Frost: Target missing apply_slow()")
