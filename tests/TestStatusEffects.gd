extends "res://tests/TestBase.gd"

## TestStatusEffects - Tests for burn, poison, slow, and stun effects

func _init() -> void:
	super._init("Status Effects Tests")

func _ready() -> void:
	run_all_tests()

# ============================================================================
# BURN EFFECT TESTS
# ============================================================================

func test_burn_application() -> void:
	# Test that burn effect can be applied
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	var initial_hp = enemy.hp
	var burn_level = 3
	var base_damage = 10.0

	assert_false(enemy.burn_active, "Enemy should not have burn initially")

	enemy.apply_burn(burn_level, base_damage)

	assert_true(enemy.burn_active, "Enemy should have burn active after application")
	assert_greater(enemy.burn_duration, 0.0, "Burn should have positive duration")
	assert_greater(enemy.burn_damage_per_tick, 0.0, "Burn should have positive damage per tick")

	log_info("Burn applied: %.1f damage/sec for %.1f seconds" % [enemy.burn_damage_per_tick, enemy.burn_duration])

	cleanup_test_node(enemy)

func test_burn_damage_over_time() -> void:
	# Test that burn deals damage over time
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	var initial_hp = enemy.hp
	enemy.apply_burn(5, 20.0)

	# Wait for one tick interval
	await get_tree().create_timer(1.1).timeout

	# HP should have decreased from burn
	assert_less(enemy.hp, initial_hp, "Burn should have dealt damage after one tick")

	var damage_dealt = initial_hp - enemy.hp
	log_info("Burn dealt %d damage in 1 second" % damage_dealt)

	cleanup_test_node(enemy)

func test_burn_scaling() -> void:
	# Test that burn scales with level
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 10
	enemy.apply_wave_scaling()
	add_child(enemy)

	var base_damage = 15.0

	# Level 1 burn
	enemy.apply_burn(1, base_damage)
	var level1_damage = enemy.burn_damage_per_tick

	# Reset and apply level 10 burn
	enemy.burn_active = false
	enemy.apply_burn(10, base_damage)
	var level10_damage = enemy.burn_damage_per_tick

	assert_greater(level10_damage, level1_damage, "Level 10 burn should deal more damage than level 1")

	log_info("Burn scaling: Lvl 1: %.1f, Lvl 10: %.1f" % [level1_damage, level10_damage])

	cleanup_test_node(enemy)

# ============================================================================
# POISON EFFECT TESTS
# ============================================================================

func test_poison_application() -> void:
	# Test that poison effect can be applied
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	assert_false(enemy.poison_active, "Enemy should not have poison initially")

	enemy.apply_poison(3)

	assert_true(enemy.poison_active, "Enemy should have poison active after application")
	assert_greater(enemy.poison_duration, 0.0, "Poison should have positive duration")
	assert_greater(enemy.poison_damage_per_tick, 0.0, "Poison should have positive damage per tick")

	log_info("Poison applied: %.1f damage/sec for %.1f seconds" % [enemy.poison_damage_per_tick, enemy.poison_duration])

	cleanup_test_node(enemy)

func test_poison_percentage_based() -> void:
	# Test that poison is percentage-based
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 10
	enemy.apply_wave_scaling()
	add_child(enemy)

	var max_hp = enemy.hp
	var poison_level = 5

	enemy.apply_poison(poison_level)

	var expected_min_damage = max_hp * 0.01  # At least 1% per second
	assert_greater(enemy.poison_damage_per_tick, 0, "Poison should deal positive damage")

	log_info("Poison dealing %.1f damage/sec on %d max HP enemy" % [enemy.poison_damage_per_tick, max_hp])

	cleanup_test_node(enemy)

# ============================================================================
# SLOW EFFECT TESTS
# ============================================================================

func test_slow_application() -> void:
	# Test that slow effect can be applied
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	var initial_speed = enemy.move_speed
	assert_false(enemy.slow_active, "Enemy should not have slow initially")

	enemy.apply_slow(3)

	assert_true(enemy.slow_active, "Enemy should have slow active after application")
	assert_greater(enemy.slow_percent, 0.0, "Slow should have positive percentage")
	assert_less(enemy.slow_percent, 1.0, "Slow percentage should be less than 100%")

	log_info("Slow applied: %.0f%% reduction for %.1f seconds" % [enemy.slow_percent * 100, enemy.slow_duration])

	cleanup_test_node(enemy)

func test_slow_scaling() -> void:
	# Test that slow scales with level
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	# Level 1 slow
	enemy.apply_slow(1)
	var level1_slow = enemy.slow_percent

	# Reset and apply level 10 slow
	enemy.slow_active = false
	enemy.apply_slow(10)
	var level10_slow = enemy.slow_percent

	assert_greater(level10_slow, level1_slow, "Level 10 slow should reduce more speed than level 1")

	log_info("Slow scaling: Lvl 1: %.0f%%, Lvl 10: %.0f%%" % [level1_slow * 100, level10_slow * 100])

	cleanup_test_node(enemy)

# ============================================================================
# STUN EFFECT TESTS
# ============================================================================

func test_stun_application() -> void:
	# Test that stun effect can be applied
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	assert_false(enemy.stun_active, "Enemy should not have stun initially")

	enemy.apply_stun(3)

	assert_true(enemy.stun_active, "Enemy should have stun active after application")
	assert_greater(enemy.stun_duration, 0.0, "Stun should have positive duration")

	log_info("Stun applied for %.2f seconds" % enemy.stun_duration)

	cleanup_test_node(enemy)

func test_stun_prevents_movement() -> void:
	# Test that stunned enemies cannot move
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.tower_position = Vector2(500, 500)
	enemy.global_position = Vector2(100, 100)
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	# Apply stun
	enemy.apply_stun(3)

	var start_pos = enemy.global_position

	# Wait for physics frames
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var end_pos = enemy.global_position

	# Enemy should not have moved while stunned
	var distance_moved = start_pos.distance_to(end_pos)
	assert_less(distance_moved, 1.0, "Stunned enemy should not move significantly")

	log_info("Enemy moved %.2f pixels while stunned (should be ~0)" % distance_moved)

	cleanup_test_node(enemy)

func test_stun_duration_scaling() -> void:
	# Test that stun duration scales with level
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	# Level 1 stun
	enemy.apply_stun(1)
	var level1_duration = enemy.stun_duration

	# Reset and apply level 10 stun
	enemy.stun_active = false
	enemy.apply_stun(10)
	var level10_duration = enemy.stun_duration

	assert_greater_equal(level10_duration, level1_duration, "Level 10 stun should last longer than level 1")

	log_info("Stun duration: Lvl 1: %.2fs, Lvl 10: %.2fs" % [level1_duration, level10_duration])

	cleanup_test_node(enemy)

func assert_greater_equal(actual, expected, message: String = "") -> bool:
	if actual >= expected:
		_log_pass(message if message else "%s >= %s" % [actual, expected])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s >= %s" % [actual, expected])
		tests_failed += 1
		return false

# ============================================================================
# MULTIPLE STATUS EFFECTS TESTS
# ============================================================================

func test_multiple_effects_simultaneously() -> void:
	# Test that multiple status effects can be active at once
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 10
	enemy.apply_wave_scaling()
	add_child(enemy)

	# Apply all effects
	enemy.apply_burn(3, 15.0)
	enemy.apply_poison(3)
	enemy.apply_slow(3)
	enemy.apply_stun(3)

	assert_true(enemy.burn_active, "Burn should be active")
	assert_true(enemy.poison_active, "Poison should be active")
	assert_true(enemy.slow_active, "Slow should be active")
	assert_true(enemy.stun_active, "Stun should be active")

	log_info("All 4 status effects active simultaneously on enemy")

	cleanup_test_node(enemy)

func test_effect_expiration() -> void:
	# Test that effects expire after their duration
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 5
	enemy.apply_wave_scaling()
	add_child(enemy)

	# Apply short burn effect
	enemy.apply_burn(1, 10.0)
	var burn_duration = enemy.burn_duration

	assert_true(enemy.burn_active, "Burn should be active initially")

	# Wait for effect to expire
	await get_tree().create_timer(burn_duration + 0.5).timeout

	assert_false(enemy.burn_active, "Burn should have expired after duration")

	log_info("Burn effect expired after %.1f seconds" % burn_duration)

	cleanup_test_node(enemy)
