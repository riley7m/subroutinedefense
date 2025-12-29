# Start Screen Design - Subroutine Defense

**Inspired by:** The Tower's polished main menu
**Target Resolution:** 390x844 (Mobile Portrait)
**Status:** NEW ENHANCED VERSION READY

---

## 🎨 Visual Layout

```
┌─────────────────────────────────────┐ 390px wide x 844px tall
│ ┌─────────────────────────────────┐ │
│ │  💾 1.5M   📦 450   💎 2.3K     │ │ y=5-90 (Currency Panel)
│ │           🔮 150   Tier 6•3881  │ │
│ └─────────────────────────────────┘ │
│                                     │
│  ⚙️  ┌───────────────────────┐  💎 │ y=100-190 (Side buttons start)
│      │                       │  🎁 │
│  🔬  │  SUBROUTINE DEFENSE  │  ⏱️ │ y=200-280 (Title)
│      │   ═══════════════    │     │
│  🏆  └───────────────────────┘     │
│                                 🏆 │
│  📊     ┌─────────────────┐    ⏱️ │ y=300-440 (Tier Selector)
│         │   Difficulty    │       │
│  💎     │  ◀  Tier 6  ▶  │    🎖️│
│         │ Highest: 3881   │    📀│
│         │    💾 x5.0      │       │
│         └─────────────────┘       │
│                                   │
│  💎                               │ y=460-640 (Left buttons)
│  CLAIM                            │
│  Next 2d                          │
│                                   │
│  🏆                               │
│  Next 1d                          │
│                                   │
│  🎖️                              │
│  PASS                             │
│                                   │
│      ┌───────────────────┐       │ y=660-730 (Main button)
│      │   START BATTLE    │       │
│      └───────────────────┘       │
│                                   │
│ ┌──┐┌──┐┌──┐┌──┐                │ y=750-830 (Bottom nav)
│ │🚁││⬆️││📀││🎖️│               │
│ └──┘└──┘└──┘└──┘                │
└─────────────────────────────────┘
```

---

## 📐 Component Breakdown

### 1. **Top Currency Panel** (y=5-90, full width)
**Position:** x=5, y=5, size=380x85
**Contents:**
- Left side: DC (💾), AT (📦), Fragments (💎) stacked vertically
- Right side: QC (🔮), Tier/Wave info

### 2. **Game Title** (y=200-280, centered)
**Position:** x=20, y=200, size=350x80
**Contents:**
- Large "SUBROUTINE DEFENSE" text
- Animated border panel (similar to The Tower's circular title border)

### 3. **Tier Selector Panel** (y=300-440, centered)
**Position:** x=40, y=300, size=310x140
**Contents:**
- "Difficulty" label
- ◀ button (previous tier)
- "Tier X" display (large)
- ▶ button (next tier)
- "Highest Wave: X"
- "💾 xN.N" (DC multiplier)

### 4. **Left Side Buttons** (x=5, y=460+)
**Buttons:**
1. **Daily Reward** (y=460, 90x60)
   - Shows "💎 CLAIM"
   - Timer: "Next in 2d 6h"

2. **Tournament** (y=530, 90x50)
   - Shows "🏆"
   - Timer: "Next in 1d 6h"

3. **Milestone/Pass** (y=590, 90x50)
   - Shows "🎖️ PASS"

### 5. **Right Side Buttons** (x=295, y=100+, 60px spacing)
**Vertical stack:**
1. ⚙️ Settings (y=100)
2. 🔬 Labs (y=160)
3. 🏆 Achievements (y=220)
4. 📊 Stats (y=280)
5. 💎 Shop (y=340)

**Size:** 90x50 each

### 6. **Start Battle Button** (y=660, centered)
**Position:** x=75, y=660, size=240x70
**Text:** "START BATTLE" (large, 24pt)
**Action:** Transitions to main_hud.tscn

### 7. **Bottom Navigation** (y=750, full width)
**4 buttons across:** 90x80 each
1. 🚁 Drones (x=5)
2. ⬆️ Perms (x=100)
3. 📀 Disks (x=195)
4. 🎖️ Tiers (x=290)

---

## 🎯 Features

### **Separate from Game Screen** ✅
- Completely independent from main_hud.tscn
- Clean menu interface before battle
- Access to all progression systems without entering battle

### **Inspired by The Tower** ✅
- Polished, professional layout
- Currency display at top
- Central tier selector
- Side buttons for utilities
- Large "START" button
- Bottom navigation bar

### **Mobile-Optimized** ✅
- All elements fit within 390px width
- Proper spacing and touch targets (44x44+ minimum)
- Two-column layout (left/right buttons)
- Clear visual hierarchy

### **Feature Access**
**Before Battle:**
- View/spend all currencies
- Select tier difficulty
- Access Labs (software upgrades)
- View Achievements
- Check Stats
- Open Shop
- Upgrade Drones
- View Milestones
- Claim daily rewards
- Join tournaments

---

## 🔄 Differences from The Tower

| Feature | The Tower | Subroutine Defense |
|---------|-----------|-------------------|
| Central Element | Circular portal animation | Game title with border |
| Currencies | Top banner | Top panel (4 currencies) |
| Tier Selection | Center with arrows | Center with arrows ✓ |
| Side Buttons | Right side only | Both left & right sides |
| Daily Rewards | Left side with timer | Left side with timer ✓ |
| Bottom Nav | Icon-based | Icon + text labels |
| Color Scheme | Purple/Blue | Purple/Blue (cyberpunk) |
| Battle Button | "BATTLE" | "START BATTLE" |

**Similarities:** ✓
**Unique to SD:** Multi-currency system, separate labs/shop buttons, permanent upgrades access

---

## 🚀 Implementation

### **Files:**
1. **start_screen_enhanced.gd** (NEW) - Full implementation
2. **start_screen.gd** (OLD) - Simple 3-button version

### **How to Use:**

**Option 1: Replace Existing**
```bash
mv start_screen.gd start_screen_old.gd.bak
mv start_screen_enhanced.gd start_screen.gd
```

**Option 2: Update Scene File**
Open `StartScreen.tscn` in Godot, change script from `start_screen.gd` to `start_screen_enhanced.gd`

**Option 3: Create New Scene**
Create `StartScreenEnhanced.tscn` with the new script, update project.godot to use it as main scene

---

## 📝 TODO Integration Points

### **Daily Rewards System**
- Needs implementation in DailyRewardManager.gd
- Timer countdown logic
- Claim button functionality

### **Tournament/Event System**
- Connect to BossRushManager
- Show active tournaments
- Timer for next event

### **Permanent Upgrades Panel**
- Create dedicated UI (not implemented yet)
- Access from bottom nav

### **Data Disk Collection UI**
- Create dedicated UI (not implemented yet)
- Access from bottom nav

### **Settings Menu**
- Create SettingsScreen.tscn
- Audio, graphics, controls, etc.

---

## 🎨 Visual Enhancements (Future)

1. **Animated Border:** Rotating gradient effect on title panel
2. **Particle Effects:** Floating code fragments in background
3. **Currency Icons:** Animated when values change
4. **Button Hover:** Glow effects on hover
5. **Tier Animation:** Smooth transition when changing tiers
6. **Notification Badges:** Red dot on buttons with new content

---

## 📊 Comparison

### **Old Start Screen:**
```
Simple VBoxContainer:
- [Start Button]
- [Settings Button] (disabled)
- [Permanent Upgrades Button] (disabled)
```
**Total:** 3 buttons, minimal functionality

### **New Start Screen:**
```
Polished Layout:
- Currency display (4 types)
- Tier selector (interactive)
- Left side (3 buttons + timers)
- Right side (5 utility buttons)
- Main action (Start Battle)
- Bottom nav (4 buttons)
```
**Total:** 15+ interactive elements, full feature access

---

**END OF DESIGN DOCUMENT**
