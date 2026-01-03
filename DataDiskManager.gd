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
	},
	# --- Additional Common Disks ---
	"velocity_core": {
		"name": "Velocity Core Disk",
		"description": "+4% Projectile Speed",
		"stat": "projectile_speed",
		"value": 0.04,
		"icon": "🚀",
		"rarity": "common"
	},
	"multi_strike": {
		"name": "Multi-Strike Disk",
		"description": "+3% Multi-Target Damage",
		"stat": "multi_target_damage",
		"value": 0.03,
		"icon": "🎯",
		"rarity": "common"
	},
	"economy_boost": {
		"name": "Economy Boost Disk",
		"description": "+2% Starting Currency",
		"stat": "starting_currency",
		"value": 0.02,
		"icon": "💰",
		"rarity": "common"
	},
	# --- Additional Uncommon Disks ---
	"piercing_edge": {
		"name": "Piercing Edge Disk",
		"description": "+1 Piercing",
		"stat": "piercing",
		"value": 1.0,  # +1 pierce per disk
		"icon": "🗡️",
		"rarity": "uncommon"
	},
	"overkill_amplifier": {
		"name": "Overkill Amplifier Disk",
		"description": "+10% Overkill Damage",
		"stat": "overkill_damage",
		"value": 0.10,
		"icon": "💢",
		"rarity": "uncommon"
	},
	"boss_hunter": {
		"name": "Boss Hunter Disk",
		"description": "+5% Damage vs Bosses",
		"stat": "boss_damage",
		"value": 0.05,
		"icon": "🎯",
		"rarity": "uncommon"
	},
	"quantum_efficiency": {
		"name": "Quantum Efficiency Disk",
		"description": "+0.03x QC Multiplier (3%)",
		"stat": "qc_multiplier",
		"value": 0.03,
		"icon": "🔮",
		"rarity": "uncommon"
	},
	"lab_accelerator": {
		"name": "Lab Accelerator Disk",
		"description": "+5% Lab Speed",
		"stat": "lab_speed",
		"value": 0.05,
		"icon": "🔬",
		"rarity": "uncommon"
	},
	# --- Additional Rare Disks ---
	"ricochet_core": {
		"name": "Ricochet Core Disk",
		"description": "+2% Ricochet Chance",
		"stat": "ricochet_chance",
		"value": 2.0,  # +2% absolute
		"icon": "🔄",
		"rarity": "rare"
	},
	"lucky_strike": {
		"name": "Lucky Strike Disk",
		"description": "+3% Lucky Drops",
		"stat": "lucky_drops",
		"value": 3.0,  # +3% absolute
		"icon": "✨",
		"rarity": "rare"
	},
	"precision_matrix": {
		"name": "Precision Matrix Disk",
		"description": "+3% Crit Chance + 5% Crit Damage",
		"stat": "precision",
		"value": 1.0,  # Special multi-stat disk
		"icon": "🎯",
		"rarity": "rare"
	},
	"block_master": {
		"name": "Block Master Disk",
		"description": "+1% Block Chance",
		"stat": "block_chance",
		"value": 1.0,  # +1% absolute
		"icon": "🛡️",
		"rarity": "rare"
	},
	# --- Epic Disks (Very Rare, Powerful) ---
	"overshield_generator": {
		"name": "Overshield Generator Disk",
		"description": "+8% Overshield Capacity",
		"stat": "overshield_capacity",
		"value": 0.08,  # 8% multiplicative
		"icon": "💠",
		"rarity": "epic"
	},
	"devastator_core": {
		"name": "Devastator Core Disk",
		"description": "+10% Damage + 10% Crit Damage",
		"stat": "devastator",
		"value": 1.0,  # Special multi-stat disk
		"icon": "⭐",
		"rarity": "epic"
	},
	"resource_multiplier": {
		"name": "Resource Multiplier Disk",
		"description": "+8% ALL Currency Drops",
		"stat": "all_currency",
		"value": 0.08,
		"icon": "💸",
		"rarity": "epic"
	},
	"boss_slayer": {
		"name": "Boss Slayer Disk",
		"description": "-5% Boss HP + 10% Boss Damage",
		"stat": "boss_slayer",
		"value": 1.0,  # Special multi-stat disk
		"icon": "⚔️",
		"rarity": "epic"
	},
	# --- Additional Duplicate Disks (for milestone rewards) ---
	# More Damage variants
	"power_core": {
		"name": "Power Core Disk",
		"description": "+3% Projectile Damage",
		"stat": "projectile_damage",
		"value": 0.03,
		"icon": "🔥",
		"rarity": "common"
	},
	"assault_protocol": {
		"name": "Assault Protocol Disk",
		"description": "+3% Projectile Damage",
		"stat": "projectile_damage",
		"value": 0.03,
		"icon": "💢",
		"rarity": "common"
	},
	"annihilation_matrix": {
		"name": "Annihilation Matrix Disk",
		"description": "+3% Projectile Damage",
		"stat": "projectile_damage",
		"value": 0.03,
		"icon": "☄️",
		"rarity": "uncommon"
	},
	# More Fire Rate variants
	"hypervelocity": {
		"name": "Hypervelocity Disk",
		"description": "+2% Fire Rate",
		"stat": "fire_rate",
		"value": 0.02,
		"icon": "⚡",
		"rarity": "common"
	},
	"cascade_trigger": {
		"name": "Cascade Trigger Disk",
		"description": "+2% Fire Rate",
		"stat": "fire_rate",
		"value": 0.02,
		"icon": "🌩️",
		"rarity": "common"
	},
	"quantum_accelerator": {
		"name": "Quantum Accelerator Disk",
		"description": "+2% Fire Rate",
		"stat": "fire_rate",
		"value": 0.02,
		"icon": "⚡",
		"rarity": "uncommon"
	},
	# More Crit variants
	"tactical_scanner": {
		"name": "Tactical Scanner Disk",
		"description": "+1% Crit Chance",
		"stat": "crit_chance",
		"value": 1.0,
		"icon": "🔍",
		"rarity": "uncommon"
	},
	"weakpoint_finder": {
		"name": "Weakpoint Finder Disk",
		"description": "+1% Crit Chance",
		"stat": "crit_chance",
		"value": 1.0,
		"icon": "🎯",
		"rarity": "uncommon"
	},
	"lethal_strike": {
		"name": "Lethal Strike Disk",
		"description": "+5% Crit Damage Multiplier",
		"stat": "crit_damage",
		"value": 0.05,
		"icon": "💥",
		"rarity": "uncommon"
	},
	"execution_protocol": {
		"name": "Execution Protocol Disk",
		"description": "+5% Crit Damage Multiplier",
		"stat": "crit_damage",
		"value": 0.05,
		"icon": "⚔️",
		"rarity": "rare"
	},
	# More Defense variants
	"barrier_matrix": {
		"name": "Barrier Matrix Disk",
		"description": "+5% Shield Integrity",
		"stat": "shield_integrity",
		"value": 0.05,
		"icon": "🛡️",
		"rarity": "common"
	},
	"reactive_plating": {
		"name": "Reactive Plating Disk",
		"description": "+5% Shield Integrity",
		"stat": "shield_integrity",
		"value": 0.05,
		"icon": "🔷",
		"rarity": "uncommon"
	},
	"regenerative_field": {
		"name": "Regenerative Field Disk",
		"description": "+3% Shield Regen",
		"stat": "shield_regen",
		"value": 0.03,
		"icon": "✨",
		"rarity": "common"
	},
	"nano_repair": {
		"name": "Nano Repair Disk",
		"description": "+3% Shield Regen",
		"stat": "shield_regen",
		"value": 0.03,
		"icon": "🌀",
		"rarity": "uncommon"
	},
	"hardened_shell": {
		"name": "Hardened Shell Disk",
		"description": "+2% Damage Reduction",
		"stat": "damage_reduction",
		"value": 0.02,
		"icon": "💠",
		"rarity": "uncommon"
	},
	# More Currency variants
	"credit_optimizer": {
		"name": "Credit Optimizer Disk",
		"description": "+0.05x DC Multiplier (5%)",
		"stat": "dc_multiplier",
		"value": 0.05,
		"icon": "💰",
		"rarity": "uncommon"
	},
	"loot_algorithm": {
		"name": "Loot Algorithm Disk",
		"description": "+0.05x DC Multiplier (5%)",
		"stat": "dc_multiplier",
		"value": 0.05,
		"icon": "💾",
		"rarity": "rare"
	},
	"archive_compiler": {
		"name": "Archive Compiler Disk",
		"description": "+0.05x AT Multiplier (5%)",
		"stat": "at_multiplier",
		"value": 0.05,
		"icon": "📚",
		"rarity": "uncommon"
	},
	"data_synthesizer": {
		"name": "Data Synthesizer Disk",
		"description": "+0.05x AT Multiplier (5%)",
		"stat": "at_multiplier",
		"value": 0.05,
		"icon": "📦",
		"rarity": "rare"
	},
	"crystal_collector": {
		"name": "Crystal Collector Disk",
		"description": "+10% Fragment Drop Rate",
		"stat": "fragment_drop_rate",
		"value": 0.10,
		"icon": "💎",
		"rarity": "rare"
	},
	# More Boss variants
	"titan_bane": {
		"name": "Titan Bane Disk",
		"description": "-2% Boss HP",
		"stat": "boss_hp_reduction",
		"value": 0.02,
		"icon": "👑",
		"rarity": "rare"
	},
	"colossus_killer": {
		"name": "Colossus Killer Disk",
		"description": "-2% Boss HP",
		"stat": "boss_hp_reduction",
		"value": 0.02,
		"icon": "⚔️",
		"rarity": "rare"
	},
	# More Special variants
	"time_dilation": {
		"name": "Time Dilation Disk",
		"description": "+1% Wave Skip Chance",
		"stat": "wave_skip_chance",
		"value": 1.0,
		"icon": "⏱️",
		"rarity": "rare"
	},
	"probability_matrix": {
		"name": "Probability Matrix Disk",
		"description": "+2% Free Upgrade Chance",
		"stat": "free_upgrade_chance",
		"value": 2.0,
		"icon": "🎲",
		"rarity": "rare"
	},
	# More Epic multi-stat variants
	"warlord_core": {
		"name": "Warlord Core Disk",
		"description": "+10% Damage + 10% Crit Damage",
		"stat": "devastator",
		"value": 1.0,
		"icon": "🔴",
		"rarity": "epic"
	},
	"juggernaut_plating": {
		"name": "Juggernaut Plating Disk",
		"description": "+8% Overshield Capacity",
		"stat": "overshield_capacity",
		"value": 0.08,
		"icon": "🔵",
		"rarity": "epic"
	},
	"phantom_matrix": {
		"name": "Phantom Matrix Disk",
		"description": "+3% Crit Chance + 5% Crit Damage",
		"stat": "precision",
		"value": 1.0,
		"icon": "👻",
		"rarity": "rare"
	},
	"wealth_amplifier": {
		"name": "Wealth Amplifier Disk",
		"description": "+8% ALL Currency Drops",
		"stat": "all_currency",
		"value": 0.08,
		"icon": "💵",
		"rarity": "epic"
	}
}

# --- RARITY WEIGHTS (for random drops) ---
const RARITY_WEIGHTS := {
	"common": 45,    # 45% chance for common disks
	"uncommon": 35,  # 35% chance for uncommon disks
	"rare": 17,      # 17% chance for rare disks
	"epic": 3        # 3% chance for epic disks
}

# --- INVENTORY ---
# Format: { "disk_id": count }
var data_disk_inventory: Dictionary = {}

# --- EQUIPPED DISKS (for display/active tracking) ---
# All disks are automatically active when acquired
var equipped_disks: Array = []  # Array of disk_ids in order acquired

# --- CACHED BUFFS (for performance) ---
# Recalculated only when disks are added/removed
var _cached_buffs: Dictionary = {}

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

	# Update achievement tracking
	if AchievementManager:
		AchievementManager.update_data_disks_owned(get_unique_disk_count())

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
# Recalculate all buffs from owned disks (called on disk add/load only)
func _apply_disk_buffs() -> void:
	# Reset cached buffs (recalculate from scratch)
	_cached_buffs = {
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
		"free_upgrade_chance": 0.0,
		"overshield_capacity": 0.0,
		"piercing": 0.0,
		"overkill_damage": 0.0,
		"boss_damage": 0.0,
		"qc_multiplier": 0.0,
		"lab_speed": 0.0,
		"ricochet_chance": 0.0,
		"lucky_drops": 0.0,
		"precision": 0.0,
		"block_chance": 0.0,
		"devastator": 0.0,
		"all_currency": 0.0,
		"boss_slayer": 0.0,
		"projectile_speed": 0.0,
		"multi_target_damage": 0.0,
		"starting_currency": 0.0
	}

	# Calculate buffs from inventory (only called when disks change, not per-frame)
	for disk_id in data_disk_inventory.keys():
		var count = data_disk_inventory[disk_id]
		var disk_data = DATA_DISK_TYPES.get(disk_id, {})

		if disk_data.is_empty():
			continue

		var stat = disk_data.get("stat", "")
		var value = disk_data.get("value", 0.0)

		if stat in _cached_buffs:
			_cached_buffs[stat] += value * count

	# Buffs are now cached and will be returned by getters without recalculation

# --- GETTERS FOR BUFFS (cached, O(1) performance) ---
func get_projectile_damage_buff() -> float:
	return _cached_buffs.get("projectile_damage", 0.0)

func get_fire_rate_buff() -> float:
	return _cached_buffs.get("fire_rate", 0.0)

func get_crit_chance_buff() -> float:
	return _cached_buffs.get("crit_chance", 0.0)

func get_crit_damage_buff() -> float:
	return _cached_buffs.get("crit_damage", 0.0)

func get_shield_integrity_buff() -> float:
	return _cached_buffs.get("shield_integrity", 0.0)

func get_shield_regen_buff() -> float:
	return _cached_buffs.get("shield_regen", 0.0)

func get_damage_reduction_buff() -> float:
	return _cached_buffs.get("damage_reduction", 0.0)

func get_dc_multiplier_buff() -> float:
	return _cached_buffs.get("dc_multiplier", 0.0)

func get_at_multiplier_buff() -> float:
	return _cached_buffs.get("at_multiplier", 0.0)

func get_fragment_drop_rate_buff() -> float:
	return _cached_buffs.get("fragment_drop_rate", 0.0)

func get_boss_hp_reduction_buff() -> float:
	return _cached_buffs.get("boss_hp_reduction", 0.0)

func get_wave_skip_chance_buff() -> float:
	return _cached_buffs.get("wave_skip_chance", 0.0)

func get_free_upgrade_chance_buff() -> float:
	return _cached_buffs.get("free_upgrade_chance", 0.0)

func get_overshield_capacity_buff() -> float:
	return _cached_buffs.get("overshield_capacity", 0.0)

# Multi-stat disk support (cached)
func get_devastator_damage_buff() -> float:
	return _cached_buffs.get("devastator", 0.0) * 0.10  # +10% damage per devastator disk

func get_devastator_crit_damage_buff() -> float:
	return _cached_buffs.get("devastator", 0.0) * 0.10  # +10% crit damage per devastator disk

func get_precision_crit_chance_buff() -> float:
	return _cached_buffs.get("precision", 0.0) * 3.0  # +3% crit chance per precision disk

func get_precision_crit_damage_buff() -> float:
	return _cached_buffs.get("precision", 0.0) * 0.05  # +5% crit damage per precision disk

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
	# H-002: Use SaveManager for unified save system
	if SaveManager.simple_save(save_path, save_data):
		print("💾 Data disks saved")
	else:
		push_error("❌ Failed to save data disks")

func load_data_disks() -> void:
	var save_path = "user://data_disks.save"

	# H-002: Use SaveManager for unified save system
	var save_data = SaveManager.simple_load(save_path)

	if save_data.is_empty():
		print("📂 No data disk save file found, starting fresh")
		return

	data_disk_inventory = save_data.get("data_disk_inventory", {})
	equipped_disks = save_data.get("equipped_disks", [])

	# Apply buffs on load
	_apply_disk_buffs()

	print("✅ Data disks loaded (%d unique, %d total)" % [get_unique_disk_count(), get_total_disk_count()])

# --- DEBUG/TESTING ---
func grant_test_disks() -> void:
	# Give one of each common disk for testing
	for disk_id in DATA_DISK_TYPES.keys():
		if DATA_DISK_TYPES[disk_id]["rarity"] == "common":
			add_data_disk(disk_id)
