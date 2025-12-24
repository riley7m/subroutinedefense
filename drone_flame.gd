extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "flame"
	super._ready()

# Uses default pick_lowest_hp_enemy() from drone_base.gd

func fire_at(target: Node2D) -> void:
	var base_damage = UpgradeManager.get_projectile_damage()
	var crit_multiplier = 1.0  # (replace with actual crit logic later if needed)

	if target.has_method("apply_burn"):
		target.apply_burn(drone_level, base_damage, crit_multiplier)
		#print("🔥 Drone Flame: Applied burn to", target.name)
	else:
		print("⚠️ Drone Flame: Target missing apply_burn()")
