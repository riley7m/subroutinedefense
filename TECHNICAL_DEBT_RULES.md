# Technical Debt Management Rules

**Created:** 2025-12-27
**Status:** Active Development Policy

---

## 🚫 RULE #1: main_hud.gd Function Freeze

### Context
`main_hud.gd` is a **god object** (1383 lines, 9.7% of codebase) that violates Single Responsibility Principle. It handles:
- UI updates
- Upgrade panels
- Statistics display
- Tier transitions
- Boss Rush integration
- Drone spawning
- Wave management

### Policy

**❌ DO NOT add new functions to `main_hud.gd` unless ABSOLUTELY CRITICAL**

**Definition of "Absolutely Critical":**
1. Game-breaking bug that can ONLY be fixed in main_hud
2. Security vulnerability requiring immediate patch
3. Critical integration point that has NO other solution

**✅ DO create new separate files/classes instead:**
- New panel UI → Create new `*_panel.gd` script
- New game mode → Create new `*Manager.gd` autoload
- New feature → Create dedicated controller/manager

### Examples

**❌ BAD (adds to main_hud):**
```gdscript
# main_hud.gd
func handle_daily_rewards():
    # 50 lines of daily reward logic
```

**✅ GOOD (new file):**
```gdscript
# DailyRewardManager.gd (new autoload)
extends Node

func handle_daily_rewards():
    # 50 lines of daily reward logic
```

---

**❌ BAD (adds to main_hud):**
```gdscript
# main_hud.gd
func show_achievement_popup(achievement_id):
    # 30 lines of achievement UI
```

**✅ GOOD (separate scene):**
```gdscript
# achievement_popup.gd (attached to scene)
extends Control

func show_achievement(achievement_id):
    # 30 lines of achievement UI
```

---

### Enforcement

**Before adding ANY function to main_hud.gd:**
1. Ask: "Can this be in a separate file?"
2. If yes: Create separate file
3. If no: Ask again, harder
4. If still no: Document why in commit message

### Technical Debt Paydown Plan

**Future refactor (V1.1+):**

Split `main_hud.gd` into:
1. `GameController.gd` (150 lines) - Core game state
2. `UIManager.gd` (200 lines) - Label updates
3. `PanelManager.gd` (300 lines) - Panel visibility
4. `StatisticsManager.gd` (100 lines) - Stats display
5. `UpgradePanelController.gd` (400 lines) - Upgrade UI
6. `DroneSpawner.gd` (100 lines) - Drone lifecycle

**Estimated effort:** 24 hours
**Current priority:** LOW (post-launch)
**Reason:** Working code, non-blocking for launch

---

## 💡 RULE #2: Code Duplication Awareness

### Save/Load Logic

**Current duplication:**
- `RewardManager.gd` (230 lines)
- `SoftwareUpgradeManager.gd` (150 lines)
- `BossRushManager.gd` (33 lines)
- **Total:** 413 lines duplicated

**Future fix:** Create `SaveManager.gd` autoload (V1.1+)

---

### Upgrade UI Logic

**Current duplication:**
- 20+ upgrade types
- ~45 lines per upgrade
- **Total:** ~900 lines duplicated in `main_hud.gd`

**Future fix:** Data-driven upgrade panel scene (V1.1+)

---

## 🎯 RULE #3: New Features Checklist

Before implementing ANY new feature:

- [ ] Can it be a separate file/script?
- [ ] Does it need to touch main_hud?
- [ ] If yes to #2, can it be minimized?
- [ ] Is there existing duplication that could be unified?
- [ ] Will this add to technical debt?

---

## 📊 Technical Debt Metrics

**Current Debt:** ~80 hours
- main_hud refactor: 24 hours
- Circular dependency fix: 16 hours
- Save/load unification: 12 hours
- Test coverage expansion: 20 hours
- Performance optimization: 8 hours

**Debt Interest Rate:** ~2 hours per new feature (due to god object)

**Acceptable Debt Level:** < 100 hours
**Current Level:** 80 hours ✅
**Status:** ACCEPTABLE - Ship now, refactor post-launch

---

## 🚀 Priority Order

### P0 (Ship Blockers)
1. Fix critical bugs
2. Security vulnerabilities
3. Game-breaking issues

### P1 (Launch Features)
4. Core gameplay
5. Progression systems
6. Online multiplayer

### P2 (Quality)
7. Performance optimization
8. UX polish
9. Tutorial/onboarding

### P3 (Post-Launch)
10. Technical debt paydown
11. Code refactoring
12. Architecture improvements

---

## 📝 Commit Message Template

When adding to main_hud (rare exceptions):

```
Add [feature] to main_hud (EXCEPTION)

Reason for exception:
- [Explain why it MUST be in main_hud]
- [Alternatives considered: X, Y, Z - why rejected]

Technical debt impact:
- Added [X] lines to main_hud
- New debt: [estimate hours for future refactor]

Plan for cleanup:
- [V1.X: Move to separate controller]
```

---

## ✅ Success Criteria

**We're managing debt well when:**
- main_hud.gd stays < 1500 lines
- New features don't add to god object
- Duplication is minimized
- Tests are added for critical paths
- Performance stays acceptable

**We're failing when:**
- main_hud.gd exceeds 1500 lines
- Every feature touches main_hud
- Duplication increases
- No tests for new code
- Performance degrades

---

**Reviewed:** Every major release
**Updated:** As needed
**Owner:** Lead developer
**Enforced:** Code review process

---

**Remember:** Ship fast, refactor later. But don't make "later" impossible! ✨
