extends Control

# Settings UI
# Allows players to configure game settings

# UI Nodes
var panel: Panel
var title_label: Label
var scroll_container: ScrollContainer
var settings_list: VBoxContainer
var close_button: Button

# Settings values (cached from game settings)
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var particles_enabled: bool = true
var screen_effects_enabled: bool = true

func _ready() -> void:
	_load_settings()
	_create_ui()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Main panel (fits 390px mobile screen)
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 780)
	panel.position = Vector2(15, 50)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "⚙️ SETTINGS"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Scroll area for settings
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(20, 60)
	scroll_container.custom_minimum_size = Vector2(320, 655)
	panel.add_child(scroll_container)

	settings_list = VBoxContainer.new()
	settings_list.custom_minimum_size = Vector2(300, 0)
	scroll_container.add_child(settings_list)

	# Build settings sections
	_create_audio_section()
	_create_graphics_section()
	_create_account_section()
	_create_game_section()

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 725)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _create_audio_section() -> void:
	_create_section_header("🔊 AUDIO")

	# Master Volume
	_create_slider_setting(
		"Master Volume",
		master_volume,
		func(value):
			master_volume = value
			_apply_master_volume(value)
	)

	# Music Volume
	_create_slider_setting(
		"Music Volume",
		music_volume,
		func(value):
			music_volume = value
			_apply_music_volume(value)
	)

	# SFX Volume
	_create_slider_setting(
		"SFX Volume",
		sfx_volume,
		func(value):
			sfx_volume = value
			_apply_sfx_volume(value)
	)

	_create_spacer(20)

func _create_graphics_section() -> void:
	_create_section_header("🎨 GRAPHICS")

	# Particle Effects
	_create_toggle_setting(
		"Particle Effects",
		particles_enabled,
		func(enabled):
			particles_enabled = enabled
			_apply_particles(enabled)
	)

	# Screen Effects
	_create_toggle_setting(
		"Screen Effects",
		screen_effects_enabled,
		func(enabled):
			screen_effects_enabled = enabled
			_apply_screen_effects(enabled)
	)

	_create_spacer(20)

func _create_account_section() -> void:
	_create_section_header("👤 ACCOUNT")

	# Login/Logout button
	var login_container = HBoxContainer.new()
	login_container.custom_minimum_size = Vector2(300, 40)
	settings_list.add_child(login_container)

	var login_label = Label.new()
	if CloudSaveManager and CloudSaveManager.is_logged_in:
		login_label.text = "Status: Logged In"
		login_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		login_label.text = "Status: Not Logged In"
		login_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	login_label.add_theme_font_size_override("font_size", 14)
	login_label.custom_minimum_size = Vector2(180, 40)
	login_container.add_child(login_label)

	var login_button = Button.new()
	if CloudSaveManager and CloudSaveManager.is_logged_in:
		login_button.text = "Logout"
		login_button.pressed.connect(_on_logout_pressed)
	else:
		login_button.text = "Login"
		login_button.pressed.connect(_on_login_pressed)
	login_button.custom_minimum_size = Vector2(100, 35)
	login_container.add_child(login_button)

	# Cloud Save Status
	if CloudSaveManager and CloudSaveManager.is_logged_in:
		var cloud_label = Label.new()
		cloud_label.text = "Cloud Save: Enabled"
		cloud_label.add_theme_font_size_override("font_size", 12)
		cloud_label.modulate = Color(0.8, 0.8, 0.8)
		settings_list.add_child(cloud_label)

	_create_spacer(20)

func _create_game_section() -> void:
	_create_section_header("🎮 GAME")

	# Version info
	var version_label = Label.new()
	version_label.text = "Version: 0.9.0 (Pre-Launch)"
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.modulate = Color(0.7, 0.7, 0.7)
	settings_list.add_child(version_label)

	_create_spacer(10)

	# Reset Progress button (dangerous)
	var reset_button = Button.new()
	reset_button.text = "⚠️ Reset All Progress"
	reset_button.custom_minimum_size = Vector2(280, 40)
	reset_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	reset_button.pressed.connect(_on_reset_progress_pressed)
	settings_list.add_child(reset_button)

	_create_spacer(10)

	# Privacy Policy / EULA links
	var privacy_button = Button.new()
	privacy_button.text = "Privacy Policy"
	privacy_button.custom_minimum_size = Vector2(280, 35)
	privacy_button.pressed.connect(_on_privacy_policy_pressed)
	settings_list.add_child(privacy_button)

	var eula_button = Button.new()
	eula_button.text = "Terms of Service"
	eula_button.custom_minimum_size = Vector2(280, 35)
	eula_button.pressed.connect(_on_eula_pressed)
	settings_list.add_child(eula_button)

	_create_spacer(10)

	# Credits
	var credits_button = Button.new()
	credits_button.text = "Credits"
	credits_button.custom_minimum_size = Vector2(280, 35)
	credits_button.pressed.connect(_on_credits_pressed)
	settings_list.add_child(credits_button)

func _create_section_header(text: String) -> void:
	var header = Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	header.custom_minimum_size = Vector2(300, 30)
	settings_list.add_child(header)

func _create_slider_setting(label_text: String, initial_value: float, on_change: Callable) -> void:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(300, 60)
	settings_list.add_child(container)

	# Label with value
	var label = Label.new()
	label.text = "%s: %d%%" % [label_text, int(initial_value * 100)]
	label.add_theme_font_size_override("font_size", 14)
	container.add_child(label)

	# Slider
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.1
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(280, 30)
	slider.value_changed.connect(func(value):
		label.text = "%s: %d%%" % [label_text, int(value * 100)]
		on_change.call(value)
		_save_settings()
	)
	container.add_child(slider)

func _create_toggle_setting(label_text: String, initial_value: bool, on_change: Callable) -> void:
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(300, 40)
	settings_list.add_child(container)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(200, 40)
	container.add_child(label)

	var toggle = CheckButton.new()
	toggle.button_pressed = initial_value
	toggle.custom_minimum_size = Vector2(80, 40)
	toggle.toggled.connect(func(enabled):
		on_change.call(enabled)
		_save_settings()
	)
	container.add_child(toggle)

func _create_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	settings_list.add_child(spacer)

# === SETTING APPLICATIONS ===

func _apply_master_volume(volume: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

func _apply_music_volume(volume: float) -> void:
	# TODO: Set music bus volume when audio buses are configured
	print("🎵 Music volume: %d%%" % int(volume * 100))

func _apply_sfx_volume(volume: float) -> void:
	# TODO: Set SFX bus volume when audio buses are configured
	print("🔊 SFX volume: %d%%" % int(volume * 100))

func _apply_particles(enabled: bool) -> void:
	if ParticleEffects:
		ParticleEffects.enabled = enabled
		print("✨ Particles: %s" % ("ON" if enabled else "OFF"))

func _apply_screen_effects(enabled: bool) -> void:
	if ScreenEffects:
		ScreenEffects.enabled = enabled
		print("🎆 Screen effects: %s" % ("ON" if enabled else "OFF"))

# === BUTTON HANDLERS ===

func _on_login_pressed() -> void:
	print("👤 Login requested")
	# TODO: Show login UI
	if CloudSaveManager:
		CloudSaveManager.show_login()

func _on_logout_pressed() -> void:
	print("👤 Logout requested")
	if CloudSaveManager:
		CloudSaveManager.logout()
		queue_free()  # Close settings to refresh

func _on_reset_progress_pressed() -> void:
	# Show confirmation dialog
	_show_reset_confirmation()

func _on_privacy_policy_pressed() -> void:
	print("📄 Opening privacy policy...")
	OS.shell_open("https://example.com/privacy")  # TODO: Replace with actual URL

func _on_eula_pressed() -> void:
	print("📄 Opening terms of service...")
	OS.shell_open("https://example.com/terms")  # TODO: Replace with actual URL

func _on_credits_pressed() -> void:
	_show_credits()

func _show_reset_confirmation() -> void:
	# Create confirmation popup
	var confirm_panel = Panel.new()
	confirm_panel.position = Vector2(50, 300)
	confirm_panel.custom_minimum_size = Vector2(280, 180)
	add_child(confirm_panel)

	var warning_label = Label.new()
	warning_label.text = "⚠️ RESET PROGRESS ⚠️"
	warning_label.position = Vector2(20, 15)
	warning_label.add_theme_font_size_override("font_size", 18)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.custom_minimum_size = Vector2(240, 30)
	confirm_panel.add_child(warning_label)

	var warning_text = Label.new()
	warning_text.text = "This will delete ALL progress:\n• All currencies\n• All upgrades\n• All achievements\n\nAre you sure?"
	warning_text.position = Vector2(20, 50)
	warning_text.add_theme_font_size_override("font_size", 12)
	warning_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_text.custom_minimum_size = Vector2(240, 80)
	confirm_panel.add_child(warning_text)

	var button_row = HBoxContainer.new()
	button_row.position = Vector2(30, 135)
	confirm_panel.add_child(button_row)

	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(100, 35)
	cancel_button.pressed.connect(func(): confirm_panel.queue_free())
	button_row.add_child(cancel_button)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	button_row.add_child(spacer)

	var confirm_button = Button.new()
	confirm_button.text = "RESET"
	confirm_button.custom_minimum_size = Vector2(100, 35)
	confirm_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	confirm_button.pressed.connect(func():
		_reset_all_progress()
		confirm_panel.queue_free()
	)
	button_row.add_child(confirm_button)

func _show_credits() -> void:
	# Create credits popup
	var credits_panel = Panel.new()
	credits_panel.position = Vector2(50, 200)
	credits_panel.custom_minimum_size = Vector2(280, 400)
	add_child(credits_panel)

	var title = Label.new()
	title.text = "CREDITS"
	title.position = Vector2(20, 15)
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(240, 30)
	credits_panel.add_child(title)

	var credits_text = Label.new()
	credits_text.text = "SUBROUTINE DEFENSE\n\nDeveloped by:\nYour Studio Name\n\nBuilt with:\nGodot Engine 4.4\n\nSpecial Thanks:\nClaude AI - Development Assistant\n\n© 2025 All Rights Reserved"
	credits_text.position = Vector2(20, 50)
	credits_text.add_theme_font_size_override("font_size", 14)
	credits_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_text.custom_minimum_size = Vector2(240, 300)
	credits_panel.add_child(credits_text)

	var close_credits_button = Button.new()
	close_credits_button.text = "Close"
	close_credits_button.position = Vector2(85, 355)
	close_credits_button.custom_minimum_size = Vector2(110, 35)
	close_credits_button.pressed.connect(func(): credits_panel.queue_free())
	credits_panel.add_child(close_credits_button)

func _reset_all_progress() -> void:
	print("🔄 Resetting all progress...")

	# Delete all save files
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("perm_upgrades.save")
		dir.remove("perm_upgrades.save.backup")
		dir.remove("perm_upgrades.save.tmp")
		dir.remove("data_disks.save")
		dir.remove("daily_rewards.save")

	# Reload scene to reset game
	get_tree().reload_current_scene()

# === PERSISTENCE ===

func _save_settings() -> void:
	var settings_data = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"particles_enabled": particles_enabled,
		"screen_effects_enabled": screen_effects_enabled,
	}

	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	if file:
		file.store_var(settings_data)
		file.close()

func _load_settings() -> void:
	if not FileAccess.file_exists("user://settings.save"):
		return

	var file = FileAccess.open("user://settings.save", FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()

		if typeof(data) == TYPE_DICTIONARY:
			master_volume = data.get("master_volume", 1.0)
			music_volume = data.get("music_volume", 0.7)
			sfx_volume = data.get("sfx_volume", 1.0)
			particles_enabled = data.get("particles_enabled", true)
			screen_effects_enabled = data.get("screen_effects_enabled", true)

			# Apply loaded settings
			_apply_master_volume(master_volume)
			_apply_music_volume(music_volume)
			_apply_sfx_volume(sfx_volume)
			_apply_particles(particles_enabled)
			_apply_screen_effects(screen_effects_enabled)

func _on_close_pressed() -> void:
	queue_free()
