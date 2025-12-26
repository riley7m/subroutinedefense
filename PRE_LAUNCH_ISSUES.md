# Pre-Launch Issues & Setup Analysis

**Date:** 2025-12-26
**Status:** Critical issues found - NOT ready for launch

---

## 🔴 CRITICAL - Will Crash on Startup

### 1. **Missing Scene Node: `UpgradesBox/DamageUpgradeLabel`**
**Location:** `main_hud.gd:114`
```gdscript
@onready var damage_label: Label = $UpgradesBox/DamageUpgradeLabel
```

**Problem:**
- This node path doesn't exist in `main_hud.tscn`
- Game will crash on startup with: `"Invalid get index 'text' (on base: 'null instance')"`
- Used in lines 318, 361, 387

**Impact:** ⚠️ **INSTANT CRASH** on game launch

**Fix:**
Either:
- A) Remove the @onready line and make damage_label optional
- B) Add the missing UpgradesBox container to main_hud.tscn

**Recommended Fix A (Quick):**
```gdscript
# Line 114 - Remove this line entirely
# @onready var damage_label: Label = $UpgradesBox/DamageUpgradeLabel

# Line 361 - Make function do nothing (it only prints anyway)
func update_damage_label() -> void:
    # Debug function - no UI update needed
    pass
```

---

## 🟡 HIGH PRIORITY - Likely Bugs

### 2. **Fragment Notification Position Error**
**Location:** `ScreenEffects.gd:348`
```gdscript
notification.global_position = position - Vector2(50, 50)
```

**Problem:**
- `notification` is a Control node (Label)
- Control nodes use `position`, not `global_position` when added to UI tree
- World coordinates (from boss death) don't translate to screen space
- Notification will appear at wrong position or off-screen

**Impact:** Fragment notifications won't show where bosses die

**Fix:**
Need to convert world position to screen coordinates:
```gdscript
# Get the camera/viewport to convert coordinates
var viewport = parent.get_viewport()
if viewport and viewport.get_camera_2d():
    var camera = viewport.get_camera_2d()
    var screen_pos = position - camera.global_position + viewport.get_visible_rect().size / 2
    notification.position = screen_pos - Vector2(50, 50)
else:
    # Fallback: center screen
    notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notification.set_anchors_preset(Control.PRESET_FULL_RECT)
```

---

### 3. **PlayFab Title ID Validity Unknown**
**Location:** `CloudSaveManager.gd:14`
```gdscript
const PLAYFAB_TITLE_ID = "1DEAD6"
```

**Problem:**
- Is "1DEAD6" a real PlayFab title or placeholder?
- No way to verify without testing
- If invalid, all cloud saves will fail silently

**Impact:** Cloud saves completely broken if Title ID is fake

**Test Required:**
1. Go to PlayFab dashboard (https://developer.playfab.com/)
2. Verify "1DEAD6" exists in your titles
3. Check API access is enabled
4. Test with guest login first

---

### 4. **StartScreen Buttons Non-Functional**
**Location:** `start_screen.gd:36-40`
```gdscript
func _on_settings_button_pressed() -> void:
    print("test")  # Does nothing

func _on_permanent_upgrades_button_pressed() -> void:
    print("test")  # Does nothing
```

**Problem:**
- Settings button just prints "test"
- Permanent upgrades button just prints "test"
- Players can only start game, not access other features from menu

**Impact:** Menu navigation incomplete

**Fix:**
Either:
- Hide these buttons until implemented
- Add basic scenes for settings/perm upgrades
- Keep "test" but disable buttons visually

---

## 🟢 VERIFIED WORKING

### ✅ Scene Structure
- **main_hud.tscn** - All major nodes exist:
  - TopBanner (WaveLabel, ATLabel, DCLabel) ✓
  - BottomBanner (SpeedButton, BuyXButton) ✓
  - UpgradeUI (Offense/Defense/Economy panels) ✓
  - PermUpgradesPanel (all 11 permanent upgrades) ✓
  - Spawner, Tower, DeathScreen ✓

### ✅ All Scripts Exist
- All 35 .gd files present
- All preloaded scripts exist:
  - boss_rush_death_screen.gd ✓
  - boss_rush_ui.gd ✓
  - offline_progress_popup.gd ✓
  - software_upgrade_ui.gd ✓
  - tier_selection_ui.gd ✓
  - login_ui.gd ✓
  - Background effects (MatrixCodeRain, etc.) ✓

### ✅ Resources Exist
- 6 shader files (.gdshader) ✓
- 18 scene files (.tscn) ✓
- UI fonts and themes ✓
- All drone scenes ✓
- All enemy scenes ✓

### ✅ Autoloads Configured
All 12 singletons registered in project.godot:
- VisualFactory, AdvancedVisuals, ParticleEffects ✓
- ScreenEffects, UIStyler, ObjectPool ✓
- TierManager, BossRushManager, CloudSaveManager ✓
- RewardManager, UpgradeManager, RunStats ✓
- SoftwareUpgradeManager ✓

---

## 🧪 UNTESTED FEATURES

### Cannot Test Without Godot Engine

**Boss Rush:**
- [ ] Tournament timing (Mon/Thu/Sat check)
- [ ] Boss-only spawning
- [ ] Death screen displays correctly
- [ ] Fragment rewards granted
- [ ] Leaderboard saves/loads

**PlayFab:**
- [ ] Guest login works
- [ ] Email registration works
- [ ] Save upload succeeds
- [ ] Save download works
- [ ] Conflict resolution
- [ ] Network error handling

**Offline Progress:**
- [ ] Popup shows on return
- [ ] Calculations are correct
- [ ] 24-hour cap works
- [ ] Labs complete offline
- [ ] No negative/infinite progress

**Fragments:**
- [ ] Notifications appear on boss kills
- [ ] Position is correct
- [ ] Can spend on drone upgrades
- [ ] Boss rush rewards

**UI Panels:**
- [ ] Software labs panel renders correctly
- [ ] Tier selection works
- [ ] Boss rush UI shows tournament status
- [ ] Statistics panel displays data
- [ ] Login UI layout works on 390x844

---

## 🛠️ REQUIRED FIXES BEFORE LAUNCH

### **MUST FIX (Will Crash):**
1. ✅ Remove or fix `damage_label` reference in main_hud.gd:114

### **SHOULD FIX (Major Bugs):**
2. ✅ Fix fragment notification positioning (world → screen coords)
3. ⚠️ Verify PlayFab Title ID is valid (requires web access)
4. ✅ Disable or implement StartScreen buttons (settings/perm upgrades)

### **NICE TO FIX (Polish):**
5. Add error handling for missing camera in fragment notifications
6. Add loading screen between StartScreen and main game
7. Add "Coming Soon" text for unimplemented buttons

---

## 📋 PRE-LAUNCH TEST CHECKLIST

Run these tests in order:

### **Phase 1: Launch Test**
1. [ ] Game launches without errors
2. [ ] StartScreen appears
3. [ ] Can click "Start Game"
4. [ ] MainHUD scene loads
5. [ ] No console errors

### **Phase 2: Basic Gameplay**
6. [ ] Tower appears and shoots
7. [ ] Enemies spawn and move
8. [ ] Can buy upgrades with DC
9. [ ] Wave counter increases
10. [ ] Can die and see death screen
11. [ ] Can restart after death

### **Phase 3: Fragment System**
12. [ ] Kill first boss (wave 10)
13. [ ] See "+X 💎" notification appear
14. [ ] Fragment count increases in HUD
15. [ ] Can spend fragments on drone upgrades
16. [ ] Drone spawns and attacks

### **Phase 4: Boss Rush**
17. [ ] Check today's day (Mon/Thu/Sat?)
18. [ ] Click "🏆 Rush" button
19. [ ] Tournament status shows correctly
20. [ ] Can start boss rush (if available)
21. [ ] Only bosses spawn in boss rush
22. [ ] Death screen shows rank and fragments

### **Phase 5: Cloud Saves**
23. [ ] Login UI appears on first launch
24. [ ] Can click "Play as Guest"
25. [ ] Game proceeds after login
26. [ ] Play for a bit, then close game
27. [ ] Reopen - progress persists
28. [ ] Check PlayFab dashboard for save data

### **Phase 6: Offline Progress**
29. [ ] Close game for 5 minutes
30. [ ] Reopen game
31. [ ] See offline progress popup
32. [ ] AT rewards seem reasonable
33. [ ] Labs that were running completed

### **Phase 7: Software Labs**
34. [ ] Click "🔬 Labs" button
35. [ ] Lab panel opens
36. [ ] Can start a lab (costs AT)
37. [ ] Lab shows time remaining
38. [ ] Lab completes and grants bonus

### **Phase 8: Tier System**
39. [ ] Click "🎖️ Tiers" button
40. [ ] Shows current tier (Tier 1)
41. [ ] Shows unlock requirements
42. [ ] (Can't test tier unlock without grinding)

---

## 🚀 MINIMUM VIABLE PRODUCT (MVP)

**To have a playable alpha, you NEED:**

✅ **Working:**
- Basic tower defense gameplay
- Upgrade systems (DC, AT)
- Death and restart
- Save/load

❌ **Can Be Broken:**
- Boss rush (feature can be disabled if timing is wrong)
- Cloud saves (can use local saves only for alpha)
- Offline progress (can disable for alpha)
- Fragments (can disable if notifications broken)

**Recommendation:** Fix the 2 critical bugs, test basic gameplay, then decide which features to enable for alpha.

---

## 📊 LAUNCH READINESS: 40%

**Why only 40%?**
- ❌ Critical crash bug exists (damage_label)
- ❌ No testing done whatsoever
- ❌ Major features untested (boss rush, cloud, offline)
- ⚠️ PlayFab integration unverified
- ✅ Code is complete and structured well
- ✅ All files and resources exist

**To reach 90% (launchable alpha):**
1. Fix the 2 critical bugs (1 hour)
2. Test basic gameplay (30 min)
3. Verify PlayFab Title ID (5 min)
4. Disable untested features (30 min)
5. Playtest for crashes (1 hour)

**Estimated time to launchable alpha: 3-4 hours**

---

**Next Step:** Fix critical bugs or run first test?
