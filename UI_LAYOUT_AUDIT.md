# UI Layout Audit Report - Subroutine Defense

**Date:** 2025-12-29
**Screen Resolution:** 390x844 (Mobile Portrait)
**Status:** 🔴 CRITICAL ISSUES FOUND

---

## 🚨 CRITICAL PROBLEMS

### 1. Bottom Menu Buttons - OFF SCREEN (y=800)

**Current Layout:**
```
Screen Width: 390px
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
|                                        |← 390px edge
| [Labs] [Tiers] [Rush] [Stats] [Drones] [Shop] [Pass] [Achieve]
|   ✅     ✅      ✅      ⚠️       ❌      ❌     ❌      ❌
```

**Detailed Positions:**
1. 🔬 Labs: x=5, width=90 → **ends at 95** ✅ Fits
2. 🎖️ Tiers: x=100, width=90 → **ends at 190** ✅ Fits
3. 🏆 Rush: x=195, width=90 → **ends at 285** ✅ Fits
4. 📊 Stats: x=290, width=95 → **ends at 385** ⚠️ Only 5px margin!
5. 🚁 Drones: x=390, width=95 → **ends at 485** ❌ **OFF SCREEN** (95px overflow)
6. 💎 Shop: x=490, width=90 → **ends at 580** ❌ **OFF SCREEN** (190px overflow)
7. 🎖️ Pass: x=585, width=90 → **ends at 675** ❌ **OFF SCREEN** (285px overflow)
8. 🏆 Achieve: x=680, width=100 → **ends at 780** ❌ **OFF SCREEN** (390px overflow)

**Impact:** **4 out of 8 buttons are completely invisible!**

---

### 2. Progression Panels - TOO WIDE

All panels positioned at x=15 (15px left margin).
**Maximum safe width:** 360px (15px + 360px + 15px = 390px)

**Panel Audit:**

| Panel | Width | Ends At | Status | Overflow |
|-------|-------|---------|--------|----------|
| software_upgrade_ui.gd | 360px | 375px | ✅ Fits | 0px |
| **drone_upgrade_ui.gd** | **420px** | **435px** | ❌ Overflow | **45px** |
| **quantum_core_shop_ui.gd** | **460px** | **475px** | ❌ Overflow | **85px** |
| milestone_ui.gd | 360px | 375px | ✅ Fits | 0px |
| **achievement_ui.gd** | **480px** | **495px** | ❌ Overflow | **105px** |
| tier_selection_ui.gd | 360px | 375px | ✅ Fits | 0px |
| boss_rush_ui.gd | 360px | 375px | ✅ Fits | 0px |
| **statistics_panel** | **600px** | **900px** | ❌ Massive! | **510px** |

**Impact:** 4 out of 8 panels overflow the screen horizontally!

---

### 3. Statistics Panel - WRONG POSITION

```gdscript
statistics_panel.custom_minimum_size = Vector2(600, 700)
statistics_panel.position = Vector2(300, 100)
```

- **Width:** 600px
- **Position:** x=300
- **Ends at:** 900px
- **Screen width:** 390px
- **Overflow:** **510px** (panel is wider than the entire screen!)

This panel also starts at x=300, which means the left edge is already off-screen!

---

## 📐 LAYOUT ANALYSIS

### Screen Dimensions
- **Width:** 390px
- **Height:** 844px
- **Orientation:** Portrait (Mobile)

### Safe Zones
- **Left margin:** 15px
- **Right margin:** 15px
- **Usable width:** 360px (15 + 360 + 15 = 390)

### Fixed UI Elements (Always Visible)

**TopBanner (from main_hud.tscn):**
- WaveLabel: x=6, y=? (assumed top)
- ATLabel: x=6, y=? (assumed ~20-25)
- DCLabel: x=6, y=? (assumed ~40-45)
- FragmentsLabel: x=6, y=45 (programmatic)
- TierLabel: x=6, y=70 (programmatic)

**BottomBanner:**
- SpeedButton: position unknown (needs check)
- BuyXButton: position unknown (needs check)

**UpgradeUI (toggleable):**
- Offense/Defense/Economy panels: positions unknown (needs scene file check)

---

## 🔧 REQUIRED FIXES

### Priority 1: Bottom Menu Buttons (BLOCKING)

**Problem:** 4 buttons invisible off-screen

**Solutions:**

#### Option A: Two Rows of Buttons ⭐ RECOMMENDED
```
Row 1 (y=755):  [Labs] [Tiers] [Rush] [Stats]
Row 2 (y=800):  [Drones] [Shop] [Pass] [Achieve]

Button width: 90px each
Spacing: 5px between
Total row width: 90*4 + 5*3 = 375px
Centered: (390-375)/2 = 7.5px left margin
```

**Layout:**
```gdscript
# Row 1
Labs:    x=8,   y=755, width=90
Tiers:   x=103, y=755, width=90
Rush:    x=198, y=755, width=90
Stats:   x=293, y=755, width=90

# Row 2
Drones:  x=8,   y=800, width=90
Shop:    x=103, y=800, width=90
Pass:    x=198, y=800, width=90
Achieve: x=293, y=800, width=90
```

#### Option B: Scrollable Button Bar
- Create HBoxContainer with ScrollContainer
- Allows swiping to see all buttons
- Less ideal UX but keeps single row

#### Option C: Hamburger Menu
- Single "☰ Menu" button that opens all options
- Best for mobile but requires more UI work

---

### Priority 2: Fix Panel Widths

**Panels that need resizing:**

1. **drone_upgrade_ui.gd:**
   ```gdscript
   # Line 52
   panel.custom_minimum_size = Vector2(420, 780)
   # Change to:
   panel.custom_minimum_size = Vector2(360, 780)
   ```

2. **quantum_core_shop_ui.gd:**
   ```gdscript
   # Line 45 (estimated)
   panel.custom_minimum_size = Vector2(460, 780)
   # Change to:
   panel.custom_minimum_size = Vector2(360, 780)
   ```

3. **achievement_ui.gd:**
   ```gdscript
   # Line 30
   panel.custom_minimum_size = Vector2(480, 780)
   # Change to:
   panel.custom_minimum_size = Vector2(360, 780)
   ```

4. **statistics_panel (main_hud.gd):**
   ```gdscript
   # Line 1303-1304
   statistics_panel.custom_minimum_size = Vector2(600, 700)
   statistics_panel.position = Vector2(300, 100)
   # Change to:
   statistics_panel.custom_minimum_size = Vector2(360, 700)
   statistics_panel.position = Vector2(15, 100)
   ```

**Impact:** All panels will fit within the 390px screen width.

---

### Priority 3: Adjust Inner Content

After panel resize, inner widgets need width adjustments:

**drone_upgrade_ui.gd:**
- slots_panel: 380px → 320px
- tab buttons: may need smaller width
- upgrade_scroll: 380px → 320px

**quantum_core_shop_ui.gd:**
- qc_balance_label: 420px → 320px
- tab buttons: may need adjustment
- content_scroll: 420px → 320px

**achievement_ui.gd:**
- total_qc_label: 440px → 320px
- achievement_scroll: 440px → 320px
- achievement_list: 420px → 320px

**statistics_panel:**
- scroll: 580px → 340px
- all labels: 550px → 320px

---

## 📊 VISUAL LAYOUT MAP

### Current Screen (390x844)

```
┌─────────────────────────────────────┐ 390px wide
│ TopBanner (Wave, AT, DC, 💎, Tier)  │ y=0-100
│                                     │
│                                     │
│                                     │
│         Game Area                   │
│      (Tower, Enemies)               │ y=100-750
│                                     │
│                                     │
│                                     │
├─────────────────────────────────────┤
│ [Labs][Tiers][Rush][Stats] ← VISIBLE│ y=755 (Row 1)
│ [Drones][Shop][Pass][Achieve]       │ y=800 (Row 2)
└─────────────────────────────────────┘

Panels (when visible):
┌──────────────────┐
│ 360px Panel      │
│ at x=15          │
│ Fits perfectly!  │
└──────────────────┘
```

---

## ✅ TESTING CHECKLIST

After fixes are applied:

- [ ] All 8 bottom buttons visible on screen
- [ ] No button extends beyond x=390
- [ ] All panels fit within 390px width
- [ ] Panel content doesn't horizontally scroll
- [ ] No UI overlap when panels are open
- [ ] Buttons/panels readable at 390px width
- [ ] Touch targets are at least 44x44px (accessibility)
- [ ] Test on actual mobile device if possible

---

## 📝 NOTES

**Why This Happened:**
- UI was designed for desktop/tablet (~1920x1080 or similar)
- Project settings show mobile target (390x844)
- Hardcoded positions didn't account for mobile viewport
- No responsive design patterns used

**Best Practices Going Forward:**
1. Use anchor presets (CENTER, TOP_RIGHT, etc.)
2. Use Container nodes (HBoxContainer, VBoxContainer)
3. Test at target resolution during development
4. Use percentage-based positioning
5. Implement responsive breakpoints if needed

---

**END OF AUDIT**
