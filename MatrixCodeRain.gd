extends Node2D

## MatrixCodeRain - Falling code characters in the background

const COLUMN_COUNT = 40
const CHAR_SIZE = 16
const FALL_SPEED_MIN = 50.0
const FALL_SPEED_MAX = 150.0
const CODE_CHARS = "01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"

var columns: Array = []

class CodeColumn:
	var position: Vector2
	var characters: Array = []
	var fall_speed: float
	var trail_length: int

	func _init(x: float, speed: float, length: int):
		position = Vector2(x, randf_range(-500, 0))
		fall_speed = speed
		trail_length = length
		# Fill with random characters
		for i in range(length):
			characters.append(_random_char())

	func _random_char() -> String:
		var chars = "01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
		return chars[randi() % chars.length()]

func _ready() -> void:
	z_index = -150  # Behind parallax layers

	# Create columns
	var screen_width = 1920
	var column_spacing = screen_width / COLUMN_COUNT

	for i in range(COLUMN_COUNT):
		var speed = randf_range(FALL_SPEED_MIN, FALL_SPEED_MAX)
		var length = randi_range(8, 20)
		var column = CodeColumn.new(i * column_spacing, speed, length)
		columns.append(column)

	print("✅ Matrix code rain initialized with", COLUMN_COUNT, "columns")

func _process(delta: float) -> void:
	queue_redraw()  # Trigger _draw

	# Update column positions
	for column in columns:
		column.position.y += column.fall_speed * delta

		# Reset column when off screen
		if column.position.y > 1080 + (column.trail_length * CHAR_SIZE):
			column.position.y = -column.trail_length * CHAR_SIZE
			# Randomize character occasionally
			if randf() < 0.3:
				for i in range(column.characters.size()):
					if randf() < 0.1:
						column.characters[i] = column._random_char()

func _draw() -> void:
	for column in columns:
		_draw_column(column)

func _draw_column(column: CodeColumn) -> void:
	for i in range(column.characters.size()):
		var char_pos = column.position + Vector2(0, i * CHAR_SIZE)

		# Skip if off screen
		if char_pos.y < -CHAR_SIZE or char_pos.y > 1080 + CHAR_SIZE:
			continue

		# Color fade from bright green at head to dark at tail
		var alpha_factor = 1.0 - (float(i) / column.trail_length)
		var brightness = 0.3 + (alpha_factor * 0.7)

		var color: Color
		if i == 0:
			# Head is bright white-green
			color = Color(0.9, 1.0, 0.9, alpha_factor * 0.9)
		else:
			# Tail fades to dark green
			color = Color(0.0, brightness, 0.0, alpha_factor * 0.5)

		# Draw character (using draw_string would require font, so we'll draw rects as placeholder)
		# In production, you'd use a proper font here
		_draw_code_char(char_pos, column.characters[i], color)

func _draw_code_char(pos: Vector2, char: String, color: Color) -> void:
	# Simple representation using rectangles
	# For production, use draw_string with a monospace font

	# Draw as small rectangles forming a character-like shape
	var rect_size = Vector2(CHAR_SIZE * 0.6, CHAR_SIZE * 0.8)
	draw_rect(Rect2(pos, rect_size), color, false, 1.5)

	# Add inner detail
	if color.a > 0.5:
		var inner_size = Vector2(CHAR_SIZE * 0.3, CHAR_SIZE * 0.4)
		var inner_pos = pos + Vector2(CHAR_SIZE * 0.15, CHAR_SIZE * 0.2)
		draw_rect(Rect2(inner_pos, inner_size), Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, color.a * 0.8), true)
