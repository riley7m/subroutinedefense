extends Node

## ParticleEffects - Runtime Particle System Generator
## Creates GPU particle effects for explosions, impacts, and VFX

# ============================================================================
# ENEMY DEATH EXPLOSIONS
# ============================================================================

func create_enemy_explosion(position: Vector2, enemy_type: String, parent: Node) -> void:
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.8
	particles.explosiveness = 0.9
	particles.process_material = _create_explosion_material(enemy_type)

	parent.add_child(particles)

	# Auto-cleanup after particles finish
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _create_explosion_material(enemy_type: String) -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()

	# Get color based on enemy type
	var color: Color
	match enemy_type:
		"breacher":
			color = Color(1.0, 0.3, 0.3)  # Red
		"slicer":
			color = Color(0.9, 0.9, 0.3)  # Yellow
		"sentinel":
			color = Color(0.3, 0.7, 1.0)  # Blue
		"null_walker":
			color = Color(0.7, 0.3, 0.9)  # Purple
		"override":
			color = Color(0.3, 1.0, 0.7)  # Green
		"signal_runner":
			color = Color(1.0, 0.7, 0.3)  # Orange
		_:
			color = Color(0.9, 0.3, 0.9)  # Magenta

	# Emission shape - radial burst
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0

	# Direction - outward in all directions
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0

	# Speed
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0

	# Gravity
	material.gravity = Vector3(0, 0, 0)

	# Damping (particles slow down)
	material.damping_min = 50.0
	material.damping_max = 100.0

	# Scale
	material.scale_min = 3.0
	material.scale_max = 6.0

	# Color
	material.color = color

	# Fade out over lifetime
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(color.r, color.g, color.b, 1.0))
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# PROJECTILE IMPACTS
# ============================================================================

func create_projectile_impact(position: Vector2, parent: Node) -> void:
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.process_material = _create_impact_material()

	parent.add_child(particles)

	# Auto-cleanup
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _create_impact_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0

	# Direction - radial
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0

	# Speed
	material.initial_velocity_min = 40.0
	material.initial_velocity_max = 80.0

	# Damping
	material.damping_min = 100.0
	material.damping_max = 150.0

	# Scale
	material.scale_min = 2.0
	material.scale_max = 4.0

	# Color - cyan energy
	material.color = Color(0.6, 1.0, 1.0)

	# Fade
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 1.0, 1.0, 1.0))
	gradient.add_point(1.0, Color(0.6, 1.0, 1.0, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# TOWER MUZZLE FLASH
# ============================================================================

func create_muzzle_flash(position: Vector2, direction: Vector2, parent: Node) -> void:
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 5
	particles.lifetime = 0.2
	particles.explosiveness = 1.0
	particles.process_material = _create_muzzle_flash_material(direction)

	parent.add_child(particles)

	# Auto-cleanup
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _create_muzzle_flash_material(direction: Vector2) -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 2.0

	# Direction - along projectile path
	var dir_3d = Vector3(direction.x, direction.y, 0).normalized()
	material.direction = dir_3d
	material.spread = 30.0

	# Speed
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0

	# Damping
	material.damping_min = 200.0
	material.damping_max = 250.0

	# Scale
	material.scale_min = 3.0
	material.scale_max = 5.0

	# Color - bright cyan flash
	material.color = Color(0.8, 1.0, 1.0)

	# Quick fade
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 1.0, 1.0, 1.0))
	gradient.add_point(1.0, Color(0.8, 1.0, 1.0, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# BOSS DEATH MEGA EXPLOSION
# ============================================================================

func create_boss_explosion(position: Vector2, parent: Node) -> void:
	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 50
	particles.lifetime = 1.2
	particles.explosiveness = 0.8
	particles.process_material = _create_boss_explosion_material()

	parent.add_child(particles)

	# Auto-cleanup
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _create_boss_explosion_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0

	# Direction - massive radial burst
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0

	# Speed
	material.initial_velocity_min = 150.0
	material.initial_velocity_max = 300.0

	# Damping
	material.damping_min = 30.0
	material.damping_max = 60.0

	# Scale
	material.scale_min = 5.0
	material.scale_max = 10.0

	# Color - green/cyan mix
	material.color = Color(0.3, 1.0, 0.7)

	# Fade
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.3, 1.0, 0.7, 1.0))
	gradient.add_point(0.7, Color(0.3, 1.0, 0.7, 0.5))
	gradient.add_point(1.0, Color(0.3, 1.0, 0.7, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# WAVE COMPLETE CELEBRATION
# ============================================================================

func create_wave_complete_effect(parent: Node) -> void:
	var particles = GPUParticles2D.new()
	particles.position = Vector2(960, 540)  # Center of 1920x1080 screen
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 1.5
	particles.explosiveness = 0.5
	particles.process_material = _create_celebration_material()

	parent.add_child(particles)

	# Auto-cleanup
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _create_celebration_material() -> ParticleProcessMaterial:
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 100.0

	# Direction - upward fountain
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0

	# Speed
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0

	# Gravity - particles fall
	material.gravity = Vector3(0, 200, 0)

	# Scale
	material.scale_min = 4.0
	material.scale_max = 8.0

	# Color - cyan/blue celebration
	material.color = Color(0.4, 0.9, 1.0)

	# Fade
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.4, 0.9, 1.0, 1.0))
	gradient.add_point(1.0, Color(0.4, 0.9, 1.0, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material
