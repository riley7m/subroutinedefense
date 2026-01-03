extends Node

# Drone Upgrade System
# Fragment-based upgrades for 4 unique drones (Flame, Poison, Frost, Shock)
# Total cost: ~17.84M fragments for full upgrades

# --- SIGNALS ---
signal upgrade_purchased(upgrade_type: String, drone_type: String, new_level: int)
signal active_slot_unlocked(slot_number: int)

# --- DRONE TYPES ---
const DRONE_TYPES := ["flame", "poison", "frost", "shock"]

# --- ACTIVE DRONE SLOTS ---
const MAX_ACTIVE_SLOTS := 4

const ACTIVE_SLOT_COSTS := {
	2: 50000,
	3: 250000,
	4: 1000000
}

# --- DRONE LEVEL UPGRADE COSTS (Individual per drone) ---
# Level 1 is default, levels 2-10 are upgradeable
const DRONE_LEVEL_COSTS := {
	2: 6250,
	3: 12500,
	4: 25000,
	5: 50000,
	6: 100000,
	7: 200000,
	8: 375000,
	9: 625000,
	10: 1000000
}

# --- FLAME DRONE SPECIFIC UPGRADES ---
const FLAME_TICK_RATE_COSTS := {
	1: 20000, 2: 30000, 3: 45000, 4: 70000, 5: 105000,
	6: 155000, 7: 230000, 8: 295000, 9: 370000, 10: 230000
}

const FLAME_HP_CAP_COSTS := {
	1: 25000, 2: 40000, 3: 65000, 4: 100000, 5: 155000,
	6: 235000, 7: 355000, 8: 450000, 9: 515000, 10: 185000
}

# --- POISON DRONE SPECIFIC UPGRADES ---
const POISON_DURATION_COSTS := {
	1: 15000, 2: 25000, 3: 40000, 4: 65000, 5: 95000,
	6: 140000, 7: 200000, 8: 260000, 9: 280000, 10: 120000
}

const POISON_STACKING_COSTS := {
	1: 300000  # Only 1 level (unlocks 2 stacks max)
}

# --- FROST DRONE SPECIFIC UPGRADES ---
const FROST_AOE_COSTS := {
	1: 300000  # Only 1 level (unlocks 2 targets)
}

const FROST_DURATION_COSTS := {
	1: 60000, 2: 95000, 3: 140000, 4: 195000, 5: 260000,
	6: 335000, 7: 420000, 8: 515000, 9: 375000, 10: 105000
}

# --- SHOCK DRONE SPECIFIC UPGRADES ---
const SHOCK_CHAIN_COSTS := {
	1: 600000  # Only 1 level (unlocks +1 chain = 2 total)
}

const SHOCK_DURATION_COSTS := {
	1: 30000, 2: 50000, 3: 75000, 4: 110000, 5: 160000,
	6: 225000, 7: 305000, 8: 400000, 9: 510000, 10: 260000
}

# --- PLAYER PROGRESS ---
var active_slots_unlocked: int = 1  # Start with 1 slot

var drone_levels: Dictionary = {
	"flame": 1,
	"poison": 1,
	"frost": 1,
	"shock": 1
}

var flame_upgrades: Dictionary = {
	"tick_rate": 0,  # 0-10
	"hp_cap": 0      # 0-10
}

var poison_upgrades: Dictionary = {
	"duration": 0,   # 0-10
	"stacking": 0    # 0-1
}

var frost_upgrades: Dictionary = {
	"aoe": 0,        # 0-1
	"duration": 0    # 0-10
}

var shock_upgrades: Dictionary = {
	"chain": 0,      # 0-1
	"duration": 0    # 0-10
}

# --- PROPERTY ACCESSORS (for UI convenience) ---
var active_drone_slots: int:
	get:
		return active_slots_unlocked

var flame_tick_rate_level: int:
	get:
		return flame_upgrades["tick_rate"]

var flame_hp_cap_level: int:
	get:
		return flame_upgrades["hp_cap"]

var poison_duration_level: int:
	get:
		return poison_upgrades["duration"]

var poison_stacking_level: int:
	get:
		return poison_upgrades["stacking"]

var frost_aoe_level: int:
	get:
		return frost_upgrades["aoe"]

var frost_duration_level: int:
	get:
		return frost_upgrades["duration"]

var shock_chain_level: int:
	get:
		return shock_upgrades["chain"]

var shock_duration_level: int:
	get:
		return shock_upgrades["duration"]

# --- INITIALIZATION ---
func _ready() -> void:
	load_drone_upgrades()

# --- ACTIVE SLOT UNLOCKING ---
func unlock_active_slot(slot_number: int) -> bool:
	if slot_number <= active_slots_unlocked:
		print("❌ Slot %d already unlocked!" % slot_number)
		return false

	if slot_number > MAX_ACTIVE_SLOTS:
		print("❌ Max slots reached!")
		return false

	if not ACTIVE_SLOT_COSTS.has(slot_number):
		print("❌ Invalid slot number: %d" % slot_number)
		return false

	var cost = ACTIVE_SLOT_COSTS[slot_number]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	# Deduct fragments
	RewardManager.fragments -= cost
	active_slots_unlocked = slot_number

	save_drone_upgrades()
	emit_signal("active_slot_unlocked", slot_number)

	print("✅ Unlocked drone slot %d for %d fragments!" % [slot_number, cost])
	return true

# --- DRONE LEVEL UPGRADES ---
func upgrade_drone_level(drone_type: String) -> bool:
	if not drone_type in DRONE_TYPES:
		push_error("❌ Invalid drone type: %s" % drone_type)
		return false

	var current_level = drone_levels[drone_type]
	if current_level >= 10:
		print("❌ %s drone already at max level!" % drone_type.capitalize())
		return false

	var next_level = current_level + 1
	var cost = DRONE_LEVEL_COSTS[next_level]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	# Deduct fragments
	RewardManager.fragments -= cost
	drone_levels[drone_type] = next_level

	# Apply upgrade to actual drones in game
	_apply_drone_level_upgrade(drone_type, next_level)

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "level", drone_type, next_level)

	print("✅ %s Drone upgraded to Level %d for %d fragments!" % [drone_type.capitalize(), next_level, cost])
	return true

# --- FLAME SPECIFIC UPGRADES ---
func upgrade_flame_tick_rate() -> bool:
	var current_level = flame_upgrades["tick_rate"]
	if current_level >= 10:
		print("❌ Flame tick rate already maxed!")
		return false

	var next_level = current_level + 1
	var cost = FLAME_TICK_RATE_COSTS[next_level]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	flame_upgrades["tick_rate"] = next_level

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "tick_rate", "flame", next_level)

	print("✅ Flame tick rate upgraded to Level %d for %d fragments!" % [next_level, cost])
	return true

func upgrade_flame_hp_cap() -> bool:
	var current_level = flame_upgrades["hp_cap"]
	if current_level >= 10:
		print("❌ Flame HP cap already maxed!")
		return false

	var next_level = current_level + 1
	var cost = FLAME_HP_CAP_COSTS[next_level]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	flame_upgrades["hp_cap"] = next_level

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "hp_cap", "flame", next_level)

	print("✅ Flame HP cap upgraded to Level %d for %d fragments!" % [next_level, cost])
	return true

# --- POISON SPECIFIC UPGRADES ---
func upgrade_poison_duration() -> bool:
	var current_level = poison_upgrades["duration"]
	if current_level >= 10:
		print("❌ Poison duration already maxed!")
		return false

	var next_level = current_level + 1
	var cost = POISON_DURATION_COSTS[next_level]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	poison_upgrades["duration"] = next_level

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "duration", "poison", next_level)

	print("✅ Poison duration upgraded to Level %d for %d fragments!" % [next_level, cost])
	return true

func upgrade_poison_stacking() -> bool:
	var current_level = poison_upgrades["stacking"]
	if current_level >= 1:
		print("❌ Poison stacking already unlocked!")
		return false

	var cost = POISON_STACKING_COSTS[1]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	poison_upgrades["stacking"] = 1

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "stacking", "poison", 1)

	print("✅ Poison stacking unlocked for %d fragments! (Max 2 stacks)" % cost)
	return true

# --- FROST SPECIFIC UPGRADES ---
func upgrade_frost_aoe() -> bool:
	var current_level = frost_upgrades["aoe"]
	if current_level >= 1:
		print("❌ Frost AOE already unlocked!")
		return false

	var cost = FROST_AOE_COSTS[1]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	frost_upgrades["aoe"] = 1

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "aoe", "frost", 1)

	print("✅ Frost AOE unlocked for %d fragments! (2 targets)" % cost)
	return true

func upgrade_frost_duration() -> bool:
	var current_level = frost_upgrades["duration"]
	if current_level >= 10:
		print("❌ Frost duration already maxed!")
		return false

	var next_level = current_level + 1
	var cost = FROST_DURATION_COSTS[next_level]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	frost_upgrades["duration"] = next_level

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "duration", "frost", next_level)

	print("✅ Frost duration upgraded to Level %d for %d fragments!" % [next_level, cost])
	return true

# --- SHOCK SPECIFIC UPGRADES ---
func upgrade_shock_chain() -> bool:
	var current_level = shock_upgrades["chain"]
	if current_level >= 1:
		print("❌ Shock chain already unlocked!")
		return false

	var cost = SHOCK_CHAIN_COSTS[1]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	shock_upgrades["chain"] = 1

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "chain", "shock", 1)

	print("✅ Shock chain unlocked for %d fragments! (+1 chain = 2 total)" % cost)
	return true

func upgrade_shock_duration() -> bool:
	var current_level = shock_upgrades["duration"]
	if current_level >= 10:
		print("❌ Shock duration already maxed!")
		return false

	var next_level = current_level + 1
	var cost = SHOCK_DURATION_COSTS[next_level]

	if RewardManager.fragments < cost:
		print("❌ Not enough fragments! Need %d, have %d" % [cost, RewardManager.fragments])
		return false

	RewardManager.fragments -= cost
	shock_upgrades["duration"] = next_level

	save_drone_upgrades()
	emit_signal("upgrade_purchased", "duration", "shock", next_level)

	print("✅ Shock duration upgraded to Level %d for %d fragments!" % [next_level, cost])
	return true

# --- QUERY FUNCTIONS ---
func get_active_slots() -> int:
	return active_slots_unlocked

func get_drone_level(drone_type: String) -> int:
	return drone_levels.get(drone_type, 1)

# Flame bonuses
func get_flame_tick_rate() -> float:
	# Base: 1.0s, Max: 0.5s (10 levels, -0.05s per level)
	var level = flame_upgrades["tick_rate"]
	return 1.0 - (level * 0.05)

func get_flame_hp_cap() -> float:
	# Base: 10%, Max: 25% (10 levels, +1.5% per level)
	var level = flame_upgrades["hp_cap"]
	return 0.10 + (level * 0.015)

# Poison bonuses
func get_poison_duration() -> float:
	# Base: 4s, Max: 6s (10 levels, +0.2s per level)
	var level = poison_upgrades["duration"]
	return 4.0 + (level * 0.2)

func get_poison_max_stacks() -> int:
	# Base: 1 stack, Max: 2 stacks
	return 1 + poison_upgrades["stacking"]

func get_poison_max_dps_percent() -> float:
	# Level 10 = 7.5% HP per second per stack
	# With 2 stacks = 15% HP/sec
	# Over 6 seconds = 90% total HP (capped)
	var drone_level = drone_levels["poison"]
	var base_percent = 0.01  # 1% at level 1
	var max_percent = 0.075  # 7.5% at level 10
	var percent_per_level = (max_percent - base_percent) / 9.0
	return base_percent + ((drone_level - 1) * percent_per_level)

# Frost bonuses
func get_frost_max_targets() -> int:
	# Base: 1 target, Max: 2 targets
	return 1 + frost_upgrades["aoe"]

func get_frost_duration() -> float:
	# Base: 2s, Max: 2.5s (10 levels, +0.05s per level)
	var level = frost_upgrades["duration"]
	return 2.0 + (level * 0.05)

func get_frost_slow_cap() -> float:
	# Frost slow is capped at 75% (0.75) in code
	# This is applied in enemy.gd, not here
	return 0.75

# Shock bonuses
func get_shock_max_targets() -> int:
	# Base: 1 target, Max: 2 targets (+1 chain)
	return 1 + shock_upgrades["chain"]

func get_shock_duration_bonus() -> float:
	# Base: 0s bonus, Max: +0.5s (10 levels, +0.05s per level)
	var level = shock_upgrades["duration"]
	return level * 0.05

# --- APPLY UPGRADES TO DRONES ---
func _apply_drone_level_upgrade(drone_type: String, level: int) -> void:
	# Find all active drones of this type and update their level
	var drones = get_tree().get_nodes_in_group("drones")
	for drone in drones:
		if not is_instance_valid(drone):
			continue
		if "drone_type" in drone and drone.drone_type == drone_type:
			if drone.has_method("apply_upgrade"):
				drone.apply_upgrade(level)

# --- SAVE/LOAD ---
func save_drone_upgrades() -> void:
	var save_data = {
		"active_slots_unlocked": active_slots_unlocked,
		"drone_levels": drone_levels,
		"flame_upgrades": flame_upgrades,
		"poison_upgrades": poison_upgrades,
		"frost_upgrades": frost_upgrades,
		"shock_upgrades": shock_upgrades
	}

	var save_path = "user://drone_upgrades.save"
	# H-002: Use SaveManager for unified save system
	if SaveManager.simple_save(save_path, save_data):
		print("💾 Drone upgrades saved")
	else:
		push_error("❌ Failed to save drone upgrades")

func load_drone_upgrades() -> void:
	var save_path = "user://drone_upgrades.save"

	# H-002: Use SaveManager for unified save system
	var save_data = SaveManager.simple_load(save_path)

	if save_data.is_empty():
		print("📂 No drone upgrade save file found, starting fresh")
		return

	active_slots_unlocked = save_data.get("active_slots_unlocked", 1)
	drone_levels = save_data.get("drone_levels", {"flame": 1, "poison": 1, "frost": 1, "shock": 1})
	flame_upgrades = save_data.get("flame_upgrades", {"tick_rate": 0, "hp_cap": 0})
	poison_upgrades = save_data.get("poison_upgrades", {"duration": 0, "stacking": 0})
	frost_upgrades = save_data.get("frost_upgrades", {"aoe": 0, "duration": 0})
	shock_upgrades = save_data.get("shock_upgrades", {"chain": 0, "duration": 0})

	print("✅ Drone upgrades loaded (%d active slots)" % active_slots_unlocked)

	# Apply loaded levels to existing drones
	for drone_type in DRONE_TYPES:
		_apply_drone_level_upgrade(drone_type, drone_levels[drone_type])

# --- DEBUG ---
func grant_test_fragments(amount: int) -> void:
	RewardManager.add_fragments(amount)
	print("🧪 Test: Granted %d fragments" % amount)

func get_total_fragments_spent() -> int:
	var total = 0

	# Active slots
	for slot in range(2, active_slots_unlocked + 1):
		if ACTIVE_SLOT_COSTS.has(slot):
			total += ACTIVE_SLOT_COSTS[slot]

	# Drone levels
	for drone_type in DRONE_TYPES:
		for level in range(2, drone_levels[drone_type] + 1):
			total += DRONE_LEVEL_COSTS[level]

	# Flame upgrades
	for level in range(1, flame_upgrades["tick_rate"] + 1):
		total += FLAME_TICK_RATE_COSTS[level]
	for level in range(1, flame_upgrades["hp_cap"] + 1):
		total += FLAME_HP_CAP_COSTS[level]

	# Poison upgrades
	for level in range(1, poison_upgrades["duration"] + 1):
		total += POISON_DURATION_COSTS[level]
	if poison_upgrades["stacking"] >= 1:
		total += POISON_STACKING_COSTS[1]

	# Frost upgrades
	if frost_upgrades["aoe"] >= 1:
		total += FROST_AOE_COSTS[1]
	for level in range(1, frost_upgrades["duration"] + 1):
		total += FROST_DURATION_COSTS[level]

	# Shock upgrades
	if shock_upgrades["chain"] >= 1:
		total += SHOCK_CHAIN_COSTS[1]
	for level in range(1, shock_upgrades["duration"] + 1):
		total += SHOCK_DURATION_COSTS[level]

	return total
