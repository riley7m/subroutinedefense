# boss_rush_death_screen.gd
# Custom death screen for Boss Rush tournament mode

extends CanvasLayer

var panel: Panel
var title_label: Label
var damage_label: Label
var waves_label: Label
var rank_label: Label
var reward_label: Label
var leaderboard_preview: VBoxContainer
var continue_button: Button

var final_damage: int = 0
var final_waves: int = 0
var final_rank: int = 0
var fragment_reward: int = 0

func _ready() -> void:
	_create_ui()
	visible = false

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 550)
	panel.position = Vector2(20, 150)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🏆 BOSS RUSH COMPLETE!"
	title_label.position = Vector2(20, 20)
	title_label.custom_minimum_size = Vector2(310, 40)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title_label)

	# Stats container
	var stats_vbox = VBoxContainer.new()
	stats_vbox.position = Vector2(20, 75)
	stats_vbox.custom_minimum_size = Vector2(310, 150)
	panel.add_child(stats_vbox)

	# Damage dealt
	damage_label = Label.new()
	damage_label.text = "Damage Dealt: 0"
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.custom_minimum_size = Vector2(310, 30)
	stats_vbox.add_child(damage_label)

	# Waves survived
	waves_label = Label.new()
	waves_label.text = "Waves Survived: 0"
	waves_label.add_theme_font_size_override("font_size", 16)
	waves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waves_label.custom_minimum_size = Vector2(310, 30)
	stats_vbox.add_child(waves_label)

	# Separator
	var sep1 = HSeparator.new()
	sep1.custom_minimum_size = Vector2(310, 10)
	stats_vbox.add_child(sep1)

	# Rank
	rank_label = Label.new()
	rank_label.text = "Rank: #1"
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.custom_minimum_size = Vector2(310, 35)
	stats_vbox.add_child(rank_label)

	# Fragment reward
	reward_label = Label.new()
	reward_label.text = "💎 Reward: 5000 Fragments"
	reward_label.add_theme_font_size_override("font_size", 18)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.custom_minimum_size = Vector2(310, 35)
	stats_vbox.add_child(reward_label)

	# Leaderboard preview title
	var leaderboard_title = Label.new()
	leaderboard_title.text = "📊 Top 5 Leaderboard"
	leaderboard_title.position = Vector2(20, 240)
	leaderboard_title.add_theme_font_size_override("font_size", 16)
	leaderboard_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_title.custom_minimum_size = Vector2(310, 25)
	panel.add_child(leaderboard_title)

	# Leaderboard preview
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 270)
	scroll.custom_minimum_size = Vector2(310, 200)
	panel.add_child(scroll)

	leaderboard_preview = VBoxContainer.new()
	leaderboard_preview.custom_minimum_size = Vector2(290, 0)
	scroll.add_child(leaderboard_preview)

	# Continue button
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.position = Vector2(120, 485)
	continue_button.custom_minimum_size = Vector2(110, 45)
	continue_button.pressed.connect(_on_continue_pressed)
	panel.add_child(continue_button)

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func show_boss_rush_death(damage: int, waves: int) -> void:
	final_damage = damage
	final_waves = waves

	# Calculate rank and reward
	if BossRushManager:
		final_rank = BossRushManager.get_rank_for_damage(damage)
		fragment_reward = BossRushManager.get_fragment_reward_for_rank(final_rank)

	# Update labels
	damage_label.text = "Damage Dealt: %s" % BossRushManager.format_damage(damage)
	waves_label.text = "Waves Survived: %d" % waves

	# Update rank with medal emoji
	var rank_text = "Rank: #%d" % final_rank
	if final_rank == 1:
		rank_text = "Rank: 🥇 #1"
	elif final_rank == 2:
		rank_text = "Rank: 🥈 #2"
	elif final_rank == 3:
		rank_text = "Rank: 🥉 #3"
	rank_label.text = rank_text

	# Update reward
	reward_label.text = "💎 Reward: %d Fragments" % fragment_reward

	# Populate leaderboard preview (top 5)
	_refresh_leaderboard_preview()

	# Show screen
	visible = true
	get_tree().paused = true

	print("=== BOSS RUSH COMPLETE ===")
	print("Damage Dealt: %d" % damage)
	print("Waves Survived: %d" % waves)
	print("Rank: #%d" % final_rank)
	print("Fragment Reward: %d" % fragment_reward)
	print("==========================")

func _refresh_leaderboard_preview() -> void:
	# Clear existing entries
	for child in leaderboard_preview.get_children():
		child.queue_free()

	if not BossRushManager:
		return

	var leaderboard = BossRushManager.get_leaderboard()
	var max_entries = mini(5, leaderboard.size())

	for i in range(max_entries):
		var entry = leaderboard[i]
		var rank = i + 1

		var entry_container = HBoxContainer.new()
		entry_container.custom_minimum_size = Vector2(290, 30)
		leaderboard_preview.add_child(entry_container)

		# Rank
		var rank_label_small = Label.new()
		if rank == 1:
			rank_label_small.text = "🥇"
		elif rank == 2:
			rank_label_small.text = "🥈"
		elif rank == 3:
			rank_label_small.text = "🥉"
		else:
			rank_label_small.text = "#%d" % rank
		rank_label_small.custom_minimum_size = Vector2(40, 25)
		rank_label_small.add_theme_font_size_override("font_size", 14)
		entry_container.add_child(rank_label_small)

		# Damage
		var damage_label_small = Label.new()
		damage_label_small.text = "%s dmg" % BossRushManager.format_damage(entry["damage"])
		damage_label_small.custom_minimum_size = Vector2(100, 25)
		damage_label_small.add_theme_font_size_override("font_size", 13)
		entry_container.add_child(damage_label_small)

		# Waves
		var waves_label_small = Label.new()
		waves_label_small.text = "W%d" % entry["waves"]
		waves_label_small.custom_minimum_size = Vector2(50, 25)
		waves_label_small.add_theme_font_size_override("font_size", 12)
		entry_container.add_child(waves_label_small)

		# Highlight current player's entry
		if entry["damage"] == final_damage and entry["waves"] == final_waves:
			entry_container.modulate = Color(1.0, 1.0, 0.0)  # Yellow highlight

func _on_continue_pressed() -> void:
	print("Boss Rush death screen - Continue pressed")
	get_tree().paused = false
	visible = false

	# Return to start screen
	get_tree().change_scene_to_file("res://StartScreen.tscn")
