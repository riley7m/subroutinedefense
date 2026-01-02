extends Node

# Daily Reward Manager
# Handles daily reward claims with increasing tiers and countdown timers

# Daily Reward Tiers (rewards increase each consecutive day claimed)
const DAILY_REWARD_TIERS = [
	{"day": 1, "fragments": 50, "qc": 10},
	{"day": 2, "fragments": 75, "qc": 15},
	{"day": 3, "fragments": 100, "qc": 20},
	{"day": 4, "fragments": 150, "qc": 30},
	{"day": 5, "fragments": 200, "qc": 40},
	{"day": 6, "fragments": 300, "qc": 60},
	{"day": 7, "fragments": 500, "qc": 100},  # Bonus 7-day reward
]

# State
var last_claim_timestamp: int = 0  # Unix timestamp of last claim
var current_streak: int = 0  # How many consecutive days claimed (0-6)
var can_claim: bool = true  # Whether reward is ready to claim

# Constants
const SECONDS_PER_DAY = 86400  # 24 hours
const SAVE_FILE = "user://daily_rewards.save"

signal reward_claimed(fragments: int, qc: int, streak: int)
signal reward_ready()

func _ready() -> void:
	load_data()
	_check_reward_status()

	# Add timer to check reward status periodically (every 60 seconds)
	var check_timer = Timer.new()
	check_timer.name = "RewardCheckTimer"
	check_timer.wait_time = 60.0
	check_timer.autostart = true
	check_timer.timeout.connect(_check_reward_status)
	add_child(check_timer)

	print("🎁 DailyRewardManager initialized (Streak: %d)" % current_streak)

func _notification(what: int) -> void:
	# Save on app pause/background
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_data()

# Check if reward is ready to claim
func _check_reward_status() -> void:
	var old_can_claim = can_claim
	can_claim = is_reward_ready()

	# Emit signal when reward becomes ready
	if can_claim and not old_can_claim:
		emit_signal("reward_ready")

# Returns true if reward can be claimed now
func is_reward_ready() -> bool:
	if last_claim_timestamp == 0:
		return true  # First time ever

	var now = Time.get_unix_time_from_system()
	var seconds_since_claim = now - last_claim_timestamp

	return seconds_since_claim >= SECONDS_PER_DAY

# Returns seconds until next reward is ready (0 if ready now)
func get_seconds_until_ready() -> int:
	if last_claim_timestamp == 0:
		return 0  # Ready immediately

	var now = Time.get_unix_time_from_system()
	var seconds_since_claim = now - last_claim_timestamp
	var seconds_remaining = SECONDS_PER_DAY - seconds_since_claim

	return max(0, seconds_remaining)

# Returns formatted time string (e.g., "2d 6h", "5h 30m", "45m")
func get_time_until_ready_string() -> String:
	var seconds = get_seconds_until_ready()

	if seconds == 0:
		return "Ready!"

	var days = seconds / 86400
	var hours = (seconds % 86400) / 3600
	var minutes = (seconds % 3600) / 60

	if days > 0:
		return "%dd %dh" % [days, hours]
	elif hours > 0:
		return "%dh %dm" % [hours, minutes]
	else:
		return "%dm" % minutes

# Claim daily reward (returns dictionary with reward info if successful, empty dict if failed)
func claim_reward() -> Dictionary:
	if not is_reward_ready():
		print("⚠️ Daily reward not ready yet!")
		return {}

	# Calculate streak
	var now = Time.get_unix_time_from_system()

	if last_claim_timestamp == 0:
		# First time claiming
		current_streak = 0
	else:
		var seconds_since_claim = now - last_claim_timestamp
		var days_since_claim = seconds_since_claim / SECONDS_PER_DAY

		# If claimed within 48 hours (1-2 days), continue streak
		# If more than 48 hours, reset streak to 0
		if days_since_claim <= 2:
			current_streak = (current_streak + 1) % 7  # Cycle back to 0 after day 7
		else:
			current_streak = 0  # Missed a day, reset streak

	# Get reward for current streak tier (BEFORE incrementing)
	var reward_tier = DAILY_REWARD_TIERS[current_streak]
	var fragments = reward_tier["fragments"]
	var qc = reward_tier["qc"]
	var day_claimed = current_streak + 1

	# Award rewards
	if RewardManager:
		RewardManager.add_fragments(fragments)
		RewardManager.add_quantum_cores(qc)

	# Update state
	last_claim_timestamp = now
	can_claim = false

	# Save immediately
	save_data()

	# Emit signal
	emit_signal("reward_claimed", fragments, qc, day_claimed)

	print("🎁 Daily reward claimed! Day %d: %d 💎 + %d 🔮" % [day_claimed, fragments, qc])

	# Return claimed reward info
	return {
		"fragments": fragments,
		"qc": qc,
		"day": day_claimed
	}

# Get current reward info (what will be claimed)
func get_current_reward_info() -> Dictionary:
	# Calculate what streak we're on
	var streak_index = current_streak

	if last_claim_timestamp > 0:
		var now = Time.get_unix_time_from_system()
		var seconds_since_claim = now - last_claim_timestamp
		var days_since_claim = seconds_since_claim / SECONDS_PER_DAY

		# If we're ready to claim, it's the next day in the streak
		if is_reward_ready():
			if days_since_claim <= 2:
				streak_index = (current_streak + 1) % 7
			else:
				streak_index = 0  # Reset to day 1

	var reward_tier = DAILY_REWARD_TIERS[streak_index]

	return {
		"day": streak_index + 1,
		"fragments": reward_tier["fragments"],
		"qc": reward_tier["qc"],
		"ready": is_reward_ready()
	}

# Get all 7 reward tiers (for UI display)
func get_all_reward_tiers() -> Array:
	return DAILY_REWARD_TIERS.duplicate()

# === PERSISTENCE ===

func save_data() -> void:
	var data = {
		"last_claim_timestamp": last_claim_timestamp,
		"current_streak": current_streak,
	}

	# H-002: Use SaveManager for unified save system
	if not SaveManager.simple_save(SAVE_FILE, data):
		push_error("❌ Failed to save daily rewards")

func load_data() -> void:
	# H-002: Use SaveManager for unified save system
	var data = SaveManager.simple_load(SAVE_FILE)

	if data.is_empty():
		print("🎁 No daily reward save found - starting fresh")
		return

	last_claim_timestamp = data.get("last_claim_timestamp", 0)
	current_streak = clamp(data.get("current_streak", 0), 0, 6)

	print("🎁 Daily rewards loaded (Last claim: %d, Streak: %d)" % [last_claim_timestamp, current_streak])
