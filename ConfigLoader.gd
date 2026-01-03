extends Node

# Game Balance Configuration Loader
# Loads balance values from config/game_balance.json
# Loads PlayFab configuration from config/playfab_config.json
# This allows tuning the game without modifying code

var config: Dictionary = {}
var loaded: bool = false

var playfab_config: Dictionary = {}
var playfab_loaded: bool = false

const CONFIG_PATH := "res://config/game_balance.json"
const PLAYFAB_CONFIG_PATH := "res://config/playfab_config.json"

func _ready() -> void:
	load_config()
	load_playfab_config()

func load_config() -> bool:
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)

	if not file:
		push_error("❌ Failed to load game balance config from: %s" % CONFIG_PATH)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("❌ Failed to parse game balance JSON: %s" % json.get_error_message())
		return false

	# BUG-014 fix: Validate that parsed JSON is a dictionary
	if not json.data is Dictionary:
		push_error("❌ Game balance JSON must be a dictionary, got: %s" % type_string(typeof(json.data)))
		return false

	config = json.data
	loaded = true
	print("✅ Game balance configuration loaded")
	return true

# === PERMANENT UPGRADES ===
func get_perm_upgrade_cost_scaling() -> float:
	return config.get("permanent_upgrades", {}).get("cost_scaling", 1.13)

func get_perm_upgrade_base_cost(upgrade_key: String) -> int:
	var base_costs = config.get("permanent_upgrades", {}).get("base_costs", {})
	return base_costs.get(upgrade_key, 5000)

func get_perm_upgrade_cost_increment(upgrade_key: String) -> int:
	var increments = config.get("permanent_upgrades", {}).get("cost_increments", {})
	return increments.get(upgrade_key, 250)

# === IN-RUN UPGRADES ===
func get_in_run_cost_scaling() -> float:
	return config.get("in_run_upgrades", {}).get("cost_scaling", 1.15)

func get_in_run_base_cost(upgrade_key: String) -> int:
	var base_costs = config.get("in_run_upgrades", {}).get("base_costs", {})
	return base_costs.get(upgrade_key, 50)

func get_in_run_per_level_bonus(upgrade_key: String) -> float:
	var bonuses = config.get("in_run_upgrades", {}).get("per_level_bonuses", {})
	return bonuses.get(upgrade_key, 1.0)

func get_in_run_cap(upgrade_key: String) -> int:
	var caps = config.get("in_run_upgrades", {}).get("caps", {})
	return caps.get(upgrade_key, 100)

func get_damage_milestone_scaling() -> Dictionary:
	return config.get("in_run_upgrades", {}).get("damage_milestone_scaling", {
		"levels_per_milestone": 100,
		"multiplier_per_milestone": 1.5,
		"max_milestones": 200
	})

# === CURRENCY REWARDS ===
func get_wave_scaling_percent() -> float:
	return config.get("currency_rewards", {}).get("wave_scaling_percent", 0.02)

func get_wave_at_bonus_coefficient() -> float:
	var wave_at = config.get("currency_rewards", {}).get("wave_at_bonus", {})
	return wave_at.get("coefficient", 0.25)

func get_wave_at_bonus_exponent() -> float:
	var wave_at = config.get("currency_rewards", {}).get("wave_at_bonus", {})
	return wave_at.get("exponent", 1.15)

func get_enemy_base_dc(enemy_type: String) -> int:
	var enemy_dc = config.get("currency_rewards", {}).get("enemy_base_dc", {})
	return enemy_dc.get(enemy_type, 10)

func get_enemy_base_at(enemy_type: String) -> int:
	var enemy_at = config.get("currency_rewards", {}).get("enemy_base_at", {})
	return enemy_at.get(enemy_type, 1)

func get_lucky_drops_multiplier() -> float:
	return config.get("currency_rewards", {}).get("lucky_drops_multiplier", 1.5)

# === TIER SYSTEM ===
func get_total_tiers() -> int:
	return config.get("tier_system", {}).get("total_tiers", 10)

func get_waves_per_tier() -> int:
	return config.get("tier_system", {}).get("waves_per_tier", 5000)

func get_tier_reward_multiplier_base() -> int:
	return config.get("tier_system", {}).get("reward_multiplier_base", 5)

# === BOSS RUSH ===
func get_boss_rush_hp_scaling() -> float:
	return config.get("boss_rush", {}).get("hp_scaling_base", 1.13)

func get_boss_rush_enemy_multiplier() -> float:
	return config.get("boss_rush", {}).get("enemy_multiplier", 5.0)

func get_boss_rush_speed_multiplier() -> float:
	return config.get("boss_rush", {}).get("speed_multiplier", 3.0)

func get_boss_rush_fragment_reward(rank: int) -> int:
	var rewards = config.get("boss_rush", {}).get("fragment_rewards", {})
	return rewards.get("rank_%d" % rank, 0)

func get_boss_rush_schedule() -> Dictionary:
	return config.get("boss_rush", {}).get("schedule", {
		"days": ["Monday", "Thursday", "Saturday"],
		"utc_hour": 0
	})

# === SOFTWARE LABS ===
func get_lab_max_concurrent_slots() -> int:
	return config.get("software_labs", {}).get("max_concurrent_slots", 2)

func get_lab_tier_config(tier: int) -> Dictionary:
	var tier_key = "tier_%d_labs" % tier
	return config.get("software_labs", {}).get(tier_key, {
		"max_level": 100,
		"cost_scaling": 1.08,
		"duration_scaling": 1.05
	})

func get_lab_acceleration_scaling() -> float:
	return config.get("software_labs", {}).get("lab_acceleration_scaling", 1.20)

# === DRONES ===
func get_drone_types() -> Array:
	return config.get("drones", {}).get("types", ["flame", "frost", "poison", "shock"])

func get_drone_max_level() -> int:
	return config.get("drones", {}).get("max_level", 30)

func get_drone_base_upgrade_cost() -> int:
	return config.get("drones", {}).get("base_upgrade_cost", 2500)

func get_drone_cost_increment() -> int:
	return config.get("drones", {}).get("cost_increment_per_level", 1000)

func get_drone_stats(drone_type: String) -> Dictionary:
	var base_stats = config.get("drones", {}).get("base_stats", {})
	return base_stats.get(drone_type, {})

# === OFFLINE PROGRESS ===
func get_offline_base_efficiency() -> float:
	return config.get("offline_progress", {}).get("base_efficiency", 0.25)

func get_offline_ad_efficiency() -> float:
	return config.get("offline_progress", {}).get("ad_efficiency", 0.50)

func get_offline_max_duration_hours() -> int:
	return config.get("offline_progress", {}).get("max_duration_hours", 24)

func get_offline_min_duration_minutes() -> int:
	return config.get("offline_progress", {}).get("min_duration_minutes", 1)

func get_offline_max_at_reward() -> int:
	return config.get("offline_progress", {}).get("max_at_reward", 1000000)

# === FRAGMENTS ===
func get_boss_kill_base_fragments() -> int:
	return config.get("fragments", {}).get("boss_kill_base", 10)

func get_boss_kill_wave_divisor() -> int:
	return config.get("fragments", {}).get("boss_kill_wave_divisor", 10)

func get_boss_rush_participation_fragments() -> int:
	return config.get("fragments", {}).get("boss_rush_participation", 100)

# === ENEMY TYPES ===
func get_enemy_config(enemy_type: String) -> Dictionary:
	var enemy_types = config.get("enemy_types", {})
	return enemy_types.get(enemy_type, {})

func get_all_enemy_types() -> Array:
	return config.get("enemy_types", {}).keys()

# === WAVE PROGRESSION ===
func get_base_hp_scaling() -> float:
	return config.get("wave_progression", {}).get("base_hp_scaling", 1.02)

func get_enemies_per_wave_base() -> int:
	return config.get("wave_progression", {}).get("enemies_per_wave_base", 10)

func get_enemies_per_wave_growth() -> float:
	return config.get("wave_progression", {}).get("enemies_per_wave_growth", 1.05)

func get_boss_wave_interval() -> int:
	return config.get("wave_progression", {}).get("boss_wave_interval", 10)

# === CONSTANTS ===
func get_constant(key: String, default_value = null):
	var constants = config.get("constants", {})
	return constants.get(key, default_value)

# === SAVE SYSTEM ===
func get_save_config() -> Dictionary:
	return config.get("save_system", {
		"backup_count": 3,
		"autosave_interval_seconds": 10,
		"cloud_sync_on_save": true
	})

# === UTILITY ===
func reload_config() -> bool:
	return load_config()

func get_raw_config() -> Dictionary:
	return config

func print_config() -> void:
	print("📋 Game Balance Configuration:")
	print(JSON.stringify(config, "  "))

# === PLAYFAB CONFIGURATION ===
func load_playfab_config() -> bool:
	var file = FileAccess.open(PLAYFAB_CONFIG_PATH, FileAccess.READ)

	if not file:
		push_warning("⚠️ PlayFab config not found at: %s (using defaults)" % PLAYFAB_CONFIG_PATH)
		# Use fallback defaults
		playfab_config = {
			"title_id": "1DEAD6",
			"api_url": "https://{{TITLE_ID}}.playfabapi.com"
		}
		playfab_loaded = false
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("❌ Failed to parse PlayFab config JSON: %s" % json.get_error_message())
		playfab_loaded = false
		return false

	if not json.data is Dictionary:
		push_error("❌ PlayFab config JSON must be a dictionary, got: %s" % type_string(typeof(json.data)))
		playfab_loaded = false
		return false

	playfab_config = json.data
	playfab_loaded = true
	print("✅ PlayFab configuration loaded (Title ID: %s)" % get_playfab_title_id())
	return true

func get_playfab_title_id() -> String:
	return playfab_config.get("title_id", "1DEAD6")

func get_playfab_api_url() -> String:
	var title_id = get_playfab_title_id()
	var url_template = playfab_config.get("api_url", "https://{{TITLE_ID}}.playfabapi.com")
	# Replace {{TITLE_ID}} placeholder with actual title ID
	return url_template.replace("{{TITLE_ID}}", title_id)

func is_playfab_config_loaded() -> bool:
	return playfab_loaded

