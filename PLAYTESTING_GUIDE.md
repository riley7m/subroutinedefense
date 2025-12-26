# Playtesting Guide - Subroutine Defense

**Version:** 1.0
**Last Updated:** 2025-12-26
**For Build:** Alpha

---

## 🎯 Purpose

This guide provides a structured approach to playtesting Subroutine Defense. Follow the tests in order - each builds on the previous one. If a test fails, note it and continue (unless it's a crash).

---

## 📋 Pre-Testing Checklist

Before you start:
- [ ] Godot 4.4 installed
- [ ] Project opens without errors
- [ ] Device/emulator ready (390x844 resolution recommended)
- [ ] Notepad open for bug notes
- [ ] 30-60 minutes available for full test

---

## ⚡ Quick Smoke Test (5 minutes)

**Goal:** Verify game launches and basic loop works

### Test 1: Launch
1. Open project in Godot
2. Press F5 (Run)
3. **Expected:** StartScreen appears, no console errors
4. **If fails:** Screenshot error, check console

### Test 2: Start Game
1. Click "Start Game" button
2. **Expected:** Loads to MainHUD scene
3. **Check:** Tower visible, UI panels exist

### Test 3: Basic Gameplay
1. Wait for enemies to spawn (wave 1)
2. Watch tower shoot
3. **Expected:** Projectiles hit enemies, enemies die, DC increases

### Test 4: Buy Upgrade
1. Click "Offense" button
2. Click "Damage" upgrade
3. **Expected:** DC decreases, damage increases

### Test 5: Die
1. Let enemies through (don't buy upgrades)
2. Wait for tower HP to reach 0
3. **Expected:** Death screen appears, can restart

**If all 5 pass:** Game is minimally functional ✅

---

## 🔍 Full Feature Test (60 minutes)

### PHASE 1: Core Gameplay (15 min)

#### Test 1.1: Wave Progression
- [ ] Wave counter increases
- [ ] Enemy count scales (10 base)
- [ ] Boss spawns at wave 10
- [ ] Boss is stronger (more HP)
- [ ] Wave skip works if upgraded

#### Test 1.2: In-Run Upgrades (DC)
**Offense:**
- [ ] Damage upgrade costs 50 DC initially
- [ ] Cost increases 15% per purchase (50→58→87→176...)
- [ ] Fire Rate works
- [ ] Crit Chance works (see crits happen)
- [ ] Crit Damage multiplier works
- [ ] Multi-Target unlock (1000 DC first purchase)
- [ ] Multi-Target upgrade increases max targets

**Defense:**
- [ ] Shield Integrity adds shield bar
- [ ] Damage Reduction reduces damage taken
- [ ] Shield Regen heals over time

**Economy:**
- [ ] DC Multiplier increases DC earned
- [ ] AT Multiplier increases AT earned
- [ ] Wave Skip chance skips waves
- [ ] Free Upgrade chance gives free purchases

#### Test 1.3: Death & Restart
- [ ] Death screen shows stats (wave, damage dealt)
- [ ] Can restart run
- [ ] DC resets to 0
- [ ] AT persists
- [ ] Permanent upgrades persist

---

### PHASE 2: Permanent Progression (15 min)

#### Test 2.1: Permanent Upgrades (AT)
Open permanent upgrades panel:
- [ ] Shows all 11 core upgrades
- [ ] Costs display correctly
- [ ] First purchase costs match expected (5000-18000 AT range)
- [ ] Level increases when purchased
- [ ] AT decreases
- [ ] Bonus applies in next run

**Test exponential scaling:**
- Buy damage upgrade 5 times
- Expected costs: 5650 → 6384 → 7214 → 8152 → 9211 AT
- Formula: 5000 * (1.13^level)

#### Test 2.2: Drone Upgrades (Fragments)
- [ ] Shows 4 drone types (flame, frost, poison, shock)
- [ ] Costs fragments (not AT)
- [ ] Level increases
- [ ] Next run: drone appears and attacks
- [ ] Each drone has unique behavior

**Verify drone behaviors:**
- Flame: Targets low HP, applies burn DOT
- Frost: Targets fast enemies, slows them
- Poison: Targets low HP, applies poison DOT
- Shock: Targets close enemies, stuns them

---

### PHASE 3: Software Labs (15 min)

#### Test 3.1: Lab System
Click "🔬 Labs" button:
- [ ] Panel opens with lab list
- [ ] Shows 2 slots available
- [ ] Labs categorized by tier (1, 2, 3)

#### Test 3.2: Start Lab
Pick "Damage Processing" (Tier 1, 500 AT, 1h):
- [ ] Costs AT to start
- [ ] Shows in active slot
- [ ] Timer counts down
- [ ] Can start second lab in slot 2

#### Test 3.3: Lab Completion
**Option A (Wait):** Wait 1 hour, check completion
**Option B (Cheat):** Manually set timer to 1 second in code

- [ ] Lab completes
- [ ] Bonus applied (+10 damage per level)
- [ ] Slot becomes empty
- [ ] Can start next level (level 2)

**Test cost scaling:**
- Level 1: 500 AT, 1h
- Level 2: 540 AT, 1.05h
- Level 10: 999 AT, 1.6h
- Formula: base * (1.08^(level-1))

---

### PHASE 4: Boss Rush Tournament (10 min)

#### Test 4.1: Availability Check
Click "🏆 Rush" button:
- [ ] Panel opens
- [ ] Shows tournament schedule (Mon/Thu/Sat)
- [ ] Shows "Active" or "Next: [Day] ([X]h)"

**Check current day:**
- If Mon/Thu/Sat: Should be ACTIVE ✅
- If other day: Should be LOCKED 🔒

#### Test 4.2: Boss Rush Start (If Available)
- [ ] Start button enabled
- [ ] Click "Start Boss Rush"
- [ ] Game starts
- [ ] Only bosses spawn (no normal enemies)

#### Test 4.3: Boss Rush Mechanics
- [ ] Wave 1-9: 1 boss per wave
- [ ] Wave 10-19: 2 bosses per wave
- [ ] Wave 20-29: 3 bosses per wave
- [ ] Max 10 bosses at wave 100+
- [ ] Bosses have 13% more HP per wave (vs 2% normal)
- [ ] Bosses move 3x faster

#### Test 4.4: Boss Rush Death
Die in boss rush:
- [ ] Custom death screen appears
- [ ] Shows damage dealt
- [ ] Shows waves survived
- [ ] Shows rank (#1, #2, etc.)
- [ ] Shows fragment reward
- [ ] Shows top 5 leaderboard preview
- [ ] Fragments actually awarded

**Test leaderboard:**
- [ ] Your score appears in list
- [ ] Sorted by damage (not waves)
- [ ] Saves between sessions

---

### PHASE 5: Cloud Saves (10 min)

#### Test 5.1: First Launch
- [ ] Login UI appears on startup
- [ ] Shows 3 options: Login, Register, Guest

#### Test 5.2: Guest Login
Click "Play as Guest":
- [ ] Login succeeds
- [ ] Game proceeds
- [ ] Device ID created

#### Test 5.3: Save Upload
Play for a few waves, then:
- [ ] Close game
- [ ] Check PlayFab dashboard
- [ ] SaveData should exist

#### Test 5.4: Save Download
Reopen game:
- [ ] Progress restored
- [ ] AT count matches
- [ ] Permanent upgrades persist
- [ ] Labs persist

#### Test 5.5: Guest → Email Binding
Open Statistics panel:
- [ ] Shows "Guest Account"
- [ ] Shows "Bind Email" button
- [ ] Click it
- [ ] Enter email/password
- [ ] Binding succeeds
- [ ] Now shows "Registered Account"

#### Test 5.6: Multi-Device (Advanced)
Login on second device with same email:
- [ ] Progress syncs
- [ ] Newest save wins (conflict resolution)

---

### PHASE 6: Offline Progress (5 min)

#### Test 6.1: Offline Calculation
1. Note current AT amount
2. Close game for 5 minutes
3. Reopen game

Expected:
- [ ] Popup appears: "Welcome Back!"
- [ ] Shows time away
- [ ] Shows waves cleared offline
- [ ] Shows AT earned
- [ ] AT added to total

**Verify calculation:**
- Should use best run from last 7 days as baseline
- Efficiency: 25% (or 50% if ad watched)
- Cap: 24 hours max

#### Test 6.2: Lab Offline Completion
1. Start a 1h lab
2. Close game for 1 hour
3. Reopen

Expected:
- [ ] Lab completed while offline
- [ ] Bonus applied
- [ ] Slot available

---

### PHASE 7: Tier System (5 min)

#### Test 7.1: Tier Selection
Click "🎖️ Tiers" button:
- [ ] Shows tier 1 (unlocked by default)
- [ ] Shows unlock requirements for tier 2 (5000 waves)
- [ ] Shows multipliers (enemies 10x, rewards 5x)

#### Test 7.2: Tier Switching (If Unlocked)
If tier 2+ unlocked:
- [ ] Can switch to tier 2
- [ ] Enemies are 10x stronger
- [ ] Rewards are 5x higher
- [ ] Progress saves per tier

---

## 🐛 Bug Reporting Template

When you find a bug, note:

```
BUG: [Short description]
Steps to reproduce:
1.
2.
3.

Expected: [What should happen]
Actual: [What actually happened]

Console errors: [Paste if any]
Screenshot: [Attach if relevant]
```

---

## 🎮 Balance Observations

As you play, note:

### Pacing
- **Too fast:** Features unlock too quickly, overwhelming
- **Too slow:** Boring, stuck waiting for progress
- **Just right:** Steady unlock pace, always something to do

### Difficulty
- **Too easy:** Can AFK and win
- **Too hard:** Can't survive even with upgrades
- **Just right:** Requires strategy and upgrades

### Economy
- **DC:** Is it abundant or scarce? Can you afford upgrades?
- **AT:** Does progression feel rewarding or grindy?
- **Fragments:** Are bosses rewarding enough?

### Features
- **Most fun:** What did you enjoy?
- **Most boring:** What felt like a chore?
- **Most confusing:** What needed explanation?

---

## ✅ Success Criteria

**Minimum Viable (Alpha):**
- [ ] Game launches without crash
- [ ] Can play to wave 10
- [ ] Can buy upgrades
- [ ] Can die and restart
- [ ] Progress saves locally

**Feature Complete (Beta):**
- [ ] All systems work (boss rush, labs, tiers)
- [ ] Cloud saves work
- [ ] Offline progress works
- [ ] No major bugs
- [ ] Feels fun for 30+ minutes

**Launch Ready:**
- [ ] No crashes in 1 hour playtest
- [ ] All features tested and working
- [ ] Economy feels balanced
- [ ] Tutorials/tooltips exist
- [ ] Performance is good (60 FPS)

---

## 📊 Performance Metrics

Watch for:
- **FPS:** Should stay 60fps
- **Memory:** Should not leak (check Godot profiler)
- **Load times:** <2 seconds for scene transitions
- **Save times:** Instant (no lag)

If FPS drops below 30, note when it happens (wave number, enemy count, etc.)

---

## 🚨 Critical Issues (Stop Testing)

If any of these occur, STOP and report immediately:
- ❌ Crashes to desktop
- ❌ Data loss (progress deleted)
- ❌ Infinite loop (game freezes)
- ❌ Cannot restart after death
- ❌ Negative currency/stats

---

## 💡 Tips

- Test with fresh eyes (take breaks)
- Try to break things (spam buttons, edge cases)
- Play like a real user (not a developer)
- Note first impressions (can't get those back)
- Have fun! If it's not fun for you, it won't be fun for players

---

**Ready to test? Start with Quick Smoke Test, then move to Full Feature Test.**

**Good luck! 🎮**
