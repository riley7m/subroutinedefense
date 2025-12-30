extends Control

# Permanent Upgrades UI
# Shows all permanent upgrades purchasable with Archive Tokens (AT)

# UI Nodes
var panel: Panel
var title_label: Label
var at_label: Label
var tab_container: Control
var scroll_container: ScrollContainer
var upgrade_list: VBoxContainer
var close_button: Button

# Tab buttons
var offense_tab: Button
var defense_tab: Button
var economy_tab: Button
var special_tab: Button
var current_tab: String = "offense"

func _ready() -> void:
	_create_ui()
	_refresh_ui()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Main panel (fits 390px mobile screen)
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 780)
	panel.position = Vector2(15, 50)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "⬆️ PERMANENT UPGRADES"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# AT display
	at_label = Label.new()
	at_label.text = "📦 0 AT Available"
	at_label.position = Vector2(20, 48)
	at_label.add_theme_font_size_override("font_size", 14)
	at_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	at_label.custom_minimum_size = Vector2(320, 25)
	panel.add_child(at_label)

	# Category tabs
	_create_tabs()

	# Scroll area for upgrades
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(20, 130)
	scroll_container.custom_minimum_size = Vector2(320, 585)
	panel.add_child(scroll_container)

	upgrade_list = VBoxContainer.new()
	upgrade_list.custom_minimum_size = Vector2(300, 0)
	scroll_container.add_child(upgrade_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _create_tabs() -> void:
	# Tab buttons (80px wide each, 4 tabs)
	var tab_y = 80
	var tab_width = 75
	var tab_spacing = 5

	offense_tab = Button.new()
	offense_tab.text = "⚔️"
	offense_tab.position = Vector2(20, tab_y)
	offense_tab.custom_minimum_size = Vector2(tab_width, 40)
	offense_tab.pressed.connect(func(): _switch_tab("offense"))
	panel.add_child(offense_tab)

	defense_tab = Button.new()
	defense_tab.text = "🛡️"
	defense_tab.position = Vector2(20 + tab_width + tab_spacing, tab_y)
	defense_tab.custom_minimum_size = Vector2(tab_width, 40)
	defense_tab.pressed.connect(func(): _switch_tab("defense"))
	panel.add_child(defense_tab)

	economy_tab = Button.new()
	economy_tab.text = "💰"
	economy_tab.position = Vector2(20 + (tab_width + tab_spacing) * 2, tab_y)
	economy_tab.custom_minimum_size = Vector2(tab_width, 40)
	economy_tab.pressed.connect(func(): _switch_tab("economy"))
	panel.add_child(economy_tab)

	special_tab = Button.new()
	special_tab.text = "⭐"
	special_tab.position = Vector2(20 + (tab_width + tab_spacing) * 3, tab_y)
	special_tab.custom_minimum_size = Vector2(tab_width, 40)
	special_tab.pressed.connect(func(): _switch_tab("special"))
	panel.add_child(special_tab)

func _switch_tab(tab: String) -> void:
	current_tab = tab
	_refresh_ui()

func _refresh_ui() -> void:
	if not RewardManager or not UpgradeManager:
		return

	# Update AT display
	at_label.text = "📦 %s AT Available" % NumberFormatter.format(RewardManager.archive_tokens)

	# Clear existing upgrade widgets
	for child in upgrade_list.get_children():
		child.queue_free()

	# Load upgrades for current tab
	match current_tab:
		"offense":
			_add_offense_upgrades()
		"defense":
			_add_defense_upgrades()
		"economy":
			_add_economy_upgrades()
		"special":
			_add_special_upgrades()

func _add_offense_upgrades() -> void:
	_create_upgrade_widget(
		"Projectile Damage",
		"⚔️",
		"+10 damage per level",
		RewardManager.perm_projectile_damage,
		"projectile_damage"
	)

	_create_upgrade_widget(
		"Fire Rate",
		"🔫",
		"+0.1 shots/sec per level",
		RewardManager.perm_projectile_fire_rate * 10,  # Display as whole number
		"fire_rate"
	)

	_create_upgrade_widget(
		"Critical Chance",
		"🎯",
		"+1% crit chance per level",
		RewardManager.perm_crit_chance,
		"crit_chance"
	)

	_create_upgrade_widget(
		"Critical Damage",
		"💥",
		"+0.05x crit multiplier per level",
		RewardManager.perm_crit_damage * 20,  # Display as whole number
		"crit_damage"
	)

func _add_defense_upgrades() -> void:
	_create_upgrade_widget(
		"Shield Integrity",
		"🛡️",
		"+100 max shield per level",
		RewardManager.perm_shield_integrity / 100,
		"shield_integrity"
	)

	_create_upgrade_widget(
		"Shield Regen",
		"💚",
		"+1 shield/sec per level",
		RewardManager.perm_shield_regen,
		"shield_regen"
	)

	_create_upgrade_widget(
		"Damage Reduction",
		"🧱",
		"+1% damage reduction per level",
		RewardManager.perm_damage_reduction * 100,
		"damage_reduction"
	)

func _add_economy_upgrades() -> void:
	_create_upgrade_widget(
		"DC Multiplier",
		"💾",
		"+10% data credits per level",
		RewardManager.perm_data_credit_multiplier * 10,
		"data_credit_multiplier"
	)

	_create_upgrade_widget(
		"AT Multiplier",
		"📦",
		"+10% archive tokens per level",
		RewardManager.perm_archive_token_multiplier * 10,
		"archive_token_multiplier"
	)

	_create_upgrade_widget(
		"Wave Skip Chance",
		"⏩",
		"+1% chance to skip wave",
		RewardManager.perm_wave_skip_chance,
		"wave_skip_chance"
	)

	_create_upgrade_widget(
		"Free Upgrade Chance",
		"🎁",
		"+1% free upgrade chance",
		RewardManager.perm_free_upgrade_chance,
		"free_upgrade_chance"
	)

func _add_special_upgrades() -> void:
	# Multi-target unlock is a one-time purchase
	if not RewardManager.perm_multi_target_unlocked:
		_create_upgrade_widget(
			"Multi-Target (UNLOCK)",
			"🎯",
			"Unlock multi-target mode",
			0,
			"multi_target_unlock"
		)

func _create_upgrade_widget(upgrade_name: String, icon: String, description: String, current_level: float, upgrade_key: String) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(300, 90)
	upgrade_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Header with icon and name
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.custom_minimum_size = Vector2(40, 30)
	header.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = upgrade_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.custom_minimum_size = Vector2(180, 30)
	header.add_child(name_label)

	# Level display
	var level_label = Label.new()
	level_label.text = "Lv %d" % int(current_level)
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.custom_minimum_size = Vector2(60, 30)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(level_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	vbox.add_child(desc_label)

	# Cost and purchase button
	var bottom_row = HBoxContainer.new()
	vbox.add_child(bottom_row)

	var cost = UpgradeManager.get_perm_upgrade_cost(upgrade_key)
	var cost_label = Label.new()
	cost_label.text = "Cost: %s AT" % NumberFormatter.format(cost)
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.custom_minimum_size = Vector2(150, 25)
	bottom_row.add_child(cost_label)

	var upgrade_button = Button.new()
	upgrade_button.text = "Upgrade"
	upgrade_button.custom_minimum_size = Vector2(100, 25)
	upgrade_button.pressed.connect(func(): _on_upgrade_pressed(upgrade_key))

	# Disable if can't afford
	if RewardManager.archive_tokens < cost:
		upgrade_button.disabled = true

	bottom_row.add_child(upgrade_button)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	upgrade_list.add_child(spacer)

func _on_upgrade_pressed(upgrade_key: String) -> void:
	if not UpgradeManager:
		return

	if UpgradeManager.upgrade_permanent(upgrade_key):
		print("✅ Upgraded: %s" % upgrade_key)
		_refresh_ui()
	else:
		print("❌ Failed to upgrade: %s" % upgrade_key)

func _on_close_pressed() -> void:
	queue_free()
