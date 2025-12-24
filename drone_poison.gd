extends "res://drone_base.gd"

func _ready() -> void:
	drone_type = "poison"
	super._ready()

# Uses default pick_lowest_hp_enemy() from drone_base.gd

func fire_at(target: Node2D) -> void:
	if target.has_method("apply_poison"):
		target.apply_poison(drone_level)
		#print("🟣 Drone Poison: Applied poison to", target.name)
	else:
		print("⚠️ Drone Poison: Target missing apply_poison()")
