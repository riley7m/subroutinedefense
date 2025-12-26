extends Node

# Software Upgrade System - Ranked/Leveled Labs
# Each lab has multiple levels (30-100) with incremental bonuses

# Active upgrade slots
const MAX_SLOTS = 2
var active_upgrades: Array = [null, null]  # Each entry is a Dictionary with upgrade data

# Current levels for each lab (0 = not started)
var lab_levels: Dictionary = {
	"damage_processing": 0,
	"fire_rate_optimization": 0,
	"critical_analysis": 0,
	"damage_amplification": 0,
	"shield_matrix": 0,
	"damage_mitigation": 0,
	"shield_regeneration": 0,
	"resource_optimization": 0,
	"archive_efficiency": 0,
	"wave_analysis": 0,
	"probability_matrix": 0,
	"multi_target_systems": 0,
	"piercing_enhancement": 0,
	"overkill_processing": 0,
	"projectile_acceleration": 0,
	"block_systems": 0,
	"block_amplification": 0,
	"boss_resistance_training": 0,
	"overshield_enhancement": 0,
	"boss_targeting": 0,
	"loot_optimization": 0,
	"lab_acceleration": 0,
}

# Lab definitions
var labs: Dictionary = {}

signal upgrade_completed(lab_id: String, new_level: int)
signal upgrade_started(lab_id: String, slot_index: int)
signal upgrades_updated

func _ready() -> void:
	_initialize_labs()
	load_upgrade_state()

func _initialize_labs() -> void:
	labs = {
		"damage_processing": {
			"name": "Damage Processing",
			"description": "Optimize projectile damage algorithms",
			"max_level": 100,
			"base_duration": 3600,  # 1 hour for level 1
			"duration_scaling": 1.05,  # 5% longer each level
			"base_cost_at": 500,  # AT-only cost from level 1
			"cost_scaling": 1.08,  # 8% more expensive each level
			"bonus_per_level": {"projectile_damage_perm": 10},
			"tier": 1,
		},

		"fire_rate_optimization": {
			"name": "Fire Rate Optimization",
			"description": "Increase projectile firing speed",
			"max_level": 100,
			"base_duration": 3600,
			"duration_scaling": 1.05,
			"base_cost_at": 500,
			"cost_scaling": 1.08,
			"bonus_per_level": {"fire_rate_perm": 0.01},
			"tier": 1,
		},

		"critical_analysis": {
			"name": "Critical Analysis",
			"description": "Enhance critical hit probability",
			"max_level": 100,
			"base_duration": 7200,  # 2 hours
			"duration_scaling": 1.06,
			"base_cost_at": 600,
			"cost_scaling": 1.10,
			"bonus_per_level": {"crit_chance_perm": 0.5},  # 0.5% per level
			"tier": 1,
		},

		"damage_amplification": {
			"name": "Damage Amplification",
			"description": "Boost critical hit damage",
			"max_level": 50,
			"base_duration": 14400,  # 4 hours
			"duration_scaling": 1.07,
			"base_cost_at": 1000,
			"cost_scaling": 1.12,
			"bonus_per_level": {"crit_damage_perm": 0.02},  # 2% per level
			"tier": 2,
		},

		"shield_matrix": {
			"name": "Shield Matrix",
			"description": "Fortify shield integrity",
			"max_level": 100,
			"base_duration": 3600,
			"duration_scaling": 1.05,
			"base_cost_at": 500,
			"cost_scaling": 1.08,
			"bonus_per_level": {"shield_integrity_perm": 20},
			"tier": 1,
		},

		"damage_mitigation": {
			"name": "Damage Mitigation",
			"description": "Reduce incoming damage",
			"max_level": 50,
			"base_duration": 14400,  # 4 hours
			"duration_scaling": 1.07,
			"base_cost_at": 1000,
			"cost_scaling": 1.12,
			"bonus_per_level": {"damage_reduction_perm": 0.005},  # 0.5% per level
			"tier": 2,
		},

		"shield_regeneration": {
			"name": "Shield Regeneration",
			"description": "Accelerate shield recovery",
			"max_level": 76,
			"base_duration": 7200,  # 2 hours
			"duration_scaling": 1.06,
			"base_cost_at": 500,
			"cost_scaling": 1.09,
			"bonus_per_level": {"shield_regen_perm": 0.5},
			"tier": 1,
		},

		"resource_optimization": {
			"name": "Resource Optimization",
			"description": "Boost data credit income",
			"max_level": 50,
			"base_duration": 10800,  # 3 hours
			"duration_scaling": 1.08,
			"base_cost_at": 1200,
			"cost_scaling": 1.15,
			"bonus_per_level": {"data_credit_multiplier": 0.01},  # 1% per level
			"tier": 2,
		},

		"archive_efficiency": {
			"name": "Archive Efficiency",
			"description": "Increase archive token income",
			"max_level": 50,
			"base_duration": 10800,  # 3 hours
			"duration_scaling": 1.08,
			"base_cost_at": 1200,
			"cost_scaling": 1.15,
			"bonus_per_level": {"archive_token_multiplier": 0.01},  # 1% per level
			"tier": 2,
		},

		"wave_analysis": {
			"name": "Wave Analysis",
			"description": "Predict and skip waves",
			"max_level": 30,
			"base_duration": 21600,  # 6 hours
			"duration_scaling": 1.10,
			"base_cost_at": 2000,
			"cost_scaling": 1.18,
			"bonus_per_level": {"wave_skip_chance_perm": 0.5},  # 0.5% per level
			"tier": 3,
		},

		"probability_matrix": {
			"name": "Probability Matrix",
			"description": "Free upgrade chance",
			"max_level": 30,
			"base_duration": 21600,  # 6 hours
			"duration_scaling": 1.10,
			"base_cost_at": 2000,
			"cost_scaling": 1.18,
			"bonus_per_level": {"free_upgrade_chance_perm": 0.5},  # 0.5% per level
			"tier": 3,
		},

		"multi_target_systems": {
			"name": "Multi-Target Systems",
			"description": "Enhance multi-target capabilities",
			"max_level": 30,
			"base_duration": 28800,  # 8 hours
			"duration_scaling": 1.12,
			"base_cost_at": 5000,
			"cost_scaling": 1.20,
			"bonus_per_level": {"multi_target_bonus": 0.1},  # 0.1 per level
			"tier": 3,
		},

		"piercing_enhancement": {
			"name": "Piercing Enhancement",
			"description": "Enable projectiles to pierce multiple enemies",
			"max_level": 100,
			"base_duration": 7200,  # 2 hours
			"duration_scaling": 1.06,
			"base_cost_at": 700,
			"cost_scaling": 1.09,
			"bonus_per_level": {"piercing_perm": 1},  # +1 pierce per level
			"tier": 1,
		},

		"overkill_processing": {
			"name": "Overkill Processing",
			"description": "Spread excess damage to nearby enemies",
			"max_level": 50,
			"base_duration": 14400,  # 4 hours
			"duration_scaling": 1.07,
			"base_cost_at": 1000,
			"cost_scaling": 1.12,
			"bonus_per_level": {"overkill_damage_perm": 0.05},  # +5% overkill per level
			"tier": 2,
		},

		"projectile_acceleration": {
			"name": "Projectile Acceleration",
			"description": "Increase projectile travel speed",
			"max_level": 100,
			"base_duration": 3600,  # 1 hour
			"duration_scaling": 1.05,
			"base_cost_at": 400,
			"cost_scaling": 1.07,
			"bonus_per_level": {"projectile_speed_perm": 0.1},  # +10% speed per level
			"tier": 1,
		},

		"block_systems": {
			"name": "Block Systems",
			"description": "Add chance to completely block incoming damage",
			"max_level": 75,
			"base_duration": 7200,  # 2 hours
			"duration_scaling": 1.06,
			"base_cost_at": 700,
			"cost_scaling": 1.09,
			"bonus_per_level": {"block_chance_perm": 1.0},  # +1% block chance per level
			"tier": 1,
		},

		"block_amplification": {
			"name": "Block Amplification",
			"description": "Increase amount of damage blocked per successful block",
			"max_level": 100,
			"base_duration": 5400,  # 1.5 hours
			"duration_scaling": 1.055,
			"base_cost_at": 500,
			"cost_scaling": 1.08,
			"bonus_per_level": {"block_amount_perm": 5},  # +5 damage blocked per level
			"tier": 1,
		},

		"boss_resistance_training": {
			"name": "Boss Resistance Training",
			"description": "Reduce damage taken from boss enemies",
			"max_level": 50,
			"base_duration": 18000,  # 5 hours
			"duration_scaling": 1.08,
			"base_cost_at": 1500,
			"cost_scaling": 1.14,
			"bonus_per_level": {"boss_resistance_perm": 1.0},  # +1% boss resistance per level
			"tier": 2,
		},

		"overshield_enhancement": {
			"name": "Overshield Enhancement",
			"description": "Add extra shield layer beyond base shield",
			"max_level": 100,
			"base_duration": 3600,  # 1 hour
			"duration_scaling": 1.05,
			"base_cost_at": 500,
			"cost_scaling": 1.08,
			"bonus_per_level": {"overshield_perm": 15},  # +15 overshield per level
			"tier": 1,
		},

		"boss_targeting": {
			"name": "Boss Targeting",
			"description": "Optimize damage output against bosses",
			"max_level": 50,
			"base_duration": 14400,  # 4 hours
			"duration_scaling": 1.07,
			"base_cost_at": 1000,
			"cost_scaling": 1.12,
			"bonus_per_level": {"boss_bonus_perm": 0.05},  # +5% boss damage per level
			"tier": 2,
		},

		"loot_optimization": {
			"name": "Loot Optimization",
			"description": "Increase chance for extra rewards",
			"max_level": 50,
			"base_duration": 10800,  # 3 hours
			"duration_scaling": 1.08,
			"base_cost_at": 1200,
			"cost_scaling": 1.15,
			"bonus_per_level": {"lucky_drops_perm": 0.5},  # +0.5% lucky drops per level
			"tier": 2,
		},

		"lab_acceleration": {
			"name": "Lab Acceleration",
			"description": "Reduce lab completion time",
			"max_level": 50,
			"base_duration": 21600,  # 6 hours
			"duration_scaling": 1.10,
			"base_cost_at": 2000,
			"cost_scaling": 1.16,
			"bonus_per_level": {"lab_speed_perm": 1.0},  # +1% lab speed per level
			"tier": 3,
		},
	}

func get_level(lab_id: String) -> int:
	return lab_levels.get(lab_id, 0)

func get_max_level(lab_id: String) -> int:
	if not labs.has(lab_id):
		return 0
	return labs[lab_id]["max_level"]

func is_maxed(lab_id: String) -> bool:
	return get_level(lab_id) >= get_max_level(lab_id)

func get_duration_for_level(lab_id: String, level: int) -> int:
	if not labs.has(lab_id):
		return 0

	var lab = labs[lab_id]
	var base = lab["base_duration"]
	var scaling = lab["duration_scaling"]

	# Duration = base * (scaling ^ (level - 1))
	var duration = base * pow(scaling, level - 1)

	# Apply lab acceleration (reduces duration by perm_lab_speed %)
	# Example: 10% lab speed = duration / 1.10 = 0.909x duration (9.1% reduction)
	var lab_speed_multiplier = 1.0 + (RewardManager.perm_lab_speed / 100.0)
	duration = duration / lab_speed_multiplier

	return int(duration)

func get_cost_for_level(lab_id: String, level: int) -> int:
	if not labs.has(lab_id):
		return 0

	var lab = labs[lab_id]
	var base_at = lab["base_cost_at"]
	var scaling = lab["cost_scaling"]

	# Cost = base_at * (scaling ^ (level - 1))
	var at_cost = int(base_at * pow(scaling, level - 1))

	return at_cost

func can_start_upgrade(lab_id: String) -> bool:
	# Check if lab exists
	if not labs.has(lab_id):
		return false

	# Check if maxed
	if is_maxed(lab_id):
		return false

	# Check if already in progress
	for slot in active_upgrades:
		if slot != null and slot["id"] == lab_id:
			return false

	# Check cost for next level
	var next_level = get_level(lab_id) + 1
	var cost = get_cost_for_level(lab_id, next_level)

	# Only check AT cost
	if cost > RewardManager.archive_tokens:
		return false

	return true

func start_upgrade(lab_id: String, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false

	if active_upgrades[slot_index] != null:
		return false

	if not can_start_upgrade(lab_id):
		return false

	var lab = labs[lab_id]
	var next_level = get_level(lab_id) + 1
	var cost = get_cost_for_level(lab_id, next_level)
	var duration = get_duration_for_level(lab_id, next_level)

	# Deduct AT cost
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_lab(cost)  # Track lifetime AT spent on labs

	# Start upgrade
	active_upgrades[slot_index] = {
		"id": lab_id,
		"start_time": Time.get_unix_time_from_system(),
		"duration": duration,
		"target_level": next_level,
	}

	emit_signal("upgrade_started", lab_id, slot_index)
	emit_signal("upgrades_updated")
	save_upgrade_state()

	print("🔬 Started %s level %d (slot %d) - Cost: %d AT" % [lab["name"], next_level, slot_index, cost])
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

	var lab_id = slot["id"]
	var new_level = slot["target_level"]
	var lab = labs[lab_id]

	# Set new level
	lab_levels[lab_id] = new_level

	# Apply bonuses
	_apply_level_bonuses(lab)

	# Clear slot
	active_upgrades[slot_index] = null

	emit_signal("upgrade_completed", lab_id, new_level)
	save_upgrade_state()

	print("✅ Completed %s level %d" % [lab["name"], new_level])

func _apply_level_bonuses(lab: Dictionary) -> void:
	var bonuses = lab.get("bonus_per_level", {})

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
			"multi_target_bonus":
				pass  # Not currently stored in RewardManager
			"piercing_perm":
				RewardManager.perm_piercing += value
			"overkill_damage_perm":
				RewardManager.perm_overkill_damage += value
			"projectile_speed_perm":
				RewardManager.perm_projectile_speed += value
			"block_chance_perm":
				RewardManager.perm_block_chance += value
			"block_amount_perm":
				RewardManager.perm_block_amount += value
			"boss_resistance_perm":
				RewardManager.perm_boss_resistance += value
			"overshield_perm":
				RewardManager.perm_overshield += value
			"boss_bonus_perm":
				RewardManager.perm_boss_bonus += value
			"lucky_drops_perm":
				RewardManager.perm_lucky_drops += value
			"lab_speed_perm":
				RewardManager.perm_lab_speed += value  # +1% lab speed per level

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

func get_total_bonus(lab_id: String) -> Dictionary:
	var level = get_level(lab_id)
	if level == 0 or not labs.has(lab_id):
		return {}

	var lab = labs[lab_id]
	var bonus_per = lab.get("bonus_per_level", {})
	var result = {}

	for key in bonus_per.keys():
		result[key] = bonus_per[key] * level

	return result

# === SAVE/LOAD ===
const LAB_SAVE_FILE = "user://software_upgrades.save"
const LAB_SAVE_FILE_TEMP = "user://software_upgrades.save.tmp"
const LAB_SAVE_FILE_BACKUP = "user://software_upgrades.save.backup"

func save_upgrade_state() -> bool:
	var data = {
		"active_upgrades": active_upgrades,
		"lab_levels": lab_levels,
	}

	# ATOMIC SAVE WITH BACKUP
	# Step 1: Backup existing save
	if FileAccess.file_exists(LAB_SAVE_FILE):
		var dir = DirAccess.open("user://")
		if dir:
			if FileAccess.file_exists(LAB_SAVE_FILE_BACKUP):
				dir.remove(LAB_SAVE_FILE_BACKUP)
			dir.copy(LAB_SAVE_FILE, LAB_SAVE_FILE_BACKUP)

	# Step 2: Write to temp file
	var file = FileAccess.open(LAB_SAVE_FILE_TEMP, FileAccess.WRITE)
	if file == null:
		push_error("❌ Failed to save software upgrades: " + str(FileAccess.get_open_error()))
		return false
	file.store_var(data)
	file.close()

	# Step 3: Verify temp file
	file = FileAccess.open(LAB_SAVE_FILE_TEMP, FileAccess.READ)
	if file == null or typeof(file.get_var()) != TYPE_DICTIONARY:
		push_error("❌ Lab save verification failed!")
		return false
	file.close()

	# Step 4: Atomic rename
	var dir = DirAccess.open("user://")
	if not dir:
		return false
	if FileAccess.file_exists(LAB_SAVE_FILE):
		dir.remove(LAB_SAVE_FILE)
	dir.rename(LAB_SAVE_FILE_TEMP, LAB_SAVE_FILE)

	print("💾 Software upgrades saved (atomic)")
	return true

func load_upgrade_state() -> void:
	# Try main save, then backup if corrupted
	var files_to_try = [LAB_SAVE_FILE, LAB_SAVE_FILE_BACKUP]

	for save_file_path in files_to_try:
		if not FileAccess.file_exists(save_file_path):
			continue

		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file == null:
			continue

		var data = file.get_var()
		file.close()

		if typeof(data) != TYPE_DICTIONARY:
			continue

		# Successfully loaded
		if save_file_path == LAB_SAVE_FILE_BACKUP:
			print("⚠️ Lab save corrupted, loaded from backup!")

		active_upgrades = data.get("active_upgrades", [null, null])
		lab_levels = data.get("lab_levels", {})

		print("🔄 Software upgrades loaded")
		# Update any completed upgrades that finished while offline
		update_upgrades()
		return

	print("No software upgrade save found")
