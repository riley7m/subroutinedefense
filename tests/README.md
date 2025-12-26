# Automated Test Suite

Comprehensive test coverage for Subroutine Defense game systems.

## Running Tests

### Via Godot Editor

1. Open `tests/RunAllTests.tscn` scene
2. Press F5 or click "Run Current Scene"
3. View test results in Output console

### Via Command Line

```bash
godot --headless --script tests/RunAllTests.gd
```

## Test Suites

### 1. TestUpgrades.gd
**Coverage:** In-run upgrade system (DC-based)

**Tests:**
- Upgrade manager initialization
- Damage upgrade progression
- Fire rate upgrades
- Crit chance and damage upgrades
- Shield capacity and regen
- Multi-target system
- Upgrade cost calculations
- Maximum level bounds

### 2. TestEconomy.gd ✨ (New)
**Coverage:** Currency formulas and progression math

**Tests:**
- Wave scaling formula (1.0 + wave * 0.02)
- Wave AT bonus polynomial (0.25 * wave^1.15)
- Enemy base rewards (DC and AT)
- Tier multiplier (5^tier)
- Permanent upgrade cost scaling (1.13^level)
- In-run upgrade cost scaling (1.15^purchases)
- Boss Rush HP scaling (1.13^wave * 5.0)
- Fragment reward calculations
- Lab cost scaling (1.08^level)
- Offline progress efficiency (25% / 50%)
- Integer overflow safety tests

### 3. TestConfig.gd ✨ (New)
**Coverage:** Configuration loading system

**Tests:**
- ConfigLoader singleton initialization
- game_balance.json file loading
- All config sections (upgrades, rewards, boss rush, labs, etc.)
- Config reload functionality

### 4. TestSaveLoad.gd ✨ (New)
**Coverage:** Save/load system integrity

**Tests:**
- Save data generation
- Currency value bounds
- Upgrade level validation
- Lab state consistency
- Cloud save validation rules

## Test Coverage Summary

| System | Coverage | Test File |
|--------|----------|-----------|
| In-Run Upgrades | ✅ 100% | TestUpgrades.gd |
| Economy Formulas | ✅ 100% | TestEconomy.gd |
| Configuration | ✅ 100% | TestConfig.gd |
| Save/Load | ✅ 90% | TestSaveLoad.gd |
| Enemy Spawning | ⚠️ 20% | TestEnemySpawning.gd |
| Combat | ⚠️ 20% | TestCombat.gd |
| Status Effects | ⚠️ 10% | TestStatusEffects.gd |
| Resources | ⚠️ 30% | TestResources.gd |

**Overall Coverage:** ~60%

## Before Launch Checklist

Run these critical tests before releasing:

1. **Economy Balance**
   - TestEconomy (all formulas)
2. **Save Integrity**
   - TestSaveLoad (validation)
3. **Overflow Prevention**
   - TestEconomy (extreme levels)
4. **Configuration**
   - TestConfig (all sections)

---

**Last Updated:** 2025-12-26
**Total Tests:** ~150 test functions
