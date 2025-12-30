extends Control

# Subroutine Defense - Enhanced Start Screen
# Inspired by The Tower's polished main menu design

# === UI NODES ===

# Top Currency Display
var currency_panel: Panel
var dc_label: Label
var at_label: Label
var fragments_label: Label
var qc_label: Label
var tier_wave_label: Label

# Center Title & Tier Selection
var title_label: Label
var title_border: Panel
var tier_selector_panel: Panel
var tier_left_button: Button
var tier_right_button: Button
var tier_label: Label
var highest_wave_label: Label
var dc_multiplier_label: Label

# Left Side Buttons
var left_button_container: VBoxContainer
var daily_reward_button: Button
var daily_reward_timer_label: Label
var tournament_button: Button
var tournament_timer_label: Label
var milestone_progress_button: Button

# Right Side Buttons
var right_button_container: VBoxContainer
var settings_button: Button
var labs_button: Button
var achievements_button: Button
var stats_button: Button
var shop_button: Button

# Main Action Button
var start_battle_button: Button

# Bottom Navigation
var bottom_nav_container: HBoxContainer
var drones_nav_button: Button
var perms_nav_button: Button
var data_disks_nav_button: Button
var tiers_nav_button: Button

# Overlays
var login_ui: Control = null
var overlay_panel: Control = null

# === INITIALIZATION ===

func _ready() -> void:
	_create_ui()
	_connect_signals()
	_update_display()

	# Show login if needed
	if CloudSaveManager and not CloudSaveManager.is_logged_in:
		_show_login_screen()

	# Update timer displays every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_timers)
	timer.autostart = true
	add_child(timer)

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

# === UI CREATION ===

func _create_ui() -> void:
	# Background (matrix effect or solid color)
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)  # Dark blue-purple
	bg.size = Vector2(390, 844)
	add_child(bg)

	_create_top_currency_display()
	_create_center_title_section()
	_create_tier_selector()
	_create_left_side_buttons()
	_create_right_side_buttons()
	_create_start_battle_button()
	_create_bottom_navigation()

func _create_top_currency_display() -> void:
	# Top banner with all currencies (y=0-90)
	currency_panel = Panel.new()
	currency_panel.position = Vector2(5, 5)
	currency_panel.custom_minimum_size = Vector2(380, 85)
	add_child(currency_panel)

	# DC (Data Credits)
	dc_label = Label.new()
	dc_label.text = "💾 0"
	dc_label.position = Vector2(10, 10)
	dc_label.add_theme_font_size_override("font_size", 14)
	currency_panel.add_child(dc_label)

	# AT (Archive Tokens)
	at_label = Label.new()
	at_label.text = "📦 0"
	at_label.position = Vector2(10, 30)
	at_label.add_theme_font_size_override("font_size", 14)
	currency_panel.add_child(at_label)

	# Fragments
	fragments_label = Label.new()
	fragments_label.text = "💎 0"
	fragments_label.position = Vector2(10, 50)
	fragments_label.add_theme_font_size_override("font_size", 14)
	currency_panel.add_child(fragments_label)

	# QC (Quantum Cores) - top right
	qc_label = Label.new()
	qc_label.text = "🔮 0"
	qc_label.position = Vector2(200, 10)
	qc_label.add_theme_font_size_override("font_size", 16)
	currency_panel.add_child(qc_label)

	# Tier/Wave - top right
	tier_wave_label = Label.new()
	tier_wave_label.text = "Tier 1 • Wave 1"
	tier_wave_label.position = Vector2(200, 35)
	tier_wave_label.add_theme_font_size_override("font_size", 12)
	currency_panel.add_child(tier_wave_label)

func _create_center_title_section() -> void:
	# Game title with animated border (y=200-300)
	title_border = Panel.new()
	title_border.position = Vector2(20, 200)
	title_border.custom_minimum_size = Vector2(350, 80)
	add_child(title_border)

	title_label = Label.new()
	title_label.text = "SUBROUTINE DEFENSE"
	title_label.position = Vector2(10, 25)
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(330, 30)
	title_border.add_child(title_label)

func _create_tier_selector() -> void:
	# Tier selection with arrows (y=300-450)
	tier_selector_panel = Panel.new()
	tier_selector_panel.position = Vector2(40, 300)
	tier_selector_panel.custom_minimum_size = Vector2(310, 140)
	add_child(tier_selector_panel)

	# Title
	var difficulty_label = Label.new()
	difficulty_label.text = "Difficulty"
	difficulty_label.position = Vector2(100, 10)
	difficulty_label.add_theme_font_size_override("font_size", 16)
	tier_selector_panel.add_child(difficulty_label)

	# Left arrow
	tier_left_button = Button.new()
	tier_left_button.text = "◀"
	tier_left_button.position = Vector2(20, 40)
	tier_left_button.custom_minimum_size = Vector2(50, 50)
	tier_selector_panel.add_child(tier_left_button)

	# Tier display
	tier_label = Label.new()
	tier_label.text = "Tier 1"
	tier_label.position = Vector2(80, 45)
	tier_label.add_theme_font_size_override("font_size", 24)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.custom_minimum_size = Vector2(150, 40)
	tier_selector_panel.add_child(tier_label)

	# Right arrow
	tier_right_button = Button.new()
	tier_right_button.text = "▶"
	tier_right_button.position = Vector2(240, 40)
	tier_right_button.custom_minimum_size = Vector2(50, 50)
	tier_selector_panel.add_child(tier_right_button)

	# Highest wave
	highest_wave_label = Label.new()
	highest_wave_label.text = "Highest Wave: 1"
	highest_wave_label.position = Vector2(60, 100)
	highest_wave_label.add_theme_font_size_override("font_size", 14)
	tier_selector_panel.add_child(highest_wave_label)

	# DC Multiplier
	dc_multiplier_label = Label.new()
	dc_multiplier_label.text = "💾 x1.0"
	dc_multiplier_label.position = Vector2(120, 120)
	dc_multiplier_label.add_theme_font_size_override("font_size", 14)
	tier_selector_panel.add_child(dc_multiplier_label)

func _create_left_side_buttons() -> void:
	# Daily rewards, events, etc. (x=5, y=460+)

	# Daily reward button with timer
	daily_reward_button = Button.new()
	daily_reward_button.text = "💎 CLAIM"
	daily_reward_button.position = Vector2(5, 460)
	daily_reward_button.custom_minimum_size = Vector2(90, 60)
	add_child(daily_reward_button)

	daily_reward_timer_label = Label.new()
	daily_reward_timer_label.text = "Next in\n2d 6h"
	daily_reward_timer_label.position = Vector2(12, 15)
	daily_reward_timer_label.add_theme_font_size_override("font_size", 10)
	daily_reward_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily_reward_button.add_child(daily_reward_timer_label)

	# Tournament button
	tournament_button = Button.new()
	tournament_button.text = "🏆"
	tournament_button.position = Vector2(5, 530)
	tournament_button.custom_minimum_size = Vector2(90, 50)
	add_child(tournament_button)

	tournament_timer_label = Label.new()
	tournament_timer_label.text = "Next in 1d 6h"
	tournament_timer_label.position = Vector2(5, 30)
	tournament_timer_label.add_theme_font_size_override("font_size", 9)
	tournament_button.add_child(tournament_timer_label)

	# Milestone button (similar to "MILESTONES" in The Tower)
	milestone_progress_button = Button.new()
	milestone_progress_button.text = "🎖️\nPASS"
	milestone_progress_button.position = Vector2(5, 590)
	milestone_progress_button.custom_minimum_size = Vector2(90, 50)
	add_child(milestone_progress_button)

func _create_right_side_buttons() -> void:
	# Settings, Labs, Achievements, etc. (x=295, y=100+)
	var button_y = 100
	var button_spacing = 60

	# Settings
	settings_button = Button.new()
	settings_button.text = "⚙️"
	settings_button.position = Vector2(295, button_y)
	settings_button.custom_minimum_size = Vector2(90, 50)
	add_child(settings_button)
	button_y += button_spacing

	# Labs
	labs_button = Button.new()
	labs_button.text = "🔬"
	labs_button.position = Vector2(295, button_y)
	labs_button.custom_minimum_size = Vector2(90, 50)
	add_child(labs_button)
	button_y += button_spacing

	# Achievements
	achievements_button = Button.new()
	achievements_button.text = "🏆"
	achievements_button.position = Vector2(295, button_y)
	achievements_button.custom_minimum_size = Vector2(90, 50)
	add_child(achievements_button)
	button_y += button_spacing

	# Stats
	stats_button = Button.new()
	stats_button.text = "📊"
	stats_button.position = Vector2(295, button_y)
	stats_button.custom_minimum_size = Vector2(90, 50)
	add_child(stats_button)
	button_y += button_spacing

	# Shop
	shop_button = Button.new()
	shop_button.text = "💎"
	shop_button.position = Vector2(295, button_y)
	shop_button.custom_minimum_size = Vector2(90, 50)
	add_child(shop_button)

func _create_start_battle_button() -> void:
	# Large "START BATTLE" button (y=660)
	start_battle_button = Button.new()
	start_battle_button.text = "START BATTLE"
	start_battle_button.position = Vector2(75, 660)
	start_battle_button.custom_minimum_size = Vector2(240, 70)
	start_battle_button.add_theme_font_size_override("font_size", 24)
	add_child(start_battle_button)

func _create_bottom_navigation() -> void:
	# Bottom nav bar (y=750+) - similar to The Tower's bottom icons
	var nav_y = 750
	var button_width = 90
	var spacing = 5

	# Drones
	drones_nav_button = Button.new()
	drones_nav_button.text = "🚁\nDrones"
	drones_nav_button.position = Vector2(5, nav_y)
	drones_nav_button.custom_minimum_size = Vector2(button_width, 80)
	add_child(drones_nav_button)

	# Permanent Upgrades
	perms_nav_button = Button.new()
	perms_nav_button.text = "⬆️\nPerms"
	perms_nav_button.position = Vector2(100, nav_y)
	perms_nav_button.custom_minimum_size = Vector2(button_width, 80)
	add_child(perms_nav_button)

	# Data Disks
	data_disks_nav_button = Button.new()
	data_disks_nav_button.text = "📀\nDisks"
	data_disks_nav_button.position = Vector2(195, nav_y)
	data_disks_nav_button.custom_minimum_size = Vector2(button_width, 80)
	add_child(data_disks_nav_button)

	# Tiers (alternative access)
	tiers_nav_button = Button.new()
	tiers_nav_button.text = "🎖️\nTiers"
	tiers_nav_button.position = Vector2(290, nav_y)
	tiers_nav_button.custom_minimum_size = Vector2(button_width, 80)
	add_child(tiers_nav_button)

# === SIGNAL CONNECTIONS ===

func _connect_signals() -> void:
	# Tier selection
	tier_left_button.pressed.connect(_on_tier_left_pressed)
	tier_right_button.pressed.connect(_on_tier_right_pressed)

	# Left side buttons
	daily_reward_button.pressed.connect(_on_daily_reward_pressed)
	tournament_button.pressed.connect(_on_tournament_pressed)
	milestone_progress_button.pressed.connect(_on_milestone_pressed)

	# Right side buttons
	settings_button.pressed.connect(_on_settings_pressed)
	labs_button.pressed.connect(_on_labs_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	shop_button.pressed.connect(_on_shop_pressed)

	# Main action
	start_battle_button.pressed.connect(_on_start_battle_pressed)

	# Bottom nav
	drones_nav_button.pressed.connect(_on_drones_nav_pressed)
	perms_nav_button.pressed.connect(_on_perms_nav_pressed)
	data_disks_nav_button.pressed.connect(_on_data_disks_nav_pressed)
	tiers_nav_button.pressed.connect(_on_tiers_nav_pressed)

	# Listen for currency changes
	if RewardManager:
		RewardManager.currency_changed.connect(_update_display)

	# Listen for daily reward signals
	if DailyRewardManager:
		DailyRewardManager.reward_ready.connect(_update_timers)
		DailyRewardManager.reward_claimed.connect(_on_daily_reward_claimed_signal)

# === DISPLAY UPDATE ===

func _update_display() -> void:
	if not RewardManager or not TierManager:
		return

	# Update currencies
	dc_label.text = "💾 %s" % NumberFormatter.format(RewardManager.data_credits)
	at_label.text = "📦 %s" % NumberFormatter.format(RewardManager.archive_tokens)
	fragments_label.text = "💎 %s" % NumberFormatter.format(RewardManager.fragments)
	qc_label.text = "🔮 %s" % NumberFormatter.format(RewardManager.quantum_cores)

	# Update tier/wave info
	var current_tier = TierManager.get_current_tier()
	var highest_wave = TierManager.get_highest_wave_in_tier(current_tier)
	tier_wave_label.text = "Tier %d • Wave %d" % [current_tier, highest_wave]
	tier_label.text = "Tier %d" % current_tier
	highest_wave_label.text = "Highest Wave: %d" % highest_wave

	# Update DC multiplier
	var multiplier = TierManager.get_dc_multiplier_for_tier(current_tier)
	dc_multiplier_label.text = "💾 x%.1f" % multiplier

func _update_timers() -> void:
	# Update daily reward timer
	if DailyRewardManager:
		if DailyRewardManager.is_reward_ready():
			daily_reward_button.text = "💎 CLAIM"
			daily_reward_button.disabled = false
			daily_reward_timer_label.text = "Ready!"
		else:
			daily_reward_button.text = "💎"
			daily_reward_button.disabled = true
			var time_string = DailyRewardManager.get_time_until_ready_string()
			daily_reward_timer_label.text = "Next in\n%s" % time_string

	# Update tournament timer
	if BossRushManager:
		if BossRushManager.is_tournament_available():
			tournament_button.disabled = false
			tournament_timer_label.text = "ACTIVE!"
		else:
			tournament_button.disabled = true
			var next_tournament = BossRushManager.get_next_tournament_time()
			var hours = next_tournament["hours_until"]
			var days = hours / 24
			var remaining_hours = hours % 24

			if days > 0:
				tournament_timer_label.text = "Next in %dd %dh" % [days, remaining_hours]
			else:
				tournament_timer_label.text = "Next in %dh" % remaining_hours

# === BUTTON HANDLERS ===

func _on_tier_left_pressed() -> void:
	if not TierManager:
		return
	var current_tier = TierManager.get_current_tier()
	if current_tier > 1:
		TierManager.set_current_tier(current_tier - 1)
		_update_display()

func _on_tier_right_pressed() -> void:
	if not TierManager:
		return
	var current_tier = TierManager.get_current_tier()
	var max_unlocked_tier = TierManager.max_unlocked_tier
	if current_tier < max_unlocked_tier:
		TierManager.set_current_tier(current_tier + 1)
		_update_display()

func _on_daily_reward_pressed() -> void:
	if not DailyRewardManager:
		return

	var reward_info = DailyRewardManager.claim_reward()
	if not reward_info.is_empty():
		# Show popup with claimed reward
		_show_daily_reward_popup(reward_info["fragments"], reward_info["qc"], reward_info["day"])
		_update_display()
		_update_timers()

func _on_daily_reward_claimed_signal(fragments: int, qc: int, streak: int) -> void:
	# Signal handler for when reward is claimed (can be used for notifications)
	pass

func _on_tournament_pressed() -> void:
	if not BossRushManager:
		return

	if BossRushManager.is_tournament_available():
		_show_tournament_ui()
	else:
		print("⚠️ Tournament not available yet")

func _on_milestone_pressed() -> void:
	_show_overlay("milestone")

func _on_settings_pressed() -> void:
	_show_overlay("settings")

func _on_labs_pressed() -> void:
	_show_overlay("labs")

func _on_achievements_pressed() -> void:
	_show_overlay("achievements")

func _on_stats_pressed() -> void:
	_show_overlay("stats")

func _on_shop_pressed() -> void:
	_show_overlay("shop")

func _on_start_battle_pressed() -> void:
	# Transition to main game
	get_tree().change_scene_to_file("res://main_hud.tscn")

func _on_drones_nav_pressed() -> void:
	_show_overlay("drones")

func _on_perms_nav_pressed() -> void:
	_show_overlay("perms")

func _on_data_disks_nav_pressed() -> void:
	_show_overlay("data_disks")

func _on_tiers_nav_pressed() -> void:
	_show_overlay("tiers")

# === OVERLAY SYSTEM ===

func _show_overlay(overlay_type: String) -> void:
	# Show overlay panel for various systems
	if overlay_panel:
		overlay_panel.queue_free()

	match overlay_type:
		"labs":
			overlay_panel = preload("res://software_upgrade_ui.gd").new()
		"achievements":
			overlay_panel = preload("res://achievement_ui.gd").new()
		"stats":
			# TODO: Create a start screen stats overlay
			print("📊 Stats overlay")
			return
		"shop":
			overlay_panel = preload("res://quantum_core_shop_ui.gd").new()
		"drones":
			overlay_panel = preload("res://drone_upgrade_ui.gd").new()
		"milestone":
			overlay_panel = preload("res://milestone_ui.gd").new()
		"tiers":
			overlay_panel = preload("res://tier_selection_ui.gd").new()
		"perms":
			overlay_panel = preload("res://permanent_upgrades_ui.gd").new()
		"data_disks":
			overlay_panel = preload("res://data_disk_collection_ui.gd").new()
		"settings":
			overlay_panel = preload("res://settings_ui.gd").new()

	if overlay_panel:
		add_child(overlay_panel)
		overlay_panel.visible = true

# === TOURNAMENT UI ===

func _show_tournament_ui() -> void:
	# Create tournament info panel
	var tournament_panel = Panel.new()
	tournament_panel.position = Vector2(15, 50)
	tournament_panel.custom_minimum_size = Vector2(360, 780)
	add_child(tournament_panel)

	# Title
	var title = Label.new()
	title.text = "🏆 BOSS RUSH TOURNAMENT"
	title.position = Vector2(20, 15)
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(320, 30)
	tournament_panel.add_child(title)

	# Info text
	var info = Label.new()
	info.text = "Every wave spawns only bosses!\nDamage dealt determines your rank.\n\nTop 10 players earn fragment rewards!"
	info.position = Vector2(20, 50)
	info.add_theme_font_size_override("font_size", 14)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size = Vector2(320, 80)
	tournament_panel.add_child(info)

	# Start Boss Rush button
	var start_button = Button.new()
	start_button.text = "START BOSS RUSH"
	start_button.position = Vector2(60, 140)
	start_button.custom_minimum_size = Vector2(240, 60)
	start_button.add_theme_font_size_override("font_size", 20)
	start_button.pressed.connect(_on_start_boss_rush_from_tournament)
	tournament_panel.add_child(start_button)

	# Leaderboard section
	var leaderboard_label = Label.new()
	leaderboard_label.text = "LEADERBOARD"
	leaderboard_label.position = Vector2(20, 220)
	leaderboard_label.add_theme_font_size_override("font_size", 18)
	leaderboard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_label.custom_minimum_size = Vector2(320, 25)
	tournament_panel.add_child(leaderboard_label)

	# Leaderboard scroll area
	var leaderboard_scroll = ScrollContainer.new()
	leaderboard_scroll.position = Vector2(20, 255)
	leaderboard_scroll.custom_minimum_size = Vector2(320, 450)
	tournament_panel.add_child(leaderboard_scroll)

	var leaderboard_list = VBoxContainer.new()
	leaderboard_list.custom_minimum_size = Vector2(300, 0)
	leaderboard_scroll.add_child(leaderboard_list)

	# Add leaderboard entries from BossRushManager
	if BossRushManager and BossRushManager.leaderboard.size() > 0:
		var rank = 1
		for entry_data in BossRushManager.leaderboard:
			var entry_container = HBoxContainer.new()
			entry_container.custom_minimum_size = Vector2(300, 35)
			leaderboard_list.add_child(entry_container)

			# Rank
			var rank_label = Label.new()
			rank_label.text = "%d." % rank
			rank_label.add_theme_font_size_override("font_size", 14)
			rank_label.custom_minimum_size = Vector2(30, 35)
			entry_container.add_child(rank_label)

			# Player ID (truncate if too long)
			var player_id = entry_data.get("player_id", "Player")
			if player_id.length() > 12:
				player_id = player_id.substr(0, 12) + "..."
			var player_label = Label.new()
			player_label.text = player_id
			player_label.add_theme_font_size_override("font_size", 13)
			player_label.custom_minimum_size = Vector2(120, 35)
			entry_container.add_child(player_label)

			# Damage
			var damage_label = Label.new()
			damage_label.text = "%s DMG" % NumberFormatter.format(entry_data.get("damage", 0))
			damage_label.add_theme_font_size_override("font_size", 13)
			damage_label.custom_minimum_size = Vector2(120, 35)
			damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			damage_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			entry_container.add_child(damage_label)

			rank += 1

			# Top 3 get special colors
			if rank <= 4:  # rank is already incremented, so check <= 4
				var color = Color.WHITE
				if rank == 2:  # 1st place (gold)
					color = Color(1.0, 0.84, 0.0)
				elif rank == 3:  # 2nd place (silver)
					color = Color(0.75, 0.75, 0.75)
				elif rank == 4:  # 3rd place (bronze)
					color = Color(0.8, 0.5, 0.2)

				rank_label.add_theme_color_override("font_color", color)
				player_label.add_theme_color_override("font_color", color)
	else:
		# No leaderboard data yet
		var empty_label = Label.new()
		empty_label.text = "No tournament data yet.\nBe the first to compete!"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(300, 100)
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		leaderboard_list.add_child(empty_label)

	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(func(): tournament_panel.queue_free())
	tournament_panel.add_child(close_button)

func _on_start_boss_rush_from_tournament() -> void:
	# Start boss rush mode and transition to game
	if BossRushManager:
		BossRushManager.start_boss_rush()
	get_tree().change_scene_to_file("res://main_hud.tscn")

# === DAILY REWARD POPUP ===

func _show_daily_reward_popup(fragments: int, qc: int, day: int) -> void:
	# Create popup panel
	var popup_bg = Panel.new()
	popup_bg.position = Vector2(60, 300)
	popup_bg.custom_minimum_size = Vector2(270, 200)
	add_child(popup_bg)

	# Title
	var title = Label.new()
	title.text = "🎁 DAILY REWARD"
	title.position = Vector2(20, 15)
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(230, 30)
	popup_bg.add_child(title)

	# Day streak
	var day_label = Label.new()
	day_label.text = "Day %d Claimed!" % day
	day_label.position = Vector2(20, 50)
	day_label.add_theme_font_size_override("font_size", 16)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.custom_minimum_size = Vector2(230, 25)
	popup_bg.add_child(day_label)

	# Rewards
	var reward_label = Label.new()
	reward_label.text = "💎 %s Fragments\n🔮 %s Quantum Cores" % [
		NumberFormatter.format(fragments),
		NumberFormatter.format(qc)
	]
	reward_label.position = Vector2(20, 85)
	reward_label.add_theme_font_size_override("font_size", 16)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.custom_minimum_size = Vector2(230, 60)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	popup_bg.add_child(reward_label)

	# Close button
	var close_button = Button.new()
	close_button.text = "Claim"
	close_button.position = Vector2(80, 155)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(func(): popup_bg.queue_free())
	popup_bg.add_child(close_button)

# === LOGIN ===

func _show_login_screen() -> void:
	login_ui = preload("res://login_ui.gd").new()
	add_child(login_ui)
	login_ui.show_login()
	login_ui.login_completed.connect(_on_login_completed)

func _on_login_completed() -> void:
	print("✅ Player logged in successfully")
	_update_display()
