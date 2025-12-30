extends Control

# Drone Upgrade UI
# Shows upgrade options for all 4 drones (Flame, Poison, Frost, Shock)

# UI Nodes
var panel: Panel
var title_label: Label
var fragments_label: Label
var close_button: Button

# Active Slots Section
var slots_panel: Panel
var slots_title: Label
var slot_buttons: Array = []

# Drone Selection Tabs
var tab_container: Control
var tab_buttons: Array = []
var current_drone: String = "flame"

# Upgrade Scroll Area
var upgrade_scroll: ScrollContainer
var upgrade_list: VBoxContainer

# Drone display names and icons
const DRONE_INFO := {
	"flame": {"name": "Flame Drone", "icon": "🔥"},
	"poison": {"name": "Poison Drone", "icon": "☠️"},
	"frost": {"name": "Frost Drone", "icon": "❄️"},
	"shock": {"name": "Shock Drone", "icon": "⚡"}
}

func _ready() -> void:
	_create_ui()

	# Connect signals
	if DroneUpgradeManager:
		DroneUpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
		DroneUpgradeManager.active_slot_unlocked.connect(_on_slot_unlocked)

	# Initial refresh
	_refresh_ui()

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
	title_label.text = "🚁 DRONE UPGRADES"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Fragments display
	fragments_label = Label.new()
	fragments_label.text = "Fragments: 0 💎"
	fragments_label.position = Vector2(20, 48)
	fragments_label.add_theme_font_size_override("font_size", 14)
	fragments_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fragments_label.custom_minimum_size = Vector2(320, 25)
	panel.add_child(fragments_label)

	# Active Slots Panel
	slots_panel = Panel.new()
	slots_panel.custom_minimum_size = Vector2(320, 80)
	slots_panel.position = Vector2(20, 80)
	panel.add_child(slots_panel)

	slots_title = Label.new()
	slots_title.text = "Active Drone Slots"
	slots_title.position = Vector2(10, 8)
	slots_title.add_theme_font_size_override("font_size", 14)
	slots_panel.add_child(slots_title)

	# Create slot buttons (4 total: 1 default + 3 unlockable)
	for i in range(4):
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(70, 40)
		slot_button.position = Vector2(10 + i * 77, 32)

		if i == 0:
			slot_button.text = "Slot 1\n✅"
			slot_button.disabled = true
		else:
			slot_button.text = "Slot %d\n🔒" % (i + 1)
			slot_button.pressed.connect(_on_slot_unlock_pressed.bind(i + 1))

		slots_panel.add_child(slot_button)
		slot_buttons.append(slot_button)

	# Drone Selection Tabs
	tab_container = Control.new()
	tab_container.position = Vector2(20, 170)
	tab_container.custom_minimum_size = Vector2(320, 45)
	panel.add_child(tab_container)

	var tab_names = ["flame", "poison", "frost", "shock"]
	for i in range(4):
		var drone_type = tab_names[i]
		var tab_button = Button.new()
		tab_button.custom_minimum_size = Vector2(75, 40)
		tab_button.position = Vector2(i * 80, 0)
		tab_button.text = DRONE_INFO[drone_type]["icon"]
		tab_button.pressed.connect(_on_tab_pressed.bind(drone_type))
		tab_container.add_child(tab_button)
		tab_buttons.append({"button": tab_button, "drone": drone_type})

	# Upgrade scroll area
	upgrade_scroll = ScrollContainer.new()
	upgrade_scroll.position = Vector2(20, 225)
	upgrade_scroll.custom_minimum_size = Vector2(320, 490)
	panel.add_child(upgrade_scroll)

	upgrade_list = VBoxContainer.new()
	upgrade_list.custom_minimum_size = Vector2(300, 0)
	upgrade_scroll.add_child(upgrade_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _refresh_ui() -> void:
	if not DroneUpgradeManager or not RewardManager:
		return

	# Update fragments display
	var fragments = RewardManager.fragments
	fragments_label.text = "Fragments: %s 💎" % NumberFormatter.format(fragments)

	# Update active slots
	_update_slot_buttons()

	# Update tab button styles
	_update_tab_styles()

	# Update upgrade list for current drone
	_update_upgrade_list()

func _update_slot_buttons() -> void:
	var active_slots = DroneUpgradeManager.active_drone_slots

	for i in range(4):
		var slot_num = i + 1
		var button = slot_buttons[i]

		if slot_num == 1:
			# Slot 1 always unlocked
			button.text = "Slot 1\n✅"
			button.disabled = true
		elif slot_num <= active_slots:
			# Slot unlocked
			button.text = "Slot %d\n✅" % slot_num
			button.disabled = true
		else:
			# Slot locked
			var cost = DroneUpgradeManager.ACTIVE_SLOT_COSTS[slot_num]
			button.text = "Slot %d\n🔒 %s" % [slot_num, NumberFormatter.format(cost)]
			button.disabled = false

func _update_tab_styles() -> void:
	for tab_data in tab_buttons:
		var button = tab_data["button"]
		var drone = tab_data["drone"]

		if drone == current_drone:
			# Highlight selected tab
			button.text = "%s\n▼" % DRONE_INFO[drone]["icon"]
		else:
			button.text = DRONE_INFO[drone]["icon"]

func _update_upgrade_list() -> void:
	# Clear existing widgets
	for child in upgrade_list.get_children():
		child.queue_free()

	# Add title for current drone
	var drone_title = Label.new()
	drone_title.text = "%s %s" % [DRONE_INFO[current_drone]["icon"], DRONE_INFO[current_drone]["name"]]
	drone_title.add_theme_font_size_override("font_size", 18)
	drone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drone_title.custom_minimum_size = Vector2(360, 30)
	upgrade_list.add_child(drone_title)

	# Add drone level upgrade
	_add_drone_level_widget()

	# Add separator
	var separator1 = HSeparator.new()
	separator1.custom_minimum_size = Vector2(360, 10)
	upgrade_list.add_child(separator1)

	# Add specific upgrades based on drone type
	match current_drone:
		"flame":
			_add_flame_upgrades()
		"poison":
			_add_poison_upgrades()
		"frost":
			_add_frost_upgrades()
		"shock":
			_add_shock_upgrades()

func _add_drone_level_widget() -> void:
	var current_level = DroneUpgradeManager.drone_levels[current_drone]
	var max_level = 10

	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(360, 90)
	upgrade_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Level display
	var level_label = Label.new()
	level_label.text = "Drone Level: %d / %d" % [current_level, max_level]
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = "Increases base power and effectiveness"
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Upgrade button
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(200, 35)

	if current_level >= max_level:
		upgrade_button.text = "✅ MAXED"
		upgrade_button.disabled = true
	else:
		var next_level = current_level + 1
		var cost = DroneUpgradeManager.DRONE_LEVEL_COSTS[next_level]
		var can_afford = RewardManager.fragments >= cost

		upgrade_button.text = "Upgrade to Level %d\nCost: %s 💎" % [next_level, NumberFormatter.format(cost)]
		upgrade_button.disabled = not can_afford
		upgrade_button.pressed.connect(_on_level_upgrade_pressed.bind(current_drone))

	hbox.add_child(upgrade_button)

func _add_flame_upgrades() -> void:
	var tick_rate_level = DroneUpgradeManager.flame_tick_rate_level
	var hp_cap_level = DroneUpgradeManager.flame_hp_cap_level

	# Tick Rate Upgrade
	_add_upgrade_widget(
		"Burn Tick Rate",
		"Reduces time between burn damage ticks",
		tick_rate_level,
		10,
		DroneUpgradeManager.FLAME_TICK_RATE_COSTS,
		"1.0s → 0.5s",
		"flame_tick_rate"
	)

	# HP Cap Upgrade
	_add_upgrade_widget(
		"Burn HP Cap",
		"Increases max damage per tick",
		hp_cap_level,
		10,
		DroneUpgradeManager.FLAME_HP_CAP_COSTS,
		"10% → 25% max HP",
		"flame_hp_cap"
	)

func _add_poison_upgrades() -> void:
	var duration_level = DroneUpgradeManager.poison_duration_level
	var stacking_level = DroneUpgradeManager.poison_stacking_level

	# Duration Upgrade
	_add_upgrade_widget(
		"Poison Duration",
		"Extends poison effect duration",
		duration_level,
		10,
		DroneUpgradeManager.POISON_DURATION_COSTS,
		"4s → 6s",
		"poison_duration"
	)

	# Stacking Upgrade (single unlock)
	var stacking_unlocked = stacking_level >= 1
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(360, 80)
	upgrade_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	var title = Label.new()
	title.text = "Poison Stacking"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Allows 2 poison stacks on same enemy"
	desc.add_theme_font_size_override("font_size", 11)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 30)

	if stacking_unlocked:
		button.text = "✅ UNLOCKED"
		button.disabled = true
	else:
		var cost = DroneUpgradeManager.POISON_STACKING_COSTS[1]
		var can_afford = RewardManager.fragments >= cost
		button.text = "Unlock\nCost: %s 💎" % NumberFormatter.format(cost)
		button.disabled = not can_afford
		button.pressed.connect(_on_specific_upgrade_pressed.bind("poison_stacking"))

	hbox.add_child(button)

func _add_frost_upgrades() -> void:
	var aoe_level = DroneUpgradeManager.frost_aoe_level
	var duration_level = DroneUpgradeManager.frost_duration_level

	# AOE Upgrade (single unlock)
	var aoe_unlocked = aoe_level >= 1
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(360, 80)
	upgrade_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	var title = Label.new()
	title.text = "Frost AOE"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Slows 2 enemies instead of 1"
	desc.add_theme_font_size_override("font_size", 11)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 30)

	if aoe_unlocked:
		button.text = "✅ UNLOCKED"
		button.disabled = true
	else:
		var cost = DroneUpgradeManager.FROST_AOE_COSTS[1]
		var can_afford = RewardManager.fragments >= cost
		button.text = "Unlock\nCost: %s 💎" % NumberFormatter.format(cost)
		button.disabled = not can_afford
		button.pressed.connect(_on_specific_upgrade_pressed.bind("frost_aoe"))

	hbox.add_child(button)

	# Duration Upgrade
	_add_upgrade_widget(
		"Frost Duration",
		"Extends slow effect duration",
		duration_level,
		10,
		DroneUpgradeManager.FROST_DURATION_COSTS,
		"2s → 2.5s",
		"frost_duration"
	)

func _add_shock_upgrades() -> void:
	var chain_level = DroneUpgradeManager.shock_chain_level
	var duration_level = DroneUpgradeManager.shock_duration_level

	# Chain Upgrade (single unlock)
	var chain_unlocked = chain_level >= 1
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(360, 80)
	upgrade_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	var title = Label.new()
	title.text = "Shock Chain"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Stuns 2 enemies instead of 1"
	desc.add_theme_font_size_override("font_size", 11)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 30)

	if chain_unlocked:
		button.text = "✅ UNLOCKED"
		button.disabled = true
	else:
		var cost = DroneUpgradeManager.SHOCK_CHAIN_COSTS[1]
		var can_afford = RewardManager.fragments >= cost
		button.text = "Unlock\nCost: %s 💎" % NumberFormatter.format(cost)
		button.disabled = not can_afford
		button.pressed.connect(_on_specific_upgrade_pressed.bind("shock_chain"))

	hbox.add_child(button)

	# Duration Upgrade
	_add_upgrade_widget(
		"Shock Duration",
		"Adds bonus stun duration",
		duration_level,
		10,
		DroneUpgradeManager.SHOCK_DURATION_COSTS,
		"+0s → +0.5s bonus",
		"shock_duration"
	)

func _add_upgrade_widget(title: String, description: String, current_level: int, max_level: int, cost_dict: Dictionary, effect_range: String, upgrade_id: String) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(360, 90)
	upgrade_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Title
	var title_label = Label.new()
	title_label.text = "%s: %d / %d" % [title, current_level, max_level]
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Description + effect range
	var desc_label = Label.new()
	desc_label.text = "%s (%s)" % [description, effect_range]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Upgrade button
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var upgrade_button = Button.new()
	upgrade_button.custom_minimum_size = Vector2(200, 35)

	if current_level >= max_level:
		upgrade_button.text = "✅ MAXED"
		upgrade_button.disabled = true
	else:
		var next_level = current_level + 1
		var cost = cost_dict[next_level]
		var can_afford = RewardManager.fragments >= cost

		upgrade_button.text = "Upgrade to Level %d\nCost: %s 💎" % [next_level, NumberFormatter.format(cost)]
		upgrade_button.disabled = not can_afford
		upgrade_button.pressed.connect(_on_specific_upgrade_pressed.bind(upgrade_id))

	hbox.add_child(upgrade_button)

func _on_tab_pressed(drone_type: String) -> void:
	current_drone = drone_type
	_refresh_ui()

func _on_slot_unlock_pressed(slot_num: int) -> void:
	if DroneUpgradeManager.unlock_active_slot(slot_num):
		print("✅ Unlocked drone slot %d" % slot_num)
		_refresh_ui()
	else:
		print("❌ Cannot unlock slot %d (insufficient fragments)" % slot_num)

func _on_level_upgrade_pressed(drone_type: String) -> void:
	if DroneUpgradeManager.upgrade_drone_level(drone_type):
		var new_level = DroneUpgradeManager.drone_levels[drone_type]
		print("✅ %s upgraded to level %d" % [DRONE_INFO[drone_type]["name"], new_level])
		_refresh_ui()

func _on_specific_upgrade_pressed(upgrade_id: String) -> void:
	var success = false

	match upgrade_id:
		"flame_tick_rate":
			success = DroneUpgradeManager.upgrade_flame_tick_rate()
		"flame_hp_cap":
			success = DroneUpgradeManager.upgrade_flame_hp_cap()
		"poison_duration":
			success = DroneUpgradeManager.upgrade_poison_duration()
		"poison_stacking":
			success = DroneUpgradeManager.upgrade_poison_stacking()
		"frost_aoe":
			success = DroneUpgradeManager.upgrade_frost_aoe()
		"frost_duration":
			success = DroneUpgradeManager.upgrade_frost_duration()
		"shock_chain":
			success = DroneUpgradeManager.upgrade_shock_chain()
		"shock_duration":
			success = DroneUpgradeManager.upgrade_shock_duration()

	if success:
		print("✅ Upgrade purchased: %s" % upgrade_id)
		_refresh_ui()

func _on_upgrade_purchased(upgrade_type: String, drone_type: String, new_level: int) -> void:
	_refresh_ui()

func _on_slot_unlocked(slot_number: int) -> void:
	_refresh_ui()

func _on_close_pressed() -> void:
	visible = false

func _exit_tree() -> void:
	# Disconnect signals
	if DroneUpgradeManager:
		if DroneUpgradeManager.upgrade_purchased.is_connected(Callable(self, "_on_upgrade_purchased")):
			DroneUpgradeManager.upgrade_purchased.disconnect(Callable(self, "_on_upgrade_purchased"))
		if DroneUpgradeManager.active_slot_unlocked.is_connected(Callable(self, "_on_slot_unlocked")):
			DroneUpgradeManager.active_slot_unlocked.disconnect(Callable(self, "_on_slot_unlocked"))
