class_name PermanentUpgradeManager
extends Node

# === PERMANENT UPGRADE UI MANAGER ===
# Manages permanent upgrade UI updates and drone purchase UI
# Extracted from main_hud.gd (Phase 3.3 Refactor - C7)
#
# Responsibilities:
# - Update permanent upgrade button costs and levels
# - Handle permanent upgrade purchases
# - Create and manage drone purchase UI
# - Update drone purchase button states

signal permanent_upgrade_purchased(upgrade_key: String)
signal drone_purchased(drone_type: String)

# References to UI nodes (set externally)
var perm_nodes: Dictionary = {}
var perm_panel: Control = null
var perm_panel_toggle_button: Button = null

# Drone purchase UI tracking
var drone_purchase_containers: Dictionary = {}
var drone_purchase_buttons: Dictionary = {}
var drone_status_labels: Dictionary = {}

# Reference to main_hud for get_current_buy_amount()
var main_hud: Node = null

## Updates a single permanent upgrade button UI
## @param key: Upgrade key (e.g., "projectile_damage")
func update_perm_upgrade_ui(key: String) -> void:
	if not perm_nodes.has(key):
		push_error("Invalid perm upgrade key: %s" % key)
		return

	var level = UpgradeManager.get_perm_level(key)
	var at = RewardManager.archive_tokens
	var buy_amount = main_hud.get_current_buy_amount() if main_hud else 1
	var label_text = ""
	var total_cost = 0

	if buy_amount == -1:
		# Max: Calculate how many upgrades you can actually afford
		var arr = BulkPurchaseCalculator.get_perm_max_affordable(key, at)
		var max_afford = arr[0]
		var max_cost = arr[1]
		label_text = "Upgrade x%s (%s AT)" % [str(max_afford), str(max_cost)]
		total_cost = max_cost
	else:
		total_cost = BulkPurchaseCalculator.get_perm_total_cost(key, buy_amount)
		label_text = "Upgrade x%s (%s AT)" % [str(buy_amount), str(total_cost)]

	perm_nodes[key]["level"].text = "Lvl %d" % level
	perm_nodes[key]["button"].text = label_text
	perm_nodes[key]["button"].disabled = at < (total_cost if total_cost > 0 else UpgradeManager.get_perm_upgrade_cost(key))

## Updates all permanent upgrade buttons
func update_all_perm_upgrade_ui() -> void:
	for key in perm_nodes.keys():
		update_perm_upgrade_ui(key)

## Handles a permanent upgrade purchase
## @param key: Upgrade key to purchase
func handle_upgrade_purchase(key: String) -> void:
	if not main_hud:
		push_error("main_hud reference not set!")
		return

	var amount = main_hud.get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_permanent(key):
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_permanent(key):
				break

	update_all_perm_upgrade_ui()
	permanent_upgrade_purchased.emit(key)

## Creates drone purchase UI in the permanent panel
func create_drone_purchase_ui() -> void:
	var perm_list = perm_panel.get_node_or_null("PermUpgradesList")
	if not perm_list:
		print("⚠️ PermUpgradesPanel/PermUpgradesList not found!")
		return

	# Add separator before drones section
	var separator = HSeparator.new()
	perm_list.add_child(separator)

	# Add drones section title
	var title_container = HBoxContainer.new()
	perm_list.add_child(title_container)

	var title = Label.new()
	title.text = "=== DRONES (Purchase with 💎 Fragments) ==="
	title.custom_minimum_size = Vector2(400, 25)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title)

	# Drone types and info
	var drone_info = {
		"flame": {"name": "🔥 Flame", "desc": "Burns enemies"},
		"frost": {"name": "❄️ Frost", "desc": "Slows fastest"},
		"poison": {"name": "🟣 Poison", "desc": "Poisons enemies"},
		"shock": {"name": "⚡ Shock", "desc": "Stuns closest"}
	}

	for drone_type in ["flame", "frost", "poison", "shock"]:
		var info = drone_info[drone_type]

		# Create container
		var container = HBoxContainer.new()
		container.custom_minimum_size = Vector2(400, 30)
		drone_purchase_containers[drone_type] = container
		perm_list.add_child(container)

		# Name label
		var name_label = Label.new()
		name_label.text = info["name"]
		name_label.custom_minimum_size = Vector2(80, 30)
		container.add_child(name_label)

		# Status label
		var status_label = Label.new()
		status_label.text = "Not Owned"
		status_label.custom_minimum_size = Vector2(120, 30)
		drone_status_labels[drone_type] = status_label
		container.add_child(status_label)

		# Purchase button
		var button = Button.new()
		button.text = "Purchase (5000 💎)"
		button.custom_minimum_size = Vector2(180, 30)
		button.pressed.connect(_on_drone_purchase_button_pressed.bind(drone_type))
		drone_purchase_buttons[drone_type] = button
		container.add_child(button)

	# Initial UI update
	update_drone_purchase_ui()

## Updates drone purchase button states
func update_drone_purchase_ui() -> void:
	for drone_type in ["flame", "frost", "poison", "shock"]:
		if not drone_status_labels.has(drone_type) or not drone_purchase_buttons.has(drone_type):
			continue

		var status_label = drone_status_labels[drone_type]
		var button = drone_purchase_buttons[drone_type]
		var is_owned = RewardManager.owns_drone(drone_type)
		var cost = RewardManager.get_drone_purchase_cost(drone_type)

		# Update status
		if is_owned:
			status_label.text = "✅ Owned"
			button.text = "Owned"
			button.disabled = true
		else:
			status_label.text = "Not Owned"
			button.text = "Purchase (%d 💎)" % cost
			button.disabled = RewardManager.fragments < cost

## Toggles permanent panel visibility
func toggle_panel() -> void:
	if not perm_panel or not perm_panel_toggle_button:
		return

	perm_panel.visible = not perm_panel.visible
	if perm_panel.visible:
		perm_panel_toggle_button.text = "Hide Upgrades"
		# Update drone purchase UI when opening
		update_drone_purchase_ui()
	else:
		perm_panel_toggle_button.text = "Show Upgrades"

# === PRIVATE FUNCTIONS ===

func _on_drone_purchase_button_pressed(drone_type: String) -> void:
	var cost = RewardManager.get_drone_purchase_cost(drone_type)
	if RewardManager.purchase_drone_permanent(drone_type, cost):
		update_drone_purchase_ui()
		print("💎 Successfully purchased %s drone!" % drone_type)
		drone_purchased.emit(drone_type)
