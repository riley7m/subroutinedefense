extends Node

# --- IN-RUN UPGRADE STATE ---
var projectile_damage_level: int = 1
var base_projectile_damage: int = 100

var projectile_fire_rate_level: int = 0
var base_fire_rate: float = 1.0

var crit_chance: int = 0
const CRIT_CHANCE_CAP := 60

var crit_damage_level: int = 0
const BASE_CRIT_MULTIPLIER := 1.25

var shield_integrity_level: int = 0
const BASE_SHIELD := 200

var damage_reduction_level: int = 0

var shield_regen_level: int = 0

var data_credit_multiplier_level: int = 0
var archive_token_multiplier_level: int = 0

var wave_skip_chance_level: int = 0
var free_upgrade_chance_level: int = 1

# New upgrades (batch 1)
var piercing_level: int = 0
var overkill_damage_level: int = 0
var projectile_speed_level: int = 0
var block_chance_level: int = 0
var block_amount_level: int = 0
var boss_resistance_level: int = 0

# New upgrades (batch 2)
var overshield_level: int = 0
var boss_bonus_level: int = 0
var lucky_drops_level: int = 0
var ricochet_chance_level: int = 0
var ricochet_max_targets_level: int = 0

# --- PURCHASE COUNT TRACKING (for cost scaling) ---
var damage_purchases: int = 0
var fire_rate_purchases: int = 0
var crit_chance_purchases: int = 0
var crit_damage_purchases: int = 0
var shield_purchases: int = 0
var damage_reduction_purchases: int = 0
var shield_regen_purchases: int = 0
var data_multiplier_purchases: int = 0
var archive_multiplier_purchases: int = 0
var wave_skip_purchases: int = 0
var free_upgrade_purchases: int = 0
var piercing_purchases: int = 0
var overkill_purchases: int = 0
var projectile_speed_purchases: int = 0
var block_chance_purchases: int = 0
var block_amount_purchases: int = 0
var boss_resistance_purchases: int = 0
var overshield_purchases: int = 0
var boss_bonus_purchases: int = 0
var lucky_drops_purchases: int = 0
var ricochet_chance_purchases: int = 0
var ricochet_max_targets_purchases: int = 0

# --- UPGRADE CONSTANTS (In-Run) - BASE COSTS ---
# Base costs scale exponentially with each purchase (like The Tower)
const DAMAGE_UPGRADE_BASE_COST := 50
const FIRE_RATE_PER_UPGRADE := 0.25
const FIRE_RATE_UPGRADE_BASE_COST := 50
const CRIT_CHANCE_UPGRADE_BASE_COST := 100
const CRIT_DAMAGE_PER_LEVEL := 0.05
const CRIT_DAMAGE_UPGRADE_BASE_COST := 125
const SHIELD_PER_LEVEL := 10
const SHIELD_UPGRADE_BASE_COST := 50
const DAMAGE_REDUCTION_UPGRADE_BASE_COST := 75
const SHIELD_REGEN_UPGRADE_BASE_COST := 100
const SHIELD_REGEN_PER_LEVEL := 0.25
const DATA_MULTIPLIER_UPGRADE_BASE_COST := 60
const DATA_MULTIPLIER_PER_LEVEL := 0.05
const ARCHIVE_MULTIPLIER_UPGRADE_BASE_COST := 70
const ARCHIVE_MULTIPLIER_PER_LEVEL := 0.05
const WAVE_SKIP_UPGRADE_BASE_COST := 400
const WAVE_SKIP_CHANCE_PER_LEVEL := 1.0
const WAVE_SKIP_MAX_CHANCE := 25.0
const FREE_UPGRADE_BASE_COST := 250
const FREE_UPGRADE_CHANCE_PER_LEVEL := 1.0
const FREE_UPGRADE_MAX_CHANCE := 50.0

# New upgrade constants
const PIERCING_BASE_COST := 150
const PIERCING_PER_LEVEL := 1  # +1 enemy pierced per level
const OVERKILL_BASE_COST := 200
const OVERKILL_PER_LEVEL := 0.05  # +5% overkill damage spread
const PROJECTILE_SPEED_BASE_COST := 75
const PROJECTILE_SPEED_PER_LEVEL := 0.1  # +10% speed
const BLOCK_CHANCE_BASE_COST := 150
const BLOCK_CHANCE_PER_LEVEL := 1.0  # +1% block chance
const BLOCK_CHANCE_MAX := 75.0  # Max 75% block chance
const BLOCK_AMOUNT_BASE_COST := 100
const BLOCK_AMOUNT_PER_LEVEL := 5  # +5 damage blocked
const BOSS_RESISTANCE_BASE_COST := 250
const BOSS_RESISTANCE_PER_LEVEL := 1.0  # +1% damage reduction vs bosses
const BOSS_RESISTANCE_MAX := 50.0  # Max 50% damage reduction

# Batch 2 upgrade constants
const OVERSHIELD_BASE_COST := 125
const OVERSHIELD_PER_LEVEL := 15  # +15 overshield per level
const BOSS_BONUS_BASE_COST := 200
const BOSS_BONUS_PER_LEVEL := 0.05  # +5% damage vs bosses
const LUCKY_DROPS_BASE_COST := 175
const LUCKY_DROPS_PER_LEVEL := 0.5  # +0.5% extra reward chance
const LUCKY_DROPS_MAX := 25.0  # Max 25% lucky drop chance
const RICOCHET_CHANCE_BASE_COST := 300
const RICOCHET_CHANCE_PER_LEVEL := 1.0  # +1% ricochet chance
const RICOCHET_CHANCE_MAX := 50.0  # Max 50% ricochet chance
const RICOCHET_MAX_TARGETS_BASE_COST := 400
const RICOCHET_MAX_TARGETS_PER_LEVEL := 1  # +1 max ricochet target

# --- PER-PURCHASE COST SCALING (like The Tower) ---
# Cost increases exponentially with each purchase, not with wave number
# This keeps early run cheap for all players (new and late-game)
const UPGRADE_COST_SCALING := 1.15  # 15% increase per purchase

# Formula: base_cost * (1.15 ^ purchases)
# Purchase 1: 50 DC (1.0x)
# Purchase 5: 87 DC (1.75x)
# Purchase 10: 202 DC (4.05x)
# Purchase 20: 818 DC (16.37x)
# Purchase 50: 36,841 DC (736x)
func get_purchase_scaled_cost(base_cost: int, purchase_count: int) -> int:
	return int(base_cost * pow(UPGRADE_COST_SCALING, purchase_count))

# --- PER-PURCHASE COST GETTERS ---
func get_damage_upgrade_cost() -> int:
	return get_purchase_scaled_cost(DAMAGE_UPGRADE_BASE_COST, damage_purchases)

func get_fire_rate_upgrade_cost() -> int:
	return get_purchase_scaled_cost(FIRE_RATE_UPGRADE_BASE_COST, fire_rate_purchases)

func get_crit_chance_upgrade_cost() -> int:
	return get_purchase_scaled_cost(CRIT_CHANCE_UPGRADE_BASE_COST, crit_chance_purchases)

func get_crit_damage_upgrade_cost() -> int:
	return get_purchase_scaled_cost(CRIT_DAMAGE_UPGRADE_BASE_COST, crit_damage_purchases)

func get_shield_upgrade_cost() -> int:
	return get_purchase_scaled_cost(SHIELD_UPGRADE_BASE_COST, shield_purchases)

func get_damage_reduction_upgrade_cost() -> int:
	return get_purchase_scaled_cost(DAMAGE_REDUCTION_UPGRADE_BASE_COST, damage_reduction_purchases)

func get_shield_regen_upgrade_cost() -> int:
	return get_purchase_scaled_cost(SHIELD_REGEN_UPGRADE_BASE_COST, shield_regen_purchases)

func get_data_multiplier_upgrade_cost() -> int:
	return get_purchase_scaled_cost(DATA_MULTIPLIER_UPGRADE_BASE_COST, data_multiplier_purchases)

func get_archive_multiplier_upgrade_cost() -> int:
	return get_purchase_scaled_cost(ARCHIVE_MULTIPLIER_UPGRADE_BASE_COST, archive_multiplier_purchases)

func get_wave_skip_upgrade_cost() -> int:
	return get_purchase_scaled_cost(WAVE_SKIP_UPGRADE_BASE_COST, wave_skip_purchases)

func get_free_upgrade_cost() -> int:
	return get_purchase_scaled_cost(FREE_UPGRADE_BASE_COST, free_upgrade_purchases)

# Batch 2 cost getters
func get_overshield_upgrade_cost() -> int:
	return get_purchase_scaled_cost(OVERSHIELD_BASE_COST, overshield_purchases)

func get_boss_bonus_upgrade_cost() -> int:
	return get_purchase_scaled_cost(BOSS_BONUS_BASE_COST, boss_bonus_purchases)

func get_lucky_drops_upgrade_cost() -> int:
	return get_purchase_scaled_cost(LUCKY_DROPS_BASE_COST, lucky_drops_purchases)

func get_ricochet_chance_upgrade_cost() -> int:
	return get_purchase_scaled_cost(RICOCHET_CHANCE_BASE_COST, ricochet_chance_purchases)

func get_ricochet_max_targets_upgrade_cost() -> int:
	return get_purchase_scaled_cost(RICOCHET_MAX_TARGETS_BASE_COST, ricochet_max_targets_purchases)

var multi_target_level: int = 0
const MULTI_TARGET_BASE_COST := 1000
const MULTI_TARGET_MAX_LEVEL := 9   # (max 10 targets total)
const MULTI_TARGET_COST_SCALE := 2.5  # Exponential cost
const MULTI_TARGET_INITIAL_LOCKED := true
var multi_target_unlocked := false

# --- PERMANENT DRONE UPGRADE CONSTANTS ---
const PERM_DRONE_MAX_LEVEL := 30  # Max level for permanent drone upgrades

# --- PERMANENT UPGRADE COSTS ---
# Exponential cost scaling for permanent upgrades (AT-based)
# Formula: base * (1.13 ^ level)
#
# This creates a 3-year progression timeline where:
# - Early levels: affordable with basic gameplay (1-50)
# - Mid levels: require focused farming (50-200)
# - Late levels: endgame grind (200-500)
#
# Example costs for base=5000:
# - Level 1: 5,650 AT (1.13x)
# - Level 10: 16,946 AT (3.39x)
# - Level 50: 423,063 AT (84.6x)
# - Level 100: 35,847,267 AT (7,169x)
# - Level 200: 1.03e12 AT (206 billion)
#
# Note: The 'increment' parameter is legacy and not used
func get_perm_cost(base: int, increment: int, level: int) -> int:
	return int(base * pow(1.13, level))

func get_perm_drone_upgrade_cost(level: int) -> int:
	return 2500 + level * 1000

# --- UPGRADE GETTERS (add permanent bonuses!) ---
# In-run damage calculation with milestone multipliers
# Formula: (base + polynomial_growth) * (1.5 ^ milestone) + permanent_damage
#
# Base calculation: 100 + floor(5 * level^1.12 + 5)
# - Provides smooth polynomial scaling within each milestone tier
#
# Milestone multiplier: 1.5 ^ (level / 100)
# - Every 100 levels doubles damage (1.5x per milestone ≈ 2x per 100 levels)
# - Example: Level 200 = 1.5^2 = 2.25x, Level 300 = 1.5^3 = 3.375x
#
# Safety caps:
# - Uses BigNumber for values > int64 max (supports up to 10^237 = 1az)
# - Allows damage to reach octillions (10^27) and beyond
# - Returns int64 max if value exceeds int64 range for backwards compatibility
#
# This dual-scaling system ensures:
# - Smooth progression within tiers (polynomial)
# - Significant jumps at milestones (exponential)
# - No overflow at extreme levels (uses BigNumber)
func get_projectile_damage() -> int:
	var level = projectile_damage_level
	var base = 100 + (floor(5 * pow(level, 1.12) + 5))
	var milestones = floor(level / 100)

	# Calculate multiplier (no cap - BigNumber handles it)
	var multiplier = pow(1.5, milestones)
	var total = base * multiplier

	# Check if we need BigNumber (exponent > 18 = quintillions+)
	if milestones > 120:  # pow(1.5, 120) ≈ 4.4e20 (exceeds int64)
		# Use BigNumber for truly massive values
		var bn = BigNumber.new(total)
		var perm_bn = BigNumber.new(RewardManager.perm_projectile_damage)
		bn = bn.add(perm_bn)
		# Return int64 max if too large, otherwise convert
		return bn.to_int()
	else:
		# Safe int64 range
		var total_with_perm = total + RewardManager.perm_projectile_damage
		# Apply data disk buffs (percentage boost)
		var disk_buff = DataDiskManager.get_projectile_damage_buff()
		var devastator_buff = DataDiskManager.get_devastator_damage_buff()
		total_with_perm = int(total_with_perm * (1.0 + disk_buff + devastator_buff))
		return int(min(total_with_perm, 9223372036854775807))  # int64 max

func get_projectile_fire_rate() -> float:
	var base_rate = base_fire_rate + projectile_fire_rate_level * FIRE_RATE_PER_UPGRADE + RewardManager.perm_projectile_fire_rate
	# Apply data disk buff (percentage boost)
	var disk_buff = DataDiskManager.get_fire_rate_buff()
	return base_rate * (1.0 + disk_buff)

func get_crit_chance() -> int:
	var base_crit = crit_chance + RewardManager.perm_crit_chance
	# Apply data disk buffs (flat addition)
	var disk_buff = DataDiskManager.get_crit_chance_buff()
	var precision_buff = DataDiskManager.get_precision_crit_chance_buff()
	return int(base_crit + disk_buff + precision_buff)

func get_crit_damage_multiplier() -> float:
	var base_crit_dmg = BASE_CRIT_MULTIPLIER + (crit_damage_level * CRIT_DAMAGE_PER_LEVEL) + RewardManager.perm_crit_damage
	# Apply data disk buffs (percentage boost)
	var disk_buff = DataDiskManager.get_crit_damage_buff()
	var devastator_buff = DataDiskManager.get_devastator_crit_damage_buff()
	var precision_buff = DataDiskManager.get_precision_crit_damage_buff()
	return base_crit_dmg * (1.0 + disk_buff + devastator_buff + precision_buff)

func get_shield_capacity() -> int:
	var base_shield = BASE_SHIELD + (shield_integrity_level * SHIELD_PER_LEVEL) + RewardManager.perm_shield_integrity
	# Apply data disk buff (percentage boost)
	var disk_buff = DataDiskManager.get_shield_integrity_buff()
	return int(base_shield * (1.0 + disk_buff))

func get_damage_reduction_level() -> float:
	var base_reduction = damage_reduction_level * 0.5 + RewardManager.perm_damage_reduction
	# Apply data disk buff (flat addition)
	var disk_buff = DataDiskManager.get_damage_reduction_buff()
	return base_reduction + disk_buff

func get_shield_regen_rate() -> float:
	var base_regen = shield_regen_level * SHIELD_REGEN_PER_LEVEL + RewardManager.perm_shield_regen
	# Apply data disk buff (percentage boost)
	var disk_buff = DataDiskManager.get_shield_regen_buff()
	return base_regen * (1.0 + disk_buff)

func get_data_credit_multiplier() -> float:
	var base_mult = 1.0 + (data_credit_multiplier_level * DATA_MULTIPLIER_PER_LEVEL) + RewardManager.perm_data_credit_multiplier
	# Apply data disk buff (flat addition to multiplier)
	var disk_buff = DataDiskManager.get_dc_multiplier_buff()
	return base_mult + disk_buff

func get_archive_token_multiplier() -> float:
	var base_mult = 1.0 + (archive_token_multiplier_level * ARCHIVE_MULTIPLIER_PER_LEVEL) + RewardManager.perm_archive_token_multiplier
	# Apply data disk buff (flat addition to multiplier)
	var disk_buff = DataDiskManager.get_at_multiplier_buff()
	return base_mult + disk_buff

func get_wave_skip_chance() -> float:
	var base_chance = wave_skip_chance_level * WAVE_SKIP_CHANCE_PER_LEVEL + RewardManager.perm_wave_skip_chance
	# Apply data disk buff (flat addition)
	var disk_buff = DataDiskManager.get_wave_skip_chance_buff()
	return min(base_chance + disk_buff, WAVE_SKIP_MAX_CHANCE)

func get_free_upgrade_chance() -> float:
	var base_chance = free_upgrade_chance_level * FREE_UPGRADE_CHANCE_PER_LEVEL + RewardManager.perm_free_upgrade_chance
	# Apply data disk buff (flat addition)
	var disk_buff = DataDiskManager.get_free_upgrade_chance_buff()
	return min(base_chance + disk_buff, FREE_UPGRADE_MAX_CHANCE)

# --- BATCH 1 UPGRADE GETTERS ---
func get_piercing() -> int:
	return piercing_level * PIERCING_PER_LEVEL + RewardManager.perm_piercing

func get_overkill_damage() -> float:
	return overkill_damage_level * OVERKILL_PER_LEVEL + RewardManager.perm_overkill_damage

func get_projectile_speed() -> float:
	return 1.0 + (projectile_speed_level * PROJECTILE_SPEED_PER_LEVEL) + RewardManager.perm_projectile_speed

func get_block_chance() -> float:
	return min(block_chance_level * BLOCK_CHANCE_PER_LEVEL + RewardManager.perm_block_chance, BLOCK_CHANCE_MAX)

func get_block_amount() -> int:
	return block_amount_level * BLOCK_AMOUNT_PER_LEVEL + RewardManager.perm_block_amount

func get_boss_resistance() -> float:
	return min(boss_resistance_level * BOSS_RESISTANCE_PER_LEVEL + RewardManager.perm_boss_resistance, BOSS_RESISTANCE_MAX)

# --- BATCH 2 UPGRADE GETTERS ---
func get_overshield() -> int:
	var base_overshield = overshield_level * OVERSHIELD_PER_LEVEL + RewardManager.perm_overshield
	# Apply data disk buff (percentage boost)
	var disk_buff = DataDiskManager.get_overshield_capacity_buff()
	return int(base_overshield * (1.0 + disk_buff))

func get_boss_bonus() -> float:
	return 1.0 + (boss_bonus_level * BOSS_BONUS_PER_LEVEL) + RewardManager.perm_boss_bonus

func get_lucky_drops() -> float:
	return min(lucky_drops_level * LUCKY_DROPS_PER_LEVEL + RewardManager.perm_lucky_drops, LUCKY_DROPS_MAX)

func get_ricochet_chance() -> float:
	return min(ricochet_chance_level * RICOCHET_CHANCE_PER_LEVEL + RewardManager.perm_ricochet_chance, RICOCHET_CHANCE_MAX)

func get_ricochet_max_targets() -> int:
	return ricochet_max_targets_level * RICOCHET_MAX_TARGETS_PER_LEVEL + RewardManager.perm_ricochet_max_targets

# --- DRONE PERMANENT LEVEL GETTERS ---
func get_perm_drone_flame_level() -> int:
	return RewardManager.perm_drone_flame_level

func get_perm_drone_frost_level() -> int:
	return RewardManager.perm_drone_frost_level

func get_perm_drone_poison_level() -> int:
	return RewardManager.perm_drone_poison_level

func get_perm_drone_shock_level() -> int:
	return RewardManager.perm_drone_shock_level

# --- IN-RUN UPGRADE FUNCTIONS (COST or FREE) ---

func upgrade_projectile_damage(is_free := false):
	if is_free:
		projectile_damage_level += 1
		print("🆙 Projectile Damage upgraded for FREE! Level:", projectile_damage_level)
		return true
	var cost = get_damage_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		damage_purchases += 1  # Increment purchase count for cost scaling
		projectile_damage_level += 1
		print("🆙 Projectile Damage upgraded! Level:", projectile_damage_level)
		return true
	else:
		print("❌ Not enough DC to upgrade Projectile Damage.")
		return false

func upgrade_fire_rate(is_free := false):
	if is_free:
		projectile_fire_rate_level += 1
		print("⚙️ Fire Rate upgraded for FREE! Level:", get_projectile_fire_rate())
		return true
	var cost = get_fire_rate_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		fire_rate_purchases += 1  # Increment purchase count for cost scaling
		projectile_fire_rate_level += 1
		print("⚙️ Fire Rate upgraded to:", get_projectile_fire_rate())
		return true
	else:
		print("❌ Not enough DC to upgrade Fire Rate.")
		return false

func upgrade_crit_chance(is_free := false):
	if get_crit_chance() >= CRIT_CHANCE_CAP:
		print("✅ Crit Chance already at max.")
		return false
	if is_free:
		crit_chance += 1
		print("🎯 Crit Chance upgraded for FREE to", get_crit_chance(), "%")
		return true
	var cost = get_crit_chance_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		crit_chance_purchases += 1  # Increment purchase count for cost scaling
		crit_chance += 1
		print("🎯 Crit Chance upgraded to", get_crit_chance(), "%")
		return true
	else:
		print("❌ Not enough DC to upgrade Crit Chance.")
		return false

func upgrade_crit_damage(is_free := false):
	if is_free:
		crit_damage_level += 1
		print("⚡ Crit Damage upgraded for FREE to:", get_crit_damage_multiplier(), "x")
		return true
	var cost = get_crit_damage_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		crit_damage_purchases += 1  # Increment purchase count for cost scaling
		crit_damage_level += 1
		print("⚡ Crit Damage upgraded to:", get_crit_damage_multiplier(), "x")
		return true
	else:
		print("❌ Not enough DC to upgrade Crit Damage.")
		return false

func upgrade_shield_integrity(is_free := false):
	if is_free:
		shield_integrity_level += 1
		print("🛡️ Shield Integrity upgraded for FREE to", get_shield_capacity())
		return true
	var cost = get_shield_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		shield_purchases += 1  # Increment purchase count for cost scaling
		shield_integrity_level += 1
		print("🛡️ Shield Integrity upgraded to", get_shield_capacity())
		return true
	else:
		print("❌ Not enough DC to upgrade Shield Integrity.")
		return false

func upgrade_damage_reduction(is_free := false):
	if is_free:
		damage_reduction_level += 1
		print("🛡️ Damage Reduction upgraded for FREE to", get_damage_reduction_level(), "%")
		return true
	var cost = get_damage_reduction_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		damage_reduction_purchases += 1  # Increment purchase count for cost scaling
		damage_reduction_level += 1
		print("🛡️ Damage Reduction upgraded to", get_damage_reduction_level(), "%")
		return true
	else:
		print("❌ Not enough DC to upgrade Damage Reduction.")
		return false

func upgrade_shield_regen(is_free := false):
	if is_free:
		shield_regen_level += 1
		print("🌀 Shield Regen upgraded for FREE to", get_shield_regen_rate(), "% per sec")
		return true
	var cost = get_shield_regen_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		shield_regen_purchases += 1  # Increment purchase count for cost scaling
		shield_regen_level += 1
		print("🌀 Shield Regen upgraded to", get_shield_regen_rate(), "% per sec")
		return true
	else:
		print("❌ Not enough DC to upgrade Shield Regen.")
		return false

func upgrade_data_credit_multiplier(is_free := false):
	if is_free:
		data_credit_multiplier_level += 1
		print("💰 Data Credit Multiplier upgraded for FREE to x", get_data_credit_multiplier())
		return true
	var cost = get_data_multiplier_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		data_multiplier_purchases += 1  # Increment purchase count for cost scaling
		data_credit_multiplier_level += 1
		print("💰 Data Credit Multiplier upgraded to x", get_data_credit_multiplier())
		return true
	else:
		print("❌ Not enough DC to upgrade Data Credit Multiplier.")
		return false

func upgrade_archive_token_multiplier(is_free := false):
	if is_free:
		archive_token_multiplier_level += 1
		print("📦 Archive Token Multiplier upgraded for FREE to x", get_archive_token_multiplier())
		return true
	var cost = get_archive_multiplier_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		archive_multiplier_purchases += 1  # Increment purchase count for cost scaling
		archive_token_multiplier_level += 1
		print("📦 Archive Token Multiplier upgraded to x", get_archive_token_multiplier())
		return true
	else:
		print("❌ Not enough DC to upgrade Archive Token Multiplier.")
		return false

func upgrade_wave_skip_chance(is_free := false):
	if get_wave_skip_chance() >= WAVE_SKIP_MAX_CHANCE:
		print("✅ Wave Skip Chance already at max.")
		return false
	if is_free:
		wave_skip_chance_level += 1
		print("⏩ Wave Skip Chance upgraded for FREE to", get_wave_skip_chance(), "%")
		return true
	var cost = get_wave_skip_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		wave_skip_purchases += 1  # Increment purchase count for cost scaling
		wave_skip_chance_level += 1
		print("⏩ Wave Skip Chance upgraded to", get_wave_skip_chance(), "%")
		return true
	else:
		print("❌ Not enough DC to upgrade Wave Skip Chance.")
		return false

func upgrade_free_upgrade_chance(is_free := false):
	if get_free_upgrade_chance() >= FREE_UPGRADE_MAX_CHANCE:
		print("✅ Free Upgrade Chance already at max.")
		return false
	if is_free:
		free_upgrade_chance_level += 1
		print("🎲 Free Upgrade Chance increased for FREE to", get_free_upgrade_chance(), "%")
		return true
	var cost = get_free_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		free_upgrade_purchases += 1  # Increment purchase count for cost scaling
		free_upgrade_chance_level += 1
		print("🎲 Free Upgrade Chance increased to", get_free_upgrade_chance(), "%")
		return true
	else:
		print("❌ Not enough DC to upgrade Free Upgrade Chance.")
		return false

# Batch 2 in-run upgrade functions
func upgrade_overshield(is_free := false):
	if is_free:
		overshield_level += 1
		print("🛡️ Overshield upgraded for FREE! Level:", overshield_level)
		return true
	var cost = get_overshield_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		overshield_purchases += 1
		overshield_level += 1
		print("🛡️ Overshield upgraded! Level:", overshield_level)
		return true
	else:
		print("❌ Not enough DC to upgrade Overshield.")
		return false

func upgrade_boss_bonus(is_free := false):
	if is_free:
		boss_bonus_level += 1
		print("👑 Boss Bonus upgraded for FREE! Level:", boss_bonus_level)
		return true
	var cost = get_boss_bonus_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		boss_bonus_purchases += 1
		boss_bonus_level += 1
		print("👑 Boss Bonus upgraded! Level:", boss_bonus_level)
		return true
	else:
		print("❌ Not enough DC to upgrade Boss Bonus.")
		return false

func upgrade_lucky_drops(is_free := false):
	if lucky_drops_level * LUCKY_DROPS_PER_LEVEL >= LUCKY_DROPS_MAX:
		print("✅ Lucky Drops already at max.")
		return false
	if is_free:
		lucky_drops_level += 1
		print("🍀 Lucky Drops upgraded for FREE! Level:", lucky_drops_level)
		return true
	var cost = get_lucky_drops_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		lucky_drops_purchases += 1
		lucky_drops_level += 1
		print("🍀 Lucky Drops upgraded! Level:", lucky_drops_level)
		return true
	else:
		print("❌ Not enough DC to upgrade Lucky Drops.")
		return false

func upgrade_ricochet_chance(is_free := false):
	if ricochet_chance_level * RICOCHET_CHANCE_PER_LEVEL >= RICOCHET_CHANCE_MAX:
		print("✅ Ricochet Chance already at max.")
		return false
	if is_free:
		ricochet_chance_level += 1
		print("🔁 Ricochet Chance upgraded for FREE! Level:", ricochet_chance_level)
		return true
	var cost = get_ricochet_chance_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		ricochet_chance_purchases += 1
		ricochet_chance_level += 1
		print("🔁 Ricochet Chance upgraded! Level:", ricochet_chance_level)
		return true
	else:
		print("❌ Not enough DC to upgrade Ricochet Chance.")
		return false

func upgrade_ricochet_max_targets(is_free := false):
	if is_free:
		ricochet_max_targets_level += 1
		print("🎯 Ricochet Max Targets upgraded for FREE! Level:", ricochet_max_targets_level)
		return true
	var cost = get_ricochet_max_targets_upgrade_cost()
	if RewardManager.data_credits >= cost:
		RewardManager.data_credits -= cost
		ricochet_max_targets_purchases += 1
		ricochet_max_targets_level += 1
		print("🎯 Ricochet Max Targets upgraded! Level:", ricochet_max_targets_level)
		return true
	else:
		print("❌ Not enough DC to upgrade Ricochet Max Targets.")
		return false

# --- PERMANENT UPGRADE FUNCTIONS (with bool returns for Buy X support) ---

# Returns the cost for a given perm upgrade at a specific future level
func get_perm_upgrade_cost_for_level(key: String, level: int) -> int:
	match key:
		"projectile_damage":
			return get_perm_cost(5000, 250, level)
		"fire_rate":
			return get_perm_cost(8000, 500, int(level * 10))
		"crit_chance":
			return get_perm_cost(7500, 500, level)
		"crit_damage":
			return get_perm_cost(9000, 500, int(level * 20))
		"shield_integrity":
			return get_perm_cost(7000, 300, int(level * 5))  # Fixed: was dividing by 10
		"shield_regen":
			return get_perm_cost(8500, 400, int(level * 4))
		"damage_reduction":
			return get_perm_cost(8000, 400, int(level * 2))
		"data_credit_multiplier":
			return get_perm_cost(12000, 750, int(level * 20))
		"archive_token_multiplier":
			return get_perm_cost(13000, 850, int(level * 20))
		"wave_skip_chance":
			return get_perm_cost(15000, 1000, int(level * 10))
		"free_upgrade_chance":
			return get_perm_cost(18000, 1200, int(level * 10))
		_:
			return 99999999 # fallback

# --- MULTI TARGET GETTERS ---
func get_multi_target_level() -> int:
	# Returns the number of EXTRA targets (so actual = level + 1)
	if not is_multi_target_unlocked():
		return 1
	return multi_target_level + 1

func is_multi_target_unlocked() -> bool:
	# Permanent unlocks for this run; OR if unlocked in-run
	return multi_target_unlocked or RewardManager.perm_multi_target_unlocked

func get_multi_target_cost_for_level(level: int) -> int:
	# Level is 1-based: 1 = unlock, 2+ = upgrades
	return int(MULTI_TARGET_BASE_COST * pow(MULTI_TARGET_COST_SCALE, max(level-1, 0)))

func get_multi_target_upgrade_cost() -> int:
	# For current upgrade button (next level)
	var next_level = multi_target_level + 1
	return get_multi_target_cost_for_level(next_level)

# --- IN-RUN MULTI TARGET UPGRADE LOGIC ---

func unlock_multi_target(is_free := false) -> bool:
	if is_multi_target_unlocked():
		print("Multi Target already unlocked.")
		return false
	var cost = get_multi_target_cost_for_level(1)
	if not is_free and RewardManager.data_credits < cost:
		print("❌ Not enough DC to unlock Multi Target.")
		return false
	if not is_free:
		RewardManager.data_credits -= cost
	multi_target_unlocked = true
	multi_target_level = 1
	print("🔓 Multi Target unlocked! Level 1 (2 targets)")
	return true

func upgrade_multi_target(is_free := false) -> bool:
	if not is_multi_target_unlocked():
		print("Multi Target is locked! Unlock first.")
		return false
	if multi_target_level >= MULTI_TARGET_MAX_LEVEL:
		print("Multi Target already at max!")
		return false
	var next_level = multi_target_level + 1
	var cost = get_multi_target_cost_for_level(next_level)
	if not is_free and RewardManager.data_credits < cost:
		print("❌ Not enough DC for Multi Target upgrade.")
		return false
	if not is_free:
		RewardManager.data_credits -= cost
	multi_target_level = next_level
	print("⛓️ Multi Target upgraded! Level %d (%d targets)" % [multi_target_level, multi_target_level + 1])
	return true

# --- PERMANENT MULTI TARGET UPGRADE LOGIC ---

func upgrade_perm_multi_target_unlock() -> bool:
	# Permanent unlock: expensive, but only needs to be bought once!
	var cost = get_perm_cost(100000, 0, 0)  # Example: 100,000 AT flat cost
	if RewardManager.perm_multi_target_unlocked:
		print("Permanent Multi Target already unlocked.")
		return false
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent Multi Target unlock.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_multi_target_unlocked = true
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Multi Target unlocked for all runs!")
	return true


func upgrade_perm_projectile_damage() -> bool:
	var cost = get_perm_cost(5000, 250, RewardManager.perm_projectile_damage / 10)
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent projectile damage.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_projectile_damage += 10
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Projectile Damage +10. Now:", RewardManager.perm_projectile_damage)
	return true

func upgrade_perm_projectile_fire_rate() -> bool:
	var cost = get_perm_cost(8000, 500, int(RewardManager.perm_projectile_fire_rate * 10))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent fire rate.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_projectile_fire_rate += 0.1
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Fire Rate +0.1. Now:", RewardManager.perm_projectile_fire_rate)
	return true

func upgrade_perm_crit_chance() -> bool:
	var cost = get_perm_cost(7500, 500, RewardManager.perm_crit_chance)
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent crit chance.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_crit_chance += 1
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Crit Chance +1%. Now:", RewardManager.perm_crit_chance)
	return true

func upgrade_perm_crit_damage() -> bool:
	var cost = get_perm_cost(9000, 500, int(RewardManager.perm_crit_damage * 20))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent crit damage.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_crit_damage += 0.05
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Crit Damage +0.05x. Now:", RewardManager.perm_crit_damage)
	return true

func upgrade_perm_shield_integrity() -> bool:
	var cost = get_perm_cost(7000, 300, int(RewardManager.perm_shield_integrity / 10))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent shield integrity.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_shield_integrity += 10
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Shield Integrity +10. Now:", RewardManager.perm_shield_integrity)
	return true

func upgrade_perm_damage_reduction() -> bool:
	var cost = get_perm_cost(8000, 400, int(RewardManager.perm_damage_reduction * 2))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent damage reduction.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_damage_reduction += 0.5
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Damage Reduction +0.5%. Now:", RewardManager.perm_damage_reduction)
	return true

func upgrade_perm_shield_regen() -> bool:
	var cost = get_perm_cost(8500, 400, int(RewardManager.perm_shield_regen * 4))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent shield regen.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_shield_regen += 0.25
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Shield Regen +0.25%. Now:", RewardManager.perm_shield_regen)
	return true

func upgrade_perm_data_credit_multiplier() -> bool:
	var cost = get_perm_cost(12000, 750, int(RewardManager.perm_data_credit_multiplier * 20))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent DC multiplier.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_data_credit_multiplier += 0.05
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent DC Multiplier +0.05. Now:", RewardManager.perm_data_credit_multiplier)
	return true

func upgrade_perm_archive_token_multiplier() -> bool:
	var cost = get_perm_cost(13000, 850, int(RewardManager.perm_archive_token_multiplier * 20))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent AT multiplier.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_archive_token_multiplier += 0.05
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent AT Multiplier +0.05. Now:", RewardManager.perm_archive_token_multiplier)
	return true

func upgrade_perm_wave_skip_chance() -> bool:
	var cost = get_perm_cost(15000, 1000, int(RewardManager.perm_wave_skip_chance * 10))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent wave skip.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_wave_skip_chance += 1.0
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Wave Skip Chance +1%. Now:", RewardManager.perm_wave_skip_chance)
	return true

func upgrade_perm_free_upgrade_chance() -> bool:
	var cost = get_perm_cost(18000, 1200, int(RewardManager.perm_free_upgrade_chance * 10))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent free upgrade chance.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_free_upgrade_chance += 1.0
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Free Upgrade Chance +1%. Now:", RewardManager.perm_free_upgrade_chance)
	return true

# Batch 2 permanent upgrade functions
func upgrade_perm_overshield() -> bool:
	var cost = get_perm_cost(6000, 300, int(RewardManager.perm_overshield / 15))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent overshield.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_overshield += 15
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Overshield +15. Now:", RewardManager.perm_overshield)
	return true

func upgrade_perm_boss_bonus() -> bool:
	var cost = get_perm_cost(9000, 500, int(RewardManager.perm_boss_bonus * 20))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent boss bonus.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_boss_bonus += 0.05
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Boss Bonus +5%. Now:", RewardManager.perm_boss_bonus)
	return true

func upgrade_perm_lucky_drops() -> bool:
	var cost = get_perm_cost(10000, 600, int(RewardManager.perm_lucky_drops * 2))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent lucky drops.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_lucky_drops += 0.5
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Lucky Drops +0.5%. Now:", RewardManager.perm_lucky_drops)
	return true

func upgrade_perm_ricochet_chance() -> bool:
	var cost = get_perm_cost(12000, 750, int(RewardManager.perm_ricochet_chance))
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent ricochet chance.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_ricochet_chance += 1.0
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Ricochet Chance +1%. Now:", RewardManager.perm_ricochet_chance)
	return true

func upgrade_perm_ricochet_max_targets() -> bool:
	var cost = get_perm_cost(15000, 1000, RewardManager.perm_ricochet_max_targets)
	if RewardManager.archive_tokens < cost:
		print("❌ Not enough AT for permanent ricochet max targets.")
		return false
	RewardManager.archive_tokens -= cost
	RunStats.add_at_spent_perm_upgrade(cost)
	RewardManager.perm_ricochet_max_targets += 1
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Ricochet Max Targets +1. Now:", RewardManager.perm_ricochet_max_targets)
	return true

func upgrade_perm_drone_flame() -> bool:
	if not RewardManager.owns_drone("flame"):
		print("❌ Flame Drone not owned! Purchase it first.")
		return false
	if RewardManager.perm_drone_flame_level >= PERM_DRONE_MAX_LEVEL:
		print("❌ Flame Drone already at max level!")
		return false
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_flame_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Flame Drone.")
		return false
	RewardManager.fragments -= cost
	RewardManager.perm_drone_flame_level += 1
	RewardManager.save_permanent_upgrades()
	print("🔥 Flame Drone permanently upgraded! Now:", RewardManager.perm_drone_flame_level)
	return true

func upgrade_perm_drone_frost() -> bool:
	if not RewardManager.owns_drone("frost"):
		print("❌ Frost Drone not owned! Purchase it first.")
		return false
	if RewardManager.perm_drone_frost_level >= PERM_DRONE_MAX_LEVEL:
		print("❌ Frost Drone already at max level!")
		return false
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_frost_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Frost Drone.")
		return false
	RewardManager.fragments -= cost
	RewardManager.perm_drone_frost_level += 1
	RewardManager.save_permanent_upgrades()
	print("❄️ Frost Drone permanently upgraded! Now:", RewardManager.perm_drone_frost_level)
	return true

func upgrade_perm_drone_poison() -> bool:
	if not RewardManager.owns_drone("poison"):
		print("❌ Poison Drone not owned! Purchase it first.")
		return false
	if RewardManager.perm_drone_poison_level >= PERM_DRONE_MAX_LEVEL:
		print("❌ Poison Drone already at max level!")
		return false
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_poison_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Poison Drone.")
		return false
	RewardManager.fragments -= cost
	RewardManager.perm_drone_poison_level += 1
	RewardManager.save_permanent_upgrades()
	print("🟣 Poison Drone permanently upgraded! Now:", RewardManager.perm_drone_poison_level)
	return true

func upgrade_perm_drone_shock() -> bool:
	if not RewardManager.owns_drone("shock"):
		print("❌ Shock Drone not owned! Purchase it first.")
		return false
	if RewardManager.perm_drone_shock_level >= PERM_DRONE_MAX_LEVEL:
		print("❌ Shock Drone already at max level!")
		return false
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_shock_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Shock Drone.")
		return false
	RewardManager.fragments -= cost
	RewardManager.perm_drone_shock_level += 1
	RewardManager.save_permanent_upgrades()
	print("⚡ Shock Drone permanently upgraded! Now:", RewardManager.perm_drone_shock_level)
	return true

# --- WAVE-END FREE UPGRADE SYSTEM (unchanged) ---
func maybe_grant_free_upgrade():
	var roll = randf() * 100.0
	var chance = get_free_upgrade_chance()
	print("🎲 Free upgrade wave-end roll: %.2f vs %.2f" % [roll, chance])

	if roll >= chance:
		print("❌ No free upgrade this wave.")
		return

	var category = randi_range(1, 3)
	var upgraded = false

	match category:
		1:
			upgraded = try_upgrade_offense()
		2:
			upgraded = try_upgrade_defense()
		3:
			upgraded = try_upgrade_economy()

	if upgraded:
		print("✨ Free upgrade granted from wave-end roll.")
	else:
		print("⚠️ No eligible upgrades in selected category.")

# --- TRY UPGRADE HELPERS (for FREE upgrades only) ---
func try_upgrade_offense() -> bool:
	var options = []
	if get_crit_chance() < CRIT_CHANCE_CAP:
		options.append(func(): upgrade_crit_chance(true))
	if crit_damage_level * CRIT_DAMAGE_PER_LEVEL + BASE_CRIT_MULTIPLIER < 3.0:
		options.append(func(): upgrade_crit_damage(true))
	if projectile_fire_rate_level < 49:
		options.append(func(): upgrade_fire_rate(true))
	if true:  # projectile_damage_level has no cap
		options.append(func(): upgrade_projectile_damage(true))
	if is_multi_target_unlocked() and multi_target_level < MULTI_TARGET_MAX_LEVEL:
		options.append(func(): upgrade_multi_target(true))
	if options.is_empty():
		return false
	var selected = options.pick_random()
	selected.call()
	return true

func try_upgrade_defense() -> bool:
	var options = []
	if shield_integrity_level * SHIELD_PER_LEVEL + BASE_SHIELD < 99999:
		options.append(func(): upgrade_shield_integrity(true))
	if damage_reduction_level * 0.5 < 50.0:
		options.append(func(): upgrade_damage_reduction(true))
	if shield_regen_level * SHIELD_REGEN_PER_LEVEL < 20.0:
		options.append(func(): upgrade_shield_regen(true))
	if options.is_empty():
		return false
	var selected = options.pick_random()
	selected.call()
	return true

func try_upgrade_economy() -> bool:
	var options = []
	if data_credit_multiplier_level * DATA_MULTIPLIER_PER_LEVEL + 1.0 < 20.0:
		options.append(func(): upgrade_data_credit_multiplier(true))
	if archive_token_multiplier_level * ARCHIVE_MULTIPLIER_PER_LEVEL + 1.0 < 20.0:
		options.append(func(): upgrade_archive_token_multiplier(true))
	if wave_skip_chance_level * WAVE_SKIP_CHANCE_PER_LEVEL < WAVE_SKIP_MAX_CHANCE:
		options.append(func(): upgrade_wave_skip_chance(true))
	if free_upgrade_chance_level * FREE_UPGRADE_CHANCE_PER_LEVEL < FREE_UPGRADE_MAX_CHANCE:
		options.append(func(): upgrade_free_upgrade_chance(true))
	if options.is_empty():
		return false
	var selected = options.pick_random()
	selected.call()
	return true

# --- GENERIC PERMANENT UPGRADE GETTER ---
func get_perm_level(key: String) -> int:
	match key:
		"projectile_damage":
			return RewardManager.perm_projectile_damage
		"fire_rate":
			return int(RewardManager.perm_projectile_fire_rate * 10)
		"crit_chance":
			return RewardManager.perm_crit_chance
		"crit_damage":
			return int(RewardManager.perm_crit_damage * 20)
		"shield_integrity":
			return int(RewardManager.perm_shield_integrity / 10)
		"shield_regen":
			return int(RewardManager.perm_shield_regen * 4)
		"damage_reduction":
			return int(RewardManager.perm_damage_reduction * 2)
		"data_credit_multiplier":
			return int(RewardManager.perm_data_credit_multiplier * 20)
		"archive_token_multiplier":
			return int(RewardManager.perm_archive_token_multiplier * 20)
		"wave_skip_chance":
			return int(RewardManager.perm_wave_skip_chance)
		"free_upgrade_chance":
			return int(RewardManager.perm_free_upgrade_chance)
		"multi_target_unlock":
			return int(RewardManager.perm_multi_target_unlocked)
		_:
			return 0

func get_perm_upgrade_cost(key: String) -> int:
	match key:
		"projectile_damage":
			return get_perm_cost(5000, 250, RewardManager.perm_projectile_damage / 10)
		"fire_rate":
			return get_perm_cost(8000, 500, int(RewardManager.perm_projectile_fire_rate * 10))
		"crit_chance":
			return get_perm_cost(7500, 500, RewardManager.perm_crit_chance)
		"crit_damage":
			return get_perm_cost(9000, 500, int(RewardManager.perm_crit_damage * 20))
		"shield_integrity":
			return get_perm_cost(7000, 300, int(RewardManager.perm_shield_integrity / 10))
		"shield_regen":
			return get_perm_cost(8500, 400, int(RewardManager.perm_shield_regen * 4))
		"damage_reduction":
			return get_perm_cost(8000, 400, int(RewardManager.perm_damage_reduction * 2))
		"data_credit_multiplier":
			return get_perm_cost(12000, 750, int(RewardManager.perm_data_credit_multiplier * 20))
		"archive_token_multiplier":
			return get_perm_cost(13000, 850, int(RewardManager.perm_archive_token_multiplier * 20))
		"wave_skip_chance":
			return get_perm_cost(15000, 1000, int(RewardManager.perm_wave_skip_chance))
		"free_upgrade_chance":
			return get_perm_cost(18000, 1200, int(RewardManager.perm_free_upgrade_chance))
		"multi_target_unlock":
			return get_perm_cost(100000, 0, 0) # Flat, non-scaling cost
		_:
			return 0

func upgrade_permanent(key: String) -> bool:
	match key:
		"projectile_damage":
			return upgrade_perm_projectile_damage()
		"fire_rate":
			return upgrade_perm_projectile_fire_rate()
		"crit_chance":
			return upgrade_perm_crit_chance()
		"crit_damage":
			return upgrade_perm_crit_damage()
		"shield_integrity":
			return upgrade_perm_shield_integrity()
		"shield_regen":
			return upgrade_perm_shield_regen()
		"damage_reduction":
			return upgrade_perm_damage_reduction()
		"data_credit_multiplier":
			return upgrade_perm_data_credit_multiplier()
		"archive_token_multiplier":
			return upgrade_perm_archive_token_multiplier()
		"wave_skip_chance":
			return upgrade_perm_wave_skip_chance()
		"free_upgrade_chance":
			return upgrade_perm_free_upgrade_chance()
		"multi_target_unlock":
			return upgrade_perm_multi_target_unlock()
		_:
			print("Unknown perm upgrade key:", key)
			return false

func reset_run_upgrades():
	projectile_damage_level = 1
	projectile_fire_rate_level = 0
	crit_chance = 0
	crit_damage_level = 0
	shield_integrity_level = 0
	damage_reduction_level = 0
	shield_regen_level = 0
	data_credit_multiplier_level = 0
	archive_token_multiplier_level = 0
	wave_skip_chance_level = 0
	free_upgrade_chance_level = 50
	# Batch 1 upgrades
	piercing_level = 0
	overkill_damage_level = 0
	projectile_speed_level = 0
	block_chance_level = 0
	block_amount_level = 0
	boss_resistance_level = 0
	# Batch 2 upgrades
	overshield_level = 0
	boss_bonus_level = 0
	lucky_drops_level = 0
	ricochet_chance_level = 0
	ricochet_max_targets_level = 0
	# Multi Target
	multi_target_unlocked = false
	multi_target_level = 0
	# Reset purchase counts for cost scaling
	damage_purchases = 0
	fire_rate_purchases = 0
	crit_chance_purchases = 0
	crit_damage_purchases = 0
	shield_purchases = 0
	damage_reduction_purchases = 0
	shield_regen_purchases = 0
	data_multiplier_purchases = 0
	archive_multiplier_purchases = 0
	wave_skip_purchases = 0
	free_upgrade_purchases = 0
	piercing_purchases = 0
	overkill_purchases = 0
	projectile_speed_purchases = 0
	block_chance_purchases = 0
	block_amount_purchases = 0
	boss_resistance_purchases = 0
	overshield_purchases = 0
	boss_bonus_purchases = 0
	lucky_drops_purchases = 0
	ricochet_chance_purchases = 0
	ricochet_max_targets_purchases = 0
