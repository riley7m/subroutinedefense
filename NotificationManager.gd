extends Node

# Notification Manager - Shows popup notifications for various game events
# Handles milestone unlocks, data disk acquisitions, etc.

# Reference to the UI root (set by main_hud or main scene)
var ui_root: Control = null

func _ready() -> void:
	# Connect to milestone signals
	if MilestoneManager:
		MilestoneManager.milestone_reached.connect(_on_milestone_reached)

	# Connect to data disk signals
	if DataDiskManager:
		DataDiskManager.data_disk_acquired.connect(_on_data_disk_acquired)

func set_ui_root(root: Control) -> void:
	ui_root = root

func _on_milestone_reached(tier: int, wave: int, rewards: Dictionary) -> void:
	if not ui_root:
		print("⚠️ NotificationManager: UI root not set, cannot show notification")
		return

	# Create and show milestone notification
	var notification = load("res://milestone_notification.gd").new()
	ui_root.add_child(notification)
	notification.show_milestone_notification(tier, wave, rewards)

func _on_data_disk_acquired(disk_id: String) -> void:
	# Simple print for now - could create a data disk notification popup later
	var disk_data = DataDiskManager.DATA_DISK_TYPES.get(disk_id, {})
	if not disk_data.is_empty():
		print("📀 ACQUIRED: %s - %s" % [disk_data["name"], disk_data["description"]])

func show_custom_notification(title: String, message: String, icon: String = "ℹ️") -> void:
	if not ui_root:
		print("⚠️ NotificationManager: UI root not set")
		return

	# Create generic notification popup
	var notification = _create_notification_popup(title, message, icon)
	ui_root.add_child(notification)

func _create_notification_popup(title: String, message: String, icon: String) -> Control:
	# Create notification container
	var container = Control.new()
	container.position = Vector2(15, -300)  # Start off-screen
	container.z_index = 100  # Ensure it's on top

	# Main panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 180)
	container.add_child(panel)

	# Icon
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.position = Vector2(150, 15)
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(60, 60)
	panel.add_child(icon_label)

	# Title
	var title_label = Label.new()
	title_label.text = title
	title_label.position = Vector2(20, 85)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Message
	var message_label = Label.new()
	message_label.text = message
	message_label.position = Vector2(20, 120)
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.custom_minimum_size = Vector2(320, 40)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(message_label)

	# Apply theme
	if UIStyler:
		UIStyler.apply_theme_to_node(container)

	# Animate in
	var tween = container.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(container, "position", Vector2(15, 50), 0.4)

	# Auto-dismiss after 4 seconds
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(func():
		var out_tween = container.create_tween()
		out_tween.set_ease(Tween.EASE_IN)
		out_tween.set_trans(Tween.TRANS_BACK)
		out_tween.tween_property(container, "position", Vector2(15, -300), 0.4)
		out_tween.tween_callback(container.queue_free)
	)
	container.add_child(timer)
	timer.start()

	return container
