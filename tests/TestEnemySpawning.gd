extends "res://tests/TestBase.gd"

## TestEnemySpawning - Tests for enemy spawning and wave progression

func _init() -> void:
	super._init("Enemy Spawning & Wave Tests")

func _ready() -> void:
	# Auto-run tests when loaded
	run_all_tests()

# ============================================================================
# WAVE SCALING TESTS
# ============================================================================

func test_enemy_wave_scaling() -> void:
	# Test that enemies scale properly with wave number
	var enemy = preload("res://enemy.tscn").instantiate()
	add_child(enemy)

	# Test wave 1
	enemy.wave_number = 1
	enemy.apply_wave_scaling()
	var wave1_hp = enemy.hp

	assert_greater(wave1_hp, 0, "Wave 1: Enemy HP should be positive")
	log_info("Wave 1 HP: %d" % wave1_hp)

	# Test wave 10
	enemy.wave_number = 10
	enemy.apply_wave_scaling()
	var wave10_hp = enemy.hp

	assert_greater(wave10_hp, wave1_hp, "Wave 10: HP should be higher than Wave 1")
	log_info("Wave 10 HP: %d" % wave10_hp)

	# Test wave 50
	enemy.wave_number = 50
	enemy.apply_wave_scaling()
	var wave50_hp = enemy.hp

	assert_greater(wave50_hp, wave10_hp, "Wave 50: HP should be higher than Wave 10")
	log_info("Wave 50 HP: %d" % wave50_hp)

	cleanup_test_node(enemy)

func test_enemy_damage_scaling() -> void:
	# Test that enemy damage scales with waves
	var enemy = preload("res://enemy.tscn").instantiate()
	add_child(enemy)

	enemy.wave_number = 1
	enemy.apply_wave_scaling()
	var wave1_damage = enemy.damage_to_tower

	enemy.wave_number = 20
	enemy.apply_wave_scaling()
	var wave20_damage = enemy.damage_to_tower

	assert_greater(wave20_damage, wave1_damage, "Wave 20 damage should be higher than Wave 1")
	log_info("Wave 1 Damage: %d, Wave 20 Damage: %d" % [wave1_damage, wave20_damage])

	cleanup_test_node(enemy)

func test_enemy_speed_scaling() -> void:
	# Test that enemy speed scales with waves
	var enemy = preload("res://enemy.tscn").instantiate()
	add_child(enemy)

	enemy.wave_number = 1
	enemy.apply_wave_scaling()
	var wave1_speed = enemy.move_speed

	enemy.wave_number = 30
	enemy.apply_wave_scaling()
	var wave30_speed = enemy.move_speed

	assert_greater(wave30_speed, wave1_speed, "Wave 30 speed should be higher than Wave 1")
	log_info("Wave 1 Speed: %.2f, Wave 30 Speed: %.2f" % [wave1_speed, wave30_speed])

	cleanup_test_node(enemy)

# ============================================================================
# ENEMY TYPE TESTS
# ============================================================================

func test_enemy_types() -> void:
	# Test that different enemy types can be created
	var types = ["breacher", "slicer", "sentinel", "null_walker", "override", "signal_runner"]

	for type in types:
		var enemy = preload("res://enemy.tscn").instantiate()
		enemy.enemy_type = type
		add_child(enemy)

		assert_equal(enemy.enemy_type, type, "Enemy type should be set to %s" % type)
		log_info("Successfully created enemy type: %s" % type)

		cleanup_test_node(enemy)

func test_boss_enemy() -> void:
	# Test boss enemy ("override" type)
	var boss = preload("res://enemy.tscn").instantiate()
	boss.enemy_type = "override"
	boss.wave_number = 10
	boss.apply_wave_scaling()
	add_child(boss)

	assert_equal(boss.enemy_type, "override", "Boss type should be 'override'")
	assert_greater(boss.hp, 0, "Boss should have HP")

	log_info("Boss HP at wave 10: %d" % boss.hp)

	cleanup_test_node(boss)

# ============================================================================
# ENEMY MOVEMENT TESTS
# ============================================================================

func test_enemy_movement_toward_tower() -> void:
	# Test that enemy moves toward tower position
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.tower_position = Vector2(500, 500)
	enemy.global_position = Vector2(100, 100)
	enemy.wave_number = 1
	enemy.apply_wave_scaling()
	add_child(enemy)

	var start_pos = enemy.global_position
	var start_distance = start_pos.distance_to(enemy.tower_position)

	# Simulate one physics frame
	await get_tree().process_frame
	await get_tree().physics_frame

	var end_pos = enemy.global_position
	var end_distance = end_pos.distance_to(enemy.tower_position)

	# Enemy should have moved (position changed)
	var moved = start_pos != end_pos
	assert_true(moved, "Enemy should have moved from starting position")

	if moved:
		log_info("Enemy moved from %s to %s" % [start_pos, end_pos])

	cleanup_test_node(enemy)

# ============================================================================
# ENEMY DEATH TESTS
# ============================================================================

func test_enemy_death() -> void:
	# Test that enemy dies when HP reaches 0
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 1
	enemy.apply_wave_scaling()
	add_child(enemy)

	var initial_hp = enemy.hp
	assert_greater(initial_hp, 0, "Enemy should start with positive HP")

	# Deal lethal damage
	enemy.take_damage(initial_hp + 100)

	assert_true(enemy.is_dead, "Enemy should be marked as dead after lethal damage")
	log_info("Enemy died after taking %d damage (had %d HP)" % [initial_hp + 100, initial_hp])

	# Wait for death animation
	await get_tree().create_timer(0.5).timeout

	cleanup_test_node(enemy)

func test_enemy_partial_damage() -> void:
	# Test that enemy takes partial damage correctly
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.wave_number = 1
	enemy.apply_wave_scaling()
	add_child(enemy)

	var initial_hp = enemy.hp
	var damage_amount = int(initial_hp / 2)

	enemy.take_damage(damage_amount)

	var expected_hp = initial_hp - damage_amount
	assert_equal(enemy.hp, expected_hp, "Enemy HP should be reduced by damage amount")
	assert_false(enemy.is_dead, "Enemy should not be dead from partial damage")

	log_info("Enemy took %d damage, HP: %d -> %d" % [damage_amount, initial_hp, enemy.hp])

	cleanup_test_node(enemy)
