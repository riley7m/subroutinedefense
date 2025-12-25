extends Control

# Offline progress data
var waves_cleared: int = 0
var dc_earned: int = 0
var at_earned: int = 0
var time_away: float = 0.0
var watched_ad: bool = false

# UI Nodes (will be created dynamically)
var panel: Panel
var title_label: Label
var time_label: Label
var waves_label: Label
var dc_label: Label
var at_label: Label
var claim_button: Button
var ad_button: Button
var bg_overlay: ColorRect

func _ready() -> void:
	# Create dark overlay background
	bg_overlay = ColorRect.new()
	bg_overlay.color = Color(0, 0, 0, 0.7)
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_overlay)

	# Create panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 400)
	panel.position = Vector2(20, 100)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🌙 Welcome Back!"
	title_label.position = Vector2(20, 20)
	title_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(title_label)

	# Time away
	time_label = Label.new()
	time_label.position = Vector2(20, 60)
	time_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(time_label)

	# Waves cleared
	waves_label = Label.new()
	waves_label.position = Vector2(20, 100)
	waves_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(waves_label)

	# DC earned
	dc_label = Label.new()
	dc_label.position = Vector2(20, 140)
	dc_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(dc_label)

	# AT earned
	at_label = Label.new()
	at_label.position = Vector2(20, 180)
	at_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(at_label)

	# Ad button (watch ad for 2x rewards)
	ad_button = Button.new()
	ad_button.text = "📺 Watch Ad for 2x Rewards (50%)"
	ad_button.position = Vector2(20, 240)
	ad_button.custom_minimum_size = Vector2(310, 50)
	ad_button.pressed.connect(_on_ad_button_pressed)
	panel.add_child(ad_button)

	# Claim button
	claim_button = Button.new()
	claim_button.text = "Claim Rewards (25%)"
	claim_button.position = Vector2(20, 310)
	claim_button.custom_minimum_size = Vector2(310, 50)
	claim_button.pressed.connect(_on_claim_button_pressed)
	panel.add_child(claim_button)

	# Apply cyber theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

	# Hide by default
	visible = false

	# Connect to RewardManager signal
	if RewardManager:
		if not RewardManager.offline_progress_calculated.is_connected(Callable(self, "_on_offline_progress_calculated")):
			RewardManager.offline_progress_calculated.connect(_on_offline_progress_calculated)

func _on_offline_progress_calculated(waves: int, dc: int, at: int, duration: float) -> void:
	# Store data
	waves_cleared = waves
	dc_earned = dc
	at_earned = at
	time_away = duration

	# Only show if there's meaningful progress
	if waves_cleared > 0:
		_update_labels()
		visible = true

func _update_labels() -> void:
	# Format time away
	var hours = int(time_away / 3600)
	var minutes = int((time_away - hours * 3600) / 60)
	var time_str = ""
	if hours > 0:
		time_str = "%dh %dm" % [hours, minutes]
	else:
		time_str = "%dm" % minutes

	time_label.text = "Time away: %s" % time_str
	waves_label.text = "Waves cleared: %d" % waves_cleared

	# Show current rewards (25% efficiency)
	dc_label.text = "Data Credits: +%d" % dc_earned
	at_label.text = "Archive Tokens: +%d" % at_earned

func _on_ad_button_pressed() -> void:
	# Recalculate with 50% efficiency
	watched_ad = true
	RewardManager.calculate_offline_progress(true)

	# Double the rewards display
	dc_earned = RewardManager.offline_dc
	at_earned = RewardManager.offline_at

	_update_labels()

	# Update button text
	claim_button.text = "Claim Rewards (50%)"
	ad_button.disabled = true
	ad_button.text = "✓ Ad Watched - Rewards Doubled!"

	print("📺 Ad watched! Rewards doubled to 50% efficiency")

func _on_claim_button_pressed() -> void:
	# Apply the rewards
	RewardManager.apply_offline_rewards()

	# Close popup
	visible = false

	print("✓ Offline rewards claimed!")

func _exit_tree() -> void:
	# Disconnect signal
	if RewardManager and RewardManager.offline_progress_calculated.is_connected(Callable(self, "_on_offline_progress_calculated")):
		RewardManager.offline_progress_calculated.disconnect(Callable(self, "_on_offline_progress_calculated"))
