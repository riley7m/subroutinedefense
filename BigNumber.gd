extends RefCounted
class_name BigNumber

## BigNumber - Scientific notation system for extremely large numbers
## Stores numbers as: coefficient * 10^exponent
## Example: 1.5 octillion = 1.5 * 10^27
##
## Supports numbers from 0 to 1az (10^237)

var mantissa: float = 0.0  # The coefficient (1.0 - 9.999...)
var exponent: int = 0      # Power of 10

# Number suffix system for idle games
# Goes: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc, UnDc... then aa, ab, ac... az, ba... bz, ca... zz
const SUFFIXES = [
	"", "K", "M", "B", "T",  # 0-12
	"Qa", "Qi", "Sx", "Sp", "Oc", "No",  # 15-30
	"Dc", "UnDc", "DoDc", "TrDc", "QaDc",  # 33-48
	"QiDc", "SxDc", "SpDc", "OcDc", "NoDc",  # 51-66
	"Vg", "UnVg", "DoVg", "TrVg", "QaVg",  # 69-84
	"QiVg", "SxVg", "SpVg", "OcVg", "NoVg",  # 87-102
	"Tg", "UnTg", "DoTg", "TrTg", "QaTg",  # 105-120
	"QiTg", "SxTg", "SpTg", "OcTg", "NoTg"  # 123-138
]

# Letter suffix system: aa, ab, ac... az, ba, bb... bz, ca... zz
# Covers 10^141 to 10^3000+
func _get_letter_suffix(tier: int) -> String:
	if tier < 47:
		return SUFFIXES[tier] if tier < SUFFIXES.size() else "?"

	# tier 47+ use letter system: aa, ab, ac... az, ba... zz
	var adjusted_tier = tier - 47
	var first_letter = char(97 + (adjusted_tier / 26))  # a-z
	var second_letter = char(97 + (adjusted_tier % 26))  # a-z
	return first_letter + second_letter

## Constructor
func _init(value = 0, exp: int = 0):
	if value is BigNumber:
		mantissa = value.mantissa
		exponent = value.exponent
	elif value is float or value is int:
		from_number(value, exp)
	else:
		mantissa = 0.0
		exponent = 0
	normalize()

## Create from regular number
func from_number(value: float, exp: int = 0) -> BigNumber:
	if value == 0:
		mantissa = 0.0
		exponent = 0
		return self

	mantissa = abs(value)
	exponent = exp

	# Handle sign
	var sign = 1.0 if value >= 0 else -1.0

	# Normalize to scientific notation (1.0 <= mantissa < 10.0)
	while mantissa >= 10.0:
		mantissa /= 10.0
		exponent += 1

	while mantissa < 1.0 and mantissa != 0:
		mantissa *= 10.0
		exponent -= 1

	mantissa *= sign
	return self

## Normalize the BigNumber to standard form
func normalize() -> void:
	if mantissa == 0:
		exponent = 0
		return

	var sign = 1.0 if mantissa >= 0 else -1.0
	var abs_mantissa = abs(mantissa)

	while abs_mantissa >= 10.0:
		abs_mantissa /= 10.0
		exponent += 1

	while abs_mantissa < 1.0 and abs_mantissa != 0:
		abs_mantissa *= 10.0
		exponent -= 1

	mantissa = abs_mantissa * sign

## Convert to regular int (loses precision for large numbers)
func to_int() -> int:
	if exponent > 18:
		return 9223372036854775807  # int64 max
	return int(mantissa * pow(10, exponent))

## Convert to regular float (loses precision for large numbers)
func to_float() -> float:
	if exponent > 308:
		return INF
	return mantissa * pow(10.0, exponent)

## Format for display with suffix
func format(decimal_places: int = 2) -> String:
	if mantissa == 0:
		return "0"

	# For small numbers (< 1000), show as regular number
	if exponent < 3:
		var num = mantissa * pow(10, exponent)
		if decimal_places == 0:
			return str(int(num))
		return ("%." + str(decimal_places) + "f") % num

	# Calculate tier (K = 1, M = 2, B = 3, T = 4, etc.)
	var tier = int(exponent / 3)
	var suffix = _get_letter_suffix(tier)

	# Calculate display mantissa for this tier
	var display_mantissa = mantissa * pow(10, exponent % 3)

	var format_str = "%." + str(decimal_places) + "f%s"
	return format_str % [display_mantissa, suffix]

## Format with scientific notation (1.5e27)
func format_scientific() -> String:
	if mantissa == 0:
		return "0"
	return "%.2fe%d" % [mantissa, exponent]

## Addition
func add(other: BigNumber) -> BigNumber:
	if other.mantissa == 0:
		return self
	if mantissa == 0:
		mantissa = other.mantissa
		exponent = other.exponent
		return self

	# Align exponents
	var exp_diff = exponent - other.exponent

	if abs(exp_diff) > 15:
		# Difference too large, keep larger value
		if exp_diff > 0:
			return self  # self is much larger
		else:
			mantissa = other.mantissa
			exponent = other.exponent
			return self  # other is much larger

	if exp_diff >= 0:
		mantissa = mantissa + other.mantissa * pow(10, -exp_diff)
	else:
		mantissa = mantissa * pow(10, exp_diff) + other.mantissa
		exponent = other.exponent

	normalize()
	return self

## Subtraction
func subtract(other: BigNumber) -> BigNumber:
	var neg = other.copy()
	neg.mantissa = -neg.mantissa
	return add(neg)

## Multiplication
func multiply(other) -> BigNumber:
	if other is BigNumber:
		mantissa *= other.mantissa
		exponent += other.exponent
	elif other is float or other is int:
		mantissa *= other
	normalize()
	return self

## Division
func divide(other) -> BigNumber:
	if other is BigNumber:
		if other.mantissa == 0:
			push_error("BigNumber: Division by zero")
			return self
		mantissa /= other.mantissa
		exponent -= other.exponent
	elif other is float or other is int:
		if other == 0:
			push_error("BigNumber: Division by zero")
			return self
		mantissa /= other
	normalize()
	return self

## Power
func power(exp_value: int) -> BigNumber:
	if exp_value == 0:
		mantissa = 1.0
		exponent = 0
		return self

	if exp_value == 1:
		return self

	# Use logarithm method for large exponents
	var log_value = log(abs(mantissa)) + exponent * log(10)
	var new_log = log_value * exp_value

	exponent = int(new_log / log(10))
	mantissa = exp(new_log - exponent * log(10))

	normalize()
	return self

## Comparison: self > other
func greater_than(other: BigNumber) -> bool:
	if exponent > other.exponent:
		return mantissa > 0
	if exponent < other.exponent:
		return mantissa < 0
	return mantissa > other.mantissa

## Comparison: self < other
func less_than(other: BigNumber) -> bool:
	return other.greater_than(self)

## Comparison: self >= other
func greater_equal(other: BigNumber) -> bool:
	return greater_than(other) or equals(other)

## Comparison: self <= other
func less_equal(other: BigNumber) -> bool:
	return less_than(other) or equals(other)

## Comparison: self == other
func equals(other: BigNumber) -> bool:
	return mantissa == other.mantissa and exponent == other.exponent

## Copy this BigNumber
func copy() -> BigNumber:
	var bn = BigNumber.new()
	bn.mantissa = mantissa
	bn.exponent = exponent
	return bn

## Static helper: Create BigNumber from string (e.g., "1.5Oc" = 1.5 octillion)
static func from_string(text: String) -> BigNumber:
	var bn = BigNumber.new()

	# Handle scientific notation (1.5e27)
	if "e" in text.to_lower():
		var parts = text.split("e")
		if parts.size() == 2:
			bn.mantissa = float(parts[0])
			bn.exponent = int(parts[1])
			bn.normalize()
			return bn

	# Extract number and suffix
	var num_part = ""
	var suffix_part = ""

	for i in range(text.length()):
		var c = text[i]
		if c.is_valid_float() or c == "." or c == "-":
			num_part += c
		else:
			suffix_part = text.substr(i).strip_edges()
			break

	bn.mantissa = float(num_part) if num_part else 0.0

	# Find suffix tier
	if suffix_part:
		var tier = 0
		for i in range(bn.SUFFIXES.size()):
			if bn.SUFFIXES[i] == suffix_part:
				tier = i
				break

		# Handle letter suffixes (aa, ab, etc.)
		if suffix_part.length() == 2 and suffix_part[0] >= 'a' and suffix_part[0] <= 'z':
			var first = suffix_part.unicode_at(0) - 97
			var second = suffix_part.unicode_at(1) - 97
			tier = 47 + first * 26 + second

		bn.exponent = tier * 3

	bn.normalize()
	return bn

## Static helper: Max of two BigNumbers
static func max_bn(a: BigNumber, b: BigNumber) -> BigNumber:
	return a.copy() if a.greater_than(b) else b.copy()

## Static helper: Min of two BigNumbers
static func min_bn(a: BigNumber, b: BigNumber) -> BigNumber:
	return a.copy() if a.less_than(b) else b.copy()

## Debug string
func _to_string() -> String:
	return format(2)
