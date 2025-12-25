# Test Suite for Subroutine Defense

⚠️ **IMPORTANT DISCLAIMER**: These tests have been written but **NOT YET EXECUTED** in Godot. They may contain errors, incorrect API calls, or other issues. Please run the test suite in Godot and report any failures so they can be fixed.

This directory contains comprehensive tests for all major gameplay loops and systems.

## Test Structure

### Test Files

1. **TestBase.gd** - Base class providing assertion methods and test utilities
2. **TestEnemySpawning.gd** - Tests for enemy spawning, wave scaling, and enemy types
3. **TestCombat.gd** - Tests for tower shooting, damage calculation, and critical hits
4. **TestStatusEffects.gd** - Tests for burn, poison, slow, and stun effects
5. **TestUpgrades.gd** - Tests for upgrade system and progression
6. **TestResources.gd** - Tests for currency, rewards, and resource management
7. **RunAllTests.gd/tscn** - Main test runner to execute all test suites

## Running Tests

### Option 1: Run All Tests
```bash
# Open Godot and run the RunAllTests.tscn scene
# Or from command line:
godot --headless --path /home/user/subroutinedefense tests/RunAllTests.tscn
```

### Option 2: Run Individual Test Suites
You can instantiate and run individual test files in the Godot editor or via script:
```gdscript
var test = preload("res://tests/TestEnemySpawning.gd").new()
add_child(test)
# Tests will auto-run in _ready()
```

## Test Coverage

### ✅ Enemy System Tests
- Wave scaling (HP, damage, speed)
- Different enemy types
- Enemy movement toward tower
- Death mechanics
- Partial and lethal damage

### ✅ Combat System Tests
- Critical hit calculations
- Critical chance and damage multipliers
- Base damage and upgrades
- Fire rate mechanics
- Multi-target system
- Projectile behavior
- Tower health and shields
- Damage reduction

### ✅ Status Effects Tests
- **Burn**: Application, damage over time, scaling
- **Poison**: Application, percentage-based damage
- **Slow**: Movement reduction, scaling
- **Stun**: Application, movement prevention, duration
- Multiple simultaneous effects
- Effect expiration

### ✅ Upgrade System Tests
- Upgrade manager existence
- Reset functionality
- Damage upgrade progression and costs
- Fire rate upgrades
- Critical hit upgrades (chance + damage)
- Shield capacity and regeneration
- Damage reduction
- Multi-target upgrades
- Max level enforcement

### ✅ Resource Management Tests
- Data credits (basic currency)
- Archive tokens (permanent currency)
- Fragments (special currency)
- Enemy kill rewards
- Boss reward scaling
- Wave-based reward scaling
- Run statistics tracking
- Spending validation (can't overspend)

## Assertion Methods

The TestBase class provides comprehensive assertion methods:

```gdscript
assert_true(condition, message)
assert_false(condition, message)
assert_equal(actual, expected, message)
assert_not_equal(actual, expected, message)
assert_null(value, message)
assert_not_null(value, message)
assert_greater(actual, threshold, message)
assert_less(actual, threshold, message)
assert_in_range(value, min_val, max_val, message)
```

## Test Output Format

Each test outputs:
- ✅ PASS: Green checkmark for successful assertions
- ❌ FAIL: Red X for failed assertions
- ℹ️ INFO: Blue info for diagnostic messages
- Final summary with pass/fail counts

## Example Output

```
==========================================================
  TEST SUITE: Enemy Spawning & Wave Tests
==========================================================

▶ Running: test_enemy_wave_scaling
  ℹ️  INFO: Wave 1 HP: 12
  ✅ PASS: Wave 1: Enemy HP should be positive
  ℹ️  INFO: Wave 10 HP: 35
  ✅ PASS: Wave 10: HP should be higher than Wave 1
  ℹ️  INFO: Wave 50 HP: 135
  ✅ PASS: Wave 50: HP should be higher than Wave 10

...

==========================================================
  TEST RESULTS: Enemy Spawning & Wave Tests
==========================================================
✅ Passed: 15
❌ Failed: 0
📊 Total:  15

🎉 ALL TESTS PASSED!
==========================================================
```

## Adding New Tests

To add new tests:

1. Create a new file extending TestBase:
```gdscript
extends "res://tests/TestBase.gd"

func _init() -> void:
    super._init("My Test Suite Name")

func _ready() -> void:
    run_all_tests()

func test_my_feature() -> void:
    # Your test code here
    assert_equal(1 + 1, 2, "Math should work")
```

2. Add test methods prefixed with `test_`
3. Use assertion methods to validate behavior
4. Add your test file to RunAllTests.gd

## Best Practices

- **Name tests descriptively**: `test_enemy_wave_scaling` not `test1`
- **Test one thing**: Each test should verify a single behavior
- **Use log_info**: Provide diagnostic output for debugging
- **Clean up**: Use `cleanup_test_node()` to prevent memory leaks
- **Test edge cases**: Zero values, max values, invalid inputs
- **Document intent**: Comment what behavior you're testing

## Known Fixes Applied

During development, the following API mismatches were corrected:

- ✅ Fixed `UpgradeManager.reset_upgrades()` → `reset_run_upgrades()` (correct method)
- ✅ Fixed `RunStats.reset_stats()` → `RunStats.reset()` (correct method)
- ✅ Fixed `RunStats.enemies_killed` → `RunStats.data_credits_earned` (correct variable)
- ✅ Rewrote spending tests to manually check `data_credits >= cost` (no `can_afford()` method exists)
- ✅ Rewrote spending tests to manually subtract credits (no `spend_data_credits()` method exists)
- ✅ Fixed cost tests to check constant values instead of calling non-existent `get_damage_cost_for_level()`

**Note**: Additional issues may still exist. Run the tests in Godot to verify!

## Known Limitations

- **Tests have NOT been executed** - may contain additional errors
- Tests run sequentially (not parallel)
- Some tests require scene instantiation (slower)
- Visual/rendering effects are not tested
- Input/UI interactions are not tested
- Network/multiplayer features are not tested

## Future Test Ideas

- [ ] Drone behavior tests
- [ ] Save/load system tests
- [ ] Wave progression integration tests
- [ ] Performance benchmarks
- [ ] Stress tests (1000+ enemies)
- [ ] Game balance validation
- [ ] Achievement/unlock system tests
