extends Area2D

@export var speed: float = 400
var target: Node2D = null

# Trail system
var trail: Line2D
const MAX_TRAIL_POINTS: int = 15
const TRAIL_SPACING: float = 5.0
var last_trail_pos: Vector2

func _ready() -> void:
	if not body_entered.is_connected(Callable(self, "_on_body_entered")):
		var err = body_entered.connect(Callable(self, "_on_body_entered"))
		if err != OK:
			push_error("Failed to connect projectile body_entered signal: " + str(err))

	# Create visual representation
	VisualFactory.create_projectile_visual(self)

	# Add Light2D for projectile glow
	var light = Light2D.new()
	light.enabled = true
	light.texture = preload("res://icon.svg")
	light.texture_scale = 0.8
	light.color = Color(0.3, 0.9, 1.0, 1.0)  # Bright cyan-white
	light.energy = 1.2
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	add_child(light)

	# Create trail effect
	trail = Line2D.new()
	trail.width = 3.0
	trail.default_color = Color(0.3, 0.9, 1.0, 0.6)

	# Create gradient for trail fade
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.3, 0.9, 1.0, 0.0))  # Transparent at tail
	gradient.add_point(1.0, Color(0.3, 0.9, 1.0, 0.8))  # Brighter at head
	trail.gradient = gradient

	trail.width_curve = Curve.new()
	trail.width_curve.add_point(Vector2(0.0, 0.3))  # Thin at tail
	trail.width_curve.add_point(Vector2(1.0, 1.0))  # Full width at head

	trail.antialiased = true
	trail.z_index = -1

	# Null safety check for parent
	var parent = get_parent()
	if parent and is_instance_valid(parent):
		parent.add_child(trail)
	else:
		trail.queue_free()
		trail = null

	last_trail_pos = global_position

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		rotation = direction.angle()

		# Update trail
		if trail and is_instance_valid(trail):
			if global_position.distance_to(last_trail_pos) > TRAIL_SPACING:
				trail.add_point(global_position)
				last_trail_pos = global_position

				# Limit trail length
				if trail.get_point_count() > MAX_TRAIL_POINTS:
					trail.remove_point(0)
	else:
		# Target is invalid, clean up
		if trail and is_instance_valid(trail):
			trail.queue_free()

		# Disconnect signal before freeing
		if body_entered.is_connected(Callable(self, "_on_body_entered")):
			body_entered.disconnect(Callable(self, "_on_body_entered"))

		queue_free()

func _exit_tree() -> void:
	# Safety cleanup if projectile is freed without hitting target
	if trail and is_instance_valid(trail):
		trail.queue_free()

	# Disconnect signal if still connected
	if body_entered.is_connected(Callable(self, "_on_body_entered")):
		body_entered.disconnect(Callable(self, "_on_body_entered"))

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

		# Create impact effect (with null safety check)
		var parent = get_parent()
		if parent and is_instance_valid(parent):
			ParticleEffects.create_projectile_impact(global_position, parent)

		# Pass critical hit info to take_damage for damage number display
		if body.has_method("take_damage"):
			# Check if take_damage accepts is_critical parameter
			var method_info = body.get_method_list()
			var supports_crit = false
			for method in method_info:
				if method.name == "take_damage":
					supports_crit = method.args.size() >= 2
					break

			if supports_crit:
				body.take_damage(dealt_dmg, is_crit)
			else:
				body.take_damage(dealt_dmg)

		# Clean up trail and signal
		if trail and is_instance_valid(trail):
			trail.queue_free()

		# Disconnect signal before freeing
		if body_entered.is_connected(Callable(self, "_on_body_entered")):
			body_entered.disconnect(Callable(self, "_on_body_entered"))

		queue_free()
