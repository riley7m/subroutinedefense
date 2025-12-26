extends Control

# Tier Selection UI - Allows players to view and enter different tiers

# UI Nodes
var panel: Panel
var title_label: Label
var tier_scroll: ScrollContainer
var tier_list: VBoxContainer
var tier_containers: Dictionary = {}  # tier -> container dict
var close_button: Button

func _ready() -> void:
	_create_ui()

	# Connect signals
	if TierManager:
		TierManager.tier_changed.connect(_on_tier_changed)
		TierManager.tier_unlocked.connect(_on_tier_unlocked)

	# Initial refresh
	_refresh_ui()

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
	title_label.text = "🎖️ Tier Selection"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(title_label)

	# Info label
	var info_label = Label.new()
	info_label.text = "Entering a new tier resets to Wave 1"
	info_label.position = Vector2(20, 45)
	info_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(info_label)

	# Tier scroll container
	tier_scroll = ScrollContainer.new()
	tier_scroll.position = Vector2(20, 75)
	tier_scroll.custom_minimum_size = Vector2(320, 620)
	panel.add_child(tier_scroll)

	tier_list = VBoxContainer.new()
	tier_list.custom_minimum_size = Vector2(300, 0)
	tier_scroll.add_child(tier_list)

	# Create tier containers (1-10)
	for tier in range(1, 11):
		_create_tier_container(tier)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 705)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _create_tier_container(tier: int) -> void:
	# Container for this tier
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(300, 80)
	tier_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Tier header (name + status)
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var tier_name_label = Label.new()
	tier_name_label.text = "Tier %d" % tier
	tier_name_label.custom_minimum_size = Vector2(100, 20)
	tier_name_label.add_theme_font_size_override("font_size", 16)
	header_hbox.add_child(tier_name_label)

	var status_label = Label.new()
	status_label.text = "Locked"
	status_label.custom_minimum_size = Vector2(100, 20)
	status_label.add_theme_font_size_override("font_size", 14)
	header_hbox.add_child(status_label)

	# Info line (multipliers + highest wave)
	var info_label = Label.new()
	info_label.text = "Enemies: 1x | Rewards: 1x | Best: Wave 0"
	info_label.custom_minimum_size = Vector2(280, 18)
	info_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(info_label)

	# Enter button
	var enter_button = Button.new()
	enter_button.text = "Enter Tier"
	enter_button.custom_minimum_size = Vector2(280, 30)
	enter_button.pressed.connect(_on_enter_tier_pressed.bind(tier))
	vbox.add_child(enter_button)

	# Store references
	tier_containers[tier] = {
		"container": container,
		"status_label": status_label,
		"info_label": info_label,
		"enter_button": enter_button,
	}

func _refresh_ui() -> void:
	if not TierManager:
		return

	for tier in range(1, 11):
		var info = TierManager.get_tier_info(tier)
		if info.is_empty():
			continue

		var widgets = tier_containers.get(tier, {})
		if widgets.is_empty():
			continue

		var status_label = widgets["status_label"]
		var info_label = widgets["info_label"]
		var enter_button = widgets["enter_button"]

		# Update status
		if info["is_current"]:
			status_label.text = "⭐ CURRENT"
		elif info["unlocked"]:
			status_label.text = "✅ Unlocked"
		else:
			status_label.text = "🔒 Locked"

		# Update info line
		var enemy_mult_str = "%.0fx" % info["enemy_multiplier"] if info["enemy_multiplier"] >= 10 else "%.1fx" % info["enemy_multiplier"]
		var reward_mult_str = "%.0fx" % info["reward_multiplier"] if info["reward_multiplier"] >= 10 else "%.1fx" % info["reward_multiplier"]
		info_label.text = "Enemies: %s | Rewards: %s | Best: Wave %d" % [
			enemy_mult_str,
			reward_mult_str,
			info["highest_wave"]
		]

		# Update button
		if info["is_current"]:
			enter_button.text = "Currently Active"
			enter_button.disabled = true
		elif info["unlocked"]:
			enter_button.text = "Enter Tier %d" % tier
			enter_button.disabled = false
		else:
			enter_button.text = "Reach Wave %d in Tier %d" % [info["unlock_requirement"], tier - 1]
			enter_button.disabled = true

func _on_enter_tier_pressed(tier: int) -> void:
	if not TierManager:
		return

	# Confirm with user (via print for now, could add popup later)
	if TierManager.enter_tier(tier):
		print("✅ Entered Tier %d! Resetting to Wave 1..." % tier)
		_refresh_ui()

		# Trigger wave reset in main_hud/spawner
		var main_hud = get_parent()
		if main_hud and main_hud.has_method("reset_to_wave_1"):
			main_hud.reset_to_wave_1()
	else:
		print("❌ Failed to enter Tier %d" % tier)

func _on_tier_changed(new_tier: int) -> void:
	_refresh_ui()

func _on_tier_unlocked(tier: int) -> void:
	_refresh_ui()
	print("🎉 Tier %d unlocked! Check Tier Selection to enter it." % tier)

func _on_close_pressed() -> void:
	visible = false

func _exit_tree() -> void:
	# Disconnect signals
	if TierManager:
		if TierManager.tier_changed.is_connected(Callable(self, "_on_tier_changed")):
			TierManager.tier_changed.disconnect(Callable(self, "_on_tier_changed"))
		if TierManager.tier_unlocked.is_connected(Callable(self, "_on_tier_unlocked")):
			TierManager.tier_unlocked.disconnect(Callable(self, "_on_tier_unlocked"))
