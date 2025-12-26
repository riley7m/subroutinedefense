extends Node

# --- Currency ---
var data_credits: int = 100000
var archive_tokens: int = 100000
var fragments: int = 0  # Premium currency: earned from boss kills, used for drone purchases/upgrades

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
var perm_projectile_damage: int = 0
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

# --- Multipliers (can be modified via upgrades) ---
@export var dc_multiplier: float = 1.0
@export var at_multiplier: float = 1.0

signal archive_tokens_changed
signal offline_progress_calculated(waves: int, dc: int, at: int, duration: float)

var UpgradeManager = null

func _ready() -> void:
	# Safely get UpgradeManager
	UpgradeManager = get_node_or_null("UpgradeManager")
	if not UpgradeManager:
		push_error("UpgradeManager not found as child of RewardManager")

	# Connect to tree exit signal only if not already connected
	if not get_tree().tree_exiting.is_connected(Callable(self, "save_permanent_upgrades")):
		get_tree().connect("tree_exiting", Callable(self, "save_permanent_upgrades"))


# === Reward Functions ===
func add_archive_tokens(amount: int) -> void:
	archive_tokens += amount
	emit_signal("archive_tokens_changed")

func add_fragments(amount: int) -> void:
	fragments += amount

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

func reward_enemy_at(enemy_type: String, wave_number: int) -> void:
	var base_at = get_at_reward_for_enemy(enemy_type)
	var scaled_at = int(base_at * (1.0 + wave_number * 0.02) * get_archive_token_multiplier())

	# Apply lucky drops bonus
	var lucky_chance = UpgradeManager.get_lucky_drops()
	if lucky_chance > 0 and randf() * 100.0 < lucky_chance:
		scaled_at = int(scaled_at * 1.5)  # 50% bonus on lucky drop
		#print("🍀 Lucky drop! Bonus AT!")

	archive_tokens += scaled_at
	RunStats.archive_tokens_earned += scaled_at
	emit_signal("archive_tokens_changed")
	#print("📦 AT from", enemy_type, "→", scaled_at, "→ Total:", archive_tokens)

func reward_enemy(enemy_type: String, wave_number: int) -> void:
	var base_dc = get_dc_reward_for_enemy(enemy_type)
	var scaled_dc = int(base_dc * (1.0 + wave_number * 0.02) * get_data_credit_multiplier())

	# Apply lucky drops bonus
	var lucky_chance = UpgradeManager.get_lucky_drops()
	if lucky_chance > 0 and randf() * 100.0 < lucky_chance:
		scaled_dc = int(scaled_dc * 1.5)  # 50% bonus on lucky drop
		#print("🍀 Lucky drop! Bonus DC!")

	data_credits += scaled_dc
	RunStats.data_credits_earned += scaled_dc
	#print("🪙 DC from", enemy_type, "→", scaled_dc, "→ Total:", data_credits)

func get_wave_at_reward(wave_number: int) -> int:
	# Apply multiplier BEFORE floor to maintain canonical formula precision
	return int(floor(0.25 * pow(wave_number, 1.15) * at_multiplier))

func add_wave_at(wave_number: int) -> void:
	var reward = get_wave_at_reward(wave_number)
	archive_tokens += reward
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
	# Exponential cost: 3x multiplier per tier (5k, 15k, 45k, 135k)
	var base_costs = {
		"flame": 5000,      # First drone (500 boss kills)
		"frost": 15000,     # Second drone (1500 boss kills)
		"poison": 45000,    # Third drone (4500 boss kills)
		"shock": 135000     # Fourth drone (13500 boss kills)
	}
	return base_costs.get(drone_type, 5000)

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
func calculate_offline_progress(watched_ad: bool = false) -> void:
	if last_play_time == 0:
		last_play_time = Time.get_unix_time_from_system()
		return  # First time playing

	var now = Time.get_unix_time_from_system()
	var seconds_away = now - last_play_time

	# Update timestamp for next session
	last_play_time = now

	# Cap at 24 hours (86400 seconds)
	seconds_away = min(seconds_away, 86400)

	# Ignore absences less than 1 minute
	if seconds_away < 60:
		return

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
func save_permanent_upgrades():
	# Update last play time on save
	last_play_time = Time.get_unix_time_from_system()

	var data = {
		"perm_projectile_damage": perm_projectile_damage,
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
		"archive_tokens": archive_tokens,
		"fragments": fragments,
		"owned_drones": owned_drones,
		"last_play_time": last_play_time,
		"run_history": run_history,
	}
	var file = FileAccess.open("user://perm_upgrades.save", FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return
	file.store_var(data)
	file.close()
	print("💾 Permanent upgrades saved.")

func load_permanent_upgrades():
	if not FileAccess.file_exists("user://perm_upgrades.save"):
		print("No permanent upgrades save found.")
		return

	var file = FileAccess.open("user://perm_upgrades.save", FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: " + str(FileAccess.get_open_error()))
		return

	var data = file.get_var()
	file.close()

	# Validate data is a dictionary
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file corrupted: Invalid data type")
		return

	# Load with validation (clamp to reasonable ranges)
	perm_projectile_damage = clamp(data.get("perm_projectile_damage", 0), 0, 100000)
	perm_projectile_fire_rate = clamp(data.get("perm_projectile_fire_rate", 0.0), 0.0, 1000.0)
	perm_crit_chance = clamp(data.get("perm_crit_chance", 0), 0, 100000)
	perm_crit_damage = clamp(data.get("perm_crit_damage", 0.0), 0.0, 1000.0)
	perm_piercing = clamp(data.get("perm_piercing", 0), 0, 100000)
	perm_overkill_damage = clamp(data.get("perm_overkill_damage", 0.0), 0.0, 1000.0)
	perm_projectile_speed = clamp(data.get("perm_projectile_speed", 0.0), 0.0, 1000.0)
	perm_shield_integrity = clamp(data.get("perm_shield_integrity", 0), 0, 100000)
	perm_damage_reduction = clamp(data.get("perm_damage_reduction", 0.0), 0.0, 1000.0)
	perm_shield_regen = clamp(data.get("perm_shield_regen", 0.0), 0.0, 1000.0)
	perm_block_chance = clamp(data.get("perm_block_chance", 0.0), 0.0, 100.0)
	perm_block_amount = clamp(data.get("perm_block_amount", 0), 0, 100000)
	perm_boss_resistance = clamp(data.get("perm_boss_resistance", 0.0), 0.0, 100.0)
	perm_data_credit_multiplier = clamp(data.get("perm_data_credit_multiplier", 0.0), 0.0, 1000.0)
	perm_archive_token_multiplier = clamp(data.get("perm_archive_token_multiplier", 0.0), 0.0, 1000.0)
	perm_wave_skip_chance = clamp(data.get("perm_wave_skip_chance", 0.0), 0.0, 100.0)
	perm_free_upgrade_chance = clamp(data.get("perm_free_upgrade_chance", 0.0), 0.0, 100.0)
	perm_overshield = clamp(data.get("perm_overshield", 0), 0, 100000)
	perm_boss_bonus = clamp(data.get("perm_boss_bonus", 0.0), 0.0, 1000.0)
	perm_lucky_drops = clamp(data.get("perm_lucky_drops", 0.0), 0.0, 100.0)
	perm_ricochet_chance = clamp(data.get("perm_ricochet_chance", 0.0), 0.0, 100.0)
	perm_ricochet_max_targets = clamp(data.get("perm_ricochet_max_targets", 0), 0, 100)
	perm_multi_target_unlocked = data.get("perm_multi_target_unlocked", false)
	perm_drone_flame_level = clamp(data.get("perm_drone_flame_level", 0), 0, 10000)
	perm_drone_frost_level = clamp(data.get("perm_drone_frost_level", 0), 0, 10000)
	perm_drone_poison_level = clamp(data.get("perm_drone_poison_level", 0), 0, 10000)
	perm_drone_shock_level = clamp(data.get("perm_drone_shock_level", 0), 0, 10000)
	archive_tokens = clamp(data.get("archive_tokens", 0), 0, 999999999)
	fragments = clamp(data.get("fragments", 0), 0, 999999999)
	owned_drones = data.get("owned_drones", {"flame": false, "frost": false, "poison": false, "shock": false})
	last_play_time = data.get("last_play_time", 0)
	run_history = data.get("run_history", [])

	print("🔄 Permanent upgrades loaded.")

	# Clean up old runs on load
	_clean_old_runs()

	# Calculate offline progress (without ad by default - UI will handle ad option)
	calculate_offline_progress(false)
