extends Node

# Lifetime Achievement System
# Tracks long-term player progress and awards Quantum Cores
# Designed for multi-year progression (2-3 years for final tiers)

# --- SIGNALS ---
signal achievement_unlocked(achievement_id: String, tier: int, qc_reward: int)

# --- ACHIEVEMENT DEFINITIONS ---
# Format: { "id": { "name": "...", "description": "...", "icon": "...", "tiers": [...] } }
# Each tier: { "threshold": value, "qc_reward": amount }
# Thresholds designed for 4x speed + 30s waves = 11,520 waves/day = 4.2M waves/year

const ACHIEVEMENTS := {
	# --- WAVE PROGRESSION ---
	"waves_completed": {
		"name": "Wave Warrior",
		"description": "Complete waves across all tiers",
		"icon": "🌊",
		"stat": "total_waves_completed",
		"tiers": [
			{"threshold": 10, "qc_reward": 50},
			{"threshold": 100, "qc_reward": 100},
			{"threshold": 1000, "qc_reward": 200},
			{"threshold": 10000, "qc_reward": 500},          # ~1 day
			{"threshold": 100000, "qc_reward": 1000},        # ~9 days
			{"threshold": 500000, "qc_reward": 2500},        # ~43 days
			{"threshold": 1000000, "qc_reward": 5000},       # ~87 days (~3 months)
			{"threshold": 5000000, "qc_reward": 15000},      # ~1.2 years
			{"threshold": 10000000, "qc_reward": 30000},     # ~2.4 years
			{"threshold": 25000000, "qc_reward": 100000}     # ~6 years (ultimate)
		]
	},

	# --- BOSS SLAYER ---
	"bosses_killed": {
		"name": "Boss Slayer",
		"description": "Defeat bosses across all tiers",
		"icon": "👑",
		"stat": "total_bosses_killed",
		"tiers": [
			{"threshold": 10, "qc_reward": 50},
			{"threshold": 100, "qc_reward": 100},
			{"threshold": 1000, "qc_reward": 250},
			{"threshold": 10000, "qc_reward": 750},          # ~1 day
			{"threshold": 50000, "qc_reward": 2000},         # ~43 days
			{"threshold": 100000, "qc_reward": 5000},        # ~87 days
			{"threshold": 500000, "qc_reward": 15000},       # ~1.2 years
			{"threshold": 1000000, "qc_reward": 35000},      # ~2.4 years
			{"threshold": 2500000, "qc_reward": 100000}      # ~6 years
		]
	},

	# --- TOTAL KILLS ---
	"total_kills": {
		"name": "Exterminator",
		"description": "Eliminate enemies across all waves",
		"icon": "💀",
		"stat": "total_enemies_killed",
		"tiers": [
			{"threshold": 100, "qc_reward": 50},
			{"threshold": 1000, "qc_reward": 100},
			{"threshold": 10000, "qc_reward": 200},
			{"threshold": 100000, "qc_reward": 500},
			{"threshold": 1000000, "qc_reward": 1500},       # ~1 week (assuming 20 kills/wave)
			{"threshold": 10000000, "qc_reward": 5000},      # ~2.5 months
			{"threshold": 100000000, "qc_reward": 15000},    # ~2 years
			{"threshold": 500000000, "qc_reward": 40000},    # ~10 years
			{"threshold": 1000000000, "qc_reward": 100000}   # ~20 years (ultimate)
		]
	},

	# --- CURRENCY EARNED ---
	"data_credits_earned": {
		"name": "Data Tycoon",
		"description": "Earn Data Credits across all runs",
		"icon": "💾",
		"stat": "total_dc_earned",
		"tiers": [
			{"threshold": 1000, "qc_reward": 50},
			{"threshold": 10000, "qc_reward": 100},
			{"threshold": 100000, "qc_reward": 200},
			{"threshold": 1000000, "qc_reward": 500},
			{"threshold": 10000000, "qc_reward": 1500},
			{"threshold": 100000000, "qc_reward": 5000},
			{"threshold": 1000000000, "qc_reward": 15000},   # 1 billion
			{"threshold": 10000000000, "qc_reward": 40000},  # 10 billion
			{"threshold": 100000000000, "qc_reward": 100000} # 100 billion
		]
	},

	"archive_tokens_earned": {
		"name": "Archive Master",
		"description": "Earn Archive Tokens across all runs",
		"icon": "📦",
		"stat": "total_at_earned",
		"tiers": [
			{"threshold": 100, "qc_reward": 50},
			{"threshold": 1000, "qc_reward": 100},
			{"threshold": 10000, "qc_reward": 200},
			{"threshold": 100000, "qc_reward": 500},
			{"threshold": 1000000, "qc_reward": 1500},
			{"threshold": 10000000, "qc_reward": 5000},
			{"threshold": 100000000, "qc_reward": 15000},
			{"threshold": 1000000000, "qc_reward": 40000},
			{"threshold": 10000000000, "qc_reward": 100000}
		]
	},

	"fragments_earned": {
		"name": "Fragment Collector",
		"description": "Collect Fragments across all runs",
		"icon": "💎",
		"stat": "total_fragments_earned",
		"tiers": [
			{"threshold": 1000, "qc_reward": 50},
			{"threshold": 10000, "qc_reward": 100},
			{"threshold": 100000, "qc_reward": 200},
			{"threshold": 1000000, "qc_reward": 500},
			{"threshold": 10000000, "qc_reward": 1500},
			{"threshold": 100000000, "qc_reward": 5000},
			{"threshold": 1000000000, "qc_reward": 15000},
			{"threshold": 10000000000, "qc_reward": 40000},
			{"threshold": 100000000000, "qc_reward": 100000}
		]
	},

	# --- QUANTUM CORES SPENT ---
	"quantum_cores_spent": {
		"name": "Quantum Investor",
		"description": "Spend Quantum Cores on upgrades",
		"icon": "🔮",
		"stat": "total_qc_spent",
		"tiers": [
			{"threshold": 100, "qc_reward": 50},
			{"threshold": 1000, "qc_reward": 100},
			{"threshold": 10000, "qc_reward": 300},
			{"threshold": 50000, "qc_reward": 1000},
			{"threshold": 100000, "qc_reward": 2500},
			{"threshold": 500000, "qc_reward": 7500},
			{"threshold": 1000000, "qc_reward": 20000},
			{"threshold": 5000000, "qc_reward": 60000},
			{"threshold": 10000000, "qc_reward": 150000}
		]
	},

	# --- LAB RESEARCH TIME ---
	"lab_time": {
		"name": "Research Scientist",
		"description": "Accumulate total lab research time",
		"icon": "🔬",
		"stat": "total_lab_time_seconds",
		"tiers": [
			{"threshold": 3600, "qc_reward": 50},             # 1 hour
			{"threshold": 86400, "qc_reward": 150},           # 1 day
			{"threshold": 604800, "qc_reward": 500},          # 1 week
			{"threshold": 2592000, "qc_reward": 1500},        # 30 days
			{"threshold": 7776000, "qc_reward": 4000},        # 90 days
			{"threshold": 15552000, "qc_reward": 10000},      # 180 days
			{"threshold": 31536000, "qc_reward": 25000},      # 1 year
			{"threshold": 63072000, "qc_reward": 60000},      # 2 years
			{"threshold": 94608000, "qc_reward": 150000}      # 3 years
		]
	},

	# --- DATA DISKS COLLECTED ---
	"data_disks_owned": {
		"name": "Disk Hoarder",
		"description": "Collect unique data disks",
		"icon": "📀",
		"stat": "unique_data_disks_owned",
		"tiers": [
			{"threshold": 1, "qc_reward": 50},
			{"threshold": 5, "qc_reward": 100},
			{"threshold": 10, "qc_reward": 200},
			{"threshold": 20, "qc_reward": 500},
			{"threshold": 30, "qc_reward": 1000},             # Tier 1 complete
			{"threshold": 60, "qc_reward": 2500},             # Tier 2 complete
			{"threshold": 90, "qc_reward": 5000},             # Tier 3 complete
			{"threshold": 150, "qc_reward": 10000},           # Tier 5 complete
			{"threshold": 210, "qc_reward": 20000},           # Tier 7 complete
			{"threshold": 300, "qc_reward": 50000}            # All tiers complete
		]
	},

	# --- TOURNAMENT PARTICIPATION ---
	"tournament_participation": {
		"name": "Tournament Veteran",
		"description": "Participate in Boss Rush tournaments",
		"icon": "🏆",
		"stat": "total_tournaments_entered",
		"tiers": [
			{"threshold": 1, "qc_reward": 100},
			{"threshold": 5, "qc_reward": 200},
			{"threshold": 10, "qc_reward": 400},
			{"threshold": 25, "qc_reward": 1000},
			{"threshold": 50, "qc_reward": 2500},
			{"threshold": 100, "qc_reward": 6000},
			{"threshold": 250, "qc_reward": 15000},
			{"threshold": 500, "qc_reward": 35000},
			{"threshold": 1000, "qc_reward": 80000},
			{"threshold": 2500, "qc_reward": 200000}
		]
	}
}

# --- TRACKED STATS ---
var stats: Dictionary = {
	"total_waves_completed": 0,
	"total_bosses_killed": 0,
	"total_enemies_killed": 0,
	"total_dc_earned": 0,
	"total_at_earned": 0,
	"total_fragments_earned": 0,
	"total_qc_spent": 0,
	"total_lab_time_seconds": 0,
	"unique_data_disks_owned": 0,
	"total_tournaments_entered": 0
}

# --- ACHIEVEMENT PROGRESS ---
# Format: { "achievement_id": current_tier_unlocked }
var unlocked_tiers: Dictionary = {}

# --- INITIALIZATION ---
func _ready() -> void:
	load_achievements()
	_connect_stat_tracking()

# --- STAT TRACKING CONNECTIONS ---
func _connect_stat_tracking() -> void:
	# Achievement stat tracking is integrated into existing managers:
	# - Waves: TierManager.update_highest_wave()
	# - Kills/Bosses: RunStats.record_kill()
	# - DC/AT/Fragments: RewardManager.add_data_credits/add_archive_tokens/add_fragments()
	# - Data Disks: DataDiskManager.add_data_disk()
	# - QC Spent: Add to wherever quantum_cores is spent (not yet implemented)
	# - Lab Time: Add to SoftwareUpgradeManager when lab research completes
	# - Tournaments: Add to BossRushManager.start_tournament() or similar
	pass

# --- STAT UPDATE FUNCTIONS ---
func add_wave_completed() -> void:
	stats["total_waves_completed"] += 1
	_check_achievement("waves_completed")

func add_boss_killed() -> void:
	stats["total_bosses_killed"] += 1
	_check_achievement("bosses_killed")

func add_enemies_killed(count: int) -> void:
	stats["total_enemies_killed"] += count
	_check_achievement("total_kills")

func add_dc_earned(amount: int) -> void:
	stats["total_dc_earned"] += amount
	_check_achievement("data_credits_earned")

func add_at_earned(amount: int) -> void:
	stats["total_at_earned"] += amount
	_check_achievement("archive_tokens_earned")

func add_fragments_earned(amount: int) -> void:
	stats["total_fragments_earned"] += amount
	_check_achievement("fragments_earned")

func add_qc_spent(amount: int) -> void:
	stats["total_qc_spent"] += amount
	_check_achievement("quantum_cores_spent")

func add_lab_time(seconds: float) -> void:
	stats["total_lab_time_seconds"] += int(seconds)
	_check_achievement("lab_time")

func update_data_disks_owned(count: int) -> void:
	stats["unique_data_disks_owned"] = count
	_check_achievement("data_disks_owned")

func add_tournament_entered() -> void:
	stats["total_tournaments_entered"] += 1
	_check_achievement("tournament_participation")

# --- ACHIEVEMENT CHECKING ---
func _check_achievement(achievement_id: String) -> void:
	if not ACHIEVEMENTS.has(achievement_id):
		return

	var achievement = ACHIEVEMENTS[achievement_id]
	var stat_name = achievement["stat"]
	var current_value = stats.get(stat_name, 0)
	var current_tier = unlocked_tiers.get(achievement_id, -1)

	# Check all tiers higher than current
	var tiers = achievement["tiers"]
	for i in range(current_tier + 1, tiers.size()):
		var tier_data = tiers[i]
		if current_value >= tier_data["threshold"]:
			# Unlock this tier!
			unlocked_tiers[achievement_id] = i
			var qc_reward = tier_data["qc_reward"]

			# Award Quantum Cores
			RewardManager.add_quantum_cores(qc_reward)

			save_achievements()
			emit_signal("achievement_unlocked", achievement_id, i, qc_reward)

			print("🏆 Achievement Unlocked: %s (Tier %d) - %d QC!" % [achievement["name"], i + 1, qc_reward])
		else:
			break  # Stop checking once we hit an unmet threshold

# --- QUERY FUNCTIONS ---
func get_achievement_progress(achievement_id: String) -> Dictionary:
	if not ACHIEVEMENTS.has(achievement_id):
		return {}

	var achievement = ACHIEVEMENTS[achievement_id]
	var stat_name = achievement["stat"]
	var current_value = stats.get(stat_name, 0)
	var current_tier = unlocked_tiers.get(achievement_id, -1)
	var tiers = achievement["tiers"]

	var next_tier_index = current_tier + 1
	var next_tier_data = null
	if next_tier_index < tiers.size():
		next_tier_data = tiers[next_tier_index]

	return {
		"name": achievement["name"],
		"description": achievement["description"],
		"icon": achievement["icon"],
		"current_value": current_value,
		"current_tier": current_tier,
		"total_tiers": tiers.size(),
		"next_threshold": next_tier_data["threshold"] if next_tier_data else 0,
		"next_reward": next_tier_data["qc_reward"] if next_tier_data else 0,
		"completed": current_tier >= tiers.size() - 1
	}

func get_all_achievements() -> Array:
	var result = []
	for achievement_id in ACHIEVEMENTS.keys():
		var progress = get_achievement_progress(achievement_id)
		progress["id"] = achievement_id
		result.append(progress)
	return result

func get_total_qc_earned_from_achievements() -> int:
	var total = 0
	for achievement_id in ACHIEVEMENTS.keys():
		var current_tier = unlocked_tiers.get(achievement_id, -1)
		if current_tier >= 0:
			var tiers = ACHIEVEMENTS[achievement_id]["tiers"]
			for i in range(current_tier + 1):
				total += tiers[i]["qc_reward"]
	return total

# --- SAVE/LOAD ---
func save_achievements() -> void:
	var save_data = {
		"stats": stats,
		"unlocked_tiers": unlocked_tiers
	}

	var save_path = "user://achievements.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("💾 Achievements saved")
	else:
		push_error("❌ Failed to save achievements")

func load_achievements() -> void:
	var save_path = "user://achievements.save"
	if not FileAccess.file_exists(save_path):
		print("📂 No achievement save file found, starting fresh")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		stats = save_data.get("stats", stats)
		unlocked_tiers = save_data.get("unlocked_tiers", {})

		print("✅ Achievements loaded (%d stats tracked, %d achievements unlocked)" % [stats.size(), unlocked_tiers.size()])
	else:
		push_error("❌ Failed to load achievements")

# --- DEBUG/TESTING ---
func grant_test_progress() -> void:
	# Fast-forward stats for testing
	add_wave_completed()
	add_wave_completed()
	add_wave_completed()
	add_boss_killed()
	add_enemies_killed(100)
	add_dc_earned(10000)
	add_at_earned(1000)
	add_fragments_earned(5000)
	print("🧪 Test progress granted")
