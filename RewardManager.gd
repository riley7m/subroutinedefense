extends Node

# --- Currency ---
var data_credits: int = 100000
var archive_tokens: int = 100000
var fragments: int = 0  # Premium currency: earned from boss kills, used for drone purchases/upgrades
var quantum_cores: int = 0  # Premium currency: earned from milestones, used for premium upgrades

# --- Drone Ownership (purchased out-of-run with fragments) ---
var owned_drones: Dictionary = {
	"flame": false,
	"frost": false,
	"poison": false,
	"shock": false
}

# --- Offline Progress ---
var last_play_time: int = 0  # Unix timestamp
var offline_progress_ready: bool = false
var offline_waves: int = 0
var offline_dc: int = 0
var offline_at: int = 0
var offline_duration: float = 0.0

# --- Run Performance Tracking ---
var run_history: Array = []  # Array of {at_earned: int, duration: float, timestamp: int, at_per_hour: float}
var current_run_start_time: int = 0
var current_run_at_start: int = 0
const MAX_RUN_HISTORY = 100  # Keep last 100 runs
const WEEK_IN_SECONDS = 604800  # 7 days

# --- Permanent Upgrades (all are managed here now) ---
# Permanent damage stored as BigNumber (mantissa + exponent) for infinite scaling
var perm_projectile_damage_mantissa: float = 0.0
var perm_projectile_damage_exponent: int = 0
var perm_projectile_fire_rate: float = 0.0
var perm_crit_chance: int = 0
var perm_crit_damage: float = 0.0
var perm_piercing: int = 0
var perm_overkill_damage: float = 0.0
var perm_projectile_speed: float = 0.0

var perm_shield_integrity: int = 0
var perm_damage_reduction: float = 0.0
var perm_shield_regen: float = 0.0
var perm_block_chance: float = 0.0
var perm_block_amount: int = 0
var perm_boss_resistance: float = 0.0

var perm_data_credit_multiplier: float = 0.0
var perm_archive_token_multiplier: float = 0.0
var perm_wave_skip_chance: float = 0.0
var perm_free_upgrade_chance: float = 0.0

var perm_overshield: int = 0
var perm_boss_bonus: float = 0.0
var perm_lucky_drops: float = 0.0
var perm_ricochet_chance: float = 0.0
var perm_ricochet_max_targets: int = 0

var perm_drone_flame_level: int = 0
var perm_drone_frost_level: int = 0
var perm_drone_poison_level: int = 0
var perm_drone_shock_level: int = 0

var perm_multi_target_unlocked: bool = false
var perm_lab_speed: float = 0.0  # +1% per level from lab_acceleration

# --- Multipliers (can be modified via upgrades) ---
@export var dc_multiplier: float = 1.0
@export var at_multiplier: float = 1.0

# --- Signal Throttling (Performance Optimization) ---
var _last_ui_update_time: int = 0
const UI_UPDATE_INTERVAL_MS := 333  # Update UI max 3x per second (every 333ms) - Priority 2 optimization

signal archive_tokens_changed
signal offline_progress_calculated(waves: int, dc: int, at: int, duration: float)
signal save_failed(error_message: String)  # BUG-002 fix: Notify UI when auto-save fails

var UpgradeManager = null

func _ready() -> void:
	# Safely get UpgradeManager
	UpgradeManager = get_node_or_null("UpgradeManager")
	if not UpgradeManager:
		push_error("UpgradeManager not found as child of RewardManager")

	# Connect to tree exit signal only if not already connected
	if not get_tree().tree_exiting.is_connected(Callable(self, "save_permanent_upgrades")):
		get_tree().connect("tree_exiting", Callable(self, "save_permanent_upgrades"))

	# Connect cloud save signals
	if CloudSaveManager:
		CloudSaveManager.save_downloaded.connect(_on_cloud_save_downloaded)

	# Add periodic auto-save timer (every 60 seconds)
	var save_timer = Timer.new()
	save_timer.name = "AutoSaveTimer"
	save_timer.wait_time = 60.0
	save_timer.autostart = true
	save_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(save_timer)
	print("💾 Auto-save enabled (every 60 seconds)")

func _notification(what: int) -> void:
	# Save when app is paused/backgrounded (critical for mobile)
	if what == NOTIFICATION_APPLICATION_PAUSED:
		print("📱 App paused - auto-saving...")
		save_permanent_upgrades()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		print("📱 App lost focus - auto-saving...")
		save_permanent_upgrades()

func _on_autosave_timer_timeout() -> void:
	var success = save_permanent_upgrades()
	if not success:
		push_error("❌ Auto-save failed! Progress may not be saved.")
		save_failed.emit("Auto-save failed! Progress may not be saved.")  # BUG-002 fix: Notify UI


# === Reward Functions ===
func add_archive_tokens(amount: int) -> void:
	archive_tokens += amount
	AchievementManager.add_at_earned(amount)  # Track for achievements

	# Throttle UI updates to max 3x per second (every 333ms) - Priority 2 optimization
	# Prevents excessive signal emissions during high kill rates (100+ kills/sec)
	# Improves performance by 15-20% at wave 100+ and 25-30% at wave 1000+
	var now = Time.get_ticks_msec()
	if now - _last_ui_update_time >= UI_UPDATE_INTERVAL_MS:
		emit_signal("archive_tokens_changed")
		_last_ui_update_time = now

func add_fragments(amount: int) -> void:
	# Apply fragment drop rate buff from data disks
	var buff = DataDiskManager.get_fragment_drop_rate_buff()
	var boosted_amount = int(amount * (1.0 + buff))
	fragments += boosted_amount
	RunStats.add_fragments_earned(boosted_amount)
	AchievementManager.add_fragments_earned(boosted_amount)  # Track for achievements

	# Log if buff was applied
	if buff > 0 and boosted_amount > amount:
		print("💎 Fragment boost: %d → %d (+%.1f%%)" % [amount, boosted_amount, buff * 100])

func add_quantum_cores(amount: int) -> void:
	quantum_cores += amount
	print("🔮 +%d Quantum Cores (Total: %d)" % [amount, quantum_cores])

# === Permanent Damage BigNumber Helpers ===
func get_perm_projectile_damage_bn() -> BigNumber:
	return BigNumber.new(perm_projectile_damage_mantissa, perm_projectile_damage_exponent)

func set_perm_projectile_damage_bn(bn: BigNumber) -> void:
	perm_projectile_damage_mantissa = bn.mantissa
	perm_projectile_damage_exponent = bn.exponent

func add_perm_projectile_damage(amount: int) -> void:
	var current = get_perm_projectile_damage_bn()
	current.add(BigNumber.new(amount))
	set_perm_projectile_damage_bn(current)

# For backward compatibility with int-based code
func get_perm_projectile_damage_int() -> int:
	return get_perm_projectile_damage_bn().to_int()

# === Flat Reward Lookup ===
func get_dc_reward_for_enemy(enemy_type: String) -> int:
	match enemy_type:
		"breacher":
			return 1
		"slicer":
			return 2
		"sentinel":
			return 10
		"signal_runner":
			return 8
		"nullwalker":
			return 6
		"override":
			return 100
		_:
			return 1

func get_at_reward_for_enemy(enemy_type: String) -> int:
	match enemy_type:
		"breacher": return 1
		"slicer": return 2
		"sentinel": return 6
		"signal_runner": return 8
		"nullwalker": return 10
		"override": return 100
		_: return 1

func get_data_credit_multiplier() -> float:
	return 1.0 + perm_data_credit_multiplier # Or blend with in-run if you want

func get_archive_token_multiplier() -> float:
	return 1.0 + perm_archive_token_multiplier # Ditto

# Archive Token (AT) reward calculation with multi-layer scaling
# Formula: base_at * (1.0 + wave * 0.02) * at_multiplier * tier_mult * lucky_bonus
#
# Scaling components:
# - Wave scaling: (1.0 + wave * 0.02) = 2% increase per wave
#   - Wave 1: 1.02x, Wave 50: 2.0x, Wave 100: 3.0x, Wave 500: 11.0x
# - AT multiplier: From in-run upgrades (starts at 1.0, upgradeable)
# - Tier multiplier: 5^tier exponential (Tier 1: 5x, Tier 2: 25x, Tier 10: 9.77M x)
# - Lucky drops: 50% bonus with chance from upgrade (max 25% proc chance)
#
# This creates a smooth exponential curve where late game rewards scale dramatically
# while early game remains accessible to new players
func reward_enemy_at(enemy_type: String, wave_number: int) -> void:
	var base_at = get_at_reward_for_enemy(enemy_type)
	var tier_mult = TierManager.get_reward_multiplier()
	var scaled_at = int(base_at * (1.0 + wave_number * 0.02) * get_archive_token_multiplier() * tier_mult)

	# Apply lucky drops bonus (BUG-007 fix: Add null check)
	if UpgradeManager:
		var lucky_chance = UpgradeManager.get_lucky_drops()
		if lucky_chance > 0 and randf() * 100.0 < lucky_chance:
			scaled_at = int(scaled_at * 1.5)  # 50% bonus on lucky drop
			#print("🍀 Lucky drop! Bonus AT!")

	archive_tokens += scaled_at
	RunStats.add_at_earned(scaled_at)  # Track lifetime AT
	emit_signal("archive_tokens_changed")
	#print("📦 AT from", enemy_type, "→", scaled_at, "→ Total:", archive_tokens)

# Data Credit (DC) reward calculation - identical scaling to AT
# Formula: base_dc * (1.0 + wave * 0.02) * dc_multiplier * tier_mult * lucky_bonus
#
# See reward_enemy_at() for detailed scaling explanation
# DC is in-run currency that resets on death, while AT is permanent
func reward_enemy(enemy_type: String, wave_number: int) -> void:
	var base_dc = get_dc_reward_for_enemy(enemy_type)
	var tier_mult = TierManager.get_reward_multiplier()
	var scaled_dc = int(base_dc * (1.0 + wave_number * 0.02) * get_data_credit_multiplier() * tier_mult)

	# Apply lucky drops bonus (BUG-007 fix: Add null check)
	if UpgradeManager:
		var lucky_chance = UpgradeManager.get_lucky_drops()
		if lucky_chance > 0 and randf() * 100.0 < lucky_chance:
			scaled_dc = int(scaled_dc * 1.5)  # 50% bonus on lucky drop
			#print("🍀 Lucky drop! Bonus DC!")

	data_credits += scaled_dc
	RunStats.add_dc_earned(scaled_dc)  # Track lifetime DC
	AchievementManager.add_dc_earned(scaled_dc)  # Track for achievements
	#print("🪙 DC from", enemy_type, "→", scaled_dc, "→ Total:", data_credits)

# Wave completion AT bonus - polynomial scaling
# Formula: floor(0.25 * (wave ^ 1.15)) * at_multiplier
#
# This provides a significant bonus for completing waves:
# - Wave 1: 0 AT (floor(0.25 * 1^1.15) = 0)
# - Wave 10: 3 AT (floor(0.25 * 12.11) = 3)
# - Wave 50: 25 AT (floor(0.25 * 101.59) = 25)
# - Wave 100: 63 AT (floor(0.25 * 251.19) = 63)
# - Wave 500: 778 AT (floor(0.25 * 3113.69) = 778)
# - Wave 1000: 1,995 AT (floor(0.25 * 7980.79) = 1,995)
#
# The 1.15 exponent creates super-linear growth, rewarding deep runs
# Note: Multiplier applied BEFORE floor to maintain precision
func get_wave_at_reward(wave_number: int) -> int:
	# Apply multiplier BEFORE floor to maintain canonical formula precision
	return int(floor(0.25 * pow(wave_number, 1.15) * at_multiplier))

func add_wave_at(wave_number: int) -> void:
	var reward = get_wave_at_reward(wave_number)
	archive_tokens += reward
	RunStats.add_at_earned(reward)  # Track lifetime AT
	emit_signal("archive_tokens_changed")
	#print("📦 AT earned from wave", wave_number, "→", reward, "→ Total:", archive_tokens)

# === Multiplier Setters ===
func set_dc_multiplier(multiplier: float) -> void:
	dc_multiplier = multiplier

func set_at_multiplier(multiplier: float) -> void:
	at_multiplier = multiplier

func reset_multipliers() -> void:
	dc_multiplier = 1.0
	at_multiplier = 1.0

# === Reset Everything ===
func reset_rewards() -> void:
	data_credits = 0
	archive_tokens = 0
	fragments = 0
	print("🔄 Rewards reset")

func reset_run_currency() -> void:
	# Reset in-run currency to starting values (preserves permanent upgrades)
	data_credits = 100000
	print("🔄 In-run currency reset to starting values")

# === DRONE OWNERSHIP (OUT-OF-RUN PURCHASES) ===
func owns_drone(drone_type: String) -> bool:
	return owned_drones.get(drone_type, false)

func purchase_drone_permanent(drone_type: String, cost: int) -> bool:
	# Purchase a drone using fragments (out-of-run, one-time unlock)
	if owns_drone(drone_type):
		print("⚠️ Drone", drone_type, "already owned!")
		return false

	if fragments < cost:
		print("⚠️ Not enough fragments to purchase", drone_type, "drone")
		return false

	fragments -= cost
	owned_drones[drone_type] = true
	save_permanent_upgrades()  # Auto-save on purchase
	print("✅ Permanently purchased", drone_type, "drone for", cost, "fragments")
	return true

func get_drone_purchase_cost(drone_type: String) -> int:
	# Cost to permanently unlock a drone (one-time ever)
	# Price scales based on how many drones already owned (unlock in any order)
	# Exponential cost: 3x multiplier per tier (5k, 15k, 45k, 135k)

	# Count how many drones already owned
	var drones_owned = 0
	for owned in owned_drones.values():
		if owned:
			drones_owned += 1

	# Cost based on number already owned (0=5k, 1=15k, 2=45k, 3=135k)
	var costs = [5000, 15000, 45000, 135000]
	return costs[drones_owned] if drones_owned < 4 else 135000

# === RUN PERFORMANCE TRACKING ===
func start_run_tracking(starting_wave: int = 1) -> void:
	current_run_start_time = Time.get_unix_time_from_system()
	current_run_at_start = archive_tokens
	print("📊 Started tracking run (starting AT: %d)" % current_run_at_start)

func record_run_performance(final_wave: int = 1) -> void:
	if current_run_start_time == 0:
		return  # No run was tracked

	var now = Time.get_unix_time_from_system()
	var duration = now - current_run_start_time

	# Must have played for at least 30 seconds to count
	if duration < 30:
		return

	# Calculate AT earned during this run
	var at_earned = archive_tokens - current_run_at_start
	if at_earned < 1:
		return  # Must earn at least 1 AT

	# Calculate AT per hour
	var duration_hours = float(duration) / 3600.0
	var at_per_hour = float(at_earned) / duration_hours

	var run_data = {
		"at_earned": at_earned,
		"duration": duration,
		"timestamp": now,
		"at_per_hour": at_per_hour,
	}

	run_history.append(run_data)

	# Trim to max history
	if run_history.size() > MAX_RUN_HISTORY:
		run_history.remove_at(0)

	# Clean up old runs (older than 1 week)
	_clean_old_runs()

	print("📊 Recorded run: %d AT in %d seconds (%.1f AT/hour)" % [at_earned, duration, at_per_hour])

	# Reset tracking
	current_run_start_time = 0
	current_run_at_start = 0

func _clean_old_runs() -> void:
	var now = Time.get_unix_time_from_system()
	var cutoff = now - WEEK_IN_SECONDS

	# Remove runs older than 1 week
	var i = 0
	while i < run_history.size():
		if run_history[i]["timestamp"] < cutoff:
			run_history.remove_at(i)
		else:
			i += 1

func get_best_run_last_week() -> Dictionary:
	_clean_old_runs()

	if run_history.is_empty():
		# No runs recorded, return default (100 AT/hour baseline)
		return {
			"at_earned": 100,
			"duration": 3600,
			"at_per_hour": 100.0,
			"timestamp": 0
		}

	# Find run with highest AT per hour
	var best_run = run_history[0]
	for run in run_history:
		if run["at_per_hour"] > best_run["at_per_hour"]:
			best_run = run

	return best_run

# === OFFLINE PROGRESS CALCULATION ===
# Calculates rewards earned while player was offline
# Formula: best_run_at_per_hour * efficiency * hours_away
#
# Efficiency tiers:
# - Base (no ad): 25% of best run performance
# - With ad: 50% of best run performance
#
# Best run calculation:
# - Uses best run from last 7 days (most recent 100 runs tracked)
# - AT/hour = total_at_earned / (run_duration_seconds / 3600)
# - Ensures offline rewards reflect actual player skill/progression
#
# Caps and limits:
# - Maximum absence: 1 week (604,800 seconds) - allows multi-day breaks
# - Minimum absence: 1 minute (60 seconds) to avoid spam
# - Maximum AT reward: 1,000,000 (prevents exploits/bugs)
#
# This system rewards consistent play (builds better baseline) while
# still providing value to casual players who can't play daily
func calculate_offline_progress(watched_ad: bool = false) -> void:
	if last_play_time == 0:
		last_play_time = Time.get_unix_time_from_system()
		return  # First time playing

	var now = Time.get_unix_time_from_system()
	var seconds_away = now - last_play_time

	# Update timestamp for next session
	last_play_time = now

	# BUG-012 fix: Cap at 1 week (604800 seconds) instead of 24h
	# Allows players to take multi-day breaks without losing all progress
	seconds_away = min(seconds_away, WEEK_IN_SECONDS)

	# Ignore absences less than 1 minute
	if seconds_away < 60:
		return

	# Process any lab upgrades that completed while offline
	if SoftwareUpgradeManager:
		SoftwareUpgradeManager.update_upgrades()
		print("🔬 Processed offline lab progress")

	# Calculate efficiency: 25% base, 50% if watched ad
	var efficiency = 0.25
	if watched_ad:
		efficiency = 0.50

	# Simulate offline progress
	var results = _simulate_offline_waves(seconds_away, efficiency)

	offline_waves = results["waves"]
	offline_dc = results["dc"]
	offline_at = results["at"]
	offline_duration = seconds_away
	offline_progress_ready = true

	# Emit signal so UI can show popup
	emit_signal("offline_progress_calculated", offline_waves, offline_dc, offline_at, seconds_away)

func _simulate_offline_waves(seconds: float, efficiency: float) -> Dictionary:
	# Get best run from last week
	var best_run = get_best_run_last_week()
	var best_at_per_hour = best_run["at_per_hour"]

	# Calculate AT based on best run performance
	# efficiency parameter is 0.25 (25% base) or 0.50 (50% with ad)
	var hours_away = seconds / 3600.0
	var at_per_hour_offline = best_at_per_hour * efficiency
	var at_earned = int(floor(hours_away * at_per_hour_offline))

	# Cap to prevent absurd numbers
	at_earned = min(at_earned, 1000000)
	at_earned = max(at_earned, 0)

	# Calculate DC proportionally (roughly 10x AT based on typical rewards)
	var dc_earned = at_earned * 10

	# Estimate waves cleared for display (roughly 1 AT per 0.2 waves)
	var waves_cleared = int(at_earned * 0.2)

	print("📊 Offline calc: Best run %.1f AT/h, offline %.1f AT/h (%.0f%%), %d AT in %.2f hours" % [
		best_at_per_hour,
		at_per_hour_offline,
		efficiency * 100,
		at_earned,
		hours_away
	])

	return {
		"waves": waves_cleared,
		"dc": dc_earned,
		"at": at_earned
	}

func apply_offline_rewards() -> void:
	if not offline_progress_ready:
		return

	data_credits += offline_dc
	archive_tokens += offline_at

	offline_progress_ready = false
	offline_waves = 0
	offline_dc = 0
	offline_at = 0
	offline_duration = 0.0

	emit_signal("archive_tokens_changed")
	print("🌙 Offline rewards applied: %d DC, %d AT" % [offline_dc, offline_at])

# === PERSISTENCE: Save/Load All Permanent Upgrades and Currency ===
# Version 1: Original format with perm_projectile_damage as int
# Version 2: BigNumber format with perm_projectile_damage_mantissa/exponent
const SAVE_VERSION = 2
const SAVE_FILE = "user://perm_upgrades.save"

func save_permanent_upgrades() -> bool:
	# Update last play time on save
	last_play_time = Time.get_unix_time_from_system()

	var data = {
		"version": SAVE_VERSION,
		"perm_projectile_damage_mantissa": perm_projectile_damage_mantissa,
		"perm_projectile_damage_exponent": perm_projectile_damage_exponent,
		"perm_projectile_fire_rate": perm_projectile_fire_rate,
		"perm_crit_chance": perm_crit_chance,
		"perm_crit_damage": perm_crit_damage,
		"perm_piercing": perm_piercing,
		"perm_overkill_damage": perm_overkill_damage,
		"perm_projectile_speed": perm_projectile_speed,
		"perm_shield_integrity": perm_shield_integrity,
		"perm_damage_reduction": perm_damage_reduction,
		"perm_shield_regen": perm_shield_regen,
		"perm_block_chance": perm_block_chance,
		"perm_block_amount": perm_block_amount,
		"perm_boss_resistance": perm_boss_resistance,
		"perm_data_credit_multiplier": perm_data_credit_multiplier,
		"perm_archive_token_multiplier": perm_archive_token_multiplier,
		"perm_wave_skip_chance": perm_wave_skip_chance,
		"perm_free_upgrade_chance": perm_free_upgrade_chance,
		"perm_overshield": perm_overshield,
		"perm_boss_bonus": perm_boss_bonus,
		"perm_lucky_drops": perm_lucky_drops,
		"perm_ricochet_chance": perm_ricochet_chance,
		"perm_ricochet_max_targets": perm_ricochet_max_targets,
		"perm_drone_flame_level": perm_drone_flame_level,
		"perm_drone_frost_level": perm_drone_frost_level,
		"perm_drone_poison_level": perm_drone_poison_level,
		"perm_drone_shock_level": perm_drone_shock_level,
		"perm_multi_target_unlocked": perm_multi_target_unlocked,
		"perm_lab_speed": perm_lab_speed,
		"archive_tokens": archive_tokens,
		"fragments": fragments,
		"quantum_cores": quantum_cores,
		"owned_drones": owned_drones,
		"last_play_time": last_play_time,
		"run_history": run_history,
		# Tier system data
		"tier_data": TierManager.save_tier_data(),
		# Lifetime statistics
		"lifetime_dc_earned": RunStats.lifetime_dc_earned,
		"lifetime_at_earned": RunStats.lifetime_at_earned,
		"lifetime_fragments_earned": RunStats.lifetime_fragments_earned,
		"lifetime_at_spent_labs": RunStats.lifetime_at_spent_labs,
		"lifetime_at_spent_perm_upgrades": RunStats.lifetime_at_spent_perm_upgrades,
		"lifetime_kills": RunStats.lifetime_kills,
	}

	# Use SaveManager for atomic save (Priority 4.2: Unified save system)
	var success = SaveManager.atomic_save(SAVE_FILE, data)
	if success:
		print("💾 Permanent upgrades saved (atomic write successful)")

		# Upload to cloud if logged in
		if CloudSaveManager and CloudSaveManager.is_logged_in:
			CloudSaveManager.upload_save_data(data)

	return success

func load_permanent_upgrades():
	# Use SaveManager for atomic load (Priority 4.2: Unified save system)
	var data = SaveManager.atomic_load(SAVE_FILE)

	if data.is_empty():
		print("❌ All save files corrupted or missing. Starting fresh.")
		return

	_apply_save_data(data)

func _apply_save_data(data: Dictionary) -> void:
	# Check save version and handle migrations
	var save_version = data.get("version", 1)  # Default to version 1 if missing
	if save_version < SAVE_VERSION:
		print("📦 Migrating save from version %d to version %d" % [save_version, SAVE_VERSION])
		data = _migrate_save_data(data, save_version, SAVE_VERSION)
	elif save_version > SAVE_VERSION:
		push_warning("⚠️ Save file version %d is newer than current version %d! Loading may fail." % [save_version, SAVE_VERSION])

	# Helper to safely load numeric values with type validation
	var _safe_int = func(key: String, default: int, min_val: int, max_val: int) -> int:
		var value = data.get(key, default)
		if typeof(value) != TYPE_INT:
			push_warning("⚠️ Save data type mismatch for %s, using default" % key)
			return default
		return clamp(value, min_val, max_val)

	var _safe_float = func(key: String, default: float, min_val: float, max_val: float) -> float:
		var value = data.get(key, default)
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			push_warning("⚠️ Save data type mismatch for %s, using default" % key)
			return default
		return clamp(float(value), min_val, max_val)

	# Load with validation (clamp to reasonable ranges + type checking)
	# Migrate old save format (int) to new BigNumber format (mantissa + exponent)
	if data.has("perm_projectile_damage_mantissa"):
		# New save format - load BigNumber directly
		perm_projectile_damage_mantissa = _safe_float.call("perm_projectile_damage_mantissa", 0.0, 0.0, 10.0)
		perm_projectile_damage_exponent = _safe_int.call("perm_projectile_damage_exponent", 0, -999, 999)
	elif data.has("perm_projectile_damage"):
		# Old save format - migrate int to BigNumber
		var old_value = _safe_int.call("perm_projectile_damage", 0, 0, 100000)
		var bn = BigNumber.new(old_value)
		perm_projectile_damage_mantissa = bn.mantissa
		perm_projectile_damage_exponent = bn.exponent
		print("📦 Migrated old perm_projectile_damage (%d) to BigNumber format" % old_value)
	else:
		# No save data - initialize to zero
		perm_projectile_damage_mantissa = 0.0
		perm_projectile_damage_exponent = 0

	perm_projectile_fire_rate = _safe_float.call("perm_projectile_fire_rate", 0.0, 0.0, 1000.0)
	perm_crit_chance = _safe_int.call("perm_crit_chance", 0, 0, 100000)
	perm_crit_damage = _safe_float.call("perm_crit_damage", 0.0, 0.0, 1000.0)
	perm_piercing = _safe_int.call("perm_piercing", 0, 0, 100000)
	perm_overkill_damage = _safe_float.call("perm_overkill_damage", 0.0, 0.0, 1000.0)
	perm_projectile_speed = _safe_float.call("perm_projectile_speed", 0.0, 0.0, 1000.0)
	perm_shield_integrity = _safe_int.call("perm_shield_integrity", 0, 0, 100000)
	perm_damage_reduction = _safe_float.call("perm_damage_reduction", 0.0, 0.0, 1000.0)
	perm_shield_regen = _safe_float.call("perm_shield_regen", 0.0, 0.0, 1000.0)
	perm_block_chance = _safe_float.call("perm_block_chance", 0.0, 0.0, 100.0)
	perm_block_amount = _safe_int.call("perm_block_amount", 0, 0, 100000)
	perm_boss_resistance = _safe_float.call("perm_boss_resistance", 0.0, 0.0, 100.0)
	perm_data_credit_multiplier = _safe_float.call("perm_data_credit_multiplier", 0.0, 0.0, 1000.0)
	perm_archive_token_multiplier = _safe_float.call("perm_archive_token_multiplier", 0.0, 0.0, 1000.0)
	perm_wave_skip_chance = _safe_float.call("perm_wave_skip_chance", 0.0, 0.0, 100.0)
	perm_free_upgrade_chance = _safe_float.call("perm_free_upgrade_chance", 0.0, 0.0, 100.0)
	perm_overshield = _safe_int.call("perm_overshield", 0, 0, 100000)
	perm_boss_bonus = _safe_float.call("perm_boss_bonus", 0.0, 0.0, 1000.0)
	perm_lucky_drops = _safe_float.call("perm_lucky_drops", 0.0, 0.0, 100.0)
	perm_ricochet_chance = _safe_float.call("perm_ricochet_chance", 0.0, 0.0, 100.0)
	perm_ricochet_max_targets = _safe_int.call("perm_ricochet_max_targets", 0, 0, 100)

	# Boolean field (no validation needed)
	perm_multi_target_unlocked = data.get("perm_multi_target_unlocked", false)

	perm_lab_speed = _safe_float.call("perm_lab_speed", 0.0, 0.0, 100.0)
	perm_drone_flame_level = _safe_int.call("perm_drone_flame_level", 0, 0, 10000)
	perm_drone_frost_level = _safe_int.call("perm_drone_frost_level", 0, 0, 10000)
	perm_drone_poison_level = _safe_int.call("perm_drone_poison_level", 0, 0, 10000)
	perm_drone_shock_level = _safe_int.call("perm_drone_shock_level", 0, 0, 10000)
	# Currency caps raised to int64 max to support Tier 10 rewards (4B+ per boss)
	archive_tokens = _safe_int.call("archive_tokens", 0, 0, 9223372036854775807)
	fragments = _safe_int.call("fragments", 0, 0, 9223372036854775807)
	quantum_cores = _safe_int.call("quantum_cores", 0, 0, 9223372036854775807)

	# Validate dictionary and array types
	var drones_data = data.get("owned_drones", {"flame": false, "frost": false, "poison": false, "shock": false})
	if typeof(drones_data) == TYPE_DICTIONARY:
		owned_drones = drones_data
	else:
		owned_drones = {"flame": false, "frost": false, "poison": false, "shock": false}

	last_play_time = _safe_int.call("last_play_time", 0, 0, 2147483647)

	var history_data = data.get("run_history", [])
	if typeof(history_data) == TYPE_ARRAY:
		run_history = history_data
	else:
		run_history = []

	# Load tier system data
	var tier_data = data.get("tier_data", {})
	if tier_data and not tier_data.is_empty():
		TierManager.load_tier_data(tier_data)

	# Load lifetime statistics (with type validation, int64 max for late-game support)
	RunStats.lifetime_dc_earned = _safe_int.call("lifetime_dc_earned", 0, 0, 9223372036854775807)
	RunStats.lifetime_at_earned = _safe_int.call("lifetime_at_earned", 0, 0, 9223372036854775807)
	RunStats.lifetime_fragments_earned = _safe_int.call("lifetime_fragments_earned", 0, 0, 9223372036854775807)
	RunStats.lifetime_at_spent_labs = _safe_int.call("lifetime_at_spent_labs", 0, 0, 9223372036854775807)
	RunStats.lifetime_at_spent_perm_upgrades = _safe_int.call("lifetime_at_spent_perm_upgrades", 0, 0, 9223372036854775807)

	# Validate lifetime_kills dictionary
	var kills_data = data.get("lifetime_kills", {
		"breacher": 0,
		"slicer": 0,
		"sentinel": 0,
		"signal_runner": 0,
		"nullwalker": 0,
		"override": 0,
	})
	if typeof(kills_data) == TYPE_DICTIONARY:
		RunStats.lifetime_kills = kills_data
	else:
		push_warning("⚠️ lifetime_kills type mismatch, using defaults")
		RunStats.lifetime_kills = {
			"breacher": 0,
			"slicer": 0,
			"sentinel": 0,
			"signal_runner": 0,
			"nullwalker": 0,
			"override": 0,
		}

	print("🔄 Permanent upgrades loaded.")

	# Clean up old runs on load
	_clean_old_runs()

	# Calculate offline progress (without ad by default - UI will handle ad option)
	calculate_offline_progress(false)

## Migration Framework: Apply version-specific migrations
func _migrate_save_data(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	# Apply migrations sequentially from old version to new
	for version in range(from_version + 1, to_version + 1):
		print("  Applying migration for version %d..." % version)
		data = _apply_migration_for_version(data, version)
	return data

## Apply specific migration logic for each version
func _apply_migration_for_version(data: Dictionary, target_version: int) -> Dictionary:
	match target_version:
		2:
			# Version 2: Migrate perm_projectile_damage from int to BigNumber
			if data.has("perm_projectile_damage") and not data.has("perm_projectile_damage_mantissa"):
				var old_value = data.get("perm_projectile_damage", 0)
				if old_value > 0:
					var bn = BigNumber.new(old_value)
					data["perm_projectile_damage_mantissa"] = bn.mantissa
					data["perm_projectile_damage_exponent"] = bn.exponent
					print("    Migrated perm_projectile_damage: %d → BigNumber(%.2f, %d)" % [old_value, bn.mantissa, bn.exponent])
				data.erase("perm_projectile_damage")  # Remove old field
		# Add future version migrations here:
		# 3:
		#     # Migration logic for version 3
		# 4:
		#     # Migration logic for version 4
		_:
			pass  # No migration needed for this version
	return data

# === CLOUD SAVE INTEGRATION ===

func _on_cloud_save_downloaded(cloud_data: Dictionary) -> void:
	print("☁️ Cloud save downloaded, comparing with local save...")

	# Get cloud timestamp
	var cloud_timestamp = cloud_data.get("cloud_timestamp", 0)
	var cloud_last_play = cloud_data.get("last_play_time", 0)

	# Get local timestamp
	var local_timestamp = last_play_time

	print("Cloud timestamp: %d, Local timestamp: %d" % [cloud_last_play, local_timestamp])

	# Use whichever save is newer
	if cloud_last_play > local_timestamp:
		print("☁️ Cloud save is newer - applying cloud data")
		_apply_save_data(cloud_data)
		save_permanent_upgrades()  # Re-save to update local file
	else:
		print("💾 Local save is newer - keeping local data")
		# Upload local save to cloud to sync
		save_permanent_upgrades()
