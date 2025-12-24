extends Area2D

@export var speed: float = 400
var target: Node2D = null

func _ready():
	if not body_entered.is_connected(Callable(self, "_on_body_entered")):
		body_entered.connect(Callable(self, "_on_body_entered"))

	# Create visual representation
	VisualFactory.create_projectile_visual(self)

func _process(delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		rotation = direction.angle()
	else:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == target and body.has_method("take_damage"):
		var base_dmg = UpgradeManager.get_projectile_damage()
		var crit_roll = randi() % 100
		var is_crit = crit_roll < UpgradeManager.get_crit_chance()
		var dealt_dmg = base_dmg

		if is_crit:
			var crit_multiplier = UpgradeManager.get_crit_damage_multiplier()
			dealt_dmg = int(base_dmg * crit_multiplier)
			#print("💥 CRITICAL HIT! Damage:", dealt_dmg)
			#print("🎯 Hit for", dealt_dmg)

		# --- Record damage dealt before applying to enemy (for run stats)
		RunStats.damage_dealt += dealt_dmg

		body.take_damage(dealt_dmg)
		queue_free()
