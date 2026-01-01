class_name BulkPurchaseCalculator
extends Node

# === BULK PURCHASE COST CALCULATOR ===
# Static utility class for calculating costs when buying multiple upgrades at once
# Extracted from main_hud.gd (Phase 2.1 Refactor - C7)
#
# Handles both in-run upgrades (DC) and permanent upgrades (AT)
# Supports exponential cost scaling and "Max" purchase mode

const MAX_ITERATIONS = 10000  # Safety limit to prevent infinite loops

# === PERMANENT UPGRADE CALCULATIONS (Archive Tokens) ===

## Calculates total cost to buy 'amount' permanent upgrades
## @param key: Upgrade key (e.g., "projectile_damage")
## @param amount: Number of upgrades to buy
## @return: Total AT cost
static func get_perm_total_cost(key: String, amount: int) -> int:
	var level = UpgradeManager.get_perm_level(key)
	var total_cost = 0
	for i in range(amount):
		var this_cost = UpgradeManager.get_perm_upgrade_cost_for_level(key, level + i)
		total_cost += this_cost
	return total_cost

## Calculates maximum affordable permanent upgrades for current AT
## @param key: Upgrade key
## @param currency: Current archive tokens available
## @return: [max_count, total_cost]
static func get_perm_max_affordable(key: String, currency: int) -> Array:
	var level = UpgradeManager.get_perm_level(key)
	var total_cost = 0
	var max_count = 0
	var safety_counter = 0

	while safety_counter < MAX_ITERATIONS:
		var this_cost = UpgradeManager.get_perm_upgrade_cost_for_level(key, level + max_count)

		# Guard against zero/negative costs which would cause infinite loop
		if this_cost <= 0:
			push_warning("get_perm_max_affordable: Invalid cost %d for level %d" % [this_cost, level + max_count])
			break

		if currency >= total_cost + this_cost:
			total_cost += this_cost
			max_count += 1
		else:
			break

		safety_counter += 1

	if safety_counter >= MAX_ITERATIONS:
		push_error("get_perm_max_affordable: Hit safety limit! Possible infinite loop prevented.")

	return [max_count, total_cost]

# === IN-RUN UPGRADE CALCULATIONS (Data Credits) ===

## Calculates total cost to buy 'amount' in-run upgrades
## @param base_cost: Base cost constant (e.g., DAMAGE_UPGRADE_BASE_COST)
## @param current_purchases: How many times this upgrade has been purchased
## @param amount: Number of upgrades to buy
## @return: Total DC cost
static func get_inrun_total_cost(base_cost: int, current_purchases: int, amount: int) -> int:
	var total_cost = 0
	for i in range(amount):
		# Use UpgradeManager's safe cost calculation (handles BigNumber for high counts)
		var cost = UpgradeManager.get_purchase_scaled_cost(base_cost, current_purchases + i)
		total_cost += cost
	return total_cost

## Calculates maximum affordable in-run upgrades for current DC
## @param base_cost: Base cost constant
## @param current_purchases: How many times this upgrade has been purchased
## @param currency: Current data credits available
## @return: [max_count, total_cost]
static func get_inrun_max_affordable(base_cost: int, current_purchases: int, currency: int) -> Array:
	var total_cost = 0
	var max_count = 0
	var safety_counter = 0

	while safety_counter < MAX_ITERATIONS:
		# Use UpgradeManager's safe cost calculation (handles BigNumber for high counts)
		var this_cost = UpgradeManager.get_purchase_scaled_cost(base_cost, current_purchases + max_count)

		if this_cost <= 0:
			push_warning("get_inrun_max_affordable: Invalid cost %d for purchase %d" % [this_cost, current_purchases + max_count])
			break

		if currency >= total_cost + this_cost:
			total_cost += this_cost
			max_count += 1
		else:
			break

		safety_counter += 1

	if safety_counter >= MAX_ITERATIONS:
		push_error("get_inrun_max_affordable: Hit safety limit! Possible infinite loop prevented.")

	return [max_count, total_cost]
