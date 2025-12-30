# TECHNICAL AUDIT REPORT - Subroutine Defense
**Date:** 2025-12-30
**Audit Scope:** Full game codebase analysis
**Focus:** Long-term stability, scaling, performance, architectural integrity

---

## 1. CRITICAL BUGS

### 🔴 CRITICAL-01: Boss Rush Damage Tracking Int Overflow
**File:** `BossRushManager.gd`
**Location:** Lines 21, 139, 144, 201-214, 494-502
**Severity:** CRITICAL

**Issue:**
```gdscript
var current_run_damage: int = 0  # Line 21
RunStats.damage_dealt += dealt_dmg_bn.to_float()  # projectile.gd:88
```

Boss Rush tracks damage as `int`, but damage dealt is accumulated from `BigNumber.to_float()`. With BigNumber supporting values up to 10^237, converting to float then to int will:
- Return `9223372036854775807` (int64 max) for any value exceeding that range
- Cause all high-tier players to have identical scores (int64 max)
- Break leaderboard ranking for late-game players

**When It Surfaces:** Mid-to-late game (Tier 5+, where damage exceeds 9.2e18)

**Impact:**
- Leaderboard becomes meaningless for competitive players
- Fragment rewards distributed incorrectly
- Server-side validation will detect mismatch and reject scores

**Recommendation:** Change `current_run_damage` and all boss rush damage tracking to `float`, or implement BigNumber-based leaderboard serialization.

---

### 🔴 CRITICAL-02: Wave Skip Can Skip Boss Waves
**File:** `spawner.gd`
**Location:** Lines 79-82, 189-192
**Severity:** CRITICAL

**Issue:**
```gdscript
# Normal mode handling
if should_skip_wave():
    print("⏩ Wave", actual_wave, "skipped due to Wave Skip Chance!")
    actual_wave += 1
```

Wave skipping triggers before boss wave detection (line 92: `if current_wave % 10 == 0`). This means:
- Boss waves (every 10th wave) can be skipped
- Players miss boss encounters and boss-specific rewards
- Fragment reward progression disrupted (bosses give 100x fragments)
- Progression gate bypassed unintentionally

**When It Surfaces:** Early game (as soon as wave skip chance > 0%, typically by wave 20-30)

**Impact:**
- Economic imbalance: players skip high-value content
- Boss encounters become optional instead of required
- Achievement/milestone triggers may break

**Recommendation:** Add boss wave check before wave skip logic:
```gdscript
if should_skip_wave() and actual_wave % 10 != 0:
    actual_wave += 1
```

---

### 🔴 CRITICAL-03: No Transaction Safety on Permanent Upgrades
**File:** `UpgradeManager.gd`
**Location:** Lines 753-763, 765-775, 777-787 (all perm upgrade functions)
**Severity:** CRITICAL

**Issue:**
```gdscript
func upgrade_perm_projectile_damage() -> bool:
    var cost = get_perm_cost(5000, 250, RewardManager.get_perm_projectile_damage_int() / 10)
    if RewardManager.archive_tokens < cost:
        return false
    RewardManager.archive_tokens -= cost  # Currency deducted
    RunStats.add_at_spent_perm_upgrade(cost)
    RewardManager.add_perm_projectile_damage(10)  # Upgrade applied
    RewardManager.save_permanent_upgrades()  # Save may fail!
    return true
```

If `save_permanent_upgrades()` fails (disk full, permissions, corruption):
- Currency is already deducted
- Upgrade is already applied in memory
- Player loses currency permanently on next save
- No rollback mechanism exists

**When It Surfaces:** Any time disk I/O fails (low disk space, file lock, permission change)

**Impact:**
- Data loss for players
- Loss of trust/reputation
- Support burden

**Recommendation:** Implement transaction pattern:
1. Attempt save FIRST with test write
2. Only deduct currency if save succeeds
3. Add rollback mechanism for failed saves

---

## 2. HIGH-RISK DESIGN / IMPLEMENTATION ISSUES

### 🟠 HIGH-01: Tier Unlock Requirements Unrealistic
**File:** `TierManager.gd`
**Location:** Lines 11, 77-78, 132-133
**Severity:** HIGH

**Issue:**
```gdscript
const WAVES_PER_TIER := 5000  # Waves needed to unlock next tier
```

To reach Tier 10:
- Tier 2: 5,000 waves
- Tier 3: 10,000 total waves
- Tier 4: 15,000 total waves
- ...
- Tier 10: **45,000 total waves**

At 30 seconds per wave (fast player), this requires:
- 45,000 waves × 30 sec = 1,350,000 seconds = **375 hours** of active gameplay
- Equivalent to **15.6 full days** of non-stop playing

**When It Surfaces:** Mid game (players reach Tier 3-4 and realize impossibility)

**Impact:**
- Player retention: 99%+ of players will never see Tier 10 content
- Wasted development effort on high-tier content
- Player frustration/abandonment

**Recommendation:** Consider exponential or logarithmic scaling:
- Tier 2: 100 waves
- Tier 3: 250 waves
- Tier 4: 500 waves
- Tier 5: 1,000 waves
- Tier 10: ~5,000 waves total

---

### 🟠 HIGH-02: Boss Rush Fragment Double-Award Race Condition
**File:** `BossRushManager.gd`
**Location:** Lines 23, 134, 411-422
**Severity:** HIGH

**Issue:**
```gdscript
var fragments_awarded_for_current_run: bool = false

func _award_fragments_for_rank(rank: int) -> void:
    if fragments_awarded_for_current_run:  # Check
        return
    var fragments = get_fragment_reward_for_rank(rank)
    if fragments > 0:
        RewardManager.add_fragments(fragments)  # Award
        fragments_awarded_for_current_run = true  # Set flag AFTER award
```

If online leaderboard fetch completes AND local rank calculation both trigger `_award_fragments_for_rank()` simultaneously:
- Both pass the check (race condition)
- Fragments awarded twice
- Player gets unearned currency

Also called from:
- Line 158: Offline mode fallback
- Line 208: Rate limit fallback
- Line 315: Validation failure fallback
- Line 339: Server rejection fallback
- Line 347: Submission failure fallback
- Line 402: Online success path
- Line 407: Participation fallback

**When It Surfaces:** Network instability, race between HTTP callbacks

**Impact:**
- Economic exploit
- Undermines leaderboard integrity
- Fragment inflation

**Recommendation:** Use atomic flag or mutex, set flag BEFORE awarding.

---

### 🟠 HIGH-03: Enemy Pool Insufficient for Late Game
**File:** `spawner.gd`
**Location:** Lines 29-35, 160-163
**Severity:** HIGH

**Issue:**
```gdscript
ObjectPool.create_pool(pool_name, enemy_scenes[i], 30)  # Only 30 per type

func get_max_enemies_for_wave(wave: int) -> int:
    var base = 10
    var increment = int(wave / 250) * 2
    return min(base + increment, 40)  # Up to 40 enemies
```

At wave 1000+:
- 40 enemies spawn per wave
- Pool has 30 instances
- ObjectPool must create 10 NEW instances every wave
- No pooling benefit for 25% of enemies

**When It Surfaces:** Late game (wave 750+)

**Impact:**
- Performance degradation (allocation/GC)
- Defeats purpose of pooling
- Stuttering during wave spawn

**Recommendation:** Make pool size scale with max wave enemies or increase to 50-60.

---

### 🟠 HIGH-04: Save Version Migration Incomplete
**File:** `RewardManager.gd`
**Location:** Lines 524-526, 669-675, 685-699
**Severity:** HIGH

**Issue:**
```gdscript
const SAVE_VERSION = 2
# Version 1: Original format with perm_projectile_damage as int
# Version 2: BigNumber format with perm_projectile_damage_mantissa/exponent
```

Only ONE migration path exists (v1 → v2 for permanent damage). Missing:
- No migration for future changes to other fields
- No handling of field additions/removals
- No migration for tier unlock format changes
- No migration for achievement/milestone formats
- Hard-coded field names in save/load

**When It Surfaces:** Next time save format changes (inevitable during development)

**Impact:**
- Save corruption on updates
- Player data loss
- Emergency hotfix required

**Recommendation:** Implement proper migration framework:
```gdscript
func _migrate_save_data(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
    for version in range(from_version + 1, to_version + 1):
        data = _apply_migration(data, version)
    return data
```

---

## 3. SCALING & LONG-TERM TIMEBOMBS

### 🟡 SCALE-01: BigNumber Precision Loss in Statistics
**File:** `projectile.gd`, `RunStats.gd`
**Location:** projectile.gd:88, RunStats.gd:4
**Severity:** MEDIUM

**Issue:**
```gdscript
RunStats.damage_dealt += dealt_dmg_bn.to_float()  # precision loss

var damage_dealt: float = 0.0  # Can only store up to ~10^308 precisely
```

`BigNumber.to_float()` conversion:
- Loses precision for numbers > 10^15 (float64 mantissa limit)
- Returns `INF` for numbers > 10^308
- Boss Rush leaderboard compares INF vs INF (all ties)

**When It Surfaces:** Late game (Tier 7+, damage > 10^15)

**Impact:**
- Inaccurate statistics
- Broken leaderboards
- Achievements may not trigger correctly

**Recommendation:** Store statistics as BigNumber or use logarithmic representation.

---

### 🟡 SCALE-02: Tier Multipliers Cause Numeric Instability
**File:** `TierManager.gd`, `enemy.gd`
**Location:** TierManager.gd:50-59, enemy.gd:433-439
**Severity:** MEDIUM

**Issue:**
```gdscript
func get_enemy_multiplier() -> float:
    return pow(ENEMY_MULTIPLIER_BASE, current_tier - 1)  # 10^tier

func get_reward_multiplier() -> float:
    return pow(REWARD_MULTIPLIER_BASE, current_tier - 1)  # 5^tier

var calculated_hp = base_hp * tier_mult * pow(HP_SCALING_BASE, wave_number)
```

Tier 10 multipliers:
- Enemy HP: `base * 10^9 * 1.02^wave = base * 1,000,000,000 * 1.02^wave`
- At wave 1000: `base * 10^9 * 4.4e8 = base * 4.4e17`
- Rewards: `base * 5^9 = base * 1,953,125`

Problems:
- Intermediate float calculations lose precision
- Multiple multiplications compound rounding errors
- May exceed float range in pathological cases

**When It Surfaces:** Late game (Tier 8+, wave 500+)

**Impact:**
- HP calculations may be incorrect
- Rewards may round incorrectly
- Balance breaks at extreme tiers

**Recommendation:** Use BigNumber for tier multiplier calculations or logarithmic scaling.

---

### 🟡 SCALE-03: No Upper Bound on Upgrade Costs
**File:** `UpgradeManager.gd`
**Location:** Lines 213-214
**Severity:** MEDIUM

**Issue:**
```gdscript
func get_perm_cost(base: int, increment: int, level: int) -> int:
    return int(base * pow(1.13, level))
```

Permanent upgrade costs scale as `1.13^level`:
- Level 100: base × 118,648
- Level 500: base × 1.9e25
- Level 1000: base × 3.6e50

At level 500+, cost exceeds `int64 max` and wraps to negative or clamps to max:
- Upgrades become free (if wrapping to negative)
- Or impossible to afford (if clamping to int64 max)

**When It Surfaces:** Late game (perm upgrade level 150+, ~500+ hours of gameplay)

**Impact:**
- Economic exploit or soft-lock
- Progression halts

**Recommendation:** Cap upgrade levels or use BigNumber for costs.

---

### 🟡 SCALE-04: Offline Progress Assumes Single Session
**File:** `RewardManager.gd`
**Location:** Lines 476-521
**Severity:** MEDIUM

**Issue:**
```gdscript
func apply_offline_rewards():
    var now = Time.get_unix_time_from_system()
    var elapsed = now - last_play_time

    # Cap at 24 hours
    elapsed = min(elapsed, 86400)
```

Offline calculation assumes:
- Linear time progression
- Single session between logins
- No timezone changes
- System clock accuracy

Problems:
- System clock manipulation can exploit
- Daylight saving time changes break
- Player who plays at 11:59 PM and logs in at 12:01 AM loses progress (2 minutes counted as 0)

**When It Surfaces:** Early (any offline session)

**Impact:**
- Exploitable by clock manipulation
- DST bugs twice per year
- Player frustration

**Recommendation:** Add server-side time validation or signed timestamps.

---

## 4. PERFORMANCE RISKS

### 🟠 PERF-01: Enemy Targeting O(n) Iteration
**File:** `tower.gd`
**Location:** Lines 98-115
**Severity:** HIGH

**Issue:**
```gdscript
func get_closest_enemy() -> Node2D:
    if _cache_frame_counter % CACHE_REFRESH_FRAMES != 0:  # Every 3 frames
        return _cached_closest_enemy

    # Recalculate - O(n) iteration
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var dist = global_position.distance_to(enemy.global_position)
```

Performance analysis:
- Wave 100: 40 enemies × 20 targeting checks/sec = 800 distance calculations/sec
- Multiple towers (if added): scales multiplicatively
- `get_nodes_in_group()` creates new array allocation

**When It Surfaces:** Mid-game (wave 50+, 20+ enemies)

**Impact:**
- Frame drops during intense waves
- Scales poorly with tower count
- CPU bottleneck

**Recommendation:** Implement spatial partitioning (quadtree/grid) or keep sorted distance list.

---

### 🟡 PERF-02: Trail Per-Frame Allocations
**File:** `projectile.gd`
**Location:** Lines 41-51
**Severity:** MEDIUM

**Issue:**
```gdscript
func _process(delta: float) -> void:
    if trail and is_instance_valid(trail):
        if global_position.distance_to(last_trail_pos) > TRAIL_SPACING:
            AdvancedVisuals.update_trail(trail, global_position, MAX_TRAIL_POINTS)
```

Every projectile updates trail per frame:
- 10 projectiles in flight = 10 trail updates/frame = 600 updates/sec
- Each update modifies Line2D.points array (allocation)
- At high fire rate (10/sec), can have 50+ projectiles = 3000 trail updates/sec

**When It Surfaces:** Mid game (high fire rate upgrade + piercing)

**Impact:**
- GC pressure from array allocations
- Frame stuttering
- Memory churn

**Recommendation:** Pool trail points arrays or reduce update frequency.

---

### 🟡 PERF-03: No Pooling for Visual Effects
**File:** `projectile.gd`, `ParticleEffects.gd`
**Location:** projectile.gd:33-39, 59
**Severity:** MEDIUM

**Issue:**
```gdscript
trail = AdvancedVisuals.create_projectile_trail(parent, Color(...))

func _exit_tree() -> void:
    if trail:
        trail.queue_free()  # Create/destroy every projectile
```

Every projectile creates and destroys:
- 1× Line2D (trail)
- 1× Sprite2D (visual)
- 1× impact particle effect on hit

At 10 shots/sec with 2 sec flight time:
- 20 projectiles in flight
- 10 creates + 10 destroys per second
- 20 object allocations/sec + GC

**When It Surfaces:** Early-mid game (fire rate > 5/sec)

**Impact:**
- Allocation pressure
- GC stuttering
- Frame drops

**Recommendation:** Pool Line2D trails and particle systems.

---

### 🟡 PERF-04: Boss Rush HTTP Calls Not Rate Limited Properly
**File:** `BossRushManager.gd`
**Location:** Lines 202-214, 275-305
**Severity:** MEDIUM

**Issue:**
```gdscript
func submit_score_online(damage: int, waves: int) -> void:
    if now - last_score_submit < MIN_SUBMIT_INTERVAL:
        print("⚠️ Score submission too frequent.")
        var rank = get_rank_for_damage(damage)
        _award_fragments_for_rank(rank)  # Still awards!
        return
```

Rate limiting is client-side only:
- Malicious client can bypass by modifying `last_score_submit`
- No server-side rate limiting mentioned
- Fragments awarded even when rate-limited (allows spam)

**When It Surfaces:** Any time (exploitable immediately)

**Impact:**
- Server DoS potential
- Fragment exploit
- Leaderboard spam

**Recommendation:** Enforce rate limiting server-side, don't award fragments on rate-limit.

---

## 5. ARCHITECTURAL SMELLS / TECH DEBT

### 🟡 ARCH-01: God Object - RewardManager
**File:** `RewardManager.gd`
**Location:** Entire file (767 lines)
**Severity:** MEDIUM

**Responsibilities:**
- Currency management (DC, AT, Fragments, Quantum Cores)
- Permanent upgrades (18+ different upgrade types)
- Drone ownership tracking
- Save/load persistence
- Offline progress calculation
- Tier data serialization
- Run history tracking
- Lifetime statistics
- Reward calculation formulas

**Problems:**
- Violates Single Responsibility Principle
- Hard to test individual components
- Merge conflicts in team development
- Difficult to extend without breaking changes
- 767 lines in single file

**Recommendation:** Split into:
- `CurrencyManager` (DC, AT, Fragments, QC)
- `PersistenceManager` (save/load, backups, cloud sync)
- `OfflineProgressManager` (offline rewards)
- `PermUpgradeManager` (permanent upgrades only)

---

### 🟡 ARCH-02: Circular Reference Risk
**File:** Multiple
**Location:** TierManager ↔ AchievementManager ↔ RunStats ↔ RewardManager
**Severity:** MEDIUM

**Circular references:**
```gdscript
# TierManager.gd:125
if AchievementManager:
    AchievementManager.add_wave_completed()

# TierManager.gd:129
if MilestoneManager:
    MilestoneManager.check_milestone_for_wave(current_tier, wave)

# RunStats.gd:58
if AchievementManager:
    AchievementManager.add_enemies_killed(1)

# All managers access RewardManager
```

**Problems:**
- Load order dependencies
- Null reference risks if load order wrong
- Hard to understand data flow
- Testing requires full dependency graph

**Recommendation:** Implement event bus pattern or use signals for cross-manager communication.

---

### 🟡 ARCH-03: No Game Mode Abstraction
**File:** `spawner.gd`, `BossRushManager.gd`, `enemy.gd`
**Location:** spawner.gd:61-76, 107-126; enemy.gd:438-450
**Severity:** MEDIUM

**Issue:**
```gdscript
# spawner.gd
if BossRushManager.is_boss_rush_active():
    # Boss rush logic
else:
    # Normal mode logic

# enemy.gd
if BossRushManager.is_boss_rush_active():
    apply_boss_rush_scaling()
else:
    apply_wave_scaling()
```

Game mode logic scattered across:
- Spawner (wave generation)
- Enemy (scaling)
- BossRushManager (state tracking)
- Main HUD (UI state)

**Problems:**
- Adding new game mode requires changes in 4+ files
- No polymorphism/inheritance for modes
- Conditional checks everywhere
- Hard to test individual modes

**Recommendation:** Create `GameMode` base class with:
- `NormalMode`
- `BossRushMode`
- `[Future modes]`

Each mode encapsulates its own spawning, scaling, and reward logic.

---

### 🟡 ARCH-04: No Event/Message System
**File:** Multiple
**Location:** Direct coupling throughout
**Severity:** LOW

**Issue:**
Direct method calls between systems:
```gdscript
RewardManager.add_wave_at(current_wave)
AchievementManager.add_wave_completed()
MilestoneManager.check_milestone_for_wave(tier, wave)
ScreenEffects.wave_transition(current_wave)
ParticleEffects.create_wave_complete_effect(pos)
```

**Problems:**
- Tight coupling
- Hard to add/remove features
- No way to hook into events without modifying source
- Testing requires full system

**Recommendation:** Implement event bus:
```gdscript
EventBus.emit("wave_completed", {wave: 10, tier: 1})
# Multiple systems listen independently
```

---

## 6. INCONSISTENCIES BETWEEN DESIGN AND CODE

### 🟡 INCONSIST-01: Boss Rush Validation Not Enforced
**File:** `BossRushManager.gd`
**Location:** Lines 217-243
**Severity:** MEDIUM

**Design Intent:** Server-side anti-cheat validation
**Implementation:**
```gdscript
func validate_score_with_server(damage: int, waves: int) -> void:
    # Calls CloudScript "validateBossRushScore"
    # But CloudScript implementation not shown in codebase
```

**Problems:**
- No evidence CloudScript function exists
- No validation logic visible
- Trusts client-submitted damage value
- If validation fails, still awards participation fragments

**Recommendation:** Implement visible validation rules or remove claim of anti-cheat.

---

### 🟡 INCONSIST-02: Overkill System Disabled
**File:** `projectile.gd`
**Location:** Lines 96, 113-117
**Severity:** LOW

**Design Intent:** Overkill damage spreads to nearby enemies
**Implementation:**
```gdscript
var overkill_damage = 0  # Defined but never set
# TODO: Overkill calculation needs redesign - enemies don't store max HP
# For now, disable overkill to prevent errors
```

**Problems:**
- Feature advertised but non-functional
- Upgrade exists (`overkill_damage_level`) but does nothing
- Players waste currency on useless upgrade
- Code debt

**Recommendation:** Either fully implement or remove upgrade from shop.

---

### 🟡 INCONSIST-03: Wave Skip Percentage vs Actual Behavior
**File:** `spawner.gd`, `UpgradeManager.gd`
**Location:** spawner.gd:189-192, UpgradeManager.gd:312-316
**Severity:** LOW

**Design Intent:** Wave skip chance capped at 25%
**Implementation:**
```gdscript
const WAVE_SKIP_MAX_CHANCE := 25.0

func get_wave_skip_chance() -> float:
    return min(base_chance + disk_buff, WAVE_SKIP_MAX_CHANCE)

# spawner.gd
func should_skip_wave() -> bool:
    var chance = UpgradeManager.get_wave_skip_chance()
    var roll = randf() * 100.0
    return roll < chance  # Skips every wave that rolls under chance
```

**Inconsistency:**
- Documentation/intent: "Skip waves occasionally"
- Implementation: Skips EVERY wave independently with 25% chance
- At max chance, skips ~25% of ALL waves (including back-to-back skips)
- No cooldown or skip prevention

**Recommendation:** Add skip cooldown or streak prevention.

---

## 7. SAFE EXTENSION POINTS

### ✅ SAFE-01: Data Disk System
**File:** `DataDiskManager.gd`
**Location:** Buff cache system

**Why Safe:**
- Clean separation of data disk definitions
- Cached buff system prevents performance issues
- Easy to add new disk types without touching core systems
- Formula-based buffs make balance tweaking simple

**Extension Path:**
- Add new disk types to config
- Define buff formulas
- Cache invalidation handled automatically

---

### ✅ SAFE-02: Achievement System
**File:** `AchievementManager.gd`
**Location:** Achievement tracking and validation

**Why Safe:**
- Event-driven architecture (emit signals)
- No direct coupling to core gameplay
- Easy to add new achievement types
- Separate from reward logic

**Extension Path:**
- Define new achievement criteria
- Hook into existing stat tracking
- Add UI display independently

---

### ✅ SAFE-03: Enemy Type System
**File:** `spawner.gd`, ObjectPool system
**Location:** Enemy scene preloading and pooling

**Why Safe:**
- Scene-based enemy definitions
- Probability table for spawn rates
- Pooling handles scaling automatically
- No hard-coded enemy logic in spawner

**Extension Path:**
- Create new enemy scene
- Add to `enemy_scenes` array
- Add to probability table
- Pool created automatically

---

### ✅ SAFE-04: Visual Effects System
**File:** `VisualFactory.gd`, `ParticleEffects.gd`, `AdvancedVisuals.gd`
**Location:** Centralized visual creation

**Why Safe:**
- Factory pattern for all visual elements
- No gameplay logic in visual code
- Easy to swap/upgrade visuals
- Separated from core systems

**Extension Path:**
- Add new visual effect functions
- Call from gameplay code
- No risk to game logic

---

## SUMMARY & PRIORITY RECOMMENDATIONS

### Immediate Actions (Critical/High):
1. **Fix boss rush damage overflow** - Change to float or BigNumber
2. **Fix wave skip boss bypass** - Add boss wave check before skip
3. **Implement transaction safety** - Save before deducting currency
4. **Reduce tier unlock requirements** - Make Tier 10 achievable
5. **Fix boss rush fragment race condition** - Atomic flag

### Short-Term (Medium):
1. Increase enemy pool size for late game
2. Implement comprehensive save migration framework
3. Add spatial partitioning for enemy targeting
4. Add validation for offline progress
5. Split RewardManager into separate concerns

### Long-Term (Architectural):
1. Implement event bus system
2. Create game mode abstraction layer
3. Break circular dependencies
4. Add server-side validation for competitive features
5. Consider BigNumber for all statistics tracking

### Performance Monitoring:
- Track frame time at wave 100, 500, 1000
- Monitor GC pressure during high fire rate
- Profile HTTP request patterns in boss rush
- Track save/load times with large save files

---

**End of Technical Audit Report**
