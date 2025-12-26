extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "flame"
	super._ready()

# Uses default pick_lowest_hp_enemy() from drone_base.gd

func fire_at(target: Node2D) -> void:
	# Flame drone uses % of enemy's max HP as base damage (not tower's projectile damage)
	# Base: 5% of max HP per application
	var base_damage_percent = 0.05
	var max_hp = target.base_hp if "base_hp" in target else 100
	if "wave_number" in target:
		# Use exponential HP scaling and tier multiplier to match enemy.gd
		var hp_scaling = target.HP_SCALING_BASE if "HP_SCALING_BASE" in target else 1.02
		var tier_mult = TierManager.get_enemy_multiplier()
		max_hp = int(target.base_hp * tier_mult * pow(hp_scaling, target.wave_number))

	var base_damage = max_hp * base_damage_percent
	var crit_multiplier = 1.0  # No crit for drones

	if target.has_method("apply_burn"):
		# Apply burn with level scaling (enemy.gd handles power/duration scaling internally)
		target.apply_burn(drone_level, base_damage, crit_multiplier)
		#print("🔥 Drone Flame: Applied burn to", target.name)
	else:
		print("⚠️ Drone Flame: Target missing apply_burn()")
