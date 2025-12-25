extends Node

## TestBase - Base class for all gameplay tests
## Provides assertion methods and test utilities

class_name TestBase

var test_name: String = "UnnamedTest"
var tests_passed: int = 0
var tests_failed: int = 0
var current_test: String = ""

func _init(name: String = "TestBase") -> void:
	test_name = name

# ============================================================================
# ASSERTION METHODS
# ============================================================================

func assert_true(condition: bool, message: String = "") -> bool:
	if condition:
		_log_pass(message if message else "Assertion passed")
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected true, got false")
		tests_failed += 1
		return false

func assert_false(condition: bool, message: String = "") -> bool:
	if not condition:
		_log_pass(message if message else "Assertion passed")
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected false, got true")
		tests_failed += 1
		return false

func assert_equal(actual, expected, message: String = "") -> bool:
	if actual == expected:
		_log_pass(message if message else "Values are equal")
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s, got %s" % [expected, actual])
		tests_failed += 1
		return false

func assert_not_equal(actual, expected, message: String = "") -> bool:
	if actual != expected:
		_log_pass(message if message else "Values are not equal")
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected values to be different, both are %s" % [actual])
		tests_failed += 1
		return false

func assert_null(value, message: String = "") -> bool:
	if value == null:
		_log_pass(message if message else "Value is null")
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected null, got %s" % [value])
		tests_failed += 1
		return false

func assert_not_null(value, message: String = "") -> bool:
	if value != null:
		_log_pass(message if message else "Value is not null")
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected non-null value")
		tests_failed += 1
		return false

func assert_greater(actual, threshold, message: String = "") -> bool:
	if actual > threshold:
		_log_pass(message if message else "%s > %s" % [actual, threshold])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s > %s" % [actual, threshold])
		tests_failed += 1
		return false

func assert_less(actual, threshold, message: String = "") -> bool:
	if actual < threshold:
		_log_pass(message if message else "%s < %s" % [actual, threshold])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s < %s" % [actual, threshold])
		tests_failed += 1
		return false

func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> bool:
	if value >= min_val and value <= max_val:
		_log_pass(message if message else "%s is in range [%s, %s]" % [value, min_val, max_val])
		tests_passed += 1
		return true
	else:
		_log_fail(message if message else "Expected %s in range [%s, %s]" % [value, min_val, max_val])
		tests_failed += 1
		return false

# ============================================================================
# TEST LIFECYCLE
# ============================================================================

func run_test(test_func_name: String) -> void:
	current_test = test_func_name
	print("\n▶ Running: %s" % test_func_name)

	if has_method(test_func_name):
		call(test_func_name)
	else:
		_log_fail("Test method '%s' not found!" % test_func_name)

func run_all_tests() -> void:
	print("\n" + "=".repeat(60))
	print("  TEST SUITE: %s" % test_name)
	print("=".repeat(60))

	# Get all methods that start with "test_"
	var methods = get_method_list()
	var test_methods: Array = []

	for method in methods:
		if method.name.begins_with("test_"):
			test_methods.append(method.name)

	# Run all tests
	for test_method in test_methods:
		run_test(test_method)

	# Print summary
	print_summary()

func print_summary() -> void:
	print("\n" + "=".repeat(60))
	print("  TEST RESULTS: %s" % test_name)
	print("=".repeat(60))
	print("✅ Passed: %d" % tests_passed)
	print("❌ Failed: %d" % tests_failed)
	print("📊 Total:  %d" % (tests_passed + tests_failed))

	if tests_failed == 0:
		print("\n🎉 ALL TESTS PASSED!")
	else:
		print("\n⚠️  SOME TESTS FAILED")

	print("=".repeat(60) + "\n")

# ============================================================================
# LOGGING
# ============================================================================

func _log_pass(message: String) -> void:
	print("  ✅ PASS: %s" % message)

func _log_fail(message: String) -> void:
	print("  ❌ FAIL: %s" % message)

func log_info(message: String) -> void:
	print("  ℹ️  INFO: %s" % message)

# ============================================================================
# UTILITY METHODS
# ============================================================================

func wait_seconds(duration: float) -> void:
	await get_tree().create_timer(duration).timeout

func create_test_node(node_type: String) -> Node:
	var node: Node
	match node_type:
		"Node2D":
			node = Node2D.new()
		"CharacterBody2D":
			node = CharacterBody2D.new()
		"Area2D":
			node = Area2D.new()
		_:
			node = Node.new()

	add_child(node)
	return node

func cleanup_test_node(node: Node) -> void:
	if node and is_instance_valid(node):
		if node.is_inside_tree():
			remove_child(node)
		node.queue_free()
