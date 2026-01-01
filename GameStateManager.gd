class_name GameStateManager
extends Node

# === GAME STATE MANAGEMENT SYSTEM ===
# Manages game state transitions and resets
# Extracted from main_hud.gd (Phase 3.1 Refactor - C7)
#
# Responsibilities:
# - Reset to wave 1 (tier transitions)
# - Start/exit boss rush mode
# - Quit to main menu
# - Coordinate state resets across multiple systems

# References to game systems (set externally)
var spawner: Node = null
var tower: Node = null
var main_hud: Control = null  # For wave_timer and panel references

signal state_reset_complete
signal boss_rush_started
signal returning_to_menu

## Resets game to wave 1 (called when entering new tier)
## Keeps permanent upgrades and AT/Fragments, resets DC
func reset_to_wave_1() -> void:
	print("🔄 Resetting to Wave 1 for new tier...")

	# 1. Reset in-run upgrades
	if Engine.has_singleton("UpgradeManager"):
		UpgradeManager.reset_run_upgrades()

	# 2. Reset run currency (keep AT/Fragments, reset DC)
	if Engine.has_singleton("RewardManager"):
		RewardManager.reset_run_currency()

	# 3. Reset wave and clear enemies
	_reset_wave_and_enemies()

	# 4. Reset the tower
	_reset_tower()

	# 5. Hide all upgrade panels
	_hide_all_panels()

	# 6. Start wave 1
	if main_hud:
		main_hud.wave_timer = 0.0
	if spawner:
		spawner.start_wave(1)
	if main_hud:
		main_hud.update_labels()

	# 7. Start tracking this run's performance
	if Engine.has_singleton("RewardManager"):
		RewardManager.start_run_tracking(1)

	print("✅ Reset complete! Starting Wave 1 in Tier %d" % TierManager.get_current_tier())
	state_reset_complete.emit()

## Starts boss rush mode
## Resets all state and begins boss rush tracking
func start_boss_rush() -> void:
	print("🏆 Starting Boss Rush mode...")

	if not BossRushManager.start_boss_rush():
		print("⚠️ Failed to start boss rush!")
		return

	# 1. Reset in-run upgrades
	if Engine.has_singleton("UpgradeManager"):
		UpgradeManager.reset_run_upgrades()

	# 2. Reset run currency
	if Engine.has_singleton("RewardManager"):
		RewardManager.reset_run_currency()

	# 3. Reset wave and clear enemies
	_reset_wave_and_enemies()

	# 4. Reset the tower
	_reset_tower()

	# 5. Hide all panels (including boss rush panel)
	_hide_all_panels(true)

	# 6. Reset RunStats for damage tracking
	RunStats.reset()

	# 7. Start wave 1
	if main_hud:
		main_hud.wave_timer = 0.0
	if spawner:
		spawner.start_wave(1)
	if main_hud:
		main_hud.update_labels()

	print("✅ Boss Rush started! Good luck!")
	boss_rush_started.emit()

## Exits boss rush mode
## Ends boss rush tracking and returns to main menu
func exit_boss_rush() -> void:
	print("🏆 Exiting Boss Rush mode...")

	# End boss rush in spawner (triggers leaderboard entry)
	if spawner and spawner.has_method("end_boss_rush"):
		spawner.end_boss_rush()

	# Return to start screen
	quit_to_menu()

## Quits current run and returns to main menu
## Saves progress and resets all state
func quit_to_menu() -> void:
	# Record run performance before quitting
	if Engine.has_singleton("RewardManager") and spawner:
		RewardManager.record_run_performance(spawner.current_wave)

	# 1. Reset in-run upgrades
	if Engine.has_singleton("UpgradeManager"):
		UpgradeManager.reset_run_upgrades()
		UpgradeManager.maybe_grant_free_upgrade()  # Optional

	# 2. Save permanent upgrades and reset currencies
	if Engine.has_singleton("RewardManager"):
		RewardManager.save_permanent_upgrades()
		RewardManager.reset_run_currency()

	# 3. Reset wave and clear enemies
	_reset_wave_and_enemies()

	# 4. Reset the tower
	_reset_tower()

	# 5. Hide all upgrade panels
	if main_hud:
		if main_hud.has_node("OffensePanel"):
			main_hud.get_node("OffensePanel").visible = false
		if main_hud.has_node("DefensePanel"):
			main_hud.get_node("DefensePanel").visible = false
		if main_hud.has_node("EconomyPanel"):
			main_hud.get_node("EconomyPanel").visible = false
		if main_hud.has_node("PermUpgradesPanel"):
			main_hud.get_node("PermUpgradesPanel").visible = false

	# 6. Print run stats
	print("=== RUN STATS ON DEATH ===")
	print("AT Earned: ", RunStats.archive_tokens_earned)
	print("DC Earned: ", RunStats.data_credits_earned)
	print("Damage Dealt: ", RunStats.damage_dealt)
	print("Damage Taken: ", RunStats.damage_taken)
	print("==========================")
	RunStats.reset()

	# 7. Return to the Start Screen
	returning_to_menu.emit()
	if main_hud:
		main_hud.get_tree().change_scene_to_file("res://StartScreen.tscn")

# === PRIVATE HELPER FUNCTIONS ===

func _reset_wave_and_enemies() -> void:
	if not spawner:
		return

	# Reset wave timers
	if spawner.has_method("reset_wave_timers"):
		spawner.reset_wave_timers()

	# Reset spawner state
	spawner.wave_spawning = false
	spawner.current_wave = 1
	spawner.enemies_to_spawn = 0
	spawner.spawned_enemies = 0

	# Remove all enemy nodes
	for enemy in spawner.get_children():
		if is_instance_valid(enemy) and enemy.is_in_group("enemies"):
			enemy.queue_free()

func _reset_tower() -> void:
	if not tower:
		return

	tower.tower_hp = 1000
	tower.refresh_shield_stats()
	tower.current_shield = tower.max_shield
	tower.update_bars()

func _hide_all_panels(include_boss_rush: bool = false) -> void:
	if not main_hud:
		return

	# Hide in-run upgrade panels
	if main_hud.get("offense_panel"):
		main_hud.offense_panel.visible = false
	if main_hud.get("defense_panel"):
		main_hud.defense_panel.visible = false
	if main_hud.get("economy_panel"):
		main_hud.economy_panel.visible = false
	if main_hud.get("perm_panel"):
		main_hud.perm_panel.visible = false

	# Hide progression panels
	if main_hud.get("software_upgrade_panel") and main_hud.software_upgrade_panel:
		main_hud.software_upgrade_panel.visible = false
	if main_hud.get("tier_selection_panel") and main_hud.tier_selection_panel:
		main_hud.tier_selection_panel.visible = false

	# Optionally hide boss rush panel
	if include_boss_rush:
		if main_hud.get("boss_rush_panel") and main_hud.boss_rush_panel:
			main_hud.boss_rush_panel.visible = false
