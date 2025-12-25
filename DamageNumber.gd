extends Label

## Floating damage number that animates upward and fades out

const FLOAT_DURATION: float = 1.0
const FLOAT_DISTANCE: float = 50.0
const FADE_START: float = 0.5  # Start fading after 50% of duration

var start_pos: Vector2
var velocity: Vector2
var lifetime: float = 0.0

func _ready() -> void:
	start_pos = position
	# Random horizontal drift
	velocity = Vector2(randf_range(-20, 20), -FLOAT_DISTANCE / FLOAT_DURATION)

	# Set label properties for better visibility
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 3)
	z_index = 100

func _process(delta: float) -> void:
	lifetime += delta

	# Move upward with slight horizontal drift
	position += velocity * delta

	# Fade out after FADE_START
	if lifetime > FADE_START:
		var fade_progress = (lifetime - FADE_START) / (FLOAT_DURATION - FADE_START)
		modulate.a = 1.0 - fade_progress

	# Remove when done
	if lifetime >= FLOAT_DURATION:
		queue_free()

func setup(damage: int, is_critical: bool = false) -> void:
	text = str(damage)

	if is_critical:
		# Critical hits are larger and yellow
		add_theme_font_size_override("font_size", 32)
		add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))  # Yellow
	else:
		# Normal damage is white
		add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
