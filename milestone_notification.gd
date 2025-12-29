extends Control

# Milestone Notification Popup - Shows when milestones are unlocked/claimed

# UI Nodes
var panel: Panel
var icon_label: Label
var title_label: Label
var wave_label: Label
var rewards_label: RichTextLabel
var close_button: Button
var auto_dismiss_timer: Timer

# Animation
var animation_tween: Tween
const SLIDE_DURATION := 0.4
const AUTO_DISMISS_DELAY := 5.0  # Auto-close after 5 seconds

func _ready() -> void:
	# Start off-screen (above viewport)
	position = Vector2(15, -400)

	_create_ui()

	# Slide in animation
	_animate_in()

	# Auto-dismiss timer
	auto_dismiss_timer = Timer.new()
	auto_dismiss_timer.wait_time = AUTO_DISMISS_DELAY
	auto_dismiss_timer.one_shot = true
	auto_dismiss_timer.timeout.connect(_on_auto_dismiss)
	add_child(auto_dismiss_timer)
	auto_dismiss_timer.start()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 250)
	add_child(panel)

	# Large icon/emoji
	icon_label = Label.new()
	icon_label.text = "🎉"
	icon_label.position = Vector2(150, 15)
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(60, 60)
	panel.add_child(icon_label)

	# Title
	title_label = Label.new()
	title_label.text = "MILESTONE UNLOCKED!"
	title_label.position = Vector2(20, 85)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Wave info
	wave_label = Label.new()
	wave_label.text = "Wave 1000 Reached"
	wave_label.position = Vector2(20, 120)
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.custom_minimum_size = Vector2(320, 25)
	panel.add_child(wave_label)

	# Rewards
	rewards_label = RichTextLabel.new()
	rewards_label.position = Vector2(30, 150)
	rewards_label.custom_minimum_size = Vector2(300, 60)
	rewards_label.bbcode_enabled = true
	rewards_label.fit_content = true
	rewards_label.scroll_active = false
	panel.add_child(rewards_label)

	# Close button
	close_button = Button.new()
	close_button.text = "Claim Rewards"
	close_button.position = Vector2(110, 215)
	close_button.custom_minimum_size = Vector2(140, 30)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func show_milestone_notification(tier: int, wave: int, rewards: Dictionary) -> void:
	# Update labels
	wave_label.text = "Tier %d - Wave %d Reached!" % [tier, wave]

	# Format rewards
	var reward_parts = []

	if rewards.has("quantum_cores") and rewards["quantum_cores"] > 0:
		reward_parts.append("[color=cyan]+%s Quantum Cores 🔮[/color]" % NumberFormatter.format(rewards["quantum_cores"]))

	if rewards.has("fragments") and rewards["fragments"] > 0:
		reward_parts.append("[color=yellow]+%s Fragments 💎[/color]" % NumberFormatter.format(rewards["fragments"]))

	if rewards.has("data_disk"):
		reward_parts.append("[color=magenta]+1 Data Disk 📀[/color]")

	if rewards.has("lab_unlock"):
		reward_parts.append("[color=lime]+Lab Unlocked 🔬[/color]")

	if reward_parts.is_empty():
		rewards_label.text = "[center][b]No rewards for this milestone[/b][/center]"
	else:
		rewards_label.text = "[center][b]Rewards Claimed:[/b]\n" + "\n".join(reward_parts) + "[/center]"

func _animate_in() -> void:
	if animation_tween:
		animation_tween.kill()

	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.set_trans(Tween.TRANS_BACK)

	# Slide down from top
	animation_tween.tween_property(self, "position", Vector2(15, 50), SLIDE_DURATION)

func _animate_out() -> void:
	if animation_tween:
		animation_tween.kill()

	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_IN)
	animation_tween.set_trans(Tween.TRANS_BACK)

	# Slide up off screen
	animation_tween.tween_property(self, "position", Vector2(15, -400), SLIDE_DURATION)
	animation_tween.tween_callback(queue_free)

func _on_close_pressed() -> void:
	_animate_out()

func _on_auto_dismiss() -> void:
	_animate_out()
