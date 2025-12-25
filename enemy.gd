extends CharacterBody2D

# Wave Scaling Constants
const HP_PER_WAVE: float = 2.5
const DAMAGE_PER_WAVE: float = 0.4
const SPEED_PER_WAVE: float = 0.25

# Burn Effect Constants
const BURN_MIN_PERCENT: float = 0.15
const BURN_MAX_PERCENT: float = 1.5
const BURN_HP_CAP_PERCENT: float = 0.10
const BURN_BASE_DURATION: float = 3.0
const BURN_DURATION_PER_LEVEL: float = 0.5

# Poison Effect Constants
const POISON_MIN_PERCENT: float = 0.01
const POISON_MAX_PERCENT: float = 0.10
const POISON_PERCENT_PER_LEVEL: float = 0.01
const POISON_DURATION: float = 4.0

# Slow Effect Constants
const SLOW_MIN_PERCENT: float = 0.3
const SLOW_MAX_PERCENT: float = 0.8
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
var hp: int
var damage_to_tower: int
var move_speed: float
@export var tower_position: Vector2 = Vector2.ZERO
@export var enemy_type: String = "breacher"  # Or slicer/sentinel/etc



var time_since_last_attack := 0.0
var is_dead: bool = false
var in_range: bool = false
var tower: Node = null

# --- Burn Effect ---
var burn_active: bool = false
var burn_timer: float = 0.0
var burn_duration: float = 0.0
var burn_damage_per_tick: float = 0.0
var burn_tick_interval: float = 1.0   # 1 second per tick
var burn_tick_timer: float = 0.0

# --- Poison Effect ---
var poison_active: bool = false
var poison_timer: float = 0.0
var poison_duration: float = 0.0
var poison_damage_per_tick: float = 0.0
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


func _ready() -> void:
	add_to_group("enemies")

	# Initialize stats (will be overwritten by apply_wave_scaling, but safe defaults)
	hp = base_hp
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
	VisualFactory.create_enemy_visual(enemy_type, self)

	# Add Light2D for enemy glow (color varies by type)
	var light = Light2D.new()
	light.enabled = true
	light.texture = preload("res://icon.svg")
	light.texture_scale = 1.5

	# Different colors for different enemy types
	match enemy_type:
		"override":  # Boss
			light.color = Color(1.0, 0.0, 1.0, 1.0)  # Magenta
			light.energy = 2.0
			light.texture_scale = 3.0
		"sentinel":
			light.color = Color(1.0, 0.5, 0.0, 1.0)  # Orange
			light.energy = 1.2
		"slicer":
			light.color = Color(1.0, 0.3, 0.3, 1.0)  # Red-orange
			light.energy = 1.0
		_:  # Default (breacher)
			light.color = Color(1.0, 0.2, 0.2, 1.0)  # Red
			light.energy = 1.0

	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	add_child(light)

	# Create trail effect
	trail = Line2D.new()
	trail.width = 4.0

	# Trail color matches enemy type
	var trail_color: Color
	match enemy_type:
		"override":  # Boss
			trail_color = Color(1.0, 0.0, 1.0, 0.5)  # Magenta
		"sentinel":
			trail_color = Color(1.0, 0.5, 0.0, 0.5)  # Orange
		"slicer":
			trail_color = Color(1.0, 0.3, 0.3, 0.5)  # Red-orange
		_:  # Breacher
			trail_color = Color(1.0, 0.2, 0.2, 0.5)  # Red

	# Create gradient for trail fade
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	gradient.add_point(1.0, trail_color)
	trail.gradient = gradient

	trail.width_curve = Curve.new()
	trail.width_curve.add_point(Vector2(0.0, 0.2))
	trail.width_curve.add_point(Vector2(1.0, 1.0))

	trail.antialiased = true
	trail.z_index = -1

	# Null safety check for parent
	var parent = get_parent()
	if parent and is_instance_valid(parent):
		parent.add_child(trail)
	else:
		trail.queue_free()
		trail = null

	last_trail_pos = global_position

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
			# Remove visual effect
			VisualFactory.remove_status_effect_overlay("stun", self)
			#print(name, "stun ended")
		return
	# Move toward tower
	var direction = (tower_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Update trail
	if trail and is_instance_valid(trail):
		if global_position.distance_to(last_trail_pos) > TRAIL_SPACING:
			trail.add_point(global_position)
			last_trail_pos = global_position

			# Limit trail length
			if trail.get_point_count() > MAX_TRAIL_POINTS:
				trail.remove_point(0)

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
			hp -= burn_damage_per_tick
			burn_tick_timer -= burn_tick_interval
			#print("🔥", name, "takes", burn_damage_per_tick, "burn tick! HP now", hp)
		if burn_timer >= burn_duration:
			burn_active = false
			burn_timer = 0.0
			burn_tick_timer = 0.0
			burn_duration = 0.0
			burn_damage_per_tick = 0.0
			# Remove visual effect
			VisualFactory.remove_status_effect_overlay("burn", self)
			#print("🔥", name, "burn ended")
		if hp <= 0 and not is_dead:
			is_dead = true
			die()
	
		# --- Poison effect tick ---
	if poison_active:
		poison_timer += delta
		poison_tick_timer += delta
		if poison_tick_timer >= poison_tick_interval:
			hp -= poison_damage_per_tick
			poison_tick_timer -= poison_tick_interval
			#print("🟣", name, "takes", poison_damage_per_tick, "poison tick! HP now", hp)
		if poison_timer >= poison_duration:
			poison_active = false
			poison_timer = 0.0
			poison_tick_timer = 0.0
			poison_duration = 0.0
			poison_damage_per_tick = 0.0
			# Remove visual effect
			VisualFactory.remove_status_effect_overlay("poison", self)
			#print("🟣", name, "poison ended")
		if hp <= 0 and not is_dead:
			is_dead = true
			die()
	# --- Apply slow effect ---
	if slow_active:
		slow_timer += delta
		if slow_timer >= slow_duration:
			slow_active = false
			slow_timer = 0.0
			slow_percent = 0.0
			# Remove visual effect
			VisualFactory.remove_status_effect_overlay("slow", self)
			#print("🟦", name, "slow effect ended.")
		else:
			# Apply slow to current movement
			var slow_multiplier = (1.0 - slow_percent)
			velocity *= slow_multiplier

	# --- Final death check (in case status effects reduced hp to 0) ---
	if hp <= 0 and not is_dead:
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

	# Spawn floating damage number
	var damage_label = Label.new()
	damage_label.text = str(amount)
	damage_label.global_position = global_position
	damage_label.z_index = 100

	# Style the label
	damage_label.add_theme_font_size_override("font_size", 24 if not is_critical else 32)
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	damage_label.add_theme_constant_override("outline_size", 3)

	if is_critical:
		damage_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))  # Yellow for crits
	else:
		damage_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White for normal

	# Null safety check for parent
	var parent = get_parent()
	if parent and is_instance_valid(parent):
		parent.add_child(damage_label)
	else:
		damage_label.queue_free()
		return

	# Animate the damage number
	var tween = damage_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "global_position:y", global_position.y - 50, 1.0)
	tween.tween_property(damage_label, "global_position:x", global_position.x + randf_range(-20, 20), 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tween.tween_callback(func():
		if is_instance_valid(damage_label):
			damage_label.queue_free()
	).set_delay(1.0)

	hp -= amount
	if hp <= 0:
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

	# Clean up trail
	if trail and is_instance_valid(trail):
		trail.queue_free()

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

	# Grant fragments for boss kills
	if enemy_type == "override":
		var fragment_reward = 10 + int(wave_number / 10)  # Scales with wave
		RewardManager.add_fragments(fragment_reward)
		print("💎 Boss killed! Fragments earned:", fragment_reward)
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
		queue_free()
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
			queue_free()
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
	hp = base_hp + int(wave_number * HP_PER_WAVE)
	damage_to_tower = base_damage + int(wave_number * DAMAGE_PER_WAVE)
	move_speed = (base_speed + wave_number * SPEED_PER_WAVE) / 2
	#print("wave number:", wave_number)
	#print("enemy hp:", hp)
	
func apply_burn(level: int, base_damage: float, crit_multiplier: float = 1.0) -> void:
	# 15% at level 1 → 150% at level 10 (linear)
	var percent = BURN_MIN_PERCENT + ((level - 1) * (BURN_MAX_PERCENT - BURN_MIN_PERCENT) / 9)
	percent = clamp(percent, BURN_MIN_PERCENT, BURN_MAX_PERCENT)
	burn_damage_per_tick = base_damage * percent * crit_multiplier

	# Cap at 10% of max HP per second
	var max_hp = base_hp + int(wave_number * HP_PER_WAVE)
	var max_burn_per_tick = max_hp * BURN_HP_CAP_PERCENT
	if burn_damage_per_tick > max_burn_per_tick:
		burn_damage_per_tick = max_burn_per_tick

	burn_duration = BURN_BASE_DURATION + level * BURN_DURATION_PER_LEVEL
	burn_active = true
	burn_timer = 0.0
	burn_tick_timer = 0.0

	# Add visual effect
	VisualFactory.create_status_effect_overlay("burn", self)
	#print("🔥", name, "burning for", burn_duration, "sec, burn tick:", burn_damage_per_tick, "every", burn_tick_interval, "s (capped at 10% max HP if exceeded)")

func apply_poison(level: int) -> void:
	#print("🟣 apply_poison CALLED on", name, "level", level)
	# Level 1 = 1% per sec, Level 10 = 10% per sec, capped at 10%
	var percent_per_sec = POISON_MIN_PERCENT + (level - 1) * POISON_PERCENT_PER_LEVEL
	percent_per_sec = clamp(percent_per_sec, POISON_MIN_PERCENT, POISON_MAX_PERCENT)
	var max_hp = base_hp + int(wave_number * HP_PER_WAVE)
	poison_damage_per_tick = max_hp * percent_per_sec

	poison_duration = POISON_DURATION
	poison_active = true
	poison_timer = 0.0
	poison_tick_timer = 0.0

	# Add visual effect
	VisualFactory.create_status_effect_overlay("poison", self)
	#print("🟣", name, "poisoned for", poison_duration, "sec at", poison_damage_per_tick, "DPS (" + str(round(percent_per_sec * 100.0)) + "%/s)")

func apply_slow(level: int) -> void:
	# Scaling: starts at 30%, up to 80% over 10 levels, 2 sec duration
	slow_percent = clamp(SLOW_MIN_PERCENT + (level - 1) * SLOW_PERCENT_PER_LEVEL, SLOW_MIN_PERCENT, SLOW_MAX_PERCENT)
	slow_duration = SLOW_BASE_DURATION + (level * SLOW_DURATION_PER_LEVEL)
	slow_timer = 0.0
	slow_active = true

	# Add visual effect
	VisualFactory.create_status_effect_overlay("slow", self)
	#print("❄️", name, "slowed by", int(slow_percent * 100), "% for", slow_duration, "seconds")

func apply_stun(level: int) -> void:
	# Example scaling: 1 second base, +0.25s per drone level, max 2.0s
	stun_duration = min(STUN_BASE_DURATION + (level * STUN_DURATION_PER_LEVEL), STUN_MAX_DURATION)
	stun_timer = 0.0
	stun_active = true

	# Add visual effect
	VisualFactory.create_status_effect_overlay("stun", self)
	#print("⚡", name, "stunned for", stun_duration, "seconds!")

func get_current_hp() -> int:
	return hp

func get_health() -> int:
	return hp

func is_boss() -> bool:
	return enemy_type == "override"
