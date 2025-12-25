# Offline Progress & Lab System Audit

## Executive Summary

**STATUS: NOT IMPLEMENTED**

Neither offline/background progress nor a lab system currently exist in the codebase. This document outlines the current state, identifies risks, and proposes implementation strategies.

---

## 🔍 Audit Findings

### 1. Offline / Background Progress System

#### **Current State: DOES NOT EXIST**

**What's Missing:**
- ❌ No time tracking (last played timestamp)
- ❌ No offline simulation
- ❌ No background progress calculations
- ❌ No catchup mechanics when returning to the game

**What EXISTS (but not used for offline):**
- ✅ Save/load system for permanent upgrades (RewardManager.gd:140-207)
- ✅ Speed multiplier system via `Engine.time_scale` (main_hud.gd:82-85, 469-478)
- ✅ Wave progression system (spawner.gd, main_hud.gd)
- ✅ Currency and reward systems (RewardManager.gd)

**Critical Gap:**
When a player closes the game and returns, they resume exactly where they left off with ZERO progress made during absence. This is a major missing feature for an idle/incremental game.

---

### 2. Speed Multipliers - Offline Accuracy Audit

#### **Current Implementation:**

```gdscript
# main_hud.gd:82-85
var speed_levels := [1.0, 2.0, 3.0, 4.0]
var current_speed_index := 0

# main_hud.gd:469-474
func _on_speed_button_pressed() -> void:
    current_speed_index = (current_speed_index + 1) % speed_levels.size()
    var new_speed = speed_levels[current_speed_index]
    Engine.time_scale = new_speed
```

**Analysis:**
- ✅ **ACCURATE** for real-time play
- ❌ **NOT APPLICABLE** to offline (no offline system exists)
- ⚠️ **RISK:** When offline is implemented, speed setting is NOT saved
- ⚠️ **RISK:** Unclear if offline should use last active speed or base speed

**Recommendation:**
1. Save current speed level to save file
2. Decide policy: offline at 1x or last active speed?
3. Add speed multiplier to offline calculations

---

### 3. Wave Skipping - Offline Accuracy Audit

#### **Current Implementation:**

```gdscript
# spawner.gd:138-141
func should_skip_wave() -> bool:
    var chance = UpgradeManager.get_wave_skip_chance()
    var roll = randf() * 100.0
    return roll < chance

# spawner.gd:42-47 (called in start_wave)
if should_skip_wave():
    print("⏩ Wave", actual_wave, "skipped due to Wave Skip Chance!")
    actual_wave += 1
```

**Analysis:**
- ✅ **ACCURATE** for real-time play (RNG per wave)
- ❌ **NOT APPLICABLE** to offline (no offline system exists)
- ⚠️ **CRITICAL RISK FOR OFFLINE:** RNG-based mechanics are hard to simulate accurately

**Offline Wave Skip Challenges:**
1. **RNG Determinism:** Can't replay same RNG sequence offline
2. **Fairness:** Should offline get same skip chance?
3. **Expected Value:** Could use statistical average instead
   - Example: 5% skip chance = skip 1 wave every 20 waves on average

**Recommendation:**
- For offline calculations, use **expected value** (deterministic)
- Formula: `waves_completed_offline = actual_waves * (1 + wave_skip_chance/100)`
- Example: 100 waves with 5% skip = progress 105 waves
- This avoids RNG manipulation while being fair

---

### 4. Drone Behavior - Offline Accuracy Audit

#### **Current Implementation:**

```gdscript
# drone_base.gd:7-15
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
    fire_timer.wait_time = fire_interval
    fire_timer.timeout.connect(_on_fire_timer_timeout)
    fire_timer.start()

func _on_fire_timer_timeout() -> void:
    var target = pick_target()
    if target:
        fire_at(target)
```

**Drone Types (all timer-based):**
- drone_flame.gd - Fire interval timer
- drone_frost.gd - Fire interval timer
- drone_poison.gd - Fire interval timer
- drone_shock.gd - Fire interval timer

**Analysis:**
- ✅ **ACCURATE** for real-time play (Timer nodes)
- ❌ **NOT APPLICABLE** to offline (Timers don't run when game closed)
- ⚠️ **MAJOR RISK:** Drones do NOTHING offline

**Offline Drone Challenges:**
1. **Targeting:** Offline simulation has no enemies to target
2. **Status Effects:** Burn/poison DOT needs enemies alive
3. **Damage Output:** Need to estimate contribution to wave clear

**Recommendation:**
- **Option A (Simple):** Drones grant flat % damage boost in offline calculation
  - Example: Each drone level = +10% effective damage offline
- **Option B (Accurate):** Simulate drone DPS * time_offline
  - Requires complex combat simulation
  - May not match real-time results due to targeting/overkill
- **Option C (Hybrid):** Use historical data
  - Track "drone contribution %" from last 10 waves played
  - Apply that multiplier to offline waves

---

### 5. Lab System - Implementation Audit

#### **Current State: DOES NOT EXIST**

**No files found matching:**
- lab*.gd
- research*.gd
- project*.gd (besides project.godot)

**Analysis:**
- ❌ No lab system implemented
- ❌ No research tree
- ❌ No long-duration projects
- ❌ No branching upgrade paths

**What the user mentions:**
> "Lab refactor fixed correctness" - **This doesn't exist in codebase**
> "Lab content depth is shallow" - **Can't be shallow if it doesn't exist**

**Hypothesis:** Either:
1. Lab system was planned but never implemented
2. Lab system was removed/rolled back
3. User is referring to a different project/branch
4. "Lab" is a metaphor for the upgrade system

---

## 🚨 Critical Risks

### Offline Progress Desync Risks

| Risk | Severity | Description |
|------|----------|-------------|
| **No offline system** | 🔴 CRITICAL | Players get ZERO progress when away |
| **Speed not saved** | 🟡 MEDIUM | Can't determine offline speed multiplier |
| **Wave skip RNG** | 🟠 HIGH | Can't accurately replicate skip chance offline |
| **Drone inactivity** | 🟠 HIGH | Drones contribute 0% to offline progress |
| **Silent desync** | 🔴 CRITICAL | No system = no desync detection possible |

---

## ✅ Proposed Implementation

### Phase 1: Basic Offline Progress

**Add to RewardManager.gd save data:**
```gdscript
var last_play_time: int = 0  # Unix timestamp
var last_speed_multiplier: float = 1.0
```

**On game close (save):**
```gdscript
func save_permanent_upgrades():
    data["last_play_time"] = Time.get_unix_time_from_system()
    data["last_speed_multiplier"] = current_speed  # from main_hud
```

**On game open (load):**
```gdscript
func calculate_offline_progress():
    if last_play_time == 0:
        return  # First time playing

    var now = Time.get_unix_time_from_system()
    var seconds_away = now - last_play_time

    # Cap at 24 hours (prevent exploits)
    seconds_away = min(seconds_away, 86400)

    if seconds_away < 60:
        return  # Ignore <1 minute absences

    # Calculate offline gains
    simulate_offline_progress(seconds_away)
```

---

### Phase 2: Offline Wave Simulation

**Deterministic offline calculation:**

```gdscript
func simulate_offline_progress(seconds: float):
    # Constants (tune based on playtesting)
    const AVG_WAVE_DURATION = 10.0  # seconds per wave (estimate)

    # Get player power
    var damage = UpgradeManager.get_total_damage()
    var fire_rate = UpgradeManager.get_fire_rate()
    var dps = damage * fire_rate

    # Get upgrades
    var wave_skip_chance = UpgradeManager.get_wave_skip_chance()
    var dc_multiplier = RewardManager.get_data_credit_multiplier()
    var at_multiplier = RewardManager.get_archive_token_multiplier()

    # Calculate waves cleared (simplified)
    var time_multiplier = 1.0  # Use 1x for offline, or last_speed_multiplier
    var effective_time = seconds * time_multiplier
    var waves_cleared = floor(effective_time / AVG_WAVE_DURATION)

    # Apply wave skip (expected value, not RNG)
    var skip_multiplier = 1.0 + (wave_skip_chance / 100.0)
    waves_cleared = floor(waves_cleared * skip_multiplier)

    # Cap waves to prevent runaway progression
    waves_cleared = min(waves_cleared, 1000)

    # Calculate rewards (simplified - no per-enemy drops)
    var dc_earned = calculate_offline_dc(waves_cleared, dc_multiplier)
    var at_earned = calculate_offline_at(waves_cleared, at_multiplier)

    # Grant rewards
    RewardManager.data_credits += dc_earned
    RewardManager.archive_tokens += at_earned

    # Show popup to player
    show_offline_progress_popup(waves_cleared, dc_earned, at_earned, seconds)
```

---

### Phase 3: Drone Offline Contribution

**Option A: Flat multiplier (RECOMMENDED)**

```gdscript
# Add to offline calculation
var drone_multiplier = 1.0
drone_multiplier += RewardManager.perm_drone_flame_level * 0.05  # +5% per level
drone_multiplier += RewardManager.perm_drone_frost_level * 0.05
drone_multiplier += RewardManager.perm_drone_poison_level * 0.05
drone_multiplier += RewardManager.perm_drone_shock_level * 0.05

waves_cleared = floor(waves_cleared * drone_multiplier)
```

**Option B: Historical tracking (COMPLEX)**

```gdscript
# Track in RunStats during gameplay
var total_player_damage: float = 0.0
var total_drone_damage: float = 0.0

func get_drone_contribution_percent() -> float:
    if total_player_damage == 0:
        return 0.0
    return total_drone_damage / (total_player_damage + total_drone_damage)

# Use in offline calculation
var drone_contribution = get_avg_drone_contribution_last_10_runs()
waves_cleared = floor(waves_cleared * (1.0 + drone_contribution))
```

---

### Phase 4: Lab System Implementation

Since lab system doesn't exist, here's a proposed architecture:

#### **Lab System Design**

**Core Concept:** Long-duration research projects that provide powerful upgrades

**File Structure:**
```
LabManager.gd          # Autoload singleton
LabProject.gd          # Resource class for projects
lab_ui.gd              # UI for lab interface
lab_projects/*.tres    # Project definitions
```

**LabManager.gd Structure:**
```gdscript
extends Node

class_name LabManager

# Active research slots
var research_slots: Array[LabProject] = []
const MAX_SLOTS = 3  # Unlock more with upgrades

# Available projects (branching tree)
var unlocked_projects: Array[String] = ["basic_analysis"]
var completed_projects: Array[String] = []

# Research tree structure
var project_tree = {
    "basic_analysis": {
        "duration": 3600,  # 1 hour
        "unlocks": ["advanced_algorithms", "data_compression"],
        "bonus": {"data_credit_multiplier": 0.1}
    },
    "advanced_algorithms": {
        "duration": 14400,  # 4 hours
        "requires": ["basic_analysis"],
        "unlocks": ["quantum_optimization", "neural_networks"],
        "bonus": {"projectile_damage": 50},
        "tradeoff": "Cannot research data_compression path"
    },
    "data_compression": {
        "duration": 14400,  # 4 hours
        "requires": ["basic_analysis"],
        "unlocks": ["archive_streaming", "cache_burst"],
        "bonus": {"archive_token_multiplier": 0.15},
        "tradeoff": "Cannot research advanced_algorithms path"
    },
    # ... more projects
}

func start_research(project_id: String, slot_index: int):
    var project = create_project(project_id)
    project.start_time = Time.get_unix_time_from_system()
    research_slots[slot_index] = project
    save_research_state()

func update_research():
    var now = Time.get_unix_time_from_system()
    for i in range(research_slots.size()):
        var project = research_slots[i]
        if project and project.is_complete(now):
            complete_research(i)

func complete_research(slot_index: int):
    var project = research_slots[slot_index]
    apply_research_bonus(project)
    completed_projects.append(project.id)
    unlock_next_projects(project.id)
    research_slots[slot_index] = null
    save_research_state()
```

#### **Lab System Features**

**1. Branching Paths (Meaningful Choices)**
- "Advanced Algorithms" vs "Data Compression"
- Choosing one locks out the other
- Different bonuses encourage different playstyles

**2. Long-Duration Projects**
- Short: 1-2 hours (early game)
- Medium: 4-8 hours (mid game)
- Long: 24-72 hours (late game)
- Epic: 7+ days (endgame)

**3. Tradeoffs**
- Offensive vs Defensive research
- Speed vs Power
- Active vs Idle bonuses

**4. Depth**
- 50+ total projects
- 10+ tiers deep
- Multiple paths through tree

**5. Offline Friendly**
- Research continues offline
- Shows "Research completed!" popup on return
- Can queue next research (with upgrade)

#### **Example Project Definitions**

```gdscript
# res://lab_projects/basic_analysis.tres
{
    "id": "basic_analysis",
    "name": "Basic Code Analysis",
    "description": "Analyze enemy code patterns to improve efficiency",
    "duration": 3600,
    "cost": {"fragments": 100},
    "requires": [],
    "unlocks": ["advanced_algorithms", "data_compression"],
    "bonuses": {
        "data_credit_multiplier": 0.1
    },
    "flavor_text": "Every system has its weaknesses..."
}
```

```gdscript
# res://lab_projects/quantum_optimization.tres
{
    "id": "quantum_optimization",
    "name": "Quantum Optimization",
    "description": "Harness quantum computing for devastating damage",
    "duration": 86400,  # 24 hours
    "cost": {"fragments": 5000, "archive_tokens": 1000},
    "requires": ["advanced_algorithms", "entanglement_theory"],
    "unlocks": ["quantum_tunneling", "superposition_targeting"],
    "bonuses": {
        "crit_damage_multiplier": 0.5,
        "projectile_damage_perm": 200
    },
    "tradeoffs": {
        "locks": ["classical_optimization_tree"]
    },
    "flavor_text": "Reality is just probability until observed..."
}
```

---

## 📊 Implementation Priority

### Priority 1: Offline Progress Foundation (CRITICAL)
- [ ] Add time tracking to save system
- [ ] Implement basic offline calculation
- [ ] Add offline progress popup UI
- [ ] Test with various offline durations

### Priority 2: Offline Accuracy (HIGH)
- [ ] Audit wave skip offline behavior
- [ ] Implement drone offline contribution
- [ ] Add speed multiplier to offline calc
- [ ] Cap offline gains (prevent exploits)

### Priority 3: Lab System Foundation (MEDIUM)
- [ ] Design lab project tree structure
- [ ] Implement LabManager singleton
- [ ] Create lab UI interface
- [ ] Add 10-20 initial projects

### Priority 4: Lab System Depth (LOW)
- [ ] Add branching paths (30+ projects)
- [ ] Implement tradeoff mechanics
- [ ] Add long-duration projects (24h+)
- [ ] Create endgame research content

---

## 🎯 Success Metrics

**Offline Progress:**
- ✅ Player returns after 1 hour → sees meaningful progress
- ✅ Player returns after 8 hours → sees significant progress (but capped)
- ✅ Offline progress ≈ 30-50% of active play efficiency (balanced)
- ✅ No exploits (time manipulation, repeated quits, etc.)

**Lab System:**
- ✅ Players face meaningful choices (can't have everything)
- ✅ Long-term goals (some projects take days)
- ✅ Depth matters (late-game content exists)
- ✅ Researching feels impactful (not just +1% bonuses)

---

## 📝 Next Steps

1. **Confirm scope with user:**
   - Is there an existing lab system I missed?
   - What's the priority: offline progress or lab system?
   - What's the target offline efficiency (% of active play)?

2. **Implement offline progress first** (more critical)
   - Phase 1: Basic time tracking
   - Phase 2: Wave simulation
   - Phase 3: Drone contribution

3. **Then implement lab system**
   - Design project tree
   - Implement core mechanics
   - Add content depth

---

**Document Version:** 1.0
**Last Updated:** 2025-12-25
**Status:** Awaiting user feedback
