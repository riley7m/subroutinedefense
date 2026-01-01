extends Node

# Boss Rush Mode Manager
# - Every wave spawns only bosses (Override)
# - Every 10 waves, add another boss (max 10 bosses at wave 100)
# - Faster enemy scaling than normal tiers
# - Leaderboard based on damage dealt, not waves survived
# - Available Mon/Thu/Sat for 24 hours (UTC 00:00 to 00:00)
# - Rewards fragments based on rank
# - **ONLINE**: Syncs with PlayFab global leaderboards

# Signals
signal boss_rush_started()
signal boss_rush_ended(damage_dealt: int, waves_survived: int)
signal leaderboard_updated()
signal online_leaderboard_loaded(entries: Array)
signal score_submitted(success: bool, rank: int)

# Boss Rush State
var is_active: bool = false
var current_run_damage: float = 0.0  # Float to handle BigNumber.to_float() without overflow
var current_run_wave: int = 0
var fragments_awarded_for_current_run: bool = false  # Prevent double fragment awards

# Online state
var is_online: bool = true
var last_online_fetch: int = 0
var last_score_submit: int = 0
const MIN_FETCH_INTERVAL := 60  # Fetch global leaderboard max once per minute
const MIN_SUBMIT_INTERVAL := 300  # Max 1 submission per 5 minutes (prevent spam)

# HTTP Nodes for PlayFab
var http_submit_score: HTTPRequest
var http_fetch_leaderboard: HTTPRequest
var http_validate_score: HTTPRequest

# PlayFab Configuration
const PLAYFAB_TITLE_ID := "1DEAD6"
const LEADERBOARD_NAME := "BossRushDamage"

# Boss Rush Configuration
const BOSS_HP_SCALING_BASE := 1.13  # 13% per wave (vs 2% normal)
const BOSS_ENEMY_MULTIPLIER := 5.0  # Base stats 5x higher than normal

# Tournament Schedule (UTC 00:00-00:00 on these days)
const TOURNAMENT_DAYS := [1, 4, 6]  # Monday=1, Thursday=4, Saturday=6

# Fragment Rewards by Rank
const FRAGMENT_REWARDS := {
	1: 5000,   # 1st place
	2: 3000,   # 2nd place
	3: 2000,   # 3rd place
	4: 1000,   # 4th-5th
	5: 1000,
	6: 500,    # 6th-10th
	7: 500,
	8: 500,
	9: 500,
	10: 500,
}
const PARTICIPATION_REWARD := 100  # For runs not in top 10

# Leaderboard (top 10 runs sorted by damage)
# Local cache + fallback if offline
# Each entry: {"damage": int, "waves": int, "tier": int, "timestamp": int, "player_id": String}
var leaderboard: Array = []
const MAX_LEADERBOARD_ENTRIES := 10

func _ready() -> void:
	# Create HTTP nodes for PlayFab
	http_submit_score = HTTPRequest.new()
	add_child(http_submit_score)
	http_submit_score.request_completed.connect(_on_submit_score_completed)

	http_fetch_leaderboard = HTTPRequest.new()
	add_child(http_fetch_leaderboard)
	http_fetch_leaderboard.request_completed.connect(_on_fetch_leaderboard_completed)

	http_validate_score = HTTPRequest.new()
	add_child(http_validate_score)
	http_validate_score.request_completed.connect(_on_validate_score_completed)

	load_leaderboard()

	# Try to fetch online leaderboard on startup
	fetch_online_leaderboard()

# === TOURNAMENT AVAILABILITY ===

func is_tournament_available() -> bool:
	# Check if current day is a tournament day (Mon/Thu/Sat)
	var datetime = Time.get_datetime_dict_from_system(true)  # true = UTC
	var weekday = datetime["weekday"]  # 0=Sunday, 1=Monday, ..., 6=Saturday
	return weekday in TOURNAMENT_DAYS

func get_next_tournament_time() -> Dictionary:
	# Returns {day_name: String, hours_until: int}
	var datetime = Time.get_datetime_dict_from_system(true)  # UTC
	var current_weekday = datetime["weekday"]

	# Find next tournament day
	var days_until = 7  # Default to a week away
	for day in TOURNAMENT_DAYS:
		var diff = day - current_weekday
		if diff <= 0:
			diff += 7  # Next week
		if diff < days_until:
			days_until = diff

	var day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	var next_day_index = (current_weekday + days_until) % 7
	var next_day_name = day_names[next_day_index]

	var hours_until = days_until * 24
	# Subtract hours/minutes already passed today
	hours_until -= datetime["hour"]
	hours_until -= int(datetime["minute"] / 60.0)

	return {
		"day_name": next_day_name,
		"hours_until": hours_until,
	}

# === BOSS RUSH CONTROL ===

func start_boss_rush() -> bool:
	if is_active:
		print("⚠️ Boss Rush already active!")
		return false

	is_active = true
	current_run_damage = 0.0
	current_run_wave = 0
	fragments_awarded_for_current_run = false  # Reset fragment award flag
	print("🏆 Boss Rush started!")
	boss_rush_started.emit()
	return true

func end_boss_rush(final_damage: float, final_wave: int) -> void:
	if not is_active:
		return

	is_active = false
	current_run_damage = final_damage
	current_run_wave = final_wave

	print("🏆 Boss Rush ended! Damage: %d, Waves: %d" % [final_damage, final_wave])

	# Add to local leaderboard (cache/fallback)
	add_leaderboard_entry(final_damage, final_wave)

	# Submit to online leaderboard (with server-side validation)
	if is_online and CloudSaveManager and CloudSaveManager.is_logged_in:
		submit_score_online(final_damage, final_wave)
	else:
		# Offline mode: just use local leaderboard for rank
		var rank = get_rank_for_damage(final_damage)
		_award_fragments_for_rank(rank)
		print("📡 Offline mode: Score saved locally only")

	boss_rush_ended.emit(final_damage, final_wave)

func is_boss_rush_active() -> bool:
	return is_active

# === BOSS RUSH MECHANICS ===

func get_boss_count_for_wave(wave: int) -> int:
	# Every 10 waves adds a boss (1-10, max 10 bosses)
	return mini(1 + int(wave / 10.0), 10)

func get_boss_rush_hp_multiplier(wave: int) -> float:
	# Exponential HP scaling for Boss Rush tournament
	# Formula: (1.13 ^ wave) * 5.0
	#
	# - Base scaling: 1.13^wave (13% increase per wave, vs 2% in normal mode)
	# - Enemy multiplier: 5x base HP for all bosses
	#
	# This creates rapid difficulty scaling:
	# - Wave 1: 1.13^1 * 5 = 5.65x base HP
	# - Wave 5: 1.13^5 * 5 = 9.24x base HP
	# - Wave 10: 1.13^10 * 5 = 16.97x base HP
	# - Wave 20: 1.13^20 * 5 = 57.59x base HP
	# - Wave 50: 1.13^50 * 5 = 2,249x base HP
	# - Wave 100: 1.13^100 * 5 = 1.01e6x (requires BigNumber)
	# - Wave 500: 1.13^500 * 5 = 1.9e25x (catastrophic overflow without BigNumber)
	#
	# This aggressive scaling ensures Boss Rush ends quickly (5-15 minutes)
	# and rewards top-tier builds for leaderboard competition

	# For low waves, use fast float calculation
	if wave < 100:
		return pow(BOSS_HP_SCALING_BASE, wave) * BOSS_ENEMY_MULTIPLIER

	# For high waves, use BigNumber to prevent overflow
	var multiplier_bn = BigNumber.new(BOSS_ENEMY_MULTIPLIER)
	var wave_multiplier = pow(BOSS_HP_SCALING_BASE, wave)
	multiplier_bn.multiply(wave_multiplier)
	return multiplier_bn.to_float()

func get_boss_rush_damage_multiplier() -> float:
	# Bosses deal 5x base damage
	return BOSS_ENEMY_MULTIPLIER

func get_boss_rush_speed_multiplier() -> float:
	# Bosses move at 3x speed
	return 3.0

# === ONLINE LEADERBOARD (PlayFab) ===

## Submit score to PlayFab with server-side validation
func submit_score_online(damage: float, waves: int) -> void:
	# Rate limiting: prevent spam submissions
	var now = int(Time.get_unix_time_from_system())
	if now - last_score_submit < MIN_SUBMIT_INTERVAL:
		print("⚠️ Score submission too frequent. Wait %d seconds." % (MIN_SUBMIT_INTERVAL - (now - last_score_submit)))
		# Still award fragments based on local rank
		var rank = get_rank_for_damage(damage)
		_award_fragments_for_rank(rank)
		return

	last_score_submit = now

	# Step 1: Validate with CloudScript (server-side anti-cheat)
	validate_score_with_server(damage, waves)

## Validate score with PlayFab CloudScript (server-side anti-cheat)
func validate_score_with_server(damage: float, waves: int) -> void:
	if not CloudSaveManager or not CloudSaveManager.session_ticket:
		print("❌ Not logged in to PlayFab")
		return

	var url = "https://%s.playfabapi.com/Client/ExecuteCloudScript" % PLAYFAB_TITLE_ID
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % CloudSaveManager.session_ticket
	]

	var body = JSON.stringify({
		"FunctionName": "validateBossRushScore",
		"FunctionParameter": {
			"damage": damage,
			"waves": waves,
			"tier": TierManager.get_current_tier() if TierManager else 1,
			"timestamp": int(Time.get_unix_time_from_system())
		}
	})

	print("🔒 Validating score with server...")
	var err = http_validate_score.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("❌ Failed to send validation request: %d" % err)
		is_online = false

## Submit validated score to PlayFab leaderboard
func _submit_validated_score(damage: float, waves: int) -> void:
	if not CloudSaveManager or not CloudSaveManager.session_ticket:
		return

	var url = "https://%s.playfabapi.com/Client/UpdatePlayerStatistics" % PLAYFAB_TITLE_ID
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % CloudSaveManager.session_ticket
	]

	var body = JSON.stringify({
		"Statistics": [
			{
				"StatisticName": LEADERBOARD_NAME,
				"Value": damage
			},
			{
				"StatisticName": "BossRushWaves",
				"Value": waves
			}
		]
	})

	print("📊 Submitting score to global leaderboard...")
	var err = http_submit_score.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("❌ Failed to submit score: %d" % err)
		is_online = false

## Fetch global leaderboard from PlayFab
func fetch_online_leaderboard() -> void:
	# Rate limiting
	var now = int(Time.get_unix_time_from_system())
	if now - last_online_fetch < MIN_FETCH_INTERVAL:
		print("⏳ Leaderboard fetch too frequent. Using cache.")
		return

	last_online_fetch = now

	if not CloudSaveManager or not CloudSaveManager.session_ticket:
		print("📡 Not logged in, using local leaderboard")
		is_online = false
		return

	var url = "https://%s.playfabapi.com/Client/GetLeaderboard" % PLAYFAB_TITLE_ID
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % CloudSaveManager.session_ticket
	]

	var body = JSON.stringify({
		"StatisticName": LEADERBOARD_NAME,
		"StartPosition": 0,
		"MaxResultsCount": MAX_LEADERBOARD_ENTRIES
	})

	print("📡 Fetching global leaderboard...")
	var err = http_fetch_leaderboard.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("❌ Failed to fetch leaderboard: %d" % err)
		is_online = false

# === HTTP RESPONSE HANDLERS ===

func _on_validate_score_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("❌ Score validation failed: HTTP %d" % response_code)
		is_online = false
		# Award fragments based on local rank anyway
		var rank = get_rank_for_damage(current_run_damage)
		_award_fragments_for_rank(rank)
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		print("❌ Failed to parse validation response")
		return

	var response = json.data
	if not response.has("data") or not response["data"].has("FunctionResult"):
		print("❌ Invalid validation response format")
		return

	var validation_result = response["data"]["FunctionResult"]

	if validation_result.get("valid", false):
		print("✅ Score validated by server!")
		# Now submit the score
		_submit_validated_score(current_run_damage, current_run_wave)
	else:
		var reason = validation_result.get("reason", "Unknown")
		print("❌ Server rejected score: %s" % reason)
		# Award participation fragments only
		_award_fragments_for_rank(999)

func _on_submit_score_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("❌ Score submission failed: HTTP %d" % response_code)
		is_online = false
		# Award fragments based on local rank as fallback
		var rank = get_rank_for_damage(current_run_damage)
		_award_fragments_for_rank(rank)
		return

	print("✅ Score submitted successfully!")

	# Fetch updated leaderboard to get player's rank
	fetch_online_leaderboard()

func _on_fetch_leaderboard_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("❌ Leaderboard fetch failed: HTTP %d" % response_code)
		is_online = false
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		print("❌ Failed to parse leaderboard response")
		return

	var response = json.data
	if not response.has("data") or not response["data"].has("Leaderboard"):
		print("❌ Invalid leaderboard response format")
		return

	var entries = response["data"]["Leaderboard"]
	print("📊 Global leaderboard fetched: %d entries" % entries.size())

	# Convert PlayFab entries to local format
	leaderboard.clear()
	var player_rank = 0
	for i in range(entries.size()):
		var entry = entries[i]
		var player_id = entry.get("PlayFabId", "")
		var damage_val = entry.get("StatValue", 0)

		leaderboard.append({
			"damage": damage_val,
			"waves": 0,  # Would need separate call to get this
			"tier": 0,
			"timestamp": 0,
			"player_id": player_id,
			"position": entry.get("Position", i)
		})

		# Check if this is the current player
		if CloudSaveManager and player_id == CloudSaveManager.player_id:
			player_rank = entry.get("Position", 0) + 1  # Position is 0-indexed

	save_leaderboard()
	online_leaderboard_loaded.emit(leaderboard)
	leaderboard_updated.emit()

	# Award fragments based on global rank
	if player_rank > 0:
		_award_fragments_for_rank(player_rank)
		score_submitted.emit(true, player_rank)
		print("🏆 Global rank: #%d" % player_rank)
	elif current_run_damage > 0:
		# Player not in top 10, award participation
		_award_fragments_for_rank(999)
		score_submitted.emit(true, 999)

## Helper: Award fragments based on rank
func _award_fragments_for_rank(rank: int) -> void:
	# Prevent double fragment awards for the same run
	if fragments_awarded_for_current_run:
		print("⚠️ Fragments already awarded for this run")
		return

	# Set flag BEFORE awarding to prevent race condition
	fragments_awarded_for_current_run = true

	var fragments = get_fragment_reward_for_rank(rank)
	if fragments > 0 and RewardManager:
		RewardManager.add_fragments(fragments)
		print("💎 Awarded %d fragments for rank #%d!" % [fragments, rank])

# === LOCAL LEADERBOARD (Fallback/Cache) ===

func add_leaderboard_entry(damage: float, waves: int) -> void:
	var entry = {
		"damage": damage,
		"waves": waves,
		"tier": TierManager.get_current_tier() if TierManager else 1,
		"timestamp": int(Time.get_unix_time_from_system()),
	}

	leaderboard.append(entry)

	# Sort by damage (descending)
	leaderboard.sort_custom(func(a, b): return a["damage"] > b["damage"])

	# Keep top 10
	if leaderboard.size() > MAX_LEADERBOARD_ENTRIES:
		leaderboard.resize(MAX_LEADERBOARD_ENTRIES)

	save_leaderboard()
	leaderboard_updated.emit()
	print("📊 Leaderboard updated! New entry: %d damage, %d waves" % [damage, waves])

func get_leaderboard() -> Array:
	return leaderboard.duplicate()

func clear_leaderboard() -> void:
	leaderboard.clear()
	save_leaderboard()
	leaderboard_updated.emit()
	print("🗑️ Leaderboard cleared!")

# === SAVE/LOAD ===

func save_leaderboard() -> void:
	var save_data = {
		"leaderboard": leaderboard,
		"version": 1,
	}

	var save_path = "user://boss_rush_leaderboard.save"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("💾 Boss rush leaderboard saved")
	else:
		print("⚠️ Failed to save boss rush leaderboard")

func load_leaderboard() -> void:
	var save_path = "user://boss_rush_leaderboard.save"
	if not FileAccess.file_exists(save_path):
		print("📊 No boss rush leaderboard found, starting fresh")
		return

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		if save_data and save_data is Dictionary:
			leaderboard = save_data.get("leaderboard", [])
			print("📊 Boss rush leaderboard loaded: %d entries" % leaderboard.size())
		else:
			print("⚠️ Invalid boss rush leaderboard data")
	else:
		print("⚠️ Failed to load boss rush leaderboard")

# === UTILITY ===

func format_damage(damage: float) -> String:
	if damage < 1000:
		return str(damage)
	elif damage < 1000000:
		return "%.1fK" % (damage / 1000.0)
	elif damage < 1000000000:
		return "%.1fM" % (damage / 1000000.0)
	else:
		return "%.1fB" % (damage / 1000000000.0)

func get_rank_for_damage(damage: float) -> int:
	# Returns what rank this damage would place (1 = best)
	var rank = 1
	for entry in leaderboard:
		if entry["damage"] > damage:
			rank += 1
	return rank

func get_fragment_reward_for_rank(rank: int) -> int:
	# Returns fragment reward for a given rank
	if rank in FRAGMENT_REWARDS:
		return FRAGMENT_REWARDS[rank]
	elif rank <= MAX_LEADERBOARD_ENTRIES:
		# Shouldn't happen, but safety fallback
		return PARTICIPATION_REWARD
	else:
		# Not in top 10, but still participated
		return PARTICIPATION_REWARD
