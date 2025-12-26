extends Node

# Generic Object Pooling System
# Reduces instantiation overhead by reusing objects

# Pool structure: { "pool_name": { "scene": PackedScene, "pool": Array[Node], "active": Array[Node] } }
var pools: Dictionary = {}

# Pool configuration
const DEFAULT_POOL_SIZE := 50  # Initial pool size
const MAX_POOL_SIZE := 200  # Maximum pool size before forcing cleanup

# Statistics for monitoring
var stats: Dictionary = {}

func _ready() -> void:
	print("🏊 ObjectPool initialized")

# Create or get a pool for a specific scene
func create_pool(pool_name: String, scene: PackedScene, initial_size: int = DEFAULT_POOL_SIZE) -> void:
	if pools.has(pool_name):
		print("⚠️ Pool '%s' already exists" % pool_name)
		return

	pools[pool_name] = {
		"scene": scene,
		"pool": [],  # Inactive objects ready for reuse
		"active": []  # Currently active objects
	}

	stats[pool_name] = {
		"spawned": 0,
		"recycled": 0,
		"created": 0,
		"peak_active": 0
	}

	# Pre-populate pool
	for i in range(initial_size):
		var obj = scene.instantiate()
		obj.set_meta("pool_name", pool_name)
		obj.set_meta("pooled", true)
		_deactivate_object(obj)
		pools[pool_name]["pool"].append(obj)
		stats[pool_name]["created"] += 1

	print("✅ Created pool '%s' with %d objects" % [pool_name, initial_size])

# Get an object from the pool (or create new if pool empty)
func spawn(pool_name: String, parent: Node) -> Node:
	if not pools.has(pool_name):
		push_error("Pool '%s' does not exist!" % pool_name)
		return null

	var pool_data = pools[pool_name]
	var obj: Node = null

	# Try to get from pool
	if pool_data["pool"].size() > 0:
		obj = pool_data["pool"].pop_back()
		stats[pool_name]["recycled"] += 1
	else:
		# Pool empty, create new object
		obj = pool_data["scene"].instantiate()
		obj.set_meta("pool_name", pool_name)
		obj.set_meta("pooled", true)
		stats[pool_name]["created"] += 1

	# Activate object
	_activate_object(obj, parent)
	pool_data["active"].append(obj)
	stats[pool_name]["spawned"] += 1

	# Update peak stats
	var active_count = pool_data["active"].size()
	if active_count > stats[pool_name]["peak_active"]:
		stats[pool_name]["peak_active"] = active_count

	return obj

# Return an object to the pool
func recycle(obj: Node) -> void:
	if not obj or not is_instance_valid(obj):
		return

	if not obj.has_meta("pooled"):
		# Object not from pool, just free it
		obj.queue_free()
		return

	var pool_name = obj.get_meta("pool_name")
	if not pools.has(pool_name):
		push_error("Pool '%s' no longer exists!" % pool_name)
		obj.queue_free()
		return

	var pool_data = pools[pool_name]

	# Remove from active list
	var idx = pool_data["active"].find(obj)
	if idx >= 0:
		pool_data["active"].remove_at(idx)

	# Check pool size limit
	if pool_data["pool"].size() >= MAX_POOL_SIZE:
		# Pool too large, actually free the object
		obj.queue_free()
		return

	# Deactivate and return to pool
	_deactivate_object(obj)
	pool_data["pool"].append(obj)

# Clean up a pool (free all inactive objects)
func clear_pool(pool_name: String) -> void:
	if not pools.has(pool_name):
		return

	var pool_data = pools[pool_name]

	# Free all inactive objects
	for obj in pool_data["pool"]:
		if is_instance_valid(obj):
			obj.queue_free()

	pool_data["pool"].clear()
	print("🧹 Cleared pool '%s'" % pool_name)

# Clean up all pools
func clear_all_pools() -> void:
	for pool_name in pools.keys():
		clear_pool(pool_name)

# Get pool statistics
func get_pool_stats(pool_name: String) -> Dictionary:
	if not pools.has(pool_name):
		return {}

	var pool_data = pools[pool_name]
	var stat_data = stats.get(pool_name, {})

	return {
		"pool_size": pool_data["pool"].size(),
		"active": pool_data["active"].size(),
		"total_spawned": stat_data.get("spawned", 0),
		"total_recycled": stat_data.get("recycled", 0),
		"total_created": stat_data.get("created", 0),
		"peak_active": stat_data.get("peak_active", 0),
		"reuse_rate": _calculate_reuse_rate(pool_name)
	}

# Print pool statistics
func print_stats() -> void:
	print("\n📊 Object Pool Statistics:")
	for pool_name in pools.keys():
		var s = get_pool_stats(pool_name)
		print("  [%s] Pool: %d | Active: %d | Created: %d | Reuse: %.1f%%" % [
			pool_name,
			s["pool_size"],
			s["active"],
			s["total_created"],
			s["reuse_rate"]
		])

# --- PRIVATE METHODS ---

func _activate_object(obj: Node, parent: Node) -> void:
	# Add to scene tree if not already
	if obj.get_parent() == null:
		parent.add_child(obj)

	# Enable processing and visibility
	obj.set_process(true)
	obj.set_physics_process(true)
	obj.set_process_input(true)
	if obj is CanvasItem:
		obj.show()

	# Call custom reset method if available
	if obj.has_method("reset_pooled_object"):
		obj.reset_pooled_object()

func _deactivate_object(obj: Node) -> void:
	# Disable processing
	obj.set_process(false)
	obj.set_physics_process(false)
	obj.set_process_input(false)
	if obj is CanvasItem:
		obj.hide()

	# Remove from scene tree (keep in memory)
	if obj.get_parent():
		obj.get_parent().remove_child(obj)

	# Call custom cleanup method if available
	if obj.has_method("cleanup_pooled_object"):
		obj.cleanup_pooled_object()

func _calculate_reuse_rate(pool_name: String) -> float:
	var stat_data = stats.get(pool_name, {})
	var spawned = stat_data.get("spawned", 0)
	var created = stat_data.get("created", 0)

	if spawned == 0:
		return 0.0

	var reused = spawned - created
	return (float(reused) / float(spawned)) * 100.0

func _exit_tree() -> void:
	clear_all_pools()
