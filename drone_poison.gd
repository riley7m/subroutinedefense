extends "res://drone_base.gd"

func _ready():
	drone_type = "poison"
	super._ready()

# Pick the enemy with the lowest HP
func pick_target() -> Node2D:
	var best: Node2D = null
	var min_hp = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("get_current_hp"):
			continue  # Enemy must have a get_current_hp() function
		var hp = enemy.get_current_hp()
		if hp < min_hp:
			min_hp = hp
			best = enemy
	return best


func fire_at(target: Node2D) -> void:
	if target.has_method("apply_poison"):
		target.apply_poison(drone_level)
		#print("🟣 Drone Poison: Applied poison to", target.name)
	else:
		print("⚠️ Drone Poison: Target missing apply_poison()")
