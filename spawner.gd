extends Node2D

# Spawn Configuration Constants
const SPAWN_MARGIN: int = 60
const SPAWN_Y_OFFSET: float = -150.0

@export var enemy_scenes: Array[PackedScene] = [
	preload("res://enemy_breacher.tscn"),
	preload("res://enemy_slicer.tscn"),
	preload("res://enemy_sentinel.tscn"),
	preload("res://enemy_signal_runner.tscn"),
	preload("res://enemy_null_walker.tscn"),
	preload("res://enemy_override.tscn"),
]
@export var tower_ref: Node2D
@export var tower_position: Vector2 = Vector2.ZERO
@export var spawn_interval: float = 0.2

var main_hud: Node = null

# Wave spawn tracking
var enemies_to_spawn: int = 0
var spawned_enemies: int = 0
var current_wave: int = 1
var wave_spawning: bool = false
var enemy_spawn_timer: float = 0.0

func _ready() -> void:
	# Initialize enemy pools for all types
	var enemy_types = ["breacher", "slicer", "sentinel", "signal_runner", "null_walker", "override"]
	for i in range(enemy_scenes.size()):
		if i < enemy_types.size():
			var pool_name = "enemy_" + enemy_types[i]
			if not ObjectPool.pools.has(pool_name):
				ObjectPool.create_pool(pool_name, enemy_scenes[i], 30)

func _process(delta: float) -> void:
	if wave_spawning:
		enemy_spawn_timer += delta
		while enemies_to_spawn > 0 and enemy_spawn_timer >= spawn_interval:
			enemy_spawn_timer -= spawn_interval
			spawn_enemy()
			spawned_enemies += 1
			enemies_to_spawn -= 1
		if enemies_to_spawn <= 0:
			wave_spawning = false
			# Award Archive Tokens for completing the wave
			RewardManager.add_wave_at(current_wave)
			print("📦 Wave", current_wave, "completed! AT reward granted.")

			# Trigger wave complete celebration effect
			var tower = get_tree().current_scene.get_node_or_null("tower")
			if tower:
				ParticleEffects.create_wave_complete_effect(tower.global_position)

func start_wave(wave_number: int) -> int:
	print("Called start_wave with wave number: ", wave_number)
	var actual_wave = wave_number
	if should_skip_wave():
		print("⏩ Wave", actual_wave, "skipped due to Wave Skip Chance!")
		actual_wave += 1

	current_wave = actual_wave
	RunStats.current_wave = actual_wave  # Track wave in RunStats for upgrade scaling
	enemies_to_spawn = get_max_enemies_for_wave(current_wave)
	spawned_enemies = 0
	wave_spawning = true
	enemy_spawn_timer = 0.0

	# Show wave transition
	if current_wave % 10 == 0:
		spawn_boss(current_wave)
		ScreenEffects.boss_wave_transition(current_wave)
	else:
		ScreenEffects.wave_transition(current_wave)

	print("🟦 Starting wave", current_wave, "→ Spawning", enemies_to_spawn, "enemies")
	return current_wave  # ← return the actual started wave


func spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		print("❌ No enemy scenes assigned!")
		return

	var enemy_type_index = pick_enemy_type(current_wave)
	var enemy_types = ["breacher", "slicer", "sentinel", "signal_runner", "null_walker", "override"]
	var pool_name = "enemy_" + enemy_types[enemy_type_index]

	# Spawn from pool
	var enemy = ObjectPool.spawn(pool_name, self)
	if not enemy:
		print("❌ Failed to spawn enemy from pool!")
		return

	# Assign wave info
	enemy.wave_number = current_wave
	enemy.apply_wave_scaling()
	enemy.tower = tower_ref
	enemy.tower_position = tower_ref.global_position

	# Spawn within horizontal bounds
	var screen_size = get_viewport().get_visible_rect().size
	var margin = SPAWN_MARGIN
	var max_x = screen_size.x - margin

	# Ensure min < max to avoid randf_range crash
	var spawn_x: float
	if margin >= max_x or max_x <= margin:
		# Screen too small or invalid, use safe center position
		spawn_x = screen_size.x / 2.0 if screen_size.x > 0 else 960.0
	else:
		spawn_x = randf_range(margin, max_x)
	var spawn_y = SPAWN_Y_OFFSET  # Off-screen above
	enemy.position = Vector2(spawn_x, spawn_y)

func spawn_boss(wave_number: int) -> void:
	# Spawn boss from pool
	var boss = ObjectPool.spawn("enemy_override", self)
	if not boss:
		print("❌ Failed to spawn boss from pool!")
		return

	boss.wave_number = wave_number
	boss.tower_position = tower_ref.global_position
	boss.tower = tower_ref
	boss.apply_wave_scaling()
	# Position boss in center
	var screen_size = get_viewport().get_visible_rect().size
	boss.position = Vector2(screen_size.x * 0.5, -300)

func get_max_enemies_for_wave(wave: int) -> int:
	var base = 10
	var increment = int(wave / 250) * 2
	return min(base + increment, 40)

func pick_enemy_type(wave: int) -> int:
	var rng = randi() % 100
	var probabilities = {
		1:     [90, 10, 0, 0, 0],
		25:    [80, 15, 5, 0, 0],
		50:    [65, 20, 10, 5, 0],
		100:   [50, 25, 15, 8, 2],
		200:   [40, 28, 18, 10, 4],
		300:   [35, 30, 20, 10, 5],
		500:   [30, 30, 20, 12, 8],
		1000:  [25, 30, 20, 15, 10]
	}
	var closest_wave = 1
	for w in probabilities.keys():
		if w <= wave and w > closest_wave:
			closest_wave = w
	var probs = probabilities[closest_wave]
	var cumulative = 0
	for i in range(probs.size()):
		cumulative += probs[i]
		if rng < cumulative:
			return i
	return 0  # fallback

func should_skip_wave() -> bool:
	var chance = UpgradeManager.get_wave_skip_chance()
	var roll = randf() * 100.0
	return roll < chance
	
func set_main_hud(hud: Node) -> void:
	main_hud = hud
	
func reset():
	current_wave = 1
	enemies_to_spawn = 0
	spawned_enemies = 0
	wave_spawning = false
	enemy_spawn_timer = 0.0
	# Remove all enemies from the scene
	for enemy in get_children():
		if "Enemy" in enemy.name or enemy.is_in_group("enemies"):
			if enemy.has_method("_cleanup_and_recycle"):
				enemy._cleanup_and_recycle()
			else:
				enemy.queue_free()
