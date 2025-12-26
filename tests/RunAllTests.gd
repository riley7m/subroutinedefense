extends Node

## RunAllTests - Main test runner script
## Run this scene to execute all gameplay tests

func _ready() -> void:
	print("\n")
	print("╔════════════════════════════════════════════════════════════╗")
	print("║                                                            ║")
	print("║          SUBROUTINE DEFENSE - TEST SUITE                  ║")
	print("║                                                            ║")
	print("╚════════════════════════════════════════════════════════════╝")
	print("\n")

	# Run all test suites
	await run_all_test_suites()

	print("\n")
	print("╔════════════════════════════════════════════════════════════╗")
	print("║                                                            ║")
	print("║               ALL TEST SUITES COMPLETED                    ║")
	print("║                                                            ║")
	print("╚════════════════════════════════════════════════════════════╝")
	print("\n")

	# Exit after tests
	await get_tree().create_timer(1.0).timeout
	print("Exiting test runner...")
	get_tree().quit()

func run_all_test_suites() -> void:
	# List of all test scripts
	var test_scripts = [
		"res://tests/TestEnemySpawning.gd",
		"res://tests/TestCombat.gd",
		"res://tests/TestStatusEffects.gd",
		"res://tests/TestUpgrades.gd",
		"res://tests/TestResources.gd",
		"res://tests/TestEconomy.gd",
		"res://tests/TestConfig.gd",
		"res://tests/TestSaveLoad.gd"
	]

	for test_script_path in test_scripts:
		await run_test_suite(test_script_path)

func run_test_suite(script_path: String) -> void:
	# Load and instantiate test script
	var test_script = load(script_path)
	if not test_script:
		print("❌ Failed to load test script: %s" % script_path)
		return

	var test_instance = test_script.new()
	add_child(test_instance)

	# Wait for tests to complete (tests run in _ready)
	await get_tree().create_timer(0.5).timeout

	# Remove test instance
	remove_child(test_instance)
	test_instance.queue_free()

	# Small delay between test suites
	await get_tree().create_timer(0.3).timeout
