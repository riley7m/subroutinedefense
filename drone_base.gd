extends Node2D

@export var fire_interval: float = 1.0
@export var drone_type: String = "base"  # Override in child scripts
var drone_level: int = 1

@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	fire_timer.wait_time = fire_interval
	var err = fire_timer.timeout.connect(_on_fire_timer_timeout)
	if err != OK:
		push_error("Failed to connect fire_timer.timeout signal: " + str(err))
	fire_timer.one_shot = false
	fire_timer.start()

	# Create visual representation (child classes should set drone_type)
	_create_drone_visual()

	# Add Light2D for drone glow (color varies by type)
	var light = Light2D.new()
	light.enabled = true
	light.texture = preload("res://icon.svg")
	light.texture_scale = 1.2

	# Different colors for different drone types
	match drone_type:
		"flame":
			light.color = Color(1.0, 0.5, 0.0, 1.0)  # Orange flame
			light.energy = 1.3
		"poison":
			light.color = Color(0.5, 0.0, 1.0, 1.0)  # Purple poison
			light.energy = 1.1
		"frost":
			light.color = Color(0.3, 0.7, 1.0, 1.0)  # Ice blue
			light.energy = 1.1
		"lightning":
			light.color = Color(1.0, 1.0, 0.3, 1.0)  # Electric yellow
			light.energy = 1.4
		_:  # Default
			light.color = Color(0.5, 1.0, 0.5, 1.0)  # Green
			light.energy = 1.0

	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	add_child(light)

func _on_fire_timer_timeout() -> void:
	var target = pick_target()
	if target:
		fire_at(target)

# --- Methods to be overridden in child drone scripts ---

func pick_target() -> Node2D:
	# Default implementation: pick enemy with lowest HP
	# Override in child classes for different targeting strategies
	return pick_lowest_hp_enemy()

# Helper: Pick enemy with lowest HP (used by flame and poison drones)
func pick_lowest_hp_enemy() -> Node2D:
	var best: Node2D = null
	var min_hp = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("get_current_hp"):
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
	# Optional: Override for per-drone upgrade scaling

func _create_drone_visual() -> void:
	# Create visual based on drone type
	VisualFactory.create_drone_visual(drone_type, self)

func _exit_tree() -> void:
	# Clean up timer when drone is removed
	if fire_timer and is_instance_valid(fire_timer):
		fire_timer.stop()
		if fire_timer.timeout.is_connected(Callable(self, "_on_fire_timer_timeout")):
			fire_timer.timeout.disconnect(Callable(self, "_on_fire_timer_timeout"))
