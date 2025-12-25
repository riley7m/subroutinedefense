extends Control

var offense_panel: Control = null
var defense_panel: Control = null
var economy_panel: Control = null

func _ready() -> void:
	# Safely get parent and child nodes
	var parent = get_parent()
	if not parent:
		push_error("upgrade_ui has no parent")
		return

	offense_panel = parent.get_node_or_null("OffensePanel")
	defense_panel = parent.get_node_or_null("DefensePanel")
	economy_panel = parent.get_node_or_null("EconomyPanel")

	# Warn if any panels are missing
	if not offense_panel:
		push_warning("OffensePanel not found")
	if not defense_panel:
		push_warning("DefensePanel not found")
	if not economy_panel:
		push_warning("EconomyPanel not found")
