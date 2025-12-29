extends Control

# Achievement UI
# Shows all lifetime achievements with progress bars and rewards

# UI Nodes
var panel: Panel
var title_label: Label
var total_qc_label: Label
var achievement_scroll: ScrollContainer
var achievement_list: VBoxContainer
var close_button: Button

func _ready() -> void:
	_create_ui()

	# Connect signals
	if AchievementManager:
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	# Initial refresh
	_refresh_ui()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(480, 780)
	panel.position = Vector2(15, 50)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🏆 LIFETIME ACHIEVEMENTS"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(440, 30)
	panel.add_child(title_label)

	# Total QC earned from achievements
	total_qc_label = Label.new()
	total_qc_label.text = "Total QC Earned: 0 🔮"
	total_qc_label.position = Vector2(20, 48)
	total_qc_label.add_theme_font_size_override("font_size", 14)
	total_qc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_qc_label.custom_minimum_size = Vector2(440, 25)
	panel.add_child(total_qc_label)

	# Achievement scroll area
	achievement_scroll = ScrollContainer.new()
	achievement_scroll.position = Vector2(20, 85)
	achievement_scroll.custom_minimum_size = Vector2(440, 630)
	panel.add_child(achievement_scroll)

	achievement_list = VBoxContainer.new()
	achievement_list.custom_minimum_size = Vector2(420, 0)
	achievement_scroll.add_child(achievement_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(185, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _refresh_ui() -> void:
	if not AchievementManager:
		return

	# Update total QC earned
	var total_qc = AchievementManager.get_total_qc_earned_from_achievements()
	total_qc_label.text = "Total QC Earned: %s 🔮" % NumberFormatter.format(total_qc)

	# Clear existing achievement widgets
	for child in achievement_list.get_children():
		child.queue_free()

	# Get all achievements
	var achievements = AchievementManager.get_all_achievements()

	# Create widget for each achievement
	for achievement in achievements:
		_create_achievement_widget(achievement)

func _create_achievement_widget(achievement: Dictionary) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(420, 120)
	achievement_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Header with icon and name
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var icon_label = Label.new()
	icon_label.text = achievement["icon"]
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.custom_minimum_size = Vector2(40, 30)
	header.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = achievement["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.custom_minimum_size = Vector2(300, 30)
	header.add_child(name_label)

	# Tier indicator
	var tier_label = Label.new()
	if achievement["completed"]:
		tier_label.text = "✅ MAX"
		tier_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
	else:
		tier_label.text = "Tier %d/%d" % [achievement["current_tier"] + 1, achievement["total_tiers"]]
	tier_label.add_theme_font_size_override("font_size", 12)
	tier_label.custom_minimum_size = Vector2(80, 30)
	header.add_child(tier_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = achievement["description"]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desc_label)

	# Progress bar and text
	var progress_container = HBoxContainer.new()
	vbox.add_child(progress_container)

	var progress_label = Label.new()
	if achievement["completed"]:
		progress_label.text = "Completed! 🎉"
	else:
		progress_label.text = "%s / %s" % [
			NumberFormatter.format(achievement["current_value"]),
			NumberFormatter.format(achievement["next_threshold"])
		]
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.custom_minimum_size = Vector2(200, 20)
	progress_container.add_child(progress_label)

	# Progress bar (visual)
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(200, 20)
	if achievement["completed"]:
		progress_bar.value = 100
	else:
		var progress_percent = 0.0
		if achievement["next_threshold"] > 0:
			progress_percent = (float(achievement["current_value"]) / float(achievement["next_threshold"])) * 100.0
			progress_percent = min(progress_percent, 100.0)
		progress_bar.value = progress_percent
	progress_container.add_child(progress_bar)

	# Reward info
	var reward_label = Label.new()
	if achievement["completed"]:
		reward_label.text = "All rewards claimed! Total: %s QC" % _calculate_total_qc_for_achievement(achievement)
	else:
		reward_label.text = "Next Reward: %s QC 🔮" % NumberFormatter.format(achievement["next_reward"])
	reward_label.add_theme_font_size_override("font_size", 12)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(reward_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	achievement_list.add_child(spacer)

func _calculate_total_qc_for_achievement(achievement: Dictionary) -> String:
	if not AchievementManager or not AchievementManager.ACHIEVEMENTS.has(achievement["id"]):
		return "0"

	var achievement_data = AchievementManager.ACHIEVEMENTS[achievement["id"]]
	var total_qc = 0
	for tier in achievement_data["tiers"]:
		total_qc += tier["qc_reward"]

	return NumberFormatter.format(total_qc)

func _on_achievement_unlocked(achievement_id: String, tier: int, qc_reward: int) -> void:
	# Refresh UI when achievement is unlocked
	_refresh_ui()

	# Could add a notification popup here
	print("🏆 Achievement Unlocked: %s (Tier %d) - %d QC!" % [achievement_id, tier + 1, qc_reward])

func _on_close_pressed() -> void:
	visible = false
