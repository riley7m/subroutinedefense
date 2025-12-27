extends Control

# Paid Track Purchase UI - Fragment-based battle pass unlock

signal purchase_confirmed(tier: int)
signal purchase_cancelled

# UI Nodes
var overlay: ColorRect
var panel: Panel
var title_label: Label
var description_label: RichTextLabel
var cost_label: Label
var confirm_button: Button
var cancel_button: Button

# Purchase data
var tier_to_unlock: int = 1
var fragment_cost: int = 10000  # Base cost for tier 1

# Tier scaling for cost
const BASE_COST := 10000  # Tier 1 base cost
const COST_SCALING := 1.25  # 25% increase per tier

func _ready() -> void:
	_create_ui()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Full screen overlay (semi-transparent)
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Center panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(340, 350)
	panel.position = Vector2(25, 250)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🔓 UNLOCK PAID TRACK"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(300, 30)
	panel.add_child(title_label)

	# Description
	description_label = RichTextLabel.new()
	description_label.position = Vector2(20, 55)
	description_label.custom_minimum_size = Vector2(300, 150)
	description_label.bbcode_enabled = true
	description_label.fit_content = true
	description_label.scroll_active = false
	panel.add_child(description_label)

	# Cost label
	cost_label = Label.new()
	cost_label.position = Vector2(20, 215)
	cost_label.add_theme_font_size_override("font_size", 18)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.custom_minimum_size = Vector2(300, 30)
	panel.add_child(cost_label)

	# Confirm button
	confirm_button = Button.new()
	confirm_button.text = "Purchase"
	confirm_button.position = Vector2(40, 260)
	confirm_button.custom_minimum_size = Vector2(130, 50)
	confirm_button.pressed.connect(_on_confirm_pressed)
	panel.add_child(confirm_button)

	# Cancel button
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.position = Vector2(180, 260)
	cancel_button.custom_minimum_size = Vector2(130, 50)
	cancel_button.pressed.connect(_on_cancel_pressed)
	panel.add_child(cancel_button)

func show_purchase_dialog(tier: int) -> void:
	tier_to_unlock = tier
	fragment_cost = _calculate_cost(tier)

	# Update UI
	title_label.text = "🔓 UNLOCK TIER %d PAID TRACK" % tier

	# Get rewards info
	var rewards = MilestoneManager.get_total_rewards_for_tier(tier)

	description_label.text = """[b]Unlock the paid track to claim:[/b]

• [color=cyan]%s Quantum Cores[/color] 🔮
• [color=yellow]%s Fragments[/color] 💎
• [color=magenta]%d Data Disks[/color] 📀

[b]Plus all future paid rewards in this tier![/b]

This unlock is [b]permanent[/b] for Tier %d.""" % [
		NumberFormatter.format(rewards["paid_quantum_cores"]),
		NumberFormatter.format(rewards["paid_fragments"]),
		rewards["paid_data_disks"],
		tier
	]

	# Update cost
	var current_fragments = RewardManager.fragments
	var can_afford = current_fragments >= fragment_cost

	if can_afford:
		cost_label.text = "Cost: %s / %s 💎" % [
			NumberFormatter.format(fragment_cost),
			NumberFormatter.format(current_fragments)
		]
		confirm_button.disabled = false
	else:
		cost_label.text = "[color=red]Cost: %s 💎 (Need %s more)[/color]" % [
			NumberFormatter.format(fragment_cost),
			NumberFormatter.format(fragment_cost - current_fragments)
		]
		confirm_button.disabled = true

	visible = true

func _calculate_cost(tier: int) -> int:
	# Cost scales with tier: 10k, 12.5k, 15.6k, 19.5k, etc.
	return int(BASE_COST * pow(COST_SCALING, tier - 1))

func _on_confirm_pressed() -> void:
	# Double check they can afford it
	if RewardManager.fragments < fragment_cost:
		print("⚠️ Not enough fragments!")
		return

	# Spend fragments
	RewardManager.fragments -= fragment_cost
	print("💎 Spent %d fragments to unlock Tier %d paid track" % [fragment_cost, tier_to_unlock])

	# Unlock the paid track
	if MilestoneManager.unlock_paid_track(tier_to_unlock):
		emit_signal("purchase_confirmed", tier_to_unlock)
		queue_free()
	else:
		# Refund if unlock failed
		RewardManager.fragments += fragment_cost
		print("❌ Failed to unlock paid track, fragments refunded")

func _on_cancel_pressed() -> void:
	emit_signal("purchase_cancelled")
	queue_free()
