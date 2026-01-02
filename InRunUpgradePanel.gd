class_name InRunUpgradePanel
extends Node

## Manages in-run upgrade panels (Offense, Defense, Economy)
## Extracted from main_hud.gd Phase 3.4 Refactor
##
## Responsibilities:
## - Toggle offense/defense/economy panel visibility
## - Handle upgrade button presses with generic handler
## - Update upgrade button UI (cost, disabled state)
## - Manage multi-target unlock/upgrade UI

# References to main_hud components
var main_hud: Node = null
var tower: Node = null

# Panel references
var offense_panel: Control = null
var defense_panel: Control = null
var economy_panel: Control = null
var perm_panel: Control = null

# Button references
var damage_upgrade: Button = null
var fire_rate_upgrade: Button = null
var crit_upgrade_button: Button = null
var crit_damage_upgrade: Button = null
var shield_upgrade: Button = null
var reduction_upgrade: Button = null
var regen_upgrade: Button = null
var data_credits_upgrade: Button = null
var archive_token_upgrade: Button = null
var free_upgrade_chance: Button = null
var wave_skip_chance: Button = null
var unlock_multi_target_button: Button = null
var upgrade_multi_target_button: Button = null
var multi_target_label: Label = null

# === GENERIC UPGRADE HANDLER (Phase 1 Refactor) ===
# Metadata table for all in-run upgrade handlers
# Eliminates 11 duplicated button handlers (120+ lines → 1 generic function)
const UPGRADE_METADATA = {
	"damage": {
		"upgrade_func": "upgrade_projectile_damage",
		"post_actions": ["update_damage_label", "tower_update_visual"]
	},
	"fire_rate": {
		"upgrade_func": "upgrade_fire_rate",
		"post_actions": ["tower_refresh_fire_rate", "tower_update_visual", "update_labels"]
	},
	"crit_chance": {
		"upgrade_func": "upgrade_crit_chance",
		"post_actions": ["update_crit_label", "update_labels"]
	},
	"crit_damage": {
		"upgrade_func": "upgrade_crit_damage",
		"post_actions": ["update_labels"]
	},
	"shield": {
		"upgrade_func": "upgrade_shield_integrity",
		"post_actions": ["tower_refresh_shield", "update_labels"]
	},
	"damage_reduction": {
		"upgrade_func": "upgrade_damage_reduction",
		"post_actions": ["update_labels"]
	},
	"shield_regen": {
		"upgrade_func": "upgrade_shield_regen",
		"post_actions": ["tower_refresh_shield", "update_labels"]
	},
	"data_credits": {
		"upgrade_func": "upgrade_data_credit_multiplier",
		"post_actions": ["update_labels"]
	},
	"archive_token": {
		"upgrade_func": "upgrade_archive_token_multiplier",
		"post_actions": ["update_labels"]
	},
	"free_upgrade": {
		"upgrade_func": "upgrade_free_upgrade_chance",
		"post_actions": ["update_labels"]
	},
	"wave_skip": {
		"upgrade_func": "upgrade_wave_skip_chance",
		"post_actions": ["update_labels"]
	}
}

# === GENERIC UI UPDATE FUNCTION (Phase 1.2 Refactor) ===
# Metadata table for all in-run upgrade button UI updates
# Eliminates 165+ lines of duplicated UI update logic
const BUTTON_UI_METADATA = {
	"damage": {
		"button": "damage_upgrade",
		"base_cost": "DAMAGE_UPGRADE_BASE_COST",
		"purchases": "damage_purchases",
		"label": "Damage"
	},
	"fire_rate": {
		"button": "fire_rate_upgrade",
		"base_cost": "FIRE_RATE_UPGRADE_BASE_COST",
		"purchases": "fire_rate_purchases",
		"label": "Fire Rate"
	},
	"crit_chance": {
		"button": "crit_upgrade_button",
		"base_cost": "CRIT_CHANCE_UPGRADE_BASE_COST",
		"purchases": "crit_chance_purchases",
		"label": "Crit Chance",
		"has_cap": true,
		"cap_func": "get_crit_chance",
		"cap_value": "CRIT_CHANCE_CAP"
	},
	"crit_damage": {
		"button": "crit_damage_upgrade",
		"base_cost": "CRIT_DAMAGE_UPGRADE_BASE_COST",
		"purchases": "crit_damage_purchases",
		"label": "Crit Damage"
	},
	"shield": {
		"button": "shield_upgrade",
		"base_cost": "SHIELD_UPGRADE_BASE_COST",
		"purchases": "shield_purchases",
		"label": "Shield Integrity"
	},
	"damage_reduction": {
		"button": "reduction_upgrade",
		"base_cost": "DAMAGE_REDUCTION_UPGRADE_BASE_COST",
		"purchases": "damage_reduction_purchases",
		"label": "Damage Reduction"
	},
	"shield_regen": {
		"button": "regen_upgrade",
		"base_cost": "SHIELD_REGEN_UPGRADE_BASE_COST",
		"purchases": "shield_regen_purchases",
		"label": "Shield Regen"
	},
	"data_credits": {
		"button": "data_credits_upgrade",
		"base_cost": "DATA_MULTIPLIER_UPGRADE_BASE_COST",
		"purchases": "data_multiplier_purchases",
		"label": "Data Credits Multiplier"
	},
	"archive_token": {
		"button": "archive_token_upgrade",
		"base_cost": "ARCHIVE_MULTIPLIER_UPGRADE_BASE_COST",
		"purchases": "archive_multiplier_purchases",
		"label": "Archive Token Multiplier"
	},
	"free_upgrade": {
		"button": "free_upgrade_chance",
		"base_cost": "FREE_UPGRADE_BASE_COST",
		"purchases": "free_upgrade_purchases",
		"label": "Free Upgrade Chance",
		"has_cap": true,
		"cap_func": "get_free_upgrade_chance",
		"cap_value": "FREE_UPGRADE_MAX_CHANCE"
	},
	"wave_skip": {
		"button": "wave_skip_chance",
		"base_cost": "WAVE_SKIP_UPGRADE_BASE_COST",
		"purchases": "wave_skip_purchases",
		"label": "Wave Skip Chance",
		"has_cap": true,
		"cap_func": "get_wave_skip_chance",
		"cap_value": "WAVE_SKIP_MAX_CHANCE"
	}
}

## Toggle offense panel visibility, hide other panels
func toggle_offense_panel() -> void:
	var new_state = not offense_panel.visible
	offense_panel.visible = new_state
	defense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false

## Toggle defense panel visibility, hide other panels
func toggle_defense_panel() -> void:
	var new_state = not defense_panel.visible
	defense_panel.visible = new_state
	offense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false

## Toggle economy panel visibility, hide other panels
func toggle_economy_panel() -> void:
	var new_state = not economy_panel.visible
	economy_panel.visible = new_state
	offense_panel.visible = false
	defense_panel.visible = false
	perm_panel.visible = false

## Generic upgrade handler - replaces 11 duplicated functions
func handle_inrun_upgrade(upgrade_key: String) -> void:
	if not UPGRADE_METADATA.has(upgrade_key):
		push_error("Invalid upgrade key: %s" % upgrade_key)
		return

	var metadata = UPGRADE_METADATA[upgrade_key]
	var amount = main_hud.get_current_buy_amount()

	# Execute upgrade purchases
	if amount == -1:
		# Max mode: buy until can't afford
		while UpgradeManager.call(metadata.upgrade_func):
			pass
	else:
		# Buy specified amount
		for i in range(amount):
			if not UpgradeManager.call(metadata.upgrade_func):
				break

	# Execute post-actions
	for action in metadata.post_actions:
		match action:
			"update_labels":
				if main_hud:
					main_hud.update_labels()
			"update_damage_label":
				if main_hud:
					main_hud.update_damage_label()
			"update_crit_label":
				update_crit_label()
			"tower_update_visual":
				if tower and is_instance_valid(tower):
					tower.update_visual_tier()
			"tower_refresh_fire_rate":
				if tower and is_instance_valid(tower):
					tower.refresh_fire_rate()
			"tower_refresh_shield":
				if tower and is_instance_valid(tower):
					tower.refresh_shield_stats()
			_:
				push_warning("Unknown post-action: %s" % action)

## Generic UI update function - replaces 165+ lines of duplicated button update logic
func update_upgrade_button_ui(upgrade_key: String) -> void:
	if not BUTTON_UI_METADATA.has(upgrade_key):
		push_error("Invalid upgrade key for UI: %s" % upgrade_key)
		return

	var metadata = BUTTON_UI_METADATA[upgrade_key]
	var button = get(metadata.button)
	if not button:
		push_error("Button not found: %s" % metadata.button)
		return

	var dc = RewardManager.data_credits
	var buy_amount = main_hud.get_current_buy_amount()

	# Check if upgrade is capped
	if metadata.has("has_cap") and metadata.has_cap:
		var current_value = UpgradeManager.call(metadata.cap_func)
		var cap_value = UpgradeManager.get(metadata.cap_value)
		if current_value >= cap_value:
			button.text = "%s (MAX)" % metadata.label
			button.disabled = true
			return

	# Get cost constants
	var base_cost = UpgradeManager.get(metadata.base_cost)
	var purchases = UpgradeManager.get(metadata.purchases)

	# Calculate cost and text
	var cost: int
	var text: String

	if buy_amount == -1:
		# Max mode: show how many can afford
		var arr = BulkPurchaseCalculator.get_inrun_max_affordable(base_cost, purchases, dc)
		cost = arr[1]
		text = "%s x%d (%s DC)" % [metadata.label, arr[0], NumberFormatter.format(cost)]
	else:
		# Buy X mode: show cost for X purchases
		cost = BulkPurchaseCalculator.get_inrun_total_cost(base_cost, purchases, buy_amount)
		text = "%s x%d (%s DC)" % [metadata.label, buy_amount, NumberFormatter.format(cost)]

	button.text = text
	button.disabled = dc < cost or cost == 0

## Update all in-run upgrade button UI
func update_all_inrun_upgrade_ui() -> void:
	# Generic updates for all 11 upgrades
	for upgrade_key in BUTTON_UI_METADATA.keys():
		update_upgrade_button_ui(upgrade_key)
	# Multi-target has custom logic (unlock vs upgrade)
	update_multi_target_ui()

## Handle multi-target unlock button press
func handle_unlock_multi_target() -> void:
	if UpgradeManager.unlock_multi_target():
		update_multi_target_ui()
		if main_hud:
			main_hud.update_labels()

## Handle multi-target upgrade button press
func handle_upgrade_multi_target() -> void:
	if UpgradeManager.upgrade_multi_target():
		update_multi_target_ui()
		if main_hud:
			main_hud.update_labels()

## Update multi-target UI (unlock vs upgrade mode)
func update_multi_target_ui() -> void:
	if not UpgradeManager.multi_target_unlocked:
		unlock_multi_target_button.visible = true
		upgrade_multi_target_button.visible = false
		var cost = UpgradeManager.get_multi_target_cost_for_level(1)
		unlock_multi_target_button.text = "Unlock Multi Target (%d DC)" % cost
		unlock_multi_target_button.disabled = RewardManager.data_credits < cost
		multi_target_label.text = "Multi Target: Locked"
	else:
		unlock_multi_target_button.visible = false
		upgrade_multi_target_button.visible = true
		var lvl = UpgradeManager.multi_target_level
		var targets = lvl + 1

		# Handle max level separately to avoid type mismatch
		if lvl >= UpgradeManager.MULTI_TARGET_MAX_LEVEL:
			upgrade_multi_target_button.text = "Max Level Reached"
			upgrade_multi_target_button.disabled = true
		else:
			var next_cost = UpgradeManager.get_multi_target_cost_for_level(lvl + 1)
			upgrade_multi_target_button.text = "Upgrade Multi Target (%d DC)" % next_cost
			upgrade_multi_target_button.disabled = RewardManager.data_credits < next_cost

		multi_target_label.text = "Multi Target: %d" % targets

## Update crit label (debug)
func update_crit_label() -> void:
	var chance = UpgradeManager.get_crit_chance()
	print("Crit Chance: %d%%" % chance)
