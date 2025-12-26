extends Node

# CloudSaveManager - PlayFab Integration for Account Binding
# Syncs save data to cloud so players don't lose progress

# Signals
signal login_succeeded(player_id: String)
signal login_failed(error: String)
signal save_uploaded()
signal save_downloaded(data: Dictionary)
signal account_created(player_id: String)

# PlayFab Configuration
const PLAYFAB_TITLE_ID = "1DEAD6"  # Your PlayFab Title ID
const PLAYFAB_API_URL = "https://%s.playfabapi.com" % PLAYFAB_TITLE_ID

# Session State
var session_ticket: String = ""
var player_id: String = ""
var is_logged_in: bool = false
var is_guest: bool = true

# HTTP Request Node
var http_request: HTTPRequest

func _ready() -> void:
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)

	# Try to restore session from last login
	_try_restore_session()

# === AUTHENTICATION ===

func login_with_email(email: String, password: String) -> void:
	print("🔐 Logging in with email: %s" % email)

	var url = PLAYFAB_API_URL + "/Client/LoginWithEmailAddress"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"TitleId": PLAYFAB_TITLE_ID,
		"Email": email,
		"Password": password,
		"InfoRequestParameters": {
			"GetUserData": true
		}
	})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		login_failed.emit("HTTP request failed: %s" % error)

func register_with_email(email: String, password: String, username: String) -> void:
	print("📝 Registering new account: %s" % email)

	var url = PLAYFAB_API_URL + "/Client/RegisterPlayFabUser"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"TitleId": PLAYFAB_TITLE_ID,
		"Email": email,
		"Password": password,
		"Username": username,
		"RequireBothUsernameAndEmail": false
	})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		login_failed.emit("HTTP request failed: %s" % error)

func login_as_guest() -> void:
	print("👤 Logging in as guest (local only)")

	# Generate a unique device ID for this installation
	var device_id = _get_or_create_device_id()

	var url = PLAYFAB_API_URL + "/Client/LoginWithCustomID"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"TitleId": PLAYFAB_TITLE_ID,
		"CustomId": device_id,
		"CreateAccount": true,
		"InfoRequestParameters": {
			"GetUserData": true
		}
	})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		login_failed.emit("HTTP request failed: %s" % error)

func bind_email_to_guest(email: String, password: String) -> void:
	# Upgrades guest account to full account
	if not is_logged_in or not is_guest:
		print("⚠️ Can only bind email to guest accounts")
		return

	print("🔗 Binding email to guest account")

	var url = PLAYFAB_API_URL + "/Client/AddUsernamePassword"
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % session_ticket
	]
	var body = JSON.stringify({
		"Email": email,
		"Password": password,
		"Username": email.split("@")[0]  # Use email prefix as username
	})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		login_failed.emit("HTTP request failed: %s" % error)

# === CLOUD SAVE/LOAD ===

func upload_save_data(save_data: Dictionary) -> void:
	if not is_logged_in:
		print("⚠️ Not logged in - save not uploaded")
		return

	print("☁️ Uploading save data to cloud...")

	# Convert save data to JSON string
	var save_json = JSON.stringify(save_data)

	var url = PLAYFAB_API_URL + "/Client/UpdateUserData"
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % session_ticket
	]
	var body = JSON.stringify({
		"Data": {
			"SaveData": save_json,
			"LastSaveTimestamp": str(Time.get_unix_time_from_system())
		}
	})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("⚠️ Failed to upload save: %s" % error)

func download_save_data() -> void:
	if not is_logged_in:
		print("⚠️ Not logged in - cannot download save")
		return

	print("☁️ Downloading save data from cloud...")

	var url = PLAYFAB_API_URL + "/Client/GetUserData"
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % session_ticket
	]
	var body = JSON.stringify({
		"Keys": ["SaveData", "LastSaveTimestamp"]
	})

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("⚠️ Failed to download save: %s" % error)

# === HTTP RESPONSE HANDLING ===

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		login_failed.emit("Network error: %s" % result)
		return

	if response_code != 200:
		login_failed.emit("Server error: %s" % response_code)
		return

	# Parse response
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		login_failed.emit("Failed to parse response")
		return

	var response = json.data

	# Check for PlayFab errors
	if response.has("error"):
		var error_msg = response["error"].get("errorMessage", "Unknown error")
		login_failed.emit(error_msg)
		return

	# Handle success
	if response.has("data"):
		_handle_playfab_response(response["data"])

func _handle_playfab_response(data: Dictionary) -> void:
	# Handle login responses
	if data.has("SessionTicket"):
		session_ticket = data["SessionTicket"]
		player_id = data.get("PlayFabId", "")
		is_logged_in = true

		# Check if guest account
		if data.has("NewlyCreated") and data["NewlyCreated"]:
			is_guest = true
			print("✅ Logged in as guest (player ID: %s)" % player_id)
		else:
			is_guest = false
			print("✅ Logged in successfully (player ID: %s)" % player_id)

		# Save session
		_save_session()

		login_succeeded.emit(player_id)

		# Auto-download cloud save if exists
		if data.has("InfoResultPayload") and data["InfoResultPayload"].has("UserData"):
			var user_data = data["InfoResultPayload"]["UserData"]
			if user_data.has("SaveData"):
				_process_downloaded_save(user_data)
		else:
			# No cloud save yet, download explicitly
			download_save_data()

	# Handle save upload responses
	elif data.has("DataVersion"):
		print("✅ Save uploaded successfully!")
		save_uploaded.emit()

	# Handle save download responses
	elif data.has("Data"):
		_process_downloaded_save(data["Data"])

	# Handle account binding
	elif data.has("Username"):
		is_guest = false
		print("✅ Email bound to account!")
		_save_session()

func _process_downloaded_save(data: Dictionary) -> void:
	if not data.has("SaveData"):
		print("ℹ️ No cloud save found")
		return

	var save_json = data["SaveData"].get("Value", "{}")
	var timestamp = int(data.get("LastSaveTimestamp", {}).get("Value", "0"))

	print("☁️ Cloud save found (timestamp: %d)" % timestamp)

	# Parse save data
	var json = JSON.new()
	var error = json.parse(save_json)
	if error != OK:
		print("⚠️ Failed to parse cloud save")
		return

	var save_data = json.data

	# SECURITY: Validate save data before applying
	if not _validate_save_data(save_data):
		print("❌ Cloud save failed validation - possible tampering!")
		login_failed.emit("Cloud save data is invalid")
		return

	save_data["cloud_timestamp"] = timestamp
	save_downloaded.emit(save_data)

# === SESSION PERSISTENCE ===

func _save_session() -> void:
	var session_data = {
		"session_ticket": session_ticket,
		"player_id": player_id,
		"is_guest": is_guest,
	}

	var file = FileAccess.open("user://cloud_session.save", FileAccess.WRITE)
	if file:
		file.store_var(session_data)
		file.close()
		print("💾 Session saved")

func _try_restore_session() -> void:
	if not FileAccess.file_exists("user://cloud_session.save"):
		return

	var file = FileAccess.open("user://cloud_session.save", FileAccess.READ)
	if file:
		var session_data = file.get_var()
		file.close()

		if session_data and session_data is Dictionary:
			session_ticket = session_data.get("session_ticket", "")
			player_id = session_data.get("player_id", "")
			is_guest = session_data.get("is_guest", true)

			if session_ticket != "":
				is_logged_in = true
				print("🔄 Session restored (player ID: %s)" % player_id)
				# Note: Session may have expired, will fail on first API call

func _get_or_create_device_id() -> String:
	# Check if device ID exists
	if FileAccess.file_exists("user://device_id.save"):
		var file = FileAccess.open("user://device_id.save", FileAccess.READ)
		if file:
			var device_id = file.get_line()
			file.close()
			return device_id

	# Generate new device ID
	var device_id = _generate_uuid()
	var file = FileAccess.open("user://device_id.save", FileAccess.WRITE)
	if file:
		file.store_line(device_id)
		file.close()

	return device_id

func _generate_uuid() -> String:
	# Simple UUID v4 generation
	randomize()
	return "%08x-%04x-%04x-%04x-%012x" % [
		randi(),
		randi() & 0xffff,
		(randi() & 0x0fff) | 0x4000,
		(randi() & 0x3fff) | 0x8000,
		(randi() << 32) | randi()
	]

# === SAVE DATA VALIDATION ===

func _validate_save_data(data: Dictionary) -> bool:
	# Validate that all values are within reasonable bounds
	# Prevents save file tampering/exploits

	# Validate currency bounds (max 1 billion AT, 10 million fragments)
	var at = data.get("archive_tokens", 0)
	var fragments = data.get("fragments", 0)

	if at < 0 or at > 1000000000:
		print("⚠️ Invalid AT value: %d" % at)
		return false
	if fragments < 0 or fragments > 10000000:
		print("⚠️ Invalid fragments value: %d" % fragments)
		return false

	# Validate permanent upgrade levels (max 1000 per stat)
	var perm_damage = data.get("perm_projectile_damage", 0)
	var perm_fire_rate = data.get("perm_projectile_fire_rate", 0)

	if perm_damage < 0 or perm_damage > 100000:
		print("⚠️ Invalid perm damage: %d" % perm_damage)
		return false
	if perm_fire_rate < 0 or perm_fire_rate > 1000:
		print("⚠️ Invalid perm fire rate: %f" % perm_fire_rate)
		return false

	# Validate lifetime stats aren't absurdly high
	var total_waves = data.get("total_waves_completed", 0)
	if total_waves < 0 or total_waves > 100000000:  # 100 million waves max
		print("⚠️ Invalid total waves: %d" % total_waves)
		return false

	# All checks passed
	return true

# === UTILITY ===

func logout() -> void:
	session_ticket = ""
	player_id = ""
	is_logged_in = false
	is_guest = true

	# Remove session file
	if FileAccess.file_exists("user://cloud_session.save"):
		DirAccess.remove_absolute("user://cloud_session.save")

	print("👋 Logged out")

func get_player_info() -> Dictionary:
	return {
		"player_id": player_id,
		"is_logged_in": is_logged_in,
		"is_guest": is_guest,
	}
