extends Node

# Boss Rush Mode Manager
# - Every wave spawns only bosses (Override)
# - Every 10 waves, add another boss (max 10 bosses at wave 100)
# - Faster enemy scaling than normal tiers
# - Leaderboard based on damage dealt, not waves survived
# - Available Mon/Thu/Sat for 24 hours (UTC 00:00 to 00:00)
# - Rewards fragments based on rank

# Signals
signal boss_rush_started()
signal boss_rush_ended(damage_dealt: int, waves_survived: int)
signal leaderboard_updated()

# Boss Rush State
var is_active: bool = false
var current_run_damage: int = 0
var current_run_wave: int = 0

# Boss Rush Configuration
const BOSS_HP_SCALING_BASE := 1.13  # 13% per wave (vs 2% normal)
const BOSS_ENEMY_MULTIPLIER := 5.0  # Base stats 5x higher than normal

# Tournament Schedule (UTC 00:00-00:00 on these days)
const TOURNAMENT_DAYS := [1, 4, 6]  # Monday=1, Thursday=4, Saturday=6

# Fragment Rewards by Rank
const FRAGMENT_REWARDS := {
	1: 5000,   # 1st place
	2: 3000,   # 2nd place
	3: 2000,   # 3rd place
	4: 1000,   # 4th-5th
	5: 1000,
	6: 500,    # 6th-10th
	7: 500,
	8: 500,
	9: 500,
	10: 500,
}
const PARTICIPATION_REWARD := 100  # For runs not in top 10

# Leaderboard (top 10 runs sorted by damage)
# Each entry: {"damage": int, "waves": int, "tier": int, "timestamp": int}
var leaderboard: Array = []
const MAX_LEADERBOARD_ENTRIES := 10

func _ready() -> void:
	load_leaderboard()

# === TOURNAMENT AVAILABILITY ===

func is_tournament_available() -> bool:
	# Check if current day is a tournament day (Mon/Thu/Sat)
	var datetime = Time.get_datetime_dict_from_system(true)  # true = UTC
	var weekday = datetime["weekday"]  # 0=Sunday, 1=Monday, ..., 6=Saturday
	return weekday in TOURNAMENT_DAYS

func get_next_tournament_time() -> Dictionary:
	# Returns {day_name: String, hours_until: int}
	var datetime = Time.get_datetime_dict_from_system(true)  # UTC
	var current_weekday = datetime["weekday"]

	# Find next tournament day
	var days_until = 7  # Default to a week away
	for day in TOURNAMENT_DAYS:
		var diff = day - current_weekday
		if diff <= 0:
			diff += 7  # Next week
		if diff < days_until:
			days_until = diff

	var day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	var next_day_index = (current_weekday + days_until) % 7
	var next_day_name = day_names[next_day_index]

	var hours_until = days_until * 24
	# Subtract hours/minutes already passed today
	hours_until -= datetime["hour"]
	hours_until -= int(datetime["minute"] / 60.0)

	return {
		"day_name": next_day_name,
		"hours_until": hours_until,
	}

# === BOSS RUSH CONTROL ===

func start_boss_rush() -> bool:
	if is_active:
		print("⚠️ Boss Rush already active!")
		return false

	is_active = true
	current_run_damage = 0
	current_run_wave = 0
	print("🏆 Boss Rush started!")
	boss_rush_started.emit()
	return true

func end_boss_rush(final_damage: int, final_wave: int) -> void:
	if not is_active:
		return

	is_active = false
	current_run_damage = final_damage
	current_run_wave = final_wave

	print("🏆 Boss Rush ended! Damage: %d, Waves: %d" % [final_damage, final_wave])

	# Calculate rank and award fragments
	var rank = get_rank_for_damage(final_damage)
	var fragments = get_fragment_reward_for_rank(rank)

	if fragments > 0 and RewardManager:
		RewardManager.add_fragments(fragments)
		print("💎 Awarded %d fragments for rank #%d!" % [fragments, rank])

	# Add to leaderboard
	add_leaderboard_entry(final_damage, final_wave)

	boss_rush_ended.emit(final_damage, final_wave)

func is_boss_rush_active() -> bool:
	return is_active

# === BOSS RUSH MECHANICS ===

func get_boss_count_for_wave(wave: int) -> int:
	# Every 10 waves adds a boss (1-10, max 10 bosses)
	return mini(1 + int(wave / 10.0), 10)

func get_boss_rush_hp_multiplier(wave: int) -> float:
	# Exponential HP scaling: 5% per wave
	return pow(BOSS_HP_SCALING_BASE, wave) * BOSS_ENEMY_MULTIPLIER

func get_boss_rush_damage_multiplier() -> float:
	# Bosses deal 5x base damage
	return BOSS_ENEMY_MULTIPLIER

func get_boss_rush_speed_multiplier() -> float:
	# Bosses move at 3x speed
	return 3.0

# === LEADERBOARD ===

func add_leaderboard_entry(damage: int, waves: int) -> void:
	var entry = {
		"damage": damage,
		"waves": waves,
		"tier": TierManager.get_current_tier() if TierManager else 1,
		"timestamp": int(Time.get_unix_time_from_system()),
	}

	leaderboard.append(entry)

	# Sort by damage (descending)
	leaderboard.sort_custom(func(a, b): return a["damage"] > b["damage"])

	# Keep top 10
	if leaderboard.size() > MAX_LEADERBOARD_ENTRIES:
		leaderboard.resize(MAX_LEADERBOARD_ENTRIES)

	save_leaderboard()
	leaderboard_updated.emit()
	print("📊 Leaderboard updated! New entry: %d damage, %d waves" % [damage, waves])

func get_leaderboard() -> Array:
	return leaderboard.duplicate()

func clear_leaderboard() -> void:
	leaderboard.clear()
	save_leaderboard()
	leaderboard_updated.emit()
	print("🗑️ Leaderboard cleared!")

# === SAVE/LOAD ===

func save_leaderboard() -> void:
	var save_data = {
		"leaderboard": leaderboard,
		"version": 1,
	}

	var save_path = "user://boss_rush_leaderboard.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("💾 Boss rush leaderboard saved")
	else:
		print("⚠️ Failed to save boss rush leaderboard")

func load_leaderboard() -> void:
	var save_path = "user://boss_rush_leaderboard.save"
	if not FileAccess.file_exists(save_path):
		print("📊 No boss rush leaderboard found, starting fresh")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		if save_data and save_data is Dictionary:
			leaderboard = save_data.get("leaderboard", [])
			print("📊 Boss rush leaderboard loaded: %d entries" % leaderboard.size())
		else:
			print("⚠️ Invalid boss rush leaderboard data")
	else:
		print("⚠️ Failed to load boss rush leaderboard")

# === UTILITY ===

func format_damage(damage: int) -> String:
	if damage < 1000:
		return str(damage)
	elif damage < 1000000:
		return "%.1fK" % (damage / 1000.0)
	elif damage < 1000000000:
		return "%.1fM" % (damage / 1000000.0)
	else:
		return "%.1fB" % (damage / 1000000000.0)

func get_rank_for_damage(damage: int) -> int:
	# Returns what rank this damage would place (1 = best)
	var rank = 1
	for entry in leaderboard:
		if entry["damage"] > damage:
			rank += 1
	return rank

func get_fragment_reward_for_rank(rank: int) -> int:
	# Returns fragment reward for a given rank
	if rank in FRAGMENT_REWARDS:
		return FRAGMENT_REWARDS[rank]
	elif rank <= MAX_LEADERBOARD_ENTRIES:
		# Shouldn't happen, but safety fallback
		return PARTICIPATION_REWARD
	else:
		# Not in top 10, but still participated
		return PARTICIPATION_REWARD
