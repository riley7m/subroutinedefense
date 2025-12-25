extends Control

# Wave and Tower Status
var wave: int = 1
var current_wave: int = 1
var wave_number: int = 1
var tower_hp: int = 1000
var wave_timer: float = 0.0
const WAVE_INTERVAL := 2.0

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

# Upgrade UI – Damage label
@onready var damage_label: Label = $UpgradesBox/DamageUpgradeLabel

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

@onready var death_screen = get_tree().current_scene.get_node("DeathScreen")
@onready var spawner: Node = $Spawner
@onready var tower: Node = $tower



func _ready() -> void:
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
	
	for drone_type in drone_scenes.keys():
		var drone = drone_scenes[drone_type].instantiate()
		
		add_child(drone)
		
	# Spawner hookup
	spawner.set_main_hud(self)
	spawner.start_wave(wave)
	spawner.set_main_hud(self)
	randomize()
	RewardManager.load_permanent_upgrades()
	update_all_perm_upgrade_ui()
	# Refresh currency labels every 0.2s
	var refresh_timer := Timer.new()
	refresh_timer.wait_time = 0.2
	refresh_timer.timeout.connect(update_labels)
	refresh_timer.autostart = true
	add_child(refresh_timer)
	RewardManager.archive_tokens_changed.connect(update_all_perm_upgrade_ui)
	update_labels()
	update_damage_label()

	# Apply cyber theme to all UI elements
	UIStyler.apply_theme_to_node(self)

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

func update_damage_label() -> void:
	var dmg = UpgradeManager.get_projectile_damage()
	print("Projectile Damage: %d" % dmg)

func take_damage(amount: int) -> void:
	tower_hp -= amount
	#print("💥 Tower hit! Remaining HP:", tower_hp)
	if tower_hp <= 0:
		print("☠️ Tower destroyed!")
		# TODO: Add game-over logic

# --- Offense Panel Logic ---
func _on_offense_button_pressed() -> void:
	var new_state = not offense_panel.visible
	offense_panel.visible = new_state
	defense_panel.visible = false
	economy_panel.visible = false
	perm_panel.visible = false

func _on_damage_upgrade_pressed() -> void:
	print("DEBUG: DC before:", RewardManager.data_credits)
	var amount = get_current_buy_amount()
	print("DEBUG: Buy amount is", amount)
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


func _on_fire_rate_upgrade_pressed() -> void:
	var amount = get_current_buy_amount()
	if amount == -1:
		while UpgradeManager.upgrade_fire_rate():
			pass
	else:
		for i in range(amount):
			if not UpgradeManager.upgrade_fire_rate():
				break
	tower.refresh_fire_rate()
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
		var next_cost = UpgradeManager.get_multi_target_cost_for_level(lvl + 1) if lvl < UpgradeManager.MULTI_TARGET_MAX_LEVEL else "-"
		upgrade_multi_target_button.text = "Upgrade Multi Target (%s DC)" % str(next_cost)
		upgrade_multi_target_button.disabled = (lvl >= UpgradeManager.MULTI_TARGET_MAX_LEVEL or RewardManager.data_credits < int(next_cost))
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

	
func _on_buy_x_button_pressed():
	current_buy_index = (current_buy_index + 1) % buy_x_options.size()
	buy_x_button.text = "Buy x" + str(buy_x_options[current_buy_index])
	print("DEBUG: New buy index is", current_buy_index, "Amount is", buy_x_options[current_buy_index])



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
	while true:
		var this_cost = UpgradeManager.get_perm_upgrade_cost_for_level(key, level + max_count)
		if at >= total_cost + this_cost:
			total_cost += this_cost
			max_count += 1
		else:
			break
	return [max_count, total_cost]
	
func _on_perm_panel_toggle_button_pressed():
	perm_panel.visible = not perm_panel.visible
	if perm_panel.visible:
		perm_panel_toggle_button.text = "Hide Upgrades"
		# Hide all other panels when perm panel is shown
		offense_panel.visible = false
		defense_panel.visible = false
		economy_panel.visible = false
	else:
		perm_panel_toggle_button.text = "Show Upgrades"
		
func _on_quit_button_pressed():
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
