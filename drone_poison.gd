extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "poison"
	super._ready()

# Uses default pick_lowest_hp_enemy() from drone_base.gd

func fire_at(target: Node2D) -> void:
	# Get DroneUpgradeManager bonuses
	var poison_duration = DroneUpgradeManager.get_poison_duration() if DroneUpgradeManager else 4.0
	var max_stacks = DroneUpgradeManager.get_poison_max_stacks() if DroneUpgradeManager else 1

	if target.has_method("apply_poison"):
		target.apply_poison(drone_level, poison_duration, max_stacks)
		#print("🟣 Drone Poison: Applied poison to", target.name)
	else:
		print("⚠️ Drone Poison: Target missing apply_poison()")
