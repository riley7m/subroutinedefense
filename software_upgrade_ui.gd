extends Control

# UI for Software Upgrades (Lab/Research system)

# UI Nodes
var panel: Panel
var title_label: Label
var slot_containers: Array = []
var available_scroll: ScrollContainer
var available_list: VBoxContainer
var completed_label: Label

func _ready() -> void:
	_create_ui()

	# Connect signals
	if SoftwareUpgradeManager:
		SoftwareUpgradeManager.upgrade_started.connect(_on_upgrade_started)
		SoftwareUpgradeManager.upgrade_completed.connect(_on_upgrade_completed)
		SoftwareUpgradeManager.upgrades_updated.connect(_refresh_ui)

	# Initial refresh
	_refresh_ui()

	# Update progress every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_progress_bars)
	timer.autostart = true
	add_child(timer)

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 700)
	panel.position = Vector2(15, 50)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🔬 Software Upgrades"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(title_label)

	# Upgrade Slots (2 slots)
	for i in range(2):
		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = Vector2(320, 100)
		slot_panel.position = Vector2(20, 55 + i * 110)
		panel.add_child(slot_panel)

		var slot_dict = {
			"panel": slot_panel,
			"name_label": Label.new(),
			"progress_bar": ProgressBar.new(),
			"time_label": Label.new(),
			"cancel_button": Button.new(),
		}

		# Slot name label
		slot_dict["name_label"].text = "Slot %d: Empty" % (i + 1)
		slot_dict["name_label"].position = Vector2(10, 10)
		slot_dict["name_label"].add_theme_font_size_override("font_size", 14)
		slot_panel.add_child(slot_dict["name_label"])

		# Progress bar
		slot_dict["progress_bar"].position = Vector2(10, 35)
		slot_dict["progress_bar"].custom_minimum_size = Vector2(300, 20)
		slot_dict["progress_bar"].value = 0
		slot_dict["progress_bar"].max_value = 100
		slot_panel.add_child(slot_dict["progress_bar"])

		# Time remaining label
		slot_dict["time_label"].text = "Time: --"
		slot_dict["time_label"].position = Vector2(10, 60)
		slot_dict["time_label"].add_theme_font_size_override("font_size", 12)
		slot_panel.add_child(slot_dict["time_label"])

		slot_containers.append(slot_dict)

	# Completed upgrades count
	completed_label = Label.new()
	completed_label.position = Vector2(20, 280)
	completed_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(completed_label)

	# Available upgrades scroll container
	available_scroll = ScrollContainer.new()
	available_scroll.position = Vector2(20, 310)
	available_scroll.custom_minimum_size = Vector2(320, 360)
	panel.add_child(available_scroll)

	available_list = VBoxContainer.new()
	available_list.custom_minimum_size = Vector2(300, 0)
	available_scroll.add_child(available_list)

func _refresh_ui() -> void:
	_update_slots()
	_update_available_upgrades()
	_update_completed_count()

func _update_slots() -> void:
	for i in range(2):
		var slot = SoftwareUpgradeManager.active_upgrades[i]
		var ui = slot_containers[i]

		if slot == null:
			ui["name_label"].text = "Slot %d: Empty" % (i + 1)
			ui["progress_bar"].value = 0
			ui["time_label"].text = "Ready for new upgrade"
		else:
			var upgrade = SoftwareUpgradeManager.upgrade_tree[slot["id"]]
			ui["name_label"].text = "Slot %d: %s" % [i + 1, upgrade["name"]]

			var progress = SoftwareUpgradeManager.get_upgrade_progress(i)
			ui["progress_bar"].value = progress * 100

			var time_left = SoftwareUpgradeManager.get_upgrade_time_remaining(i)
			ui["time_label"].text = "Time: %s" % _format_time(time_left)

func _update_progress_bars() -> void:
	for i in range(2):
		var slot = SoftwareUpgradeManager.active_upgrades[i]
		if slot != null:
			var progress = SoftwareUpgradeManager.get_upgrade_progress(i)
			slot_containers[i]["progress_bar"].value = progress * 100

			var time_left = SoftwareUpgradeManager.get_upgrade_time_remaining(i)
			slot_containers[i]["time_label"].text = "Time: %s" % _format_time(time_left)

	# Check for completed upgrades
	SoftwareUpgradeManager.update_upgrades()

func _update_available_upgrades() -> void:
	# Clear existing buttons
	for child in available_list.get_children():
		child.queue_free()

	# Get available upgrades
	var available = []
	for upgrade_id in SoftwareUpgradeManager.unlocked_upgrades:
		if upgrade_id not in SoftwareUpgradeManager.completed_upgrades:
			available.append(upgrade_id)

	# Sort by tier
	available.sort_custom(func(a, b):
		var tier_a = SoftwareUpgradeManager.upgrade_tree[a].get("tier", 0)
		var tier_b = SoftwareUpgradeManager.upgrade_tree[b].get("tier", 0)
		return tier_a < tier_b
	)

	# Create buttons for each available upgrade
	for upgrade_id in available:
		var upgrade = SoftwareUpgradeManager.upgrade_tree[upgrade_id]

		var button = Button.new()
		button.custom_minimum_size = Vector2(300, 80)

		var name = upgrade["name"]
		var duration = _format_time(upgrade["duration"])
		var cost = upgrade.get("cost", {})
		var cost_str = ""
		if cost.get("fragments", 0) > 0:
			cost_str += "%d Fragments" % cost["fragments"]
		if cost.get("archive_tokens", 0) > 0:
			if cost_str != "":
				cost_str += ", "
			cost_str += "%d AT" % cost["archive_tokens"]

		var tier = upgrade.get("tier", 1)
		button.text = "[T%d] %s\n%s\nCost: %s" % [tier, name, duration, cost_str]

		var can_start = SoftwareUpgradeManager.can_start_upgrade(upgrade_id)
		button.disabled = not can_start

		button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id))

		available_list.add_child(button)

func _update_completed_count() -> void:
	var total = SoftwareUpgradeManager.upgrade_tree.size()
	var completed = SoftwareUpgradeManager.completed_upgrades.size()
	completed_label.text = "✓ Completed: %d / %d" % [completed, total]

func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	# Find first empty slot
	var slot_index = -1
	for i in range(2):
		if SoftwareUpgradeManager.active_upgrades[i] == null:
			slot_index = i
			break

	if slot_index == -1:
		print("⚠️ No empty slots available!")
		return

	if SoftwareUpgradeManager.start_upgrade(upgrade_id, slot_index):
		_refresh_ui()

func _on_upgrade_started(upgrade_id: String, slot_index: int) -> void:
	var upgrade = SoftwareUpgradeManager.upgrade_tree[upgrade_id]
	print("🔬 Started: %s in slot %d" % [upgrade["name"], slot_index])
	_refresh_ui()

func _on_upgrade_completed(upgrade_id: String) -> void:
	var upgrade = SoftwareUpgradeManager.upgrade_tree[upgrade_id]
	print("✅ Completed: %s" % upgrade["name"])
	_refresh_ui()

	# Show notification (you can make this fancier)
	if has_node("/root/Main/NotificationLabel"):
		var notif = get_node("/root/Main/NotificationLabel")
		notif.text = "✅ Upgrade Complete: %s" % upgrade["name"]

func _format_time(seconds: int) -> String:
	if seconds <= 0:
		return "Complete!"

	var days = seconds / 86400
	var hours = (seconds % 86400) / 3600
	var mins = (seconds % 3600) / 60

	if days > 0:
		return "%dd %dh" % [days, hours]
	elif hours > 0:
		return "%dh %dm" % [hours, mins]
	else:
		return "%dm" % mins

func _exit_tree() -> void:
	if SoftwareUpgradeManager:
		if SoftwareUpgradeManager.upgrade_started.is_connected(Callable(self, "_on_upgrade_started")):
			SoftwareUpgradeManager.upgrade_started.disconnect(Callable(self, "_on_upgrade_started"))
		if SoftwareUpgradeManager.upgrade_completed.is_connected(Callable(self, "_on_upgrade_completed")):
			SoftwareUpgradeManager.upgrade_completed.disconnect(Callable(self, "_on_upgrade_completed"))
		if SoftwareUpgradeManager.upgrades_updated.is_connected(Callable(self, "_refresh_ui")):
			SoftwareUpgradeManager.upgrades_updated.disconnect(Callable(self, "_refresh_ui"))
