extends CharacterBody2D


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


func _ready() -> void:
	add_to_group("enemies")
	if not $AttackZone.body_entered.is_connected(Callable(self, "_on_attack_zone_body_entered")):
		$AttackZone.body_entered.connect(Callable(self, "_on_attack_zone_body_entered"))

	if not $AttackZone.body_exited.is_connected(Callable(self, "_on_attack_zone_body_exited")):
		$AttackZone.body_exited.connect(Callable(self, "_on_attack_zone_body_exited"))

	$AttackZone.monitoring = true
	$AttackZone.monitorable = true

	# Create visual representation
	VisualFactory.create_enemy_visual(enemy_type, self)

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
	velocity = (direction * move_speed) / 2
	move_and_slide()

	time_since_last_attack += delta
	if in_range and time_since_last_attack >= attack_speed:
		#print("💢 Attempting to deal damage")
		time_since_last_attack = 0.0

		if tower and tower.has_method("take_damage"):
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
	var effective_speed = move_speed
	if slow_active:
		effective_speed = move_speed * (1.0 - slow_percent)
		slow_timer += delta
		if slow_timer >= slow_duration:
			slow_active = false
			slow_timer = 0.0
			slow_percent = 0.0
			# Remove visual effect
			VisualFactory.remove_status_effect_overlay("slow", self)
			#print("🟦", name, "slow effect ended.")

	# Use effective_speed for movement!
		var direction_slow = (tower_position - global_position).normalized()
		velocity = (direction * effective_speed) / 2
		move_and_slide()
	
		# --- Handle stun ---



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

func take_damage(amount: int) -> void:
	#print("🟥 Enemy takes damage")
	if is_dead:
		return
	hp -= amount
	if hp <= 0:
		is_dead = true
		die()
		

func die():
	is_dead = true
	# Existing death logic (play animation, remove from scene, etc.)
	RewardManager.reward_enemy(enemy_type, wave_number)
	RewardManager.reward_enemy_at(enemy_type, wave_number)

	queue_free()
	
func apply_wave_scaling():
	hp = base_hp + int(wave_number * 2.5)
	damage_to_tower = base_damage + int(wave_number * 0.4)
	move_speed = (base_speed + wave_number * 0.25) / 2
	#print("wave number:", wave_number)
	#print("enemy hp:", hp)
	
func apply_burn(level: int, base_damage: float, crit_multiplier: float = 1.0) -> void:
	# 15% at level 1 → 150% at level 10 (linear)
	var percent = 0.15 + ((level - 1) * (1.5 - 0.15) / 9)
	percent = clamp(percent, 0.15, 1.5)
	burn_damage_per_tick = base_damage * percent * crit_multiplier

	# Cap at 10% of max HP per second
	var max_hp = base_hp + int(wave_number * 2.5)  # Use the same as your HP scaling
	var max_burn_per_tick = max_hp * 0.10
	if burn_damage_per_tick > max_burn_per_tick:
		burn_damage_per_tick = max_burn_per_tick

	burn_duration = 3.0 + level * 0.5
	burn_active = true
	burn_timer = 0.0
	burn_tick_timer = 0.0

	# Add visual effect
	VisualFactory.create_status_effect_overlay("burn", self)
	#print("🔥", name, "burning for", burn_duration, "sec, burn tick:", burn_damage_per_tick, "every", burn_tick_interval, "s (capped at 10% max HP if exceeded)")

func apply_poison(level: int) -> void:
	#print("🟣 apply_poison CALLED on", name, "level", level)
	# Level 1 = 1% per sec, Level 10 = 10% per sec, capped at 10%
	var percent_per_sec = 0.01 + (level - 1) * 0.01
	percent_per_sec = clamp(percent_per_sec, 0.01, 0.10)
	var max_hp = base_hp + int(wave_number * 2.5)  # Or use your stored max_hp var
	poison_damage_per_tick = max_hp * percent_per_sec

	poison_duration = 4.0
	poison_active = true
	poison_timer = 0.0
	poison_tick_timer = 0.0

	# Add visual effect
	VisualFactory.create_status_effect_overlay("poison", self)
	#print("🟣", name, "poisoned for", poison_duration, "sec at", poison_damage_per_tick, "DPS (" + str(round(percent_per_sec * 100.0)) + "%/s)")

func apply_slow(level: int) -> void:
	# Scaling: starts at 30%, up to 80% over 10 levels, 2 sec duration
	var base_slow = 0.3  # 30% slow
	var max_slow = 0.8   # 80% slow
	slow_percent = clamp(base_slow + (level - 1) * 0.05, base_slow, max_slow)
	slow_duration = 2.0 + (level * 0.1)  # Optionally scale duration up a bit
	slow_timer = 0.0
	slow_active = true

	# Add visual effect
	VisualFactory.create_status_effect_overlay("slow", self)
	#print("❄️", name, "slowed by", int(slow_percent * 100), "% for", slow_duration, "seconds")

func apply_stun(level: int) -> void:
	# Example scaling: 1 second base, +0.25s per drone level, max 2.0s
	stun_duration = min(0.5 + (level * 0.25), 2.0)
	stun_timer = 0.0
	stun_active = true

	# Add visual effect
	VisualFactory.create_status_effect_overlay("stun", self)
	#print("⚡", name, "stunned for", stun_duration, "seconds!")

func get_current_hp() -> int:
	return hp
