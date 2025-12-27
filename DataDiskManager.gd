extends Node

# Data Disk System - Permanent stat buffs from milestone rewards
# Each disk type provides a small permanent boost that stacks with duplicates

# --- SIGNALS ---
signal data_disk_acquired(disk_id: String)
signal data_disk_equipped(disk_id: String)

# --- DATA DISK TYPES ---
# Format: { "id": { "name": "...", "stat": "...", "value": ... } }
const DATA_DISK_TYPES := {
	"damage_amplifier": {
		"name": "Damage Amplifier Disk",
		"description": "+3% Projectile Damage",
		"stat": "projectile_damage",
		"value": 0.03,  # 3% additive bonus
		"icon": "📀",
		"rarity": "common"
	},
	"rapid_fire": {
		"name": "Rapid Fire Disk",
		"description": "+2% Fire Rate",
		"stat": "fire_rate",
		"value": 0.02,
		"icon": "⚡",
		"rarity": "common"
	},
	"critical_analysis": {
		"name": "Critical Analysis Disk",
		"description": "+1% Crit Chance",
		"stat": "crit_chance",
		"value": 1.0,  # +1% absolute
		"icon": "🎯",
		"rarity": "uncommon"
	},
	"critical_overload": {
		"name": "Critical Overload Disk",
		"description": "+5% Crit Damage Multiplier",
		"stat": "crit_damage",
		"value": 0.05,
		"icon": "💥",
		"rarity": "uncommon"
	},
	"reinforced_plating": {
		"name": "Reinforced Plating Disk",
		"description": "+5% Shield Integrity",
		"stat": "shield_integrity",
		"value": 0.05,
		"icon": "🛡️",
		"rarity": "common"
	},
	"adaptive_shielding": {
		"name": "Adaptive Shielding Disk",
		"description": "+3% Shield Regen",
		"stat": "shield_regen",
		"value": 0.03,
		"icon": "🌀",
		"rarity": "common"
	},
	"ablative_armor": {
		"name": "Ablative Armor Disk",
		"description": "+2% Damage Reduction",
		"stat": "damage_reduction",
		"value": 0.02,
		"icon": "🔰",
		"rarity": "uncommon"
	},
	"data_harvester": {
		"name": "Data Harvester Disk",
		"description": "+0.05x DC Multiplier (5%)",
		"stat": "dc_multiplier",
		"value": 0.05,
		"icon": "💾",
		"rarity": "uncommon"
	},
	"archive_optimizer": {
		"name": "Archive Optimizer Disk",
		"description": "+0.05x AT Multiplier (5%)",
		"stat": "at_multiplier",
		"value": 0.05,
		"icon": "📦",
		"rarity": "uncommon"
	},
	"fragment_magnet": {
		"name": "Fragment Magnet Disk",
		"description": "+10% Fragment Drop Rate",
		"stat": "fragment_drop_rate",
		"value": 0.10,
		"icon": "💎",
		"rarity": "rare"
	},
	"structural_weakness": {
		"name": "Structural Weakness Disk",
		"description": "-2% Boss HP",
		"stat": "boss_hp_reduction",
		"value": 0.02,
		"icon": "👑",
		"rarity": "rare"
	},
	"temporal_accelerator": {
		"name": "Temporal Accelerator Disk",
		"description": "+1% Wave Skip Chance",
		"stat": "wave_skip_chance",
		"value": 1.0,  # +1% absolute
		"icon": "⏩",
		"rarity": "rare"
	},
	"fortune_protocol": {
		"name": "Fortune Protocol Disk",
		"description": "+2% Free Upgrade Chance",
		"stat": "free_upgrade_chance",
		"value": 2.0,  # +2% absolute
		"icon": "🍀",
		"rarity": "rare"
	}
}

# --- RARITY WEIGHTS (for random drops) ---
const RARITY_WEIGHTS := {
	"common": 50,    # 50% chance for common disks
	"uncommon": 35,  # 35% chance for uncommon disks
	"rare": 15       # 15% chance for rare disks
}

# --- INVENTORY ---
# Format: { "disk_id": count }
var data_disk_inventory: Dictionary = {}

# --- EQUIPPED DISKS (for display/active tracking) ---
# All disks are automatically active when acquired
var equipped_disks: Array = []  # Array of disk_ids in order acquired

# --- INITIALIZATION ---
func _ready() -> void:
	load_data_disks()

# --- ADD DATA DISK ---
func add_data_disk(disk_id: String) -> bool:
	if not DATA_DISK_TYPES.has(disk_id):
		push_error("❌ Invalid data disk ID: %s" % disk_id)
		return false

	# Add to inventory (or increment count)
	if disk_id in data_disk_inventory:
		data_disk_inventory[disk_id] += 1
	else:
		data_disk_inventory[disk_id] = 1
		equipped_disks.append(disk_id)  # Track first acquisition

	# Apply buff immediately
	_apply_disk_buffs()

	save_data_disks()
	emit_signal("data_disk_acquired", disk_id)

	var disk_data = DATA_DISK_TYPES[disk_id]
	print("📀 Acquired: %s (Total: %d)" % [disk_data["name"], data_disk_inventory[disk_id]])

	return true

# --- GET RANDOM DISK ID ---
func get_random_disk_id() -> String:
	# Build weighted list based on rarity
	var weighted_list = []

	for disk_id in DATA_DISK_TYPES.keys():
		var rarity = DATA_DISK_TYPES[disk_id]["rarity"]
		var weight = RARITY_WEIGHTS.get(rarity, 1)

		for i in range(weight):
			weighted_list.append(disk_id)

	if weighted_list.is_empty():
		return "damage_amplifier"  # Fallback

	return weighted_list[randi() % weighted_list.size()]

# --- APPLY DISK BUFFS ---
# Recalculate all buffs from owned disks
func _apply_disk_buffs() -> void:
	# Reset buffs (we'll recalculate from scratch)
	var buffs = {
		"projectile_damage": 0.0,
		"fire_rate": 0.0,
		"crit_chance": 0.0,
		"crit_damage": 0.0,
		"shield_integrity": 0.0,
		"shield_regen": 0.0,
		"damage_reduction": 0.0,
		"dc_multiplier": 0.0,
		"at_multiplier": 0.0,
		"fragment_drop_rate": 0.0,
		"boss_hp_reduction": 0.0,
		"wave_skip_chance": 0.0,
		"free_upgrade_chance": 0.0
	}

	# Calculate buffs from inventory
	for disk_id in data_disk_inventory.keys():
		var count = data_disk_inventory[disk_id]
		var disk_data = DATA_DISK_TYPES.get(disk_id, {})

		if disk_data.is_empty():
			continue

		var stat = disk_data.get("stat", "")
		var value = disk_data.get("value", 0.0)

		if stat in buffs:
			buffs[stat] += value * count

	# TODO: Apply buffs to appropriate managers
	# For now, we'll store them and expose getters
	# These will be consumed by UpgradeManager and RewardManager

# --- GETTERS FOR BUFFS ---
func get_projectile_damage_buff() -> float:
	return _calculate_buff("projectile_damage")

func get_fire_rate_buff() -> float:
	return _calculate_buff("fire_rate")

func get_crit_chance_buff() -> float:
	return _calculate_buff("crit_chance")

func get_crit_damage_buff() -> float:
	return _calculate_buff("crit_damage")

func get_shield_integrity_buff() -> float:
	return _calculate_buff("shield_integrity")

func get_shield_regen_buff() -> float:
	return _calculate_buff("shield_regen")

func get_damage_reduction_buff() -> float:
	return _calculate_buff("damage_reduction")

func get_dc_multiplier_buff() -> float:
	return _calculate_buff("dc_multiplier")

func get_at_multiplier_buff() -> float:
	return _calculate_buff("at_multiplier")

func get_fragment_drop_rate_buff() -> float:
	return _calculate_buff("fragment_drop_rate")

func get_boss_hp_reduction_buff() -> float:
	return _calculate_buff("boss_hp_reduction")

func get_wave_skip_chance_buff() -> float:
	return _calculate_buff("wave_skip_chance")

func get_free_upgrade_chance_buff() -> float:
	return _calculate_buff("free_upgrade_chance")

func _calculate_buff(stat: String) -> float:
	var total = 0.0

	for disk_id in data_disk_inventory.keys():
		var count = data_disk_inventory[disk_id]
		var disk_data = DATA_DISK_TYPES.get(disk_id, {})

		if disk_data.is_empty():
			continue

		if disk_data.get("stat", "") == stat:
			total += disk_data.get("value", 0.0) * count

	return total

# --- INVENTORY QUERIES ---
func get_disk_count(disk_id: String) -> int:
	return data_disk_inventory.get(disk_id, 0)

func get_total_disk_count() -> int:
	var total = 0
	for count in data_disk_inventory.values():
		total += count
	return total

func get_unique_disk_count() -> int:
	return data_disk_inventory.size()

func get_all_owned_disks() -> Array:
	var disks = []
	for disk_id in data_disk_inventory.keys():
		var count = data_disk_inventory[disk_id]
		var disk_data = DATA_DISK_TYPES.get(disk_id, {}).duplicate()
		disk_data["id"] = disk_id
		disk_data["count"] = count
		disks.append(disk_data)
	return disks

# --- SAVE/LOAD ---
func save_data_disks() -> void:
	var save_data = {
		"data_disk_inventory": data_disk_inventory,
		"equipped_disks": equipped_disks
	}

	var save_path = "user://data_disks.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("💾 Data disks saved")
	else:
		push_error("❌ Failed to save data disks")

func load_data_disks() -> void:
	var save_path = "user://data_disks.save"
	if not FileAccess.file_exists(save_path):
		print("📂 No data disk save file found, starting fresh")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		data_disk_inventory = save_data.get("data_disk_inventory", {})
		equipped_disks = save_data.get("equipped_disks", [])

		# Apply buffs on load
		_apply_disk_buffs()

		print("✅ Data disks loaded (%d unique, %d total)" % [get_unique_disk_count(), get_total_disk_count()])
	else:
		push_error("❌ Failed to load data disks")

# --- DEBUG/TESTING ---
func grant_test_disks() -> void:
	# Give one of each common disk for testing
	for disk_id in DATA_DISK_TYPES.keys():
		if DATA_DISK_TYPES[disk_id]["rarity"] == "common":
			add_data_disk(disk_id)
