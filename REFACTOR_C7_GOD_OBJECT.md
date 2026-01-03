# C7 God Object Refactoring Analysis - main_hud.gd

## Issue Summary

**File:** main_hud.gd
**Lines:** 1,694
**Functions:** 62
**Responsibilities:** 17+
**Severity:** CRITICAL (C7)

main_hud.gd is a massive god object that violates the Single Responsibility Principle. It handles UI rendering, business logic, state management, panel coordination, drone management, statistics display, and scene transitions all in one file.

---

## Current Structure Analysis

### 1. State Variables (Lines 3-165)
**Lines:** 162
**Variables:** 50+

**Issues:**
- Mixes wave state, UI references, drone tracking, and panel visibility
- 45-line hardcoded `perm_nodes` dictionary (lines 20-65)
- 10+ panel/button references scattered throughout
- No clear separation between state and UI references

**Example:**
```gdscript
# Wave state mixed with UI state
var wave: int = 1
var current_wave: int = 1
var wave_number: int = 1  # DUPLICATE of current_wave!
var tower_hp: int = 1000
var wave_timer: float = 0.0

# Massive hardcoded UI references
@onready var perm_nodes = {
    "projectile_damage": {
        "level": $PermUpgradesPanel/PermUpgradesList/PermProjectileDamage/PermProjectileDamageLevel,
        "button": $PermUpgradesPanel/PermUpgradesList/PermProjectileDamage/PermProjectileDamageButton,
    },
    # ... 45 more lines of this!
}
```

---

### 2. Initialization (_ready) (Lines 168-393)
**Lines:** 225
**Issues:**
- Creates 8 UI panels programmatically
- Creates 8 buttons with manual positioning (hardcoded coordinates)
- Connects 25+ signals
- Mixes UI construction with game initialization

**Example of manual UI construction:**
```gdscript
software_upgrade_button = Button.new()
software_upgrade_button.text = "🔬 Labs"
software_upgrade_button.position = Vector2(8, 755)  # Hardcoded position!
software_upgrade_button.custom_minimum_size = Vector2(90, 35)
software_upgrade_button.pressed.connect(_on_software_upgrade_button_pressed)
add_child(software_upgrade_button)
```

This is done 8 times for different buttons. Should be data-driven.

---

### 3. In-Run Upgrade Button Handlers (Lines 448-812)
**Lines:** 364
**Functions:** 11
**Code Duplication:** ~95%

**THE WORST OFFENDER:** All 11 handlers follow identical pattern:

```gdscript
func _on_damage_upgrade_pressed() -> void:
    var amount = get_current_buy_amount()
    if amount == -1:
        while UpgradeManager.upgrade_projectile_damage():
            pass
    else:
        for i in range(amount):
            if not UpgradeManager.upgrade_projectile_damage():
                break
    update_damage_label()
    if tower and is_instance_valid(tower):
        tower.update_visual_tier()

func _on_fire_rate_upgrade_pressed() -> void:
    var amount = get_current_buy_amount()
    if amount == -1:
        while UpgradeManager.upgrade_fire_rate():
            pass
    else:
        for i in range(amount):
            if not UpgradeManager.upgrade_fire_rate():
                break
    if tower and is_instance_valid(tower):
        tower.refresh_fire_rate()
        tower.update_visual_tier()
    update_labels()

# ... 9 MORE IDENTICAL FUNCTIONS
```

**Quick Win:** Replace all 11 handlers with generic handler + lookup table.

---

### 4. UI Update Functions (Lines 545-716)
**Lines:** 171
**Functions:** 4
**Code Duplication:** ~90%

Each category (offense/defense/economy) has identical per-button update logic:

```gdscript
func update_offense_upgrade_ui() -> void:
    var dc = RewardManager.data_credits
    var buy_amount = get_current_buy_amount()

    # Damage upgrade
    var damage_cost: int
    var damage_text: String
    if buy_amount == -1:
        var arr = get_inrun_max_affordable(UpgradeManager.DAMAGE_UPGRADE_BASE_COST, UpgradeManager.damage_purchases)
        damage_cost = arr[1]
        damage_text = "Damage x%d (%s DC)" % [arr[0], NumberFormatter.format(damage_cost)]
    else:
        damage_cost = get_inrun_total_cost(UpgradeManager.DAMAGE_UPGRADE_BASE_COST, UpgradeManager.damage_purchases, buy_amount)
        damage_text = "Damage x%d (%s DC)" % [buy_amount, NumberFormatter.format(damage_cost)]
    damage_upgrade.text = damage_text
    damage_upgrade.disabled = dc < damage_cost or damage_cost == 0

    # Fire rate upgrade (EXACT SAME PATTERN)
    var fire_rate_cost: int
    var fire_rate_text: String
    if buy_amount == -1:
        var arr = get_inrun_max_affordable(UpgradeManager.FIRE_RATE_UPGRADE_BASE_COST, UpgradeManager.fire_rate_purchases)
        # ... same logic repeated
```

This pattern is duplicated **11 times** for 11 different upgrades across 3 functions.

**Quick Win:** Create generic button update function with upgrade metadata.

---

### 5. Statistics Panel (Lines 1307-1638)
**Lines:** 331
**Functions:** 6

**Issues:**
- 190-line `_create_statistics_panel()` function constructs entire UI manually
- Creates 20+ labels programmatically
- No separation between UI construction and data display
- Hardcoded positioning for all elements

**Example:**
```gdscript
func _create_statistics_panel() -> void:
    # Create panel (fits 390px mobile screen)
    statistics_panel = Panel.new()
    statistics_panel.custom_minimum_size = Vector2(360, 700)
    statistics_panel.position = Vector2(15, 50)

    # Create 20+ labels manually
    var dc_stat = Label.new()
    dc_stat.name = "DCStatLabel"
    dc_stat.text = "Data Credits: 0"
    dc_stat.custom_minimum_size = Vector2(320, 20)
    vbox.add_child(dc_stat)

    # ... 150 more lines of this!
```

**Should be:** Scene-based UI with data binding.

---

## Responsibilities Breakdown

| Responsibility | Lines | Functions | Should Extract? |
|---|---|---|---|
| **Wave State Management** | ~30 | 2 | ✅ YES → WaveController |
| **Currency Display** | ~50 | 2 | ✅ YES → CurrencyUI |
| **In-Run Upgrade UI** | ~550 | 15 | ✅ YES → InRunUpgradePanel |
| **Permanent Upgrade UI** | ~100 | 4 | ✅ YES → PermanentUpgradePanel |
| **Drone Spawning** | ~40 | 2 | ✅ YES → DroneManager |
| **Drone Purchase UI** | ~90 | 3 | ✅ YES → DronePurchasePanel |
| **Statistics Panel** | ~330 | 6 | ✅ YES → StatisticsPanel |
| **Panel Management** | ~100 | 11 | ✅ YES → PanelManager |
| **Speed Control** | ~15 | 2 | ⚠️ MAYBE → GameSettings |
| **Buy Amount Selection** | ~20 | 2 | ❌ NO (too small) |
| **Bulk Purchase Calculations** | ~80 | 5 | ✅ YES → BulkPurchaseCalculator |
| **Scene Transitions** | ~150 | 4 | ✅ YES → GameStateManager |
| **Tower References** | scattered | N/A | ⚠️ Use signals instead |
| **Spawner References** | scattered | N/A | ⚠️ Use signals instead |

**Total extractable:** 1,555 lines (~92% of file)
**Remaining in main_hud.gd:** ~140 lines (orchestration only)

---

## Proposed Extraction Plan

### Phase 1: Quick Wins (Eliminate Duplication)

**1.1 Generic In-Run Upgrade Handler**
**Effort:** 1 hour
**Impact:** Eliminates 350+ lines

Replace 11 button handlers with:

```gdscript
# Upgrade metadata lookup table
const UPGRADE_ACTIONS = {
    "damage": {
        "upgrade_func": "upgrade_projectile_damage",
        "post_action": "update_visual_tier",
        "target": "tower"
    },
    "fire_rate": {
        "upgrade_func": "upgrade_fire_rate",
        "post_action": ["refresh_fire_rate", "update_visual_tier"],
        "target": "tower"
    },
    # ... rest of upgrades
}

func _handle_inrun_upgrade(upgrade_key: String) -> void:
    var action = UPGRADE_ACTIONS[upgrade_key]
    var amount = get_current_buy_amount()

    if amount == -1:
        while UpgradeManager.call(action.upgrade_func):
            pass
    else:
        for i in range(amount):
            if not UpgradeManager.call(action.upgrade_func):
                break

    # Execute post-actions (tower refresh, visual updates)
    if action.has("post_action"):
        var target = get(action.target)
        if target and is_instance_valid(target):
            var post = action.post_action
            if post is String:
                target.call(post)
            elif post is Array:
                for method in post:
                    target.call(method)

    update_labels()

# Connect all buttons to generic handler
damage_upgrade.pressed.connect(_handle_inrun_upgrade.bind("damage"))
fire_rate_upgrade.pressed.connect(_handle_inrun_upgrade.bind("fire_rate"))
# ... etc
```

**1.2 Generic UI Update Function**
**Effort:** 1 hour
**Impact:** Eliminates 150+ lines

Replace 3 category update functions with:

```gdscript
# Upgrade button metadata
const UPGRADE_BUTTONS = {
    "damage": {
        "button": "damage_upgrade",
        "base_cost": "DAMAGE_UPGRADE_BASE_COST",
        "purchases": "damage_purchases",
        "label": "Damage",
        "category": "offense"
    },
    # ... rest of buttons
}

func update_upgrade_button(upgrade_key: String) -> void:
    var meta = UPGRADE_BUTTONS[upgrade_key]
    var button = get(meta.button)
    var dc = RewardManager.data_credits
    var buy_amount = get_current_buy_amount()
    var base_cost = UpgradeManager.get(meta.base_cost)
    var purchases = UpgradeManager.get(meta.purchases)

    var cost: int
    var text: String

    if buy_amount == -1:
        var arr = get_inrun_max_affordable(base_cost, purchases)
        cost = arr[1]
        text = "%s x%d (%s DC)" % [meta.label, arr[0], NumberFormatter.format(cost)]
    else:
        cost = get_inrun_total_cost(base_cost, purchases, buy_amount)
        text = "%s x%d (%s DC)" % [meta.label, buy_amount, NumberFormatter.format(cost)]

    button.text = text
    button.disabled = dc < cost or cost == 0

func update_all_inrun_upgrade_ui() -> void:
    for upgrade_key in UPGRADE_BUTTONS.keys():
        update_upgrade_button(upgrade_key)
```

---

### Phase 2: Extract Panels (Modular Architecture)

**2.1 Extract InRunUpgradePanel.gd**
**Effort:** 3 hours
**Lines extracted:** ~550

**Responsibilities:**
- Manage offense/defense/economy panel visibility
- Handle all in-run upgrade button presses
- Update button text/cost/disabled state
- Display multi-target upgrade UI

**Interface:**
```gdscript
class_name InRunUpgradePanel
extends Control

signal upgrade_purchased(upgrade_key: String, amount: int)

func update_all_buttons() -> void
func show_category(category: String) -> void  # "offense", "defense", "economy"
func hide_all() -> void
```

**2.2 Extract PermanentUpgradePanel.gd**
**Effort:** 2 hours
**Lines extracted:** ~100

**Responsibilities:**
- Manage permanent upgrade buttons
- Handle permanent upgrade purchases
- Update AT costs and levels

**Interface:**
```gdscript
class_name PermanentUpgradePanel
extends Control

signal perm_upgrade_purchased(upgrade_key: String, amount: int)

func update_all_buttons() -> void
func show() -> void
func hide() -> void
```

**2.3 Extract StatisticsPanel.gd**
**Effort:** 2 hours
**Lines extracted:** ~330

**Responsibilities:**
- Display lifetime stats (currency, kills, spending)
- Format numbers for display
- Handle account binding UI

**Interface:**
```gdscript
class_name StatisticsPanel
extends Panel

func show_statistics() -> void
func update_statistics() -> void
func close() -> void
```

**Should be:** Convert to .tscn scene with data binding instead of programmatic UI construction.

**2.4 Extract DronePurchasePanel.gd**
**Effort:** 1 hour
**Lines extracted:** ~90

**Responsibilities:**
- Display drone purchase UI (flame, frost, poison, shock)
- Handle fragment purchases
- Update ownership status

**2.5 Extract PanelManager.gd**
**Effort:** 1 hour
**Lines extracted:** ~100

**Responsibilities:**
- Coordinate showing/hiding of all panels
- Ensure only one panel visible at a time
- Handle panel z-ordering

**Interface:**
```gdscript
class_name PanelManager
extends Node

func show_panel(panel_name: String) -> void
func hide_all_panels() -> void
func register_panel(panel_name: String, panel: Control) -> void
```

---

### Phase 3: Extract Managers (Business Logic)

**3.1 Extract DroneManager.gd**
**Effort:** 2 hours
**Lines extracted:** ~80

**Responsibilities:**
- Spawn owned drones at run start
- Track active drones
- Refresh drone stats when upgraded
- Position drones around tower

**Interface:**
```gdscript
class_name DroneManager
extends Node

signal drone_spawned(drone_type: String, drone: Node2D)

func spawn_owned_drones(tower_position: Vector2) -> void
func refresh_all_drones() -> void
func cleanup_drones() -> void
```

**3.2 Extract BulkPurchaseCalculator.gd**
**Effort:** 1 hour
**Lines extracted:** ~80

**Responsibilities:**
- Calculate total cost for X upgrades
- Calculate max affordable upgrades
- Handle both in-run and permanent upgrades

**Interface:**
```gdscript
class_name BulkPurchaseCalculator
extends Node

static func get_inrun_total_cost(base_cost: int, current_purchases: int, amount: int) -> int
static func get_inrun_max_affordable(base_cost: int, current_purchases: int, currency: int) -> Array
static func get_perm_total_cost(key: String, amount: int) -> int
static func get_perm_max_affordable(key: String, currency: int) -> Array
```

**3.3 Extract GameStateManager.gd**
**Effort:** 2 hours
**Lines extracted:** ~150

**Responsibilities:**
- Handle scene transitions (quit, tier reset, boss rush)
- Reset game state for new runs
- Coordinate reset across multiple systems

**Interface:**
```gdscript
class_name GameStateManager
extends Node

signal state_changed(new_state: String)

func reset_to_wave_1() -> void
func start_boss_rush() -> void
func exit_boss_rush() -> void
func quit_to_menu() -> void
```

---

## Architectural Improvements

### Replace Direct References with Signals

**Current (BAD):**
```gdscript
# main_hud.gd directly calls tower methods
tower.refresh_fire_rate()
tower.update_visual_tier()
tower.refresh_shield_stats()
```

**Proposed (GOOD):**
```gdscript
# Tower listens to signals from UpgradeManager
UpgradeManager.fire_rate_upgraded.connect(tower.refresh_fire_rate)
UpgradeManager.damage_upgraded.connect(tower.update_visual_tier)
UpgradeManager.shield_upgraded.connect(tower.refresh_shield_stats)
```

**Benefits:**
- Decouples main_hud from tower
- Allows tower to react to upgrades independently
- Easier to test (mock signals)

---

### Convert Programmatic UI to Scenes

**Current (BAD):**
```gdscript
# 190 lines of manual UI construction in _ready()
var dc_stat = Label.new()
dc_stat.name = "DCStatLabel"
dc_stat.text = "Data Credits: 0"
dc_stat.custom_minimum_size = Vector2(320, 20)
vbox.add_child(dc_stat)
UIStyler.apply_theme_to_node(dc_stat)
```

**Proposed (GOOD):**
1. Create StatisticsPanel.tscn in Godot editor
2. Use @export variables for data binding
3. Load scene in main_hud.gd:

```gdscript
var statistics_panel = preload("res://StatisticsPanel.tscn").instantiate()
add_child(statistics_panel)
statistics_panel.update_data(RunStats)
```

**Benefits:**
- Visual editing in Godot editor
- Easier layout management
- Clearer separation of UI and logic

---

### Data-Driven Button Creation

**Current (BAD):**
```gdscript
# 8 manually created buttons with hardcoded positions
software_upgrade_button = Button.new()
software_upgrade_button.text = "🔬 Labs"
software_upgrade_button.position = Vector2(8, 755)
software_upgrade_button.custom_minimum_size = Vector2(90, 35)
software_upgrade_button.pressed.connect(_on_software_upgrade_button_pressed)
add_child(software_upgrade_button)

tier_selection_button = Button.new()
tier_selection_button.text = "🎖️ Tiers"
tier_selection_button.position = Vector2(103, 755)
# ... etc
```

**Proposed (GOOD):**
```gdscript
const BOTTOM_MENU_BUTTONS = [
    # Row 1
    {"text": "🔬 Labs", "panel": "software_upgrade", "pos": Vector2(8, 755)},
    {"text": "🎖️ Tiers", "panel": "tier_selection", "pos": Vector2(103, 755)},
    {"text": "🏆 Rush", "panel": "boss_rush", "pos": Vector2(198, 755)},
    {"text": "📊 Stats", "panel": "statistics", "pos": Vector2(293, 755)},
    # Row 2
    {"text": "🚁 Drones", "panel": "drone_upgrade", "pos": Vector2(8, 800)},
    {"text": "💎 Shop", "panel": "qc_shop", "pos": Vector2(103, 800)},
    {"text": "🎖️ Pass", "panel": "milestone", "pos": Vector2(198, 800)},
    {"text": "🏆 Achieve", "panel": "achievement", "pos": Vector2(293, 800)},
]

func _create_bottom_menu() -> void:
    for btn_data in BOTTOM_MENU_BUTTONS:
        var button = Button.new()
        button.text = btn_data.text
        button.position = btn_data.pos
        button.custom_minimum_size = Vector2(90, 35)
        button.pressed.connect(panel_manager.show_panel.bind(btn_data.panel))
        add_child(button)
```

---

## File Size Reduction Estimate

| Component | Current Lines | After Refactor | Reduction |
|---|---|---|---|
| **main_hud.gd (orchestration only)** | 1,694 | 140 | -1,554 (-92%) |
| **InRunUpgradePanel.gd** | 0 | 200 | +200 |
| **PermanentUpgradePanel.gd** | 0 | 100 | +100 |
| **StatisticsPanel.gd** | 0 | 150 | +150 |
| **DronePurchasePanel.gd** | 0 | 80 | +80 |
| **PanelManager.gd** | 0 | 60 | +60 |
| **DroneManager.gd** | 0 | 80 | +80 |
| **BulkPurchaseCalculator.gd** | 0 | 80 | +80 |
| **GameStateManager.gd** | 0 | 120 | +120 |
| **Total Lines of Code** | 1,694 | 1,010 | -684 (-40%) |

**Net reduction:** 684 lines eliminated through deduplication and better architecture.

---

## Testing Strategy

### Before Refactoring
1. Document all upgrade button behaviors
2. Screenshot all panel layouts
3. Test all 11 upgrade purchases (x1, x5, x10, Max)
4. Test all panel show/hide sequences
5. Test boss rush start/exit
6. Test tier reset

### During Refactoring
1. Extract one component at a time
2. Run tests after each extraction
3. Use signals to decouple components
4. Maintain backward compatibility

### After Refactoring
1. Verify all upgrade purchases work identically
2. Verify all panels show/hide correctly
3. Performance test (should be neutral or better)
4. Code review for maintainability

---

## Implementation Priority

### ✅ QUICK WINS (Do First - High Impact, Low Effort)
1. **Generic In-Run Upgrade Handler** (1 hour, -350 lines)
2. **Generic UI Update Function** (1 hour, -150 lines)

**Total Phase 1:** 2 hours, -500 lines

### ⚠️ MEDIUM EFFORT (Do Second - High Impact, Medium Effort)
3. **Extract BulkPurchaseCalculator.gd** (1 hour, -80 lines)
4. **Extract DroneManager.gd** (2 hours, -80 lines)
5. **Extract DronePurchasePanel.gd** (1 hour, -90 lines)
6. **Extract PanelManager.gd** (1 hour, -100 lines)

**Total Phase 2:** 5 hours, -350 lines

### 🚧 LARGE EFFORT (Do Last - Highest Impact, Highest Effort)
7. **Extract InRunUpgradePanel.gd** (3 hours, -550 lines)
8. **Extract PermanentUpgradePanel.gd** (2 hours, -100 lines)
9. **Extract StatisticsPanel.gd** (2 hours, -330 lines)
10. **Extract GameStateManager.gd** (2 hours, -150 lines)

**Total Phase 3:** 9 hours, -1,130 lines

---

## Risks and Mitigation

### Risk 1: Breaking Existing Functionality
**Mitigation:**
- Extract one component at a time
- Test thoroughly after each extraction
- Keep git commits small and focused
- Easy to revert if issues found

### Risk 2: Signal Coupling Complexity
**Mitigation:**
- Document all signals in each component
- Use typed signals where possible
- Create signal connection diagram

### Risk 3: Performance Regression
**Mitigation:**
- Profile before and after
- Signals have minimal overhead
- Reduced code size may improve cache performance

### Risk 4: UI Layout Changes
**Mitigation:**
- Convert to .tscn scenes preserves exact layout
- Screenshot comparison before/after
- Pixel-perfect positioning with scene editor

---

## Conclusion

main_hud.gd is a **critical-severity god object** with 17+ responsibilities crammed into 1,694 lines. The file violates Single Responsibility Principle extensively, with **~90% code duplication** in upgrade handlers and UI updates.

**Recommended approach:**
1. **Phase 1 (Quick Wins):** 2 hours to eliminate 500 lines of duplication
2. **Phase 2 (Medium Effort):** 5 hours to extract managers and utilities
3. **Phase 3 (Large Effort):** 9 hours to fully modularize panels

**Total effort:** ~16 hours
**Total reduction:** 684 lines (-40%)
**Maintainability improvement:** Massive (god object → 8 focused components)

**Next steps:**
1. Get user approval for refactoring scope
2. Start with Phase 1 (quick wins) to prove value
3. Continue with Phase 2/3 based on results
