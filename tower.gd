extends Node2D

@export var projectile_scene: PackedScene
var target: Node2D = null

# Timers
@onready var fire_timer = Timer.new()
@onready var shield_regen_timer = Timer.new()

@onready var shield_bar: ProgressBar = $CanvasLayer/ShieldBar
@onready var health_bar: ProgressBar = $CanvasLayer/HealthBar


# Shield + HP
var tower_hp: int = 1000
var max_shield: int
var current_shield: int = 0
var current_overshield: int = 0  # Extra shield layer from upgrades
var shield_regen_rate: float
var shield_initialized: bool = false

@onready var death_screen = null  # Will be set in _ready()

# Enemy targeting cache (performance optimization for wave 50+)
var _cached_closest_enemy: Node2D = null
var _cached_enemy_list: Array = []
var _cache_frame_counter: int = 0
const CACHE_REFRESH_FRAMES: int = 3  # Refresh every 3 frames (~20Hz at 60fps)

func _ready() -> void:
	# Add to Tower group for easy reference
	add_to_group("Tower")

	# Initialize projectile pool
	if projectile_scene and not ObjectPool.pools.has("projectile"):
		ObjectPool.create_pool("projectile", projectile_scene, 50)

	# Init timers
	var fire_rate = max(UpgradeManager.get_projectile_fire_rate(), 0.1)  # Guard against division by zero
	fire_timer.wait_time = 1.0 / fire_rate
	var err = fire_timer.timeout.connect(_on_fire_timer_timeout)
	if err != OK:
		push_error("Failed to connect fire_timer.timeout signal: " + str(err))
	fire_timer.one_shot = false
	add_child(fire_timer)
	fire_timer.start()

	shield_regen_timer.wait_time = 1.0
	err = shield_regen_timer.timeout.connect(_on_shield_regen_tick)
	if err != OK:
		push_error("Failed to connect shield_regen_timer.timeout signal: " + str(err))
	shield_regen_timer.one_shot = false
	add_child(shield_regen_timer)
	shield_regen_timer.start()

	# Safely get death screen reference
	var current = get_tree().current_scene
	if current:
		death_screen = current.get_node_or_null("DeathScreen")

	# Create visual representation (includes Light2D)
	VisualFactory.create_tower_visual(self)

	# Shield init
	refresh_shield_stats()

func refresh_fire_rate():
	var fire_rate = max(UpgradeManager.get_projectile_fire_rate(), 0.1)  # Guard against division by zero
	fire_timer.wait_time = 1.0 / fire_rate

func refresh_shield_stats():
	max_shield = UpgradeManager.get_shield_capacity()
	shield_regen_rate = UpgradeManager.get_shield_regen_rate()

	# On first initialization, set shield to max; otherwise cap at new max
	if not shield_initialized:
		current_shield = max_shield
		current_overshield = UpgradeManager.get_overshield()
		shield_initialized = true
	else:
		current_shield = min(current_shield, max_shield)
		# Update overshield based on upgrades
		var max_overshield = UpgradeManager.get_overshield()
		current_overshield = min(current_overshield, max_overshield)

	update_bars()
	update_visual_tier()

func _process(_delta: float) -> void:
	# Increment cache frame counter
	_cache_frame_counter += 1

	# Invalidate cache if target is dead
	if _cached_closest_enemy and not is_instance_valid(_cached_closest_enemy):
		_cached_closest_enemy = null
		_cached_enemy_list.clear()

func get_closest_enemy() -> Node2D:
	# Use cached result if still valid
	if _cache_frame_counter % CACHE_REFRESH_FRAMES != 0 and _cached_closest_enemy and is_instance_valid(_cached_closest_enemy):
		return _cached_closest_enemy

	# Use EnemyTracker for efficient lookup (no array allocation)
	_cached_closest_enemy = EnemyTracker.get_closest_to_position(global_position)
	return _cached_closest_enemy

func get_nearest_enemies(count: int) -> Array:
	# Use cached result if still valid
	if _cache_frame_counter % CACHE_REFRESH_FRAMES != 0 and _cached_enemy_list.size() > 0:
		return _cached_enemy_list.slice(0, count)

	# Use EnemyTracker for efficient lookup
	_cached_enemy_list = EnemyTracker.get_nearest_to_position(global_position, count)
	return _cached_enemy_list


func _on_fire_timer_timeout() -> void:
	target = get_closest_enemy()

	if target:
		fire_projectile()

func fire_projectile() -> void:
	# Null safety checks
	if not projectile_scene:
		push_error("Tower: projectile_scene not assigned!")
		return

	var current = get_tree().current_scene
	if not current:
		push_error("Tower: current_scene is null!")
		return

	var num_targets = UpgradeManager.get_multi_target_level()
	var enemies = get_nearest_enemies(num_targets)
	for enemy in enemies:
		var projectile = ObjectPool.spawn("projectile", current)
		if projectile:
			projectile.global_position = global_position
			projectile.target = enemy

		# Create muzzle flash effect
		var direction = (enemy.global_position - global_position).normalized()
		ParticleEffects.create_muzzle_flash(global_position, direction, current)

func take_damage(amount: int, attacker: Node2D = null) -> void:
	var damage = amount

	# Check for block chance
	var block_chance = UpgradeManager.get_block_chance()
	if block_chance > 0 and randf() * 100.0 < block_chance:
		var block_amount = UpgradeManager.get_block_amount()
		damage = max(0, damage - block_amount)
		if damage == 0:
			#print("🛡️ Blocked all damage!")
			return

	# Apply boss resistance if attacker is a boss
	var is_boss_attack = false
	if attacker and attacker.has_method("is_boss") and attacker.is_boss():
		is_boss_attack = true
		var boss_resistance = UpgradeManager.get_boss_resistance()
		damage = int(damage * (1.0 - (boss_resistance / 100.0)))

		# Trigger impact distortion on boss hits
		BackgroundEffects.trigger_impact_distortion(global_position, 5.0)

	# Apply damage reduction
	var reduction = UpgradeManager.get_damage_reduction_level()
	var reduced_amount = int(damage * (1.0 - (reduction / 100.0)))

	RunStats.damage_taken += reduced_amount

	# Screen shake when hit
	ScreenEffects.screen_shake(3.0, 0.2)

	# Apply to overshield first
	if current_overshield > 0:
		var blocked = min(current_overshield, reduced_amount)
		current_overshield -= blocked
		reduced_amount -= blocked
		#print("⚡ Overshield blocked", blocked, "Remaining:", current_overshield)

	# Then apply to shield
	if current_shield > 0 and reduced_amount > 0:
		var blocked = min(current_shield, reduced_amount)
		var shield_broke = (current_shield - blocked) <= 0 and current_shield > 0
		current_shield -= blocked
		reduced_amount -= blocked
		#print("🛡️ Shield blocked", blocked, "Remaining:", current_shield)

		# Shield break flash
		if shield_broke:
			_trigger_shield_break_flash()

	# Apply remaining damage to HP
	if reduced_amount > 0:
		tower_hp -= reduced_amount
		#print("💥 Tower hit! Remaining HP:", tower_hp)

		# Check for death
		if tower_hp <= 0:
			_cleanup_before_death()

			# Check if boss rush is active - use custom death screen
			if BossRushManager and BossRushManager.is_boss_rush_active():
				var spawner = get_tree().current_scene.get_node_or_null("Spawner")
				if spawner and spawner.has_method("end_boss_rush"):
					spawner.end_boss_rush()

				# Show boss rush death screen instead of normal death screen
				var boss_rush_death = get_tree().current_scene.get_node_or_null("BossRushDeathScreen")
				if boss_rush_death and boss_rush_death.has_method("show_boss_rush_death"):
					ScreenEffects.death_transition()
					boss_rush_death.show_boss_rush_death(RunStats.damage_dealt, spawner.current_wave)
				else:
					print("⚠️ Boss rush death screen not found!")
					if death_screen:
						ScreenEffects.death_transition()
						death_screen.show_death()
			elif death_screen:
				# Normal death
				ScreenEffects.death_transition()
				death_screen.show_death()

	update_bars()

func _on_shield_regen_tick() -> void:
	if current_shield < max_shield:
		var regen_amount = int(max_shield * (shield_regen_rate / 100.0))
		if regen_amount > 0:
			current_shield = min(current_shield + regen_amount, max_shield)
			update_bars()
			#print("🌀 Shield regenerated:", regen_amount, "→", current_shield)
	

func update_bars() -> void:
	# Health - smooth animation
	health_bar.max_value = 1000
	var tween = create_tween()
	tween.tween_property(health_bar, "value", tower_hp, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Shield - smooth animation
	shield_bar.max_value = max_shield
	var shield_tween = create_tween()
	shield_tween.tween_property(shield_bar, "value", current_shield, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _trigger_shield_break_flash() -> void:
	# Null safety check
	var current = get_tree().current_scene
	if not current:
		return

	# Create white flash overlay
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.6)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 1000
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	current.add_child(flash)

	# Fade out quickly
	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)

	# Extra screen shake for emphasis
	ScreenEffects.screen_shake(8.0, 0.25)

func update_visual_tier() -> void:
	# Calculate total upgrade level based on key stats
	var damage_level = UpgradeManager.get_projectile_damage()
	var fire_rate = UpgradeManager.get_projectile_fire_rate()
	var shield_capacity = max_shield

	# Calculate tier (0-4) based on total power
	var total_power = damage_level + (fire_rate * 10) + (shield_capacity / 10)
	var tier = 0

	if total_power > 200:
		tier = 4  # Elite tier
	elif total_power > 120:
		tier = 3  # Advanced tier
	elif total_power > 60:
		tier = 2  # Upgraded tier
	elif total_power > 20:
		tier = 1  # Enhanced tier
	else:
		tier = 0  # Basic tier

	# Update visual based on tier
	var visual_container = get_node_or_null("VisualContainer")
	var tower_light = get_node_or_null("TowerLight")

	if visual_container:
		# Scale increases with tier
		var target_scale = Vector2(1.0 + tier * 0.15, 1.0 + tier * 0.15)
		var tween = create_tween()
		tween.tween_property(visual_container, "scale", target_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if tower_light:
		# Light gets brighter and more colorful with upgrades
		match tier:
			4:  # Elite - Purple/pink
				tower_light.color = Color(0.8, 0.3, 1.0, 1.0)
				tower_light.energy = 2.5
				tower_light.texture_scale = 3.5
			3:  # Advanced - Bright cyan
				tower_light.color = Color(0.3, 1.0, 1.0, 1.0)
				tower_light.energy = 2.2
				tower_light.texture_scale = 3.0
			2:  # Upgraded - Cyan-green
				tower_light.color = Color(0.2, 0.9, 0.7, 1.0)
				tower_light.energy = 1.9
				tower_light.texture_scale = 2.5
			1:  # Enhanced - Light cyan
				tower_light.color = Color(0.2, 0.8, 1.0, 1.0)
				tower_light.energy = 1.6
				tower_light.texture_scale = 2.2
			_:  # Basic
				tower_light.color = Color(0.2, 0.8, 1.0, 1.0)
				tower_light.energy = 1.5
				tower_light.texture_scale = 2.0

func _cleanup_before_death() -> void:
	# Stop and clean up timers to prevent leaks
	if fire_timer and is_instance_valid(fire_timer):
		fire_timer.stop()
		if fire_timer.timeout.is_connected(Callable(self, "_on_fire_timer_timeout")):
			fire_timer.timeout.disconnect(Callable(self, "_on_fire_timer_timeout"))

	if shield_regen_timer and is_instance_valid(shield_regen_timer):
		shield_regen_timer.stop()
		if shield_regen_timer.timeout.is_connected(Callable(self, "_on_shield_regen_tick")):
			shield_regen_timer.timeout.disconnect(Callable(self, "_on_shield_regen_tick"))

