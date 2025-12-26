extends Control

# Wave and Tower Status
var wave: int = 1
var current_wave: int = 1
var wave_number: int = 1
var tower_hp: int = 1000
var wave_timer: float = 0.0
const WAVE_INTERVAL := 2.0

# Cleanup tracking
var active_drones: Array = []
var refresh_timer: Timer = null

const DRONE_FLAME_SCENE = preload("res://drone_flame.tscn")
const DRONE_POISON_SCENE = preload("res://drone_poison.tscn")
const DRONE_FROST_SCENE = preload("res://drone_frost.tscn")
const DRONE_SHOCK_SCENE = preload("res://drone_shock.tscn")

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

# Statistics panel
var statistics_panel: Panel = null
var statistics_button: Button = null

# Drone purchase UI (in perm panel)
var drone_purchase_containers: Dictionary = {}
var drone_purchase_buttons: Dictionary = {}
var drone_status_labels: Dictionary = {}

var drone_scenes = {
	"flame": DRONE_FLAME_SCENE,
	"poison": DRONE_POISON_SCENE,
	"frost": DRONE_FROST_SCENE,
	"shock": DRONE_SHOCK_SCENE,
}

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

	software_upgrade_button = Button.new()
	software_upgrade_button.text = "🔬 Labs"
	software_upgrade_button.position = Vector2(5, 800)
	software_upgrade_button.custom_minimum_size = Vector2(90, 35)
	software_upgrade_button.pressed.connect(_on_software_upgrade_button_pressed)
	add_child(software_upgrade_button)

	# Add Tier Selection panel and button
	tier_selection_panel = preload("res://tier_selection_ui.gd").new()
	tier_selection_panel.visible = false
	add_child(tier_selection_panel)

	tier_selection_button = Button.new()
	tier_selection_button.text = "🎖️ Tiers"
	tier_selection_button.position = Vector2(100, 800)
	tier_selection_button.custom_minimum_size = Vector2(90, 35)
	tier_selection_button.pressed.connect(_on_tier_selection_button_pressed)
	add_child(tier_selection_button)

	# Add Boss Rush panel and button
	boss_rush_panel = preload("res://boss_rush_ui.gd").new()
	boss_rush_panel.visible = false
	add_child(boss_rush_panel)

	boss_rush_button = Button.new()
	boss_rush_button.text = "🏆 Rush"
	boss_rush_button.position = Vector2(195, 800)
	boss_rush_button.custom_minimum_size = Vector2(90, 35)
	boss_rush_button.pressed.connect(_on_boss_rush_button_pressed)
	add_child(boss_rush_button)

	# Add Statistics button
	statistics_button = Button.new()
	statistics_button.text = "📊 Stats"
	statistics_button.position = Vector2(290, 800)
	statistics_button.custom_minimum_size = Vector2(95, 35)
	statistics_button.pressed.connect(_on_statistics_button_pressed)
	add_child(statistics_button)

	# Create statistics panel
	_create_statistics_panel()

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
	damage_upgrade.pressed.connect(_on_damage_upgrade_pressed)
	fire_rate_upgrade.pressed.connect(_on_fire_rate_upgrade_pressed)
	crit_upgrade_button.pressed.connect(_on_crit_chance_upgrade_pressed)
	crit_damage_upgrade.pressed.connect(_on_crit_damage_upgrade_pressed)
	defense_button.pressed.connect(_on_defense_button_pressed)
	shield_upgrade.pressed.connect(_on_shield_upgrade_pressed)
	reduction_upgrade.pressed.connect(_on_damage_reduction_upgrade_pressed)
	regen_upgrade.pressed.connect(_on_shield_regen_upgrade_pressed)
	economy_button.pressed.connect(_on_economy_button_pressed)
	data_credits_upgrade.pressed.connect(_on_data_credits_upgrade_pressed)
	archive_token_upgrade.pressed.connect(_on_archive_token_upgrade_pressed)
	free_upgrade_chance.pressed.connect(_on_free_upgrade_chance_pressed)
	wave_skip_chance.pressed.connect(_on_wave_skip_chance_pressed)
	speed_button.pressed.connect(_on_speed_button_pressed)
	buy_x_button.text = "Buy x" + str(buy_x_options[current_buy_index])
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

	# Auto-spawn owned drones (purchased out-of-run)
	_spawn_owned_drones()

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

	# Clean up drones
	for drone in active_drones:
		if is_instance_valid(drone):
			drone.queue_free()
	active_drones.clear()

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

func _on_damage_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_projectile_damage():
			print("Bought one (Max mode)")
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_projectile_damage():
				print("Stopped at %d upgrades" % i)
				break
			else:
				print("Bought upgrade %d" % (i+1))
	update_damage_label()
	if tower and is_instance_valid(tower):
		tower.update_visual_tier()  # Update tower visuals after damage upgrade


func _on_fire_rate_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_fire_rate():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_fire_rate():
				break
	if tower and is_instance_valid(tower):
		tower.refresh_fire_rate()
		tower.update_visual_tier()  # Update tower visuals after fire rate upgrade
	# Drones have independent fire rates based on their level, no need to refresh
	update_labels()

func _on_crit_chance_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_crit_chance():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_crit_chance():
				break
	update_crit_label()
	update_labels()

func _on_crit_damage_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_crit_damage():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_crit_damage():
				break
	update_labels()

func update_crit_label():
	var chance = UpgradeManager.get_crit_chance()
	print("Crit Chance: %d%%" % chance)
	
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


# --- Defense Panel Logic ---
func _on_defense_button_pressed():
	var new_state = not defense_panel.visible
	defense_panel.visible = new_state
	offense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false
	
func _on_shield_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_shield_integrity():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_shield_integrity():
				break
	tower.refresh_shield_stats()
	update_labels()

func _on_damage_reduction_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_damage_reduction():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_damage_reduction():
				break
	update_labels()

func _on_shield_regen_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_shield_regen():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_shield_regen():
				break
	tower.refresh_shield_stats()
	update_labels()

# --- Economy Panel Logic ---
func _on_economy_button_pressed():
	var new_state = not economy_panel.visible
	economy_panel.visible = new_state
	offense_panel.visible = false
	defense_panel.visible = false
	perm_panel.visible = false

func _on_data_credits_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_data_credit_multiplier():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_data_credit_multiplier():
				break
	update_labels()

func _on_archive_token_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_archive_token_multiplier():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_archive_token_multiplier():
				break
	update_labels()

func _on_free_upgrade_chance_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_free_upgrade_chance():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_free_upgrade_chance():
				break
	update_labels()

func _on_wave_skip_chance_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_wave_skip_chance():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_wave_skip_chance():
				break
	update_labels()

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

	# Refresh drones if drone upgrades were purchased
	if key in ["drone_flame", "drone_frost", "drone_poison", "drone_shock"]:
		refresh_all_drones()

	
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
		var arr = get_perm_max_affordable(key)
		var max_afford = arr[0]
		var max_cost = arr[1]
		label_text = "Upgrade x%s (%s AT)" % [str(max_afford), str(max_cost)]
		total_cost = max_cost
	else:
		total_cost = get_perm_total_upgrade_cost(key, buy_amount)
		label_text = "Upgrade x%s (%s AT)" % [str(buy_amount), str(total_cost)]

	perm_nodes[key]["level"].text = "Lvl %d" % level
	perm_nodes[key]["button"].text = label_text
	perm_nodes[key]["button"].disabled = at < (total_cost if total_cost > 0 else UpgradeManager.get_perm_upgrade_cost(key))


func update_all_perm_upgrade_ui():
	for key in perm_nodes.keys():
		update_perm_upgrade_ui(key)

func refresh_all_drones() -> void:
	# Update all active drones with current permanent upgrade levels
	for drone in active_drones:
		if not is_instance_valid(drone):
			continue

		# Determine drone type and apply permanent upgrade level
		if drone.has_method("apply_upgrade"):
			var drone_type = drone.drone_type if drone.get("drone_type") else ""
			match drone_type:
				"flame":
					drone.apply_upgrade(UpgradeManager.get_perm_drone_flame_level())
				"frost":
					drone.apply_upgrade(UpgradeManager.get_perm_drone_frost_level())
				"poison":
					drone.apply_upgrade(UpgradeManager.get_perm_drone_poison_level())
				"shock":
					drone.apply_upgrade(UpgradeManager.get_perm_drone_shock_level())
			# Fire rate automatically updates in apply_upgrade()

# === DRONE AUTO-SPAWN SYSTEM ===
# Drones are purchased out-of-run and auto-spawn if owned

func _spawn_owned_drones() -> void:
	var drone_types = ["flame", "frost", "poison", "shock"]
	var drone_scenes_map = {
		"flame": DRONE_FLAME_SCENE,
		"frost": DRONE_FROST_SCENE,
		"poison": DRONE_POISON_SCENE,
		"shock": DRONE_SHOCK_SCENE
	}

	var tower_pos = Vector2(193, 637)  # Tower position from tower.tscn
	var slot_index = 0

	for drone_type in drone_types:
		# Check if this drone is owned (purchased out-of-run)
		if not RewardManager.owns_drone(drone_type):
			continue

		# Spawn the drone
		var drone = drone_scenes_map[drone_type].instantiate()
		active_drones.append(drone)
		add_child(drone)

		# Apply permanent upgrade level
		match drone_type:
			"flame":
				drone.apply_upgrade(UpgradeManager.get_perm_drone_flame_level())
			"frost":
				drone.apply_upgrade(UpgradeManager.get_perm_drone_frost_level())
			"poison":
				drone.apply_upgrade(UpgradeManager.get_perm_drone_poison_level())
			"shock":
				drone.apply_upgrade(UpgradeManager.get_perm_drone_shock_level())

		# Position drone in horizontal line from tower
		var horizontal_offsets = [-80.0, -40.0, 40.0, 80.0]
		var horizontal_offset = horizontal_offsets[slot_index]
		drone.global_position = tower_pos + Vector2(horizontal_offset, 0)

		slot_index += 1
		print("✅ Auto-spawned", drone_type, "drone (owned)")

func get_current_buy_amount() -> int:
	var x = buy_x_options[current_buy_index]
	return -1 if x is String and x == "Max" else x
	
# Calculates the total cost to buy 'amount' upgrades of a perm stat
func get_perm_total_upgrade_cost(key: String, amount: int) -> int:
	var level = UpgradeManager.get_perm_level(key)
	var total_cost = 0
	for i in range(amount):
		var this_cost = UpgradeManager.get_perm_upgrade_cost_for_level(key, level + i)
		total_cost += this_cost
	return total_cost

# Returns [max_buyable, total_cost] for current tokens
func get_perm_max_affordable(key: String) -> Array:
	var at = RewardManager.archive_tokens
	var level = UpgradeManager.get_perm_level(key)
	var total_cost = 0
	var max_count = 0
	var safety_counter = 0
	const MAX_ITERATIONS = 10000  # Safety limit to prevent infinite loops

	while safety_counter < MAX_ITERATIONS:
		var this_cost = UpgradeManager.get_perm_upgrade_cost_for_level(key, level + max_count)

		# Guard against zero/negative costs which would cause infinite loop
		if this_cost <= 0:
			push_warning("get_perm_max_affordable: Invalid cost %d for level %d" % [this_cost, level + max_count])
			break

		if at >= total_cost + this_cost:
			total_cost += this_cost
			max_count += 1
		else:
			break

		safety_counter += 1

	if safety_counter >= MAX_ITERATIONS:
		push_error("get_perm_max_affordable: Hit safety limit! Possible infinite loop prevented.")

	return [max_count, total_cost]

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
			# Hide other panels
			offense_panel.visible = false
			defense_panel.visible = false
			economy_panel.visible = false
			perm_panel.visible = false
			if tier_selection_panel:
				tier_selection_panel.visible = false

func _on_tier_selection_button_pressed():
	if tier_selection_panel:
		tier_selection_panel.visible = not tier_selection_panel.visible
		if tier_selection_panel.visible:
			# Hide other panels
			offense_panel.visible = false
			defense_panel.visible = false
			economy_panel.visible = false
			perm_panel.visible = false
			if software_upgrade_panel:
				software_upgrade_panel.visible = false
			if boss_rush_panel:
				boss_rush_panel.visible = false

func _on_boss_rush_button_pressed():
	if boss_rush_panel:
		boss_rush_panel.visible = not boss_rush_panel.visible
		if boss_rush_panel.visible:
			# Hide other panels
			offense_panel.visible = false
			defense_panel.visible = false
			economy_panel.visible = false
			perm_panel.visible = false
			if software_upgrade_panel:
				software_upgrade_panel.visible = false
			if tier_selection_panel:
				tier_selection_panel.visible = false

func reset_to_wave_1():
	# Called when entering a new tier - resets to wave 1 but keeps permanent upgrades
	print("🔄 Resetting to Wave 1 for new tier...")

	# 1. Reset in-run upgrades
	if Engine.has_singleton("UpgradeManager"):
		UpgradeManager.reset_run_upgrades()

	# 2. Reset run currency (keep AT/Fragments, reset DC)
	if Engine.has_singleton("RewardManager"):
		RewardManager.reset_run_currency()

	# 3. Reset wave and clear enemies
	if spawner.has_method("reset_wave_timers"):
		spawner.reset_wave_timers()
	spawner.wave_spawning = false
	spawner.current_wave = 1
	spawner.enemies_to_spawn = 0
	spawner.spawned_enemies = 0

	# Remove any enemy nodes
	for e in spawner.get_children():
		if is_instance_valid(e) and e.is_in_group("enemies"):
			e.queue_free()

	# 4. Reset the tower
	tower.tower_hp = 1000
	tower.refresh_shield_stats()
	tower.current_shield = tower.max_shield
	tower.update_bars()

	# 5. Hide all upgrade panels
	offense_panel.visible = false
	defense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false
	if software_upgrade_panel:
		software_upgrade_panel.visible = false
	if tier_selection_panel:
		tier_selection_panel.visible = false

	# 6. Start wave 1
	wave_timer = 0.0
	spawner.start_wave(1)
	update_labels()

	# 7. Start tracking this run's performance
	RewardManager.start_run_tracking(1)

	print("✅ Reset complete! Starting Wave 1 in Tier %d" % TierManager.get_current_tier())

func start_boss_rush():
	# Called when boss rush starts from UI
	print("🏆 Starting Boss Rush mode...")

	if not BossRushManager.start_boss_rush():
		print("⚠️ Failed to start boss rush!")
		return

	# Reset game state (similar to tier reset but for boss rush)
	# 1. Reset in-run upgrades
	if Engine.has_singleton("UpgradeManager"):
		UpgradeManager.reset_run_upgrades()

	# 2. Reset run currency
	if Engine.has_singleton("RewardManager"):
		RewardManager.reset_run_currency()

	# 3. Reset wave and clear enemies
	if spawner.has_method("reset_wave_timers"):
		spawner.reset_wave_timers()
	spawner.wave_spawning = false
	spawner.current_wave = 1
	spawner.enemies_to_spawn = 0
	spawner.spawned_enemies = 0

	# Remove any enemy nodes
	for e in spawner.get_children():
		if is_instance_valid(e) and e.is_in_group("enemies"):
			e.queue_free()

	# 4. Reset the tower
	tower.tower_hp = 1000
	tower.refresh_shield_stats()
	tower.current_shield = tower.max_shield
	tower.update_bars()

	# 5. Hide all panels
	offense_panel.visible = false
	defense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false
	if software_upgrade_panel:
		software_upgrade_panel.visible = false
	if tier_selection_panel:
		tier_selection_panel.visible = false
	if boss_rush_panel:
		boss_rush_panel.visible = false

	# 6. Reset RunStats for damage tracking
	RunStats.reset()

	# 7. Start wave 1
	wave_timer = 0.0
	spawner.start_wave(1)
	update_labels()

	print("✅ Boss Rush started! Good luck!")

func exit_boss_rush():
	# Called when exiting boss rush (player quits or dies)
	print("🏆 Exiting Boss Rush mode...")

	# End boss rush in spawner (this will trigger leaderboard entry)
	if spawner and spawner.has_method("end_boss_rush"):
		spawner.end_boss_rush()

	# Return to start screen
	_on_quit_button_pressed()

func _on_quit_button_pressed():
	# Record run performance before quitting
	if Engine.has_singleton("RewardManager") and spawner:
		RewardManager.record_run_performance(spawner.current_wave)

	# 1. Reset in-run upgrades
	if Engine.has_singleton("UpgradeManager"):
		UpgradeManager.reset_run_upgrades()
		UpgradeManager.maybe_grant_free_upgrade() # Optional

	# 2. Save permanent upgrades and reset currencies
	if Engine.has_singleton("RewardManager"):
		RewardManager.save_permanent_upgrades()
		RewardManager.reset_run_currency()

	# 3. Reset wave and clear enemies
	if spawner.has_method("reset_wave_timers"):
		spawner.reset_wave_timers()
	spawner.wave_spawning = false
	spawner.current_wave = 1
	spawner.enemies_to_spawn = 0
	spawner.spawned_enemies = 0
	# Remove any enemy nodes
	for e in spawner.get_children():
		if is_instance_valid(e) and e.is_in_group("enemies"):
			e.queue_free()

	# 4. Reset the tower
	tower.tower_hp = 1000
	tower.refresh_shield_stats()
	tower.current_shield = tower.max_shield
	tower.update_bars()

	# 5. Hide all upgrade panels
	if has_node("OffensePanel"):
		$OffensePanel.visible = false
	if has_node("DefensePanel"):
		$DefensePanel.visible = false
	if has_node("EconomyPanel"):
		$EconomyPanel.visible = false
	if has_node("PermUpgradesPanel"):
		$PermUpgradesPanel.visible = false

	# 6. Return to the Start Screen
	get_tree().change_scene_to_file("res://StartScreen.tscn")

	print("=== RUN STATS ON DEATH ===")
	print("AT Earned: ", RunStats.archive_tokens_earned)
	print("DC Earned: ", RunStats.data_credits_earned)
	print("Damage Dealt: ", RunStats.damage_dealt)
	print("Damage Taken: ", RunStats.damage_taken)
	print("==========================")	
	RunStats.reset()

# === STATISTICS PANEL ===

func _create_statistics_panel() -> void:
	# Create panel
	statistics_panel = Panel.new()
	statistics_panel.custom_minimum_size = Vector2(600, 700)
	statistics_panel.position = Vector2(300, 100)
	statistics_panel.visible = false
	add_child(statistics_panel)

	# Create scroll container
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 680)
	scroll.position = Vector2(10, 10)
	statistics_panel.add_child(scroll)

	# Create VBox for content
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "=== LIFETIME STATISTICS ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(550, 30)
	vbox.add_child(title)
	UIStyler.apply_theme_to_node(title)

	# Separator
	var sep_account = HSeparator.new()
	vbox.add_child(sep_account)

	# Account Section
	var account_title = Label.new()
	account_title.text = "🔐 Account"
	account_title.custom_minimum_size = Vector2(550, 25)
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
	account_status.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(account_status)
	UIStyler.apply_theme_to_node(account_status)

	# Bind account button (only for guests)
	if CloudSaveManager and CloudSaveManager.is_logged_in and CloudSaveManager.is_guest:
		var bind_button = Button.new()
		bind_button.text = "🔗 Bind Email to Save Progress"
		bind_button.custom_minimum_size = Vector2(300, 40)
		bind_button.pressed.connect(_on_bind_account_pressed)
		vbox.add_child(bind_button)
		UIStyler.apply_theme_to_node(bind_button)

	# Separator
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)

	# Currency Stats
	var currency_title = Label.new()
	currency_title.text = "💰 Currency Earned"
	currency_title.custom_minimum_size = Vector2(550, 25)
	vbox.add_child(currency_title)
	UIStyler.apply_theme_to_node(currency_title)

	var dc_stat = Label.new()
	dc_stat.name = "DCStatLabel"
	dc_stat.text = "Data Credits: 0"
	dc_stat.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(dc_stat)
	UIStyler.apply_theme_to_node(dc_stat)

	var at_stat = Label.new()
	at_stat.name = "ATStatLabel"
	at_stat.text = "Archive Tokens: 0"
	at_stat.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(at_stat)
	UIStyler.apply_theme_to_node(at_stat)

	var frag_stat = Label.new()
	frag_stat.name = "FragStatLabel"
	frag_stat.text = "Fragments: 0"
	frag_stat.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(frag_stat)
	UIStyler.apply_theme_to_node(frag_stat)

	# Separator
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Spending Stats
	var spending_title = Label.new()
	spending_title.text = "💸 Archive Tokens Spent"
	spending_title.custom_minimum_size = Vector2(550, 25)
	vbox.add_child(spending_title)
	UIStyler.apply_theme_to_node(spending_title)

	var lab_spent = Label.new()
	lab_spent.name = "LabSpentLabel"
	lab_spent.text = "On Labs: 0"
	lab_spent.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(lab_spent)
	UIStyler.apply_theme_to_node(lab_spent)

	var perm_spent = Label.new()
	perm_spent.name = "PermSpentLabel"
	perm_spent.text = "On Permanent Upgrades: 0"
	perm_spent.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(perm_spent)
	UIStyler.apply_theme_to_node(perm_spent)

	var total_spent = Label.new()
	total_spent.name = "TotalSpentLabel"
	total_spent.text = "Total Spent: 0"
	total_spent.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(total_spent)
	UIStyler.apply_theme_to_node(total_spent)

	# Separator
	var sep3 = HSeparator.new()
	vbox.add_child(sep3)

	# Kill Stats
	var kills_title = Label.new()
	kills_title.text = "⚔️ Enemies Defeated"
	kills_title.custom_minimum_size = Vector2(550, 25)
	vbox.add_child(kills_title)
	UIStyler.apply_theme_to_node(kills_title)

	var breacher_kills = Label.new()
	breacher_kills.name = "BreacherKillsLabel"
	breacher_kills.text = "Breachers: 0"
	breacher_kills.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(breacher_kills)
	UIStyler.apply_theme_to_node(breacher_kills)

	var slicer_kills = Label.new()
	slicer_kills.name = "SlicerKillsLabel"
	slicer_kills.text = "Slicers: 0"
	slicer_kills.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(slicer_kills)
	UIStyler.apply_theme_to_node(slicer_kills)

	var sentinel_kills = Label.new()
	sentinel_kills.name = "SentinelKillsLabel"
	sentinel_kills.text = "Sentinels: 0"
	sentinel_kills.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(sentinel_kills)
	UIStyler.apply_theme_to_node(sentinel_kills)

	var signal_kills = Label.new()
	signal_kills.name = "SignalKillsLabel"
	signal_kills.text = "Signal Runners: 0"
	signal_kills.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(signal_kills)
	UIStyler.apply_theme_to_node(signal_kills)

	var null_kills = Label.new()
	null_kills.name = "NullKillsLabel"
	null_kills.text = "Null Walkers: 0"
	null_kills.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(null_kills)
	UIStyler.apply_theme_to_node(null_kills)

	var boss_kills = Label.new()
	boss_kills.name = "BossKillsLabel"
	boss_kills.text = "Bosses (Override): 0"
	boss_kills.custom_minimum_size = Vector2(550, 20)
	vbox.add_child(boss_kills)
	UIStyler.apply_theme_to_node(boss_kills)

	var total_kills = Label.new()
	total_kills.name = "TotalKillsLabel"
	total_kills.text = "Total Kills: 0"
	total_kills.custom_minimum_size = Vector2(550, 25)
	vbox.add_child(total_kills)
	UIStyler.apply_theme_to_node(total_kills)

	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(200, 40)
	close_button.position = Vector2(200, 640)
	close_button.pressed.connect(_on_statistics_panel_close)
	statistics_panel.add_child(close_button)
	UIStyler.apply_theme_to_node(close_button)

func _on_statistics_button_pressed() -> void:
	if not statistics_panel:
		return

	statistics_panel.visible = not statistics_panel.visible

	if statistics_panel.visible:
		_update_statistics_panel()
		# Hide other panels
		if software_upgrade_panel:
			software_upgrade_panel.visible = false
		perm_panel.visible = false

func _on_bind_account_pressed() -> void:
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
			_create_statistics_panel()
			statistics_panel.visible = true
			_update_statistics_panel()
	)

func _on_statistics_panel_close() -> void:
	if statistics_panel:
		statistics_panel.visible = false

func _update_statistics_panel() -> void:
	if not statistics_panel:
		return

	# Update currency stats
	var dc_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/DCStatLabel")
	if dc_label:
		dc_label.text = "Data Credits: %s" % _format_number(RunStats.lifetime_dc_earned)

	var at_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/ATStatLabel")
	if at_label:
		at_label.text = "Archive Tokens: %s" % _format_number(RunStats.lifetime_at_earned)

	var frag_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/FragStatLabel")
	if frag_label:
		frag_label.text = "Fragments: %s" % _format_number(RunStats.lifetime_fragments_earned)

	# Update spending stats
	var lab_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/LabSpentLabel")
	if lab_label:
		lab_label.text = "On Labs: %s" % _format_number(RunStats.lifetime_at_spent_labs)

	var perm_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/PermSpentLabel")
	if perm_label:
		perm_label.text = "On Permanent Upgrades: %s" % _format_number(RunStats.lifetime_at_spent_perm_upgrades)

	var total_spent_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/TotalSpentLabel")
	if total_spent_label:
		var total = RunStats.lifetime_at_spent_labs + RunStats.lifetime_at_spent_perm_upgrades
		total_spent_label.text = "Total Spent: %s" % _format_number(total)

	# Update kill stats
	var breacher_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/BreacherKillsLabel")
	if breacher_label:
		breacher_label.text = "Breachers: %s" % _format_number(RunStats.lifetime_kills.get("breacher", 0))

	var slicer_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/SlicerKillsLabel")
	if slicer_label:
		slicer_label.text = "Slicers: %s" % _format_number(RunStats.lifetime_kills.get("slicer", 0))

	var sentinel_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/SentinelKillsLabel")
	if sentinel_label:
		sentinel_label.text = "Sentinels: %s" % _format_number(RunStats.lifetime_kills.get("sentinel", 0))

	var signal_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/SignalKillsLabel")
	if signal_label:
		signal_label.text = "Signal Runners: %s" % _format_number(RunStats.lifetime_kills.get("signal_runner", 0))

	var null_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/NullKillsLabel")
	if null_label:
		null_label.text = "Null Walkers: %s" % _format_number(RunStats.lifetime_kills.get("nullwalker", 0))

	var boss_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/BossKillsLabel")
	if boss_label:
		boss_label.text = "Bosses (Override): %s" % _format_number(RunStats.lifetime_kills.get("override", 0))

	var total_kills_label = statistics_panel.get_node_or_null("ScrollContainer/VBoxContainer/TotalKillsLabel")
	if total_kills_label:
		var total_kills = 0
		for kills in RunStats.lifetime_kills.values():
			total_kills += kills
		total_kills_label.text = "Total Kills: %s" % _format_number(total_kills)

func _format_number(num: int) -> String:
	if num < 1000:
		return str(num)
	elif num < 1000000:
		return "%.1fK" % (num / 1000.0)
	elif num < 1000000000:
		return "%.1fM" % (num / 1000000.0)
	else:
		return "%.1fB" % (num / 1000000000.0)
