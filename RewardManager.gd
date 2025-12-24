extends Node

# --- Currency ---
var data_credits: int = 100000
var archive_tokens: int = 100000
var fragments: int = 0  # For drone upgrades

# --- Permanent Upgrades (all are managed here now) ---
var perm_projectile_damage: int = 0
var perm_projectile_fire_rate: float = 0.0
var perm_crit_chance: int = 0
var perm_crit_damage: float = 0.0

var perm_shield_integrity: int = 0
var perm_damage_reduction: float = 0.0
var perm_shield_regen: float = 0.0

var perm_data_credit_multiplier: float = 0.0
var perm_archive_token_multiplier: float = 0.0
var perm_wave_skip_chance: float = 0.0
var perm_free_upgrade_chance: float = 0.0

var perm_drone_flame_level: int = 0
var perm_drone_frost_level: int = 0
var perm_drone_poison_level: int = 0
var perm_drone_shock_level: int = 0

var perm_multi_target_unlocked: bool = false

# --- Multipliers (can be modified via upgrades) ---
@export var dc_multiplier: float = 1.0
@export var at_multiplier: float = 1.0

signal archive_tokens_changed

@onready var UpgradeManager = get_node("UpgradeManager")

func _ready() -> void:
	get_tree().connect("tree_exiting", Callable(self, "save_permanent_upgrades"))


# === Reward Functions ===
func add_archive_tokens(amount: int) -> void:
	archive_tokens += amount
	emit_signal("archive_tokens_changed")

func add_fragments(amount: int) -> void:
	fragments += amount

# === Flat Reward Lookup ===
func get_dc_reward_for_enemy(enemy_type: String) -> int:
	match enemy_type:
		"breacher":
			return 1
		"slicer":
			return 2
		"sentinel":
			return 10
		"signal_runner":
			return 8
		"nullwalker":
			return 6
		"override":
			return 100
		_:
			return 1

func get_at_reward_for_enemy(enemy_type: String) -> int:
	match enemy_type:
		"breacher": return 1
		"slicer": return 2
		"sentinel": return 6
		"signal_runner": return 8
		"nullwalker": return 10
		"override": return 100
		_: return 1

func get_data_credit_multiplier() -> float:
	return 1.0 + perm_data_credit_multiplier # Or blend with in-run if you want

func get_archive_token_multiplier() -> float:
	return 1.0 + perm_archive_token_multiplier # Ditto

func reward_enemy_at(enemy_type: String, wave_number: int) -> void:
	var base_at = get_at_reward_for_enemy(enemy_type)
	var scaled_at = int(base_at * (1.0 + wave_number * 0.02) * get_archive_token_multiplier())
	archive_tokens += scaled_at
	RunStats.archive_tokens_earned += scaled_at
	emit_signal("archive_tokens_changed")
	#print("📦 AT from", enemy_type, "→", scaled_at, "→ Total:", archive_tokens)

func reward_enemy(enemy_type: String, wave_number: int) -> void:
	var base_dc = get_dc_reward_for_enemy(enemy_type)
	var scaled_dc = int(base_dc * (1.0 + wave_number * 0.02) * get_data_credit_multiplier())
	data_credits += scaled_dc
	RunStats.data_credits_earned += scaled_dc
	#print("🪙 DC from", enemy_type, "→", scaled_dc, "→ Total:", data_credits)

func get_wave_at_reward(wave_number: int) -> int:
	var base = floor(0.25 * pow(wave_number, 1.15))
	return int(base * at_multiplier)

func add_wave_at(wave_number: int) -> void:
	var reward = get_wave_at_reward(wave_number)
	archive_tokens += reward
	emit_signal("archive_tokens_changed")
	#print("📦 AT earned from wave", wave_number, "→", reward, "→ Total:", archive_tokens)

# === Multiplier Setters ===
func set_dc_multiplier(multiplier: float) -> void:
	dc_multiplier = multiplier

func set_at_multiplier(multiplier: float) -> void:
	at_multiplier = multiplier

func reset_multipliers() -> void:
	dc_multiplier = 1.0
	at_multiplier = 1.0

# === Reset Everything ===
func reset_rewards() -> void:
	data_credits = 0
	archive_tokens = 0
	fragments = 0
	print("🔄 Rewards reset")

# === PERSISTENCE: Save/Load All Permanent Upgrades and Currency ===
func save_permanent_upgrades():
	var data = {
		"perm_projectile_damage": perm_projectile_damage,
		"perm_projectile_fire_rate": perm_projectile_fire_rate,
		"perm_crit_chance": perm_crit_chance,
		"perm_crit_damage": perm_crit_damage,
		"perm_shield_integrity": perm_shield_integrity,
		"perm_damage_reduction": perm_damage_reduction,
		"perm_shield_regen": perm_shield_regen,
		"perm_data_credit_multiplier": perm_data_credit_multiplier,
		"perm_archive_token_multiplier": perm_archive_token_multiplier,
		"perm_wave_skip_chance": perm_wave_skip_chance,
		"perm_free_upgrade_chance": perm_free_upgrade_chance,
		"perm_drone_flame_level": perm_drone_flame_level,
		"perm_drone_frost_level": perm_drone_frost_level,
		"perm_drone_poison_level": perm_drone_poison_level,
		"perm_drone_shock_level": perm_drone_shock_level,
		"perm_multi_target_unlocked": perm_multi_target_unlocked,
		"archive_tokens": archive_tokens,
		"fragments": fragments,
	}
	var file = FileAccess.open("user://perm_upgrades.save", FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return
	file.store_var(data)
	file.close()
	print("💾 Permanent upgrades saved.")

func load_permanent_upgrades():
	if not FileAccess.file_exists("user://perm_upgrades.save"):
		print("No permanent upgrades save found.")
		return

	var file = FileAccess.open("user://perm_upgrades.save", FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: " + str(FileAccess.get_open_error()))
		return

	var data = file.get_var()
	file.close()

	# Validate data is a dictionary
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file corrupted: Invalid data type")
		return

	# Load with validation (clamp to reasonable ranges)
	perm_projectile_damage = clamp(data.get("perm_projectile_damage", 0), 0, 100000)
	perm_projectile_fire_rate = clamp(data.get("perm_projectile_fire_rate", 0.0), 0.0, 1000.0)
	perm_crit_chance = clamp(data.get("perm_crit_chance", 0), 0, 100000)
	perm_crit_damage = clamp(data.get("perm_crit_damage", 0.0), 0.0, 1000.0)
	perm_shield_integrity = clamp(data.get("perm_shield_integrity", 0), 0, 100000)
	perm_damage_reduction = clamp(data.get("perm_damage_reduction", 0.0), 0.0, 1000.0)
	perm_shield_regen = clamp(data.get("perm_shield_regen", 0.0), 0.0, 1000.0)
	perm_data_credit_multiplier = clamp(data.get("perm_data_credit_multiplier", 0.0), 0.0, 1000.0)
	perm_archive_token_multiplier = clamp(data.get("perm_archive_token_multiplier", 0.0), 0.0, 1000.0)
	perm_wave_skip_chance = clamp(data.get("perm_wave_skip_chance", 0.0), 0.0, 100.0)
	perm_free_upgrade_chance = clamp(data.get("perm_free_upgrade_chance", 0.0), 0.0, 100.0)
	perm_multi_target_unlocked = data.get("perm_multi_target_unlocked", false)
	perm_drone_flame_level = clamp(data.get("perm_drone_flame_level", 0), 0, 10000)
	perm_drone_frost_level = clamp(data.get("perm_drone_frost_level", 0), 0, 10000)
	perm_drone_poison_level = clamp(data.get("perm_drone_poison_level", 0), 0, 10000)
	perm_drone_shock_level = clamp(data.get("perm_drone_shock_level", 0), 0, 10000)
	archive_tokens = clamp(data.get("archive_tokens", 0), 0, 999999999)
	fragments = clamp(data.get("fragments", 0), 0, 999999999)

	print("🔄 Permanent upgrades loaded.")
