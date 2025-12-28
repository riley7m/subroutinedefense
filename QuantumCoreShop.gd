extends Node

# Quantum Core Shop System
# Players can spend QC (premium currency) or purchase direct IAP items
# Simplified monetization: Fragments, Lab Rush, Lab Slots, No Ads, Double Economy

# --- SIGNALS ---
signal item_purchased(item_id: String, cost: int)
signal qc_purchase_completed(pack_id: String, qc_amount: int, usd_cost: float)
signal iap_purchase_completed(iap_id: String, usd_cost: float)

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

# --- DIRECT IAP ITEMS (Real Money → Permanent Benefits) ---
const DIRECT_IAP_ITEMS := {
	"no_ads": {
		"name": "Remove Ads",
		"description": "Permanently remove all advertisements",
		"usd": 7.99,
		"icon": "🚫",
		"type": "permanent"
	},
	"double_economy": {
		"name": "Double Economy",
		"description": "Permanently double all currency drops (DC, AT, Fragments)",
		"usd": 9.99,
		"icon": "💰",
		"type": "permanent"
	}
}

# --- QC SHOP ITEMS (QC → Game Benefits) ---
# Conversion rate: 1 QC = 50 Fragments
const FRAGMENTS_PER_QC := 50

const SHOP_ITEMS := {
	# --- FRAGMENT BUNDLES (1 QC = 50 Fragments) ---
	"fragments_100": {
		"name": "Fragment Bundle (Tiny)",
		"description": "5,000 Fragments",
		"qc_cost": 100,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 5000}
	},
	"fragments_500": {
		"name": "Fragment Bundle (Small)",
		"description": "25,000 Fragments",
		"qc_cost": 500,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 25000}
	},
	"fragments_1000": {
		"name": "Fragment Bundle (Medium)",
		"description": "50,000 Fragments",
		"qc_cost": 1000,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 50000}
	},
	"fragments_2500": {
		"name": "Fragment Bundle (Large)",
		"description": "125,000 Fragments",
		"qc_cost": 2500,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 125000},
		"popular": true
	},
	"fragments_5000": {
		"name": "Fragment Bundle (Huge)",
		"description": "250,000 Fragments",
		"qc_cost": 5000,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 250000}
	},
	"fragments_10000": {
		"name": "Fragment Bundle (Mega)",
		"description": "500,000 Fragments",
		"qc_cost": 10000,
		"type": "consumable",
		"icon": "💎",
		"effect": {"fragments": 500000},
		"best_value": true
	},

	# --- LAB RUSH (25 QC per hour) ---
	"lab_rush": {
		"name": "Lab Rush",
		"description": "Reduce current lab research time (25 QC per hour)",
		"qc_cost": -1,  # Calculated dynamically
		"type": "consumable",
		"icon": "🔬",
		"effect": {"lab_rush": true}
	},

	# --- EXTRA LAB SLOTS (Permanent) ---
	"lab_slot_3": {
		"name": "Extra Lab Slot III",
		"description": "Research 3 labs simultaneously (permanent)",
		"qc_cost": 1000,
		"type": "permanent",
		"icon": "🔬",
		"effect": {"lab_slots": 3}
	},
	"lab_slot_4": {
		"name": "Extra Lab Slot IV",
		"description": "Research 4 labs simultaneously (permanent)",
		"qc_cost": 5000,
		"type": "permanent",
		"icon": "🔬",
		"effect": {"lab_slots": 4},
		"requires": "lab_slot_3"
	},
	"lab_slot_5": {
		"name": "Extra Lab Slot V",
		"description": "Research 5 labs simultaneously (permanent)",
		"qc_cost": 15000,
		"type": "permanent",
		"icon": "🔬",
		"effect": {"lab_slots": 5},
		"requires": "lab_slot_4"
	}
}

# --- PURCHASED ITEMS TRACKING ---
var purchased_permanent_items: Array = []  # QC permanent items
var purchased_iap_items: Array = []  # Direct IAP items

# --- DEV MODE ---
const DEV_MODE := true  # SET TO FALSE FOR PRODUCTION!

# --- INITIALIZATION ---
func _ready() -> void:
	load_shop_data()

# --- QC PURCHASE (Real Money → QC) ---
func purchase_qc_pack(pack_id: String) -> bool:
	if not QC_PURCHASE_PACKS.has(pack_id):
		push_error("❌ Invalid QC pack ID: %s" % pack_id)
		return false

	var pack = QC_PURCHASE_PACKS[pack_id]
	var qc_amount = pack["qc"]
	var usd_cost = pack["usd"]

	print("💳 Initiating QC purchase: %s ($%.2f for %d QC)" % [pack["name"], usd_cost, qc_amount])

	if not DEV_MODE:
		print("❌ IAP not implemented yet! Contact developer to enable payments.")
		return false
	else:
		# DEV MODE: Grant QC for free
		print("⚠️ DEV_MODE enabled - granting %d QC for free" % qc_amount)
		RewardManager.add_quantum_cores(qc_amount)
		emit_signal("qc_purchase_completed", pack_id, qc_amount, usd_cost)
		return true

# --- DIRECT IAP PURCHASE (Real Money → Permanent Benefit) ---
func purchase_direct_iap(iap_id: String) -> bool:
	if not DIRECT_IAP_ITEMS.has(iap_id):
		push_error("❌ Invalid IAP ID: %s" % iap_id)
		return false

	# Check if already purchased
	if iap_id in purchased_iap_items:
		print("❌ This item has already been purchased!")
		return false

	var iap = DIRECT_IAP_ITEMS[iap_id]
	var usd_cost = iap["usd"]

	print("💳 Initiating IAP purchase: %s ($%.2f)" % [iap["name"], usd_cost])

	if not DEV_MODE:
		print("❌ IAP not implemented yet! Contact developer to enable payments.")
		return false
	else:
		# DEV MODE: Grant for free
		print("⚠️ DEV_MODE enabled - granting %s for free" % iap["name"])
		purchased_iap_items.append(iap_id)
		save_shop_data()
		emit_signal("iap_purchase_completed", iap_id, usd_cost)
		print("✅ Purchased: %s" % iap["name"])
		return true

# --- SHOP ITEM PURCHASE (QC → Game Benefits) ---
func purchase_shop_item(item_id: String, hours_to_rush: int = 0) -> bool:
	if not SHOP_ITEMS.has(item_id):
		push_error("❌ Invalid shop item ID: %s" % item_id)
		return false

	var item = SHOP_ITEMS[item_id]
	var qc_cost = item["qc_cost"]

	# Special handling for lab rush (dynamic cost)
	if item_id == "lab_rush":
		if hours_to_rush <= 0:
			push_error("❌ Must specify hours to rush for lab_rush item")
			return false
		qc_cost = hours_to_rush * 25
		print("🔬 Lab Rush: %d hours = %d QC" % [hours_to_rush, qc_cost])

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
	_apply_item_effect(item_id, item["effect"], hours_to_rush)

	# Track permanent purchases
	if item["type"] == "permanent":
		purchased_permanent_items.append(item_id)

	save_shop_data()
	emit_signal("item_purchased", item_id, qc_cost)

	print("✅ Purchased: %s for %d QC" % [item["name"], qc_cost])
	return true

# --- APPLY ITEM EFFECTS ---
func _apply_item_effect(item_id: String, effect: Dictionary, hours_to_rush: int = 0) -> void:
	# Fragments
	if effect.has("fragments"):
		RewardManager.add_fragments(effect["fragments"])
		print("💎 +%d Fragments" % effect["fragments"])

	# Lab Rush
	if effect.has("lab_rush") and hours_to_rush > 0:
		if SoftwareUpgradeManager:
			var slot_index = SoftwareUpgradeManager.get_active_lab_slot()
			if slot_index >= 0:
				if SoftwareUpgradeManager.rush_upgrade(slot_index, hours_to_rush):
					print("⏩ Lab research rushed by %d hours!" % hours_to_rush)
				else:
					print("❌ Failed to rush lab research")
			else:
				print("⚠️ No active lab research to rush")
		else:
			print("❌ SoftwareUpgradeManager not available")

	# Lab slots tracked in purchased_permanent_items

# --- QUERY FUNCTIONS ---
func get_max_lab_slots() -> int:
	# Default is 1 lab slot (base game, but assuming we start with 2)
	var slots = 2  # Base game assumes 2 lab slots

	if "lab_slot_3" in purchased_permanent_items:
		slots = 3
	if "lab_slot_4" in purchased_permanent_items:
		slots = 4
	if "lab_slot_5" in purchased_permanent_items:
		slots = 5

	return slots

func has_no_ads() -> bool:
	return "no_ads" in purchased_iap_items

func has_double_economy() -> bool:
	return "double_economy" in purchased_iap_items

func get_economy_multiplier() -> float:
	return 2.0 if has_double_economy() else 1.0

# --- SAVE/LOAD ---
func save_shop_data() -> void:
	var save_data = {
		"purchased_permanent_items": purchased_permanent_items,
		"purchased_iap_items": purchased_iap_items
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
		purchased_iap_items = save_data.get("purchased_iap_items", [])

		print("✅ Shop data loaded (%d QC items, %d IAP items purchased)" % [purchased_permanent_items.size(), purchased_iap_items.size()])
	else:
		push_error("❌ Failed to load shop data")

# --- DEBUG ---
func grant_test_qc(amount: int) -> void:
	RewardManager.add_quantum_cores(amount)
	print("🧪 Test: Granted %d QC" % amount)
