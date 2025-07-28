extends Node2D

@export var fire_interval: float = 1.0
var drone_level: int = 1

@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	fire_timer.one_shot = false
	fire_timer.start()

func _on_fire_timer_timeout() -> void:
	var target = pick_target()
	if target:
		fire_at(target)

# --- Methods to be overridden in child drone scripts ---

func pick_target() -> Node2D:
	# Placeholder: Override this in derived drones
	return null

@warning_ignore("unused_parameter")
func fire_at(target: Node2D) -> void:
	# Placeholder: Override this in derived drones
	pass

func apply_upgrade(level: int) -> void:
	drone_level = level
	# Optional: Override for per-drone upgrade scaling
