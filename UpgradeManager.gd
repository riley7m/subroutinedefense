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

# New upgrades
var piercing_level: int = 0
var overkill_damage_level: int = 0
var projectile_speed_level: int = 0
var block_chance_level: int = 0
var block_amount_level: int = 0
var boss_resistance_level: int = 0

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
var multi_target_level: int = 0
const MULTI_TARGET_BASE_COST := 1000
const MULTI_TARGET_MAX_LEVEL := 9   # (max 10 targets total)
const MULTI_TARGET_COST_SCALE := 2.5  # Exponential cost
const MULTI_TARGET_INITIAL_LOCKED := true
var multi_target_unlocked := false

# --- PERMANENT UPGRADE COSTS ---
func get_perm_cost(base: int, increment: int, level: int) -> int:
	return base + (increment * level)

func get_perm_drone_upgrade_cost(level: int) -> int:
	return 2500 + level * 1000

# --- UPGRADE GETTERS (add permanent bonuses!) ---
func get_projectile_damage() -> int:
	var level = projectile_damage_level
	var base = 100 + (floor(5 * pow(level, 1.12) + 5))
	var milestones = floor(level / 100)
	# Cap milestones at 500 to prevent overflow (pow(1.5, 500) ≈ 10^88)
	# Beyond this, only base scaling continues to grow
	var multiplier = pow(1.5, min(milestones, 500))
	return int(base * multiplier) + RewardManager.perm_projectile_damage

func get_projectile_fire_rate() -> float:
	return base_fire_rate + projectile_fire_rate_level * FIRE_RATE_PER_UPGRADE + RewardManager.perm_projectile_fire_rate

func get_crit_chance() -> int:
	return crit_chance + RewardManager.perm_crit_chance

func get_crit_damage_multiplier() -> float:
	return BASE_CRIT_MULTIPLIER + (crit_damage_level * CRIT_DAMAGE_PER_LEVEL) + RewardManager.perm_crit_damage

func get_shield_capacity() -> int:
	return BASE_SHIELD + (shield_integrity_level * SHIELD_PER_LEVEL) + RewardManager.perm_shield_integrity

func get_damage_reduction_level() -> float:
	return damage_reduction_level * 0.5 + RewardManager.perm_damage_reduction

func get_shield_regen_rate() -> float:
	return shield_regen_level * SHIELD_REGEN_PER_LEVEL + RewardManager.perm_shield_regen

func get_data_credit_multiplier() -> float:
	return 1.0 + (data_credit_multiplier_level * DATA_MULTIPLIER_PER_LEVEL) + RewardManager.perm_data_credit_multiplier

func get_archive_token_multiplier() -> float:
	return 1.0 + (archive_token_multiplier_level * ARCHIVE_MULTIPLIER_PER_LEVEL) + RewardManager.perm_archive_token_multiplier

func get_wave_skip_chance() -> float:
	return min(wave_skip_chance_level * WAVE_SKIP_CHANCE_PER_LEVEL + RewardManager.perm_wave_skip_chance, WAVE_SKIP_MAX_CHANCE)

func get_free_upgrade_chance() -> float:
	return min(free_upgrade_chance_level * FREE_UPGRADE_CHANCE_PER_LEVEL + RewardManager.perm_free_upgrade_chance, FREE_UPGRADE_MAX_CHANCE)

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
	RewardManager.perm_free_upgrade_chance += 1.0
	RewardManager.save_permanent_upgrades()
	print("🏅 Permanent Free Upgrade Chance +1%. Now:", RewardManager.perm_free_upgrade_chance)
	return true


func upgrade_perm_drone_flame():
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_flame_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Flame Drone.")
		return
	RewardManager.fragments -= cost
	RewardManager.perm_drone_flame_level += 1
	RewardManager.save_permanent_upgrades()
	print("🔥 Flame Drone permanently upgraded! Now:", RewardManager.perm_drone_flame_level)

func upgrade_perm_drone_frost():
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_frost_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Frost Drone.")
		return
	RewardManager.fragments -= cost
	RewardManager.perm_drone_frost_level += 1
	RewardManager.save_permanent_upgrades()
	print("❄️ Frost Drone permanently upgraded! Now:", RewardManager.perm_drone_frost_level)

func upgrade_perm_drone_poison():
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_poison_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Poison Drone.")
		return
	RewardManager.fragments -= cost
	RewardManager.perm_drone_poison_level += 1
	RewardManager.save_permanent_upgrades()
	print("🟣 Poison Drone permanently upgraded! Now:", RewardManager.perm_drone_poison_level)

func upgrade_perm_drone_shock():
	var cost = get_perm_drone_upgrade_cost(RewardManager.perm_drone_shock_level)
	if RewardManager.fragments < cost:
		print("❌ Not enough Fragments to upgrade Shock Drone.")
		return
	RewardManager.fragments -= cost
	RewardManager.perm_drone_shock_level += 1
	RewardManager.save_permanent_upgrades()
	print("⚡ Shock Drone permanently upgraded! Now:", RewardManager.perm_drone_shock_level)

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
