extends Control

# Boss Rush UI - Tournament mode with leaderboards

# UI Nodes
var panel: Panel
var title_label: Label
var info_text: RichTextLabel
var start_button: Button
var exit_button: Button
var clear_leaderboard_button: Button
var leaderboard_scroll: ScrollContainer
var leaderboard_list: VBoxContainer
var close_button: Button

func _ready() -> void:
	_create_ui()

	# Connect signals
	if BossRushManager:
		BossRushManager.boss_rush_started.connect(_on_boss_rush_started)
		BossRushManager.boss_rush_ended.connect(_on_boss_rush_ended)
		BossRushManager.leaderboard_updated.connect(_refresh_leaderboard)

	# Initial refresh
	_refresh_leaderboard()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 750)
	panel.position = Vector2(15, 50)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🏆 BOSS RUSH"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Info text (rules)
	info_text = RichTextLabel.new()
	info_text.position = Vector2(20, 55)
	info_text.custom_minimum_size = Vector2(320, 140)
	info_text.bbcode_enabled = true
	info_text.fit_content = true
	info_text.scroll_active = false
	info_text.text = """[b]RULES:[/b]
• Every wave spawns only BOSSES
• Wave 1-9: 1 boss
• Wave 10-19: 2 bosses
• +1 boss every 10 waves (max 10)
• Wave 100: Final challenge!
• Faster scaling than normal tiers
• Ranked by DAMAGE DEALT
"""
	panel.add_child(info_text)

	# Start button
	start_button = Button.new()
	start_button.text = "🎮 START BOSS RUSH"
	start_button.position = Vector2(20, 205)
	start_button.custom_minimum_size = Vector2(200, 45)
	start_button.pressed.connect(_on_start_pressed)
	panel.add_child(start_button)

	# Exit button (only visible during boss rush)
	exit_button = Button.new()
	exit_button.text = "🚪 Exit Boss Rush"
	exit_button.position = Vector2(230, 205)
	exit_button.custom_minimum_size = Vector2(110, 45)
	exit_button.pressed.connect(_on_exit_pressed)
	exit_button.visible = false
	panel.add_child(exit_button)

	# Leaderboard title
	var leaderboard_title = Label.new()
	leaderboard_title.text = "📊 LEADERBOARD - Top 10"
	leaderboard_title.position = Vector2(20, 260)
	leaderboard_title.add_theme_font_size_override("font_size", 16)
	leaderboard_title.custom_minimum_size = Vector2(320, 25)
	leaderboard_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(leaderboard_title)

	# Clear leaderboard button
	clear_leaderboard_button = Button.new()
	clear_leaderboard_button.text = "🗑️ Clear"
	clear_leaderboard_button.position = Vector2(265, 290)
	clear_leaderboard_button.custom_minimum_size = Vector2(75, 30)
	clear_leaderboard_button.pressed.connect(_on_clear_leaderboard_pressed)
	panel.add_child(clear_leaderboard_button)

	# Leaderboard scroll container
	leaderboard_scroll = ScrollContainer.new()
	leaderboard_scroll.position = Vector2(20, 325)
	leaderboard_scroll.custom_minimum_size = Vector2(320, 370)
	panel.add_child(leaderboard_scroll)

	leaderboard_list = VBoxContainer.new()
	leaderboard_list.custom_minimum_size = Vector2(300, 0)
	leaderboard_scroll.add_child(leaderboard_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 705)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _refresh_leaderboard() -> void:
	if not BossRushManager:
		return

	# Clear existing entries
	for child in leaderboard_list.get_children():
		child.queue_free()

	var leaderboard = BossRushManager.get_leaderboard()

	if leaderboard.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No runs yet. Be the first!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(300, 30)
		leaderboard_list.add_child(empty_label)
		return

	# Create leaderboard entries
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		var rank = i + 1

		# Container for this entry
		var entry_container = PanelContainer.new()
		entry_container.custom_minimum_size = Vector2(300, 50)
		leaderboard_list.add_child(entry_container)

		var vbox = VBoxContainer.new()
		entry_container.add_child(vbox)

		# Rank + damage (primary)
		var top_line = HBoxContainer.new()
		vbox.add_child(top_line)

		var rank_label = Label.new()
		rank_label.text = "#%d" % rank
		rank_label.custom_minimum_size = Vector2(40, 20)
		rank_label.add_theme_font_size_override("font_size", 16)
		if rank == 1:
			rank_label.text = "🥇"
		elif rank == 2:
			rank_label.text = "🥈"
		elif rank == 3:
			rank_label.text = "🥉"
		top_line.add_child(rank_label)

		var damage_label = Label.new()
		damage_label.text = "%s damage" % BossRushManager.format_damage(entry["damage"])
		damage_label.custom_minimum_size = Vector2(180, 20)
		damage_label.add_theme_font_size_override("font_size", 14)
		top_line.add_child(damage_label)

		# Wave + tier (secondary)
		var bottom_line = Label.new()
		bottom_line.text = "  Wave %d | Tier %d" % [entry["waves"], entry["tier"]]
		bottom_line.add_theme_font_size_override("font_size", 11)
		bottom_line.custom_minimum_size = Vector2(280, 18)
		vbox.add_child(bottom_line)

func _on_start_pressed() -> void:
	if BossRushManager.is_boss_rush_active():
		print("⚠️ Boss Rush already active!")
		return

	# Hide this panel
	visible = false

	# Trigger boss rush start in main HUD
	var main_hud = get_parent()
	if main_hud and main_hud.has_method("start_boss_rush"):
		main_hud.start_boss_rush()
	else:
		print("⚠️ Could not find main_hud.start_boss_rush()")

func _on_exit_pressed() -> void:
	if not BossRushManager.is_boss_rush_active():
		return

	# Trigger boss rush exit in spawner
	var spawner = get_tree().current_scene.get_node_or_null("Spawner")
	if spawner and spawner.has_method("end_boss_rush"):
		spawner.end_boss_rush()

	# Return to main menu or normal mode
	var main_hud = get_parent()
	if main_hud and main_hud.has_method("exit_boss_rush"):
		main_hud.exit_boss_rush()

func _on_clear_leaderboard_pressed() -> void:
	BossRushManager.clear_leaderboard()

func _on_close_pressed() -> void:
	visible = false

func _on_boss_rush_started() -> void:
	start_button.visible = false
	exit_button.visible = true
	print("🏆 Boss Rush UI: Started")

func _on_boss_rush_ended(damage_dealt: int, waves_survived: int) -> void:
	start_button.visible = true
	exit_button.visible = false
	print("🏆 Boss Rush UI: Ended with %d damage, %d waves" % [damage_dealt, waves_survived])

	# Show results popup
	_show_results_popup(damage_dealt, waves_survived)

func _show_results_popup(damage: int, waves: int) -> void:
	# Create a simple results popup
	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(300, 200)
	popup.position = Vector2(45, 275)
	popup.z_index = 100
	add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	popup.add_child(vbox)

	var title = Label.new()
	title.text = "🏆 BOSS RUSH COMPLETE!"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(260, 30)
	vbox.add_child(title)

	var damage_label = Label.new()
	damage_label.text = "Damage Dealt: %s" % BossRushManager.format_damage(damage)
	damage_label.add_theme_font_size_override("font_size", 14)
	damage_label.custom_minimum_size = Vector2(260, 25)
	vbox.add_child(damage_label)

	var waves_label = Label.new()
	waves_label.text = "Waves Survived: %d" % waves
	waves_label.add_theme_font_size_override("font_size", 14)
	waves_label.custom_minimum_size = Vector2(260, 25)
	vbox.add_child(waves_label)

	var rank = BossRushManager.get_rank_for_damage(damage)
	var rank_label = Label.new()
	rank_label.text = "Rank: #%d" % rank
	rank_label.add_theme_font_size_override("font_size", 16)
	rank_label.custom_minimum_size = Vector2(260, 30)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rank_label)

	var ok_button = Button.new()
	ok_button.text = "OK"
	ok_button.custom_minimum_size = Vector2(100, 40)
	ok_button.pressed.connect(func(): popup.queue_free())
	vbox.add_child(ok_button)

	# Auto-close after 10 seconds
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(popup):
		popup.queue_free()

func _exit_tree() -> void:
	# Disconnect signals
	if BossRushManager:
		if BossRushManager.boss_rush_started.is_connected(Callable(self, "_on_boss_rush_started")):
			BossRushManager.boss_rush_started.disconnect(Callable(self, "_on_boss_rush_started"))
		if BossRushManager.boss_rush_ended.is_connected(Callable(self, "_on_boss_rush_ended")):
			BossRushManager.boss_rush_ended.disconnect(Callable(self, "_on_boss_rush_ended"))
		if BossRushManager.leaderboard_updated.is_connected(Callable(self, "_refresh_leaderboard")):
			BossRushManager.leaderboard_updated.disconnect(Callable(self, "_refresh_leaderboard"))
