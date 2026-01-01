extends Control

# Wave and Tower Status
var wave: int = 1
var current_wave: int = 1
var wave_number: int = 1
var tower_hp: int = 1000
var wave_timer: float = 0.0
const WAVE_INTERVAL := 2.0

# Cleanup tracking
var refresh_timer: Timer = null

# Drone management (Phase 2.2 Refactor)
var drone_manager: DroneManager = null

# Game state management (Phase 3.1 Refactor)
var game_state_manager: GameStateManager = null

@onready var perm_nodes = {
	"projectile_damage": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermProjectileDamage/PermProjectileDamageLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermProjectileDamage/PermProjectileDamageButton,
	},
	"fire_rate": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermFireRate/PermFireRateLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermFireRate/PermFireRateButton,
	},
	"crit_chance": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermCritChance/PermCritChanceLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermCritChance/PermCritChanceButton,
	},
	"crit_damage": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermCritDamage/PermCritDamageLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermCritDamage/PermCritDamageButton,
	},
	"shield_integrity": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermShieldIntegrity/PermShieldIntegrityLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermShieldIntegrity/PermShieldIntegrityButton,
	},
	"shield_regen": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermShieldRegen/PermShieldRegenLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermShieldRegen/PermShieldRegenButton,
	},
	"damage_reduction": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermDamageReduction/PermDamageReductionLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermDamageReduction/PermDamageReductionButton,
	},
	"data_credit_multiplier": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermDataCreditMultiplier/PermDataCreditMultiplierLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermDataCreditMultiplier/PermDataCreditMultiplierButton,
	},
	"archive_token_multiplier": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermArchiveTokenMultiplier/PermArchiveTokenMultiplierLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermArchiveTokenMultiplier/PermArchiveTokenMultiplierButton,
	},
	"free_upgrade_chance": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermFreeUpgradeChance/PermFreeUpgradeChanceLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermFreeUpgradeChance/PermFreeUpgradeChanceButton,
	},
	"wave_skip_chance": {
		"level": $PermUpgradesPanel/PermUpgradesList/PermWaveSkipChance/PermWaveSkipChanceLevel,
		"button": $PermUpgradesPanel/PermUpgradesList/PermWaveSkipChance/PermWaveSkipChanceButton,
	}
}

@onready var perm_panel: Control = $PermUpgradesPanel
@onready var perm_panel_toggle_button: Button = $PermPanelToggleButton

var software_upgrade_panel: Control = null
var software_upgrade_button: Button = null

# Tier selection panel
var tier_selection_panel: Control = null
var tier_selection_button: Button = null

# Boss rush panel
var boss_rush_panel: Control = null
var boss_rush_button: Button = null

# Statistics panel (Phase 3.2 Refactor)
var statistics_panel: StatisticsPanel = null
var statistics_button: Button = null

# Drone upgrade panel
var drone_upgrade_panel: Control = null
var drone_upgrade_button: Button = null

# QC Shop panel
var qc_shop_panel: Control = null
var qc_shop_button: Button = null

# Milestone panel
var milestone_panel: Control = null
var milestone_button: Button = null

# Achievement panel
var achievement_panel: Control = null
var achievement_button: Button = null

# Drone purchase UI (in perm panel)
var drone_purchase_containers: Dictionary = {}
var drone_purchase_buttons: Dictionary = {}
var drone_status_labels: Dictionary = {}

var buy_x_options = [1, 5, 10, "Max"]
var current_buy_index = 0


# Speed Controls
@onready var speed_button: Button = $BottomBanner/SpeedButton
var speed_levels := [1.0, 2.0, 3.0, 4.0]
var current_speed_index := 0

# UI Nodes
@onready var wave_label: Label = $TopBanner/WaveLabel
@onready var dc_label: Label = $TopBanner/DCLabel
@onready var at_label: Label = $TopBanner/ATLabel
var fragments_label: Label = null  # Created programmatically
var tier_label: Label = null  # Created programmatically

# Offense Menu Root + Toggle
@onready var offense_button: Button = $UpgradeUI/ButtonBar/OffenseButton
@onready var offense_panel: VBoxContainer = $UpgradeUI/OffensePanel

# Offense Upgrade Buttons
@onready var damage_upgrade: Button = $UpgradeUI/OffensePanel/DamageUpgradeButton
@onready var fire_rate_upgrade: Button = $UpgradeUI/OffensePanel/FireRateUpgradeButton
@onready var crit_upgrade_button: Button = $UpgradeUI/OffensePanel/CritChanceUpgradeButton
@onready var crit_damage_upgrade: Button = $UpgradeUI/OffensePanel/CritDamageUpgradeButton
@onready var unlock_multi_target_button: Button = $UpgradeUI/OffensePanel/UnlockMultiTargetButton
@onready var upgrade_multi_target_button: Button = $UpgradeUI/OffensePanel/UpgradeMultiTargetButton
@onready var multi_target_label: Label = $UpgradeUI/OffensePanel/MultiTargetLabel


# Defense Upgrade Buttons
@onready var defense_button: Button = $UpgradeUI/ButtonBar/DefenseButton
@onready var defense_panel: VBoxContainer = $UpgradeUI/DefensePanel
@onready var shield_upgrade: Button = $UpgradeUI/DefensePanel/ShieldIntegrityUpgradeButton
@onready var reduction_upgrade: Button = $UpgradeUI/DefensePanel/DamageReductionUpgradeButton
@onready var regen_upgrade: Button = $UpgradeUI/DefensePanel/ShieldRegenUpgradeButton

# Economy Upgrade Buttons
@onready var economy_button: Button = $UpgradeUI/ButtonBar/EconomyButton
@onready var economy_panel: VBoxContainer = $UpgradeUI/EconomyPanel
@onready var data_credits_upgrade: Button = $UpgradeUI/EconomyPanel/DataCreditsUpgradeButton
@onready var archive_token_upgrade: Button = $UpgradeUI/EconomyPanel/ArchiveTokenUpgradeButton
@onready var free_upgrade_chance: Button = $UpgradeUI/EconomyPanel/FreeUpgradeChanceButton
@onready var wave_skip_chance: Button = $UpgradeUI/EconomyPanel/WaveSkipChanceButton

@onready var buy_x_button: Button = $BottomBanner/BuyXButton
@onready var quit_button: Button = $QuitButton

@onready var death_screen = null  # Will be set in _ready()
@onready var boss_rush_death_screen = null  # Will be set in _ready()
@onready var spawner: Node = $Spawner
@onready var tower: Node = $tower



func _ready() -> void:
	# Safely get death screen reference
	var current = get_tree().current_scene
	if current:
		death_screen = current.get_node_or_null("DeathScreen")

	# Add boss rush death screen
	boss_rush_death_screen = preload("res://boss_rush_death_screen.gd").new()
	boss_rush_death_screen.name = "BossRushDeathScreen"
	boss_rush_death_screen.visible = false
	add_child(boss_rush_death_screen)

	# Add offline progress popup (highest z-index)
	var offline_popup = preload("res://offline_progress_popup.gd").new()
	add_child(offline_popup)

	# Add Software Upgrade panel and toggle button
	software_upgrade_panel = preload("res://software_upgrade_ui.gd").new()
	software_upgrade_panel.visible = false
	add_child(software_upgrade_panel)

	# BOTTOM MENU BUTTONS - TWO ROWS TO FIT 390px MOBILE SCREEN
	# Row 1 (y=755): Labs, Tiers, Rush, Stats
	# Row 2 (y=800): Drones, Shop, Pass, Achieve
	# Each button: 90px wide, 5px spacing = 375px total (centered in 390px)

	# ROW 1 - Core Systems
	software_upgrade_button = Button.new()
	software_upgrade_button.text = "🔬 Labs"
	software_upgrade_button.position = Vector2(8, 755)
	software_upgrade_button.custom_minimum_size = Vector2(90, 35)
	software_upgrade_button.pressed.connect(_on_software_upgrade_button_pressed)
	add_child(software_upgrade_button)

	# Add Tier Selection panel and button
	tier_selection_panel = preload("res://tier_selection_ui.gd").new()
	tier_selection_panel.visible = false
	add_child(tier_selection_panel)

	tier_selection_button = Button.new()
	tier_selection_button.text = "🎖️ Tiers"
	tier_selection_button.position = Vector2(103, 755)
	tier_selection_button.custom_minimum_size = Vector2(90, 35)
	tier_selection_button.pressed.connect(_on_tier_selection_button_pressed)
	add_child(tier_selection_button)

	# Add Boss Rush panel and button
	boss_rush_panel = preload("res://boss_rush_ui.gd").new()
	boss_rush_panel.visible = false
	add_child(boss_rush_panel)

	boss_rush_button = Button.new()
	boss_rush_button.text = "🏆 Rush"
	boss_rush_button.position = Vector2(198, 755)
	boss_rush_button.custom_minimum_size = Vector2(90, 35)
	boss_rush_button.pressed.connect(_on_boss_rush_button_pressed)
	add_child(boss_rush_button)

	# Add Statistics button
	statistics_button = Button.new()
	statistics_button.text = "📊 Stats"
	statistics_button.position = Vector2(293, 755)
	statistics_button.custom_minimum_size = Vector2(90, 35)
	statistics_button.pressed.connect(_on_statistics_button_pressed)
	add_child(statistics_button)

	# Create statistics panel (Phase 3.2 Refactor)
	statistics_panel = StatisticsPanel.new()
	statistics_panel.panel_closed.connect(_on_statistics_panel_closed)
	statistics_panel.bind_account_requested.connect(_on_bind_account_requested)
	add_child(statistics_panel)

	# ROW 2 - Progression Systems
	# Add Drone Upgrade panel and button
	drone_upgrade_panel = preload("res://drone_upgrade_ui.gd").new()
	drone_upgrade_panel.visible = false
	add_child(drone_upgrade_panel)

	drone_upgrade_button = Button.new()
	drone_upgrade_button.text = "🚁 Drones"
	drone_upgrade_button.position = Vector2(8, 800)
	drone_upgrade_button.custom_minimum_size = Vector2(90, 35)
	drone_upgrade_button.pressed.connect(_on_drone_upgrade_button_pressed)
	add_child(drone_upgrade_button)

	# Add QC Shop panel and button
	qc_shop_panel = preload("res://quantum_core_shop_ui.gd").new()
	qc_shop_panel.visible = false
	add_child(qc_shop_panel)

	qc_shop_button = Button.new()
	qc_shop_button.text = "💎 Shop"
	qc_shop_button.position = Vector2(103, 800)
	qc_shop_button.custom_minimum_size = Vector2(90, 35)
	qc_shop_button.pressed.connect(_on_qc_shop_button_pressed)
	add_child(qc_shop_button)

	# Add Milestone panel and button
	milestone_panel = preload("res://milestone_ui.gd").new()
	milestone_panel.visible = false
	add_child(milestone_panel)

	milestone_button = Button.new()
	milestone_button.text = "🎖️ Pass"
	milestone_button.position = Vector2(198, 800)
	milestone_button.custom_minimum_size = Vector2(90, 35)
	milestone_button.pressed.connect(_on_milestone_button_pressed)
	add_child(milestone_button)

	# Add Achievement panel and button
	achievement_panel = preload("res://achievement_ui.gd").new()
	achievement_panel.visible = false
	add_child(achievement_panel)

	achievement_button = Button.new()
	achievement_button.text = "🏆 Achieve"
	achievement_button.position = Vector2(293, 800)
	achievement_button.custom_minimum_size = Vector2(90, 35)
	achievement_button.pressed.connect(_on_achievement_button_pressed)
	add_child(achievement_button)

	# Add matrix code rain (furthest back)
	var matrix_rain = preload("res://MatrixCodeRain.gd").new()
	add_child(matrix_rain)
	move_child(matrix_rain, 0)

	# Add background layers (parallax depth)
	var bg_layers = preload("res://BackgroundLayers.gd").new()
	add_child(bg_layers)
	move_child(bg_layers, 1)  # Render after matrix

	# Add background effects (grid + CRT + bloom + chromatic aberration)
	var bg_effects = preload("res://BackgroundEffects.gd").new()
	add_child(bg_effects)
	move_child(bg_effects, 2)  # Render after layers

	# Add holographic UI overlays
	var holo_ui = preload("res://HolographicUI.gd").new()
	add_child(holo_ui)

	# Create fragments label in TopBanner
	var top_banner = get_node_or_null("TopBanner")
	if top_banner:
		fragments_label = Label.new()
		fragments_label.name = "FragmentsLabel"
		fragments_label.text = "💎: 0"
		fragments_label.position = Vector2(6, 45)  # Position below AT label
		fragments_label.size = Vector2(150, 20)
		top_banner.add_child(fragments_label)
		UIStyler.apply_theme_to_node(fragments_label)

		# Create tier label in TopBanner
		tier_label = Label.new()
		tier_label.name = "TierLabel"
		tier_label.text = "🎖️ Tier: 1"
		tier_label.position = Vector2(6, 70)  # Position below Fragments label
		tier_label.size = Vector2(150, 20)
		top_banner.add_child(tier_label)
		UIStyler.apply_theme_to_node(tier_label)

	# Connect upgrade and toggle buttons
	offense_button.pressed.connect(_on_offense_button_pressed)
	# Generic upgrade handler (Phase 1 refactor)
	damage_upgrade.pressed.connect(_handle_inrun_upgrade.bind("damage"))
	fire_rate_upgrade.pressed.connect(_handle_inrun_upgrade.bind("fire_rate"))
	crit_upgrade_button.pressed.connect(_handle_inrun_upgrade.bind("crit_chance"))
	crit_damage_upgrade.pressed.connect(_handle_inrun_upgrade.bind("crit_damage"))
	defense_button.pressed.connect(_on_defense_button_pressed)
	shield_upgrade.pressed.connect(_handle_inrun_upgrade.bind("shield"))
	reduction_upgrade.pressed.connect(_handle_inrun_upgrade.bind("damage_reduction"))
	regen_upgrade.pressed.connect(_handle_inrun_upgrade.bind("shield_regen"))
	economy_button.pressed.connect(_on_economy_button_pressed)
	data_credits_upgrade.pressed.connect(_handle_inrun_upgrade.bind("data_credits"))
	archive_token_upgrade.pressed.connect(_handle_inrun_upgrade.bind("archive_token"))
	free_upgrade_chance.pressed.connect(_handle_inrun_upgrade.bind("free_upgrade"))
	wave_skip_chance.pressed.connect(_handle_inrun_upgrade.bind("wave_skip"))
	speed_button.pressed.connect(_on_speed_button_pressed)
	buy_x_button.text = "Buy x" + str(buy_x_options[current_buy_index])
	buy_x_button.pressed.connect(_on_buy_x_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	perm_panel_toggle_button.pressed.connect(_on_perm_panel_toggle_button_pressed)
	unlock_multi_target_button.pressed.connect(_on_unlock_multi_target_pressed)
	upgrade_multi_target_button.pressed.connect(_on_upgrade_multi_target_pressed)

	for key in perm_nodes.keys():
		var button = perm_nodes[key]["button"]
		button.pressed.connect(_on_perm_upgrade_pressed.bind(key))
		update_perm_upgrade_ui(key)


	
	# Set initial time scale and update label
	Engine.time_scale = speed_levels[0]
	_update_speed_button_label()

	# Hide panels initially
	offense_panel.visible = false
	defense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false

	# Initialize drone manager (Phase 2.2 Refactor)
	drone_manager = DroneManager.new()
	drone_manager.spawn_parent = self
	add_child(drone_manager)

	# Auto-spawn owned drones (purchased out-of-run)
	var tower_pos = Vector2(193, 637)  # Tower position from tower.tscn
	drone_manager.spawn_owned_drones(tower_pos)

	# Initialize game state manager (Phase 3.1 Refactor)
	game_state_manager = GameStateManager.new()
	game_state_manager.spawner = spawner
	game_state_manager.tower = tower
	game_state_manager.main_hud = self
	add_child(game_state_manager)

	# Spawner hookup
	spawner.set_main_hud(self)
	spawner.start_wave(wave)
	randomize()
	RewardManager.load_permanent_upgrades()
	update_all_perm_upgrade_ui()

	# Create drone purchase UI in permanent upgrades panel
	_create_drone_purchase_ui()

	# Start tracking this run's performance
	RewardManager.start_run_tracking(wave)

	# Refresh currency labels every 0.2s
	refresh_timer = Timer.new()
	refresh_timer.wait_time = 0.2
	refresh_timer.timeout.connect(update_labels)
	refresh_timer.autostart = true
	add_child(refresh_timer)
	RewardManager.archive_tokens_changed.connect(update_all_perm_upgrade_ui)
	update_labels()
	update_damage_label()
	update_all_inrun_upgrade_ui()  # Initialize in-run upgrade button costs

	# Apply cyber theme to all UI elements
	UIStyler.apply_theme_to_node(self)

func _exit_tree() -> void:
	# Clean up refresh timer
	if refresh_timer and is_instance_valid(refresh_timer):
		refresh_timer.stop()
		if refresh_timer.timeout.is_connected(Callable(self, "update_labels")):
			refresh_timer.timeout.disconnect(Callable(self, "update_labels"))
		refresh_timer.queue_free()

	# Disconnect signal from RewardManager
	if RewardManager.archive_tokens_changed.is_connected(Callable(self, "update_all_perm_upgrade_ui")):
		RewardManager.archive_tokens_changed.disconnect(Callable(self, "update_all_perm_upgrade_ui"))

	# Clean up drones (Phase 2.2 Refactor)
	if drone_manager:
		drone_manager.cleanup_drones()

func _process(delta: float) -> void:
	wave_timer += delta
	if spawner.wave_spawning:
		return
	if wave_timer >= WAVE_INTERVAL:
		wave_timer = 0.0
		UpgradeManager.maybe_grant_free_upgrade()  # Grant before wave starts
		spawner.start_wave(spawner.current_wave + 1)  # always request next wave
		update_labels()


func update_labels() -> void:
	wave_label.text = "Wave: %d" % spawner.current_wave
	at_label.text = "AT: %d" % RewardManager.archive_tokens
	dc_label.text = "DC: %d" % RewardManager.data_credits
	if fragments_label:
		fragments_label.text = "💎: %d" % RewardManager.fragments
	if tier_label:
		tier_label.text = "🎖️ Tier: %d" % TierManager.get_current_tier()

	# Update in-run upgrade button costs (since DC changes frequently)
	update_all_inrun_upgrade_ui()

func update_damage_label() -> void:
	# Debug function - no UI update needed (damage_label node removed)
	pass

# --- Offense Panel Logic ---
func _on_offense_button_pressed() -> void:
	var new_state = not offense_panel.visible
	offense_panel.visible = new_state
	defense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false

# Offense upgrade handlers removed - replaced by generic _handle_inrun_upgrade()

func update_crit_label():
	var chance = UpgradeManager.get_crit_chance()
	print("Crit Chance: %d%%" % chance)

# === GENERIC UPGRADE HANDLER (Phase 1 Refactor) ===
# Metadata table for all in-run upgrade handlers
# Eliminates 11 duplicated button handlers (120+ lines → 1 generic function)
const UPGRADE_METADATA = {
	"damage": {
		"upgrade_func": "upgrade_projectile_damage",
		"post_actions": ["update_damage_label", "tower_update_visual"]
	},
	"fire_rate": {
		"upgrade_func": "upgrade_fire_rate",
		"post_actions": ["tower_refresh_fire_rate", "tower_update_visual", "update_labels"]
	},
	"crit_chance": {
		"upgrade_func": "upgrade_crit_chance",
		"post_actions": ["update_crit_label", "update_labels"]
	},
	"crit_damage": {
		"upgrade_func": "upgrade_crit_damage",
		"post_actions": ["update_labels"]
	},
	"shield": {
		"upgrade_func": "upgrade_shield_integrity",
		"post_actions": ["tower_refresh_shield", "update_labels"]
	},
	"damage_reduction": {
		"upgrade_func": "upgrade_damage_reduction",
		"post_actions": ["update_labels"]
	},
	"shield_regen": {
		"upgrade_func": "upgrade_shield_regen",
		"post_actions": ["tower_refresh_shield", "update_labels"]
	},
	"data_credits": {
		"upgrade_func": "upgrade_data_credit_multiplier",
		"post_actions": ["update_labels"]
	},
	"archive_token": {
		"upgrade_func": "upgrade_archive_token_multiplier",
		"post_actions": ["update_labels"]
	},
	"free_upgrade": {
		"upgrade_func": "upgrade_free_upgrade_chance",
		"post_actions": ["update_labels"]
	},
	"wave_skip": {
		"upgrade_func": "upgrade_wave_skip_chance",
		"post_actions": ["update_labels"]
	}
}

# Generic upgrade handler - replaces 11 duplicated functions
func _handle_inrun_upgrade(upgrade_key: String) -> void:
	if not UPGRADE_METADATA.has(upgrade_key):
		push_error("Invalid upgrade key: %s" % upgrade_key)
		return

	var metadata = UPGRADE_METADATA[upgrade_key]
	var amount = get_current_buy_amount()

	# Execute upgrade purchases
	if amount == -1:
		# Max mode: buy until can't afford
		while UpgradeManager.call(metadata.upgrade_func):
			pass
	else:
		# Buy specified amount
		for i in range(amount):
			if not UpgradeManager.call(metadata.upgrade_func):
				break

	# Execute post-actions
	for action in metadata.post_actions:
		match action:
			"update_labels":
				update_labels()
			"update_damage_label":
				update_damage_label()
			"update_crit_label":
				update_crit_label()
			"tower_update_visual":
				if tower and is_instance_valid(tower):
					tower.update_visual_tier()
			"tower_refresh_fire_rate":
				if tower and is_instance_valid(tower):
					tower.refresh_fire_rate()
			"tower_refresh_shield":
				if tower and is_instance_valid(tower):
					tower.refresh_shield_stats()
			_:
				push_warning("Unknown post-action: %s" % action)

# === GENERIC UI UPDATE FUNCTION (Phase 1.2 Refactor) ===
# Metadata table for all in-run upgrade button UI updates
# Eliminates 165+ lines of duplicated UI update logic
const BUTTON_UI_METADATA = {
	"damage": {
		"button": "damage_upgrade",
		"base_cost": "DAMAGE_UPGRADE_BASE_COST",
		"purchases": "damage_purchases",
		"label": "Damage"
	},
	"fire_rate": {
		"button": "fire_rate_upgrade",
		"base_cost": "FIRE_RATE_UPGRADE_BASE_COST",
		"purchases": "fire_rate_purchases",
		"label": "Fire Rate"
	},
	"crit_chance": {
		"button": "crit_upgrade_button",
		"base_cost": "CRIT_CHANCE_UPGRADE_BASE_COST",
		"purchases": "crit_chance_purchases",
		"label": "Crit Chance",
		"has_cap": true,
		"cap_func": "get_crit_chance",
		"cap_value": "CRIT_CHANCE_CAP"
	},
	"crit_damage": {
		"button": "crit_damage_upgrade",
		"base_cost": "CRIT_DAMAGE_UPGRADE_BASE_COST",
		"purchases": "crit_damage_purchases",
		"label": "Crit Damage"
	},
	"shield": {
		"button": "shield_upgrade",
		"base_cost": "SHIELD_UPGRADE_BASE_COST",
		"purchases": "shield_purchases",
		"label": "Shield Integrity"
	},
	"damage_reduction": {
		"button": "reduction_upgrade",
		"base_cost": "DAMAGE_REDUCTION_UPGRADE_BASE_COST",
		"purchases": "damage_reduction_purchases",
		"label": "Damage Reduction"
	},
	"shield_regen": {
		"button": "regen_upgrade",
		"base_cost": "SHIELD_REGEN_UPGRADE_BASE_COST",
		"purchases": "shield_regen_purchases",
		"label": "Shield Regen"
	},
	"data_credits": {
		"button": "data_credits_upgrade",
		"base_cost": "DATA_MULTIPLIER_UPGRADE_BASE_COST",
		"purchases": "data_multiplier_purchases",
		"label": "Data Credits Multiplier"
	},
	"archive_token": {
		"button": "archive_token_upgrade",
		"base_cost": "ARCHIVE_MULTIPLIER_UPGRADE_BASE_COST",
		"purchases": "archive_multiplier_purchases",
		"label": "Archive Token Multiplier"
	},
	"free_upgrade": {
		"button": "free_upgrade_chance",
		"base_cost": "FREE_UPGRADE_BASE_COST",
		"purchases": "free_upgrade_purchases",
		"label": "Free Upgrade Chance",
		"has_cap": true,
		"cap_func": "get_free_upgrade_chance",
		"cap_value": "FREE_UPGRADE_MAX_CHANCE"
	},
	"wave_skip": {
		"button": "wave_skip_chance",
		"base_cost": "WAVE_SKIP_UPGRADE_BASE_COST",
		"purchases": "wave_skip_purchases",
		"label": "Wave Skip Chance",
		"has_cap": true,
		"cap_func": "get_wave_skip_chance",
		"cap_value": "WAVE_SKIP_MAX_CHANCE"
	}
}

# Generic UI update function - replaces 165+ lines of duplicated button update logic
func _update_upgrade_button_ui(upgrade_key: String) -> void:
	if not BUTTON_UI_METADATA.has(upgrade_key):
		push_error("Invalid upgrade key for UI: %s" % upgrade_key)
		return

	var metadata = BUTTON_UI_METADATA[upgrade_key]
	var button = get(metadata.button)
	if not button:
		push_error("Button not found: %s" % metadata.button)
		return

	var dc = RewardManager.data_credits
	var buy_amount = get_current_buy_amount()

	# Check if upgrade is capped
	if metadata.has("has_cap") and metadata.has_cap:
		var current_value = UpgradeManager.call(metadata.cap_func)
		var cap_value = UpgradeManager.get(metadata.cap_value)
		if current_value >= cap_value:
			button.text = "%s (MAX)" % metadata.label
			button.disabled = true
			return

	# Get cost constants
	var base_cost = UpgradeManager.get(metadata.base_cost)
	var purchases = UpgradeManager.get(metadata.purchases)

	# Calculate cost and text
	var cost: int
	var text: String

	if buy_amount == -1:
		# Max mode: show how many can afford
		var arr = BulkPurchaseCalculator.get_inrun_max_affordable(base_cost, purchases, dc)
		cost = arr[1]
		text = "%s x%d (%s DC)" % [metadata.label, arr[0], NumberFormatter.format(cost)]
	else:
		# Buy X mode: show cost for X purchases
		cost = BulkPurchaseCalculator.get_inrun_total_cost(base_cost, purchases, buy_amount)
		text = "%s x%d (%s DC)" % [metadata.label, buy_amount, NumberFormatter.format(cost)]

	button.text = text
	button.disabled = dc < cost or cost == 0

func update_all_inrun_upgrade_ui() -> void:
	# Generic updates for all 11 upgrades
	for upgrade_key in BUTTON_UI_METADATA.keys():
		_update_upgrade_button_ui(upgrade_key)
	# Multi-target has custom logic (unlock vs upgrade)
	update_multi_target_ui()

func _on_unlock_multi_target_pressed():
	if UpgradeManager.unlock_multi_target():
		update_multi_target_ui()
		update_labels()

func _on_upgrade_multi_target_pressed():
	if UpgradeManager.upgrade_multi_target():
		update_multi_target_ui()
		update_labels()
		
func update_multi_target_ui():
	if not UpgradeManager.multi_target_unlocked:
		unlock_multi_target_button.visible = true
		upgrade_multi_target_button.visible = false
		var cost = UpgradeManager.get_multi_target_cost_for_level(1)
		unlock_multi_target_button.text = "Unlock Multi Target (%d DC)" % cost
		unlock_multi_target_button.disabled = RewardManager.data_credits < cost
		multi_target_label.text = "Multi Target: Locked"
	else:
		unlock_multi_target_button.visible = false
		upgrade_multi_target_button.visible = true
		var lvl = UpgradeManager.multi_target_level
		var targets = lvl + 1

		# Handle max level separately to avoid type mismatch
		if lvl >= UpgradeManager.MULTI_TARGET_MAX_LEVEL:
			upgrade_multi_target_button.text = "Max Level Reached"
			upgrade_multi_target_button.disabled = true
		else:
			var next_cost = UpgradeManager.get_multi_target_cost_for_level(lvl + 1)
			upgrade_multi_target_button.text = "Upgrade Multi Target (%d DC)" % next_cost
			upgrade_multi_target_button.disabled = RewardManager.data_credits < next_cost

		multi_target_label.text = "Multi Target: %d" % targets

# --- IN-RUN UPGRADE UI UPDATE FUNCTIONS (Phase 1.2 Refactor) ---
# Old category-specific update functions removed - replaced by generic _update_upgrade_button_ui()
# Eliminated: update_offense_upgrade_ui(), update_defense_upgrade_ui(), update_economy_upgrade_ui()
# Total reduction: 165+ lines of duplicated code

# --- Defense Panel Logic ---
func _on_defense_button_pressed():
	var new_state = not defense_panel.visible
	defense_panel.visible = new_state
	offense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false
	
# Defense upgrade handlers removed - replaced by generic _handle_inrun_upgrade()

# --- Economy Panel Logic ---
func _on_economy_button_pressed():
	var new_state = not economy_panel.visible
	economy_panel.visible = new_state
	offense_panel.visible = false
	defense_panel.visible = false
	perm_panel.visible = false

# Economy upgrade handlers removed - replaced by generic _handle_inrun_upgrade()

# --- Speed Button Logic ---
func _on_speed_button_pressed() -> void:
	current_speed_index = (current_speed_index + 1) % speed_levels.size()
	var new_speed = speed_levels[current_speed_index]
	Engine.time_scale = new_speed
	_update_speed_button_label()
	print("⚡ Game speed set to %.1fx" % new_speed)

func _update_speed_button_label() -> void:
	var new_speed = speed_levels[current_speed_index]
	speed_button.text = "%.0fx Speed" % new_speed
	
func _on_perm_upgrade_pressed(key):
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_permanent(key):
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_permanent(key):
				break
	update_all_perm_upgrade_ui()

	# Refresh drones if drone upgrades were purchased (Phase 2.2 Refactor)
	if key in ["drone_flame", "drone_frost", "drone_poison", "drone_shock"]:
		if drone_manager:
			drone_manager.refresh_all_drones()

	
func _on_buy_x_button_pressed():
	current_buy_index = (current_buy_index + 1) % buy_x_options.size()
	buy_x_button.text = "Buy x" + str(buy_x_options[current_buy_index])



func update_perm_upgrade_ui(key):
	var level = UpgradeManager.get_perm_level(key)
	var at = RewardManager.archive_tokens
	var buy_amount = get_current_buy_amount()
	var label_text = ""
	var total_cost = 0

	if buy_amount == -1:
		# Max: Calculate how many upgrades you can actually afford, and total cost for that amount
		var arr = BulkPurchaseCalculator.get_perm_max_affordable(key, at)
		var max_afford = arr[0]
		var max_cost = arr[1]
		label_text = "Upgrade x%s (%s AT)" % [str(max_afford), str(max_cost)]
		total_cost = max_cost
	else:
		total_cost = BulkPurchaseCalculator.get_perm_total_cost(key, buy_amount)
		label_text = "Upgrade x%s (%s AT)" % [str(buy_amount), str(total_cost)]

	perm_nodes[key]["level"].text = "Lvl %d" % level
	perm_nodes[key]["button"].text = label_text
	perm_nodes[key]["button"].disabled = at < (total_cost if total_cost > 0 else UpgradeManager.get_perm_upgrade_cost(key))


func update_all_perm_upgrade_ui():
	for key in perm_nodes.keys():
		update_perm_upgrade_ui(key)

# Drone spawn and refresh functions extracted to DroneManager.gd (Phase 2.2 Refactor)
# - spawn_owned_drones()
# - refresh_all_drones()
# - cleanup_drones()

func get_current_buy_amount() -> int:
	var x = buy_x_options[current_buy_index]
	return -1 if x is String and x == "Max" else x

# Bulk purchase calculations extracted to BulkPurchaseCalculator.gd (Phase 2.1 Refactor)
# - get_perm_total_cost()
# - get_perm_max_affordable()
# - get_inrun_total_cost()
# - get_inrun_max_affordable()

# === DRONE PURCHASE UI (IN PERM PANEL) ===

func _create_drone_purchase_ui() -> void:
	var perm_list = get_node_or_null("PermUpgradesPanel/PermUpgradesList")
	if not perm_list:
		print("⚠️ PermUpgradesList not found!")
		return

	# Add separator before drones section
	var separator = HSeparator.new()
	perm_list.add_child(separator)

	# Add drones section title
	var title_container = HBoxContainer.new()
	perm_list.add_child(title_container)

	var title = Label.new()
	title.text = "=== DRONES (Purchase with 💎 Fragments) ==="
	title.custom_minimum_size = Vector2(400, 25)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title)

	# Drone types and info
	var drone_info = {
		"flame": {"name": "🔥 Flame", "desc": "Burns enemies"},
		"frost": {"name": "❄️ Frost", "desc": "Slows fastest"},
		"poison": {"name": "🟣 Poison", "desc": "Poisons enemies"},
		"shock": {"name": "⚡ Shock", "desc": "Stuns closest"}
	}

	for drone_type in ["flame", "frost", "poison", "shock"]:
		var info = drone_info[drone_type]

		# Create container
		var container = HBoxContainer.new()
		container.custom_minimum_size = Vector2(400, 30)
		drone_purchase_containers[drone_type] = container
		perm_list.add_child(container)

		# Name label
		var name_label = Label.new()
		name_label.text = info["name"]
		name_label.custom_minimum_size = Vector2(80, 30)
		container.add_child(name_label)

		# Status label
		var status_label = Label.new()
		status_label.text = "Not Owned"
		status_label.custom_minimum_size = Vector2(120, 30)
		drone_status_labels[drone_type] = status_label
		container.add_child(status_label)

		# Purchase button
		var button = Button.new()
		button.text = "Purchase (5000 💎)"
		button.custom_minimum_size = Vector2(180, 30)
		button.pressed.connect(_on_drone_purchase_button_pressed.bind(drone_type))
		drone_purchase_buttons[drone_type] = button
		container.add_child(button)

	# Initial UI update
	_update_drone_purchase_ui()

func _on_drone_purchase_button_pressed(drone_type: String) -> void:
	var cost = RewardManager.get_drone_purchase_cost(drone_type)
	if RewardManager.purchase_drone_permanent(drone_type, cost):
		_update_drone_purchase_ui()
		print("💎 Successfully purchased", drone_type, "drone!")

func _update_drone_purchase_ui() -> void:
	for drone_type in ["flame", "frost", "poison", "shock"]:
		if not drone_status_labels.has(drone_type) or not drone_purchase_buttons.has(drone_type):
			continue

		var status_label = drone_status_labels[drone_type]
		var button = drone_purchase_buttons[drone_type]
		var is_owned = RewardManager.owns_drone(drone_type)
		var cost = RewardManager.get_drone_purchase_cost(drone_type)

		# Update status
		if is_owned:
			status_label.text = "✅ Owned"
			button.text = "Owned"
			button.disabled = true
		else:
			status_label.text = "Not Owned"
			button.text = "Purchase (%d 💎)" % cost
			button.disabled = RewardManager.fragments < cost

# === PERM PANEL FUNCTIONS ===

func _on_perm_panel_toggle_button_pressed():
	perm_panel.visible = not perm_panel.visible
	if perm_panel.visible:
		perm_panel_toggle_button.text = "Hide Upgrades"
		# Hide all other panels when perm panel is shown
		offense_panel.visible = false
		defense_panel.visible = false
		economy_panel.visible = false
		if software_upgrade_panel:
			software_upgrade_panel.visible = false
		# Update drone purchase UI when opening perm panel
		_update_drone_purchase_ui()
	else:
		perm_panel_toggle_button.text = "Show Upgrades"

func _on_software_upgrade_button_pressed():
	if software_upgrade_panel:
		software_upgrade_panel.visible = not software_upgrade_panel.visible
		if software_upgrade_panel.visible:
			_hide_all_progression_panels_except("software_upgrade")

func _on_tier_selection_button_pressed():
	if tier_selection_panel:
		tier_selection_panel.visible = not tier_selection_panel.visible
		if tier_selection_panel.visible:
			_hide_all_progression_panels_except("tier_selection")

func _on_boss_rush_button_pressed():
	if boss_rush_panel:
		boss_rush_panel.visible = not boss_rush_panel.visible
		if boss_rush_panel.visible:
			_hide_all_progression_panels_except("boss_rush")

# Game state management functions delegated to GameStateManager (Phase 3.1 Refactor)
func reset_to_wave_1():
	if game_state_manager:
		game_state_manager.reset_to_wave_1()

func start_boss_rush():
	if game_state_manager:
		game_state_manager.start_boss_rush()

func exit_boss_rush():
	if game_state_manager:
		game_state_manager.exit_boss_rush()

func _on_quit_button_pressed():
	if game_state_manager:
		game_state_manager.quit_to_menu()

# === STATISTICS PANEL (Phase 3.2 Refactor) ===
# Statistics panel extracted to StatisticsPanel.gd

func _on_statistics_button_pressed() -> void:
	if not statistics_panel:
		return

	if statistics_panel.visible:
		statistics_panel.hide_panel()
	else:
		statistics_panel.show_panel()
		_hide_all_progression_panels_except("statistics")

func _on_statistics_panel_closed() -> void:
	# Signal handler from StatisticsPanel
	pass

func _on_bind_account_requested() -> void:
	# Handle bind account request from StatisticsPanel
	if not CloudSaveManager:
		print("⚠️ CloudSaveManager not available")
		return

	if not CloudSaveManager.is_guest:
		print("⚠️ Account already registered")
		return

	# Show login UI in bind mode
	var login_ui = preload("res://login_ui.gd").new()
	add_child(login_ui)
	login_ui.show_login()
	login_ui.login_completed.connect(func():
		print("✅ Account bound successfully!")
		# Refresh statistics panel to show new account status
		if statistics_panel and statistics_panel.visible:
			statistics_panel.queue_free()
			statistics_panel = StatisticsPanel.new()
			statistics_panel.panel_closed.connect(_on_statistics_panel_closed)
			statistics_panel.bind_account_requested.connect(_on_bind_account_requested)
			add_child(statistics_panel)
			statistics_panel.show_panel()
	)

# === NEW PROGRESSION UI BUTTON HANDLERS ===

func _on_drone_upgrade_button_pressed() -> void:
	if drone_upgrade_panel:
		drone_upgrade_panel.visible = not drone_upgrade_panel.visible
		if drone_upgrade_panel.visible:
			# Hide other panels
			_hide_all_progression_panels_except("drone_upgrade")

func _on_qc_shop_button_pressed() -> void:
	if qc_shop_panel:
		qc_shop_panel.visible = not qc_shop_panel.visible
		if qc_shop_panel.visible:
			# Hide other panels
			_hide_all_progression_panels_except("qc_shop")

func _on_milestone_button_pressed() -> void:
	if milestone_panel:
		milestone_panel.visible = not milestone_panel.visible
		if milestone_panel.visible:
			# Hide other panels
			_hide_all_progression_panels_except("milestone")

func _on_achievement_button_pressed() -> void:
	if achievement_panel:
		achievement_panel.visible = not achievement_panel.visible
		if achievement_panel.visible:
			# Hide other panels
			_hide_all_progression_panels_except("achievement")

func _hide_all_progression_panels_except(keep_visible: String) -> void:
	# Hide in-run upgrade panels
	offense_panel.visible = false
	defense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false

	# Hide other progression panels
	if software_upgrade_panel and keep_visible != "software_upgrade":
		software_upgrade_panel.visible = false
	if tier_selection_panel and keep_visible != "tier_selection":
		tier_selection_panel.visible = false
	if boss_rush_panel and keep_visible != "boss_rush":
		boss_rush_panel.visible = false
	if statistics_panel and keep_visible != "statistics":
		statistics_panel.visible = false
	if drone_upgrade_panel and keep_visible != "drone_upgrade":
		drone_upgrade_panel.visible = false
	if qc_shop_panel and keep_visible != "qc_shop":
		qc_shop_panel.visible = false
	if milestone_panel and keep_visible != "milestone":
		milestone_panel.visible = false
	if achievement_panel and keep_visible != "achievement":
		achievement_panel.visible = false
