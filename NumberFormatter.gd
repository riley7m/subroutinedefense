extends Node

## NumberFormatter - Singleton for formatting numbers with big number support
##
## Usage:
##   NumberFormatter.format(1500)  # "1.50K"
##   NumberFormatter.format(1500000000000)  # "1.50T"
##   NumberFormatter.format_big(BigNumber)  # For BigNumber objects

# Priority 2 optimization: Cache formatted numbers to avoid repeated string operations
var _format_cache: Dictionary = {}  # {value:decimal_places -> formatted_string}
var _cache_keys: Array = []  # Track insertion order for LRU eviction
const MAX_CACHE_SIZE := 100  # Limit cache size to prevent memory bloat

## Format regular int/float with suffix (up to int64 max ~10^18)
func format(num, decimal_places: int = 2) -> String:
	# Priority 2 optimization: Check cache first
	var cache_key = str(num) + ":" + str(decimal_places)
	if _format_cache.has(cache_key):
		return _format_cache[cache_key]
	if num is BigNumber:
		return num.format(decimal_places)

	# Convert to int if needed
	var int_num = int(num) if num is float else num

	# Handle negative numbers
	var sign = "" if int_num >= 0 else "-"
	var abs_num = abs(int_num)

	# Small numbers (< 1000) - show raw value
	if abs_num < 1000:
		var result = str(int_num)
		_cache_result(cache_key, result)
		return result

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
	var result: String
	for i in range(THRESHOLDS.size()):
		if abs_num >= THRESHOLDS[i]:
			var value = abs_num / DIVISORS[i]
			var format_str = "%s%." + str(decimal_places) + "f%s"
			result = format_str % [sign, value, SUFFIXES[i]]
			_cache_result(cache_key, result)
			return result

	# Fallback
	result = str(int_num)
	_cache_result(cache_key, result)
	return result

## Priority 2 optimization: Store result in cache with LRU eviction
func _cache_result(key: String, value: String) -> void:
	# Add to cache
	_format_cache[key] = value
	_cache_keys.append(key)

	# Evict oldest if cache is full (LRU)
	if _cache_keys.size() > MAX_CACHE_SIZE:
		var oldest_key = _cache_keys.pop_front()
		_format_cache.erase(oldest_key)

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
