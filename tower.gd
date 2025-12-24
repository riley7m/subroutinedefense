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

func take_damage(amount: int) -> void:
	# Apply damage reduction
	var reduction = UpgradeManager.get_damage_reduction_level()
	var reduced_amount = int(amount * (1.0 - (reduction / 100.0)))

	RunStats.damage_taken += reduced_amount

	# Apply to shield first
	if current_shield > 0:
		var blocked = min(current_shield, reduced_amount)
		current_shield -= blocked
		reduced_amount -= blocked
		#print("🛡️ Shield blocked", blocked, "Remaining:", current_shield)

	# Apply remaining damage to HP
	if reduced_amount > 0:
		tower_hp -= reduced_amount
		#print("💥 Tower hit! Remaining HP:", tower_hp)

		# Check for death
		if tower_hp <= 0 and death_screen:
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
	# Health
	health_bar.max_value = 100  # If you have a fixed max HP, use that number instead
	health_bar.value = tower_hp

	# Shield
	shield_bar.max_value = max_shield
	shield_bar.value = current_shield
	
