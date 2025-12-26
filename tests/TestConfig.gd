extends "res://tests/TestBase.gd"

## TestConfig - Tests for configuration loading system

func _init() -> void:
	super._init("Configuration System Tests")

func _ready() -> void:
	run_all_tests()

# ============================================================================
# CONFIG LOADER TESTS
# ============================================================================

func test_config_loader_exists() -> void:
	# Test that ConfigLoader singleton exists
	assert_not_null(ConfigLoader, "ConfigLoader should exist as singleton")
	log_info("ConfigLoader singleton accessible")

func test_config_loaded() -> void:
	# Test that configuration was loaded successfully
	assert_true(ConfigLoader.loaded, "Configuration should be loaded on startup")
	assert_not_null(ConfigLoader.config, "Config dictionary should not be null")
	assert_greater(ConfigLoader.config.keys().size(), 0, "Config should have data")

	log_info("Configuration loaded with %d top-level sections" % ConfigLoader.config.keys().size())

func test_config_file_exists() -> void:
	# Test that the config file exists
	var file = FileAccess.open("res://config/game_balance.json", FileAccess.READ)
	assert_not_null(file, "game_balance.json should exist")

	if file:
		var content = file.get_as_text()
		file.close()
		assert_greater(content.length(), 100, "Config file should have content")

	log_info("game_balance.json exists and has content")

# ============================================================================
# PERMANENT UPGRADE CONFIG TESTS
# ============================================================================

func test_perm_upgrade_cost_scaling_config() -> void:
	# Test that permanent upgrade cost scaling is loaded
	var scaling = ConfigLoader.get_perm_upgrade_cost_scaling()

	assert_equal_float(scaling, 1.13, 0.001, "Perm upgrade scaling should be 1.13")

	log_info("Perm upgrade cost scaling: %.2f" % scaling)

func test_perm_upgrade_base_costs_config() -> void:
	# Test that permanent upgrade base costs are loaded
	var damage_cost = ConfigLoader.get_perm_upgrade_base_cost("projectile_damage")

	assert_equal(damage_cost, 5000, "Projectile damage base cost should be 5000 AT")

	log_info("Projectile damage base cost: %d AT" % damage_cost)

# ============================================================================
# IN-RUN UPGRADE CONFIG TESTS
# ============================================================================

func test_in_run_cost_scaling_config() -> void:
	# Test that in-run upgrade cost scaling is loaded
	var scaling = ConfigLoader.get_in_run_cost_scaling()

	assert_equal_float(scaling, 1.15, 0.001, "In-run upgrade scaling should be 1.15")

	log_info("In-run upgrade cost scaling: %.2f" % scaling)

func test_in_run_base_costs_config() -> void:
	# Test that in-run upgrade base costs are loaded
	var damage_cost = ConfigLoader.get_in_run_base_cost("damage")

	assert_equal(damage_cost, 50, "Damage upgrade base cost should be 50 DC")

	log_info("Damage upgrade base cost: %d DC" % damage_cost)

func test_in_run_caps_config() -> void:
	# Test that upgrade caps are loaded
	var crit_cap = ConfigLoader.get_in_run_cap("crit_chance")

	assert_equal(crit_cap, 60, "Crit chance cap should be 60%")

	log_info("Crit chance cap: %d%%" % crit_cap)

func test_damage_milestone_config() -> void:
	# Test that damage milestone scaling is loaded
	var milestone_config = ConfigLoader.get_damage_milestone_scaling()

	assert_equal(milestone_config["levels_per_milestone"], 100, "Should be 100 levels per milestone")
	assert_equal_float(milestone_config["multiplier_per_milestone"], 1.5, 0.01, "Should be 1.5x per milestone")
	assert_equal(milestone_config["max_milestones"], 200, "Should cap at 200 milestones")

	log_info("Milestone config: %d levels, %.1fx mult, %d max" % [
		milestone_config["levels_per_milestone"],
		milestone_config["multiplier_per_milestone"],
		milestone_config["max_milestones"]
	])

# ============================================================================
# CURRENCY REWARD CONFIG TESTS
# ============================================================================

func test_wave_scaling_config() -> void:
	# Test that wave scaling percentage is loaded
	var wave_scaling = ConfigLoader.get_wave_scaling_percent()

	assert_equal_float(wave_scaling, 0.02, 0.001, "Wave scaling should be 0.02 (2%)")

	log_info("Wave scaling: %.2f%%" % (wave_scaling * 100))

func test_wave_at_bonus_config() -> void:
	# Test that wave AT bonus formula parameters are loaded
	var coefficient = ConfigLoader.get_wave_at_bonus_coefficient()
	var exponent = ConfigLoader.get_wave_at_bonus_exponent()

	assert_equal_float(coefficient, 0.25, 0.001, "Wave AT coefficient should be 0.25")
	assert_equal_float(exponent, 1.15, 0.001, "Wave AT exponent should be 1.15")

	log_info("Wave AT bonus: %.2f * (wave ^ %.2f)" % [coefficient, exponent])

func test_enemy_rewards_config() -> void:
	# Test that enemy base rewards are loaded
	var breacher_dc = ConfigLoader.get_enemy_base_dc("Breacher")
	var override_dc = ConfigLoader.get_enemy_base_dc("Override")

	assert_equal(breacher_dc, 10, "Breacher should give 10 DC")
	assert_equal(override_dc, 100, "Override should give 100 DC")

	log_info("Enemy DC rewards: Breacher: %d, Override: %d" % [breacher_dc, override_dc])

# ============================================================================
# TIER SYSTEM CONFIG TESTS
# ============================================================================

func test_tier_system_config() -> void:
	# Test that tier system config is loaded
	var total_tiers = ConfigLoader.get_total_tiers()
	var waves_per_tier = ConfigLoader.get_waves_per_tier()
	var multiplier_base = ConfigLoader.get_tier_reward_multiplier_base()

	assert_equal(total_tiers, 10, "Should have 10 tiers")
	assert_equal(waves_per_tier, 5000, "Should be 5000 waves per tier")
	assert_equal(multiplier_base, 5, "Multiplier base should be 5")

	log_info("Tier config: %d tiers, %d waves/tier, %dx base" % [total_tiers, waves_per_tier, multiplier_base])

# ============================================================================
# BOSS RUSH CONFIG TESTS
# ============================================================================

func test_boss_rush_scaling_config() -> void:
	# Test that Boss Rush scaling is loaded
	var hp_scaling = ConfigLoader.get_boss_rush_hp_scaling()
	var enemy_mult = ConfigLoader.get_boss_rush_enemy_multiplier()
	var speed_mult = ConfigLoader.get_boss_rush_speed_multiplier()

	assert_equal_float(hp_scaling, 1.13, 0.001, "Boss Rush HP scaling should be 1.13")
	assert_equal_float(enemy_mult, 5.0, 0.01, "Boss Rush enemy multiplier should be 5.0")
	assert_equal_float(speed_mult, 3.0, 0.01, "Boss Rush speed multiplier should be 3.0")

	log_info("Boss Rush: HP %.2f, Enemy %.1fx, Speed %.1fx" % [hp_scaling, enemy_mult, speed_mult])

func test_boss_rush_rewards_config() -> void:
	# Test that Boss Rush fragment rewards are loaded
	var rank_1 = ConfigLoader.get_boss_rush_fragment_reward(1)
	var rank_10 = ConfigLoader.get_boss_rush_fragment_reward(10)

	assert_equal(rank_1, 5000, "Rank 1 should give 5000 fragments")
	assert_equal(rank_10, 100, "Rank 10 should give 100 fragments")

	log_info("Boss Rush rewards: Rank 1: %d, Rank 10: %d fragments" % [rank_1, rank_10])

func test_boss_rush_schedule_config() -> void:
	# Test that Boss Rush schedule is loaded
	var schedule = ConfigLoader.get_boss_rush_schedule()

	assert_not_null(schedule, "Schedule should not be null")
	assert_true(schedule.has("days"), "Schedule should have days array")
	assert_equal(schedule["days"].size(), 3, "Should have 3 tournament days")
	assert_equal(schedule["utc_hour"], 0, "Should start at UTC hour 0")

	log_info("Boss Rush schedule: %s at %02d:00 UTC" % [str(schedule["days"]), schedule["utc_hour"]])

# ============================================================================
# SOFTWARE LAB CONFIG TESTS
# ============================================================================

func test_lab_config() -> void:
	# Test that software lab config is loaded
	var max_slots = ConfigLoader.get_lab_max_concurrent_slots()
	var tier_1_config = ConfigLoader.get_lab_tier_config(1)

	assert_equal(max_slots, 2, "Should have 2 concurrent lab slots")
	assert_equal(tier_1_config["max_level"], 100, "Tier 1 labs should have max level 100")
	assert_equal_float(tier_1_config["cost_scaling"], 1.08, 0.001, "Tier 1 cost scaling should be 1.08")

	log_info("Lab config: %d slots, Tier 1 max %d, scaling %.2f" % [max_slots, tier_1_config["max_level"], tier_1_config["cost_scaling"]])

# ============================================================================
# DRONE CONFIG TESTS
# ============================================================================

func test_drone_config() -> void:
	# Test that drone config is loaded
	var drone_types = ConfigLoader.get_drone_types()
	var max_level = ConfigLoader.get_drone_max_level()
	var base_cost = ConfigLoader.get_drone_base_upgrade_cost()

	assert_equal(drone_types.size(), 4, "Should have 4 drone types")
	assert_equal(max_level, 30, "Drones should have max level 30")
	assert_equal(base_cost, 2500, "Base drone cost should be 2500 fragments")

	log_info("Drones: %d types, max level %d, base cost %d" % [drone_types.size(), max_level, base_cost])

func test_drone_stats_config() -> void:
	# Test that individual drone stats are loaded
	var flame_stats = ConfigLoader.get_drone_stats("flame")

	assert_not_null(flame_stats, "Flame drone stats should exist")
	assert_true(flame_stats.has("fire_rate"), "Should have fire_rate stat")
	assert_true(flame_stats.has("range"), "Should have range stat")

	log_info("Flame drone stats loaded: fire_rate %.1f, range %d" % [flame_stats["fire_rate"], flame_stats["range"]])

# ============================================================================
# OFFLINE PROGRESS CONFIG TESTS
# ============================================================================

func test_offline_config() -> void:
	# Test that offline progress config is loaded
	var base_eff = ConfigLoader.get_offline_base_efficiency()
	var ad_eff = ConfigLoader.get_offline_ad_efficiency()
	var max_hours = ConfigLoader.get_offline_max_duration_hours()

	assert_equal_float(base_eff, 0.25, 0.001, "Base offline efficiency should be 25%")
	assert_equal_float(ad_eff, 0.50, 0.001, "Ad offline efficiency should be 50%")
	assert_equal(max_hours, 24, "Max offline duration should be 24 hours")

	log_info("Offline: %.0f%% base, %.0f%% ad, %dh max" % [base_eff * 100, ad_eff * 100, max_hours])

# ============================================================================
# FRAGMENT CONFIG TESTS
# ============================================================================

func test_fragment_config() -> void:
	# Test that fragment config is loaded
	var boss_base = ConfigLoader.get_boss_kill_base_fragments()
	var rush_participation = ConfigLoader.get_boss_rush_participation_fragments()

	assert_equal(boss_base, 10, "Boss kill base should be 10 fragments")
	assert_equal(rush_participation, 100, "Boss Rush participation should give 100 fragments")

	log_info("Fragments: %d per boss, %d for participation" % [boss_base, rush_participation])

# ============================================================================
# ENEMY TYPE CONFIG TESTS
# ============================================================================

func test_enemy_config() -> void:
	# Test that enemy configs are loaded
	var breacher = ConfigLoader.get_enemy_config("Breacher")
	var override = ConfigLoader.get_enemy_config("Override")

	assert_not_null(breacher, "Breacher config should exist")
	assert_not_null(override, "Override config should exist")

	assert_equal(breacher["base_hp"], 100, "Breacher should have 100 HP")
	assert_equal(override["base_hp"], 1000, "Override should have 1000 HP")

	log_info("Enemy HP: Breacher %d, Override %d" % [breacher["base_hp"], override["base_hp"]])

func test_all_enemy_types_loaded() -> void:
	# Test that all enemy types are present
	var enemy_types = ConfigLoader.get_all_enemy_types()

	assert_greater_equal(enemy_types.size(), 6, "Should have at least 6 enemy types")

	log_info("Loaded %d enemy types: %s" % [enemy_types.size(), str(enemy_types)])

# ============================================================================
# WAVE PROGRESSION CONFIG TESTS
# ============================================================================

func test_wave_progression_config() -> void:
	# Test that wave progression config is loaded
	var hp_scaling = ConfigLoader.get_base_hp_scaling()
	var enemies_base = ConfigLoader.get_enemies_per_wave_base()
	var enemies_growth = ConfigLoader.get_enemies_per_wave_growth()
	var boss_interval = ConfigLoader.get_boss_wave_interval()

	assert_equal_float(hp_scaling, 1.02, 0.001, "HP scaling should be 1.02 (2% per wave)")
	assert_equal(enemies_base, 10, "Base enemies per wave should be 10")
	assert_equal_float(enemies_growth, 1.05, 0.001, "Enemy count growth should be 1.05")
	assert_equal(boss_interval, 10, "Boss wave interval should be 10")

	log_info("Wave progression: HP %.2f, base %d enemies, growth %.2f, boss every %d" % [
		hp_scaling, enemies_base, enemies_growth, boss_interval
	])

# ============================================================================
# CONSTANTS CONFIG TESTS
# ============================================================================

func test_constants_config() -> void:
	# Test that game constants are loaded
	var base_fire_rate = ConfigLoader.get_constant("base_fire_rate", 0.0)
	var base_shield = ConfigLoader.get_constant("base_shield", 0)
	var tower_range = ConfigLoader.get_constant("tower_range", 0)

	assert_equal_float(base_fire_rate, 1.0, 0.01, "Base fire rate should be 1.0")
	assert_equal(base_shield, 100, "Base shield should be 100")
	assert_equal(tower_range, 400, "Tower range should be 400")

	log_info("Constants: fire rate %.1f, shield %d, range %d" % [base_fire_rate, base_shield, tower_range])

# ============================================================================
# SAVE SYSTEM CONFIG TESTS
# ============================================================================

func test_save_config() -> void:
	# Test that save system config is loaded
	var save_config = ConfigLoader.get_save_config()

	assert_not_null(save_config, "Save config should exist")
	assert_equal(save_config["backup_count"], 3, "Should have 3 backups")
	assert_equal(save_config["autosave_interval_seconds"], 10, "Autosave every 10 seconds")
	assert_true(save_config["cloud_sync_on_save"], "Cloud sync should be enabled")

	log_info("Save config: %d backups, %ds interval, cloud sync: %s" % [
		save_config["backup_count"],
		save_config["autosave_interval_seconds"],
		"enabled" if save_config["cloud_sync_on_save"] else "disabled"
	])

# ============================================================================
# CONFIG RELOAD TESTS
# ============================================================================

func test_config_reload() -> void:
	# Test that config can be reloaded
	var success = ConfigLoader.reload_config()

	assert_true(success, "Config reload should succeed")
	assert_true(ConfigLoader.loaded, "Config should still be loaded after reload")

	log_info("Config reload successful")

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

func assert_greater_equal(actual, expected, message: String = "") -> bool:
	if actual >= expected:
		_log_pass(message if message else "%s >= %s" % [str(actual), str(expected)])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s >= %s" % [str(actual), str(expected)])
		tests_failed += 1
		return false
