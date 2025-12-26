# Balance Guide - Subroutine Defense

**Version:** 1.0
**Last Updated:** 2025-12-26
**Target Timeline:** 3 years of progression

---

## 📊 Executive Summary

This document explains all the math behind Subroutine Defense's economy and progression systems. Understanding these formulas helps with:
- Debugging economy issues
- Tuning difficulty curves
- Planning new content
- Validating player feedback

---

## 💰 Currency Systems

### Data Credits (DC) - Temporary
**Purpose:** In-run upgrades (reset on death)
**Starting Amount:** 0 (earn during run)
**Max Theoretical:** Unlimited (scales with progression)

### Archive Tokens (AT) - Permanent
**Purpose:** Permanent upgrades, software labs
**Starting Amount:** 100,000 (testing only, production: 0)
**Max Theoretical:** Billions (3-year grind)

### Fragments - Premium
**Purpose:** Drone permanent upgrades
**Starting Amount:** 0
**Max Theoretical:** Unlimited (from boss kills)

---

## 🎮 In-Run Upgrade Costs (DC)

### The Tower Model - Per-Purchase Scaling

**Formula:** `cost = base_cost * (1.15 ^ purchase_count)`

**Why this works:**
- Early game: Costs stay low (50-200 DC for first few purchases)
- Late game: Can afford many purchases due to permanent bonuses
- Wave-independent: Late-game player at wave 10,000 still starts with 50 DC cost
- Natural progression: More permanent upgrades → more purchases per run

**Example: Damage Upgrade (50 DC base)**
```
Purchase  1:     50 DC   (baseline)
Purchase  2:     58 DC   (+15%)
Purchase  5:     87 DC   (+75%)
Purchase 10:    176 DC   (+252%)
Purchase 20:    736 DC   (+1372%)
Purchase 30:  3,075 DC   (+6050%)
Purchase 50: 36,841 DC   (+73582%)
```

**All Upgrade Base Costs:**
```
Offense:
  Damage:              50 DC
  Fire Rate:           50 DC
  Crit Chance:        100 DC
  Crit Damage:        125 DC
  Multi-Target:     1,000 DC (first unlock)
  Piercing:            80 DC
  Overkill:            90 DC
  Projectile Speed:    60 DC
  Ricochet Chance:    120 DC
  Ricochet Max:       150 DC

Defense:
  Shield Integrity:    50 DC
  Damage Reduction:    75 DC
  Shield Regen:       100 DC
  Block Chance:       110 DC
  Block Amount:       130 DC
  Boss Resistance:    200 DC
  Overshield:         180 DC

Economy:
  DC Multiplier:       60 DC
  AT Multiplier:       70 DC
  Wave Skip:          400 DC
  Free Upgrade:       250 DC
```

**Caps:**
- Crit Chance: 60% max
- Wave Skip: 25% max
- Free Upgrade: 50% max
- Everything else: Unlimited

---

## 🔄 Permanent Upgrade Costs (AT)

### Exponential Scaling Formula

**Formula:** `cost = base_cost * (1.13 ^ level)`

**Why 1.13:**
- Aggressive growth prevents maxing everything
- Creates meaningful choices (can't afford all upgrades)
- 3-year timeline achievable for dedicated players
- Forces prioritization strategy

**Cost Progression Examples:**

**Damage (5,000 AT base):**
```
Level   1:      5,650 AT
Level   5:      9,211 AT
Level  10:     18,599 AT
Level  20:     69,192 AT
Level  50:  2,206,414 AT
Level 100: 456,308,051 AT (456 million!)
```

**AT Multiplier (13,000 AT base):**
```
Level   1:     14,690 AT
Level   5:     23,947 AT
Level  10:     48,357 AT
Level  20:    179,898 AT
Level  50:  5,736,675 AT
Level 100: 1,186,401,331 AT (1.2 billion!)
```

**All Permanent Upgrade Bases:**
```
Stat                      Base Cost   Bonus per Level
──────────────────────────────────────────────────────
Projectile Damage             5,000   +10 damage
Fire Rate                     8,000   +0.1 fire rate
Crit Chance                   7,500   +1% crit
Crit Damage                   9,000   +0.05x mult
Shield Integrity              7,000   +10 shield
Damage Reduction              8,000   +0.5% reduction
Shield Regen                  8,500   +0.25 regen/sec
DC Multiplier                12,000   +5% DC earned
AT Multiplier                13,000   +5% AT earned
Wave Skip                    15,000   +1% skip chance
Free Upgrade                 18,000   +1% free chance

Batch 2 (Advanced):
Overshield                   10,000   +5 overshield
Boss Bonus                   12,000   +3% boss damage
Lucky Drops                  11,000   +2% drop chance
Ricochet Targets             14,000   +1 max target

Drone Upgrades (Fragments):
Flame Drone                      50   +1 level
Frost Drone                      50   +1 level
Poison Drone                     50   +1 level
Shock Drone                      50   +1 level
```

**Target Levels for 3-Year Timeline:**
- Core stats (damage, fire rate): Level 30-50
- Economy multipliers: Level 20-30
- Utility stats (skip, free): Level 10-20
- Total AT spent: ~100-500 million

---

## 🔬 Software Lab Costs (AT)

### Exponential Duration & Cost Scaling

**Duration Formula:** `duration = base_duration * (scaling ^ (level-1))`
**Cost Formula:** `cost = base_cost_at * (cost_scaling ^ (level-1))`

### Tier 1 Labs (100 levels)

**Damage Processing:**
```
Base: 500 AT, 3600s (1h)
Scaling: Duration 1.05, Cost 1.08

Level   1:   500 AT,    1.0h
Level  10:   999 AT,    1.6h
Level  50: 25,432 AT,    5.7h
Level 100: 1,028,572 AT, 65.0h
```

**Fire Rate Optimization:**
```
Base: 500 AT, 3600s (1h)
Scaling: Duration 1.05, Cost 1.08
(Same progression as Damage Processing)
```

**Critical Analysis:**
```
Base: 600 AT, 7200s (2h)
Scaling: Duration 1.06, Cost 1.10

Level   1:   600 AT,    2.0h
Level  10: 1,391 AT,    3.3h
Level  50: 70,128 AT,   18.4h
Level 100: 7,438,117 AT, 339h (14 days!)
```

### Tier 2 Labs (50 levels)

**Damage Amplification:**
```
Base: 1,000 AT, 14400s (4h)
Scaling: Duration 1.07, Cost 1.12

Level   1: 1,000 AT,   4.0h
Level  25: 15,270 AT,  21.3h
Level  50: 233,290 AT, 114h (4.7 days)
```

**Resource Optimization (DC Multiplier):**
```
Base: 1,200 AT, 10800s (3h)
Scaling: Duration 1.06, Cost 1.10

Level   1: 1,200 AT,   3.0h
Level  25: 11,958 AT,  12.9h
Level  50: 141,048 AT,  55h (2.3 days)
```

### Tier 3 Labs (30 levels)

**Multi-Target Systems:**
```
Base: 5,000 AT, 21600s (6h)
Scaling: Duration 1.08, Cost 1.20

Level   1:  5,000 AT,    6.0h
Level  15: 72,855 AT,   19.0h
Level  30: 1,187,289 AT, 60h (2.5 days)
```

**Lab Acceleration (Meta Lab):**
```
Base: 2,000 AT, 21600s (6h)
Scaling: Duration 1.08, Cost 1.16

Effect: Reduces all lab durations by level%
Level 10 = -10% duration on all labs
```

---

## 💎 Fragment Economy

### Fragment Earning

**Boss Kills:**
```
Formula: 10 + floor(wave / 10)

Wave  10:  11 fragments
Wave  50:  15 fragments
Wave 100:  20 fragments
Wave 500:  60 fragments
```

**Boss Rush Tournament:**
```
Rank  1: 5,000 fragments
Rank  2: 3,000 fragments
Rank  3: 2,000 fragments
Rank  4: 1,000 fragments
Rank  5: 1,000 fragments
Rank  6:   500 fragments
Rank  7:   500 fragments
Rank  8:   500 fragments
Rank  9:   500 fragments
Rank 10:   500 fragments
Other:      100 fragments (participation)
```

**Weekly Fragment Income (Aggressive Play):**
```
Regular Play: ~10 boss kills/day * 15 frags = 150/day = 1,050/week
Boss Rush: 3 tournaments/week * 100-5000 = 300-15,000/week

Total: 1,350-16,050 fragments/week
```

### Fragment Spending (Drone Upgrades)

**Cost:** 50 fragments per drone level (all 4 drones)

**To Max All 4 Drones (Level 10 each):**
```
4 drones * 10 levels * 50 frags = 2,000 fragments
At 1,350/week = 1.5 weeks to max (regular play)
```

**Fragments are the "premium but farmable" currency.**

---

## 🎯 Earning Rates

### Data Credits (DC)

**Base Enemy Rewards:**
```
Breacher:       1 DC
Slicer:         2 DC
Sentinel:      10 DC
Signal Runner:  8 DC
Null Walker:    6 DC
Override:     100 DC (boss)
```

**Wave Scaling:** `reward * (1.0 + wave * 0.02)`

**Example Progression:**
```
Wave   1: Breacher = 1 * 1.02 = 1 DC
Wave  50: Breacher = 1 * 2.00 = 2 DC
Wave 100: Breacher = 1 * 3.00 = 3 DC
Wave 500: Breacher = 1 * 11.0 = 11 DC
```

**DC Per Wave (Estimated):**
```
Wave   1:   ~20-40 DC (10 enemies, mixed)
Wave  10:  ~150-200 DC (includes boss)
Wave  50:  ~400-600 DC
Wave 100: ~1,000-1,500 DC
Wave 500: ~5,000-8,000 DC
```

**DC Multipliers:**
- In-run: +5% per level (max realistic: +50% = 1.5x)
- Permanent: +5% per level (max realistic: +100% = 2.0x)
- Labs: +1% per level (max: +50% = 1.5x)
- **Combined Max: 4.5x**

### Archive Tokens (AT)

**Base Enemy Rewards:**
```
Breacher:       1 AT
Slicer:         2 AT
Sentinel:       6 AT
Signal Runner:  8 AT
Null Walker:   10 AT
Override:     100 AT (boss)
```

**Wave Completion Bonus:**
```
Formula: floor(0.25 * (wave ^ 1.15))

Wave   1:   0 AT
Wave  10:   2 AT
Wave  50:  26 AT
Wave 100:  78 AT
Wave 500: 915 AT
```

**AT Per Wave (Estimated):**
```
Wave  10:  ~130 AT (30 enemies + 2 wave + 100 boss)
Wave  50:  ~150 AT (120 enemies + 26 wave)
Wave 100:  ~620 AT (240 enemies + 78 wave + 300 boss)
Wave 500: ~1,500 AT (550 enemies + 915 wave)
```

**AT Multipliers:**
- In-run: +5% per level (max realistic: +50% = 1.5x)
- Permanent: +5% per level (max realistic: +100% = 2.0x)
- Labs: +1% per level (max: +50% = 1.5x)
- **Combined Max: 4.5x**

---

## ⏱️ Offline Progress

### Formula

**Base Rate:** Best run from last 7 days (AT/hour)
**Efficiency:** 25% (base) or 50% (with ad)
**Cap:** 24 hours maximum

```
offline_at = best_at_per_hour * efficiency * hours_away
(capped at 24 hours)
```

**Example:**
```
Best run: 500 AT/hour
Offline: 8 hours
Efficiency: 25% (no ad)

Reward: 500 * 0.25 * 8 = 1,000 AT
```

**Default Baseline:** 100 AT/hour if no run history

---

## 🎖️ Tier System

### Unlock Requirements

```
Tier 1: Always unlocked
Tier 2: 5,000 total waves across all tiers
Tier 3: 10,000 total waves
Tier 4: 15,000 total waves
...
Tier 10: 45,000 total waves
```

### Multipliers

**Enemy Stats:** `base_stats * (10 ^ (tier - 1))`
```
Tier 1: 1x enemies, 1x rewards
Tier 2: 10x enemies, 5x rewards
Tier 3: 100x enemies, 25x rewards
Tier 4: 1,000x enemies, 125x rewards
...
Tier 10: 1,000,000,000x enemies, 390,625x rewards
```

**Why Tier 10 is insane:**
- Enemies have billion times more HP
- But you also have billion times more upgrades by then
- Target: 3-year players

---

## 🏆 Boss Rush Scaling

### Mechanics

**Boss Count:** `1 + floor(wave / 10)` (max 10)
```
Wave 1-9:    1 boss
Wave 10-19:  2 bosses
Wave 20-29:  3 bosses
...
Wave 90-99:  10 bosses
Wave 100+:   10 bosses (capped)
```

**HP Scaling:** `base_hp * 5.0 * (1.13 ^ wave)`
```
Wave  1: Boss has   5.0x normal HP
Wave 10: Boss has  17.0x normal HP
Wave 50: Boss has 2,945x normal HP
Wave 100: Boss has 1.67M x normal HP
```

**Compare to Normal Mode:** 2% scaling vs 13% scaling
```
Normal Wave 100: 7.2x HP
Boss Rush Wave 100: 1,670,000x HP

Boss Rush is 231,944x harder at wave 100!
```

---

## 🎲 Probability Systems

### Wave Skip Chance

**Max:** 25% (from permanent upgrades + in-run)

**Effect:** Skip entire wave, get rewards instantly

**Expected Value:**
```
100 waves with 25% skip = ~133 effective waves
(Multiplier: 1.33x progression speed)
```

### Free Upgrade Chance

**Max:** 50%

**Effect:** Upgrade costs 0 DC (rolled per purchase)

**Expected Savings:**
```
100 purchases at 50% free = 50 purchases saved
Savings depends on purchase count (exponential costs)
```

### Crit Chance

**Max:** 60% (from in-run + permanent)

**Crit Damage:** Base 2.0x + permanent bonuses + in-run
- Realistic max: 5.0x-10.0x damage on crit

**DPS Increase:**
```
60% crit * 5.0x damage = +180% average DPS
(2.8x total DPS)
```

---

## 🔢 Math Behind the Madness

### Why Exponential Scaling?

**Linear scaling problems:**
- Late game: Everything costs nothing
- Early game: Everything too expensive
- No long-term goals

**Exponential scaling benefits:**
- Self-balancing (always something to save for)
- Creates meaningful choices (can't afford everything)
- Scales with player power (multiplicative bonuses)
- Long-term engagement (3-year timeline)

### Why Different Scaling Rates?

```
In-run upgrades:  1.15 (15% per purchase) - Gentle, many purchases
Permanent:        1.13 (13% per level) - Steep, fewer levels
Labs:             1.08-1.20 - Varied by tier and impact
```

**Reasoning:**
- In-run: Reset every death, should be affordable within single run
- Permanent: Persist forever, must be expensive to avoid power creep
- Labs: Long duration = steeper cost (time investment)

---

## 🎯 Target Progression Timeline

**Week 1:**
- Reach wave 50-100 consistently
- Unlock a few permanent upgrades (levels 1-5)
- Start first labs
- Total AT earned: ~50,000

**Month 1:**
- Reach wave 200-300
- Permanent upgrades at level 10-15
- Several labs at level 20-30
- Total AT earned: ~1 million

**Year 1:**
- Reach wave 1,000+
- Permanent upgrades level 20-30
- Labs level 50-70
- Unlock tier 2-3
- Total AT earned: ~100 million

**Year 3 (Endgame):**
- Reach wave 5,000+
- Permanent upgrades level 40-60
- Labs mostly maxed
- Tier 5-7 unlocked
- Total AT earned: ~10 billion

---

## 💡 Tuning Recommendations

**If progression too slow:**
- Increase AT multipliers (easier to change)
- Reduce permanent upgrade costs (recalculate all levels)
- Increase offline efficiency (25% → 35%)
- Add more fragment sources

**If progression too fast:**
- Decrease AT multipliers
- Increase permanent upgrade cost scaling (1.13 → 1.15)
- Reduce offline efficiency
- Make labs take longer

**Test metrics:**
- Player should unlock 1-2 permanent levels per session (30-60min)
- Labs should complete while offline (overnight/work)
- Boss rush should feel rewarding but not mandatory
- Fragments should accumulate steadily (not bottleneck drones)

---

## 📈 Economy Health Checks

Run these checks periodically:

1. **Can player progress without paying?** (Yes = healthy)
2. **Are there always goals to work toward?** (Yes = healthy)
3. **Do choices matter?** (Can't afford everything = healthy)
4. **Is offline progress fair?** (25-50% efficiency = healthy)
5. **Do veterans have content?** (Tier 10 exists = healthy)

---

**All formulas implemented in code. See respective manager files for exact calculations.**

**Next: Create game_balance.json to externalize these values for easy tuning!**
