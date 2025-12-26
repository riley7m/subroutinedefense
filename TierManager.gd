extends Node

# Tier System - Provides endgame progression
# Players reach wave milestones to unlock higher tiers with increased difficulty and rewards

signal tier_changed(new_tier: int)
signal tier_unlocked(tier: int)

# Tier Configuration
const MAX_TIERS := 10
const WAVES_PER_TIER := 5000  # Waves needed to unlock next tier
const ENEMY_MULTIPLIER_BASE := 10.0  # 10x per tier
const REWARD_MULTIPLIER_BASE := 5.0  # 5x per tier (1x, 5x, 25x, 125x...)

# Current tier (1-10)
var current_tier: int = 1

# Highest wave reached in each tier
var highest_wave_per_tier: Dictionary = {
	1: 0,
	2: 0,
	3: 0,
	4: 0,
	5: 0,
	6: 0,
	7: 0,
	8: 0,
	9: 0,
	10: 0,
}

# Tier unlock status
var tier_unlocked: Dictionary = {
	1: true,  # Tier 1 always unlocked
	2: false,
	3: false,
	4: false,
	5: false,
	6: false,
	7: false,
	8: false,
	9: false,
	10: false,
}

func _ready() -> void:
	print("🎖️ TierManager initialized")

# Get enemy stat multiplier for current tier
func get_enemy_multiplier() -> float:
	if current_tier == 1:
		return 1.0
	return pow(ENEMY_MULTIPLIER_BASE, current_tier - 1)

# Get reward multiplier for current tier
func get_reward_multiplier() -> float:
	if current_tier == 1:
		return 1.0
	return pow(REWARD_MULTIPLIER_BASE, current_tier - 1)

# Check if a tier is unlocked
func is_tier_unlocked(tier: int) -> bool:
	if tier < 1 or tier > MAX_TIERS:
		return false
	return tier_unlocked.get(tier, false)

# Check if next tier can be unlocked (based on current tier progress)
func can_unlock_next_tier() -> bool:
	if current_tier >= MAX_TIERS:
		return false  # Already at max tier

	var next_tier = current_tier + 1
	if tier_unlocked.get(next_tier, false):
		return true  # Already unlocked

	# Check if reached wave requirement in current tier
	var current_highest = highest_wave_per_tier.get(current_tier, 0)
	return current_highest >= WAVES_PER_TIER

# Unlock next tier (doesn't enter it, just unlocks)
func unlock_next_tier() -> bool:
	if not can_unlock_next_tier():
		return false

	var next_tier = current_tier + 1
	if tier_unlocked.get(next_tier, false):
		return false  # Already unlocked

	tier_unlocked[next_tier] = true
	emit_signal("tier_unlocked", next_tier)
	print("🎖️ Tier %d unlocked! (Reached wave %d in Tier %d)" % [next_tier, highest_wave_per_tier[current_tier], current_tier])
	return true

# Enter a tier (resets to wave 1)
func enter_tier(tier: int) -> bool:
	if tier < 1 or tier > MAX_TIERS:
		push_error("Invalid tier: %d" % tier)
		return false

	if not is_tier_unlocked(tier):
		print("❌ Tier %d not unlocked yet!" % tier)
		return false

	if tier == current_tier:
		print("⚠️ Already in Tier %d" % tier)
		return false

	current_tier = tier
	emit_signal("tier_changed", current_tier)
	print("🎖️ Entered Tier %d! (Enemy stats: %.0fx, Rewards: %.0fx)" % [
		current_tier,
		get_enemy_multiplier(),
		get_reward_multiplier()
	])
	return true

# Update highest wave for current tier
func update_highest_wave(wave: int) -> void:
	var current_highest = highest_wave_per_tier.get(current_tier, 0)
	if wave > current_highest:
		highest_wave_per_tier[current_tier] = wave

		# Check if this unlocks next tier
		if wave >= WAVES_PER_TIER and current_tier < MAX_TIERS:
			unlock_next_tier()

# Get highest wave reached in a specific tier
func get_highest_wave(tier: int) -> int:
	return highest_wave_per_tier.get(tier, 0)

# Get current tier
func get_current_tier() -> int:
	return current_tier

# Get tier info for display
func get_tier_info(tier: int) -> Dictionary:
	if tier < 1 or tier > MAX_TIERS:
		return {}

	var enemy_mult = 1.0 if tier == 1 else pow(ENEMY_MULTIPLIER_BASE, tier - 1)
	var reward_mult = 1.0 if tier == 1 else pow(REWARD_MULTIPLIER_BASE, tier - 1)

	return {
		"tier": tier,
		"unlocked": is_tier_unlocked(tier),
		"highest_wave": highest_wave_per_tier.get(tier, 0),
		"enemy_multiplier": enemy_mult,
		"reward_multiplier": reward_mult,
		"unlock_requirement": WAVES_PER_TIER,
		"is_current": tier == current_tier,
	}

# Get all tier info for UI
func get_all_tier_info() -> Array:
	var info = []
	for i in range(1, MAX_TIERS + 1):
		info.append(get_tier_info(i))
	return info

# Reset current tier to wave 1 (called when entering a tier)
func reset_current_tier_progress() -> void:
	# This would be called by main_hud or spawner when entering a new tier
	# Resets in-run progress but keeps tier unlock status
	print("🔄 Reset Tier %d to wave 1" % current_tier)

# === SAVE/LOAD ===
func save_tier_data() -> Dictionary:
	return {
		"current_tier": current_tier,
		"highest_wave_per_tier": highest_wave_per_tier.duplicate(),
		"tier_unlocked": tier_unlocked.duplicate(),
	}

func load_tier_data(data: Dictionary) -> void:
	current_tier = data.get("current_tier", 1)
	current_tier = clamp(current_tier, 1, MAX_TIERS)

	# Load highest waves
	var saved_highest = data.get("highest_wave_per_tier", {})
	for tier in range(1, MAX_TIERS + 1):
		if saved_highest.has(str(tier)) or saved_highest.has(tier):
			var wave = saved_highest.get(str(tier), saved_highest.get(tier, 0))
			highest_wave_per_tier[tier] = clamp(wave, 0, 999999)

	# Load unlock status
	var saved_unlocked = data.get("tier_unlocked", {})
	tier_unlocked[1] = true  # Tier 1 always unlocked
	for tier in range(2, MAX_TIERS + 1):
		if saved_unlocked.has(str(tier)) or saved_unlocked.has(tier):
			tier_unlocked[tier] = saved_unlocked.get(str(tier), saved_unlocked.get(tier, false))

	print("📊 Loaded tier data: Tier %d, Unlocked: %d tiers" % [
		current_tier,
		tier_unlocked.values().count(true)
	])

# Debug: Print tier status
func print_tier_status() -> void:
	print("\n=== TIER STATUS ===")
	print("Current Tier: %d" % current_tier)
	print("Enemy Multiplier: %.0fx" % get_enemy_multiplier())
	print("Reward Multiplier: %.0fx" % get_reward_multiplier())
	print("\nUnlocked Tiers:")
	for tier in range(1, MAX_TIERS + 1):
		if is_tier_unlocked(tier):
			print("  Tier %d: Wave %d (%.0fx enemies, %.0fx rewards)" % [
				tier,
				highest_wave_per_tier[tier],
				1.0 if tier == 1 else pow(ENEMY_MULTIPLIER_BASE, tier - 1),
				1.0 if tier == 1 else pow(REWARD_MULTIPLIER_BASE, tier - 1)
			])
	print("===================\n")
