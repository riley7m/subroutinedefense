extends Node

# Milestone System - Battle Pass Style
# Tracks wave milestones and distributes rewards (Quantum Cores, Fragments, Data Disks, Lab Unlocks)

# --- SIGNALS ---
signal milestone_claimed(tier: int, wave: int, is_paid: bool)
signal milestone_reached(tier: int, wave: int, rewards: Dictionary)
signal paid_track_unlocked(tier: int)

# --- MILESTONE WAVES ---
const MILESTONE_WAVES := [10, 50, 100, 250, 500, 1000, 2000, 3000, 5000]

# --- TIER SCALING ---
const QUANTUM_CORES_BASE := 5000  # Total QC per tier (both tracks combined)
const FRAGMENTS_BASE := 50000     # Total fragments per tier (both tracks combined)
const QUANTUM_CORES_SCALING := 1.10  # 10% increase per tier
const FRAGMENTS_SCALING := 1.15      # 15% increase per tier

# --- DATA DISK REWARDS PER TIER ---
# Format: { tier: { 1000: "disk_id", 3000: "disk_id", 5000: "disk_id" } }
# Wave 1000 = paid track, Wave 3000 & 5000 = free track
const DATA_DISK_REWARDS := {
	1: {
		1000: "power_core",           # Paid: Damage boost
		3000: "hypervelocity",        # Free: Fire rate boost
		5000: "barrier_matrix"        # Free: Defense boost
	},
	2: {
		1000: "assault_protocol",     # Paid: Damage boost
		3000: "tactical_scanner",     # Free: Crit chance boost
		5000: "regenerative_field"    # Free: Shield regen
	},
	3: {
		1000: "annihilation_matrix",  # Paid: Damage boost
		3000: "cascade_trigger",      # Free: Fire rate boost
		5000: "credit_optimizer"      # Free: DC multiplier
	},
	4: {
		1000: "quantum_accelerator",  # Paid: Fire rate boost
		3000: "lethal_strike",        # Free: Crit damage boost
		5000: "reactive_plating"      # Free: Shield integrity
	},
	5: {
		1000: "weakpoint_finder",     # Paid: Crit chance boost
		3000: "nano_repair",          # Free: Shield regen
		5000: "archive_compiler"      # Free: AT multiplier
	},
	6: {
		1000: "execution_protocol",   # Paid: Crit damage (rare)
		3000: "hardened_shell",       # Free: Damage reduction
		5000: "loot_algorithm"        # Free: DC multiplier (rare)
	},
	7: {
		1000: "phantom_matrix",       # Paid: Precision multi-stat (rare)
		3000: "crystal_collector",    # Free: Fragment drop rate (rare)
		5000: "data_synthesizer"      # Free: AT multiplier (rare)
	},
	8: {
		1000: "titan_bane",           # Paid: Boss HP reduction (rare)
		3000: "colossus_killer",      # Free: Boss HP reduction (rare)
		5000: "time_dilation"         # Free: Wave skip chance (rare)
	},
	9: {
		1000: "warlord_core",         # Paid: Devastator multi-stat (epic)
		3000: "juggernaut_plating",   # Free: Overshield capacity (epic)
		5000: "probability_matrix"    # Free: Free upgrade chance (rare)
	},
	10: {
		1000: "devastator_core",      # Paid: Devastator multi-stat (epic)
		3000: "wealth_amplifier",     # Free: All currency boost (epic)
		5000: "boss_slayer"           # Free: Boss slayer multi-stat (epic)
	}
}

# --- MILESTONE REWARDS TEMPLATE (Tier 1) ---
# Format: { "free": {...}, "paid": {...} }
# Rewards scale exponentially - higher waves give MUCH bigger rewards
# Total per tier: 5,000 QC (2,250 free + 2,750 paid) + 50,000 Frag (22,500 free + 27,500 paid)
# Only 2 Lab unlocks per tier (waves 500 and 1000 free track)
const MILESTONE_REWARDS_TIER_1 := {
	10: {
		"free": {"quantum_cores": 15, "fragments": 150},
		"paid": {"quantum_cores": 20, "fragments": 200}
	},
	50: {
		"free": {"quantum_cores": 30, "fragments": 300},
		"paid": {"quantum_cores": 40, "fragments": 400}
	},
	100: {
		"free": {"quantum_cores": 50, "fragments": 500},
		"paid": {"quantum_cores": 60, "fragments": 600}
	},
	250: {
		"free": {"quantum_cores": 80, "fragments": 800},
		"paid": {"quantum_cores": 95, "fragments": 950}
	},
	500: {
		"free": {"quantum_cores": 125, "fragments": 1250, "lab_unlock": "tier1_lab1"},
		"paid": {"quantum_cores": 155, "fragments": 1550}
	},
	1000: {
		"free": {"quantum_cores": 205, "fragments": 2050, "lab_unlock": "tier1_lab2"},
		"paid": {"quantum_cores": 250, "fragments": 2500, "data_disk": "random"}
	},
	2000: {
		"free": {"quantum_cores": 330, "fragments": 3300},
		"paid": {"quantum_cores": 410, "fragments": 4100}
	},
	3000: {
		"free": {"quantum_cores": 540, "fragments": 5400, "data_disk": "random"},
		"paid": {"quantum_cores": 660, "fragments": 6600}
	},
	5000: {
		"free": {"quantum_cores": 875, "fragments": 8750, "data_disk": "random"},
		"paid": {"quantum_cores": 1060, "fragments": 10600}
	}
}

# --- SAVE DATA ---
# Format: { tier: { wave: { free: claimed, paid: claimed } } }
var claimed_milestones: Dictionary = {}

# Format: { tier: is_paid_unlocked }
var paid_tracks_unlocked: Dictionary = {}

# --- INITIALIZATION ---
func _ready() -> void:
	load_milestone_progress()

	# Priority 4.1: Connect to TierManager signal (breaks circular dependency)
	if TierManager:
		TierManager.wave_completed.connect(check_milestone_for_wave)

# --- MILESTONE CHECKING ---
func check_milestone_for_wave(tier: int, wave: int) -> void:
	if wave not in MILESTONE_WAVES:
		return

	# Auto-claim free track if reached
	if not has_claimed_milestone(tier, wave, false):
		claim_milestone(tier, wave, false)

func has_reached_milestone(tier: int, wave: int, current_wave: int) -> bool:
	return current_wave >= wave

func has_claimed_milestone(tier: int, wave: int, is_paid: bool) -> bool:
	if tier not in claimed_milestones:
		return false
	if wave not in claimed_milestones[tier]:
		return false

	var track_key = "paid" if is_paid else "free"
	return claimed_milestones[tier][wave].get(track_key, false)

func can_claim_milestone(tier: int, wave: int, is_paid: bool, current_wave: int) -> bool:
	# Must have reached the milestone wave
	if not has_reached_milestone(tier, wave, current_wave):
		return false

	# Must not have already claimed it
	if has_claimed_milestone(tier, wave, is_paid):
		return false

	# Paid track requires unlock
	if is_paid and not is_paid_track_unlocked(tier):
		return false

	return true

# --- PAID TRACK UNLOCK ---
func is_paid_track_unlocked(tier: int) -> bool:
	return paid_tracks_unlocked.get(tier, false)

func unlock_paid_track(tier: int) -> bool:
	if is_paid_track_unlocked(tier):
		print("⚠️ Paid track already unlocked for tier %d" % tier)
		return false

	# TODO: Implement payment system (fragments, real money, etc.)
	# For now, just unlock it
	paid_tracks_unlocked[tier] = true
	save_milestone_progress()
	emit_signal("paid_track_unlocked", tier)
	print("✅ Paid track unlocked for tier %d" % tier)
	return true

# --- REWARD CLAIMING ---
func claim_milestone(tier: int, wave: int, is_paid: bool) -> bool:
	if not can_claim_milestone(tier, wave, is_paid, TierManager.get_highest_wave_in_tier(tier)):
		print("❌ Cannot claim milestone tier %d wave %d (paid: %s)" % [tier, wave, is_paid])
		return false

	var rewards = get_rewards_for_milestone(tier, wave, is_paid)
	if rewards.is_empty():
		print("⚠️ No rewards found for tier %d wave %d (paid: %s)" % [tier, wave, is_paid])
		return false

	# Give rewards
	_give_rewards(rewards)

	# Mark as claimed
	if tier not in claimed_milestones:
		claimed_milestones[tier] = {}
	if wave not in claimed_milestones[tier]:
		claimed_milestones[tier][wave] = {"free": false, "paid": false}

	var track_key = "paid" if is_paid else "free"
	claimed_milestones[tier][wave][track_key] = true

	save_milestone_progress()
	emit_signal("milestone_claimed", tier, wave, is_paid)

	# Emit notification signal with rewards
	emit_signal("milestone_reached", tier, wave, rewards)

	print("✅ Claimed milestone tier %d wave %d (paid: %s)" % [tier, wave, is_paid])
	return true

func _give_rewards(rewards: Dictionary) -> void:
	# Quantum Cores
	if rewards.has("quantum_cores") and rewards["quantum_cores"] > 0:
		RewardManager.add_quantum_cores(rewards["quantum_cores"])
		print("🔮 +%d Quantum Cores" % rewards["quantum_cores"])

	# Fragments
	if rewards.has("fragments") and rewards["fragments"] > 0:
		RewardManager.add_fragments(rewards["fragments"])
		print("💎 +%d Fragments" % rewards["fragments"])

	# Data Disk (should always be a specific ID, never "random")
	if rewards.has("data_disk"):
		var disk_id = rewards["data_disk"]
		if disk_id == "random":
			push_error("❌ Data disk should not be 'random' - check DATA_DISK_REWARDS mapping")
			return
		DataDiskManager.add_data_disk(disk_id)
		var disk_name = DataDiskManager.DATA_DISK_TYPES.get(disk_id, {}).get("name", disk_id)
		print("📀 +1 Data Disk: %s" % disk_name)

	# Lab Unlock
	if rewards.has("lab_unlock"):
		var lab_id = rewards["lab_unlock"]
		SoftwareUpgradeManager.unlock_lab(lab_id)
		print("🔬 Lab Unlocked: %s" % lab_id)

# --- REWARD CALCULATION ---
func get_rewards_for_milestone(tier: int, wave: int, is_paid: bool) -> Dictionary:
	if wave not in MILESTONE_WAVES:
		return {}

	# Get base rewards from tier 1 template
	var base_rewards = MILESTONE_REWARDS_TIER_1.get(wave, {})
	var track_key = "paid" if is_paid else "free"
	var rewards = base_rewards.get(track_key, {}).duplicate()

	if rewards.is_empty():
		return {}

	# Scale rewards based on tier
	if tier > 1:
		var tier_multiplier_qc = pow(QUANTUM_CORES_SCALING, tier - 1)
		var tier_multiplier_frag = pow(FRAGMENTS_SCALING, tier - 1)

		if rewards.has("quantum_cores"):
			rewards["quantum_cores"] = int(rewards["quantum_cores"] * tier_multiplier_qc)

		if rewards.has("fragments"):
			rewards["fragments"] = int(rewards["fragments"] * tier_multiplier_frag)

		# Update lab IDs to match tier
		if rewards.has("lab_unlock"):
			var base_lab = rewards["lab_unlock"]
			rewards["lab_unlock"] = base_lab.replace("tier1", "tier%d" % tier)

	# Replace "random" data disk with specific disk ID for this tier
	if rewards.has("data_disk") and rewards["data_disk"] == "random":
		if DATA_DISK_REWARDS.has(tier) and DATA_DISK_REWARDS[tier].has(wave):
			rewards["data_disk"] = DATA_DISK_REWARDS[tier][wave]
		else:
			# Fallback to first disk if mapping not found
			push_warning("⚠️ No data disk mapping for tier %d wave %d, using fallback" % [tier, wave])
			rewards["data_disk"] = "damage_amplifier"

	return rewards

# --- SAVE/LOAD ---
func save_milestone_progress() -> void:
	var save_data = {
		"claimed_milestones": claimed_milestones,
		"paid_tracks_unlocked": paid_tracks_unlocked
	}

	var save_path = "user://milestone_progress.save"
	# H-002: Use SaveManager for unified save system
	if SaveManager.simple_save(save_path, save_data):
		print("💾 Milestone progress saved")
	else:
		push_error("❌ Failed to save milestone progress")

func load_milestone_progress() -> void:
	var save_path = "user://milestone_progress.save"

	# H-002: Use SaveManager for unified save system
	var save_data = SaveManager.simple_load(save_path)

	if save_data.is_empty():
		print("📂 No milestone save file found, starting fresh")
		return

	claimed_milestones = save_data.get("claimed_milestones", {})
	paid_tracks_unlocked = save_data.get("paid_tracks_unlocked", {})

	print("✅ Milestone progress loaded")

# --- UTILITY ---
func get_all_milestones_for_tier(tier: int) -> Array:
	var milestones = []
	for wave in MILESTONE_WAVES:
		milestones.append({
			"wave": wave,
			"free_rewards": get_rewards_for_milestone(tier, wave, false),
			"paid_rewards": get_rewards_for_milestone(tier, wave, true),
			"free_claimed": has_claimed_milestone(tier, wave, false),
			"paid_claimed": has_claimed_milestone(tier, wave, true)
		})
	return milestones

func get_total_rewards_for_tier(tier: int) -> Dictionary:
	var total_free_qc = 0
	var total_paid_qc = 0
	var total_free_frag = 0
	var total_paid_frag = 0
	var total_free_disks = 0
	var total_paid_disks = 0
	var total_labs = 0

	for wave in MILESTONE_WAVES:
		var free_rewards = get_rewards_for_milestone(tier, wave, false)
		var paid_rewards = get_rewards_for_milestone(tier, wave, true)

		total_free_qc += free_rewards.get("quantum_cores", 0)
		total_paid_qc += paid_rewards.get("quantum_cores", 0)
		total_free_frag += free_rewards.get("fragments", 0)
		total_paid_frag += paid_rewards.get("fragments", 0)

		if free_rewards.has("data_disk"):
			total_free_disks += 1
		if paid_rewards.has("data_disk"):
			total_paid_disks += 1
		if free_rewards.has("lab_unlock"):
			total_labs += 1

	return {
		"free_quantum_cores": total_free_qc,
		"paid_quantum_cores": total_paid_qc,
		"total_quantum_cores": total_free_qc + total_paid_qc,
		"free_fragments": total_free_frag,
		"paid_fragments": total_paid_frag,
		"total_fragments": total_free_frag + total_paid_frag,
		"free_data_disks": total_free_disks,
		"paid_data_disks": total_paid_disks,
		"total_data_disks": total_free_disks + total_paid_disks,
		"lab_unlocks": total_labs
	}
