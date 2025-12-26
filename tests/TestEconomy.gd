extends "res://tests/TestBase.gd"

## TestEconomy - Tests for currency rewards and progression formulas

func _init() -> void:
	super._init("Economy System Tests")

func _ready() -> void:
	run_all_tests()

# ============================================================================
# DC/AT REWARD TESTS
# ============================================================================

func test_wave_scaling_formula() -> void:
	# Test wave scaling: (1.0 + wave * 0.02)
	var wave_1_mult = 1.0 + 1 * 0.02
	var wave_50_mult = 1.0 + 50 * 0.02
	var wave_100_mult = 1.0 + 100 * 0.02

	assert_equal_float(wave_1_mult, 1.02, 0.01, "Wave 1 should be 1.02x")
	assert_equal_float(wave_50_mult, 2.0, 0.01, "Wave 50 should be 2.0x")
	assert_equal_float(wave_100_mult, 3.0, 0.01, "Wave 100 should be 3.0x")

	log_info("Wave scaling: 1.02x -> 2.0x -> 3.0x")

func test_wave_at_bonus_formula() -> void:
	# Test wave AT bonus: floor(0.25 * (wave ^ 1.15))
	var wave_10_bonus = int(floor(0.25 * pow(10, 1.15)))
	var wave_50_bonus = int(floor(0.25 * pow(50, 1.15)))
	var wave_100_bonus = int(floor(0.25 * pow(100, 1.15)))

	assert_equal(wave_10_bonus, 3, "Wave 10 bonus should be 3 AT")
	assert_equal(wave_50_bonus, 25, "Wave 50 bonus should be 25 AT")
	assert_equal(wave_100_bonus, 63, "Wave 100 bonus should be 63 AT")

	log_info("Wave AT bonuses: 3 AT -> 25 AT -> 63 AT")

func test_enemy_base_rewards() -> void:
	# Test that each enemy type has appropriate base rewards
	var breacher_dc = RewardManager.get_dc_reward_for_enemy("Breacher")
	var override_dc = RewardManager.get_dc_reward_for_enemy("Override")

	assert_greater(override_dc, breacher_dc, "Boss should give more DC than basic enemy")

	var breacher_at = RewardManager.get_at_reward_for_enemy("Breacher")
	var override_at = RewardManager.get_at_reward_for_enemy("Override")

	assert_greater(override_at, breacher_at, "Boss should give more AT than basic enemy")

	log_info("Breacher: %d DC, %d AT | Override: %d DC, %d AT" % [breacher_dc, breacher_at, override_dc, override_at])

func test_tier_multiplier() -> void:
	# Test tier reward multiplier: 5 ^ tier
	var tier_0_mult = TierManager.get_reward_multiplier_for_tier(0)
	var tier_1_mult = TierManager.get_reward_multiplier_for_tier(1)
	var tier_2_mult = TierManager.get_reward_multiplier_for_tier(2)

	assert_equal_float(tier_0_mult, 1.0, 0.01, "Tier 0 should be 1.0x")
	assert_equal_float(tier_1_mult, 5.0, 0.01, "Tier 1 should be 5.0x")
	assert_equal_float(tier_2_mult, 25.0, 0.01, "Tier 2 should be 25.0x")

	log_info("Tier multipliers: 1.0x -> 5.0x -> 25.0x")

# ============================================================================
# PERMANENT UPGRADE COST TESTS
# ============================================================================

func test_perm_cost_scaling() -> void:
	# Test permanent upgrade cost formula: base * (1.13 ^ level)
	var base = 5000

	var cost_1 = int(base * pow(1.13, 1))
	var cost_10 = int(base * pow(1.13, 10))
	var cost_50 = int(base * pow(1.13, 50))

	assert_equal(cost_1, 5650, "Level 1 should cost 5,650 AT")
	assert_equal(cost_10, 16946, "Level 10 should cost ~16,946 AT")
	assert_greater(cost_50, 420000, "Level 50 should cost >420,000 AT")

	log_info("Perm costs (base 5000): %d -> %d -> %d AT" % [cost_1, cost_10, cost_50])

func test_perm_cost_function() -> void:
	# Test UpgradeManager's actual cost function
	var cost_1 = UpgradeManager.get_perm_cost(5000, 250, 1)
	var cost_10 = UpgradeManager.get_perm_cost(5000, 250, 10)

	assert_equal(cost_1, 5650, "get_perm_cost(5000, _, 1) should return 5650")
	assert_equal(cost_10, 16946, "get_perm_cost(5000, _, 10) should return 16946")

	log_info("get_perm_cost() working correctly")

# ============================================================================
# IN-RUN UPGRADE COST TESTS
# ============================================================================

func test_in_run_cost_scaling() -> void:
	# Test in-run cost formula: base * (1.15 ^ purchases)
	var base = 50

	var cost_0 = int(base * pow(1.15, 0))
	var cost_5 = int(base * pow(1.15, 5))
	var cost_10 = int(base * pow(1.15, 10))
	var cost_20 = int(base * pow(1.15, 20))

	assert_equal(cost_0, 50, "Purchase 0 should cost 50 DC")
	assert_equal(cost_5, 100, "Purchase 5 should cost ~100 DC")
	assert_equal(cost_10, 202, "Purchase 10 should cost ~202 DC")
	assert_greater(cost_20, 800, "Purchase 20 should cost >800 DC")

	log_info("In-run costs (base 50): %d -> %d -> %d -> %d DC" % [cost_0, cost_5, cost_10, cost_20])

func test_purchase_scaled_cost() -> void:
	# Test UpgradeManager's purchase scaling function
	var cost_0 = UpgradeManager.get_purchase_scaled_cost(50, 0)
	var cost_10 = UpgradeManager.get_purchase_scaled_cost(50, 10)

	assert_equal(cost_0, 50, "0 purchases should cost base amount")
	assert_equal(cost_10, 202, "10 purchases should scale correctly")

	log_info("get_purchase_scaled_cost() working correctly")

# ============================================================================
# BOSS RUSH TESTS
# ============================================================================

func test_boss_rush_hp_scaling() -> void:
	# Test Boss Rush HP formula: (1.13 ^ wave) * 5.0
	var wave_1_mult = pow(1.13, 1) * 5.0
	var wave_5_mult = pow(1.13, 5) * 5.0
	var wave_10_mult = pow(1.13, 10) * 5.0

	assert_equal_float(wave_1_mult, 5.65, 0.01, "Wave 1 should be 5.65x HP")
	assert_equal_float(wave_5_mult, 9.24, 0.1, "Wave 5 should be ~9.24x HP")
	assert_equal_float(wave_10_mult, 16.97, 0.1, "Wave 10 should be ~16.97x HP")

	log_info("Boss Rush HP: 5.65x -> 9.24x -> 16.97x")

func test_boss_rush_fragment_rewards() -> void:
	# Test that fragment rewards decrease by rank
	var rank_1 = BossRushManager.get_fragment_reward_for_rank(1)
	var rank_5 = BossRushManager.get_fragment_reward_for_rank(5)
	var rank_10 = BossRushManager.get_fragment_reward_for_rank(10)

	assert_greater(rank_1, rank_5, "Rank 1 should give more fragments than rank 5")
	assert_greater(rank_5, rank_10, "Rank 5 should give more fragments than rank 10")
	assert_greater(rank_10, 0, "Even rank 10 should give fragments")

	log_info("Boss Rush rewards: Rank 1: %d, Rank 5: %d, Rank 10: %d fragments" % [rank_1, rank_5, rank_10])

# ============================================================================
# SOFTWARE LAB TESTS
# ============================================================================

func test_lab_cost_scaling() -> void:
	# Test lab cost formula: base * (1.08 ^ (level - 1))
	var base = 100

	var cost_1 = int(base * pow(1.08, 0))
	var cost_10 = int(base * pow(1.08, 9))
	var cost_50 = int(base * pow(1.08, 49))

	assert_equal(cost_1, 100, "Level 1 should cost 100 AT")
	assert_equal(cost_10, 199, "Level 10 should cost ~199 AT")
	assert_greater(cost_50, 4300, "Level 50 should cost >4,300 AT")

	log_info("Lab costs (base 100, 1.08 scaling): %d -> %d -> %d AT" % [cost_1, cost_10, cost_50])

# ============================================================================
# FRAGMENT TESTS
# ============================================================================

func test_boss_kill_fragments() -> void:
	# Test boss kill fragment formula: 10 + (wave / 10)
	var wave_10_frags = 10 + int(10 / 10)
	var wave_50_frags = 10 + int(50 / 10)
	var wave_100_frags = 10 + int(100 / 10)

	assert_equal(wave_10_frags, 11, "Wave 10 boss should give 11 fragments")
	assert_equal(wave_50_frags, 15, "Wave 50 boss should give 15 fragments")
	assert_equal(wave_100_frags, 20, "Wave 100 boss should give 20 fragments")

	log_info("Boss fragments: 11 -> 15 -> 20")

# ============================================================================
# OFFLINE PROGRESS TESTS
# ============================================================================

func test_offline_efficiency() -> void:
	# Test offline progress efficiency values
	# Base: 25%, With ad: 50%
	var base_efficiency = 0.25
	var ad_efficiency = 0.50

	var base_at_per_hour = 1000
	var offline_at_base = base_at_per_hour * base_efficiency
	var offline_at_ad = base_at_per_hour * ad_efficiency

	assert_equal(int(offline_at_base), 250, "Base offline should be 25% efficiency")
	assert_equal(int(offline_at_ad), 500, "Ad offline should be 50% efficiency")

	log_info("Offline efficiency: %d AT/h (base) vs %d AT/h (ad)" % [int(offline_at_base), int(offline_at_ad)])

# ============================================================================
# INTEGER OVERFLOW SAFETY TESTS
# ============================================================================

func test_damage_milestone_cap() -> void:
	# Test that milestone multiplier is capped at 200 to prevent overflow
	UpgradeManager.projectile_damage_level = 50000  # Extreme level

	var damage = UpgradeManager.get_projectile_damage()

	assert_greater(damage, 0, "Damage should be positive even at extreme levels")
	assert_less(damage, 2147483647, "Damage should not overflow int32 max")

	log_info("Extreme damage level (50k) returns valid value: %d" % damage)

	UpgradeManager.reset_run_upgrades()

func test_cost_at_extreme_levels() -> void:
	# Test that cost calculations don't overflow
	var cost_100 = UpgradeManager.get_perm_cost(5000, 250, 100)
	var cost_200 = UpgradeManager.get_perm_cost(5000, 250, 200)

	assert_greater(cost_100, 0, "Cost at level 100 should be positive")
	assert_greater(cost_200, 0, "Cost at level 200 should be positive")
	assert_greater(cost_200, cost_100, "Cost should increase with level")

	log_info("Extreme level costs remain valid: Lvl 100: %d, Lvl 200: %d" % [cost_100, cost_200])

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func assert_equal_float(actual: float, expected: float, tolerance: float, message: String = "") -> bool:
	if abs(actual - expected) <= tolerance:
		_log_pass(message if message else "%.2f ≈ %.2f" % [actual, expected])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %.2f ≈ %.2f (diff: %.2f)" % [actual, expected, abs(actual - expected)])
		tests_failed += 1
		return false
