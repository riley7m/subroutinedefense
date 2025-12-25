extends Node

## ParticleEffects - Runtime Particle System Generator
## Creates GPU particle effects for explosions, impacts, and VFX

# ============================================================================
# ENEMY DEATH EXPLOSIONS
# ============================================================================

func create_enemy_explosion(position: Vector2, enemy_type: String, parent: Node) -> void:
	# Null safety check
	if not parent or not is_instance_valid(parent):
		return

	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.8
	particles.explosiveness = 0.9
	particles.process_material = _create_explosion_material(enemy_type)

	parent.add_child(particles)

	# Auto-cleanup using finished signal (more reliable than timer)
	particles.finished.connect(particles.queue_free)

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

	# Scale with curve for expansion
	material.scale_min = 3.0
	material.scale_max = 6.0

	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.5))  # Start small
	scale_curve.add_point(Vector2(0.3, 1.0))  # Expand quickly
	scale_curve.add_point(Vector2(1.0, 0.3))  # Shrink at end
	var scale_texture = CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture

	# Multi-color gradient with emissive HDR colors
	var gradient = Gradient.new()
	# Bright emissive start (HDR values > 1.0 for bloom effect)
	gradient.add_point(0.0, Color(color.r * 2.0, color.g * 2.0, color.b * 2.0, 1.0))
	# Peak brightness
	gradient.add_point(0.2, Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 1.0))
	# Normal color
	gradient.add_point(0.5, Color(color.r, color.g, color.b, 0.8))
	# Darken and fade
	gradient.add_point(1.0, Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.0))

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# PROJECTILE IMPACTS
# ============================================================================

func create_projectile_impact(position: Vector2, parent: Node) -> void:
	# Null safety check
	if not parent or not is_instance_valid(parent):
		return

	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.process_material = _create_impact_material()

	parent.add_child(particles)

	# Auto-cleanup using finished signal
	particles.finished.connect(particles.queue_free)

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

	# Scale with expansion curve
	material.scale_min = 2.0
	material.scale_max = 4.0

	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.5, 1.2))  # Expand mid-life
	scale_curve.add_point(Vector2(1.0, 0.1))  # Shrink at end
	var scale_texture = CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture

	# Enhanced gradient with emissive cyan-white energy
	var gradient = Gradient.new()
	# Ultra-bright white flash (emissive HDR)
	gradient.add_point(0.0, Color(3.0, 3.0, 3.0, 1.0))
	# Cyan energy peak
	gradient.add_point(0.3, Color(1.5, 2.5, 2.5, 1.0))
	# Cyan fade
	gradient.add_point(0.7, Color(0.6, 1.0, 1.0, 0.5))
	# Transparent
	gradient.add_point(1.0, Color(0.3, 0.5, 0.5, 0.0))

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# TOWER MUZZLE FLASH
# ============================================================================

func create_muzzle_flash(position: Vector2, direction: Vector2, parent: Node) -> void:
	# Null safety check
	if not parent or not is_instance_valid(parent):
		return

	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 5
	particles.lifetime = 0.2
	particles.explosiveness = 1.0
	particles.process_material = _create_muzzle_flash_material(direction)

	parent.add_child(particles)

	# Auto-cleanup using finished signal
	particles.finished.connect(particles.queue_free)

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

	# Scale with quick burst
	material.scale_min = 3.0
	material.scale_max = 5.0

	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.1, 1.5))  # Quick expansion
	scale_curve.add_point(Vector2(1.0, 0.0))  # Rapid shrink
	var scale_texture = CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture

	# Intense muzzle flash gradient (emissive)
	var gradient = Gradient.new()
	# Blinding white flash (HDR emissive)
	gradient.add_point(0.0, Color(4.0, 4.0, 4.0, 1.0))
	# Cyan-white energy
	gradient.add_point(0.3, Color(2.0, 2.5, 2.5, 1.0))
	# Fade to cyan
	gradient.add_point(0.7, Color(0.8, 1.0, 1.0, 0.3))
	# Transparent
	gradient.add_point(1.0, Color(0.4, 0.5, 0.5, 0.0))

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# BOSS DEATH MEGA EXPLOSION
# ============================================================================

func create_boss_explosion(position: Vector2, parent: Node) -> void:
	# Null safety check
	if not parent or not is_instance_valid(parent):
		return

	var particles = GPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 50
	particles.lifetime = 1.2
	particles.explosiveness = 0.8
	particles.process_material = _create_boss_explosion_material()

	parent.add_child(particles)

	# Auto-cleanup using finished signal
	particles.finished.connect(particles.queue_free)

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

	# Large scale with dramatic curve
	material.scale_min = 5.0
	material.scale_max = 10.0

	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.3))  # Start smaller
	scale_curve.add_point(Vector2(0.2, 1.5))  # Massive expansion
	scale_curve.add_point(Vector2(0.6, 1.0))  # Hold
	scale_curve.add_point(Vector2(1.0, 0.2))  # Shrink
	var scale_texture = CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture

	# Epic boss explosion gradient with multiple color shifts
	var gradient = Gradient.new()
	# White-hot core (emissive HDR)
	gradient.add_point(0.0, Color(4.0, 4.0, 4.0, 1.0))
	# Cyan-green energy blast
	gradient.add_point(0.15, Color(1.5, 3.0, 2.5, 1.0))
	# Green energy
	gradient.add_point(0.4, Color(0.5, 2.0, 1.2, 0.9))
	# Cyan fade
	gradient.add_point(0.7, Color(0.3, 1.0, 0.7, 0.5))
	# Dark green smoke
	gradient.add_point(1.0, Color(0.1, 0.3, 0.2, 0.0))

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material

# ============================================================================
# WAVE COMPLETE CELEBRATION
# ============================================================================

func create_wave_complete_effect(parent: Node) -> void:
	# Null safety check
	if not parent or not is_instance_valid(parent):
		return

	var particles = GPUParticles2D.new()
	particles.position = Vector2(960, 540)  # Center of 1920x1080 screen
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 1.5
	particles.explosiveness = 0.5
	particles.process_material = _create_celebration_material()

	parent.add_child(particles)

	# Auto-cleanup using finished signal
	particles.finished.connect(particles.queue_free)

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

	# Scale with sparkle effect
	material.scale_min = 4.0
	material.scale_max = 8.0

	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.8))
	scale_curve.add_point(Vector2(0.3, 1.2))  # Sparkle expansion
	scale_curve.add_point(Vector2(0.6, 0.9))
	scale_curve.add_point(Vector2(1.0, 0.3))  # Fade out
	var scale_texture = CurveTexture.new()
	scale_texture.curve = scale_curve
	material.scale_curve = scale_texture

	# Celebratory gradient with rainbow shimmer effect
	var gradient = Gradient.new()
	# Bright white-cyan start (emissive)
	gradient.add_point(0.0, Color(2.5, 2.5, 3.0, 1.0))
	# Cyan peak
	gradient.add_point(0.25, Color(1.0, 2.0, 2.5, 1.0))
	# Blue-purple shift
	gradient.add_point(0.5, Color(0.7, 1.2, 2.0, 0.8))
	# Cyan fade
	gradient.add_point(0.75, Color(0.4, 0.9, 1.0, 0.4))
	# Transparent
	gradient.add_point(1.0, Color(0.2, 0.4, 0.5, 0.0))

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	return material
