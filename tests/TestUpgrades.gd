extends "res://tests/TestBase.gd"

## TestUpgrades - Tests for upgrade system and progression

func _init() -> void:
	super._init("Upgrade System Tests")

func _ready() -> void:
	run_all_tests()

# ============================================================================
# UPGRADE SYSTEM BASICS
# ============================================================================

func test_upgrade_manager_exists() -> void:
	# Test that UpgradeManager singleton exists
	assert_not_null(UpgradeManager, "UpgradeManager should exist as singleton")
	log_info("UpgradeManager singleton accessible")

func test_reset_upgrades() -> void:
	# Test that upgrades can be reset
	UpgradeManager.projectile_damage_level = 10
	UpgradeManager.fire_rate_level = 5

	UpgradeManager.reset_upgrades()

	assert_equal(UpgradeManager.projectile_damage_level, 0, "Damage level should reset to 0")
	assert_equal(UpgradeManager.fire_rate_level, 0, "Fire rate level should reset to 0")

	log_info("Upgrades reset successfully")

# ============================================================================
# DAMAGE UPGRADE TESTS
# ============================================================================

func test_damage_upgrade_progression() -> void:
	# Test that damage increases with each level
	UpgradeManager.reset_upgrades()

	var level0_damage = UpgradeManager.get_projectile_damage()

	UpgradeManager.projectile_damage_level = 1
	var level1_damage = UpgradeManager.get_projectile_damage()

	UpgradeManager.projectile_damage_level = 5
	var level5_damage = UpgradeManager.get_projectile_damage()

	UpgradeManager.projectile_damage_level = 10
	var level10_damage = UpgradeManager.get_projectile_damage()

	assert_greater(level1_damage, level0_damage, "Level 1 damage > Level 0")
	assert_greater(level5_damage, level1_damage, "Level 5 damage > Level 1")
	assert_greater(level10_damage, level5_damage, "Level 10 damage > Level 5")

	log_info("Damage progression: %d -> %d -> %d -> %d" % [level0_damage, level1_damage, level5_damage, level10_damage])

	UpgradeManager.reset_upgrades()

func test_damage_upgrade_cost() -> void:
	# Test that upgrade costs increase
	UpgradeManager.reset_upgrades()

	var cost_level_1 = UpgradeManager.get_damage_cost_for_level(1)
	var cost_level_5 = UpgradeManager.get_damage_cost_for_level(5)
	var cost_level_10 = UpgradeManager.get_damage_cost_for_level(10)

	assert_greater(cost_level_5, cost_level_1, "Level 5 should cost more than level 1")
	assert_greater(cost_level_10, cost_level_5, "Level 10 should cost more than level 5")

	log_info("Upgrade costs: Lvl 1: %d, Lvl 5: %d, Lvl 10: %d" % [cost_level_1, cost_level_5, cost_level_10])

# ============================================================================
# FIRE RATE UPGRADE TESTS
# ============================================================================

func test_fire_rate_upgrade_progression() -> void:
	# Test that fire rate increases with levels
	UpgradeManager.reset_upgrades()

	var level0_rate = UpgradeManager.get_projectile_fire_rate()

	UpgradeManager.fire_rate_level = 3
	var level3_rate = UpgradeManager.get_projectile_fire_rate()

	UpgradeManager.fire_rate_level = 7
	var level7_rate = UpgradeManager.get_projectile_fire_rate()

	assert_greater(level3_rate, level0_rate, "Level 3 fire rate > Level 0")
	assert_greater(level7_rate, level3_rate, "Level 7 fire rate > Level 3")

	log_info("Fire rate progression: %.2f -> %.2f -> %.2f shots/sec" % [level0_rate, level3_rate, level7_rate])

	UpgradeManager.reset_upgrades()

# ============================================================================
# CRIT UPGRADE TESTS
# ============================================================================

func test_crit_chance_upgrade() -> void:
	# Test crit chance upgrade progression
	UpgradeManager.reset_upgrades()

	var level0_chance = UpgradeManager.get_crit_chance()

	UpgradeManager.crit_chance_level = 5
	var level5_chance = UpgradeManager.get_crit_chance()

	UpgradeManager.crit_chance_level = 10
	var level10_chance = UpgradeManager.get_crit_chance()

	assert_greater(level5_chance, level0_chance, "Level 5 crit chance > Level 0")
	assert_greater(level10_chance, level5_chance, "Level 10 crit chance > Level 5")
	assert_less_equal(level10_chance, 100, "Crit chance should not exceed 100%")

	log_info("Crit chance progression: %d%% -> %d%% -> %d%%" % [level0_chance, level5_chance, level10_chance])

	UpgradeManager.reset_upgrades()

func test_crit_damage_upgrade() -> void:
	# Test crit damage multiplier upgrade
	UpgradeManager.reset_upgrades()

	var level0_mult = UpgradeManager.get_crit_damage_multiplier()

	UpgradeManager.crit_damage_level = 4
	var level4_mult = UpgradeManager.get_crit_damage_multiplier()

	UpgradeManager.crit_damage_level = 8
	var level8_mult = UpgradeManager.get_crit_damage_multiplier()

	assert_greater(level4_mult, level0_mult, "Level 4 crit damage > Level 0")
	assert_greater(level8_mult, level4_mult, "Level 8 crit damage > Level 4")
	assert_greater(level0_mult, 1.0, "Crit multiplier should be > 1.0")

	log_info("Crit damage progression: %.2fx -> %.2fx -> %.2fx" % [level0_mult, level4_mult, level8_mult])

	UpgradeManager.reset_upgrades()

# ============================================================================
# DEFENSIVE UPGRADE TESTS
# ============================================================================

func test_shield_capacity_upgrade() -> void:
	# Test shield capacity upgrade
	UpgradeManager.reset_upgrades()

	var level0_shield = UpgradeManager.get_shield_capacity()

	UpgradeManager.shield_capacity_level = 3
	var level3_shield = UpgradeManager.get_shield_capacity()

	UpgradeManager.shield_capacity_level = 7
	var level7_shield = UpgradeManager.get_shield_capacity()

	assert_greater_equal(level3_shield, level0_shield, "Level 3 shield >= Level 0")
	assert_greater_equal(level7_shield, level3_shield, "Level 7 shield >= Level 3")

	log_info("Shield capacity progression: %d -> %d -> %d" % [level0_shield, level3_shield, level7_shield])

	UpgradeManager.reset_upgrades()

func test_shield_regen_upgrade() -> void:
	# Test shield regen rate upgrade
	UpgradeManager.reset_upgrades()

	var level0_regen = UpgradeManager.get_shield_regen_rate()

	UpgradeManager.shield_regen_level = 3
	var level3_regen = UpgradeManager.get_shield_regen_rate()

	UpgradeManager.shield_regen_level = 6
	var level6_regen = UpgradeManager.get_shield_regen_rate()

	assert_greater_equal(level3_regen, level0_regen, "Level 3 regen >= Level 0")
	assert_greater_equal(level6_regen, level3_regen, "Level 6 regen >= Level 3")

	log_info("Shield regen progression: %.2f%% -> %.2f%% -> %.2f%%" % [level0_regen, level3_regen, level6_regen])

	UpgradeManager.reset_upgrades()

func test_damage_reduction_upgrade() -> void:
	# Test damage reduction upgrade
	UpgradeManager.reset_upgrades()

	var level0_reduction = UpgradeManager.get_damage_reduction_level()

	UpgradeManager.damage_reduction_level = 3
	var level3_reduction = UpgradeManager.get_damage_reduction_level()

	assert_greater_equal(level3_reduction, level0_reduction, "Level 3 reduction >= Level 0")
	assert_less(level3_reduction, 100, "Damage reduction should be < 100%")

	log_info("Damage reduction: %d%% -> %d%%" % [level0_reduction, level3_reduction])

	UpgradeManager.reset_upgrades()

# ============================================================================
# MULTI-TARGET UPGRADE TESTS
# ============================================================================

func test_multi_target_upgrade() -> void:
	# Test multi-target upgrade
	UpgradeManager.reset_upgrades()

	var level0_targets = UpgradeManager.get_multi_target_level()
	assert_equal(level0_targets, 1, "Should start with 1 target")

	UpgradeManager.multi_target_level = 1
	var level1_targets = UpgradeManager.get_multi_target_level()
	assert_greater(level1_targets, level0_targets, "Level 1 should target more enemies")

	UpgradeManager.multi_target_level = UpgradeManager.MULTI_TARGET_MAX_LEVEL
	var max_targets = UpgradeManager.get_multi_target_level()
	assert_equal(max_targets, UpgradeManager.MULTI_TARGET_MAX_LEVEL, "Should cap at max level")

	log_info("Multi-target progression: %d -> %d -> %d (max)" % [level0_targets, level1_targets, max_targets])

	UpgradeManager.reset_upgrades()

func test_multi_target_cost() -> void:
	# Test multi-target upgrade cost
	var cost_level_1 = UpgradeManager.get_multi_target_cost_for_level(1)
	var cost_level_3 = UpgradeManager.get_multi_target_cost_for_level(3)

	assert_greater(cost_level_1, 0, "Level 1 should have positive cost")
	assert_greater(cost_level_3, cost_level_1, "Level 3 should cost more than level 1")

	log_info("Multi-target costs: Lvl 1: %d, Lvl 3: %d" % [cost_level_1, cost_level_3])

# ============================================================================
# UPGRADE LIMIT TESTS
# ============================================================================

func test_max_upgrade_levels() -> void:
	# Test that upgrades respect max levels
	UpgradeManager.reset_upgrades()

	# Try to set beyond reasonable limits
	UpgradeManager.projectile_damage_level = 100
	UpgradeManager.fire_rate_level = 100
	UpgradeManager.crit_chance_level = 100

	# Should still return valid values
	var damage = UpgradeManager.get_projectile_damage()
	var fire_rate = UpgradeManager.get_projectile_fire_rate()
	var crit_chance = UpgradeManager.get_crit_chance()

	assert_greater(damage, 0, "Damage should be positive even at extreme levels")
	assert_greater(fire_rate, 0, "Fire rate should be positive even at extreme levels")
	assert_less_equal(crit_chance, 100, "Crit chance should not exceed 100%")

	log_info("Extreme level test passed - upgrades remain valid")

	UpgradeManager.reset_upgrades()

func assert_less_equal(actual, expected, message: String = "") -> bool:
	if actual <= expected:
		_log_pass(message if message else "%s <= %s" % [actual, expected])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s <= %s" % [actual, expected])
		tests_failed += 1
		return false

func assert_greater_equal(actual, expected, message: String = "") -> bool:
	if actual >= expected:
		_log_pass(message if message else "%s >= %s" % [actual, expected])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s >= %s" % [actual, expected])
		tests_failed += 1
		return false
