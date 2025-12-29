extends Node

# Per-run stats (reset each run)
var damage_dealt: int = 0
var damage_taken: int = 0
var data_credits_earned: int = 0
var archive_tokens_earned: int = 0
var current_wave: int = 1

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
	damage_dealt = 0
	damage_taken = 0
	data_credits_earned = 0
	archive_tokens_earned = 0
	current_wave = 1

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
		# Check if this is a boss kill (assuming boss types contain "boss" in name)
		if "boss" in enemy_type.to_lower():
			AchievementManager.add_boss_killed()
