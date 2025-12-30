extends Control

# Data Disk Collection UI
# Shows all owned data disks and their stats

# UI Nodes
var panel: Panel
var title_label: Label
var summary_label: Label
var scroll_container: ScrollContainer
var disk_list: VBoxContainer
var close_button: Button

# Tab buttons for rarity filtering
var all_tab: Button
var common_tab: Button
var uncommon_tab: Button
var rare_tab: Button
var epic_tab: Button
var current_filter: String = "all"

# Rarity colors
const RARITY_COLORS := {
	"common": Color(0.7, 0.7, 0.7),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.4, 0.7, 1.0),
	"epic": Color(0.9, 0.5, 1.0),
}

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
	title_label.text = "📀 DATA DISK COLLECTION"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Summary (unique disks, total count)
	summary_label = Label.new()
	summary_label.text = "Unique: 0 | Total: 0"
	summary_label.position = Vector2(20, 48)
	summary_label.add_theme_font_size_override("font_size", 14)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.custom_minimum_size = Vector2(320, 25)
	panel.add_child(summary_label)

	# Rarity filter tabs
	_create_rarity_tabs()

	# Scroll area for disks
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(20, 135)
	scroll_container.custom_minimum_size = Vector2(320, 580)
	panel.add_child(scroll_container)

	disk_list = VBoxContainer.new()
	disk_list.custom_minimum_size = Vector2(300, 0)
	scroll_container.add_child(disk_list)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _create_rarity_tabs() -> void:
	var tab_y = 80
	var tab_width = 60
	var tab_spacing = 4

	all_tab = Button.new()
	all_tab.text = "All"
	all_tab.position = Vector2(20, tab_y)
	all_tab.custom_minimum_size = Vector2(tab_width, 40)
	all_tab.pressed.connect(func(): _set_filter("all"))
	panel.add_child(all_tab)

	common_tab = Button.new()
	common_tab.text = "C"
	common_tab.position = Vector2(20 + tab_width + tab_spacing, tab_y)
	common_tab.custom_minimum_size = Vector2(tab_width, 40)
	common_tab.pressed.connect(func(): _set_filter("common"))
	panel.add_child(common_tab)

	uncommon_tab = Button.new()
	uncommon_tab.text = "U"
	uncommon_tab.position = Vector2(20 + (tab_width + tab_spacing) * 2, tab_y)
	uncommon_tab.custom_minimum_size = Vector2(tab_width, 40)
	uncommon_tab.pressed.connect(func(): _set_filter("uncommon"))
	panel.add_child(uncommon_tab)

	rare_tab = Button.new()
	rare_tab.text = "R"
	rare_tab.position = Vector2(20 + (tab_width + tab_spacing) * 3, tab_y)
	rare_tab.custom_minimum_size = Vector2(tab_width, 40)
	rare_tab.pressed.connect(func(): _set_filter("rare"))
	panel.add_child(rare_tab)

	epic_tab = Button.new()
	epic_tab.text = "E"
	epic_tab.position = Vector2(20 + (tab_width + tab_spacing) * 4, tab_y)
	epic_tab.custom_minimum_size = Vector2(tab_width, 40)
	epic_tab.pressed.connect(func(): _set_filter("epic"))
	panel.add_child(epic_tab)

func _set_filter(filter: String) -> void:
	current_filter = filter
	_refresh_ui()

func _refresh_ui() -> void:
	if not DataDiskManager:
		return

	# Update summary
	var owned_disks = DataDiskManager.get_all_owned_disks()
	var unique_count = owned_disks.size()
	var total_count = 0
	for disk in owned_disks:
		total_count += disk["count"]

	summary_label.text = "Unique: %d | Total: %d" % [unique_count, total_count]

	# Clear existing disk widgets
	for child in disk_list.get_children():
		child.queue_free()

	# Filter and sort disks
	var filtered_disks = []
	for disk in owned_disks:
		if current_filter == "all" or disk["rarity"] == current_filter:
			filtered_disks.append(disk)

	# Sort by rarity then name
	filtered_disks.sort_custom(func(a, b):
		var rarity_order = {"common": 0, "uncommon": 1, "rare": 2, "epic": 3}
		var a_rarity = rarity_order.get(a["rarity"], 0)
		var b_rarity = rarity_order.get(b["rarity"], 0)
		if a_rarity != b_rarity:
			return a_rarity < b_rarity
		return a["name"] < b["name"]
	)

	# Create widget for each disk
	for disk in filtered_disks:
		_create_disk_widget(disk)

	# Show message if no disks
	if filtered_disks.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No data disks in this category"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(300, 100)
		disk_list.add_child(empty_label)

func _create_disk_widget(disk: Dictionary) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(300, 100)
	disk_list.add_child(container)

	var vbox = VBoxContainer.new()
	container.add_child(vbox)

	# Header row (icon, name, count)
	var header = HBoxContainer.new()
	vbox.add_child(header)

	# Icon
	var icon_label = Label.new()
	icon_label.text = disk.get("icon", "📀")
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.custom_minimum_size = Vector2(40, 30)
	header.add_child(icon_label)

	# Name
	var name_label = Label.new()
	name_label.text = disk["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.custom_minimum_size = Vector2(200, 30)
	header.add_child(name_label)

	# Count
	var count_label = Label.new()
	count_label.text = "x%d" % disk["count"]
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.custom_minimum_size = Vector2(40, 30)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	header.add_child(count_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = disk["description"]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.9, 0.9, 0.9)
	vbox.add_child(desc_label)

	# Rarity and total effect
	var info_row = HBoxContainer.new()
	vbox.add_child(info_row)

	var rarity_label = Label.new()
	var rarity_text = disk["rarity"].capitalize()
	rarity_label.text = rarity_text
	rarity_label.add_theme_font_size_override("font_size", 12)
	var rarity_color = RARITY_COLORS.get(disk["rarity"], Color.WHITE)
	rarity_label.add_theme_color_override("font_color", rarity_color)
	rarity_label.custom_minimum_size = Vector2(100, 20)
	info_row.add_child(rarity_label)

	# Total effect (value * count)
	var total_value = disk["value"] * disk["count"]
	var effect_label = Label.new()

	# Format based on stat type
	var stat = disk.get("stat", "")
	if stat in ["crit_chance", "wave_skip_chance", "free_upgrade_chance", "ricochet_chance", "lucky_drops", "block_chance"]:
		# Absolute percentage stats
		effect_label.text = "Total: +%d%%" % int(total_value)
	elif stat in ["piercing"]:
		# Absolute count stats
		effect_label.text = "Total: +%d" % int(total_value)
	else:
		# Multiplicative percentage stats
		effect_label.text = "Total: +%.1f%%" % (total_value * 100)

	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	effect_label.custom_minimum_size = Vector2(180, 20)
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_row.add_child(effect_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	disk_list.add_child(spacer)

func _on_close_pressed() -> void:
	queue_free()
