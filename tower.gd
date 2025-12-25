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
var shield_regen_rate: float
var shield_initialized: bool = false

@onready var death_screen = get_tree().current_scene.get_node("DeathScreen")


func _ready() -> void:
	# Add to Tower group for easy reference
	add_to_group("Tower")

	# Init timers
	var fire_rate = max(UpgradeManager.get_projectile_fire_rate(), 0.1)  # Guard against division by zero
	fire_timer.wait_time = 1.0 / fire_rate
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	fire_timer.one_shot = false
	add_child(fire_timer)
	fire_timer.start()

	shield_regen_timer.wait_time = 1.0
	shield_regen_timer.timeout.connect(_on_shield_regen_tick)
	shield_regen_timer.one_shot = false
	add_child(shield_regen_timer)
	shield_regen_timer.start()

	# Create visual representation
	VisualFactory.create_tower_visual(self)

	# Add Light2D for tower glow
	var light = Light2D.new()
	light.name = "TowerLight"
	light.enabled = true
	light.texture = preload("res://icon.svg")  # Using default texture
	light.texture_scale = 2.0
	light.color = Color(0.2, 0.8, 1.0, 1.0)  # Bright cyan
	light.energy = 1.5
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	add_child(light)

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
		shield_initialized = true
	else:
		current_shield = min(current_shield, max_shield)

	update_bars()
	update_visual_tier()

func get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest = enemy
			closest_dist = dist
	return closest

func get_nearest_enemies(count: int) -> Array:
	var enemy_list: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		enemy_list.append(enemy)
	enemy_list.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	return enemy_list.slice(0, count)


func _on_fire_timer_timeout() -> void:
	target = get_closest_enemy()

	if target:
		fire_projectile()

func fire_projectile() -> void:
	var num_targets = UpgradeManager.get_multi_target_level()
	var enemies = get_nearest_enemies(num_targets)
	for enemy in enemies:
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position
		projectile.target = enemy
		get_tree().current_scene.add_child(projectile)

		# Create muzzle flash effect
		var direction = (enemy.global_position - global_position).normalized()
		ParticleEffects.create_muzzle_flash(global_position, direction, get_tree().current_scene)

func take_damage(amount: int) -> void:
	# Apply damage reduction
	var reduction = UpgradeManager.get_damage_reduction_level()
	var reduced_amount = int(amount * (1.0 - (reduction / 100.0)))

	RunStats.damage_taken += reduced_amount

	# Screen shake when hit
	ScreenEffects.screen_shake(3.0, 0.2)

	# Apply to shield first
	if current_shield > 0:
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
		if tower_hp <= 0 and death_screen:
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
	# Create white flash overlay
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.6)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 1000
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	get_tree().current_scene.add_child(flash)

	# Fade out quickly
	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

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

