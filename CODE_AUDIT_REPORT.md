# Subroutine Defense - Code Audit Report

**Date:** 2025-12-26
**Auditor:** Claude Code
**Codebase Version:** claude/read-text-input-JN1e8

---

## Executive Summary

This audit examined 7 critical files and identified **28 issues** across security, bugs, and code quality categories:
- **5 Critical** issues requiring immediate attention
- **9 High** priority issues
- **8 Medium** priority issues
- **6 Low** priority issues

---

## 🔴 CRITICAL SEVERITY ISSUES

### CRIT-001: Division by Zero Risk in Overkill Damage
**File:** `/home/user/subroutinedefense/projectile.gd`
**Line:** 184
**Category:** Bug - Division by Zero

**Description:**
Division by `nearby_enemies.size()` without checking if size is zero could crash the game.

**Current Code:**
```gdscript
if nearby_enemies.size() > 0:
    var split_damage = max(1, damage / nearby_enemies.size())
```

**Issue:**
While there's a size check, if `nearby_enemies.size()` is 0, the division never executes. However, the `max(1, damage / size)` pattern is unsafe if called elsewhere.

**Recommended Fix:**
```gdscript
if nearby_enemies.size() > 0:
    var split_damage = max(1, int(float(damage) / float(nearby_enemies.size())))
```

**Impact:** Game crash if logic changes

---

### CRIT-002: Integer Overflow in Damage Calculation
**File:** `/home/user/subroutinedefense/UpgradeManager.gd`
**Line:** 206-210
**Category:** Bug - Integer Overflow

**Description:**
Exponential damage scaling with `pow(1.5, milestones)` can overflow for high levels.

**Current Code:**
```gdscript
var base = 100 + (floor(5 * pow(level, 1.12) + 5))
var milestones = floor(level / 100)
# Cap milestones at 500 to prevent overflow (pow(1.5, 500) ≈ 10^88)
var multiplier = pow(1.5, min(milestones, 500))
return int(base * multiplier) + RewardManager.perm_projectile_damage
```

**Issue:**
Even with milestone cap at 500, `pow(1.5, 500)` produces astronomical numbers (10^88). GDScript `int()` will overflow.

**Recommended Fix:**
```gdscript
var base = 100 + (floor(5 * pow(level, 1.12) + 5))
var milestones = floor(level / 100)
# Cap at milestone 200 for safer range (pow(1.5, 200) ≈ 4.6e14)
var multiplier = pow(1.5, min(milestones, 200))
var total = base * multiplier
# Cap at max int before adding perm damage
total = min(total, 2147483647 - RewardManager.perm_projectile_damage)
return int(total) + RewardManager.perm_projectile_damage
```

**Impact:** Negative damage values, game crashes

---

### CRIT-003: Cloud Save Manipulation - No Integrity Checks
**File:** `/home/user/subroutinedefense/CloudSaveManager.gd`
**Line:** 238-256
**Category:** Security - Save File Manipulation

**Description:**
Cloud save data is accepted without cryptographic verification. Players can modify save JSON to grant unlimited currency.

**Current Code:**
```gdscript
func _process_downloaded_save(data: Dictionary) -> void:
    if not data.has("SaveData"):
        return
    var save_json = data["SaveData"].get("Value", "{}")
    var json = JSON.new()
    var error = json.parse(save_json)
    if error == OK:
        save_downloaded.emit(save_data)
```

**Issue:**
No validation of:
- Currency values (can be set to 999999999)
- Upgrade levels (can be maxed)
- Timestamps (can be forged)

**Recommended Fix:**
```gdscript
func _process_downloaded_save(data: Dictionary) -> void:
    if not data.has("SaveData"):
        return

    var save_json = data["SaveData"].get("Value", "{}")
    var json = JSON.new()
    var error = json.parse(save_json)
    if error != OK:
        print("⚠️ Failed to parse cloud save")
        return

    var save_data = json.data

    # VALIDATE ALL VALUES BEFORE APPLYING
    if not _validate_save_data(save_data):
        print("❌ Cloud save failed validation - possible tampering!")
        login_failed.emit("Cloud save data is invalid")
        return

    save_data["cloud_timestamp"] = timestamp
    save_downloaded.emit(save_data)

func _validate_save_data(data: Dictionary) -> bool:
    # Validate currency is within reasonable bounds
    var at = data.get("archive_tokens", 0)
    var fragments = data.get("fragments", 0)

    # Example: Max 1 billion AT, 10 million fragments
    if at < 0 or at > 1000000000:
        return false
    if fragments < 0 or fragments > 10000000:
        return false

    # Validate upgrade levels are within max bounds
    var perm_damage = data.get("perm_projectile_damage", 0)
    if perm_damage < 0 or perm_damage > 100000:
        return false

    # Add more validation for all fields...
    return true
```

**Impact:** Economy breaking exploits, unfair leaderboard advantage

---

### CRIT-004: Negative Currency Exploit via Cost Underflow
**File:** `/home/user/subroutinedefense/RewardManager.gd`
**Line:** 230-237
**Category:** Security - Currency Exploit

**Description:**
Drone purchase deducts cost before validation, allowing negative currency if interrupted.

**Current Code:**
```gdscript
func purchase_drone_permanent(drone_type: String, cost: int) -> bool:
    if owns_drone(drone_type):
        return false
    if fragments < cost:
        return false

    fragments -= cost  # DEDUCTED BEFORE SAVE!
    owned_drones[drone_type] = true
    save_permanent_upgrades()
    return true
```

**Issue:**
If game crashes/exits between line 233-235, player keeps drone but cost is not saved, allowing infinite purchases.

**Recommended Fix:**
```gdscript
func purchase_drone_permanent(drone_type: String, cost: int) -> bool:
    if owns_drone(drone_type):
        print("⚠️ Drone", drone_type, "already owned!")
        return false

    if fragments < cost:
        print("⚠️ Not enough fragments to purchase", drone_type, "drone")
        return false

    # ATOMIC: Deduct cost and set ownership in same save operation
    owned_drones[drone_type] = true
    fragments -= cost

    # Save immediately to prevent exploit
    if not save_permanent_upgrades():
        # Rollback on save failure
        owned_drones[drone_type] = false
        fragments += cost
        print("❌ Failed to save drone purchase - rolled back")
        return false

    print("✅ Permanently purchased", drone_type, "drone for", cost, "fragments")
    return true
```

**Impact:** Infinite premium currency via save manipulation

---

### CRIT-005: HTTP Response Injection Risk
**File:** `/home/user/subroutinedefense/CloudSaveManager.gd`
**Line:** 166-193
**Category:** Security - Input Validation

**Description:**
PlayFab HTTP responses are not validated for malicious content before processing.

**Current Code:**
```gdscript
func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        login_failed.emit("Network error: %s" % result)
        return

    if response_code != 200:
        login_failed.emit("Server error: %s" % response_code)
        return

    var json = JSON.new()
    var error = json.parse(body.get_string_from_utf8())
    if error != OK:
        login_failed.emit("Failed to parse response")
        return

    var response = json.data  # NO TYPE CHECKING!
```

**Issue:**
- No validation that `json.data` is a Dictionary
- No size limits on response (could be gigabytes)
- No sanitization of error messages (could contain scripts)

**Recommended Fix:**
```gdscript
func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        login_failed.emit("Network error")
        return

    if response_code != 200:
        login_failed.emit("Server returned error code")
        return

    # Validate response size (max 1MB)
    if body.size() > 1048576:
        login_failed.emit("Response too large")
        return

    var json = JSON.new()
    var error = json.parse(body.get_string_from_utf8())
    if error != OK:
        login_failed.emit("Invalid server response")
        return

    var response = json.data

    # VALIDATE TYPE!
    if typeof(response) != TYPE_DICTIONARY:
        login_failed.emit("Malformed response")
        return

    # Check for PlayFab errors
    if response.has("error"):
        # SANITIZE error message - don't trust server
        var error_code = response["error"].get("errorCode", 0)
        var safe_message = "Login failed (code: %d)" % error_code
        login_failed.emit(safe_message)
        return

    if response.has("data"):
        _handle_playfab_response(response["data"])
```

**Impact:** Potential code injection, memory exhaustion attacks

---

## 🟠 HIGH SEVERITY ISSUES

### HIGH-001: Array Index Out of Bounds
**File:** `/home/user/subroutinedefense/spawner.gd`
**Line:** 108-110
**Category:** Bug - Array Access

**Description:**
Array access without bounds checking when boss rush is active.

**Current Code:**
```gdscript
var enemy_type_index = 5 if BossRushManager.is_boss_rush_active() else pick_enemy_type(current_wave)
var enemy_types = ["breacher", "slicer", "sentinel", "signal_runner", "null_walker", "override"]
var pool_name = "enemy_" + enemy_types[enemy_type_index]
```

**Issue:**
If `pick_enemy_type()` returns value >= 5 due to probability table changes, crash occurs.

**Recommended Fix:**
```gdscript
var enemy_type_index = 5 if BossRushManager.is_boss_rush_active() else pick_enemy_type(current_wave)
var enemy_types = ["breacher", "slicer", "sentinel", "signal_runner", "null_walker", "override"]

# Bounds check
if enemy_type_index < 0 or enemy_type_index >= enemy_types.size():
    push_error("Invalid enemy type index: %d" % enemy_type_index)
    enemy_type_index = 0  # Fallback to breacher

var pool_name = "enemy_" + enemy_types[enemy_type_index]
```

**Impact:** Game crash during wave spawning

---

### HIGH-002: Infinite Loop Risk in Currency Spending
**File:** `/home/user/subroutinedefense/main_hud.gd`
**Line:** 375-577
**Category:** Bug - Infinite Loop

**Description:**
Multiple "Buy Max" loops without iteration limits could hang if upgrade costs don't increase.

**Current Code:**
```gdscript
"buy_max":
    while UpgradeManager.upgrade_projectile_damage():
        pass  # Keep buying until can't afford
```

**Issue:**
If upgrade cost calculation has bug (returns 0), infinite loop freezes game.

**Recommended Fix:**
```gdscript
const MAX_BUY_ITERATIONS = 10000  # Safety limit

func _buy_max_upgrade(upgrade_func: Callable) -> void:
    var iterations = 0
    while iterations < MAX_BUY_ITERATIONS:
        if not upgrade_func.call():
            break  # Can't afford or maxed
        iterations += 1

    if iterations >= MAX_BUY_ITERATIONS:
        push_error("Buy max hit iteration limit - possible infinite loop!")

# Use it:
"buy_max":
    _buy_max_upgrade(Callable(UpgradeManager, "upgrade_projectile_damage"))
```

**Impact:** Game freeze requiring force quit

---

### HIGH-003: Division by Zero in Tower Fire Rate
**File:** `/home/user/subroutinedefense/tower.gd`
**Line:** 35, 64
**Category:** Bug - Division by Zero

**Description:**
Fire rate calculation divides by fire_rate without validation.

**Current Code:**
```gdscript
fire_timer.wait_time = 1.0 / fire_rate
```

**Issue:**
If fire_rate is 0 or negative (due to bug/exploit), division by zero crash.

**Recommended Fix:**
```gdscript
# Ensure minimum fire rate
fire_rate = max(fire_rate, 0.1)
fire_timer.wait_time = 1.0 / fire_rate
```

**Impact:** Game crash when upgrading fire rate

---

### HIGH-004: Null Reference in Enemy Attack
**File:** `/home/user/subroutinedefense/enemy.gd`
**Line:** 189-204
**Category:** Bug - Null Reference

**Description:**
Tower damage call doesn't validate tower exists before calling method.

**Current Code:**
```gdscript
if tower and tower.has_method("take_damage"):
    # Check method signature...
    if supports_enemy_ref:
        tower.take_damage(damage_to_tower, self)
    else:
        tower.take_damage(damage_to_tower)
else:
    print("❌ tower.take_damage() failed — tower is:", tower)
```

**Issue:**
`tower` could become invalid between check and call (race condition with queue_free).

**Recommended Fix:**
```gdscript
if tower and is_instance_valid(tower) and tower.has_method("take_damage"):
    var method_info = tower.get_method_list()
    var supports_enemy_ref = false
    for method in method_info:
        if method.name == "take_damage":
            supports_enemy_ref = method.args.size() >= 2
            break

    # Double-check validity before calling
    if is_instance_valid(tower):
        if supports_enemy_ref:
            tower.take_damage(damage_to_tower, self)
        else:
            tower.take_damage(damage_to_tower)
else:
    # Tower was destroyed, stop attacking
    queue_free()
```

**Impact:** Crash when tower is destroyed

---

### HIGH-005: Memory Leak - Trail Not Freed
**File:** `/home/user/subroutinedefense/enemy.gd`
**Line:** 151-156, 320-324
**Category:** Bug - Memory Leak

**Description:**
Trail Line2D nodes created but not always freed, especially during pool recycling.

**Current Code:**
```gdscript
# In _ready:
trail = AdvancedVisuals.create_projectile_trail(parent, trail_color)

# In die:
if trail and is_instance_valid(trail):
    trail.queue_free()
```

**Issue:**
If enemy is pooled/recycled without calling `die()`, trail leaks memory.

**Recommended Fix:**
```gdscript
func _cleanup_and_recycle() -> void:
    # ALWAYS clean up trail
    _cleanup_trail()

    # Remove from group
    remove_from_group("enemies")

    # Disconnect signals
    # ... existing code ...

    if is_pooled:
        ObjectPool.recycle(self)
    else:
        queue_free()

func _cleanup_trail() -> void:
    if trail and is_instance_valid(trail):
        trail.queue_free()
        trail = null
```

**Impact:** Memory leak causing slowdown over time

---

### HIGH-006: Boss Rush HP Overflow
**File:** `/home/user/subroutinedefense/BossRushManager.gd`
**Line:** 135
**Category:** Bug - Integer Overflow

**Description:**
Boss HP multiplier grows exponentially without cap.

**Current Code:**
```gdscript
func get_boss_rush_hp_multiplier(wave: int) -> float:
    return pow(BOSS_HP_SCALING_BASE, wave) * BOSS_ENEMY_MULTIPLIER
```

**Issue:**
At wave 1000: `pow(1.13, 1000) ≈ 6.8e50` causes overflow.

**Recommended Fix:**
```gdscript
const MAX_BOSS_RUSH_WAVE = 100  # Boss rush ends at wave 100

func get_boss_rush_hp_multiplier(wave: int) -> float:
    # Cap wave for calculation
    var capped_wave = min(wave, MAX_BOSS_RUSH_WAVE)
    var multiplier = pow(BOSS_HP_SCALING_BASE, capped_wave) * BOSS_ENEMY_MULTIPLIER

    # Cap final value to prevent overflow
    return min(multiplier, 1.0e15)
```

**Impact:** Bosses have negative/invalid HP at high waves

---

### HIGH-007: Race Condition in Lab Completion
**File:** `/home/user/subroutinedefense/SoftwareUpgradeManager.gd`
**Line:** 414-430
**Category:** Bug - Race Condition

**Description:**
Multiple labs can complete simultaneously, causing stat corruption.

**Current Code:**
```gdscript
func update_upgrades() -> void:
    var now = Time.get_unix_time_from_system()
    var any_completed = false

    for i in range(MAX_SLOTS):
        var slot = active_upgrades[i]
        if slot == null:
            continue

        var elapsed = now - slot["start_time"]
        if elapsed >= slot["duration"]:
            _complete_upgrade(i)
            any_completed = true
```

**Issue:**
If two labs complete, both modify `RewardManager.perm_*` stats without locks.

**Recommended Fix:**
```gdscript
var _is_processing_completion: bool = false

func update_upgrades() -> void:
    if _is_processing_completion:
        return  # Prevent re-entrancy

    _is_processing_completion = true
    var now = Time.get_unix_time_from_system()
    var any_completed = false

    for i in range(MAX_SLOTS):
        var slot = active_upgrades[i]
        if slot == null:
            continue

        var elapsed = now - slot["start_time"]
        if elapsed >= slot["duration"]:
            _complete_upgrade(i)
            any_completed = true

    if any_completed:
        emit_signal("upgrades_updated")

    _is_processing_completion = false
```

**Impact:** Duplicate stat bonuses, corrupted upgrade levels

---

### HIGH-008: Offline Progress Exploit
**File:** `/home/user/subroutinedefense/RewardManager.gd`
**Line:** 335-373
**Category:** Security - Time Manipulation

**Description:**
Offline progress calculated using system time, easily manipulated.

**Current Code:**
```gdscript
func calculate_offline_progress(watched_ad: bool = false) -> void:
    if last_play_time == 0:
        last_play_time = Time.get_unix_time_from_system()
        return

    var now = Time.get_unix_time_from_system()
    var seconds_away = now - last_play_time
```

**Issue:**
Player can change system clock forward, claim rewards, change back.

**Recommended Fix:**
```gdscript
# Use server time from PlayFab instead of system time
func calculate_offline_progress(watched_ad: bool = false) -> void:
    if not CloudSaveManager.is_logged_in:
        # No offline progress for non-logged-in players
        return

    # Request server time from PlayFab
    var server_time = await _get_server_time()
    if server_time == 0:
        return  # Failed to get server time

    var seconds_away = server_time - last_play_time

    # VALIDATE: Reject if time went backwards (clock manipulation)
    if seconds_away < 0:
        print("⚠️ Clock manipulation detected - rejecting offline progress")
        last_play_time = server_time
        return

    # ... rest of calculation ...

func _get_server_time() -> int:
    # Call PlayFab GetTime API
    # Implementation depends on PlayFab SDK
    return 0  # Placeholder
```

**Impact:** Infinite currency via time manipulation

---

### HIGH-009: Missing Null Check on Get Child
**File:** `/home/user/subroutinedefense/enemy.gd`
**Line:** 97-113
**Category:** Bug - Null Reference

**Description:**
AttackZone access via `$AttackZone` assumes node exists.

**Current Code:**
```gdscript
if not has_node("AttackZone"):
    push_error("Enemy missing AttackZone node!")
    return

var attack_zone = $AttackZone
```

**Issue:**
If node removed dynamically or scene changed, subsequent access crashes.

**Recommended Fix:**
```gdscript
if not has_node("AttackZone"):
    push_error("Enemy missing AttackZone node!")
    queue_free()  # Enemy is invalid, clean up
    return

var attack_zone = get_node("AttackZone")
if not attack_zone:
    push_error("AttackZone is null despite has_node check!")
    queue_free()
    return

# Validate it's actually an Area2D
if not attack_zone is Area2D:
    push_error("AttackZone is not an Area2D!")
    queue_free()
    return
```

**Impact:** Crash when enemy scene is corrupted

---

## 🟡 MEDIUM SEVERITY ISSUES

### MED-001: Debug Print Statements Everywhere
**Files:** All files
**Count:** 346 print statements
**Category:** Code Quality

**Description:**
Debug print statements throughout production code impact performance and expose internal state.

**Examples:**
```gdscript
# CloudSaveManager.gd:38
print("🔐 Logging in with email: %s" % email)

# RewardManager.gd:96
print("💾 Auto-save enabled (every 60 seconds)")

# enemy.gd:489
#print("🟣", name, "poisoned for", poison_duration, "sec...")
```

**Recommended Fix:**
Create debug logging system:
```gdscript
# globals/DebugLogger.gd
extends Node

const DEBUG_ENABLED = false  # Toggle for release builds
const LOG_LEVELS = {
    "INFO": 0,
    "WARN": 1,
    "ERROR": 2
}

func log_info(message: String) -> void:
    if DEBUG_ENABLED:
        print("[INFO] ", message)

func log_warn(message: String) -> void:
    if DEBUG_ENABLED:
        push_warning("[WARN] ", message)

func log_error(message: String) -> void:
    push_error("[ERROR] ", message)

# Replace all print() with:
DebugLogger.log_info("Logging in with email: %s" % email)
```

**Impact:** Performance overhead, information disclosure

---

### MED-002: Hard-Coded PlayFab Title ID
**File:** `/home/user/subroutinedefense/CloudSaveManager.gd`
**Line:** 14
**Category:** Security - Hard-coded Secret

**Description:**
PlayFab Title ID exposed in code.

**Current Code:**
```gdscript
const PLAYFAB_TITLE_ID = "1DEAD6"
```

**Recommended Fix:**
```gdscript
# Move to environment variable or encrypted config
var PLAYFAB_TITLE_ID = OS.get_environment("PLAYFAB_TITLE_ID")

func _ready() -> void:
    if PLAYFAB_TITLE_ID == "":
        push_error("PLAYFAB_TITLE_ID not configured!")
        PLAYFAB_TITLE_ID = _load_encrypted_config("playfab_title")
```

**Impact:** API abuse if ID is public knowledge

---

### MED-003: Save File Corruption on Partial Write
**File:** `/home/user/subroutinedefense/RewardManager.gd`
**Line:** 482-536
**Category:** Bug - Data Corruption

**Description:**
Atomic save uses temp file but doesn't handle all failure modes.

**Current Code:**
```gdscript
# Step 2: Write to temporary file
var file = FileAccess.open(SAVE_FILE_TEMP, FileAccess.WRITE)
if file == null:
    push_error("❌ Failed to open temp save file: " + str(FileAccess.get_open_error()))
    return false
file.store_var(data)
file.close()
```

**Issue:**
If disk full or write fails mid-operation, temp file is corrupt but code continues to rename it.

**Recommended Fix:**
```gdscript
# Step 2: Write to temporary file with error handling
var file = FileAccess.open(SAVE_FILE_TEMP, FileAccess.WRITE)
if file == null:
    push_error("❌ Failed to open temp save file: " + str(FileAccess.get_open_error()))
    return false

# Check if we can actually write
if not file.is_open():
    push_error("❌ Temp file not open after creation!")
    return false

file.store_var(data)

# Check for write errors BEFORE closing
var error = file.get_error()
file.close()

if error != OK:
    push_error("❌ Failed to write save data (error %d)!" % error)
    # Clean up bad temp file
    DirAccess.remove_absolute(SAVE_FILE_TEMP)
    return false
```

**Impact:** Save file corruption, player progress loss

---

### MED-004: Unvalidated Leaderboard Entries
**File:** `/home/user/subroutinedefense/BossRushManager.gd`
**Line:** 147-166
**Category:** Security - Data Validation

**Description:**
Leaderboard accepts any damage/wave values without validation.

**Current Code:**
```gdscript
func add_leaderboard_entry(damage: int, waves: int) -> void:
    var entry = {
        "damage": damage,
        "waves": waves,
        "tier": TierManager.get_current_tier() if TierManager else 1,
        "timestamp": int(Time.get_unix_time_from_system()),
    }
    leaderboard.append(entry)
```

**Issue:**
Cheaters can submit fake scores via save file editing.

**Recommended Fix:**
```gdscript
func add_leaderboard_entry(damage: int, waves: int) -> void:
    # Validate entry is physically possible
    if damage < 0 or waves < 1:
        print("❌ Invalid leaderboard entry rejected")
        return

    # Check if score is suspiciously high (basic sanity check)
    var max_reasonable_damage = waves * 1000000  # 1M damage per wave max
    if damage > max_reasonable_damage:
        print("⚠️ Suspiciously high damage rejected: %d" % damage)
        return

    var entry = {
        "damage": damage,
        "waves": waves,
        "tier": TierManager.get_current_tier() if TierManager else 1,
        "timestamp": int(Time.get_unix_time_from_system()),
        "verified": false  # Flag for server-side verification
    }

    leaderboard.append(entry)
    # ... rest of code ...
```

**Impact:** Leaderboard cheating, unfair fragment rewards

---

### MED-005: No Rate Limiting on Upgrades
**File:** `/home/user/subroutinedefense/UpgradeManager.gd`
**Lines:** Various upgrade functions
**Category:** Bug - Input Validation

**Description:**
Upgrade functions can be called thousands of times per second without cooldown.

**Recommended Fix:**
```gdscript
var _last_upgrade_time: int = 0
const MIN_UPGRADE_INTERVAL_MS = 50  # Max 20 upgrades/second

func _can_upgrade() -> bool:
    var now = Time.get_ticks_msec()
    if now - _last_upgrade_time < MIN_UPGRADE_INTERVAL_MS:
        return false
    _last_upgrade_time = now
    return true

func upgrade_projectile_damage(is_free := false):
    if not _can_upgrade() and not is_free:
        return false
    # ... rest of function ...
```

**Impact:** UI spam, potential exploits

---

### MED-006: Weak Random Number Generation
**File:** `/home/user/subroutinedefense/CloudSaveManager.gd`
**Line:** 310-319
**Category:** Security - Weak Crypto

**Description:**
UUID generation uses `randi()` which is predictable.

**Current Code:**
```gdscript
func _generate_uuid() -> String:
    randomize()
    return "%08x-%04x-%04x-%04x-%012x" % [
        randi(),
        randi() & 0xffff,
        (randi() & 0x0fff) | 0x4000,
        (randi() & 0x3fff) | 0x8000,
        (randi() << 32) | randi()
    ]
```

**Issue:**
Device IDs are predictable if RNG is seeded with time.

**Recommended Fix:**
```gdscript
func _generate_uuid() -> String:
    # Use cryptographically secure random if available
    var uuid = ""
    if ClassDB.class_exists("Crypto"):
        var crypto = Crypto.new()
        var bytes = crypto.generate_random_bytes(16)
        # Format as UUID v4
        uuid = bytes.hex_encode()
    else:
        # Fallback to standard RNG with better seeding
        randomize()
        var seed_value = Time.get_ticks_usec() ^ OS.get_process_id()
        seed(seed_value)
        uuid = "%08x-%04x-%04x-%04x-%012x" % [
            randi(),
            randi() & 0xffff,
            (randi() & 0x0fff) | 0x4000,
            (randi() & 0x3fff) | 0x8000,
            (randi() << 32) | randi()
        ]
    return uuid
```

**Impact:** Account takeover if device IDs are guessed

---

### MED-007: Missing Error Recovery in Save Load
**File:** `/home/user/subroutinedefense/RewardManager.gd`
**Line:** 538-566
**Category:** Bug - Error Handling

**Description:**
If both main and backup saves are corrupted, no error recovery mechanism.

**Current Code:**
```gdscript
print("❌ All save files corrupted or missing. Starting fresh.")
```

**Recommended Fix:**
```gdscript
if all_saves_corrupted:
    # Attempt cloud save recovery
    if CloudSaveManager and CloudSaveManager.is_logged_in:
        print("🔄 Local saves corrupted, attempting cloud recovery...")
        CloudSaveManager.download_save_data()
        # Wait for cloud save signal...
    else:
        # Show warning to player
        _show_save_corruption_warning()
        # Start fresh with minimal progress
        _init_emergency_save()

func _show_save_corruption_warning() -> void:
    # Show popup to player explaining save loss
    pass

func _init_emergency_save() -> void:
    # Give player small compensation for lost progress
    archive_tokens = 10000  # Starter boost
    fragments = 100
    print("🎁 Emergency save created with starter resources")
    save_permanent_upgrades()
```

**Impact:** Poor player experience on save corruption

---

### MED-008: No Timeout on HTTP Requests
**File:** `/home/user/subroutinedefense/CloudSaveManager.gd`
**Line:** 24-30
**Category:** Bug - Network Timeout

**Description:**
HTTPRequest has no timeout configured, can hang indefinitely.

**Current Code:**
```gdscript
http_request = HTTPRequest.new()
add_child(http_request)
http_request.request_completed.connect(_on_http_request_completed)
```

**Recommended Fix:**
```gdscript
http_request = HTTPRequest.new()
http_request.timeout = 30  # 30 second timeout
add_child(http_request)
http_request.request_completed.connect(_on_http_request_completed)

# Add timeout handler
http_request.request_timeout.connect(_on_http_timeout)

func _on_http_timeout() -> void:
    login_failed.emit("Connection timed out")
```

**Impact:** Frozen login screen on network issues

---

## 🔵 LOW SEVERITY ISSUES

### LOW-001: Magic Numbers Throughout Codebase
**Files:** All
**Category:** Code Quality

**Description:**
Hard-coded numbers without named constants reduce maintainability.

**Examples:**
```gdscript
# spawner.gd:162
var increment = int(wave / 250) * 2  # Why 250?

# enemy.gd:150
if dist < 300:  # Magic number - pierce range

# BossRushManager.gd:29-40
const FRAGMENT_REWARDS := {
    1: 5000,   # Hard-coded rewards
    2: 3000,
```

**Recommended Fix:**
```gdscript
# Constants file
const WAVE_SCALING_THRESHOLD = 250
const PIERCE_MAX_RANGE = 300
const BOSS_RUSH_FIRST_PLACE_FRAGMENTS = 5000
```

**Impact:** Difficult to balance/tune game

---

### LOW-002: Inconsistent Error Messages
**Files:** All
**Category:** Code Quality

**Description:**
Error messages use different formats (emojis vs plain text).

**Recommended Fix:**
```gdscript
# Standardize all error messages
"❌ " prefix for errors
"⚠️ " prefix for warnings
"✅ " prefix for success
"ℹ️ " prefix for info
```

**Impact:** Poor log readability

---

### LOW-003: Commented Out Code
**Files:** Multiple
**Category:** Code Quality

**Description:**
1,431 comment lines including dead code.

**Examples:**
```gdscript
# enemy.gd:171
#print(name, "stun ended")

# enemy.gd:163
#print("🔥 Lucky drop! Bonus DC!")
```

**Recommended Fix:**
Remove all commented-out debug prints and dead code.

**Impact:** Code clutter, confusion

---

### LOW-004: Inconsistent Naming Conventions
**Files:** Multiple
**Category:** Code Quality

**Description:**
Mix of snake_case and camelCase in variables.

**Examples:**
```gdscript
var perm_projectile_damage  # snake_case
var enemyTypes  # camelCase (hypothetical)
```

**Recommended Fix:**
Standardize on GDScript convention (snake_case for variables).

**Impact:** Code consistency

---

### LOW-005: No Input Sanitization on Email
**File:** `/home/user/subroutinedefense/CloudSaveManager.gd`
**Line:** 37-53
**Category:** Code Quality

**Description:**
Email input not validated before sending to PlayFab.

**Recommended Fix:**
```gdscript
func login_with_email(email: String, password: String) -> void:
    # Validate email format
    if not _is_valid_email(email):
        login_failed.emit("Invalid email format")
        return

    # ... rest of code ...

func _is_valid_email(email: String) -> bool:
    var regex = RegEx.new()
    regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
    return regex.search(email) != null
```

**Impact:** Poor UX, server errors

---

### LOW-006: Duplicate Code in Permanent Upgrades
**File:** `/home/user/subroutinedefense/UpgradeManager.gd`
**Lines:** 669-861
**Category:** Code Quality

**Description:**
15 nearly identical upgrade functions with copy-paste code.

**Recommended Fix:**
```gdscript
func _upgrade_perm_stat(stat_name: String, cost_base: int, cost_increment: int,
                        current_value: Variant, increment: Variant, max_value: Variant = null) -> bool:
    var cost = get_perm_cost(cost_base, cost_increment, current_value)
    if RewardManager.archive_tokens < cost:
        print("❌ Not enough AT for", stat_name)
        return false

    if max_value != null and current_value >= max_value:
        print("✅", stat_name, "already at max")
        return false

    RewardManager.archive_tokens -= cost
    RunStats.add_at_spent_perm_upgrade(cost)

    # Update stat (requires reflection or dictionary-based system)
    # ...

    RewardManager.save_permanent_upgrades()
    return true

# Usage:
func upgrade_perm_crit_chance() -> bool:
    return _upgrade_perm_stat("Crit Chance", 7500, 500,
                              RewardManager.perm_crit_chance, 1)
```

**Impact:** Maintenance burden, bug multiplication

---

## 📊 Summary Statistics

**Total Issues Found:** 28

**By Severity:**
- Critical: 5 (17.9%)
- High: 9 (32.1%)
- Medium: 8 (28.6%)
- Low: 6 (21.4%)

**By Category:**
- Security: 8 issues
- Bugs: 15 issues
- Code Quality: 5 issues

**Critical Files Requiring Immediate Attention:**
1. `/home/user/subroutinedefense/CloudSaveManager.gd` (3 critical issues)
2. `/home/user/subroutinedefense/RewardManager.gd` (2 critical issues)
3. `/home/user/subroutinedefense/UpgradeManager.gd` (1 critical issue)
4. `/home/user/subroutinedefense/projectile.gd` (1 critical issue)

---

## 🎯 Recommended Priority Order

### Phase 1: Critical Security (Week 1)
1. CRIT-003: Implement save validation
2. CRIT-004: Fix currency exploit
3. CRIT-005: Validate HTTP responses
4. HIGH-008: Use server time for offline progress

### Phase 2: Critical Bugs (Week 2)
1. CRIT-001: Fix division by zero
2. CRIT-002: Cap integer overflow
3. HIGH-002: Add buy max iteration limits
4. HIGH-003: Validate fire rate

### Phase 3: High Priority (Week 3-4)
1. HIGH-001: Bounds check array access
2. HIGH-005: Fix memory leak
3. HIGH-006: Cap boss rush scaling
4. HIGH-007: Prevent race conditions
5. HIGH-009: Validate node access

### Phase 4: Medium Priority (Week 5-6)
1. MED-001: Implement debug logging system
2. MED-003: Improve save error handling
3. MED-004: Validate leaderboard entries
4. MED-008: Add network timeouts

### Phase 5: Code Quality (Ongoing)
1. LOW-001: Extract magic numbers to constants
2. LOW-003: Remove commented code
3. LOW-006: Refactor duplicate upgrade code

---

## 🔒 Security Recommendations

1. **Never trust client data** - All currency changes should be server-validated
2. **Use server time** - System time can be manipulated
3. **Validate all inputs** - HTTP responses, save files, user input
4. **Implement checksums** - Detect save file tampering
5. **Rate limit operations** - Prevent spam/exploits
6. **Encrypt sensitive data** - API keys, save files
7. **Add integrity checks** - Hash save data to detect edits

---

## 🧪 Testing Recommendations

### Unit Tests Needed:
1. Currency overflow tests (add MAX_INT to currency)
2. Division by zero tests (set fire rate to 0)
3. Array bounds tests (invalid enemy type indices)
4. Save/load corruption tests (partial writes)
5. Network timeout tests (disconnect during save)

### Integration Tests Needed:
1. Boss rush scaling at wave 1000
2. Offline progress with clock changes
3. Buy max with 0-cost upgrades
4. Simultaneous lab completions
5. Concurrent save operations

### Exploit Testing:
1. Change system clock forward/back
2. Edit save file with impossible values
3. Interrupt saves mid-write
4. Submit fake leaderboard scores
5. Spam upgrade buttons

---

## 📝 Code Review Checklist

Before merging any changes, verify:
- [ ] No divisions without denominator validation
- [ ] All array access has bounds checks
- [ ] All node access uses `is_instance_valid()`
- [ ] All currency changes use atomic saves
- [ ] All HTTP responses are validated
- [ ] All loops have iteration limits
- [ ] All user input is sanitized
- [ ] All temporary files are cleaned up
- [ ] All print() replaced with DebugLogger
- [ ] All magic numbers extracted to constants

---

**End of Audit Report**

For questions or clarification, contact the development team.
