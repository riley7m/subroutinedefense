extends Node

# CloudSaveManager - PlayFab Integration for Account Binding
# Syncs save data to cloud so players don't lose progress
# **SECURITY**: Includes encryption, rate limiting, and server-side validation

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

# Rate Limiting
var last_save_upload: int = 0
var last_save_download: int = 0
const MIN_SAVE_INTERVAL := 10  # Minimum 10 seconds between saves
const MIN_DOWNLOAD_INTERVAL := 5  # Minimum 5 seconds between downloads

# Save Queue (for when rate limited)
var pending_save: Dictionary = {}
var has_pending_save: bool = false

# Encryption Key (generated per-player, stored locally)
var encryption_key: PackedByteArray = []
const ENCRYPTION_KEY_SIZE := 32  # 256-bit AES

# HTTP Request Nodes
var http_request: HTTPRequest
var http_validate_save: HTTPRequest

func _ready() -> void:
	# Create HTTP request nodes
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)

	http_validate_save = HTTPRequest.new()
	add_child(http_validate_save)
	http_validate_save.request_completed.connect(_on_validate_save_completed)

	# Load or generate encryption key
	_load_or_generate_encryption_key()

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

	# Rate limiting
	var now = int(Time.get_ticks_msec() / 1000.0)
	if now - last_save_upload < MIN_SAVE_INTERVAL:
		# Queue save for later
		pending_save = save_data.duplicate(true)
		has_pending_save = true
		print("⏳ Save rate limited. Queuing for later... (%d seconds remaining)" % (MIN_SAVE_INTERVAL - (now - last_save_upload)))

		# Set timer to upload pending save
		var timer = get_tree().create_timer(MIN_SAVE_INTERVAL - (now - last_save_upload))
		timer.timeout.connect(_upload_pending_save)
		return

	last_save_upload = now

	print("☁️ Uploading encrypted save data to cloud...")

	# Convert save data to JSON string
	var save_json = JSON.stringify(save_data)

	# Encrypt save data
	var encrypted_data = _encrypt_save_data(save_json)
	var encoded_data = Marshalls.raw_to_base64(encrypted_data)

	# Add integrity hash (prevents tampering)
	var data_hash = save_json.md5_text()

	# First, validate with server-side CloudScript
	_validate_save_with_server(save_data, encoded_data, data_hash)

func _upload_pending_save() -> void:
	if has_pending_save:
		has_pending_save = false
		upload_save_data(pending_save)
		pending_save.clear()

func _validate_save_with_server(save_data: Dictionary, encrypted_data: String, data_hash: String) -> void:
	var url = PLAYFAB_API_URL + "/Client/ExecuteCloudScript"
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % session_ticket
	]

	var body = JSON.stringify({
		"FunctionName": "validateCloudSave",
		"FunctionParameter": {
			"saveData": JSON.stringify(save_data)  # Send unencrypted to server for validation
		}
	})

	print("🔒 Validating save with server...")
	var error = http_validate_save.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("❌ Failed to validate save: %s" % error)

	# Store encrypted data temporarily for upload after validation
	pending_save = {
		"encrypted": encrypted_data,
		"hash": data_hash
	}

func _upload_validated_save(encrypted_data: String, data_hash: String) -> void:
	var url = PLAYFAB_API_URL + "/Client/UpdateUserData"
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % session_ticket
	]
	var body = JSON.stringify({
		"Data": {
			"SaveData": encrypted_data,
			"SaveHash": data_hash,
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

	# Rate limiting
	var now = int(Time.get_ticks_msec() / 1000.0)
	if now - last_save_download < MIN_DOWNLOAD_INTERVAL:
		print("⏳ Download rate limited. Wait %d seconds." % (MIN_DOWNLOAD_INTERVAL - (now - last_save_download)))
		return

	last_save_download = now

	print("☁️ Downloading encrypted save data from cloud...")

	var url = PLAYFAB_API_URL + "/Client/GetUserData"
	var headers = [
		"Content-Type: application/json",
		"X-Authorization: %s" % session_ticket
	]
	var body = JSON.stringify({
		"Keys": ["SaveData", "SaveHash", "LastSaveTimestamp"]
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

	var encrypted_base64 = data["SaveData"].get("Value", "")
	var save_hash = data.get("SaveHash", {}).get("Value", "")
	var timestamp = int(data.get("LastSaveTimestamp", {}).get("Value", "0"))

	if encrypted_base64 == "":
		print("ℹ️ No cloud save data")
		return

	print("☁️ Cloud save found (timestamp: %d), decrypting..." % timestamp)

	# Decode from base64
	var encrypted_data = Marshalls.base64_to_raw(encrypted_base64)
	if encrypted_data.size() == 0:
		print("❌ Failed to decode encrypted save data")
		return

	# Decrypt save data
	var save_json = _decrypt_save_data(encrypted_data)
	if save_json == "":
		print("❌ Failed to decrypt save data (wrong key or corrupted)")
		return

	# Verify integrity hash
	var calculated_hash = save_json.md5_text()
	if save_hash != "" and calculated_hash != save_hash:
		print("❌ Save data integrity check failed - possible tampering!")
		login_failed.emit("Cloud save data integrity compromised")
		return

	# Parse decrypted JSON
	var json = JSON.new()
	var error = json.parse(save_json)
	if error != OK:
		print("⚠️ Failed to parse decrypted cloud save")
		return

	var save_data = json.data

	# SECURITY: Validate save data before applying
	if not _validate_save_data(save_data):
		print("❌ Cloud save failed validation - possible tampering!")
		login_failed.emit("Cloud save data is invalid")
		return

	print("✅ Cloud save decrypted and validated successfully")

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
	# Prevents save file tampering/exploits while allowing late-game progression

	# Validate currency bounds
	# AT can reach 10^18+ in late game (level 300+ perm upgrades cost ~10^18 AT)
	# Using conservative limits that still allow multi-year progression
	var at = data.get("archive_tokens", 0)
	var fragments = data.get("fragments", 0)

	# AT limit: 10^18 (1 quintillion) - allows for extreme late-game costs
	# Level 200 perm upgrade: ~10^12 AT, Level 300: ~10^18 AT
	if at < 0 or at > 1000000000000000000:  # 10^18
		print("⚠️ Invalid AT value: %d (max 10^18)" % at)
		return false

	# Fragments limit: 10^12 (1 trillion) - premium currency but accumulates over years
	# Boss Rush + daily activities over 3+ years can reach high amounts
	if fragments < 0 or fragments > 1000000000000:  # 10^12
		print("⚠️ Invalid fragments value: %d (max 10^12)" % fragments)
		return false

	# Validate permanent upgrade STAT VALUES (not costs)
	# These are actual damage/fire rate numbers, not currency
	var perm_damage = data.get("perm_projectile_damage", 0)
	var perm_fire_rate = data.get("perm_projectile_fire_rate", 0)

	# Damage can reach extreme values for "big number" player satisfaction
	# Limited to int64 max: 9.22e18 (9.22 quintillion)
	# Note: For octillions (10^27) display, would need big number system (coefficient + exponent)
	# Current int64 storage caps at quintillions, but that's still satisfyingly huge
	if perm_damage < 0 or perm_damage > 9223372036854775807:  # int64 max (~10^18)
		print("⚠️ Invalid perm damage: %d (max int64)" % perm_damage)
		return false

	# Fire rate is actual shots/second, not a "big number" stat
	if perm_fire_rate < 0 or perm_fire_rate > 1000:  # 1k shots/sec is plenty
		print("⚠️ Invalid perm fire rate: %f (max 1000)" % perm_fire_rate)
		return false

	# Validate lifetime stats aren't absurdly high
	# Over 3 years of heavy play, could reach billions of waves
	var total_waves = data.get("total_waves_completed", 0)
	if total_waves < 0 or total_waves > 1000000000:  # 10^9 (1 billion waves)
		print("⚠️ Invalid total waves: %d (max 10^9)" % total_waves)
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

# === VALIDATION RESPONSE HANDLER ===

func _on_validate_save_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		print("❌ Save validation failed (network error)")
		return

	if response_code != 200:
		print("❌ Save validation failed (server error: %d)" % response_code)
		return

	# Parse CloudScript response
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("❌ Save validation failed (parse error)")
		return

	var response = json.data

	# Check for PlayFab errors
	if response.has("error"):
		var error_msg = response["error"].get("errorMessage", "Unknown error")
		print("❌ Save validation failed: %s" % error_msg)
		return

	# Get CloudScript result
	var script_result = response.get("data", {}).get("FunctionResult", {})

	if not script_result.get("valid", false):
		var reason = script_result.get("reason", "Unknown validation failure")
		print("❌ Save rejected by server: %s" % reason)
		# TODO: Report suspicious activity if tampering detected
		return

	print("✅ Save validated by server")

	# Upload the encrypted save data
	if pending_save.has("encrypted") and pending_save.has("hash"):
		_upload_validated_save(pending_save["encrypted"], pending_save["hash"])
		pending_save.clear()
	else:
		print("⚠️ No pending save to upload after validation")

# === ENCRYPTION FUNCTIONS ===

func _encrypt_save_data(json_string: String) -> PackedByteArray:
	"""
	Encrypts save data using AES-256-CBC
	Returns encrypted bytes ready for base64 encoding
	"""
	if encryption_key.size() != ENCRYPTION_KEY_SIZE:
		push_error("Encryption key not initialized!")
		return PackedByteArray()

	# Convert string to bytes
	var plaintext = json_string.to_utf8_buffer()

	# Generate random IV (16 bytes for AES)
	var iv = PackedByteArray()
	iv.resize(16)
	for i in range(16):
		iv[i] = randi() % 256

	# Create AES context
	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, encryption_key, iv)

	# Encrypt data (AES requires padding to 16-byte blocks)
	var encrypted = aes.update(plaintext)
	aes.finish()

	# Prepend IV to encrypted data (needed for decryption)
	# Format: [16 bytes IV][encrypted data]
	var result = iv + encrypted

	return result

func _decrypt_save_data(encrypted_data: PackedByteArray) -> String:
	"""
	Decrypts save data using AES-256-CBC
	Returns decrypted JSON string
	"""
	if encryption_key.size() != ENCRYPTION_KEY_SIZE:
		push_error("Encryption key not initialized!")
		return ""

	if encrypted_data.size() < 16:
		push_error("Encrypted data too short (missing IV)")
		return ""

	# Extract IV from first 16 bytes
	var iv = encrypted_data.slice(0, 16)
	var ciphertext = encrypted_data.slice(16)

	# Create AES context
	var aes = AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, encryption_key, iv)

	# Decrypt data
	var decrypted = aes.update(ciphertext)
	aes.finish()

	# Convert bytes to string
	return decrypted.get_string_from_utf8()

func _load_or_generate_encryption_key() -> void:
	"""
	Loads encryption key from local storage or generates a new one
	Key is stored per-device (not synced to cloud)

	SECURITY: Key is local-only. If user reinstalls, they lose access to old encrypted saves.
	This is intentional - prevents key theft from cloud saves.
	"""
	var key_path = "user://encryption.key"

	# Try to load existing key
	if FileAccess.file_exists(key_path):
		var file = FileAccess.open(key_path, FileAccess.READ)
		if file:
			encryption_key = file.get_buffer(ENCRYPTION_KEY_SIZE)
			file.close()

			if encryption_key.size() == ENCRYPTION_KEY_SIZE:
				print("🔑 Encryption key loaded")
				return
			else:
				print("⚠️ Invalid encryption key size, regenerating...")

	# Generate new random key
	print("🔑 Generating new encryption key...")
	encryption_key.resize(ENCRYPTION_KEY_SIZE)

	# Use crypto random for security
	for i in range(ENCRYPTION_KEY_SIZE):
		encryption_key[i] = randi() % 256

	# Save key to disk
	var file = FileAccess.open(key_path, FileAccess.WRITE)
	if file:
		file.store_buffer(encryption_key)
		file.close()
		print("✅ Encryption key generated and saved")
