extends Node

# Per-run stats (reset each run)
# Damage dealt stored as BigNumber (mantissa + exponent) for infinite scaling precision
var damage_dealt_mantissa: float = 0.0
var damage_dealt_exponent: int = 0
var damage_taken: int = 0
var data_credits_earned: int = 0
var archive_tokens_earned: int = 0
var current_wave: int = 1

# Legacy damage_dealt for backward compatibility (deprecated - use get_damage_dealt_bn())
var damage_dealt: float:
	get:
		return get_damage_dealt_bn().to_float()
	set(value):
		var bn = BigNumber.new(value)
		damage_dealt_mantissa = bn.mantissa
		damage_dealt_exponent = bn.exponent

# Lifetime stats (persist across all runs)
var lifetime_dc_earned: int = 0
var lifetime_at_earned: int = 0
var lifetime_fragments_earned: int = 0
var lifetime_at_spent_labs: int = 0
var lifetime_at_spent_perm_upgrades: int = 0

# Enemy kill counts (persist across all runs)
var lifetime_kills: Dictionary = {
	"breacher": 0,
	"slicer": 0,
	"sentinel": 0,
	"signal_runner": 0,
	"nullwalker": 0,
	"override": 0,
}

func reset():
	# Reset per-run stats only
	damage_dealt_mantissa = 0.0
	damage_dealt_exponent = 0
	damage_taken = 0
	data_credits_earned = 0
	archive_tokens_earned = 0
	current_wave = 1

	# Clear enemy tracker for new run
	EnemyTracker.clear()

# BigNumber helper functions for damage_dealt
func get_damage_dealt_bn() -> BigNumber:
	return BigNumber.new(damage_dealt_mantissa, damage_dealt_exponent)

func set_damage_dealt_bn(bn: BigNumber) -> void:
	damage_dealt_mantissa = bn.mantissa
	damage_dealt_exponent = bn.exponent

func add_damage_dealt(amount: float) -> void:
	var current = get_damage_dealt_bn()
	current.add(BigNumber.new(amount))
	set_damage_dealt_bn(current)

func add_damage_dealt_bn(bn: BigNumber) -> void:
	var current = get_damage_dealt_bn()
	current.add(bn)
	set_damage_dealt_bn(current)

func add_dc_earned(amount: int) -> void:
	data_credits_earned += amount
	lifetime_dc_earned += amount

func add_at_earned(amount: int) -> void:
	archive_tokens_earned += amount
	lifetime_at_earned += amount

func add_fragments_earned(amount: int) -> void:
	lifetime_fragments_earned += amount

func add_at_spent_lab(amount: int) -> void:
	lifetime_at_spent_labs += amount

func add_at_spent_perm_upgrade(amount: int) -> void:
	lifetime_at_spent_perm_upgrades += amount

func record_kill(enemy_type: String) -> void:
	if lifetime_kills.has(enemy_type):
		lifetime_kills[enemy_type] += 1

	# Track for achievements
	if AchievementManager:
		AchievementManager.add_enemies_killed(1)
		# Boss type is "override"
		if enemy_type == "override":
			AchievementManager.add_boss_killed()
