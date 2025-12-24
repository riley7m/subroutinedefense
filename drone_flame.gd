extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "flame"
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

# Apply burn effect (placeholder logic)
func fire_at(target: Node2D) -> void:
	var base_damage = UpgradeManager.get_projectile_damage()
	var crit_multiplier = 1.0  # (replace with actual crit logic later if needed)

	if target.has_method("apply_burn"):
		target.apply_burn(drone_level, base_damage, crit_multiplier)
		#print("🔥 Drone Flame: Applied burn to", target.name)
	else:
		print("⚠️ Drone Flame: Target missing apply_burn()")
