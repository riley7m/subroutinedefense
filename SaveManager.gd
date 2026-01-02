extends Node

# SaveManager - Unified Save/Load System
# Consolidates atomic save logic from RewardManager, SoftwareUpgradeManager, and BossRushManager
# Reduces ~413 lines of duplicate code to ~150 lines

## ATOMIC SAVE PATTERN
## Uses temporary file + verification + atomic rename to prevent corruption
## Pattern: backup → write temp → verify temp → atomic rename

func atomic_save(save_path: String, data: Dictionary) -> bool:
	"""
	Atomic save with backup and verification.
	Prevents save corruption by using temp file and atomic rename.

	Returns true if save succeeded, false otherwise.
	"""
	var temp_path = save_path + ".tmp"
	var backup_path = save_path + ".backup"

	# Step 1: Backup existing save file
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open("user://")
		if dir:
			if FileAccess.file_exists(backup_path):
				dir.remove(backup_path)
			var copy_err = dir.copy(save_path, backup_path)
			if copy_err != OK:
				push_warning("⚠️ Failed to create backup (error %d), continuing anyway..." % copy_err)

	# Step 2: Write to temporary file
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("❌ Failed to open temp save file: " + str(FileAccess.get_open_error()))
		return false
	file.store_var(data)
	file.close()

	# Step 3: Verify temporary file
	file = FileAccess.open(temp_path, FileAccess.READ)
	if file == null:
		push_error("❌ Failed to verify temp save file!")
		return false
	var verification = file.get_var()
	file.close()

	if typeof(verification) != TYPE_DICTIONARY:
		push_error("❌ Save verification failed: Invalid data type!")
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(temp_path)
		return false

	# Step 4: Atomic rename (replace old save with new)
	var dir = DirAccess.open("user://")
	if not dir:
		push_error("❌ Failed to access save directory!")
		return false

	if FileAccess.file_exists(save_path):
		dir.remove(save_path)

	var rename_err = dir.rename(temp_path, save_path)
	if rename_err != OK:
		push_error("❌ Failed to finalize save file (error %d)!" % rename_err)
		return false

	return true

func atomic_load(save_path: String) -> Dictionary:
	"""
	Atomic load with backup fallback.
	Tries main save first, then backup if corrupted.

	Returns loaded data dictionary, or empty dict if all saves failed.
	"""
	var backup_path = save_path + ".backup"
	var files_to_try = [save_path, backup_path]

	for file_path in files_to_try:
		if not FileAccess.file_exists(file_path):
			continue

		var file = FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			push_error("Failed to open %s for reading: %s" % [file_path, str(FileAccess.get_open_error())])
			continue

		var data = file.get_var()
		file.close()

		# Validate data is a dictionary
		if typeof(data) != TYPE_DICTIONARY:
			push_error("Save file %s corrupted: Invalid data type" % file_path)
			continue

		# Successfully loaded save
		if file_path == backup_path:
			push_warning("⚠️ Main save corrupted, loaded from backup!")

		return data

	# All saves failed
	return {}

## SIMPLE SAVE PATTERN
## Direct write without atomic guarantees
## Use for non-critical data (leaderboards, settings, etc.)

func simple_save(save_path: String, data: Dictionary) -> bool:
	"""
	Simple save without atomic guarantees.
	Use for non-critical data.

	Returns true if save succeeded, false otherwise.
	"""
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("❌ Failed to open save file: " + str(FileAccess.get_open_error()))
		return false

	file.store_var(data)
	file.close()
	return true

func simple_load(save_path: String) -> Dictionary:
	"""
	Simple load without backup fallback.
	Use for non-critical data.

	Returns loaded data dictionary, or empty dict if load failed.
	"""
	if not FileAccess.file_exists(save_path):
		return {}

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("❌ Failed to open save file: " + str(FileAccess.get_open_error()))
		return {}

	var data = file.get_var()
	file.close()

	# Validate data is a dictionary
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file %s corrupted: Invalid data type" % save_path)
		return {}

	return data

## UTILITY FUNCTIONS

func file_exists(save_path: String) -> bool:
	"""Check if a save file exists"""
	return FileAccess.file_exists(save_path)

func delete_save(save_path: String) -> bool:
	"""Delete a save file and its backups"""
	var dir = DirAccess.open("user://")
	if not dir:
		return false

	var deleted = false
	if FileAccess.file_exists(save_path):
		dir.remove(save_path)
		deleted = true

	var backup_path = save_path + ".backup"
	if FileAccess.file_exists(backup_path):
		dir.remove(backup_path)
		deleted = true

	var temp_path = save_path + ".tmp"
	if FileAccess.file_exists(temp_path):
		dir.remove(temp_path)
		deleted = true

	return deleted
