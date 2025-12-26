# login_ui.gd
# Account login/register screen for cloud save binding

extends CanvasLayer

# UI Nodes
var panel: Panel
var title_label: Label
var mode_toggle_button: Button

# Login fields
var login_email_input: LineEdit
var login_password_input: LineEdit
var login_button: Button
var guest_button: Button

# Register fields
var register_container: VBoxContainer
var register_email_input: LineEdit
var register_password_input: LineEdit
var register_username_input: LineEdit
var register_button: Button

# Status
var status_label: Label
var close_button: Button

# State
var is_register_mode: bool = false

signal login_completed()

func _ready() -> void:
	_create_ui()

	# Connect CloudSaveManager signals
	if CloudSaveManager:
		CloudSaveManager.login_succeeded.connect(_on_login_succeeded)
		CloudSaveManager.login_failed.connect(_on_login_failed)

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

	# Hide initially
	visible = false

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 500)
	panel.position = Vector2(20, 150)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🔐 Account Login"
	title_label.position = Vector2(20, 20)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(310, 35)
	panel.add_child(title_label)

	# Mode toggle button (Login <-> Register)
	mode_toggle_button = Button.new()
	mode_toggle_button.text = "Need an account? Register"
	mode_toggle_button.position = Vector2(20, 60)
	mode_toggle_button.custom_minimum_size = Vector2(310, 30)
	mode_toggle_button.pressed.connect(_on_mode_toggle_pressed)
	panel.add_child(mode_toggle_button)

	# === LOGIN SECTION ===
	var login_y = 100

	# Email input
	login_email_input = LineEdit.new()
	login_email_input.placeholder_text = "Email"
	login_email_input.position = Vector2(20, login_y)
	login_email_input.custom_minimum_size = Vector2(310, 40)
	panel.add_child(login_email_input)

	# Password input
	login_password_input = LineEdit.new()
	login_password_input.placeholder_text = "Password"
	login_password_input.secret = true
	login_password_input.position = Vector2(20, login_y + 50)
	login_password_input.custom_minimum_size = Vector2(310, 40)
	panel.add_child(login_password_input)

	# Login button
	login_button = Button.new()
	login_button.text = "Login"
	login_button.position = Vector2(20, login_y + 100)
	login_button.custom_minimum_size = Vector2(150, 45)
	login_button.pressed.connect(_on_login_pressed)
	panel.add_child(login_button)

	# Guest button
	guest_button = Button.new()
	guest_button.text = "Play as Guest"
	guest_button.position = Vector2(180, login_y + 100)
	guest_button.custom_minimum_size = Vector2(150, 45)
	guest_button.pressed.connect(_on_guest_pressed)
	panel.add_child(guest_button)

	# === REGISTER SECTION (hidden by default) ===
	register_container = VBoxContainer.new()
	register_container.position = Vector2(20, 100)
	register_container.custom_minimum_size = Vector2(310, 250)
	register_container.visible = false
	panel.add_child(register_container)

	# Username input
	register_username_input = LineEdit.new()
	register_username_input.placeholder_text = "Username"
	register_username_input.custom_minimum_size = Vector2(310, 40)
	register_container.add_child(register_username_input)

	# Email input
	register_email_input = LineEdit.new()
	register_email_input.placeholder_text = "Email"
	register_email_input.custom_minimum_size = Vector2(310, 40)
	register_container.add_child(register_email_input)

	# Password input
	register_password_input = LineEdit.new()
	register_password_input.placeholder_text = "Password (min 6 characters)"
	register_password_input.secret = true
	register_password_input.custom_minimum_size = Vector2(310, 40)
	register_container.add_child(register_password_input)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	register_container.add_child(spacer)

	# Register button
	register_button = Button.new()
	register_button.text = "Create Account"
	register_button.custom_minimum_size = Vector2(310, 45)
	register_button.pressed.connect(_on_register_pressed)
	register_container.add_child(register_button)

	# === STATUS LABEL ===
	status_label = Label.new()
	status_label.text = ""
	status_label.position = Vector2(20, 360)
	status_label.custom_minimum_size = Vector2(310, 60)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(status_label)

	# === CLOSE BUTTON ===
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 435)
	close_button.custom_minimum_size = Vector2(100, 40)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _on_mode_toggle_pressed() -> void:
	is_register_mode = !is_register_mode

	if is_register_mode:
		title_label.text = "📝 Create Account"
		mode_toggle_button.text = "Have an account? Login"
		login_email_input.visible = false
		login_password_input.visible = false
		login_button.visible = false
		guest_button.visible = false
		register_container.visible = true
	else:
		title_label.text = "🔐 Account Login"
		mode_toggle_button.text = "Need an account? Register"
		login_email_input.visible = true
		login_password_input.visible = true
		login_button.visible = true
		guest_button.visible = true
		register_container.visible = false

	status_label.text = ""

func _on_login_pressed() -> void:
	var email = login_email_input.text.strip_edges()
	var password = login_password_input.text

	if email == "" or password == "":
		_show_status("Please enter email and password", true)
		return

	_show_status("Logging in...", false)
	CloudSaveManager.login_with_email(email, password)

func _on_register_pressed() -> void:
	var username = register_username_input.text.strip_edges()
	var email = register_email_input.text.strip_edges()
	var password = register_password_input.text

	if username == "" or email == "" or password == "":
		_show_status("Please fill in all fields", true)
		return

	if password.length() < 6:
		_show_status("Password must be at least 6 characters", true)
		return

	_show_status("Creating account...", false)
	CloudSaveManager.register_with_email(email, password, username)

func _on_guest_pressed() -> void:
	_show_status("Logging in as guest...", false)
	CloudSaveManager.login_as_guest()

func _on_login_succeeded(player_id: String) -> void:
	_show_status("✅ Login successful!", false)
	await get_tree().create_timer(1.0).timeout
	visible = false
	login_completed.emit()

func _on_login_failed(error: String) -> void:
	_show_status("❌ Login failed: %s" % error, true)

func _show_status(message: String, is_error: bool) -> void:
	status_label.text = message
	if is_error:
		status_label.modulate = Color(1.0, 0.3, 0.3)  # Red
	else:
		status_label.modulate = Color(1.0, 1.0, 1.0)  # White

func _on_close_pressed() -> void:
	# If not logged in, force guest login
	if not CloudSaveManager.is_logged_in:
		_on_guest_pressed()
	else:
		visible = false

func show_login() -> void:
	visible = true
	is_register_mode = false
	_on_mode_toggle_pressed()  # Reset to login mode
	_on_mode_toggle_pressed()  # Toggle back
	status_label.text = ""
