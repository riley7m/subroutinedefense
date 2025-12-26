extends Node

# Boss Rush Mode Manager
# - Every wave spawns only bosses (Override)
# - Every 10 waves, add another boss (max 10 bosses at wave 100)
# - Faster enemy scaling than normal tiers
# - Leaderboard based on damage dealt, not waves survived

# Signals
signal boss_rush_started()
signal boss_rush_ended(damage_dealt: int, waves_survived: int)
signal leaderboard_updated()

# Boss Rush State
var is_active: bool = false
var current_run_damage: int = 0
var current_run_wave: int = 0

# Boss Rush Configuration
const MAX_WAVE := 100  # Boss rush ends at wave 100
const BOSS_HP_SCALING_BASE := 1.05  # 5% per wave (vs 2% normal)
const BOSS_ENEMY_MULTIPLIER := 5.0  # Base stats 5x higher than normal

# Leaderboard (top 10 runs sorted by damage)
# Each entry: {"damage": int, "waves": int, "tier": int, "timestamp": int}
var leaderboard: Array = []
const MAX_LEADERBOARD_ENTRIES := 10

func _ready() -> void:
	load_leaderboard()

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
