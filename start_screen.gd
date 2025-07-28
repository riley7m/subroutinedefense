extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var permanent_upgrades_button = $VBoxContainer/PermanentUpgradesButton

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	permanent_upgrades_button.pressed.connect(_on_permanent_upgrades_button_pressed)

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
