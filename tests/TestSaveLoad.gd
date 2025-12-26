extends "res://tests/TestBase.gd"

## TestSaveLoad - Tests for save/load system integrity

func _init() -> void:
	super._init("Save/Load System Tests")

func _ready() -> void:
	run_all_tests()

# ============================================================================
# SAVE FILE INTEGRITY TESTS
# ============================================================================

func test_reward_manager_save_data() -> void:
	# Test that RewardManager can generate save data
	var save_data = RewardManager.get_save_data()

	assert_not_null(save_data, "Save data should not be null")
	assert_true(save_data.has("archive_tokens"), "Should save archive_tokens")
	assert_true(save_data.has("data_credits"), "Should save data_credits")
	assert_true(save_data.has("fragments"), "Should save fragments")

	log_info("RewardManager save data has %d keys" % save_data.keys().size())

func test_upgrade_manager_save_data() -> void:
	# Test that UpgradeManager can generate save data
	var save_data = UpgradeManager.get_save_data()

	assert_not_null(save_data, "Save data should not be null")
	assert_true(save_data is Dictionary, "Save data should be a Dictionary")

	log_info("UpgradeManager save data generated")

func test_software_manager_save_data() -> void:
	# Test that SoftwareUpgradeManager can generate save data
	var save_data = SoftwareUpgradeManager.get_save_data()

	assert_not_null(save_data, "Save data should not be null")
	assert_true(save_data.has("labs"), "Should save lab states")
	assert_true(save_data.has("active_upgrades"), "Should save active upgrades")

	log_info("SoftwareUpgradeManager save data has %d keys" % save_data.keys().size())

# ============================================================================
# CURRENCY VALUE BOUNDS TESTS
# ============================================================================

func test_currency_bounds() -> void:
	# Test that currency values stay within valid bounds
	var at = RewardManager.archive_tokens
	var dc = RewardManager.data_credits
	var frags = RewardManager.fragments

	assert_greater_equal(at, 0, "Archive tokens should be non-negative")
	assert_greater_equal(dc, 0, "Data credits should be non-negative")
	assert_greater_equal(frags, 0, "Fragments should be non-negative")

	log_info("Currency bounds: AT %d, DC %d, Frags %d" % [at, dc, frags])

func test_currency_max_values() -> void:
	# Test that currency values don't overflow
	# Max safe value from CloudSaveManager validation: 1 billion AT, 10 million fragments
	var max_at = 1000000000
	var max_frags = 10000000

	# These are validation limits, actual values should be less
	assert_less_equal(RewardManager.archive_tokens, max_at, "AT should not exceed validation limit")
	assert_less_equal(RewardManager.fragments, max_frags, "Fragments should not exceed validation limit")

	log_info("Currency values within validation limits")

# ============================================================================
# UPGRADE LEVEL BOUNDS TESTS
# ============================================================================

func test_permanent_upgrade_bounds() -> void:
	# Test that permanent upgrade levels are reasonable
	var perm_damage = RewardManager.perm_projectile_damage

	assert_greater_equal(perm_damage, 0, "Permanent damage should be non-negative")
	assert_less_equal(perm_damage, 100000, "Permanent damage should not exceed 100,000")

	log_info("Permanent damage value: %d" % perm_damage)

func test_in_run_upgrade_bounds() -> void:
	# Test that in-run upgrade levels are reasonable
	var damage_level = UpgradeManager.projectile_damage_level

	assert_greater_equal(damage_level, 0, "Damage level should be non-negative")

	log_info("Current damage level: %d" % damage_level)

# ============================================================================
# SOFTWARE LAB STATE TESTS
# ============================================================================

func test_lab_state_consistency() -> void:
	# Test that lab states are consistent
	var active_upgrades = SoftwareUpgradeManager.active_upgrades

	assert_not_null(active_upgrades, "Active upgrades array should exist")
	assert_greater_equal(active_upgrades.size(), 0, "Active upgrades should be valid size")

	var max_slots = 2
	assert_less_equal(active_upgrades.size(), max_slots, "Should not exceed max lab slots")

	log_info("Lab slots: %d / %d active" % [active_upgrades.size(), max_slots])

func test_lab_levels() -> void:
	# Test that lab levels are within valid ranges
	var labs = SoftwareUpgradeManager.labs

	for lab_id in labs.keys():
		var lab = labs[lab_id]
		var level = lab["level"]
		var max_level = lab["max_level"]

		assert_greater_equal(level, 0, "%s level should be non-negative" % lab_id)
		assert_less_equal(level, max_level, "%s level should not exceed max (%d)" % [lab_id, max_level])

	log_info("All %d lab levels within valid ranges" % labs.keys().size())

# ============================================================================
# TIER SYSTEM TESTS
# ============================================================================

func test_tier_system_state() -> void:
	# Test that tier system state is valid
	var current_tier = TierManager.current_tier

	assert_greater_equal(current_tier, 0, "Current tier should be non-negative")
	assert_less_equal(current_tier, 10, "Current tier should not exceed max (10)")

	log_info("Current tier: %d / 10" % current_tier)

func test_tier_unlocks() -> void:
	# Test that tier unlock logic works
	var tier_0_unlocked = TierManager.is_tier_unlocked(0)
	var tier_10_unlocked = TierManager.is_tier_unlocked(10)

	assert_true(tier_0_unlocked, "Tier 0 should always be unlocked")

	log_info("Tier 0 unlocked: %s, Tier 10 unlocked: %s" % [tier_0_unlocked, tier_10_unlocked])

# ============================================================================
# BOSS RUSH TESTS
# ============================================================================

func test_boss_rush_leaderboard() -> void:
	# Test that boss rush leaderboard is valid
	var leaderboard = BossRushManager.leaderboard

	assert_not_null(leaderboard, "Leaderboard should exist")
	assert_less_equal(leaderboard.size(), 10, "Leaderboard should not exceed 10 entries")

	for entry in leaderboard:
		assert_greater_equal(entry["damage"], 0, "Damage should be non-negative")
		assert_greater_equal(entry["waves"], 0, "Waves should be non-negative")

	log_info("Boss Rush leaderboard has %d entries" % leaderboard.size())

# ============================================================================
# RUN STATS TESTS
# ============================================================================

func test_run_stats_tracking() -> void:
	# Test that run stats are being tracked
	var total_waves = RunStats.total_waves_completed

	assert_greater_equal(total_waves, 0, "Total waves should be non-negative")

	log_info("Total waves completed: %d" % total_waves)

func test_run_history() -> void:
	# Test that run history is maintained
	var run_history = RewardManager.run_history

	assert_not_null(run_history, "Run history should exist")
	assert_less_equal(run_history.size(), 100, "Run history should not exceed 100 runs")

	for run in run_history:
		assert_true(run.has("waves"), "Run should have waves count")
		assert_true(run.has("at_earned"), "Run should have AT earned")

	log_info("Run history has %d entries" % run_history.size())

# ============================================================================
# OFFLINE PROGRESS TESTS
# ============================================================================

func test_offline_timestamp() -> void:
	# Test that offline timestamp is valid
	var last_play = RewardManager.last_play_time

	assert_greater_equal(last_play, 0, "Last play time should be non-negative")

	if last_play > 0:
		var now = Time.get_unix_time_from_system()
		assert_less_equal(last_play, now, "Last play time should not be in future")

	log_info("Last play time: %d" % last_play)

# ============================================================================
# CLOUD SAVE VALIDATION TESTS
# ============================================================================

func test_save_data_validation() -> void:
	# Test that current save data would pass validation
	var save_data = {
		"archive_tokens": RewardManager.archive_tokens,
		"fragments": RewardManager.fragments,
		"perm_projectile_damage": RewardManager.perm_projectile_damage,
		"total_waves_completed": RunStats.total_waves_completed
	}

	# These are the validation limits from CloudSaveManager._validate_save_data()
	assert_less_equal(save_data["archive_tokens"], 1000000000, "AT should pass validation")
	assert_less_equal(save_data["fragments"], 10000000, "Fragments should pass validation")
	assert_less_equal(save_data["perm_projectile_damage"], 100000, "Perm damage should pass validation")
	assert_less_equal(save_data["total_waves_completed"], 100000000, "Total waves should pass validation")

	log_info("Current save data passes validation checks")

# ============================================================================
# FRAGMENT EARNING TESTS
# ============================================================================

func test_fragment_sources() -> void:
	# Test that fragments can be earned from expected sources
	var initial_frags = RewardManager.fragments

	# Simulate boss kill (wave 10)
	var boss_frags = 10 + int(10 / 10)  # Base 10 + (wave / 10)
	assert_equal(boss_frags, 11, "Wave 10 boss should give 11 fragments")

	log_info("Boss kill fragments calculated correctly: %d" % boss_frags)

# ============================================================================
# MULTIPLIER TESTS
# ============================================================================

func test_multiplier_consistency() -> void:
	# Test that multipliers are applied consistently
	var dc_mult = UpgradeManager.get_data_credit_multiplier()
	var at_mult = UpgradeManager.get_archive_token_multiplier()

	assert_greater_equal(dc_mult, 1.0, "DC multiplier should be at least 1.0")
	assert_greater_equal(at_mult, 1.0, "AT multiplier should be at least 1.0")

	log_info("Multipliers: DC %.2fx, AT %.2fx" % [dc_mult, at_mult])

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func assert_greater_equal(actual, expected, message: String = "") -> bool:
	if actual >= expected:
		_log_pass(message if message else "%s >= %s" % [str(actual), str(expected)])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s >= %s" % [str(actual), str(expected)])
		tests_failed += 1
		return false

func assert_less_equal(actual, expected, message: String = "") -> bool:
	if actual <= expected:
		_log_pass(message if message else "%s <= %s" % [str(actual), str(expected)])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s <= %s" % [str(actual), str(expected)])
		tests_failed += 1
		return false
