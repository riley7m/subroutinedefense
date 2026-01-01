extends Area2D

@export var speed: float = 400
@export var base_speed: float = 400  # Store original speed for pooling reset
var target: Node2D = null
var pierced_targets: Array = []  # Track pierced enemies
var ricochet_count: int = 0  # Track number of ricochets

# Trail system
var trail: Line2D
const MAX_TRAIL_POINTS: int = 15
const TRAIL_SPACING: float = 5.0
var last_trail_pos: Vector2

# Pooling support
var is_pooled: bool = false

func _ready() -> void:
	# Apply projectile speed multiplier from upgrades
	speed *= UpgradeManager.get_projectile_speed()

	if not body_entered.is_connected(Callable(self, "_on_body_entered")):
		var err = body_entered.connect(Callable(self, "_on_body_entered"))
		if err != OK:
			push_error("Failed to connect projectile body_entered signal: " + str(err))

	# Create visual representation
	VisualFactory.create_projectile_visual(self)

	# Add quick spawn animation
	VisualFactory.add_spawn_animation(self, 0.15)

	# Get trail from pool
	var parent = get_parent()
	if parent and is_instance_valid(parent):
		trail = TrailPool.get_trail(parent, Color(0.3, 0.9, 1.0), 3.0)
		last_trail_pos = global_position
	else:
		trail = null

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		rotation = direction.angle()

		# Update trail using TrailPool
		if trail and is_instance_valid(trail):
			if global_position.distance_to(last_trail_pos) > TRAIL_SPACING:
				TrailPool.update_trail(trail, global_position, MAX_TRAIL_POINTS)
				last_trail_pos = global_position
	else:
		# Target is invalid, clean up
		_cleanup_and_recycle()

func _exit_tree() -> void:
	# Safety cleanup if projectile is freed without hitting target
	if trail and is_instance_valid(trail):
		TrailPool.recycle_trail(trail)
		trail = null

	# Disconnect signal if still connected
	if body_entered.is_connected(Callable(self, "_on_body_entered")):
		body_entered.disconnect(Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node2D) -> void:
	if body == target and body.has_method("take_damage"):
		# Skip if we already pierced this target
		if body in pierced_targets:
			return

		var base_dmg_bn = UpgradeManager.get_projectile_damage()  # BigNumber

		# Apply boss bonus damage
		var is_boss = body.has_method("is_boss") and body.is_boss()
		if is_boss:
			base_dmg_bn = base_dmg_bn.copy().multiply(UpgradeManager.get_boss_bonus())

		var crit_roll = randi() % 100
		var is_crit = crit_roll < UpgradeManager.get_crit_chance()
		var dealt_dmg_bn = base_dmg_bn.copy()

		if is_crit:
			var crit_multiplier = UpgradeManager.get_crit_damage_multiplier()
			dealt_dmg_bn = base_dmg_bn.copy().multiply(crit_multiplier)

		# --- Record damage dealt before applying to enemy (for run stats)
		# Use BigNumber to maintain precision for infinite scaling
		RunStats.add_damage_dealt_bn(dealt_dmg_bn)

		# Create impact effect (with null safety check)
		var parent = get_parent()
		if parent and is_instance_valid(parent):
			ParticleEffects.create_projectile_impact(global_position, parent)

		# Apply damage and get overkill amount
		var overkill_damage = 0
		# Convert BigNumber to float for enemy.take_damage()
		var dealt_dmg = dealt_dmg_bn.to_float()
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

			# Calculate overkill if enemy died
			# TODO: Overkill calculation needs redesign - enemies don't store max HP
			# For now, disable overkill to prevent errors
			# if body.has_method("get_health") and body.get_health().less_equal(BigNumber.new(0)):
			# 	overkill_damage calculation here

		# Handle piercing
		var piercing = UpgradeManager.get_piercing()
		if piercing > pierced_targets.size():
			pierced_targets.append(body)
			# Find next enemy to pierce through
			var nearest_enemy = _find_nearest_enemy(body)
			if nearest_enemy:
				target = nearest_enemy
				return  # Continue to next target

		# Handle ricochet
		var ricochet_chance = UpgradeManager.get_ricochet_chance()
		var ricochet_max = UpgradeManager.get_ricochet_max_targets()
		if ricochet_count < ricochet_max and randf() * 100.0 < ricochet_chance:
			var nearest_enemy = _find_nearest_enemy(body)
			if nearest_enemy:
				ricochet_count += 1
				target = nearest_enemy
				pierced_targets.clear()  # Reset piercing for ricochet
				return  # Continue to ricocheted target

		# Handle overkill damage spread
		if overkill_damage > 0:
			var overkill_percent = UpgradeManager.get_overkill_damage()
			if overkill_percent > 0:
				var spread_damage = int(overkill_damage * overkill_percent)
				_spread_overkill_damage(spread_damage, body)

		# Clean up and recycle
		_cleanup_and_recycle()

func _find_nearest_enemy(exclude: Node2D) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if enemy == exclude or enemy in pierced_targets:
			continue
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist and dist < 300:  # Max pierce/ricochet range
			nearest_dist = dist
			nearest = enemy

	return nearest

func _spread_overkill_damage(damage: int, origin: Node2D) -> void:
	if damage <= 0:
		return

	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearby_enemies = []

	# Find enemies within 150 units
	for enemy in enemies:
		if enemy == origin or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue

		var dist = origin.global_position.distance_to(enemy.global_position)
		if dist < 150:
			nearby_enemies.append(enemy)

	# Split damage among nearby enemies
	if nearby_enemies.size() > 0:
		# Use explicit float conversion to prevent division issues
		var split_damage = max(1, int(float(damage) / float(nearby_enemies.size())))
		for enemy in nearby_enemies:
			if enemy.has_method("take_damage"):
				enemy.take_damage(split_damage)
				RunStats.add_damage_dealt(split_damage)

# --- OBJECT POOLING METHODS ---

func reset_pooled_object() -> void:
	# Called when projectile is taken from pool
	is_pooled = true

	# Reset state
	pierced_targets.clear()
	ricochet_count = 0
	speed = base_speed * UpgradeManager.get_projectile_speed()

	# Reconnect signal if needed
	if not body_entered.is_connected(Callable(self, "_on_body_entered")):
		var err = body_entered.connect(Callable(self, "_on_body_entered"))
		if err != OK:
			push_error("Failed to connect projectile body_entered signal: " + str(err))

	# Create visual representation
	VisualFactory.create_projectile_visual(self)

	# Add quick spawn animation
	VisualFactory.add_spawn_animation(self, 0.15)

	# Get trail from pool
	var parent = get_parent()
	if parent and is_instance_valid(parent):
		trail = TrailPool.get_trail(parent, Color(0.3, 0.9, 1.0), 3.0)
		last_trail_pos = global_position
	else:
		trail = null

func cleanup_pooled_object() -> void:
	# Called when projectile is returned to pool
	# Recycle trail back to pool
	if trail and is_instance_valid(trail):
		TrailPool.recycle_trail(trail)
		trail = null

	# Disconnect signal
	if body_entered.is_connected(Callable(self, "_on_body_entered")):
		body_entered.disconnect(Callable(self, "_on_body_entered"))

	# Clear references
	target = null
	pierced_targets.clear()

func _cleanup_and_recycle() -> void:
	# Recycle trail back to pool
	if trail and is_instance_valid(trail):
		TrailPool.recycle_trail(trail)
		trail = null

	# Disconnect signal
	if body_entered.is_connected(Callable(self, "_on_body_entered")):
		body_entered.disconnect(Callable(self, "_on_body_entered"))

	# Return to pool or free
	if is_pooled:
		ObjectPool.recycle(self)
	else:
		queue_free()
