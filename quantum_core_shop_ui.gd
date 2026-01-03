extends Control

# Quantum Core Shop UI
# Shows QC purchase packs, direct IAP, and QC spending options

# UI Nodes
var panel: Panel
var title_label: Label
var qc_balance_label: Label
var tab_container: Control
var tab_buttons: Array = []
var current_tab: String = "qc_packs"

# Content areas
var content_scroll: ScrollContainer
var content_list: VBoxContainer

var close_button: Button

# Tab names
const TAB_INFO := {
	"qc_packs": {"name": "Buy QC", "icon": "💎"},
	"direct_iap": {"name": "Premium", "icon": "⭐"},
	"qc_shop": {"name": "Spend QC", "icon": "🛒"}
}

func _ready() -> void:
	_create_ui()

	# Connect signals
	if QuantumCoreShop:
		QuantumCoreShop.item_purchased.connect(_on_item_purchased)
		QuantumCoreShop.qc_purchase_completed.connect(_on_qc_purchased)
		QuantumCoreShop.iap_purchase_completed.connect(_on_iap_purchased)

	# Initial refresh
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
	title_label.text = "💎 QUANTUM CORE SHOP"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# QC Balance display
	qc_balance_label = Label.new()
	qc_balance_label.text = "Quantum Cores: 0 🔮"
	qc_balance_label.position = Vector2(20, 48)
	qc_balance_label.add_theme_font_size_override("font_size", 14)
	qc_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qc_balance_label.custom_minimum_size = Vector2(320, 25)
	panel.add_child(qc_balance_label)

	# Tab buttons
	tab_container = Control.new()
	tab_container.position = Vector2(20, 80)
	tab_container.custom_minimum_size = Vector2(320, 45)
	panel.add_child(tab_container)

	var tab_names = ["qc_packs", "direct_iap", "qc_shop"]
	for i in range(3):
		var tab_id = tab_names[i]
		var tab_info = TAB_INFO[tab_id]
		var tab_button = Button.new()
		tab_button.custom_minimum_size = Vector2(105, 40)
		tab_button.position = Vector2(i * 107, 0)
		tab_button.text = "%s\n%s" % [tab_info["icon"], tab_info["name"]]
		tab_button.pressed.connect(_on_tab_pressed.bind(tab_id))
		tab_container.add_child(tab_button)
		tab_buttons.append({"button": tab_button, "tab": tab_id})

	# Content scroll area
	content_scroll = ScrollContainer.new()
	content_scroll.position = Vector2(20, 135)
	content_scroll.custom_minimum_size = Vector2(320, 580)
	panel.add_child(content_scroll)

	content_list = VBoxContainer.new()
	content_list.custom_minimum_size = Vector2(300, 0)
	content_scroll.add_child(content_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _refresh_ui() -> void:
	if not QuantumCoreShop or not RewardManager:
		return

	# Update QC balance
	var qc = RewardManager.quantum_cores
	qc_balance_label.text = "Quantum Cores: %s 🔮" % NumberFormatter.format(qc)

	# Update tab styles
	_update_tab_styles()

	# Update content based on current tab
	_update_content()

func _update_tab_styles() -> void:
	for tab_data in tab_buttons:
		var button = tab_data["button"]
		var tab = tab_data["tab"]
		var info = TAB_INFO[tab]

		if tab == current_tab:
			button.text = "%s\n▼ %s" % [info["icon"], info["name"]]
		else:
			button.text = "%s\n%s" % [info["icon"], info["name"]]

func _update_content() -> void:
	# Clear existing content
	for child in content_list.get_children():
		child.queue_free()

	match current_tab:
		"qc_packs":
			_create_qc_packs_content()
		"direct_iap":
			_create_direct_iap_content()
		"qc_shop":
			_create_qc_shop_content()

func _create_qc_packs_content() -> void:
	# Section title
	var title = Label.new()
	title.text = "Purchase Quantum Cores"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(title)

	# Description
	var desc = Label.new()
	desc.text = "Convert real money to Quantum Cores\nEarn QC from milestones & achievements too!"
	desc.add_theme_font_size_override("font_size", 11)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(desc)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	content_list.add_child(spacer1)

	# Create buttons for each pack
	var pack_ids = ["starter", "small", "medium", "large", "mega", "whale"]
	for pack_id in pack_ids:
		var pack = QuantumCoreShop.QC_PURCHASE_PACKS[pack_id]
		_create_qc_pack_widget(pack_id, pack)

func _create_qc_pack_widget(pack_id: String, pack: Dictionary) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(400, 80)
	content_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Header with name and tags
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var name_label = Label.new()
	name_label.text = "%s %s" % [pack["icon"], pack["name"]]
	name_label.add_theme_font_size_override("font_size", 14)
	header.add_child(name_label)

	if pack.has("popular") and pack["popular"]:
		var popular_tag = Label.new()
		popular_tag.text = "🔥 POPULAR"
		popular_tag.add_theme_font_size_override("font_size", 11)
		popular_tag.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		header.add_child(popular_tag)

	if pack.has("best_value") and pack["best_value"]:
		var value_tag = Label.new()
		value_tag.text = "⭐ BEST VALUE"
		value_tag.add_theme_font_size_override("font_size", 11)
		value_tag.add_theme_color_override("font_color", Color(0.0, 1.0, 0.4))
		header.add_child(value_tag)

	# Details
	var details = Label.new()
	var bonus_text = ""
	if pack["bonus"] > 0:
		bonus_text = " (+%d%% bonus!)" % pack["bonus"]
	details.text = "%s Quantum Cores%s" % [NumberFormatter.format(pack["qc"]), bonus_text]
	details.add_theme_font_size_override("font_size", 12)
	vbox.add_child(details)

	# Purchase button
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var button = Button.new()
	button.custom_minimum_size = Vector2(250, 30)
	button.text = "Purchase for $%.2f USD" % pack["usd"]
	button.pressed.connect(_on_qc_pack_purchase_pressed.bind(pack_id))
	hbox.add_child(button)

func _create_direct_iap_content() -> void:
	# Section title
	var title = Label.new()
	title.text = "Premium Purchases"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(title)

	# Description
	var desc = Label.new()
	desc.text = "One-time purchases for permanent benefits"
	desc.add_theme_font_size_override("font_size", 11)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(desc)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	content_list.add_child(spacer1)

	# Create buttons for each IAP
	for iap_id in QuantumCoreShop.DIRECT_IAP_ITEMS.keys():
		var iap = QuantumCoreShop.DIRECT_IAP_ITEMS[iap_id]
		_create_iap_widget(iap_id, iap)

func _create_iap_widget(iap_id: String, iap: Dictionary) -> void:
	var is_owned = false
	if iap_id == "no_ads":
		is_owned = QuantumCoreShop.has_no_ads()
	elif iap_id == "double_economy":
		is_owned = QuantumCoreShop.has_double_economy()

	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(400, 90)
	content_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Name
	var name_label = Label.new()
	name_label.text = "%s %s" % [iap["icon"], iap["name"]]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = iap["description"]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Purchase button
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var button = Button.new()
	button.custom_minimum_size = Vector2(250, 30)

	if is_owned:
		button.text = "✅ OWNED"
		button.disabled = true
	else:
		button.text = "Purchase for $%.2f USD" % iap["usd"]
		button.pressed.connect(_on_iap_purchase_pressed.bind(iap_id))

	hbox.add_child(button)

func _create_qc_shop_content() -> void:
	# Section title
	var title = Label.new()
	title.text = "Spend Quantum Cores"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(title)

	# QC balance
	var balance = Label.new()
	var qc = RewardManager.quantum_cores if RewardManager else 0
	balance.text = "Balance: %s 🔮" % NumberFormatter.format(qc)
	balance.add_theme_font_size_override("font_size", 12)
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(balance)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	content_list.add_child(spacer1)

	# Fragment bundles section
	var frag_title = Label.new()
	frag_title.text = "💎 Fragment Bundles"
	frag_title.add_theme_font_size_override("font_size", 14)
	frag_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(frag_title)

	var frag_ids = ["fragments_100", "fragments_500", "fragments_1000", "fragments_2500", "fragments_5000", "fragments_10000"]
	for frag_id in frag_ids:
		var item = QuantumCoreShop.SHOP_ITEMS[frag_id]
		_create_shop_item_widget(frag_id, item)

	# Lab upgrades section
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	content_list.add_child(spacer2)

	var lab_title = Label.new()
	lab_title.text = "🔬 Lab Upgrades"
	lab_title.add_theme_font_size_override("font_size", 14)
	lab_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_list.add_child(lab_title)

	# Lab rush (dynamically calculated)
	# Only show if there's an active lab research
	if SoftwareUpgradeManager and SoftwareUpgradeManager.get_first_active_slot() >= 0:
		var lab_rush_item = QuantumCoreShop.SHOP_ITEMS["lab_rush"]
		var time_remaining = SoftwareUpgradeManager.get_active_lab_time_remaining_hours()
		_create_lab_rush_widget("lab_rush", lab_rush_item, time_remaining)

	# Lab slots
	var slot_ids = ["lab_slot_3", "lab_slot_4", "lab_slot_5"]
	for slot_id in slot_ids:
		var item = QuantumCoreShop.SHOP_ITEMS[slot_id]
		_create_shop_item_widget(slot_id, item)

func _create_shop_item_widget(item_id: String, item: Dictionary) -> void:
	var is_owned = false
	var can_afford = RewardManager.quantum_cores >= item["qc_cost"]

	# Check if lab slot is already owned
	if item_id.begins_with("lab_slot"):
		var slot_num = int(item_id.split("_")[2])
		var current_slots = QuantumCoreShop.get_max_lab_slots()
		is_owned = current_slots >= slot_num

	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(400, 75)
	content_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Name
	var name_label = Label.new()
	name_label.text = "%s %s" % [item["icon"], item["name"]]
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = item["description"]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Purchase button
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var button = Button.new()
	button.custom_minimum_size = Vector2(220, 30)

	if is_owned:
		button.text = "✅ OWNED"
		button.disabled = true
	elif can_afford:
		button.text = "Purchase for %s 🔮" % NumberFormatter.format(item["qc_cost"])
		button.pressed.connect(_on_shop_item_purchase_pressed.bind(item_id))
	else:
		button.text = "Requires %s 🔮" % NumberFormatter.format(item["qc_cost"])
		button.disabled = true

	hbox.add_child(button)

func _create_lab_rush_widget(item_id: String, item: Dictionary, time_remaining_hours: int) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(400, 90)
	content_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Name
	var name_label = Label.new()
	name_label.text = "%s %s" % [item["icon"], item["name"]]
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Description with time remaining
	var desc_label = Label.new()
	desc_label.text = "%s\nTime remaining: %d hours" % [item["description"], time_remaining_hours]
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	# Rush options (1h, 4h, or all remaining time)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var rush_options = [
		{"hours": min(1, time_remaining_hours), "label": "Rush 1h"},
		{"hours": min(4, time_remaining_hours), "label": "Rush 4h"},
		{"hours": time_remaining_hours, "label": "Rush All"}
	]

	for option in rush_options:
		var hours = option["hours"]
		if hours <= 0:
			continue

		var qc_cost = hours * 25
		var can_afford = RewardManager.quantum_cores >= qc_cost

		var button = Button.new()
		button.custom_minimum_size = Vector2(120, 30)

		if can_afford:
			button.text = "%s (%s 🔮)" % [option["label"], NumberFormatter.format(qc_cost)]
			button.pressed.connect(_on_lab_rush_pressed.bind(hours))
		else:
			button.text = "%s (%s 🔮)" % [option["label"], NumberFormatter.format(qc_cost)]
			button.disabled = true

		hbox.add_child(button)

func _on_lab_rush_pressed(hours: int) -> void:
	# Purchase lab rush with specified hours
	if QuantumCoreShop.purchase_shop_item("lab_rush", hours):
		print("✅ Lab rushed by %d hours!" % hours)
		_refresh_ui()
	else:
		print("❌ Failed to rush lab")

func _on_tab_pressed(tab_id: String) -> void:
	current_tab = tab_id
	_refresh_ui()

func _on_qc_pack_purchase_pressed(pack_id: String) -> void:
	# In a real implementation, this would trigger the platform IAP flow
	# For now, just simulate the purchase
	print("🛒 Attempting to purchase QC pack:", pack_id)

	if QuantumCoreShop.purchase_qc_pack(pack_id):
		print("✅ QC pack purchased successfully!")
		_refresh_ui()
	else:
		print("❌ QC pack purchase failed")

func _on_iap_purchase_pressed(iap_id: String) -> void:
	# In a real implementation, this would trigger the platform IAP flow
	print("🛒 Attempting to purchase IAP:", iap_id)

	if QuantumCoreShop.purchase_direct_iap(iap_id):
		print("✅ IAP purchased successfully!")
		_refresh_ui()
	else:
		print("❌ IAP purchase failed")

func _on_shop_item_purchase_pressed(item_id: String) -> void:
	# Purchase with QC
	if QuantumCoreShop.purchase_shop_item(item_id):
		print("✅ Purchased %s with QC" % item_id)
		_refresh_ui()
	else:
		print("❌ Failed to purchase %s" % item_id)

func _on_item_purchased(item_id: String, cost: int) -> void:
	_refresh_ui()

func _on_qc_purchased(pack_id: String, qc_amount: int, usd_cost: float) -> void:
	_refresh_ui()

func _on_iap_purchased(iap_id: String, usd_cost: float) -> void:
	_refresh_ui()

func _on_close_pressed() -> void:
	visible = false

func _exit_tree() -> void:
	# Disconnect signals
	if QuantumCoreShop:
		if QuantumCoreShop.item_purchased.is_connected(Callable(self, "_on_item_purchased")):
			QuantumCoreShop.item_purchased.disconnect(Callable(self, "_on_item_purchased"))
		if QuantumCoreShop.qc_purchase_completed.is_connected(Callable(self, "_on_qc_purchased")):
			QuantumCoreShop.qc_purchase_completed.disconnect(Callable(self, "_on_qc_purchased"))
		if QuantumCoreShop.iap_purchase_completed.is_connected(Callable(self, "_on_iap_purchased")):
			QuantumCoreShop.iap_purchase_completed.disconnect(Callable(self, "_on_iap_purchased"))
