# Economy Scaling Audit - Subroutine Defense

## Executive Summary

This document audits all currency earning rates, spending systems, and scaling across the game's 3-year progression timeline.

---

## 📊 Currency Systems

### **Data Credits (DC)**
- **Purpose**: In-run upgrades (temporary, reset on death)
- **Starting Amount**: 100,000 DC
- **Earned From**:
  - Enemy kills (scaled by wave)
  - Wave completion bonuses

### **Archive Tokens (AT)**
- **Purpose**: Permanent upgrades (persist across runs)
- **Starting Amount**: 100,000 AT (for testing)
- **Earned From**:
  - Enemy kills (scaled by wave)
  - Wave completion bonuses

### **Fragments** ❌ **TO BE REMOVED**
- **Current Status**: Used for Software Upgrades (Labs)
- **Problem**: No clear earning system implemented
- **Solution**: Remove and use AT-only for labs

---

## 💰 DC Earning Rate Analysis

### Base Enemy Rewards (No Multipliers)
```
Breacher:      1 DC
Slicer:        2 DC
Sentinel:     10 DC
Signal Runner: 8 DC
Null Walker:   6 DC
Override:    100 DC (boss, every 10 waves)
```

### Wave Scaling
Formula: `base_dc * (1.0 + wave * 0.02) * dc_multiplier`

Example progression:
```
Wave 1:  Breacher = 1 * 1.02 = 1 DC
Wave 10: Breacher = 1 * 1.20 = 1 DC
Wave 50: Breacher = 1 * 2.00 = 2 DC
Wave 100: Breacher = 1 * 3.00 = 3 DC
Wave 500: Breacher = 1 * 11.00 = 11 DC
```

### Enemies Per Wave
- Base: 10 enemies
- Scaling: +2 every 250 waves
- Cap: 40 enemies per wave

### DC Per Wave Estimate (Mixed Enemy Types)
```
Wave 1:   ~20-40 DC (10 enemies, mix of types)
Wave 10:  ~30-60 DC + 120 DC (boss) = ~190 DC
Wave 50:  ~100-200 DC
Wave 100: ~200-400 DC + ~400 DC (boss) = ~800 DC
```

### DC Multiplier Sources
**In-Run:**
- Data Credit Multiplier: 5% per level, 120 DC cost each
- Max realistic: +50% (+1.5x total)

**Permanent (AT-cost):**
- Base cost: 12,000 AT
- Increment: +750 AT per level
- Bonus: +5% per level
- Level 1: 12,000 AT → +5% (1.05x)
- Level 10: 18,750 AT → +50% (1.50x)
- Level 20: 25,500 AT → +100% (2.00x)

**Software Upgrades (Labs):**
- Resource Optimization: 50 levels
- Bonus: +1% per level
- Max: +50% (1.50x)

**Combined DC Multiplier Potential:**
- In-run: 1.50x
- Permanent: 2.00x (20 levels)
- Labs: 1.50x (50 levels)
- **Total: 4.50x** at high progression

---

## 📦 AT Earning Rate Analysis

### Base Enemy Rewards (No Multipliers)
```
Breacher:      1 AT
Slicer:        2 AT
Sentinel:      6 AT
Signal Runner: 8 AT
Null Walker:  10 AT
Override:    100 AT (boss)
```

### Wave Completion Rewards
Formula: `floor(0.25 * pow(wave, 1.15) * at_multiplier)`

```
Wave 1:   0 AT
Wave 5:   1 AT
Wave 10:  2 AT
Wave 20:  6 AT
Wave 50:  26 AT
Wave 100: 78 AT
Wave 200: 224 AT
Wave 500: 915 AT
Wave 1000: 2,456 AT
```

### AT Per Wave Estimate (Enemies + Wave Bonus)
```
Wave 10:  ~30 AT (enemies) + 2 AT (wave) + 100 AT (boss) = ~132 AT
Wave 50:  ~120 AT (enemies) + 26 AT (wave) = ~146 AT
Wave 100: ~240 AT (enemies) + 78 AT (wave) + 300 AT (boss) = ~618 AT
Wave 500: ~550 AT (enemies) + 915 AT (wave) = ~1,465 AT
```

### AT Multiplier Sources
**In-Run:**
- Archive Token Multiplier: 5% per level, 140 DC cost
- Max realistic: +50% (+1.5x)

**Permanent (AT-cost):**
- Base cost: 13,000 AT
- Increment: +850 AT per level
- Bonus: +5% per level
- Level 1: 13,000 AT → +5% (1.05x)
- Level 10: 20,650 AT → +50% (1.50x)
- Level 20: 28,300 AT → +100% (2.00x)

**Software Upgrades (Labs):**
- Archive Efficiency: 50 levels
- Bonus: +1% per level
- Max: +50% (1.50x)

**Combined AT Multiplier Potential:**
- In-run: 1.50x
- Permanent: 2.00x (20 levels)
- Labs: 1.50x (50 levels)
- **Total: 4.50x** at high progression

### Offline AT Earning
- Base: 25% of best run (AT/hour)
- With Ad: 50% of best run
- Cap: 24 hours
- Default baseline: 100 AT/hour (if no run history)

---

## 💸 Spending Systems Analysis

### 1. In-Run Upgrades (DC Cost) ✅ **FIXED - Per-Purchase Scaling (The Tower Model)**

**Per-Purchase Cost Formula:** `base_cost * (1.15 ^ purchases_this_run)`

Each upgrade tracks its own purchase count and costs 15% more with each purchase.
This system works like "The Tower - Idle Tower Defense" - costs scale with usage, not with wave progression.

**Offense:**
```
Damage:       50 DC base * (1.15^purchases) (unlimited levels)
Fire Rate:    50 DC base * (1.15^purchases) (unlimited levels)
Crit Chance: 100 DC base * (1.15^purchases) (capped at 60%)
Crit Damage: 125 DC base * (1.15^purchases) (unlimited levels)
Multi-Target: 1,000 DC base * (2.5^level) [EXPONENTIAL - unchanged]
```

**Defense:**
```
Shield:        50 DC base * (1.15^purchases)
Dam Reduction: 75 DC base * (1.15^purchases)
Shield Regen: 100 DC base * (1.15^purchases)
```

**Economy:**
```
DC Multiplier:  60 DC base * (1.15^purchases)
AT Multiplier:  70 DC base * (1.15^purchases)
Wave Skip:     400 DC base * (1.15^purchases) (capped at 25%)
Free Upgrade:  250 DC base * (1.15^purchases) (capped at 50%)
```

**Cost Progression Example (Damage Upgrade, 50 DC base):**
```
Purchase  1:     50 DC   (1.0x base)
Purchase  2:     58 DC   (1.15x)
Purchase  5:     87 DC   (1.75x)
Purchase 10:    176 DC   (3.52x)
Purchase 20:    736 DC   (14.7x)
Purchase 30:  3,075 DC   (61.5x)
Purchase 50: 36,841 DC (736.8x)
```

**Why This Works Better:**
- ✅ New players (wave 1-10, few purchases): Upgrades cost 50-200 DC → tight economy
- ✅ Late-game players (wave 5000+, many purchases): Can afford 30-50+ purchases per run
- ✅ **Wave number doesn't matter** - late-game player at wave 10,000 still starts run with 50 DC upgrades
- ✅ Permanent AT upgrades increase earning rate, allowing more purchases
- ✅ Software Upgrades increase multipliers, allowing more purchases
- ✅ Natural progression curve: early game tight, late game can max everything
- ✅ Follows proven "The Tower" incremental game model

### 2. Permanent Upgrades (AT Cost)

All use formula: `base + (increment * current_level)`

```
Stat                  Base Cost   Increment   Bonus per Level
─────────────────────────────────────────────────────────────
Projectile Damage     5,000       250         +10 damage
Fire Rate             8,000       500         +0.1 fire rate
Crit Chance           7,500       500         +1% crit
Crit Damage           9,000       500         +0.05x mult
Shield Integrity      7,000       300         +10 shield
Damage Reduction      8,000       400         +0.5% reduction
Shield Regen          8,500       400         +0.25 regen
DC Multiplier        12,000       750         +5% DC
AT Multiplier        13,000       850         +5% AT
Wave Skip            15,000     1,000         +1% skip
Free Upgrade         18,000     1,200         +1% free
```

**Cost Progression Examples:**
```
Damage (5,000 + 250*L):
  L1:  5,000 AT
  L10: 7,500 AT
  L50: 17,500 AT
  L100: 30,000 AT

AT Multiplier (13,000 + 850*L):
  L1:  13,000 AT
  L10: 21,500 AT
  L50: 55,500 AT
  L100: 98,000 AT
```

**Analysis:**
- LINEAR scaling → costs grow slowly
- Bonuses are small but permanent
- **Problem: Costs too cheap late game?**
- At wave 500, earning ~1,500 AT/wave → can buy multiple levels

### 3. Software Upgrades / Labs (AT-Only Cost) ✅ **FIXED**

**Updated System:**
- AT-only costs from level 1
- Duration scales: 1.05x - 1.12x per level
- Cost scales: 1.08x - 1.20x per level
- Fragments completely removed

**Example: Damage Processing (100 levels)**
```
Duration: base * (1.05^(level-1))
Cost: base * (1.08^(level-1))

L1:   1h,      500 AT
L10:  1.6h,    999 AT
L50:  5.7h, 25,432 AT
L100: 65h, 1,028,572 AT
```

**Lab Base Costs by Tier:**
```
Tier 1 (100-level labs): 500-600 AT base
  - Damage Processing, Fire Rate, Shield Matrix: 500 AT
  - Critical Analysis: 600 AT
  - Shield Regeneration (76 levels): 500 AT

Tier 2 (50-level labs): 1,000-1,200 AT base
  - Damage Amplification, Damage Mitigation: 1,000 AT
  - Resource Optimization, Archive Efficiency: 1,200 AT

Tier 3 (30-level labs): 2,000-5,000 AT base
  - Wave Analysis, Probability Matrix: 2,000 AT
  - Multi-Target Systems: 5,000 AT
```

**Analysis:**
- ✅ Exponential growth maintained
- ✅ Fragments completely removed
- ✅ AT costs properly scaled from level 1
- ✅ 3-year timeline achievable with 2 concurrent slots

---

## 🚨 Critical Issues

### 1. **Fragment Currency Doesn't Exist** ✅ **FIXED**
- ~~Labs require Fragments~~
- ~~No earning system for Fragments~~
- ~~Players literally cannot progress labs~~
- **IMPLEMENTED: Fragments removed, AT-only system active**

### 2. **DC Becomes Worthless Late Game** ✅ **FIXED**
- ~~DC costs are flat (100-800 DC)~~ → Now scales per-purchase (1.15^purchases)
- **IMPLEMENTED: Per-purchase exponential cost scaling like "The Tower"**
- Each upgrade costs 15% more every time you buy it in a run
- ✅ New player: Costs stay low (50-200 DC for first few purchases)
- ✅ Late-game player: Can afford many purchases due to permanent bonuses (30-50+ purchases)
- ✅ Wave-independent: Late-game players at wave 10,000 still start runs with 50 DC cost
- ✅ Natural progression: More permanent upgrades → more purchases per run → maxing feasible

### 3. **AT Permanent Upgrades Too Cheap**
- Linear scaling (base + increment*level)
- At wave 500+, earning 1,500 AT/wave
- Can buy multiple permanent upgrades per wave
- **FIX: Exponential scaling or higher increments**

### 4. **Lab Costs May Be Too High**
- Level 100 costs 91,000 AT (single lab)
- 12 labs × 100 levels avg = ~1,000,000+ AT total
- But wave 1000 gives 2,456 AT per wave
- Need ~400 waves at wave 1000 to max one lab
- **This might be okay for 3-year timeline**

---

## 📈 Recommended Economy Fixes

### Fix 1: Remove Fragments from Labs ✅ **IMPLEMENTED**
**Before:**
```gdscript
"base_cost_fragments": 50,
"base_cost_at": 0,
"at_cost_starts_at_level": 20,
```

**After (IMPLEMENTED):**
```gdscript
"base_cost_at": 500,  // AT from level 1
// Fragments completely removed
```

### Fix 2: Increase Lab AT Base Costs ✅ **IMPLEMENTED**
Fragments removed, AT costs properly scaled:

```
Tier 1 Labs (100 levels):
  Old: 0 AT → 91,445 AT (with Fragments blocking)
  NEW: 500 AT → 1,028,572 AT ✅

Tier 2 Labs (50 levels):
  Old: 50 AT → 24,085 AT (with Fragments blocking)
  NEW: 1,000-1,200 AT → ~50,000-70,000 AT ✅

Tier 3 Labs (30 levels):
  Old: 200-500 AT → 23,000-63,000 AT (with Fragments blocking)
  NEW: 2,000-5,000 AT → ~100,000-1,187,289 AT ✅
```

### Fix 3: Add DC Sinks (Future)
Consider adding:
- Respec/reset option (costly)
- Prestige currency exchange
- Cosmetics/themes
- Speed boosts

### Fix 4: Increase Permanent Upgrade Costs
Change formula from LINEAR to EXPONENTIAL:

**Before:**
```gdscript
func get_perm_cost(base: int, increment: int, level: int) -> int:
    return base + (increment * level)
```

**After:**
```gdscript
func get_perm_cost(base: int, scaling: float, level: int) -> int:
    return int(base * pow(scaling, level))
```

Example with scaling 1.15:
```
Damage (5,000 * 1.15^L):
  L1:  5,750 AT
  L10: 20,227 AT
  L50: 542,835 AT
  L100: ~11 million AT
```

---

## 🎯 Balanced Earning vs. Spending

### Early Game (Waves 1-50)
**Earning:**
- ~50-200 DC per wave
- ~50-150 AT per wave

**Spending:**
- In-run: 100-800 DC per upgrade (affordable)
- Permanent: 5,000-18,000 AT (need 50-100 waves)
- Labs: Should take a few hours each

**Balance: ✅ GOOD** - Feels rewarding but not instant

### Mid Game (Waves 50-200)
**Earning:**
- ~500-2,000 DC per wave
- ~200-800 AT per wave

**Spending:**
- In-run: Still 100-800 DC (too cheap!)
- Permanent: 10,000-50,000 AT (10-50 waves)
- Labs: Taking days to complete

**Balance: ⚠️ DC too cheap**, AT okay

### Late Game (Waves 200-1000+)
**Earning:**
- ~5,000+ DC per wave
- ~1,000-5,000+ AT per wave

**Spending:**
- In-run: Still 100-800 DC (worthless)
- Permanent: 50,000-100,000 AT (10-50 waves)
- Labs: 50,000-250,000 AT per level (weeks)

**Balance: ⚠️ DC worthless, AT labs good, permanents need exponential**

---

## ✅ Implementation Priority

1. ✅ **CRITICAL: Remove Fragments from Labs** - COMPLETED
2. ✅ **HIGH: Rebalance Lab AT Costs** - COMPLETED
3. ✅ **HIGH: Implement Per-Purchase DC Cost Scaling** - COMPLETED (The Tower model)
4. **MEDIUM: Make Permanent Upgrades Exponential** (long-term economy) - TODO
5. ~~**LOW: Add DC Sinks**~~ - NOT NEEDED (per-purchase scaling addresses this)

---

**Document Version:** 1.0
**Date:** 2025-12-25
**Status:** Ready for Implementation
