class_name StatisticsPanel
extends Panel

# === STATISTICS DISPLAY PANEL ===
# Displays lifetime statistics (currency, kills, spending)
# Extracted from main_hud.gd (Phase 3.2 Refactor - C7)
#
# Responsibilities:
# - Create statistics UI programmatically
# - Display RunStats lifetime data
# - Format large numbers for display
# - Handle account binding for guest users

signal panel_closed
signal bind_account_requested

## Creates the statistics panel UI
func _ready() -> void:
	# Panel configuration
	custom_minimum_size = Vector2(360, 700)
	position = Vector2(15, 50)
	visible = false

	# Create scroll container
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 680)
	scroll.position = Vector2(10, 10)
	add_child(scroll)

	# Create VBox for content
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "=== LIFETIME STATISTICS ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(320, 30)
	vbox.add_child(title)
	UIStyler.apply_theme_to_node(title)

	# Separator
	var sep_account = HSeparator.new()
	vbox.add_child(sep_account)

	# Account Section
	var account_title = Label.new()
	account_title.text = "🔐 Account"
	account_title.custom_minimum_size = Vector2(320, 25)
	vbox.add_child(account_title)
	UIStyler.apply_theme_to_node(account_title)

	var account_status = Label.new()
	account_status.name = "AccountStatusLabel"
	if CloudSaveManager and CloudSaveManager.is_logged_in:
		if CloudSaveManager.is_guest:
			account_status.text = "👤 Guest Account (ID: %s)" % CloudSaveManager.player_id.substr(0, 8)
		else:
			account_status.text = "✅ Registered Account (ID: %s)" % CloudSaveManager.player_id.substr(0, 8)
	else:
		account_status.text = "❌ Not Logged In"
	account_status.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(account_status)
	UIStyler.apply_theme_to_node(account_status)

	# Bind account button (only for guests)
	if CloudSaveManager and CloudSaveManager.is_logged_in and CloudSaveManager.is_guest:
		var bind_button = Button.new()
		bind_button.text = "🔗 Bind Email to Save Progress"
		bind_button.custom_minimum_size = Vector2(300, 40)
		bind_button.pressed.connect(_on_bind_account_button_pressed)
		vbox.add_child(bind_button)
		UIStyler.apply_theme_to_node(bind_button)

	# Separator
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)

	# Currency Stats
	_create_currency_section(vbox)

	# Separator
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Spending Stats
	_create_spending_section(vbox)

	# Separator
	var sep3 = HSeparator.new()
	vbox.add_child(sep3)

	# Kill Stats
	_create_kill_stats_section(vbox)

	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(200, 40)
	close_button.position = Vector2(200, 640)
	close_button.pressed.connect(_on_close_button_pressed)
	add_child(close_button)
	UIStyler.apply_theme_to_node(close_button)

## Updates all statistics with current RunStats data
func update_statistics() -> void:
	# Update currency stats
	var dc_label = get_node_or_null("ScrollContainer/VBoxContainer/DCStatLabel")
	if dc_label:
		dc_label.text = "Data Credits: %s" % format_number(RunStats.lifetime_dc_earned)

	var at_label = get_node_or_null("ScrollContainer/VBoxContainer/ATStatLabel")
	if at_label:
		at_label.text = "Archive Tokens: %s" % format_number(RunStats.lifetime_at_earned)

	var frag_label = get_node_or_null("ScrollContainer/VBoxContainer/FragStatLabel")
	if frag_label:
		frag_label.text = "Fragments: %s" % format_number(RunStats.lifetime_fragments_earned)

	# Update spending stats
	var lab_label = get_node_or_null("ScrollContainer/VBoxContainer/LabSpentLabel")
	if lab_label:
		lab_label.text = "On Labs: %s" % format_number(RunStats.lifetime_at_spent_labs)

	var perm_label = get_node_or_null("ScrollContainer/VBoxContainer/PermSpentLabel")
	if perm_label:
		perm_label.text = "On Permanent Upgrades: %s" % format_number(RunStats.lifetime_at_spent_perm_upgrades)

	var total_spent_label = get_node_or_null("ScrollContainer/VBoxContainer/TotalSpentLabel")
	if total_spent_label:
		var total = RunStats.lifetime_at_spent_labs + RunStats.lifetime_at_spent_perm_upgrades
		total_spent_label.text = "Total Spent: %s" % format_number(total)

	# Update kill stats
	var breacher_label = get_node_or_null("ScrollContainer/VBoxContainer/BreacherKillsLabel")
	if breacher_label:
		breacher_label.text = "Breachers: %s" % format_number(RunStats.lifetime_kills.get("breacher", 0))

	var slicer_label = get_node_or_null("ScrollContainer/VBoxContainer/SlicerKillsLabel")
	if slicer_label:
		slicer_label.text = "Slicers: %s" % format_number(RunStats.lifetime_kills.get("slicer", 0))

	var sentinel_label = get_node_or_null("ScrollContainer/VBoxContainer/SentinelKillsLabel")
	if sentinel_label:
		sentinel_label.text = "Sentinels: %s" % format_number(RunStats.lifetime_kills.get("sentinel", 0))

	var signal_label = get_node_or_null("ScrollContainer/VBoxContainer/SignalKillsLabel")
	if signal_label:
		signal_label.text = "Signal Runners: %s" % format_number(RunStats.lifetime_kills.get("signal_runner", 0))

	var null_label = get_node_or_null("ScrollContainer/VBoxContainer/NullKillsLabel")
	if null_label:
		null_label.text = "Null Walkers: %s" % format_number(RunStats.lifetime_kills.get("nullwalker", 0))

	var boss_label = get_node_or_null("ScrollContainer/VBoxContainer/BossKillsLabel")
	if boss_label:
		boss_label.text = "Bosses (Override): %s" % format_number(RunStats.lifetime_kills.get("override", 0))

	var total_kills_label = get_node_or_null("ScrollContainer/VBoxContainer/TotalKillsLabel")
	if total_kills_label:
		var total_kills = 0
		for kills in RunStats.lifetime_kills.values():
			total_kills += kills
		total_kills_label.text = "Total Kills: %s" % format_number(total_kills)

## Shows the panel and updates statistics
func show_panel() -> void:
	visible = true
	update_statistics()

## Hides the panel
func hide_panel() -> void:
	visible = false

# === PRIVATE HELPER FUNCTIONS ===

func _create_currency_section(vbox: VBoxContainer) -> void:
	var currency_title = Label.new()
	currency_title.text = "💰 Currency Earned"
	currency_title.custom_minimum_size = Vector2(320, 25)
	vbox.add_child(currency_title)
	UIStyler.apply_theme_to_node(currency_title)

	var dc_stat = Label.new()
	dc_stat.name = "DCStatLabel"
	dc_stat.text = "Data Credits: 0"
	dc_stat.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(dc_stat)
	UIStyler.apply_theme_to_node(dc_stat)

	var at_stat = Label.new()
	at_stat.name = "ATStatLabel"
	at_stat.text = "Archive Tokens: 0"
	at_stat.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(at_stat)
	UIStyler.apply_theme_to_node(at_stat)

	var frag_stat = Label.new()
	frag_stat.name = "FragStatLabel"
	frag_stat.text = "Fragments: 0"
	frag_stat.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(frag_stat)
	UIStyler.apply_theme_to_node(frag_stat)

func _create_spending_section(vbox: VBoxContainer) -> void:
	var spending_title = Label.new()
	spending_title.text = "💸 Archive Tokens Spent"
	spending_title.custom_minimum_size = Vector2(320, 25)
	vbox.add_child(spending_title)
	UIStyler.apply_theme_to_node(spending_title)

	var lab_spent = Label.new()
	lab_spent.name = "LabSpentLabel"
	lab_spent.text = "On Labs: 0"
	lab_spent.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(lab_spent)
	UIStyler.apply_theme_to_node(lab_spent)

	var perm_spent = Label.new()
	perm_spent.name = "PermSpentLabel"
	perm_spent.text = "On Permanent Upgrades: 0"
	perm_spent.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(perm_spent)
	UIStyler.apply_theme_to_node(perm_spent)

	var total_spent = Label.new()
	total_spent.name = "TotalSpentLabel"
	total_spent.text = "Total Spent: 0"
	total_spent.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(total_spent)
	UIStyler.apply_theme_to_node(total_spent)

func _create_kill_stats_section(vbox: VBoxContainer) -> void:
	var kills_title = Label.new()
	kills_title.text = "⚔️ Enemies Defeated"
	kills_title.custom_minimum_size = Vector2(320, 25)
	vbox.add_child(kills_title)
	UIStyler.apply_theme_to_node(kills_title)

	var breacher_kills = Label.new()
	breacher_kills.name = "BreacherKillsLabel"
	breacher_kills.text = "Breachers: 0"
	breacher_kills.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(breacher_kills)
	UIStyler.apply_theme_to_node(breacher_kills)

	var slicer_kills = Label.new()
	slicer_kills.name = "SlicerKillsLabel"
	slicer_kills.text = "Slicers: 0"
	slicer_kills.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(slicer_kills)
	UIStyler.apply_theme_to_node(slicer_kills)

	var sentinel_kills = Label.new()
	sentinel_kills.name = "SentinelKillsLabel"
	sentinel_kills.text = "Sentinels: 0"
	sentinel_kills.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(sentinel_kills)
	UIStyler.apply_theme_to_node(sentinel_kills)

	var signal_kills = Label.new()
	signal_kills.name = "SignalKillsLabel"
	signal_kills.text = "Signal Runners: 0"
	signal_kills.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(signal_kills)
	UIStyler.apply_theme_to_node(signal_kills)

	var null_kills = Label.new()
	null_kills.name = "NullKillsLabel"
	null_kills.text = "Null Walkers: 0"
	null_kills.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(null_kills)
	UIStyler.apply_theme_to_node(null_kills)

	var boss_kills = Label.new()
	boss_kills.name = "BossKillsLabel"
	boss_kills.text = "Bosses (Override): 0"
	boss_kills.custom_minimum_size = Vector2(320, 20)
	vbox.add_child(boss_kills)
	UIStyler.apply_theme_to_node(boss_kills)

	var total_kills = Label.new()
	total_kills.name = "TotalKillsLabel"
	total_kills.text = "Total Kills: 0"
	total_kills.custom_minimum_size = Vector2(320, 25)
	vbox.add_child(total_kills)
	UIStyler.apply_theme_to_node(total_kills)

## Formats large numbers with K/M/B/T/Qa/Qi suffixes
static func format_number(num: int) -> String:
	# Handle negative numbers
	var sign = "" if num >= 0 else "-"
	var abs_num = abs(num)

	# Small numbers (< 1000) - show raw value
	if abs_num < 1000:
		return str(num)

	# Define thresholds and suffixes for big numbers
	# Supports up to int64 max (~10^18 quintillion)
	const THRESHOLDS = [
		1000000000000000000,  # 10^18 Quintillion (Qi)
		1000000000000000,     # 10^15 Quadrillion (Qa)
		1000000000000,        # 10^12 Trillion (T)
		1000000000,           # 10^9 Billion (B)
		1000000,              # 10^6 Million (M)
		1000                  # 10^3 Thousand (K)
	]

	const SUFFIXES_BIG = ["Qi", "Qa", "T", "B", "M", "K"]
	const DIVISORS = [
		1000000000000000000.0,
		1000000000000000.0,
		1000000000000.0,
		1000000000.0,
		1000000.0,
		1000.0
	]

	# Find appropriate suffix
	for i in range(THRESHOLDS.size()):
		if abs_num >= THRESHOLDS[i]:
			var value = abs_num / DIVISORS[i]
			return "%s%.2f%s" % [sign, value, SUFFIXES_BIG[i]]

	# Fallback (shouldn't reach here)
	return str(num)

func _on_bind_account_button_pressed() -> void:
	bind_account_requested.emit()

func _on_close_button_pressed() -> void:
	hide_panel()
	panel_closed.emit()
