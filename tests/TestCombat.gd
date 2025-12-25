extends "res://tests/TestBase.gd"

## TestCombat - Tests for tower shooting, projectiles, and damage calculations

func _init() -> void:
	super._init("Combat & Damage Tests")

func _ready() -> void:
	run_all_tests()

# ============================================================================
# CRITICAL HIT TESTS
# ============================================================================

func test_critical_hit_calculation() -> void:
	# Test that critical hits work correctly
	UpgradeManager.reset_upgrades()

	var base_damage = UpgradeManager.get_projectile_damage()
	var crit_multiplier = UpgradeManager.get_crit_damage_multiplier()

	var expected_crit_damage = int(base_damage * crit_multiplier)

	assert_greater(crit_multiplier, 1.0, "Crit multiplier should be greater than 1.0")
	assert_greater(expected_crit_damage, base_damage, "Crit damage should be higher than base damage")

	log_info("Base Damage: %d" % base_damage)
	log_info("Crit Multiplier: %.2fx" % crit_multiplier)
	log_info("Expected Crit Damage: %d" % expected_crit_damage)

func test_critical_chance() -> void:
	# Test that crit chance is within valid range
	UpgradeManager.reset_upgrades()

	var crit_chance = UpgradeManager.get_crit_chance()

	assert_in_range(crit_chance, 0.0, 100.0, "Crit chance should be between 0% and 100%")
	log_info("Base Crit Chance: %d%%" % crit_chance)

	# Test with upgraded crit chance
	UpgradeManager.crit_chance_level = 5
	var upgraded_chance = UpgradeManager.get_crit_chance()

	assert_greater(upgraded_chance, crit_chance, "Upgraded crit chance should be higher")
	assert_in_range(upgraded_chance, 0.0, 100.0, "Upgraded crit chance should still be valid range")
	log_info("Upgraded Crit Chance (Lvl 5): %d%%" % upgraded_chance)

	UpgradeManager.reset_upgrades()

# ============================================================================
# DAMAGE CALCULATION TESTS
# ============================================================================

func test_tower_damage_output() -> void:
	# Test tower's base damage
	UpgradeManager.reset_upgrades()

	var base_damage = UpgradeManager.get_projectile_damage()

	assert_greater(base_damage, 0, "Tower should have positive base damage")
	log_info("Tower base damage: %d" % base_damage)

func test_damage_upgrades() -> void:
	# Test that damage upgrades increase damage
	UpgradeManager.reset_upgrades()

	var base_damage = UpgradeManager.get_projectile_damage()

	UpgradeManager.projectile_damage_level = 5
	var upgraded_damage = UpgradeManager.get_projectile_damage()

	assert_greater(upgraded_damage, base_damage, "Upgraded damage should be higher than base")
	log_info("Damage increase from 5 upgrades: %d -> %d" % [base_damage, upgraded_damage])

	UpgradeManager.reset_upgrades()

func test_damage_reduction() -> void:
	# Test enemy damage reduction mechanic
	UpgradeManager.reset_upgrades()

	var reduction = UpgradeManager.get_damage_reduction_level()
	assert_in_range(reduction, 0, 100, "Damage reduction should be between 0-100%")

	# Test with upgraded reduction
	UpgradeManager.damage_reduction_level = 3
	var upgraded_reduction = UpgradeManager.get_damage_reduction_level()

	assert_greater(upgraded_reduction, reduction, "Upgraded reduction should be higher")
	log_info("Damage Reduction: %d%% -> %d%% (after 3 upgrades)" % [reduction, upgraded_reduction])

	UpgradeManager.reset_upgrades()

# ============================================================================
# FIRE RATE TESTS
# ============================================================================

func test_fire_rate() -> void:
	# Test tower fire rate
	UpgradeManager.reset_upgrades()

	var base_fire_rate = UpgradeManager.get_projectile_fire_rate()

	assert_greater(base_fire_rate, 0.0, "Fire rate should be positive")
	log_info("Base fire rate: %.2f shots/sec" % base_fire_rate)

	# Test upgraded fire rate
	UpgradeManager.fire_rate_level = 5
	var upgraded_fire_rate = UpgradeManager.get_projectile_fire_rate()

	assert_greater(upgraded_fire_rate, base_fire_rate, "Upgraded fire rate should be higher")
	log_info("Upgraded fire rate: %.2f shots/sec" % upgraded_fire_rate)

	UpgradeManager.reset_upgrades()

# ============================================================================
# MULTI-TARGET TESTS
# ============================================================================

func test_multi_target() -> void:
	# Test multi-target upgrade
	UpgradeManager.reset_upgrades()

	var base_targets = UpgradeManager.get_multi_target_level()
	assert_equal(base_targets, 1, "Base should target 1 enemy")

	# Upgrade to multi-target
	UpgradeManager.multi_target_level = 3
	var upgraded_targets = UpgradeManager.get_multi_target_level()

	assert_greater(upgraded_targets, base_targets, "Upgraded should target more enemies")
	assert_less_equal(upgraded_targets, UpgradeManager.MULTI_TARGET_MAX_LEVEL,
		"Targets should not exceed max level")

	log_info("Multi-target: %d -> %d enemies" % [base_targets, upgraded_targets])

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

# ============================================================================
# PROJECTILE TESTS
# ============================================================================

func test_projectile_creation() -> void:
	# Test that projectiles can be created
	var projectile_scene = load("res://projectile.tscn")
	assert_not_null(projectile_scene, "Projectile scene should load")

	var projectile = projectile_scene.instantiate()
	assert_not_null(projectile, "Projectile should be instantiated")

	add_child(projectile)

	assert_true(projectile.is_inside_tree(), "Projectile should be in scene tree")
	assert_greater(projectile.speed, 0, "Projectile should have positive speed")

	log_info("Projectile speed: %.2f" % projectile.speed)

	cleanup_test_node(projectile)

func test_projectile_targeting() -> void:
	# Test projectile targeting mechanics
	var projectile = preload("res://projectile.tscn").instantiate()
	var enemy = preload("res://enemy.tscn").instantiate()

	add_child(projectile)
	add_child(enemy)

	enemy.global_position = Vector2(500, 500)
	projectile.global_position = Vector2(100, 100)
	projectile.target = enemy

	assert_not_null(projectile.target, "Projectile should have a target")
	assert_equal(projectile.target, enemy, "Projectile target should be the enemy")

	log_info("Projectile targeting enemy at %s" % enemy.global_position)

	cleanup_test_node(projectile)
	cleanup_test_node(enemy)

# ============================================================================
# TOWER HEALTH TESTS
# ============================================================================

func test_tower_health() -> void:
	# Test tower health system
	var tower_scene = load("res://tower.tscn")
	if not tower_scene:
		log_info("Tower scene not found, skipping test")
		return

	var tower = tower_scene.instantiate()
	add_child(tower)

	var initial_hp = tower.tower_hp
	assert_greater(initial_hp, 0, "Tower should start with positive HP")

	log_info("Tower starting HP: %d" % initial_hp)

	cleanup_test_node(tower)

func test_tower_shield() -> void:
	# Test tower shield system
	UpgradeManager.reset_upgrades()

	var shield_capacity = UpgradeManager.get_shield_capacity()
	var shield_regen = UpgradeManager.get_shield_regen_rate()

	assert_greater_equal(shield_capacity, 0, "Shield capacity should be non-negative")
	assert_greater_equal(shield_regen, 0, "Shield regen should be non-negative")

	log_info("Shield capacity: %d" % shield_capacity)
	log_info("Shield regen rate: %.2f%%/sec" % shield_regen)

func assert_greater_equal(actual, expected, message: String = "") -> bool:
	if actual >= expected:
		_log_pass(message if message else "%s >= %s" % [actual, expected])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s >= %s" % [actual, expected])
		tests_failed += 1
		return false
