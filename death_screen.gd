# death_screen.gd

extends CanvasLayer

@onready var restart_button = $RestartButton

func show_death():
	visible = true
	get_tree().paused = true
	print("=== RUN STATS ON DEATH ===")
	print("AT Earned: ", RunStats.archive_tokens_earned)
	print("DC Earned: ", RunStats.data_credits_earned)
	print("Damage Dealt: ", RunStats.damage_dealt)
	print("Damage Taken: ", RunStats.damage_taken)
	print("==========================")	

func _on_restart_button_pressed():
	print("Restart button pressed!")
	get_tree().paused = false
	visible = false
	
	var root = get_tree().current_scene

	var perm_upgrades_panel = root.get_node_or_null("PermUpgradesPanel")
	if perm_upgrades_panel:
		perm_upgrades_panel.visible = false

	var offense_panel = root.get_node_or_null("OffensePanel")
	if offense_panel:
		offense_panel.visible = false

	var defense_panel = root.get_node_or_null("DefensePanel")
	if defense_panel:
		defense_panel.visible = false

	var economy_panel = root.get_node_or_null("EconomyPanel")
	if economy_panel:
		economy_panel.visible = false

	# Reset currencies
	RewardManager.reset_run_currency()
	RewardManager.save_permanent_upgrades()

	# Reset in-run upgrades and state
	UpgradeManager.reset_run_upgrades()
	UpgradeManager.maybe_grant_free_upgrade()

	# Remove all enemies from scene
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	# Reset wave counters in spawner
	var spawner = get_tree().current_scene.get_node_or_null("Spawner")
	if spawner and spawner.has_method("reset"):
		spawner.reset()
		spawner.start_wave(1)

	# Reset the tower
	var tower = get_tree().current_scene.get_node_or_null("tower")
	if tower:
		tower.tower_hp = 1000
		tower.refresh_shield_stats()
		tower.current_shield = tower.max_shield
		tower.update_bars()

	# Reset UI
	var main_hud = get_tree().current_scene
	if main_hud.has_method("update_labels"):
		main_hud.update_labels()
