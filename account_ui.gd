extends Control

# Account/Login UI
# Handles guest login, email registration, and account binding

# UI Nodes
var panel: Panel
var title_label: Label
var status_label: Label
var content_container: VBoxContainer
var close_button: Button

# Current view state
var current_view: String = "main"  # "main", "login", "register", "bind"

signal account_updated()

func _ready() -> void:
	_create_ui()
	_show_main_view()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

	# Connect to CloudSaveManager signals
	if CloudSaveManager:
		CloudSaveManager.login_succeeded.connect(_on_login_succeeded)
		CloudSaveManager.login_failed.connect(_on_login_failed)
		CloudSaveManager.account_created.connect(_on_account_created)

func _create_ui() -> void:
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 600)
	panel.position = Vector2(15, 120)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "👤 ACCOUNT"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(320, 30)
	panel.add_child(title_label)

	# Status label
	status_label = Label.new()
	status_label.text = ""
	status_label.position = Vector2(20, 50)
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(320, 25)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	panel.add_child(status_label)

	# Content container (dynamically filled based on view)
	content_container = VBoxContainer.new()
	content_container.position = Vector2(30, 85)
	content_container.custom_minimum_size = Vector2(300, 450)
	panel.add_child(content_container)

	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(125, 545)
	close_button.custom_minimum_size = Vector2(110, 35)
	close_button.pressed.connect(_on_close_pressed)
	panel.add_child(close_button)

func _clear_content() -> void:
	for child in content_container.get_children():
		child.queue_free()

func _show_main_view() -> void:
	current_view = "main"
	_clear_content()

	if CloudSaveManager and CloudSaveManager.is_logged_in:
		_show_logged_in_view()
	else:
		_show_logged_out_view()

func _show_logged_out_view() -> void:
	status_label.text = "Not logged in - Playing as Guest"

	# Info text
	var info = Label.new()
	info.text = "Create an account to save your progress\nacross devices and prevent data loss."
	info.add_theme_font_size_override("font_size", 14)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size = Vector2(300, 60)
	content_container.add_child(info)

	_add_spacer(20)

	# Guest Login button
	var guest_button = Button.new()
	guest_button.text = "Continue as Guest"
	guest_button.custom_minimum_size = Vector2(280, 50)
	guest_button.add_theme_font_size_override("font_size", 16)
	guest_button.pressed.connect(_on_guest_login_pressed)
	content_container.add_child(guest_button)

	_add_spacer(10)

	# Email Login button
	var login_button = Button.new()
	login_button.text = "Login with Email"
	login_button.custom_minimum_size = Vector2(280, 50)
	login_button.pressed.connect(func(): _show_login_view())
	content_container.add_child(login_button)

	_add_spacer(10)

	# Register button
	var register_button = Button.new()
	register_button.text = "Create Account"
	register_button.custom_minimum_size = Vector2(280, 50)
	register_button.pressed.connect(func(): _show_register_view())
	content_container.add_child(register_button)

func _show_logged_in_view() -> void:
	var player_info = CloudSaveManager.get_player_info()

	if player_info["is_guest"]:
		status_label.text = "Logged in as Guest"
	else:
		status_label.text = "Account Linked"

	# Player ID display
	var id_container = HBoxContainer.new()
	id_container.custom_minimum_size = Vector2(300, 40)
	content_container.add_child(id_container)

	var id_label = Label.new()
	id_label.text = "Player ID:"
	id_label.add_theme_font_size_override("font_size", 14)
	id_label.custom_minimum_size = Vector2(100, 40)
	id_container.add_child(id_label)

	var id_value = Label.new()
	var player_id = player_info["player_id"]
	if player_id.length() > 16:
		player_id = player_id.substr(0, 16) + "..."
	id_value.text = player_id
	id_value.add_theme_font_size_override("font_size", 13)
	id_value.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	id_value.custom_minimum_size = Vector2(180, 40)
	id_container.add_child(id_value)

	_add_spacer(20)

	# Cloud save status
	var cloud_label = Label.new()
	cloud_label.text = "☁️ Cloud Save: Active"
	cloud_label.add_theme_font_size_override("font_size", 14)
	cloud_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	cloud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(cloud_label)

	_add_spacer(30)

	# If guest, show bind email option
	if player_info["is_guest"]:
		var bind_info = Label.new()
		bind_info.text = "Upgrade to full account to enable\nemail login and account recovery"
		bind_info.add_theme_font_size_override("font_size", 12)
		bind_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bind_info.custom_minimum_size = Vector2(300, 40)
		bind_info.modulate = Color(0.9, 0.9, 0.9)
		content_container.add_child(bind_info)

		_add_spacer(10)

		var bind_button = Button.new()
		bind_button.text = "Link Email to Account"
		bind_button.custom_minimum_size = Vector2(280, 45)
		bind_button.pressed.connect(func(): _show_bind_email_view())
		content_container.add_child(bind_button)

		_add_spacer(20)

	# Logout button
	var logout_button = Button.new()
	logout_button.text = "Logout"
	logout_button.custom_minimum_size = Vector2(280, 40)
	logout_button.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	logout_button.pressed.connect(_on_logout_pressed)
	content_container.add_child(logout_button)

func _show_login_view() -> void:
	current_view = "login"
	_clear_content()
	status_label.text = "Login with your email"

	# Email field
	_add_label("Email:")
	var email_input = LineEdit.new()
	email_input.placeholder_text = "your@email.com"
	email_input.custom_minimum_size = Vector2(280, 40)
	content_container.add_child(email_input)

	_add_spacer(15)

	# Password field
	_add_label("Password:")
	var password_input = LineEdit.new()
	password_input.placeholder_text = "Password"
	password_input.secret = true
	password_input.custom_minimum_size = Vector2(280, 40)
	content_container.add_child(password_input)

	_add_spacer(30)

	# Login button
	var login_button = Button.new()
	login_button.text = "Login"
	login_button.custom_minimum_size = Vector2(280, 50)
	login_button.add_theme_font_size_override("font_size", 18)
	login_button.pressed.connect(func():
		var email = email_input.text.strip_edges()
		var password = password_input.text
		if email.is_empty() or password.is_empty():
			status_label.text = "Please fill in all fields"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		else:
			CloudSaveManager.login_with_email(email, password)
			status_label.text = "Logging in..."
	)
	content_container.add_child(login_button)

	_add_spacer(15)

	# Back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(280, 35)
	back_button.pressed.connect(func(): _show_main_view())
	content_container.add_child(back_button)

func _show_register_view() -> void:
	current_view = "register"
	_clear_content()
	status_label.text = "Create a new account"

	# Username field
	_add_label("Username:")
	var username_input = LineEdit.new()
	username_input.placeholder_text = "Username"
	username_input.custom_minimum_size = Vector2(280, 40)
	content_container.add_child(username_input)

	_add_spacer(15)

	# Email field
	_add_label("Email:")
	var email_input = LineEdit.new()
	email_input.placeholder_text = "your@email.com"
	email_input.custom_minimum_size = Vector2(280, 40)
	content_container.add_child(email_input)

	_add_spacer(15)

	# Password field
	_add_label("Password:")
	var password_input = LineEdit.new()
	password_input.placeholder_text = "Min 6 characters"
	password_input.secret = true
	password_input.custom_minimum_size = Vector2(280, 40)
	content_container.add_child(password_input)

	_add_spacer(30)

	# Register button
	var register_button = Button.new()
	register_button.text = "Create Account"
	register_button.custom_minimum_size = Vector2(280, 50)
	register_button.add_theme_font_size_override("font_size", 18)
	register_button.pressed.connect(func():
		var username = username_input.text.strip_edges()
		var email = email_input.text.strip_edges()
		var password = password_input.text
		if username.is_empty() or email.is_empty() or password.is_empty():
			status_label.text = "Please fill in all fields"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		elif password.length() < 6:
			status_label.text = "Password must be at least 6 characters"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		else:
			CloudSaveManager.register_with_email(email, password, username)
			status_label.text = "Creating account..."
	)
	content_container.add_child(register_button)

	_add_spacer(15)

	# Back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(280, 35)
	back_button.pressed.connect(func(): _show_main_view())
	content_container.add_child(back_button)

func _show_bind_email_view() -> void:
	current_view = "bind"
	_clear_content()
	status_label.text = "Link email to your guest account"

	var info = Label.new()
	info.text = "Link an email to enable login from\nother devices and account recovery."
	info.add_theme_font_size_override("font_size", 12)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.custom_minimum_size = Vector2(300, 40)
	content_container.add_child(info)

	_add_spacer(20)

	# Email field
	_add_label("Email:")
	var email_input = LineEdit.new()
	email_input.placeholder_text = "your@email.com"
	email_input.custom_minimum_size = Vector2(280, 40)
	content_container.add_child(email_input)

	_add_spacer(15)

	# Password field
	_add_label("Password:")
	var password_input = LineEdit.new()
	password_input.placeholder_text = "Min 6 characters"
	password_input.secret = true
	password_input.custom_minimum_size = Vector2(280, 40)
	content_container.add_child(password_input)

	_add_spacer(30)

	# Bind button
	var bind_button = Button.new()
	bind_button.text = "Link Email"
	bind_button.custom_minimum_size = Vector2(280, 50)
	bind_button.add_theme_font_size_override("font_size", 18)
	bind_button.pressed.connect(func():
		var email = email_input.text.strip_edges()
		var password = password_input.text
		if email.is_empty() or password.is_empty():
			status_label.text = "Please fill in all fields"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		elif password.length() < 6:
			status_label.text = "Password must be at least 6 characters"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		else:
			CloudSaveManager.bind_email_to_guest(email, password)
			status_label.text = "Linking email..."
	)
	content_container.add_child(bind_button)

	_add_spacer(15)

	# Back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(280, 35)
	back_button.pressed.connect(func(): _show_main_view())
	content_container.add_child(back_button)

# === HELPERS ===

func _add_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(280, 25)
	content_container.add_child(label)

func _add_spacer(height: int) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	content_container.add_child(spacer)

# === BUTTON HANDLERS ===

func _on_guest_login_pressed() -> void:
	if CloudSaveManager:
		CloudSaveManager.login_as_guest()
		status_label.text = "Logging in as guest..."

func _on_logout_pressed() -> void:
	if CloudSaveManager:
		CloudSaveManager.logout()
		_show_main_view()
		account_updated.emit()

func _on_close_pressed() -> void:
	queue_free()

# === SIGNAL HANDLERS ===

func _on_login_succeeded(player_id: String) -> void:
	status_label.text = "Login successful!"
	status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_show_main_view()
	account_updated.emit()

func _on_login_failed(error: String) -> void:
	status_label.text = "Login failed: %s" % error
	status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))

func _on_account_created(player_id: String) -> void:
	status_label.text = "Account created! Logged in."
	status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_show_main_view()
	account_updated.emit()
