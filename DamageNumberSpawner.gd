extends Node

## Static helper for spawning floating damage numbers

static func spawn_damage_number(damage: int, world_position: Vector2, parent: Node, is_critical: bool = false) -> void:
	var damage_label = preload("res://DamageNumber.gd").new()
	damage_label.global_position = world_position
	damage_label.setup(damage, is_critical)

	# Add to parent (should be the main scene)
	parent.add_child(damage_label)
