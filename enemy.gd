extends CharacterBody2D

# Wave Scaling Constants
const HP_SCALING_BASE: float = 1.02  # Exponential HP scaling (2% per wave)
const DAMAGE_PER_WAVE: float = 0.4
const SPEED_PER_WAVE: float = 0.25

# Burn Effect Constants
const BURN_MIN_PERCENT: float = 0.15
const BURN_MAX_PERCENT: float = 1.5
const BURN_HP_CAP_PERCENT: float = 0.10
const BURN_BASE_DURATION: float = 3.0
const BURN_DURATION_PER_LEVEL: float = 0.5

# Poison Effect Constants (NERFED for balance)
const POISON_MIN_PERCENT: float = 0.01
const POISON_MAX_PERCENT: float = 0.075  # 7.5% at level 10 (down from 10%)
const POISON_PERCENT_PER_LEVEL: float = 0.00722  # (0.075 - 0.01) / 9
const POISON_DURATION: float = 4.0  # Base duration (upgradeable to 6s)

# Slow Effect Constants (NERFED for balance)
const SLOW_MIN_PERCENT: float = 0.3
const SLOW_MAX_PERCENT: float = 0.75  # 75% at level 10 (down from 80%)
const SLOW_PERCENT_PER_LEVEL: float = 0.05
const SLOW_BASE_DURATION: float = 2.0
const SLOW_DURATION_PER_LEVEL: float = 0.1

# Stun Effect Constants
const STUN_BASE_DURATION: float = 0.5
const STUN_DURATION_PER_LEVEL: float = 0.25
const STUN_MAX_DURATION: float = 2.0

@export var base_hp: int = 10
@export var base_damage: int = 1
@export var base_speed: float = 100.0
var wave_number: int = 1
@export var attack_speed: float = 1
var hp: BigNumber = null  # Changed to BigNumber for infinite scaling
var damage_to_tower: int
var move_speed: float
@export var tower_position: Vector2 = Vector2.ZERO
@export var enemy_type: String = "breacher"  # Or slicer/sentinel/etc



var time_since_last_attack := 0.0
var is_dead: bool = false
var in_range: bool = false
var tower: Node = null

# Pooling support
var is_pooled: bool = false

# --- Burn Effect ---
var burn_active: bool = false
var burn_timer: float = 0.0
var burn_duration: float = 0.0
var burn_damage_per_tick: float = 0.0  # Display value
var burn_damage_bn: BigNumber = null  # BigNumber for efficient damage application
var burn_tick_interval: float = 1.0   # 1 second per tick
var burn_tick_timer: float = 0.0

# --- Poison Effect ---
var poison_active: bool = false
var poison_timer: float = 0.0
var poison_duration: float = 0.0
var poison_damage_per_tick: float = 0.0  # Display value
var poison_damage_bn: BigNumber = null  # BigNumber for efficient damage application
var poison_tick_interval: float = 1.0
var poison_tick_timer: float = 0.0

# --- Slow Effect ---
var slow_active: bool = false
var slow_percent: float = 0.0
var slow_timer: float = 0.0
var slow_duration: float = 0.0

# --- Stun Effect ---
var stun_active: bool = false
var stun_timer: float = 0.0
var stun_duration: float = 0.0

# Trail system
var trail: Line2D
const MAX_TRAIL_POINTS: int = 20
const TRAIL_SPACING: float = 8.0
var last_trail_pos: Vector2

# Cached zero BigNumber for efficient death checks (avoids allocation every frame)
static var _zero_bn: BigNumber = null


func _ready() -> void:
	# Initialize shared zero BigNumber (once for all enemies)
	if _zero_bn == null:
		_zero_bn = BigNumber.new(0)
	add_to_group("enemies")

	# Register with EnemyTracker for efficient targeting
	EnemyTracker.register_enemy(self)

	# Initialize stats (will be overwritten by apply_wave_scaling, but safe defaults)
	hp = BigNumber.new(base_hp)
	damage_to_tower = base_damage
	move_speed = base_speed

	# Verify AttackZone exists before connecting signals
	if not has_node("AttackZone"):
		push_error("Enemy missing AttackZone node!")
		return

	var attack_zone = $AttackZone
	if not attack_zone.body_entered.is_connected(Callable(self, "_on_attack_zone_body_entered")):
		var err = attack_zone.body_entered.connect(Callable(self, "_on_attack_zone_body_entered"))
		if err != OK:
			push_error("Failed to connect AttackZone.body_entered signal: " + str(err))

	if not attack_zone.body_exited.is_connected(Callable(self, "_on_attack_zone_body_exited")):
		var err = attack_zone.body_exited.connect(Callable(self, "_on_attack_zone_body_exited"))
		if err != OK:
			push_error("Failed to connect AttackZone.body_exited signal: " + str(err))

	attack_zone.monitoring = true
	attack_zone.monitorable = true

	# Create visual representation
	var visual_container = VisualFactory.create_enemy_visual(enemy_type, self)

	# Add spawn animation
	VisualFactory.add_spawn_animation(self, 0.4)

	# Add idle animations based on enemy type
	if visual_container:
		match enemy_type:
			"override":  # Boss - slow rotation
				VisualFactory.add_rotation_animation(visual_container, 0.3)
			"sentinel":  # Tank - gentle pulse
				VisualFactory.add_pulse_animation(visual_container, 0.95, 1.05, 1.5)
			"slicer":  # Fast - quick rotation
				VisualFactory.add_rotation_animation(visual_container, 2.0)
			"signal_runner":  # Medium - moderate pulse
				VisualFactory.add_pulse_animation(visual_container, 0.9, 1.1, 1.0)
			"null_walker":  # Special - rotation + pulse combo
				VisualFactory.add_rotation_animation(visual_container, 0.5)
			_:  # Breacher - subtle pulse
				VisualFactory.add_pulse_animation(visual_container, 0.95, 1.05, 0.8)

	# Create trail effect using AdvancedVisuals (color matches enemy type)
	var trail_color: Color
	match enemy_type:
		"override":  # Boss
			trail_color = Color(1.0, 0.0, 1.0)  # Magenta
		"sentinel":
			trail_color = Color(1.0, 0.5, 0.0)  # Orange
		"slicer":
			trail_color = Color(1.0, 0.3, 0.3)  # Red-orange
		_:  # Breacher
			trail_color = Color(1.0, 0.2, 0.2)  # Red

	var parent = get_parent()
	if parent and is_instance_valid(parent):
		trail = TrailPool.get_trail(parent, trail_color, 4.0)
		last_trail_pos = global_position
	else:
		trail = null

	#print("✅ AttackZone signals connected")
	#print("New enemy spawned:", self.name)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if stun_active:
		stun_timer += delta
		if stun_timer >= stun_duration:
			stun_active = false
			stun_timer = 0.0
			# Remove visual effects
			VisualFactory.remove_status_effect_overlay("stun", self)
			AdvancedVisuals.remove_status_icon("stun", self)
			#print(name, "stun ended")
		return
	# Move toward tower
	var direction = (tower_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Update trail using TrailPool
	if trail and is_instance_valid(trail):
		if global_position.distance_to(last_trail_pos) > TRAIL_SPACING:
			TrailPool.update_trail(trail, global_position, MAX_TRAIL_POINTS)
			last_trail_pos = global_position

	time_since_last_attack += delta
	if in_range and time_since_last_attack >= attack_speed:
		#print("💢 Attempting to deal damage")
		time_since_last_attack = 0.0

		if tower and tower.has_method("take_damage"):
			# Pass enemy reference for boss resistance check
			var method_info = tower.get_method_list()
			var supports_enemy_ref = false
			for method in method_info:
				if method.name == "take_damage":
					supports_enemy_ref = method.args.size() >= 2
					break

			if supports_enemy_ref:
				tower.take_damage(damage_to_tower, self)
			else:
				tower.take_damage(damage_to_tower)
			#print("🔥 Called take_damage on tower!")
		else:
			print("❌ tower.take_damage() failed — tower is:", tower)

	# --- Burn effect tick ---
	if burn_active:
		burn_timer += delta
		burn_tick_timer += delta
		if burn_tick_timer >= burn_tick_interval:
			# Reuse cached BigNumber instead of creating new one every tick
			hp.subtract(burn_damage_bn)
			burn_tick_timer -= burn_tick_interval
			#print("🔥", name, "takes", burn_damage_per_tick, "burn tick! HP now", hp.format())
		if burn_timer >= burn_duration:
			burn_active = false
			burn_timer = 0.0
			burn_tick_timer = 0.0
			burn_duration = 0.0
			burn_damage_per_tick = 0.0
			burn_damage_bn = null  # Clear cached BigNumber
			# Remove visual effects
			VisualFactory.remove_status_effect_overlay("burn", self)
			AdvancedVisuals.remove_status_icon("burn", self)
			#print("🔥", name, "burn ended")
		if hp.less_equal(_zero_bn) and not is_dead:
			is_dead = true
			die()

		# --- Poison effect tick ---
	if poison_active:
		poison_timer += delta
		poison_tick_timer += delta
		if poison_tick_timer >= poison_tick_interval:
			# Reuse cached BigNumber instead of creating new one every tick
			hp.subtract(poison_damage_bn)
			poison_tick_timer -= poison_tick_interval
			#print("🟣", name, "takes", poison_damage_per_tick, "poison tick! HP now", hp.format())
		if poison_timer >= poison_duration:
			poison_active = false
			poison_timer = 0.0
			poison_tick_timer = 0.0
			poison_duration = 0.0
			poison_damage_per_tick = 0.0
			poison_damage_bn = null  # Clear cached BigNumber
			# Remove visual effects
			VisualFactory.remove_status_effect_overlay("poison", self)
			AdvancedVisuals.remove_status_icon("poison", self)
			#print("🟣", name, "poison ended")
		if hp.less_equal(_zero_bn) and not is_dead:
			is_dead = true
			die()
	# --- Apply slow effect ---
	if slow_active:
		slow_timer += delta
		if slow_timer >= slow_duration:
			slow_active = false
			slow_timer = 0.0
			slow_percent = 0.0
			# Remove visual effects
			VisualFactory.remove_status_effect_overlay("slow", self)
			AdvancedVisuals.remove_status_icon("slow", self)
			#print("🟦", name, "slow effect ended.")
		else:
			# Apply slow to current movement
			var slow_multiplier = (1.0 - slow_percent)
			velocity *= slow_multiplier

	# --- Final death check (in case status effects reduced hp to 0) ---
	if hp.less_equal(_zero_bn) and not is_dead:
		is_dead = true
		die()



func _on_attack_zone_body_entered(body: Node) -> void:
	#print("📍 AttackZone detected body:", body.name)
	#print("Body groups for", body.name, ":", body.get_groups())	
	if body.is_in_group("Tower"):
		#print("🔵 Enemy entered attack zone of tower:", self.name)
		in_range = true

func _on_attack_zone_body_exited(body: Node) -> void:
	if body == tower:
		#print("⚪ Enemy exited attack zone:", self.name)
		in_range = false

func take_damage(amount: int, is_critical: bool = false) -> void:
	#print("🟥 Enemy takes damage")
	if is_dead:
		return

	# Hit flash effect
	_trigger_hit_flash(is_critical)

	# Spawn floating damage number using AdvancedVisuals
	var parent = get_parent()
	if parent and is_instance_valid(parent):
		AdvancedVisuals.create_damage_number(amount, global_position, is_critical, parent)

	# Apply damage using BigNumber
	hp.subtract(BigNumber.new(amount))
	if hp.less_equal(_zero_bn):
		is_dead = true
		die()

func _trigger_hit_flash(is_critical: bool = false) -> void:
	# Find visual container for flash effect
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		return

	# Flash white for hit feedback
	var flash_color = Color(3.0, 3.0, 3.0, 1.0) if is_critical else Color(2.0, 2.0, 2.0, 1.0)
	var flash_duration = 0.15 if is_critical else 0.08

	visual_container.modulate = flash_color

	# Animate back to normal
	var tween = create_tween()
	tween.tween_property(visual_container, "modulate", Color(1.0, 1.0, 1.0, 1.0), flash_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		

func die():
	is_dead = true

	# Recycle trail back to pool
	if trail and is_instance_valid(trail):
		TrailPool.recycle_trail(trail)
		trail = null

	# Disconnect attack zone signals to prevent leaks
	if has_node("AttackZone"):
		var attack_zone = $AttackZone
		if attack_zone.body_entered.is_connected(Callable(self, "_on_attack_zone_body_entered")):
			attack_zone.body_entered.disconnect(Callable(self, "_on_attack_zone_body_entered"))
		if attack_zone.body_exited.is_connected(Callable(self, "_on_attack_zone_body_exited")):
			attack_zone.body_exited.disconnect(Callable(self, "_on_attack_zone_body_exited"))

	# Remove all status effect overlays and their tweens
	VisualFactory.remove_status_effect_overlay("burn", self)
	VisualFactory.remove_status_effect_overlay("poison", self)
	VisualFactory.remove_status_effect_overlay("slow", self)
	VisualFactory.remove_status_effect_overlay("stun", self)

	# Existing death logic (play animation, remove from scene, etc.)
	RewardManager.reward_enemy(enemy_type, wave_number)
	RewardManager.reward_enemy_at(enemy_type, wave_number)
	RunStats.record_kill(enemy_type)  # Track lifetime kills

	# Grant fragments for boss kills
	if enemy_type == "override":
		var base_fragments = 10 + int(wave_number / 10)  # Scales with wave
		var tier_mult = TierManager.get_reward_multiplier() if TierManager else 1.0
		var fragment_reward = int(base_fragments * tier_mult)  # Apply tier multiplier like DC/AT
		RewardManager.add_fragments(fragment_reward)
		print("💎 Boss killed! Fragments earned:", fragment_reward)

		# Show fragment notification at boss position
		ScreenEffects.fragment_notification(fragment_reward, global_position)

		# Boss mega explosion
		ParticleEffects.create_boss_explosion(global_position, get_parent())
	else:
		# Normal enemy explosion
		ParticleEffects.create_enemy_explosion(global_position, enemy_type, get_parent())

	# Death dissolve effect
	_trigger_death_dissolve()

func _trigger_death_dissolve() -> void:
	# Find visual container
	var visual_container = get_node_or_null("VisualContainer")
	if not visual_container:
		_cleanup_and_recycle()
		return

	# Dissolve animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out and scale down
	tween.tween_property(visual_container, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(visual_container, "scale", Vector2(1.3, 1.3), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	# Spawn dissolve particles
	_spawn_dissolve_particles()

	# Cleanup after animation
	tween.tween_callback(func():
		if is_instance_valid(self):
			_cleanup_and_recycle()
	).set_delay(0.4)

func _spawn_dissolve_particles() -> void:
	# Null safety check for parent
	var parent = get_parent()
	if not parent or not is_instance_valid(parent):
		return

	# Create small particle burst for dissolve effect
	for i in range(8):
		var particle_rect = ColorRect.new()
		particle_rect.size = Vector2(4, 4)
		particle_rect.position = global_position
		particle_rect.z_index = 50

		# Color based on enemy type
		match enemy_type:
			"override":
				particle_rect.color = Color(1.0, 0.0, 1.0, 1.0)
			"sentinel":
				particle_rect.color = Color(1.0, 0.5, 0.0, 1.0)
			_:
				particle_rect.color = Color(1.0, 0.2, 0.2, 1.0)

		parent.add_child(particle_rect)

		# Random direction
		var angle = (i / 8.0) * TAU
		var velocity = Vector2(cos(angle), sin(angle)) * randf_range(30, 60)

		# Animate particle
		var tween = particle_rect.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle_rect, "position", particle_rect.position + velocity, 0.5)
		tween.tween_property(particle_rect, "modulate:a", 0.0, 0.5)
		tween.tween_property(particle_rect, "scale", Vector2(0.1, 0.1), 0.5)
		tween.tween_callback(func():
			if is_instance_valid(particle_rect):
				particle_rect.queue_free()
		)
	
func apply_wave_scaling():
	# Get tier multiplier
	var tier_mult = TierManager.get_enemy_multiplier()

	# Use BigNumber for intermediate calculations to prevent float precision loss
	var wave_mult = pow(HP_SCALING_BASE, wave_number)

	# Calculate HP using BigNumber to maintain precision
	var hp_bn = BigNumber.new(base_hp)
	hp_bn.multiply(tier_mult)
	hp_bn.multiply(wave_mult)
	hp = hp_bn  # No caps - infinite scaling with BigNumber

	# Damage and speed use regular float (don't need extreme precision)
	damage_to_tower = int((base_damage * tier_mult) + (wave_number * DAMAGE_PER_WAVE))
	move_speed = ((base_speed * tier_mult) + (wave_number * SPEED_PER_WAVE)) / 2
	#print("wave number:", wave_number)
	#print("enemy hp:", hp.format(), "tier mult:", tier_mult)

func apply_boss_rush_scaling():
	# Boss rush uses faster scaling than normal tiers
	var boss_rush_mult = BossRushManager.get_boss_rush_hp_multiplier(wave_number)

	# Apply exponential HP scaling (5% per wave vs 2% normal) using BigNumber
	var calculated_hp = base_hp * boss_rush_mult
	hp = BigNumber.new(calculated_hp)
	damage_to_tower = int(base_damage * BossRushManager.get_boss_rush_damage_multiplier())
	move_speed = base_speed * BossRushManager.get_boss_rush_speed_multiplier()

	#print("Boss rush wave:", wave_number, "HP:", hp.format(), "Mult:", boss_rush_mult)

func apply_burn(level: int, base_damage: float, crit_multiplier: float = 1.0, tick_interval: float = 1.0, hp_cap_percent: float = 0.10) -> void:
	# 15% at level 1 → 150% at level 10 (linear)
	var percent = BURN_MIN_PERCENT + ((level - 1) * (BURN_MAX_PERCENT - BURN_MIN_PERCENT) / 9)
	percent = clamp(percent, BURN_MIN_PERCENT, BURN_MAX_PERCENT)
	burn_damage_per_tick = base_damage * percent * crit_multiplier

	# Cap at upgraded HP cap percent (default 10%, upgradeable to 25%)
	# Use current HP (BigNumber) for calculation
	var max_burn_bn = hp.copy().multiply(hp_cap_percent)
	var max_burn_per_tick = max_burn_bn.to_float()  # Convert for comparison
	if burn_damage_per_tick > max_burn_per_tick:
		burn_damage_per_tick = max_burn_per_tick

	burn_duration = BURN_BASE_DURATION + level * BURN_DURATION_PER_LEVEL
	burn_tick_interval = tick_interval  # Apply upgraded tick rate
	burn_active = true
	burn_timer = 0.0
	burn_tick_timer = 0.0

	# Cache BigNumber to avoid creating new objects every tick
	burn_damage_bn = BigNumber.new(burn_damage_per_tick)

	# Add visual effects
	VisualFactory.create_status_effect_overlay("burn", self)
	AdvancedVisuals.create_status_icon("burn", self)
	#print("🔥", name, "burning for", burn_duration, "sec, burn tick:", burn_damage_per_tick, "every", burn_tick_interval, "s (capped at", hp_cap_percent * 100, "% max HP)")

func apply_poison(level: int, duration: float = 4.0, max_stacks: int = 1) -> void:
	#print("🟣 apply_poison CALLED on", name, "level", level)
	# Level 1 = 1% per sec, Level 10 = 7.5% per sec (nerfed from 10%)
	var percent_per_sec = POISON_MIN_PERCENT + (level - 1) * POISON_PERCENT_PER_LEVEL
	percent_per_sec = clamp(percent_per_sec, POISON_MIN_PERCENT, POISON_MAX_PERCENT)
	# Calculate poison damage from current HP (BigNumber)
	var poison_bn = hp.copy().multiply(percent_per_sec)
	var new_poison_damage = poison_bn.to_float()

	# Stacking: if already poisoned and max_stacks > 1, add to existing damage
	if poison_active and max_stacks > 1:
		poison_damage_per_tick += new_poison_damage
		poison_duration = max(poison_duration, duration)  # Extend duration if new application is longer
		poison_timer = 0.0  # Reset timer
	else:
		poison_damage_per_tick = new_poison_damage
		poison_duration = duration
		poison_timer = 0.0
		poison_tick_timer = 0.0

	poison_active = true

	# Cache BigNumber to avoid creating new objects every tick
	poison_damage_bn = BigNumber.new(poison_damage_per_tick)

	# Add visual effects (only if not already present)
	if not has_node("StatusOverlay_poison"):
		VisualFactory.create_status_effect_overlay("poison", self)
		AdvancedVisuals.create_status_icon("poison", self)
	#print("🟣", name, "poisoned for", poison_duration, "sec at", poison_damage_per_tick, "DPS (" + str(round(percent_per_sec * 100.0)) + "%/s)")

func apply_slow(level: int, duration: float = -1.0) -> void:
	# Scaling: starts at 30%, up to 75% over 10 levels (nerfed from 80%)
	slow_percent = clamp(SLOW_MIN_PERCENT + (level - 1) * SLOW_PERCENT_PER_LEVEL, SLOW_MIN_PERCENT, SLOW_MAX_PERCENT)

	# Use custom duration if provided, otherwise use default scaling
	if duration > 0:
		slow_duration = duration
	else:
		slow_duration = SLOW_BASE_DURATION + (level * SLOW_DURATION_PER_LEVEL)

	slow_timer = 0.0
	slow_active = true

	# Add visual effects (only if not already present)
	if not has_node("StatusOverlay_slow"):
		VisualFactory.create_status_effect_overlay("slow", self)
		AdvancedVisuals.create_status_icon("slow", self)
	#print("❄️", name, "slowed by", int(slow_percent * 100), "% for", slow_duration, "seconds")

func apply_stun(level: int, duration_bonus: float = 0.0) -> void:
	# Base scaling: 1 second base, +0.25s per drone level, max 2.0s
	# Plus optional bonus from upgrades
	stun_duration = min(STUN_BASE_DURATION + (level * STUN_DURATION_PER_LEVEL) + duration_bonus, STUN_MAX_DURATION)
	stun_timer = 0.0
	stun_active = true

	# Add visual effects (only if not already present)
	if not has_node("StatusOverlay_stun"):
		VisualFactory.create_status_effect_overlay("stun", self)
		AdvancedVisuals.create_status_icon("stun", self)
	#print("⚡", name, "stunned for", stun_duration, "seconds!")

func get_current_hp() -> BigNumber:
	return hp

func get_health() -> BigNumber:
	return hp

func get_health_display() -> String:
	# Return formatted HP for UI display (e.g., "1.5M" or "3.2B")
	return hp.format(1) if hp else "0"

func is_boss() -> bool:
	return enemy_type == "override"

# --- OBJECT POOLING METHODS ---

func reset_pooled_object() -> void:
	# Called when enemy is taken from pool
	is_pooled = true

	# Re-register with EnemyTracker
	EnemyTracker.register_enemy(self)

	# Reset state
	is_dead = false
	in_range = false
	time_since_last_attack = 0.0

	# Reset status effects
	burn_active = false
	burn_timer = 0.0
	burn_damage = 0.0
	burn_power = 0.0

	poison_active = false
	poison_timer = 0.0
	poison_percent = 0.0

	slow_active = false
	slow_timer = 0.0
	slow_percent = 0.0
	slow_duration = 0.0

	stun_active = false
	stun_timer = 0.0
	stun_duration = 0.0

	# Reconnect signals if needed
	if has_node("AttackZone"):
		var attack_zone = $AttackZone
		if not attack_zone.body_entered.is_connected(Callable(self, "_on_attack_zone_body_entered")):
			var err = attack_zone.body_entered.connect(Callable(self, "_on_attack_zone_body_entered"))
			if err != OK:
				push_error("Failed to connect AttackZone.body_entered signal: " + str(err))

		if not attack_zone.body_exited.is_connected(Callable(self, "_on_attack_zone_body_exited")):
			var err = attack_zone.body_exited.connect(Callable(self, "_on_attack_zone_body_exited"))
			if err != OK:
				push_error("Failed to connect AttackZone.body_exited signal: " + str(err))

	# Create visual representation
	var visual_container = VisualFactory.create_enemy_visual(enemy_type, self)

	# Reset visual if exists
	if visual_container:
		visual_container.modulate = Color(1, 1, 1, 1)
		visual_container.scale = Vector2.ONE

func cleanup_pooled_object() -> void:
	# Called when enemy is returned to pool
	# Remove from enemies group
	remove_from_group("enemies")

	# Disconnect signals
	if has_node("AttackZone"):
		var attack_zone = $AttackZone
		if attack_zone.body_entered.is_connected(Callable(self, "_on_attack_zone_body_entered")):
			attack_zone.body_entered.disconnect(Callable(self, "_on_attack_zone_body_entered"))
		if attack_zone.body_exited.is_connected(Callable(self, "_on_attack_zone_body_exited")):
			attack_zone.body_exited.disconnect(Callable(self, "_on_attack_zone_body_exited"))

	# Clear references
	tower = null
	target = null

func _cleanup_and_recycle() -> void:
	# Unregister from EnemyTracker
	EnemyTracker.unregister_enemy(self)

	# Remove from group
	remove_from_group("enemies")

	# Disconnect signals
	if has_node("AttackZone"):
		var attack_zone = $AttackZone
		if attack_zone.body_entered.is_connected(Callable(self, "_on_attack_zone_body_entered")):
			attack_zone.body_entered.disconnect(Callable(self, "_on_attack_zone_body_entered"))
		if attack_zone.body_exited.is_connected(Callable(self, "_on_attack_zone_body_exited")):
			attack_zone.body_exited.disconnect(Callable(self, "_on_attack_zone_body_exited"))

	# Return to pool or free
	if is_pooled:
		ObjectPool.recycle(self)
	else:
		queue_free()
