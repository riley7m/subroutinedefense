extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var permanent_upgrades_button = $VBoxContainer/PermanentUpgradesButton

var login_ui: Control = null

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	permanent_upgrades_button.pressed.connect(_on_permanent_upgrades_button_pressed)

	# Disable non-functional buttons (not yet implemented)
	settings_button.disabled = true
	settings_button.tooltip_text = "Coming Soon!"
	permanent_upgrades_button.disabled = true
	permanent_upgrades_button.tooltip_text = "Coming Soon!"

	# Show login UI if not logged in
	if CloudSaveManager and not CloudSaveManager.is_logged_in:
		_show_login_screen()

func _show_login_screen():
	login_ui = preload("res://login_ui.gd").new()
	add_child(login_ui)
	login_ui.show_login()
	login_ui.login_completed.connect(_on_login_completed)

func _on_login_completed():
	print("✅ Player logged in successfully")
	# Login UI auto-hides, player can now start game

func _on_start_button_pressed():
	# Change to your main gameplay scene
	print("test")
	get_tree().change_scene_to_file("res://main_hud.tscn")  # Adjust path as needed

func _on_settings_button_pressed() -> void:
		# Change to settings scene (implement this scene later)
	# get_tree().change_scene_to_file("res://SettingsScreen.tscn")  # Placeholder
	print("test")

func _on_permanent_upgrades_button_pressed() -> void:
		print("test")
