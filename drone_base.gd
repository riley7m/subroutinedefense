extends Node2D

@export var drone_type: String = "base"  # Override in child scripts
var drone_level: int = 1

# Drone-specific constants (NOT affected by tower upgrades)
const BASE_FIRE_RATE: float = 1.0  # Base attacks per second
const FIRE_RATE_PER_LEVEL: float = 0.1  # +0.1 attacks/sec per level
const MAX_FIRE_RATE: float = 4.0  # Hard cap at 4.0 attacks/sec
const BASE_HORIZONTAL_RANGE: float = 200.0  # Base horizontal distance from tower
const RANGE_PER_LEVEL: float = 10.0  # +10px range per level
const MAX_HORIZONTAL_RANGE: float = 400.0  # Hard cap at 400px range

@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	# Drones have their own fire rate based on their level
	_update_fire_rate()
	var err = fire_timer.timeout.connect(_on_fire_timer_timeout)
	if err != OK:
		push_error("Failed to connect fire_timer.timeout signal: " + str(err))
	fire_timer.one_shot = false
	fire_timer.start()

	# Create visual representation (child classes should set drone_type)
	_create_drone_visual()

func _update_fire_rate() -> void:
	# Drones use their own fire rate based on level (independent of tower)
	var attacks_per_sec = BASE_FIRE_RATE + (drone_level * FIRE_RATE_PER_LEVEL)
	attacks_per_sec = min(attacks_per_sec, MAX_FIRE_RATE)  # Cap at 4.0 attacks/sec
	fire_timer.wait_time = 1.0 / max(attacks_per_sec, 0.1)

func _on_fire_timer_timeout() -> void:
	var target = pick_target()
	if target:
		fire_at(target)

# --- Methods to be overridden in child drone scripts ---

func pick_target() -> Node2D:
	# Default implementation: pick enemy with lowest HP
	# Override in child classes for different targeting strategies
	return pick_lowest_hp_enemy()

# Helper: Get current horizontal range based on level
func get_horizontal_range() -> float:
	var range_bonus = drone_level * RANGE_PER_LEVEL
	var total_range = BASE_HORIZONTAL_RANGE + range_bonus
	return min(total_range, MAX_HORIZONTAL_RANGE)  # Cap at 400px

# Helper: Check if enemy is within horizontal range of tower
func is_in_range(enemy: Node2D) -> bool:
	var tower = get_tree().get_first_node_in_group("Tower")
	if not tower or not is_instance_valid(enemy):
		return false

	# Check horizontal distance only (ignore vertical)
	var horizontal_dist = abs(tower.global_position.x - enemy.global_position.x)
	return horizontal_dist <= get_horizontal_range()

# Helper: Pick enemy with lowest HP (used by flame and poison drones)
func pick_lowest_hp_enemy() -> Node2D:
	var best: Node2D = null
	var min_hp = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("get_current_hp"):
			continue
		if not is_in_range(enemy):  # Only target enemies in horizontal range
			continue
		var hp = enemy.get_current_hp()
		if hp < min_hp:
			min_hp = hp
			best = enemy
	return best

@warning_ignore("unused_parameter")
func fire_at(target: Node2D) -> void:
	# Placeholder: Override this in derived drones
	pass

func apply_upgrade(level: int) -> void:
	drone_level = level
	_update_fire_rate()  # Update fire rate when level changes

func _create_drone_visual() -> void:
	# Create visual based on drone type
	VisualFactory.create_drone_visual(drone_type, self)

func _exit_tree() -> void:
	# Clean up timer when drone is removed
	if fire_timer and is_instance_valid(fire_timer):
		fire_timer.stop()
		if fire_timer.timeout.is_connected(Callable(self, "_on_fire_timer_timeout")):
			fire_timer.timeout.disconnect(Callable(self, "_on_fire_timer_timeout"))
