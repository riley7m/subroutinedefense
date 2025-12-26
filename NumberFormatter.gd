extends Node

## NumberFormatter - Singleton for formatting numbers with big number support
##
## Usage:
##   NumberFormatter.format(1500)  # "1.50K"
##   NumberFormatter.format(1500000000000)  # "1.50T"
##   NumberFormatter.format_big(BigNumber)  # For BigNumber objects

## Format regular int/float with suffix (up to int64 max ~10^18)
func format(num, decimal_places: int = 2) -> String:
	if num is BigNumber:
		return num.format(decimal_places)

	# Convert to int if needed
	var int_num = int(num) if num is float else num

	# Handle negative numbers
	var sign = "" if int_num >= 0 else "-"
	var abs_num = abs(int_num)

	# Small numbers (< 1000) - show raw value
	if abs_num < 1000:
		if decimal_places == 0:
			return str(int_num)
		return str(int_num)

	# Define thresholds and suffixes for big numbers
	# Supports up to int64 max (~10^18 quintillion)
	const THRESHOLDS = [
		1000000000000000000,  # 10^18 Quintillion (Qi)
		1000000000000000,     # 10^15 Quadrillion (Qa)
		1000000000000,        # 10^12 Trillion (T)
		1000000000,           # 10^9 Billion (B)
		1000000,              # 10^6 Million (M)
		1000                  # 10^3 Thousand (K)
	]

	const SUFFIXES = ["Qi", "Qa", "T", "B", "M", "K"]
	const DIVISORS = [
		1000000000000000000.0,
		1000000000000000.0,
		1000000000000.0,
		1000000000.0,
		1000000.0,
		1000.0
	]

	# Find appropriate suffix
	for i in range(THRESHOLDS.size()):
		if abs_num >= THRESHOLDS[i]:
			var value = abs_num / DIVISORS[i]
			var format_str = "%s%." + str(decimal_places) + "f%s"
			return format_str % [sign, value, SUFFIXES[i]]

	# Fallback
	return str(int_num)

## Format BigNumber with extended suffixes (up to 1az = 10^237)
func format_big(bn: BigNumber, decimal_places: int = 2) -> String:
	return bn.format(decimal_places)

## Create BigNumber from value
func to_big(value) -> BigNumber:
	return BigNumber.new(value)

## Parse string to BigNumber (e.g., "1.5Oc" -> BigNumber)
func parse(text: String) -> BigNumber:
	return BigNumber.from_string(text)

## Check if value would benefit from BigNumber
## Returns true if value > int64 max or needs extended suffixes
func needs_big_number(value) -> bool:
	if value is BigNumber:
		return value.exponent > 18

	var int_val = int(value) if value is float else value
	return abs(int_val) > 1000000000000000000  # > 10^18

## Convert int to BigNumber if it's very large
func auto_convert(value) -> BigNumber:
	if value is BigNumber:
		return value
	return BigNumber.new(value)

## Format with automatic BigNumber conversion for very large numbers
func format_auto(value, decimal_places: int = 2) -> String:
	if value is BigNumber:
		return format_big(value, decimal_places)

	# For regular numbers approaching int64 max, use BigNumber display
	var int_val = int(value) if value is float else value
	if abs(int_val) > 100000000000000000:  # > 10^17 (close to limit)
		var bn = BigNumber.new(int_val)
		return format_big(bn, decimal_places)

	return format(value, decimal_places)
