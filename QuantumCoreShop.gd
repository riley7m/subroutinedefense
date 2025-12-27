extends Node

# Quantum Core Shop System
# Players can spend QC (premium currency) on various game benefits
# Also handles QC purchases with real money (IAP)

# --- SIGNALS ---
signal item_purchased(item_id: String, qc_cost: int)
signal qc_purchase_completed(pack_id: String, qc_amount: int, usd_cost: float)

# --- QC PURCHASE PACKS (Real Money → QC) ---
# Format: { "id": { "qc": amount, "usd": price, "bonus": % } }
const QC_PURCHASE_PACKS := {
	"starter": {
		"name": "Starter Pack",
		"qc": 100,
		"usd": 0.99,
		"bonus": 0,
		"icon": "💎"
	},
	"small": {
		"name": "Small Pack",
		"qc": 600,
		"usd": 4.99,
		"bonus": 20,  # 20% bonus (500 base + 100 bonus)
		"icon": "💎"
	},
	"medium": {
		"name": "Medium Pack",
		"qc": 1300,
		"usd": 9.99,
		"bonus": 30,  # 30% bonus (1000 base + 300 bonus)
		"icon": "💎"
	},
	"large": {
		"name": "Large Pack",
		"qc": 2800,
		"usd": 19.99,
		"bonus": 40,  # 40% bonus (2000 base + 800 bonus)
		"icon": "💎"
	},
	"mega": {
		"name": "Mega Pack",
		"qc": 8000,
		"usd": 49.99,
		"bonus": 60,  # 60% bonus (5000 base + 3000 bonus)
		"icon": "💎",
		"popular": true
	},
	"whale": {
		"name": "Whale Pack",
		"qc": 18000,
		"usd": 99.99,
		"bonus": 80,  # 80% bonus (10000 base + 8000 bonus)
		"icon": "💎",
		"best_value": true
	}
}

# --- QC SHOP ITEMS (QC → Game Benefits) ---
const SHOP_ITEMS := {
	# --- CONSUMABLES (Can be purchased multiple times) ---
	"fragments_small": {
		"name": "Fragment Bundle (Small)",
		"description": "10,000 Fragments",
		"qc_cost": 50,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 10000}
	},
	"fragments_medium": {
		"name": "Fragment Bundle (Medium)",
		"description": "50,000 Fragments",
		"qc_cost": 200,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 50000}
	},
	"fragments_large": {
		"name": "Fragment Bundle (Large)",
		"description": "250,000 Fragments",
		"qc_cost": 900,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 250000},
		"popular": true
	},
	"fragments_mega": {
		"name": "Fragment Bundle (Mega)",
		"description": "1,000,000 Fragments",
		"qc_cost": 3000,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 1000000}
	},

	# --- TIME SKIPS ---
	"wave_skip_10": {
		"name": "Wave Skip (10 Waves)",
		"description": "Instantly complete 10 waves and collect rewards",
		"qc_cost": 100,
		"type": "consumable",
		"icon": "⏩",
		"effect": {"wave_skip": 10}
	},
	"wave_skip_50": {
		"name": "Wave Skip (50 Waves)",
		"description": "Instantly complete 50 waves and collect rewards",
		"qc_cost": 400,
		"type": "consumable",
		"icon": "⏩",
		"effect": {"wave_skip": 50}
	},
	"wave_skip_100": {
		"name": "Wave Skip (100 Waves)",
		"description": "Instantly complete 100 waves and collect rewards",
		"qc_cost": 700,
		"type": "consumable",
		"icon": "⏩",
		"effect": {"wave_skip": 100}
	},

	# --- LAB BOOSTS ---
	"lab_rush": {
		"name": "Lab Rush",
		"description": "Instantly complete current lab research",
		"qc_cost": 150,
		"type": "consumable",
		"icon": "🔬",
		"effect": {"lab_instant": true}
	},
	"lab_speed_boost_1h": {
		"name": "Lab Speed Boost (1 Hour)",
		"description": "+100% lab research speed for 1 hour",
		"qc_cost": 50,
		"type": "consumable",
		"icon": "🔬",
		"effect": {"lab_boost": 2.0, "duration": 3600}
	},
	"lab_speed_boost_24h": {
		"name": "Lab Speed Boost (24 Hours)",
		"description": "+100% lab research speed for 24 hours",
		"qc_cost": 500,
		"type": "consumable",
		"icon": "🔬",
		"effect": {"lab_boost": 2.0, "duration": 86400}
	},

	# --- RESOURCE BOOSTERS ---
	"dc_boost_1h": {
		"name": "DC Booster (1 Hour)",
		"description": "+100% Data Credit drops for 1 hour",
		"qc_cost": 75,
		"type": "consumable",
		"icon": "💾",
		"effect": {"dc_multiplier": 2.0, "duration": 3600}
	},
	"dc_boost_24h": {
		"name": "DC Booster (24 Hours)",
		"description": "+100% Data Credit drops for 24 hours",
		"qc_cost": 600,
		"type": "consumable",
		"icon": "💾",
		"effect": {"dc_multiplier": 2.0, "duration": 86400}
	},
	"at_boost_1h": {
		"name": "AT Booster (1 Hour)",
		"description": "+100% Archive Token drops for 1 hour",
		"qc_cost": 100,
		"type": "consumable",
		"icon": "📦",
		"effect": {"at_multiplier": 2.0, "duration": 3600}
	},
	"at_boost_24h": {
		"name": "AT Booster (24 Hours)",
		"description": "+100% Archive Token drops for 24 hours",
		"qc_cost": 800,
		"type": "consumable",
		"icon": "📦",
		"effect": {"at_multiplier": 2.0, "duration": 86400}
	},
	"super_boost_1h": {
		"name": "Super Booster (1 Hour)",
		"description": "+100% ALL resources for 1 hour",
		"qc_cost": 250,
		"type": "consumable",
		"icon": "⚡",
		"effect": {"all_multiplier": 2.0, "duration": 3600},
		"popular": true
	},
	"super_boost_24h": {
		"name": "Super Booster (24 Hours)",
		"description": "+100% ALL resources for 24 hours",
		"qc_cost": 2000,
		"type": "consumable",
		"icon": "⚡",
		"effect": {"all_multiplier": 2.0, "duration": 86400},
		"best_value": true
	},

	# --- DATA DISK PACKS ---
	"disk_pack_rare": {
		"name": "Rare Disk Pack",
		"description": "3 Guaranteed Rare data disks",
		"qc_cost": 500,
		"type": "consumable",
		"icon": "📀",
		"effect": {"data_disks": 3, "rarity": "rare"}
	},
	"disk_pack_epic": {
		"name": "Epic Disk Pack",
		"description": "1 Guaranteed Epic data disk",
		"qc_cost": 1000,
		"type": "consumable",
		"icon": "📀",
		"effect": {"data_disks": 1, "rarity": "epic"}
	},

	# --- PERMANENT UPGRADES (One-time purchases) ---
	"offline_boost_tier1": {
		"name": "Offline Earnings I",
		"description": "+25% offline progression (permanent)",
		"qc_cost": 500,
		"type": "permanent",
		"icon": "🌙",
		"effect": {"offline_multiplier": 0.25}
	},
	"offline_boost_tier2": {
		"name": "Offline Earnings II",
		"description": "+50% offline progression (permanent)",
		"qc_cost": 1500,
		"type": "permanent",
		"icon": "🌙",
		"effect": {"offline_multiplier": 0.50},
		"requires": "offline_boost_tier1"
	},
	"offline_boost_tier3": {
		"name": "Offline Earnings III",
		"description": "+100% offline progression (permanent)",
		"qc_cost": 5000,
		"type": "permanent",
		"icon": "🌙",
		"effect": {"offline_multiplier": 1.0},
		"requires": "offline_boost_tier2"
	},

	"extra_lab_slot_1": {
		"name": "Extra Lab Slot I",
		"description": "Research 2 labs simultaneously (permanent)",
		"qc_cost": 2000,
		"type": "permanent",
		"icon": "🔬",
		"effect": {"lab_slots": 1}
	},
	"extra_lab_slot_2": {
		"name": "Extra Lab Slot II",
		"description": "Research 3 labs simultaneously (permanent)",
		"qc_cost": 5000,
		"type": "permanent",
		"icon": "🔬",
		"effect": {"lab_slots": 1},
		"requires": "extra_lab_slot_1"
	},

	"auto_prestige": {
		"name": "Auto-Prestige",
		"description": "Automatically advance to next tier when available (permanent)",
		"qc_cost": 3000,
		"type": "permanent",
		"icon": "🔄",
		"effect": {"auto_prestige": true}
	},

	"global_damage_boost": {
		"name": "Global Damage Boost",
		"description": "+10% all damage (permanent)",
		"qc_cost": 2500,
		"type": "permanent",
		"icon": "⚔️",
		"effect": {"damage_multiplier": 0.10}
	},

	"global_currency_boost": {
		"name": "Global Currency Boost",
		"description": "+10% all currency drops (permanent)",
		"qc_cost": 2500,
		"type": "permanent",
		"icon": "💰",
		"effect": {"currency_multiplier": 0.10}
	}
}

# --- PURCHASED ITEMS TRACKING ---
var purchased_permanent_items: Array = []  # List of permanent item IDs purchased

# --- ACTIVE BOOSTERS ---
# Format: { "booster_id": { "multiplier": float, "end_time": unix_timestamp } }
var active_boosters: Dictionary = {}

# --- DEV MODE ---
const DEV_MODE := true  # SET TO FALSE FOR PRODUCTION!

# --- INITIALIZATION ---
func _ready() -> void:
	load_shop_data()
	_update_active_boosters()

func _process(delta: float) -> void:
	_update_active_boosters()

# --- QC PURCHASE (Real Money → QC) ---
func purchase_qc_pack(pack_id: String) -> bool:
	if not QC_PURCHASE_PACKS.has(pack_id):
		push_error("❌ Invalid QC pack ID: %s" % pack_id)
		return false

	var pack = QC_PURCHASE_PACKS[pack_id]
	var qc_amount = pack["qc"]
	var usd_cost = pack["usd"]

	print("💳 Initiating QC purchase: %s ($%.2f for %d QC)" % [pack["name"], usd_cost, qc_amount])

	# Platform-specific IAP integration needed:
	# For Android: GodotGooglePlayBilling plugin
	# For iOS: SKStoreReviewController or In-App Purchase plugin

	if not DEV_MODE:
		print("❌ IAP not implemented yet! Contact developer to enable payments.")
		return false
	else:
		# DEV MODE: Grant QC for free
		print("⚠️ DEV_MODE enabled - granting %d QC for free" % qc_amount)
		RewardManager.add_quantum_cores(qc_amount)
		emit_signal("qc_purchase_completed", pack_id, qc_amount, usd_cost)
		return true

# --- SHOP ITEM PURCHASE (QC → Game Benefits) ---
func purchase_shop_item(item_id: String) -> bool:
	if not SHOP_ITEMS.has(item_id):
		push_error("❌ Invalid shop item ID: %s" % item_id)
		return false

	var item = SHOP_ITEMS[item_id]
	var qc_cost = item["qc_cost"]

	# Check if player has enough QC
	if RewardManager.quantum_cores < qc_cost:
		print("❌ Not enough Quantum Cores! Need %d, have %d" % [qc_cost, RewardManager.quantum_cores])
		return false

	# Check if permanent item already purchased
	if item["type"] == "permanent" and item_id in purchased_permanent_items:
		print("❌ This permanent upgrade has already been purchased!")
		return false

	# Check requirements
	if item.has("requires") and not item["requires"] in purchased_permanent_items:
		print("❌ Must purchase %s first!" % item["requires"])
		return false

	# Deduct QC
	RewardManager.quantum_cores -= qc_cost
	if AchievementManager:
		AchievementManager.add_qc_spent(qc_cost)

	# Apply effect
	_apply_item_effect(item_id, item["effect"])

	# Track permanent purchases
	if item["type"] == "permanent":
		purchased_permanent_items.append(item_id)

	save_shop_data()
	emit_signal("item_purchased", item_id, qc_cost)

	print("✅ Purchased: %s for %d QC" % [item["name"], qc_cost])
	return true

# --- APPLY ITEM EFFECTS ---
func _apply_item_effect(item_id: String, effect: Dictionary) -> void:
	# Fragments
	if effect.has("fragments"):
		RewardManager.add_fragments(effect["fragments"])
		print("💎 +%d Fragments" % effect["fragments"])

	# Wave Skip
	if effect.has("wave_skip"):
		# TODO: Implement wave skip logic
		print("⏩ Skipped %d waves (TODO: implement)" % effect["wave_skip"])

	# Lab Instant Complete
	if effect.has("lab_instant"):
		# TODO: Integrate with SoftwareUpgradeManager
		print("🔬 Lab research completed instantly (TODO: implement)")

	# Temporary Boosters
	if effect.has("duration"):
		var end_time = Time.get_unix_time_from_system() + effect["duration"]
		if effect.has("dc_multiplier"):
			active_boosters["dc"] = {"multiplier": effect["dc_multiplier"], "end_time": end_time}
		if effect.has("at_multiplier"):
			active_boosters["at"] = {"multiplier": effect["at_multiplier"], "end_time": end_time}
		if effect.has("lab_boost"):
			active_boosters["lab"] = {"multiplier": effect["lab_boost"], "end_time": end_time}
		if effect.has("all_multiplier"):
			active_boosters["all"] = {"multiplier": effect["all_multiplier"], "end_time": end_time}

	# Data Disk Packs
	if effect.has("data_disks"):
		var count = effect["data_disks"]
		var rarity = effect.get("rarity", "random")
		for i in range(count):
			var disk_id = _get_random_disk_by_rarity(rarity)
			DataDiskManager.add_data_disk(disk_id)

	# Permanent upgrades are tracked in purchased_permanent_items

# --- BOOSTER QUERIES ---
func get_dc_multiplier() -> float:
	var multiplier = 1.0
	if active_boosters.has("dc"):
		multiplier += (active_boosters["dc"]["multiplier"] - 1.0)
	if active_boosters.has("all"):
		multiplier += (active_boosters["all"]["multiplier"] - 1.0)
	return multiplier

func get_at_multiplier() -> float:
	var multiplier = 1.0
	if active_boosters.has("at"):
		multiplier += (active_boosters["at"]["multiplier"] - 1.0)
	if active_boosters.has("all"):
		multiplier += (active_boosters["all"]["multiplier"] - 1.0)
	return multiplier

func get_lab_speed_multiplier() -> float:
	var multiplier = 1.0
	if active_boosters.has("lab"):
		multiplier += (active_boosters["lab"]["multiplier"] - 1.0)
	if active_boosters.has("all"):
		multiplier += (active_boosters["all"]["multiplier"] - 1.0)
	return multiplier

func get_offline_multiplier() -> float:
	var multiplier = 0.0
	for item_id in purchased_permanent_items:
		if SHOP_ITEMS.has(item_id) and SHOP_ITEMS[item_id]["effect"].has("offline_multiplier"):
			multiplier += SHOP_ITEMS[item_id]["effect"]["offline_multiplier"]
	return multiplier

func get_extra_lab_slots() -> int:
	var slots = 0
	for item_id in purchased_permanent_items:
		if SHOP_ITEMS.has(item_id) and SHOP_ITEMS[item_id]["effect"].has("lab_slots"):
			slots += SHOP_ITEMS[item_id]["effect"]["lab_slots"]
	return slots

func has_auto_prestige() -> bool:
	return "auto_prestige" in purchased_permanent_items

func get_global_damage_multiplier() -> float:
	if "global_damage_boost" in purchased_permanent_items:
		return 0.10
	return 0.0

func get_global_currency_multiplier() -> float:
	if "global_currency_boost" in purchased_permanent_items:
		return 0.10
	return 0.0

# --- HELPER FUNCTIONS ---
func _update_active_boosters() -> void:
	var current_time = Time.get_unix_time_from_system()
	var expired_boosters = []

	for booster_id in active_boosters.keys():
		if active_boosters[booster_id]["end_time"] <= current_time:
			expired_boosters.append(booster_id)

	for booster_id in expired_boosters:
		print("⏰ Booster expired: %s" % booster_id)
		active_boosters.erase(booster_id)

func _get_random_disk_by_rarity(rarity: String) -> String:
	var matching_disks = []
	for disk_id in DataDiskManager.DATA_DISK_TYPES.keys():
		if DataDiskManager.DATA_DISK_TYPES[disk_id]["rarity"] == rarity:
			matching_disks.append(disk_id)

	if matching_disks.is_empty():
		return DataDiskManager.get_random_disk_id()

	return matching_disks[randi() % matching_disks.size()]

# --- SAVE/LOAD ---
func save_shop_data() -> void:
	var save_data = {
		"purchased_permanent_items": purchased_permanent_items,
		"active_boosters": active_boosters
	}

	var save_path = "user://shop.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("💾 Shop data saved")
	else:
		push_error("❌ Failed to save shop data")

func load_shop_data() -> void:
	var save_path = "user://shop.save"
	if not FileAccess.file_exists(save_path):
		print("📂 No shop save file found, starting fresh")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		purchased_permanent_items = save_data.get("purchased_permanent_items", [])
		active_boosters = save_data.get("active_boosters", {})

		print("✅ Shop data loaded (%d permanent items purchased)" % purchased_permanent_items.size())
	else:
		push_error("❌ Failed to load shop data")

# --- DEBUG ---
func grant_test_qc(amount: int) -> void:
	RewardManager.add_quantum_cores(amount)
	print("🧪 Test: Granted %d QC" % amount)
