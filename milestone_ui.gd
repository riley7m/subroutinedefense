extends Control

# Milestone UI - Battle Pass Style
# Shows progress through wave milestones and rewards (free + paid tracks)

# UI Nodes
var panel: Panel
var title_label: Label
var tier_info_label: Label
var paid_unlock_button: Button
var milestone_scroll: ScrollContainer
var milestone_list: VBoxContainer
var close_button: Button
var totals_label: Label

# Track current tier
var current_tier: int = 1

func _ready() -> void:
	_create_ui()

	# Connect signals
	if MilestoneManager:
		MilestoneManager.milestone_claimed.connect(_on_milestone_claimed)
		MilestoneManager.paid_track_unlocked.connect(_on_paid_track_unlocked)

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
	title_label.text = "🎖️ BATTLE PASS"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Tier info
	tier_info_label = Label.new()
	tier_info_label.text = "Tier 1 - Wave 1"
	tier_info_label.position = Vector2(20, 48)
	tier_info_label.add_theme_font_size_override("font_size", 14)
	tier_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_info_label.custom_minimum_size = Vector2(320, 25)
	panel.add_child(tier_info_label)

	# Paid unlock button
	paid_unlock_button = Button.new()
	paid_unlock_button.text = "🔓 Unlock Paid Track"
	paid_unlock_button.position = Vector2(70, 78)
	paid_unlock_button.custom_minimum_size = Vector2(220, 40)
	paid_unlock_button.pressed.connect(_on_paid_unlock_pressed)
	panel.add_child(paid_unlock_button)

	# Totals label
	totals_label = Label.new()
	totals_label.text = "Total: 5,000 🔮 + 50,000 💎 + 3 📀 + 6 🔬"
	totals_label.position = Vector2(20, 123)
	totals_label.add_theme_font_size_override("font_size", 11)
	totals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	totals_label.custom_minimum_size = Vector2(320, 20)
	panel.add_child(totals_label)

	# Milestone scroll container
	milestone_scroll = ScrollContainer.new()
	milestone_scroll.position = Vector2(10, 150)
	milestone_scroll.custom_minimum_size = Vector2(340, 545)
	panel.add_child(milestone_scroll)

	milestone_list = VBoxContainer.new()
	milestone_list.custom_minimum_size = Vector2(320, 0)
	milestone_scroll.add_child(milestone_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 705)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _refresh_ui() -> void:
	if not TierManager or not MilestoneManager:
		return

	current_tier = TierManager.get_current_tier()
	var current_wave = TierManager.get_highest_wave_in_tier(current_tier)
	var is_paid = MilestoneManager.is_paid_track_unlocked(current_tier)

	# Update tier info
	tier_info_label.text = "Tier %d - Wave %d" % [current_tier, current_wave]

	# Update paid unlock button
	if is_paid:
		paid_unlock_button.text = "✅ Paid Track Active"
		paid_unlock_button.disabled = true
	else:
		paid_unlock_button.text = "🔓 Unlock Paid Track (Coming Soon)"
		paid_unlock_button.disabled = false  # Will show payment UI when implemented

	# Update totals
	var totals = MilestoneManager.get_total_rewards_for_tier(current_tier)
	totals_label.text = "Total: %s 🔮 + %s 💎 + %d 📀 + %d 🔬" % [
		NumberFormatter.format(totals["total_quantum_cores"]),
		NumberFormatter.format(totals["total_fragments"]),
		totals["total_data_disks"],
		totals["lab_unlocks"]
	]

	# Clear existing milestone widgets
	for child in milestone_list.get_children():
		child.queue_free()

	# Create milestone widgets
	var milestones = MilestoneManager.get_all_milestones_for_tier(current_tier)
	for milestone_data in milestones:
		_create_milestone_widget(milestone_data, current_wave, is_paid)

func _create_milestone_widget(milestone_data: Dictionary, current_wave: int, is_paid_unlocked: bool) -> void:
	var wave = milestone_data["wave"]
	var free_rewards = milestone_data["free_rewards"]
	var paid_rewards = milestone_data["paid_rewards"]
	var free_claimed = milestone_data["free_claimed"]
	var paid_claimed = milestone_data["paid_claimed"]

	# Container for this milestone
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(320, 90)
	milestone_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Wave header
	var wave_label = Label.new()
	wave_label.text = "Wave %d" % wave
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(wave_label)

	# Progress indicator
	var reached = current_wave >= wave
	var progress_label = Label.new()
	if reached:
		progress_label.text = "✅ Reached"
	else:
		progress_label.text = "🔒 Not Reached (%d/%d)" % [current_wave, wave]
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(progress_label)

	# Free track rewards + button
	var free_hbox = HBoxContainer.new()
	vbox.add_child(free_hbox)

	var free_label = Label.new()
	free_label.text = "FREE: " + _format_rewards(free_rewards)
	free_label.add_theme_font_size_override("font_size", 10)
	free_label.custom_minimum_size = Vector2(200, 20)
	free_hbox.add_child(free_label)

	var free_claim_button = Button.new()
	free_claim_button.custom_minimum_size = Vector2(80, 25)
	if free_claimed:
		free_claim_button.text = "✅ Claimed"
		free_claim_button.disabled = true
	elif reached:
		free_claim_button.text = "Claim"
		free_claim_button.pressed.connect(_on_claim_pressed.bind(current_tier, wave, false))
	else:
		free_claim_button.text = "Locked"
		free_claim_button.disabled = true
	free_hbox.add_child(free_claim_button)

	# Paid track rewards + button
	var paid_hbox = HBoxContainer.new()
	vbox.add_child(paid_hbox)

	var paid_label = Label.new()
	paid_label.text = "PAID: " + _format_rewards(paid_rewards)
	paid_label.add_theme_font_size_override("font_size", 10)
	paid_label.custom_minimum_size = Vector2(200, 20)
	paid_hbox.add_child(paid_label)

	var paid_claim_button = Button.new()
	paid_claim_button.custom_minimum_size = Vector2(80, 25)
	if not is_paid_unlocked:
		paid_claim_button.text = "🔒 Locked"
		paid_claim_button.disabled = true
	elif paid_claimed:
		paid_claim_button.text = "✅ Claimed"
		paid_claim_button.disabled = true
	elif reached:
		paid_claim_button.text = "Claim"
		paid_claim_button.pressed.connect(_on_claim_pressed.bind(current_tier, wave, true))
	else:
		paid_claim_button.text = "Locked"
		paid_claim_button.disabled = true
	paid_hbox.add_child(paid_claim_button)

func _format_rewards(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return "None"

	var parts = []

	if rewards.has("quantum_cores") and rewards["quantum_cores"] > 0:
		parts.append("%s 🔮" % NumberFormatter.format(rewards["quantum_cores"]))

	if rewards.has("fragments") and rewards["fragments"] > 0:
		parts.append("%s 💎" % NumberFormatter.format(rewards["fragments"]))

	if rewards.has("data_disk"):
		parts.append("1 📀")

	if rewards.has("lab_unlock"):
		parts.append("🔬 Lab")

	if parts.is_empty():
		return "None"

	return " + ".join(parts)

func _on_claim_pressed(tier: int, wave: int, is_paid: bool) -> void:
	if MilestoneManager.claim_milestone(tier, wave, is_paid):
		_refresh_ui()

func _on_milestone_claimed(tier: int, wave: int, is_paid: bool) -> void:
	_refresh_ui()

func _on_paid_track_unlocked(tier: int) -> void:
	_refresh_ui()

func _on_paid_unlock_pressed() -> void:
	# Show payment UI
	var payment_ui = load("res://paid_track_purchase_ui.gd").new()
	get_parent().add_child(payment_ui)
	payment_ui.purchase_confirmed.connect(_on_purchase_confirmed)
	payment_ui.purchase_cancelled.connect(_on_purchase_cancelled)
	payment_ui.show_purchase_dialog(current_tier)

func _on_purchase_confirmed(tier: int) -> void:
	print("✅ Paid track unlocked for tier %d" % tier)
	_refresh_ui()

func _on_purchase_cancelled() -> void:
	print("❌ Purchase cancelled")

func _on_close_pressed() -> void:
	visible = false

func _exit_tree() -> void:
	# Disconnect signals
	if MilestoneManager:
		if MilestoneManager.milestone_claimed.is_connected(Callable(self, "_on_milestone_claimed")):
			MilestoneManager.milestone_claimed.disconnect(Callable(self, "_on_milestone_claimed"))
		if MilestoneManager.paid_track_unlocked.is_connected(Callable(self, "_on_paid_track_unlocked")):
			MilestoneManager.paid_track_unlocked.disconnect(Callable(self, "_on_paid_track_unlocked"))
