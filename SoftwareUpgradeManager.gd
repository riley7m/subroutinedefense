extends Node

# Software Upgrade System (Lab/Research equivalent)
# Total completion time: ~3 years with 2 concurrent slots

# Active upgrade slots
const MAX_SLOTS = 2
var active_upgrades: Array = [null, null]  # Each entry is a Dictionary with upgrade data

# Completed upgrades
var completed_upgrades: Array[String] = []
var unlocked_upgrades: Array[String] = ["data_analysis_101"]  # Starting upgrade

# Upgrade tree definition
var upgrade_tree: Dictionary = {}

signal upgrade_completed(upgrade_id: String)
signal upgrade_started(upgrade_id: String, slot_index: int)
signal upgrades_updated

func _ready() -> void:
	_initialize_upgrade_tree()
	load_upgrade_state()

func _initialize_upgrade_tree() -> void:
	# Duration in seconds (for offline calculations)
	# 1 hour = 3600, 1 day = 86400, 1 week = 604800, 1 month = 2592000

	upgrade_tree = {
		# === TIER 1: Foundation (1-4 hours each) ===
		"data_analysis_101": {
			"name": "Data Analysis 101",
			"description": "Learn basic data analysis techniques",
			"duration": 3600,  # 1 hour
			"cost": {"fragments": 50},
			"requires": [],
			"unlocks": ["pattern_recognition", "code_optimization"],
			"bonuses": {"data_credit_multiplier": 0.05},
			"tier": 1,
		},

		"pattern_recognition": {
			"name": "Pattern Recognition",
			"description": "Identify enemy patterns faster",
			"duration": 7200,  # 2 hours
			"cost": {"fragments": 100},
			"requires": ["data_analysis_101"],
			"unlocks": ["advanced_targeting", "predictive_analytics"],
			"bonuses": {"crit_chance_perm": 2},
			"tier": 1,
		},

		"code_optimization": {
			"name": "Code Optimization",
			"description": "Optimize core algorithms",
			"duration": 10800,  # 3 hours
			"cost": {"fragments": 100},
			"requires": ["data_analysis_101"],
			"unlocks": ["compiler_improvements", "memory_management"],
			"bonuses": {"fire_rate_perm": 0.05},
			"tier": 1,
		},

		# === TIER 2: Specialization (8-24 hours each) ===
		"advanced_targeting": {
			"name": "Advanced Targeting",
			"description": "Multi-target enemy acquisition",
			"duration": 28800,  # 8 hours
			"cost": {"fragments": 500, "archive_tokens": 100},
			"requires": ["pattern_recognition"],
			"unlocks": ["quantum_targeting", "swarm_intelligence"],
			"bonuses": {"multi_target_bonus": 1},
			"tier": 2,
			"tradeoff": "Locks defensive_protocols path"
		},

		"predictive_analytics": {
			"name": "Predictive Analytics",
			"description": "Predict enemy movements",
			"duration": 43200,  # 12 hours
			"cost": {"fragments": 500, "archive_tokens": 100},
			"requires": ["pattern_recognition"],
			"unlocks": ["ai_prediction", "behavior_modeling"],
			"bonuses": {"wave_skip_chance_perm": 1.0},
			"tier": 2,
		},

		"compiler_improvements": {
			"name": "Compiler Improvements",
			"description": "Faster code execution",
			"duration": 57600,  # 16 hours
			"cost": {"fragments": 500, "archive_tokens": 100},
			"requires": ["code_optimization"],
			"unlocks": ["jit_compilation", "parallel_processing"],
			"bonuses": {"projectile_damage_perm": 50},
			"tier": 2,
		},

		"memory_management": {
			"name": "Memory Management",
			"description": "Efficient resource allocation",
			"duration": 86400,  # 24 hours (1 day)
			"cost": {"fragments": 500, "archive_tokens": 100},
			"requires": ["code_optimization"],
			"unlocks": ["garbage_collection", "cache_optimization"],
			"bonuses": {"shield_integrity_perm": 100},
			"tier": 2,
		},

		# === TIER 3: Advanced (2-7 days each) ===
		"quantum_targeting": {
			"name": "Quantum Targeting",
			"description": "Superposition-based targeting",
			"duration": 172800,  # 48 hours (2 days)
			"cost": {"fragments": 2000, "archive_tokens": 500},
			"requires": ["advanced_targeting"],
			"unlocks": ["entanglement_systems"],
			"bonuses": {"crit_damage_perm": 0.25},
			"tier": 3,
		},

		"jit_compilation": {
			"name": "JIT Compilation",
			"description": "Just-in-time code compilation",
			"duration": 259200,  # 72 hours (3 days)
			"cost": {"fragments": 2000, "archive_tokens": 500},
			"requires": ["compiler_improvements"],
			"unlocks": ["aot_compilation"],
			"bonuses": {"fire_rate_perm": 0.15},
			"tier": 3,
		},

		"parallel_processing": {
			"name": "Parallel Processing",
			"description": "Multi-threaded execution",
			"duration": 345600,  # 96 hours (4 days)
			"cost": {"fragments": 2000, "archive_tokens": 500},
			"requires": ["compiler_improvements"],
			"unlocks": ["distributed_computing"],
			"bonuses": {"projectile_damage_perm": 150},
			"tier": 3,
		},

		"garbage_collection": {
			"name": "Garbage Collection",
			"description": "Automatic memory cleanup",
			"duration": 432000,  # 120 hours (5 days)
			"cost": {"fragments": 2000, "archive_tokens": 500},
			"requires": ["memory_management"],
			"unlocks": ["memory_pooling"],
			"bonuses": {"shield_regen_perm": 5.0},
			"tier": 3,
		},

		"cache_optimization": {
			"name": "Cache Optimization",
			"description": "CPU cache optimization",
			"duration": 604800,  # 168 hours (1 week)
			"cost": {"fragments": 2000, "archive_tokens": 500},
			"requires": ["memory_management"],
			"unlocks": ["memory_hierarchy"],
			"bonuses": {"free_upgrade_chance_perm": 2.0},
			"tier": 3,
		},

		# === TIER 4: Expert (1-4 weeks each) ===
		"entanglement_systems": {
			"name": "Quantum Entanglement",
			"description": "Instant multi-target synchronization",
			"duration": 1209600,  # 336 hours (2 weeks)
			"cost": {"fragments": 10000, "archive_tokens": 2000},
			"requires": ["quantum_targeting"],
			"unlocks": ["superposition_weapons"],
			"bonuses": {"multi_target_bonus": 2},
			"tier": 4,
		},

		"aot_compilation": {
			"name": "AOT Compilation",
			"description": "Ahead-of-time compilation",
			"duration": 1814400,  # 504 hours (3 weeks)
			"cost": {"fragments": 10000, "archive_tokens": 2000},
			"requires": ["jit_compilation"],
			"unlocks": ["native_codegen"],
			"bonuses": {"fire_rate_perm": 0.30},
			"tier": 4,
		},

		"distributed_computing": {
			"name": "Distributed Computing",
			"description": "Network-wide processing",
			"duration": 2419200,  # 672 hours (4 weeks)
			"cost": {"fragments": 10000, "archive_tokens": 2000},
			"requires": ["parallel_processing"],
			"unlocks": ["cluster_computing"],
			"bonuses": {"projectile_damage_perm": 500},
			"tier": 4,
		},

		"memory_pooling": {
			"name": "Memory Pooling",
			"description": "Pre-allocated memory pools",
			"duration": 1814400,  # 504 hours (3 weeks)
			"cost": {"fragments": 10000, "archive_tokens": 2000},
			"requires": ["garbage_collection"],
			"unlocks": ["memory_arena"],
			"bonuses": {"shield_integrity_perm": 500},
			"tier": 4,
		},

		# === TIER 5: Master (1-3 months each) ===
		"superposition_weapons": {
			"name": "Superposition Weapons",
			"description": "Weapons exist in multiple states",
			"duration": 2592000,  # 720 hours (1 month)
			"cost": {"fragments": 50000, "archive_tokens": 10000},
			"requires": ["entanglement_systems"],
			"unlocks": ["reality_manipulation"],
			"bonuses": {"crit_damage_perm": 0.75, "crit_chance_perm": 10},
			"tier": 5,
		},

		"native_codegen": {
			"name": "Native Code Generation",
			"description": "Direct machine code generation",
			"duration": 5184000,  # 1440 hours (2 months)
			"cost": {"fragments": 50000, "archive_tokens": 10000},
			"requires": ["aot_compilation"],
			"unlocks": ["assembly_optimization"],
			"bonuses": {"fire_rate_perm": 0.50, "data_credit_multiplier": 0.25},
			"tier": 5,
		},

		"cluster_computing": {
			"name": "Cluster Computing",
			"description": "Massive parallel processing",
			"duration": 7776000,  # 2160 hours (3 months)
			"cost": {"fragments": 50000, "archive_tokens": 10000},
			"requires": ["distributed_computing"],
			"unlocks": ["grid_computing"],
			"bonuses": {"projectile_damage_perm": 2000, "archive_token_multiplier": 0.25},
			"tier": 5,
		},

		"memory_arena": {
			"name": "Memory Arena",
			"description": "Massive memory allocation",
			"duration": 5184000,  # 1440 hours (2 months)
			"cost": {"fragments": 50000, "archive_tokens": 10000},
			"requires": ["memory_pooling"],
			"unlocks": ["memory_fortress"],
			"bonuses": {"shield_integrity_perm": 2000, "damage_reduction_perm": 0.15},
			"tier": 5,
		},

		# === TIER 6: Legendary (3-6 months each) - Endgame ===
		"reality_manipulation": {
			"name": "Reality Manipulation",
			"description": "Bend the fabric of reality",
			"duration": 10368000,  # 2880 hours (4 months)
			"cost": {"fragments": 250000, "archive_tokens": 50000},
			"requires": ["superposition_weapons"],
			"unlocks": [],
			"bonuses": {"crit_damage_perm": 1.5, "crit_chance_perm": 20, "multi_target_bonus": 5},
			"tier": 6,
			"final": true,
		},

		"assembly_optimization": {
			"name": "Assembly Optimization",
			"description": "Hand-tuned assembly code",
			"duration": 12960000,  # 3600 hours (5 months)
			"cost": {"fragments": 250000, "archive_tokens": 50000},
			"requires": ["native_codegen"],
			"unlocks": [],
			"bonuses": {"fire_rate_perm": 1.0, "data_credit_multiplier": 0.50, "free_upgrade_chance_perm": 10.0},
			"tier": 6,
			"final": true,
		},

		"grid_computing": {
			"name": "Grid Computing",
			"description": "Planet-scale computing",
			"duration": 15552000,  # 4320 hours (6 months)
			"cost": {"fragments": 250000, "archive_tokens": 50000},
			"requires": ["cluster_computing"],
			"unlocks": [],
			"bonuses": {"projectile_damage_perm": 10000, "archive_token_multiplier": 1.0, "wave_skip_chance_perm": 10.0},
			"tier": 6,
			"final": true,
		},

		"memory_fortress": {
			"name": "Memory Fortress",
			"description": "Impenetrable defenses",
			"duration": 12960000,  # 3600 hours (5 months)
			"cost": {"fragments": 250000, "archive_tokens": 50000},
			"requires": ["memory_arena"],
			"unlocks": [],
			"bonuses": {"shield_integrity_perm": 10000, "damage_reduction_perm": 0.50, "shield_regen_perm": 50.0},
			"tier": 6,
			"final": true,
		},
	}

func can_start_upgrade(upgrade_id: String) -> bool:
	# Check if upgrade exists
	if not upgrade_tree.has(upgrade_id):
		return false

	# Check if already completed
	if upgrade_id in completed_upgrades:
		return false

	# Check if already in progress
	for slot in active_upgrades:
		if slot != null and slot["id"] == upgrade_id:
			return false

	# Check if unlocked
	if not upgrade_id in unlocked_upgrades:
		return false

	# Check requirements
	var upgrade = upgrade_tree[upgrade_id]
	for req in upgrade["requires"]:
		if not req in completed_upgrades:
			return false

	# Check cost
	var cost = upgrade.get("cost", {})
	if cost.get("fragments", 0) > RewardManager.fragments:
		return false
	if cost.get("archive_tokens", 0) > RewardManager.archive_tokens:
		return false

	return true

func start_upgrade(upgrade_id: String, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false

	if active_upgrades[slot_index] != null:
		return false

	if not can_start_upgrade(upgrade_id):
		return false

	var upgrade = upgrade_tree[upgrade_id]

	# Deduct cost
	var cost = upgrade.get("cost", {})
	RewardManager.fragments -= cost.get("fragments", 0)
	RewardManager.archive_tokens -= cost.get("archive_tokens", 0)

	# Start upgrade
	active_upgrades[slot_index] = {
		"id": upgrade_id,
		"start_time": Time.get_unix_time_from_system(),
		"duration": upgrade["duration"],
	}

	emit_signal("upgrade_started", upgrade_id, slot_index)
	emit_signal("upgrades_updated")
	save_upgrade_state()

	print("🔬 Started upgrade: %s (slot %d)" % [upgrade["name"], slot_index])
	return true

func update_upgrades() -> void:
	var now = Time.get_unix_time_from_system()
	var any_completed = false

	for i in range(MAX_SLOTS):
		var slot = active_upgrades[i]
		if slot == null:
			continue

		var elapsed = now - slot["start_time"]
		if elapsed >= slot["duration"]:
			_complete_upgrade(i)
			any_completed = true

	if any_completed:
		emit_signal("upgrades_updated")

func _complete_upgrade(slot_index: int) -> void:
	var slot = active_upgrades[slot_index]
	if slot == null:
		return

	var upgrade_id = slot["id"]
	var upgrade = upgrade_tree[upgrade_id]

	# Mark as completed
	completed_upgrades.append(upgrade_id)

	# Unlock next upgrades
	for next_id in upgrade.get("unlocks", []):
		if not next_id in unlocked_upgrades:
			unlocked_upgrades.append(next_id)

	# Apply bonuses
	_apply_upgrade_bonuses(upgrade)

	# Clear slot
	active_upgrades[slot_index] = null

	emit_signal("upgrade_completed", upgrade_id)
	save_upgrade_state()

	print("✅ Completed upgrade: %s" % upgrade["name"])

func _apply_upgrade_bonuses(upgrade: Dictionary) -> void:
	var bonuses = upgrade.get("bonuses", {})

	for bonus_key in bonuses.keys():
		var value = bonuses[bonus_key]

		match bonus_key:
			"projectile_damage_perm":
				RewardManager.perm_projectile_damage += value
			"fire_rate_perm":
				RewardManager.perm_projectile_fire_rate += value
			"crit_chance_perm":
				RewardManager.perm_crit_chance += value
			"crit_damage_perm":
				RewardManager.perm_crit_damage += value
			"shield_integrity_perm":
				RewardManager.perm_shield_integrity += value
			"damage_reduction_perm":
				RewardManager.perm_damage_reduction += value
			"shield_regen_perm":
				RewardManager.perm_shield_regen += value
			"data_credit_multiplier":
				RewardManager.perm_data_credit_multiplier += value
			"archive_token_multiplier":
				RewardManager.perm_archive_token_multiplier += value
			"wave_skip_chance_perm":
				RewardManager.perm_wave_skip_chance += value
			"free_upgrade_chance_perm":
				RewardManager.perm_free_upgrade_chance += value
			# Add more bonus types as needed

func get_upgrade_progress(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return 0.0

	var slot = active_upgrades[slot_index]
	if slot == null:
		return 0.0

	var now = Time.get_unix_time_from_system()
	var elapsed = now - slot["start_time"]
	return clamp(float(elapsed) / float(slot["duration"]), 0.0, 1.0)

func get_upgrade_time_remaining(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return 0

	var slot = active_upgrades[slot_index]
	if slot == null:
		return 0

	var now = Time.get_unix_time_from_system()
	var elapsed = now - slot["start_time"]
	return max(0, slot["duration"] - elapsed)

# === SAVE/LOAD ===
func save_upgrade_state() -> void:
	var data = {
		"active_upgrades": active_upgrades,
		"completed_upgrades": completed_upgrades,
		"unlocked_upgrades": unlocked_upgrades,
	}

	var file = FileAccess.open("user://software_upgrades.save", FileAccess.WRITE)
	if file == null:
		push_error("Failed to save software upgrades: " + str(FileAccess.get_open_error()))
		return

	file.store_var(data)
	file.close()
	print("💾 Software upgrades saved")

func load_upgrade_state() -> void:
	if not FileAccess.file_exists("user://software_upgrades.save"):
		print("No software upgrade save found")
		return

	var file = FileAccess.open("user://software_upgrades.save", FileAccess.READ)
	if file == null:
		push_error("Failed to load software upgrades: " + str(FileAccess.get_open_error()))
		return

	var data = file.get_var()
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Software upgrade save corrupted")
		return

	active_upgrades = data.get("active_upgrades", [null, null])
	completed_upgrades = data.get("completed_upgrades", [])
	unlocked_upgrades = data.get("unlocked_upgrades", ["data_analysis_101"])

	print("🔄 Software upgrades loaded")

	# Update any completed upgrades that finished while offline
	update_upgrades()
