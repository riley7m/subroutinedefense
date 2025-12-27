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

	# Could create a generic notification popup here
	print("%s %s: %s" % [icon, title, message])
