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
		max_hp += int(target.wave_number * (target.HP_PER_WAVE if "HP_PER_WAVE" in target else 0))

	var base_damage = max_hp * base_damage_percent
	var crit_multiplier = 1.0  # No crit for drones

	if target.has_method("apply_burn"):
		target.apply_burn(drone_level, base_damage, crit_multiplier)
		#print("🔥 Drone Flame: Applied burn to", target.name)
	else:
		print("⚠️ Drone Flame: Target missing apply_burn()")
