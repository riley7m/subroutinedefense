extends "res://tests/TestBase.gd"

## TestResources - Tests for currency, rewards, and resource management

func _init() -> void:
	super._init("Resource Management Tests")

func _ready() -> void:
	run_all_tests()

# ============================================================================
# REWARD MANAGER TESTS
# ============================================================================

func test_reward_manager_exists() -> void:
	# Test that RewardManager singleton exists
	assert_not_null(RewardManager, "RewardManager should exist as singleton")
	log_info("RewardManager singleton accessible")

func test_data_credits_initialization() -> void:
	# Test that data credits start at a valid value
	var initial_credits = RewardManager.data_credits

	assert_greater_equal(initial_credits, 0, "Data credits should be non-negative")
	log_info("Starting data credits: %d" % initial_credits)

func test_add_data_credits() -> void:
	# Test adding data credits
	var initial_credits = RewardManager.data_credits
	var amount_to_add = 100

	RewardManager.add_data_credits(amount_to_add)

	var new_credits = RewardManager.data_credits
	var expected_credits = initial_credits + amount_to_add

	assert_equal(new_credits, expected_credits, "Credits should increase by amount added")
	log_info("Added %d credits: %d -> %d" % [amount_to_add, initial_credits, new_credits])

	# Reset for other tests
	RewardManager.data_credits = initial_credits

func test_spend_data_credits() -> void:
	# Test spending data credits (manual check since no spend method exists)
	RewardManager.data_credits = 1000
	var initial_credits = RewardManager.data_credits

	# Manually check and spend
	var cost = 500
	var can_afford = RewardManager.data_credits >= cost
	assert_true(can_afford, "Should be able to afford 500 credits with 1000")

	if can_afford:
		RewardManager.data_credits -= cost

	var new_credits = RewardManager.data_credits
	assert_equal(new_credits, 500, "Credits should decrease by amount spent")

	log_info("Spent 500 credits: %d -> %d" % [initial_credits, new_credits])

func test_cannot_overspend() -> void:
	# Test that you can't spend more than you have
	RewardManager.data_credits = 100

	var cost = 200
	var can_afford = RewardManager.data_credits >= cost
	assert_false(can_afford, "Should not be able to afford 200 credits with 100")

	var initial_credits = RewardManager.data_credits
	if can_afford:
		RewardManager.data_credits -= cost

	assert_equal(RewardManager.data_credits, initial_credits, "Credits should not change when can't afford")

	log_info("Correctly prevented overspending")

# ============================================================================
# ARCHIVE TOKENS (PERMANENT CURRENCY) TESTS
# ============================================================================

func test_archive_tokens_initialization() -> void:
	# Test that archive tokens start at valid value
	var initial_tokens = RewardManager.archive_tokens

	assert_greater_equal(initial_tokens, 0, "Archive tokens should be non-negative")
	log_info("Starting archive tokens: %d" % initial_tokens)

func test_add_archive_tokens() -> void:
	# Test adding archive tokens
	var initial_tokens = RewardManager.archive_tokens
	var amount_to_add = 50

	RewardManager.add_archive_tokens(amount_to_add)

	var new_tokens = RewardManager.archive_tokens
	var expected_tokens = initial_tokens + amount_to_add

	assert_equal(new_tokens, expected_tokens, "Tokens should increase by amount added")
	log_info("Added %d tokens: %d -> %d" % [amount_to_add, initial_tokens, new_tokens])

	# Reset for other tests
	RewardManager.archive_tokens = initial_tokens

# ============================================================================
# FRAGMENTS (SPECIAL CURRENCY) TESTS
# ============================================================================

func test_fragments_initialization() -> void:
	# Test that fragments start at valid value
	var initial_fragments = RewardManager.fragments

	assert_greater_equal(initial_fragments, 0, "Fragments should be non-negative")
	log_info("Starting fragments: %d" % initial_fragments)

func test_add_fragments() -> void:
	# Test adding fragments
	var initial_fragments = RewardManager.fragments
	var amount_to_add = 25

	RewardManager.add_fragments(amount_to_add)

	var new_fragments = RewardManager.fragments
	var expected_fragments = initial_fragments + amount_to_add

	assert_equal(new_fragments, expected_fragments, "Fragments should increase by amount added")
	log_info("Added %d fragments: %d -> %d" % [amount_to_add, initial_fragments, new_fragments])

	# Reset for other tests
	RewardManager.fragments = initial_fragments

# ============================================================================
# ENEMY REWARD TESTS
# ============================================================================

func test_enemy_reward_system() -> void:
	# Test that killing enemies grants rewards
	var initial_credits = RewardManager.data_credits

	# Simulate killing a basic enemy at wave 1
	RewardManager.reward_enemy("breacher", 1)

	var new_credits = RewardManager.data_credits

	assert_greater(new_credits, initial_credits, "Killing enemy should grant credits")
	log_info("Enemy kill reward: %d credits" % (new_credits - initial_credits))

	# Reset
	RewardManager.data_credits = initial_credits

func test_boss_reward_higher() -> void:
	# Test that boss enemies give more rewards
	var initial_credits = RewardManager.data_credits

	# Kill basic enemy
	RewardManager.reward_enemy("breacher", 10)
	var credits_after_basic = RewardManager.data_credits
	var basic_reward = credits_after_basic - initial_credits

	# Reset and kill boss
	RewardManager.data_credits = initial_credits
	RewardManager.reward_enemy("override", 10)
	var credits_after_boss = RewardManager.data_credits
	var boss_reward = credits_after_boss - initial_credits

	assert_greater(boss_reward, basic_reward, "Boss should give more rewards than basic enemy")
	log_info("Basic enemy reward: %d, Boss reward: %d" % [basic_reward, boss_reward])

	# Reset
	RewardManager.data_credits = initial_credits

func test_wave_scaling_rewards() -> void:
	# Test that rewards scale with wave number
	var initial_credits = RewardManager.data_credits

	# Kill enemy at wave 1
	RewardManager.reward_enemy("breacher", 1)
	var wave1_reward = RewardManager.data_credits - initial_credits

	# Reset and kill enemy at wave 20
	RewardManager.data_credits = initial_credits
	RewardManager.reward_enemy("breacher", 20)
	var wave20_reward = RewardManager.data_credits - initial_credits

	assert_greater(wave20_reward, wave1_reward, "Wave 20 should give more rewards than Wave 1")
	log_info("Wave 1 reward: %d, Wave 20 reward: %d" % [wave1_reward, wave20_reward])

	# Reset
	RewardManager.data_credits = initial_credits

# ============================================================================
# RUN STATS TESTS
# ============================================================================

func test_run_stats_tracking() -> void:
	# Test that run stats are tracked
	RunStats.reset()

	var initial_damage = RunStats.damage_dealt
	var initial_credits = RunStats.data_credits_earned

	assert_equal(initial_damage, 0, "Starting damage dealt should be 0")
	assert_equal(initial_credits, 0, "Starting credits earned should be 0")

	# Simulate some stats
	RunStats.damage_dealt += 1000
	RunStats.data_credits_earned += 500

	assert_equal(RunStats.damage_dealt, 1000, "Damage dealt should be tracked")
	assert_equal(RunStats.data_credits_earned, 500, "Credits earned should be tracked")

	log_info("Run stats tracking: %d damage, %d credits" % [RunStats.damage_dealt, RunStats.data_credits_earned])

	RunStats.reset()

func test_run_stats_damage_taken() -> void:
	# Test damage taken stat
	RunStats.reset()

	RunStats.damage_taken += 250

	assert_equal(RunStats.damage_taken, 250, "Damage taken should be tracked")
	log_info("Damage taken tracking: %d" % RunStats.damage_taken)

	RunStats.reset()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func assert_greater_equal(actual, expected, message: String = "") -> bool:
	if actual >= expected:
		_log_pass(message if message else "%s >= %s" % [actual, expected])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s >= %s" % [actual, expected])
		tests_failed += 1
		return false
