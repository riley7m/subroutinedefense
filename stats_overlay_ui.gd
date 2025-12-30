extends Control

# Stats Overlay UI
# Shows player's lifetime statistics

# UI Nodes
var panel: Panel
var title_label: Label
var scroll_container: ScrollContainer
var stats_list: VBoxContainer
var close_button: Button

func _ready() -> void:
	_create_ui()
	_populate_stats()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 780)
	panel.position = Vector2(15, 50)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "📊 STATISTICS"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Scroll area for stats
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(20, 60)
	scroll_container.custom_minimum_size = Vector2(320, 655)
	panel.add_child(scroll_container)

	stats_list = VBoxContainer.new()
	stats_list.custom_minimum_size = Vector2(300, 0)
	scroll_container.add_child(stats_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _populate_stats() -> void:
	if not RunStats:
		return

	# Lifetime Currency Section
	_create_section_header("💰 CURRENCY EARNED")

	_create_stat_row("Data Credits", RunStats.lifetime_dc_earned, "💾")
	_create_stat_row("Archive Tokens", RunStats.lifetime_at_earned, "📦")
	_create_stat_row("Fragments", RunStats.lifetime_fragments_earned, "💎")

	_add_spacer(20)

	# Spending Section
	_create_section_header("💸 SPENDING")

	_create_stat_row("AT on Labs", RunStats.lifetime_at_spent_labs, "🔬")
	_create_stat_row("AT on Permanent Upgrades", RunStats.lifetime_at_spent_perm_upgrades, "⬆️")

	var total_at_spent = RunStats.lifetime_at_spent_labs + RunStats.lifetime_at_spent_perm_upgrades
	_create_stat_row("Total AT Spent", total_at_spent, "📊", Color(1.0, 0.85, 0.0))

	_add_spacer(20)

	# Kills Section
	_create_section_header("⚔️ LIFETIME KILLS")

	var total_kills = 0
	for enemy_type in RunStats.lifetime_kills.keys():
		var kills = RunStats.lifetime_kills[enemy_type]
		total_kills += kills
		var icon = _get_enemy_icon(enemy_type)
		var display_name = enemy_type.capitalize().replace("_", " ")
		_create_stat_row(display_name, kills, icon)

	_add_spacer(5)
	_create_stat_row("Total Kills", total_kills, "💀", Color(1.0, 0.3, 0.3))

	_add_spacer(20)

	# Tier Progress Section
	_create_section_header("🏆 TIER PROGRESS")

	if TierManager:
		var current_tier = TierManager.get_current_tier()
		var max_unlocked = TierManager.max_unlocked_tier

		_create_stat_row("Current Tier", current_tier, "📍", Color(0.4, 1.0, 0.4))
		_create_stat_row("Max Unlocked Tier", max_unlocked, "🔓")

		for tier in range(1, max_unlocked + 1):
			var highest_wave = TierManager.get_highest_wave(tier)
			_create_stat_row("Tier %d Highest Wave" % tier, highest_wave, "🌊", Color(0.7, 0.9, 1.0))

	_add_spacer(20)

	# Achievements Section
	_create_section_header("🏅 ACHIEVEMENTS")

	if AchievementManager:
		var total_achievements = AchievementManager.get_total_achievement_count()
		var unlocked_achievements = AchievementManager.get_unlocked_achievement_count()
		var qc_from_achievements = AchievementManager.get_total_qc_from_achievements()

		_create_stat_row("Achievements Unlocked", unlocked_achievements, "✨", Color(1.0, 0.85, 0.0))
		_create_stat_row("Total Achievements", total_achievements, "🏆")
		_create_stat_row("QC from Achievements", qc_from_achievements, "🔮", Color(0.8, 0.5, 1.0))

		var completion_percent = 0
		if total_achievements > 0:
			completion_percent = int((float(unlocked_achievements) / total_achievements) * 100)
		_create_stat_row("Completion", completion_percent, "%", Color(0.4, 1.0, 0.4))

func _create_section_header(text: String) -> void:
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	header.custom_minimum_size = Vector2(300, 30)
	stats_list.add_child(header)

	# Separator line
	var separator = ColorRect.new()
	separator.color = Color(0.3, 0.3, 0.4, 0.5)
	separator.custom_minimum_size = Vector2(300, 2)
	stats_list.add_child(separator)

	_add_spacer(10)

func _create_stat_row(label_text: String, value, icon: String = "", custom_color: Color = Color.WHITE) -> void:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(300, 30)
	stats_list.add_child(row)

	# Icon + Label
	var label = Label.new()
	if icon != "":
		label.text = "%s %s" % [icon, label_text]
	else:
		label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(200, 30)
	row.add_child(label)

	# Value
	var value_label = Label.new()
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		value_label.text = NumberFormatter.format(value)
	else:
		value_label.text = str(value)
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", custom_color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(80, 30)
	row.add_child(value_label)

func _get_enemy_icon(enemy_type: String) -> String:
	match enemy_type:
		"breacher":
			return "🔵"
		"slicer":
			return "🔺"
		"sentinel":
			return "🛡️"
		"signal_runner":
			return "⚡"
		"nullwalker":
			return "👻"
		"override":
			return "👑"
		_:
			return "💀"

func _add_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	stats_list.add_child(spacer)

func _on_close_pressed() -> void:
	queue_free()
