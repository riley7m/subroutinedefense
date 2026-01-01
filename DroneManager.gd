class_name DroneManager
extends Node

# === DRONE SPAWN & MANAGEMENT SYSTEM ===
# Manages drone spawning, positioning, and upgrade application
# Extracted from main_hud.gd (Phase 2.2 Refactor - C7)
#
# Responsibilities:
# - Spawn owned drones at run start
# - Position drones around tower
# - Apply DroneUpgradeManager levels to drones
# - Track active drones
# - Refresh drone stats when upgraded

# Drone scene references
const DRONE_FLAME_SCENE = preload("res://drone_flame.tscn")
const DRONE_POISON_SCENE = preload("res://drone_poison.tscn")
const DRONE_FROST_SCENE = preload("res://drone_frost.tscn")
const DRONE_SHOCK_SCENE = preload("res://drone_shock.tscn")

# Drone scene lookup
const DRONE_SCENES = {
	"flame": DRONE_FLAME_SCENE,
	"frost": DRONE_FROST_SCENE,
	"poison": DRONE_POISON_SCENE,
	"shock": DRONE_SHOCK_SCENE
}

# Drone positioning (horizontal line from tower)
const HORIZONTAL_OFFSETS = [-80.0, -40.0, 40.0, 80.0]

# Active drones in current run
var active_drones: Array = []

# Parent node to add drones to (set externally)
var spawn_parent: Node = null

## Spawns all owned drones at run start
## @param tower_position: Position of the tower to spawn drones around
func spawn_owned_drones(tower_position: Vector2) -> void:
	if not spawn_parent:
		push_error("DroneManager: spawn_parent not set! Cannot spawn drones.")
		return

	var drone_types = ["flame", "frost", "poison", "shock"]
	var slot_index = 0

	for drone_type in drone_types:
		# Check if this drone is owned (purchased out-of-run)
		if not RewardManager.owns_drone(drone_type):
			continue

		# Spawn the drone
		var drone = DRONE_SCENES[drone_type].instantiate()
		active_drones.append(drone)
		spawn_parent.add_child(drone)

		# Apply DroneUpgradeManager level
		if drone_type in DroneUpgradeManager.DRONE_TYPES:
			var level = DroneUpgradeManager.get_drone_level(drone_type)
			drone.apply_upgrade(level)

		# Position drone in horizontal line from tower
		var horizontal_offset = HORIZONTAL_OFFSETS[slot_index]
		drone.global_position = tower_position + Vector2(horizontal_offset, 0)

		slot_index += 1
		print("✅ Auto-spawned %s drone (owned)" % drone_type)

## Refreshes all active drones with current upgrade levels
## Called when drone upgrades are purchased
func refresh_all_drones() -> void:
	for drone in active_drones:
		if not is_instance_valid(drone):
			continue

		# Determine drone type and apply DroneUpgradeManager level
		if drone.has_method("apply_upgrade"):
			var drone_type = drone.drone_type if drone.get("drone_type") else ""
			if drone_type in DroneUpgradeManager.DRONE_TYPES:
				var level = DroneUpgradeManager.get_drone_level(drone_type)
				drone.apply_upgrade(level)
			# Fire rate automatically updates in apply_upgrade()

## Cleans up all active drones (called on run end/quit)
func cleanup_drones() -> void:
	for drone in active_drones:
		if is_instance_valid(drone):
			drone.queue_free()
	active_drones.clear()
