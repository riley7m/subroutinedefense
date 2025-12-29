# Subroutine Defense - Systems Audit & Integration Status

**Generated:** 2025-12-29
**Session:** claude/read-text-input-JN1e8

---

## 🎯 Overview

This document provides a complete audit of all progression and monetization systems implemented in Subroutine Defense, identifying what's complete, what's missing, and what needs integration.

---

## ✅ COMPLETED SYSTEMS

### 1. Drone Upgrade System
**Files:** `DroneUpgradeManager.gd`, `drone_upgrade_ui.gd`, `drone_*.gd`, `enemy.gd`

**Status:** ✅ FULLY IMPLEMENTED & INTEGRATED

**Features:**
- ✅ Active slot unlocking (1→4 slots, costs: 50K/250K/1M fragments)
- ✅ Per-drone level upgrades (levels 1-10, 2.4M fragments each)
- ✅ Drone-specific upgrades:
  - Flame: Tick rate (1.0s→0.5s) + HP cap (10%→25%)
  - Poison: Duration (4s→6s) + stacking (1→2 max)
  - Frost: AOE (1→2 targets) + duration (2s→2.5s)
  - Shock: Chain (1→2 targets) + duration (+0.5s bonus)
- ✅ Total cost: ~17.84M fragments
- ✅ Full save/load system
- ✅ Complete UI with 4 drone tabs
- ✅ Integration with actual drone instances (drones query DroneUpgradeManager)
- ✅ Enemy.gd updated to handle all upgraded parameters
- ✅ Balance nerfs applied (poison 90% max, slow 75% max)

**Integration Points:**
- ✅ Drones added to "drones" group
- ✅ main_hud.gd updated to use DroneUpgradeManager
- ✅ All 4 drone types fully integrated

**Missing:**
- ⚠️ UI not accessible from main menu (no button to open drone_upgrade_ui.gd)
- ⚠️ No in-game testing performed yet

---

### 2. Quantum Core Shop System
**Files:** `QuantumCoreShop.gd`, `quantum_core_shop_ui.gd`

**Status:** ✅ BACKEND COMPLETE, ⚠️ UI NOT INTEGRATED

**Features:**
- ✅ QC Purchase Packs (6 tiers: $0.99 - $99.99)
  - Starter: 100 QC ($0.99)
  - Small: 600 QC ($4.99, +20% bonus)
  - Medium: 1300 QC ($9.99, +30% bonus)
  - Large: 2800 QC ($19.99, +40% bonus)
  - Mega: 8000 QC ($49.99, +60% bonus) 🔥 Popular
  - Whale: 18000 QC ($99.99, +80% bonus) ⭐ Best Value

- ✅ Direct IAP Items
  - Remove Ads: $7.99 (permanent)
  - Double Economy: $9.99 (2x all currency)

- ✅ QC Shop Items (spend QC)
  - Fragment bundles: 100-10K QC (1 QC = 50 fragments)
  - Lab Rush: 25 QC per hour
  - Lab Slots 3/4/5: 1K/5K/15K QC

- ✅ Complete 3-tab UI (Buy QC, Premium, Spend QC)
- ✅ Full save/load system
- ✅ Integration with SoftwareUpgradeManager (lab rush works)

**Integration Points:**
- ✅ QuantumCoreShop registered in autoload
- ✅ Lab rush calls SoftwareUpgradeManager.rush_upgrade()
- ✅ Lab slots query from QuantumCoreShop.get_max_lab_slots()

**Missing:**
- ❌ UI not accessible from main menu (no button to open quantum_core_shop_ui.gd)
- ❌ IAP platform integration (Google Play, App Store) - DEV_MODE enabled
- ⚠️ Real money purchase flow not connected to actual payment processing

---

### 3. Lab Research System (Software Upgrades)
**Files:** `SoftwareUpgradeManager.gd`, `software_upgrade_ui.gd`

**Status:** ✅ FULLY IMPLEMENTED & INTEGRATED

**Features:**
- ✅ 22 unique labs with progression (30-100 levels each)
- ✅ Dynamic slot system (2-5 slots, upgradeable via QC Shop)
- ✅ Lab rush support (25 QC per hour via QuantumCoreShop)
- ✅ Time-based research (1 hour - multiple days)
- ✅ Archive Token (AT) cost scaling
- ✅ Offline progress calculation
- ✅ Atomic save/load with backup system
- ✅ UI shows locked/unlocked slots

**Labs by Tier:**
- Tier 1 (1 hour base): Damage Processing, Fire Rate, Critical Analysis
- Tier 2 (2-4 hours): Damage Amplification, Shield Matrix, etc.
- Higher tiers: Up to 22 different research tracks

**Integration Points:**
- ✅ SoftwareUpgradeManager registered in autoload
- ✅ QuantumCoreShop integration (get_max_lab_slots(), rush_upgrade())
- ✅ UI dynamically shows 2-5 slots based on purchases

**Missing:**
- ⚠️ UI may not be accessible from main menu (verify main_hud.gd integration)
- ⚠️ Lab rush UI flow (user needs to select hours to rush)

---

### 4. Milestone System (Battle Pass)
**Files:** `MilestoneManager.gd`, `milestone_ui.gd`, `paid_track_purchase_ui.gd`

**Status:** ✅ FULLY IMPLEMENTED

**Features:**
- ✅ Wave-based milestones (tier-specific)
- ✅ Free + Paid tracks
- ✅ Paid track unlocking ($4.99 per tier)
- ✅ Rewards: QC, Fragments, Data Disks, Lab unlocks
- ✅ Complete UI with milestone progression
- ✅ Save/load system

**Reward Distribution per Tier:**
- Free Track: ~2,500 QC, ~25K fragments, 2-3 data disks
- Paid Track: ~2,500 QC, ~25K fragments, 3 data disks, 3 lab unlocks
- Total (both): ~5,000 QC, ~50K fragments per tier

**Integration Points:**
- ✅ TierManager integration for wave tracking
- ✅ DataDiskManager for disk rewards
- ✅ RewardManager for currency

**Missing:**
- ⚠️ Payment processing for paid track unlock
- ⚠️ UI accessibility from main menu

---

### 5. Achievement System
**Files:** `AchievementManager.gd`

**Status:** ✅ BACKEND COMPLETE, ❌ NO UI

**Features:**
- ✅ 10 lifetime achievement tracks
- ✅ QC rewards (1.77M total over 2+ years)
- ✅ Progress tracking across multiple sessions
- ✅ Save/load system

**Achievement Tracks:**
- Wave Master (100K waves): 500K QC
- Boss Slayer (10K bosses): 200K QC
- Fragment Collector (100M fragments): 150K QC
- Data Disk Collector (500 disks): 100K QC
- Prestige Master (100 prestiges): 300K QC
- Drone Commander (10M drone damage): 150K QC
- Tower Defender (survive 10K waves): 100K QC
- Perfect Runs (1K flawless): 120K QC
- Speed Runner (100 sub-5min): 80K QC
- Elite Veteran (365 days played): 100K QC

**Missing:**
- ❌ No UI to view/claim achievements
- ❌ No integration with main menu
- ⚠️ Progress tracking may not be hooked up to all game events

---

### 6. Data Disk System
**Files:** `DataDiskManager.gd`

**Status:** ✅ FULLY IMPLEMENTED

**Features:**
- ✅ 60 unique data disks with stat bonuses
- ✅ Multi-stat support
- ✅ Tier-based unlocking via milestones
- ✅ Balanced progression (no OP disks)
- ✅ Save/load system

**Disk Categories:**
- Damage: +projectile damage, +crit damage
- Defense: +shield, +armor, +block
- Economy: +currency drops, +lucky drops
- Utility: +fire rate, +multishot, +pierce

**Missing:**
- ⚠️ UI integration (may exist, needs verification)
- ⚠️ Visual feedback when disks are equipped/active

---

### 7. Drone Purchase/Ownership System
**Files:** `main_hud.gd`, `RewardManager.gd`

**Status:** ✅ IMPLEMENTED BUT LEGACY

**Features:**
- ✅ Drone ownership tracking
- ✅ Auto-spawn owned drones
- ✅ Purchase UI in permanent upgrades panel
- ✅ Cost: 5,000 fragments per drone

**Integration:**
- ✅ Uses DroneUpgradeManager for levels
- ✅ Spawns drones at game start

**Issues:**
- ⚠️ May conflict with active slot system in DroneUpgradeManager
- ⚠️ Unclear if 4 drone limit is enforced vs DroneUpgradeManager's slot system

---

## ⚠️ PARTIALLY IMPLEMENTED SYSTEMS

### 8. Economic Audit System
**Files:** `ECONOMIC_AUDIT.md`

**Status:** 📊 DOCUMENTATION ONLY

**Content:**
- ✅ Complete QC economy analysis
- ✅ Fragment conversion rates (1 QC = 50 fragments)
- ✅ Battle pass ROI calculations
- ✅ Free vs paid progression timelines
- ✅ Recommendations for balance

**Missing:**
- ❌ No in-game economic dashboard
- ❌ No admin tools for economy tuning
- ❌ No analytics tracking for player spending

---

## ❌ MISSING OR INCOMPLETE SYSTEMS

### 9. UI Integration & Accessibility
**Critical Missing Pieces:**

**Current State (Verified in main_hud.gd):**
- ✅ **Labs Button EXISTS**: "🔬 Labs" button at position (5, 800) opens SoftwareUpgradeManager UI
- ✅ **Pattern Established**: Button creates panel → toggles visibility → updates button text
- ❌ **Missing Drone Upgrade Button**: No access to `drone_upgrade_ui.gd`
- ❌ **Missing QC Shop Button**: No access to `quantum_core_shop_ui.gd`
- ❌ **Missing Achievement Button**: No access (and UI doesn't exist)
- ⚠️ **Milestone UI**: Exists but unclear if accessible from main_hud.gd

**UI Integration Gaps:**

1. **Main Menu Integration**
   - ❌ No buttons to access:
     - Drone Upgrade UI (`drone_upgrade_ui.gd` - ready but not integrated)
     - QC Shop UI (`quantum_core_shop_ui.gd` - ready but not integrated)
     - Achievement UI (doesn't exist)
   - ⚠️ Unclear if milestone_ui.gd is accessible

2. **In-Game HUD Integration**
   - ❌ No QC/Fragment display in main HUD
   - ❌ No quick access to shops during gameplay
   - ❌ No notification when achievements unlock

3. **Navigation Flow**
   - ✅ Pattern exists for panel toggling
   - ⚠️ Need unified menu bar for all progression systems
   - ❌ No breadcrumb navigation
   - ❌ No "back" button standardization

**Solution Created:**
- 📋 **UI_INTEGRATION_GUIDE.md** provides complete implementation plan
- Includes full code for adding 3 new buttons (Drones, Shop, Pass)
- Proposes menu bar layout at y=800 with proper spacing
- Includes testing checklist and common issue solutions

---

### 10. Payment Processing & IAP
**Files:** `QuantumCoreShop.gd` (DEV_MODE enabled)

**Status:** ❌ STUBBED, NOT IMPLEMENTED

**Missing:**
- ❌ Google Play Billing integration
- ❌ Apple App Store integration
- ❌ Receipt validation
- ❌ Purchase restoration
- ❌ Subscription management (if applicable)
- ❌ Currency pack purchase flow
- ❌ Server-side validation
- ❌ Anti-fraud measures

**Current State:**
- ⚠️ DEV_MODE = true (bypasses real payments)
- ⚠️ Simulated purchases work but grant items for free

---

### 11. Testing & Balance Validation
**Status:** ❌ NOT PERFORMED

**Missing:**
- ❌ Drone upgrade balance testing in actual gameplay
- ❌ Economy balance validation (fragment earn rates vs costs)
- ❌ Progression pacing tests
- ❌ Edge case testing:
  - What happens if player buys lab slot but no labs unlocked?
  - Can player rush lab with 0 hours remaining?
  - Fragment overflow handling (max int checks)
  - Save corruption recovery testing

---

### 12. Prestige System
**Status:** 📝 REFERENCED BUT NOT IMPLEMENTED

**References:**
- AchievementManager mentions "Prestige Master" achievement
- RewardManager has prestige-related fields (TODO verify)

**Missing:**
- ❌ Prestige mechanic design
- ❌ Prestige UI
- ❌ Prestige rewards/bonuses
- ❌ Reset logic
- ❌ Permanent progression tracking

---

### 13. Tower Upgrade System (In-Run vs Permanent)
**Status:** ✅ CLARIFIED

**System Breakdown:**
- **UpgradeManager.gd**: IN-RUN upgrades (purchased with Data Credits during active run)
  - Damage, Fire Rate, Crit Chance, Crit Damage
  - Shield, Damage Reduction, Shield Regen
  - Multi-target, Piercing, Overkill, Block, etc.
  - Purchases tracked, costs scale exponentially
  - Resets after each run

- **SoftwareUpgradeManager.gd**: OUT-OF-RUN upgrades (permanent, purchased with Archive Tokens)
  - 22 lab research tracks
  - Levels 1-100 per lab
  - Permanent bonuses that persist across runs
  - Time-based research system

**Conclusion:** Two separate systems working together - in-run + permanent progression

---

### 14. Boss Rush Mode Integration
**Files:** `BossRushManager.gd`, `boss_rush_ui.gd`

**Status:** ⚠️ EXISTS BUT INTEGRATION UNCLEAR

**Features Implemented:**
- ✅ Boss rush mode tracking
- ✅ Leaderboard system
- ✅ Fragment rewards based on rank
- ✅ UI for boss rush

**Missing/Unclear:**
- ⚠️ How does player enter boss rush?
- ⚠️ Is it accessible from main menu?
- ⚠️ Does it integrate with drone upgrades?

---

### 15. Cloud Save System
**Files:** `CloudSaveManager.gd`

**Status:** ✅ IMPLEMENTED BUT NEEDS CONFIGURATION

**Features:**
- ✅ PlayFab integration
- ✅ Account binding
- ✅ Save/load to cloud
- ✅ Conflict resolution

**Missing:**
- ⚠️ PlayFab credentials configuration
- ⚠️ Testing with real PlayFab instance
- ⚠️ UI for account management
- ⚠️ Save sync status indicators

---

### 16. Notification System
**Files:** `NotificationManager.gd`, `milestone_notification.gd`

**Status:** ✅ BACKEND EXISTS, ⚠️ LIMITED USAGE

**Features:**
- ✅ Popup notification system
- ✅ Milestone notifications
- ✅ Queue system

**Missing:**
- ❌ Achievement unlock notifications
- ❌ Drone upgrade purchase confirmations
- ❌ Lab completion notifications
- ❌ QC purchase confirmations
- ❌ Fragment milestone notifications

---

### 17. Analytics & Metrics
**Status:** ❌ NOT IMPLEMENTED

**Missing:**
- ❌ Player progression tracking
- ❌ Monetization funnel analysis
- ❌ A/B testing framework
- ❌ Session analytics
- ❌ Retention metrics
- ❌ FTUE (First Time User Experience) tracking
- ❌ Crash reporting
- ❌ Performance metrics

---

### 18. Localization
**Status:** ❌ NOT IMPLEMENTED

**Missing:**
- ❌ Translation system
- ❌ String externalization
- ❌ Multi-language support
- ❌ Currency formatting per region
- ❌ Time/date localization

---

### 19. Settings & Configuration
**Status:** ⚠️ PARTIAL

**Existing:**
- ⚠️ ConfigLoader.gd exists (needs review)

**Missing:**
- ❌ Audio settings UI
- ❌ Graphics settings UI
- ❌ Control customization
- ❌ Account management UI
- ❌ Privacy settings
- ❌ Data deletion options (GDPR compliance)

---

### 20. Tutorial & FTUE
**Status:** ❌ NOT IMPLEMENTED

**Missing:**
- ❌ Tutorial for core gameplay
- ❌ Tutorial for drone upgrades
- ❌ Tutorial for lab research
- ❌ Tutorial for QC shop
- ❌ Tutorial for battle pass
- ❌ Tooltips for all UI elements
- ❌ Help screens
- ❌ Onboarding flow

---

## 🔗 INTEGRATION MATRIX

| System | Backend | UI | Menu Access | Save/Load | Tested |
|--------|---------|----|-----------| ----------|--------|
| Drone Upgrades | ✅ | ✅ | ❌ | ✅ | ❌ |
| QC Shop | ✅ | ✅ | ❌ | ✅ | ❌ |
| Lab Research | ✅ | ✅ | ⚠️ | ✅ | ❌ |
| Milestones | ✅ | ✅ | ⚠️ | ✅ | ❌ |
| Achievements | ✅ | ❌ | ❌ | ✅ | ❌ |
| Data Disks | ✅ | ⚠️ | ⚠️ | ✅ | ❌ |
| IAP/Payments | ⚠️ | ✅ | ❌ | N/A | ❌ |
| Cloud Save | ✅ | ❌ | ❌ | ✅ | ❌ |
| Boss Rush | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |
| Notifications | ✅ | ⚠️ | N/A | N/A | ⚠️ |

**Legend:**
- ✅ = Complete
- ⚠️ = Partial/Needs Investigation
- ❌ = Missing/Not Implemented
- N/A = Not Applicable

---

## 📊 ECONOMIC SUMMARY

### Fragment Economy
**Total Sinks:**
- Drone Upgrades: ~17.84M fragments
- Tier Unlocks: ~4M fragments (estimated)
- Drone Purchases: 20K fragments (4 drones × 5K)
- **Total: ~22M fragments needed for 100% completion**

**Sources:**
- QC Conversion: 1 QC = 50 fragments
- Free QC (2+ years): 1.77M QC = 88.5M fragments (4x needed) ✅ Generous
- Whale Pack ($99.99): 18K QC = 900K fragments (~4% of total)
- Battle Pass (per tier): ~50K fragments
- Boss Rush: Fragment rewards based on rank
- Milestone rewards: Direct fragment drops

**Balance Assessment:**
- ✅ Free players can complete all content over 2+ years
- ✅ Whales get significant boost but still need to grind
- ✅ Battle pass is best value (3-5x better than QC packs)
- ⚠️ Need to verify actual fragment earn rates in-game

### QC Economy
**Total Free QC Available:**
- Milestones (all tiers): ~600K QC
- Achievements (lifetime): ~1.77M QC
- **Total: ~2.37M QC (free)**

**QC Spending Sinks:**
- Fragment conversion: Unlimited (1 QC = 50 fragments)
- Lab Rush: Variable (25 QC/hour)
- Lab Slots: 21K QC (1K + 5K + 15K)
- **Primary sink: Fragment conversion for drone upgrades**

**Monetization:**
- QC Packs: $0.99 - $99.99 (100 - 18K QC)
- Best Value: Whale Pack ($99.99 = 18K QC = 180 QC/$)
- Battle Pass: Best ROI ($4.99 per tier = ~5K QC = 1000+ QC/$)

---

## 🔧 CRITICAL INTEGRATION TASKS

### Priority 1: UI Accessibility (BLOCKING)
1. **Add menu buttons for:**
   - Drone Upgrade UI → Main menu or HUD
   - QC Shop UI → Main menu or HUD
   - Achievement UI → Create + add to menu

2. **Create unified menu system:**
   - Central hub for all progression systems
   - Clear navigation paths
   - Consistent "back" button behavior

3. **HUD Integration:**
   - Display QC/Fragment balances
   - Quick access buttons to shops
   - Notification popups for unlocks

### Priority 2: Save/Load Verification
1. **Test all systems save correctly:**
   - Drone upgrades persist
   - QC purchases persist
   - Lab research persists (including time)
   - Achievements track across sessions

2. **Add save version management:**
   - Handle schema changes
   - Migration path for old saves

### Priority 3: Payment Processing (CRITICAL FOR MONETIZATION)
1. **Implement IAP platform integration:**
   - Google Play Billing
   - Apple App Store
   - Receipt validation
   - Purchase restoration

2. **Server-side validation:**
   - Prevent client-side cheating
   - Track purchase history
   - Handle refunds

### Priority 4: Testing & Balance
1. **In-game testing:**
   - Play through with drone upgrades
   - Verify fragment earn rates
   - Test progression pacing
   - Validate all formulas work as intended

2. **Edge case testing:**
   - Boundary value testing (max ints, etc.)
   - Error handling (purchase failures, etc.)
   - Save corruption recovery

### Priority 5: Polish & UX
1. **Notifications:**
   - Hook up NotificationManager to all systems
   - Show feedback for all player actions
   - Achievement unlocks
   - Purchase confirmations

2. **Tutorial:**
   - Create FTUE for new players
   - Tooltips for all systems
   - Help screens

---

## 📝 TECHNICAL DEBT

### Code Quality Issues
1. **Hardcoded values:**
   - Many costs/values in code vs config files
   - Makes balance tuning difficult

2. **Manager proliferation:**
   - Many *Manager.gd files
   - Unclear separation of concerns
   - Some overlap (UpgradeManager vs SoftwareUpgradeManager)

3. **Error handling:**
   - Limited validation in purchase flows
   - Need more defensive programming

### Architecture Issues
1. **Singleton dependencies:**
   - Heavy reliance on autoload managers
   - Makes testing difficult
   - Tight coupling

2. **UI coupling:**
   - UI directly queries managers
   - No proper MVC/MVVM separation
   - Hard to unit test

3. **Save system:**
   - Multiple save files (labs, upgrades, etc.)
   - No central save coordinator
   - Potential for save conflicts

---

## 🎯 COMPLETION CHECKLIST

### To Ship MVP (Minimum Viable Product):
- [ ] Complete UI integration (menu buttons)
- [ ] Complete IAP integration (Google Play + App Store)
- [ ] Test all progression systems in-game
- [ ] Verify save/load works correctly
- [ ] Balance economy based on playtesting
- [ ] Create basic tutorial
- [ ] Add achievement UI
- [ ] Implement notification feedback
- [ ] Cloud save testing with PlayFab
- [ ] Legal: Privacy policy, terms of service

### Post-Launch Priorities:
- [ ] Analytics integration
- [ ] A/B testing framework
- [ ] Localization (top 5 languages)
- [ ] Performance optimization
- [ ] Retention features (daily rewards, etc.)
- [ ] Social features (leaderboards, sharing)
- [ ] Live ops tools (events, sales, etc.)

---

## 📈 RECOMMENDATIONS

### Short-Term (This Week):
1. **Create main menu integration** for all UIs
2. **Test full progression loop** end-to-end
3. **Create achievement UI** (missing but backend ready)
4. **Verify all save/load** works correctly
5. **Document IAP requirements** for platform integration

### Medium-Term (This Month):
1. **Implement real IAP** (Google Play + App Store)
2. **Add comprehensive testing**
3. **Create tutorial/FTUE**
4. **Set up analytics tracking**
5. **Balance economy** based on data

### Long-Term (This Quarter):
1. **Launch MVP**
2. **Iterate based on player feedback**
3. **Add live ops features**
4. **Localization**
5. **Social features**

---

## 🔍 FILES INVENTORY

### Managers (Autoload Singletons):
```
✅ DroneUpgradeManager.gd (565 lines) - Drone upgrade system
✅ QuantumCoreShop.gd (358 lines) - Monetization & QC
✅ SoftwareUpgradeManager.gd (700+ lines) - Lab research
✅ MilestoneManager.gd - Battle pass
✅ AchievementManager.gd - Lifetime achievements
✅ DataDiskManager.gd - Data disk system
✅ RewardManager.gd - Currency management
✅ TierManager.gd - Tier progression
✅ BossRushManager.gd - Boss rush mode
✅ NotificationManager.gd - Notifications
✅ CloudSaveManager.gd - Cloud saves
⚠️ UpgradeManager.gd - In-run upgrades (?)
```

### UI Files:
```
✅ drone_upgrade_ui.gd (560 lines) - Drone upgrade interface
✅ quantum_core_shop_ui.gd (444 lines) - QC shop interface
✅ software_upgrade_ui.gd (258 lines) - Lab research interface
✅ milestone_ui.gd (271 lines) - Battle pass interface
✅ paid_track_purchase_ui.gd - Battle pass purchase
⚠️ boss_rush_ui.gd - Boss rush interface
⚠️ tier_selection_ui.gd - Tier selection
❌ achievement_ui.gd - MISSING
```

### Game Logic:
```
✅ drone_base.gd - Base drone class
✅ drone_flame.gd - Flame drone (integrated)
✅ drone_poison.gd - Poison drone (integrated)
✅ drone_frost.gd - Frost drone (integrated)
✅ drone_shock.gd - Shock drone (integrated)
✅ enemy.gd - Enemy with status effects
✅ main_hud.gd - Main game HUD
⚠️ tower.gd - Tower (needs review)
```

### Documentation:
```
✅ ECONOMIC_AUDIT.md - Economy analysis
✅ SYSTEMS_AUDIT.md - This file
```

---

## 🚀 NEXT STEPS

**Immediate Actions:**
1. Review `main_hud.gd` to find where to add shop/upgrade buttons
2. Create `achievement_ui.gd` (follow patterns from other UIs)
3. Test drone upgrades in actual gameplay
4. Document IAP platform requirements
5. Create integration plan for menu system

**Questions to Answer:**
1. How is the main menu structured?
2. Where do players access permanent upgrades currently?
3. Is there a settings menu?
4. How do players access milestone UI?
5. What's the difference between UpgradeManager and SoftwareUpgradeManager?

---

**END OF AUDIT**

*This document should be updated as systems are completed or modified.*
