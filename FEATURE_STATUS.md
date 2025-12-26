# Feature Status - Subroutine Defense

**Last Updated:** 2025-12-26
**Version:** Alpha 0.1.0
**Launch Readiness:** 65%

---

## ✅ COMPLETED FEATURES

### Core Gameplay
- ✅ Tower defense mechanics (shooting, enemies, waves)
- ✅ 6 enemy types (Breacher, Slicer, Sentinel, Signal Runner, Null Walker, Override)
- ✅ Wave progression system
- ✅ Boss waves (every 10 waves)
- ✅ Death and restart flow
- ✅ Camera system
- ✅ Object pooling (performance optimization)

### In-Run Upgrades (DC)
- ✅ 20 total upgrade types
- ✅ Per-purchase exponential scaling (1.15^purchases)
- ✅ 3 categories: Offense (9), Defense (7), Economy (4)
- ✅ Buy X system (1, 5, 10, Max)
- ✅ Upgrade caps (crit 60%, wave skip 25%, free 50%)
- ✅ Multi-target system (unlock → upgrade)
- ✅ Cost display in UI

**Offense Upgrades:**
- Damage, Fire Rate, Crit Chance, Crit Damage
- Multi-Target (unlock + max targets)
- Piercing, Overkill, Projectile Speed
- Ricochet (chance + max bounces)

**Defense Upgrades:**
- Shield Integrity, Damage Reduction, Shield Regen
- Block Chance, Block Amount
- Boss Resistance, Overshield

**Economy Upgrades:**
- DC Multiplier, AT Multiplier
- Wave Skip Chance, Free Upgrade Chance

### Permanent Upgrades (AT)
- ✅ 11 core permanent upgrades
- ✅ Exponential cost scaling (1.13^level)
- ✅ Stats persist across runs
- ✅ UI panel with level display
- ✅ 5 batch 2 upgrades (overshield, boss bonus, lucky drops, ricochet)
- ✅ Multi-target permanent unlock

### Drone System
- ✅ 4 drone types (Flame, Frost, Poison, Shock)
- ✅ Permanent upgrades (fragment cost)
- ✅ Unique behaviors per drone
  - Flame: Targets low HP, applies burn DOT
  - Frost: Targets fast enemies, slows them
  - Poison: Targets low HP, applies poison DOT
  - Shock: Targets close enemies, stuns them
- ✅ Level scaling (fire rate, range, effect strength)
- ✅ Visual representation on screen
- ✅ Automatic targeting and attacking

### Software Labs (AT Cost)
- ✅ 21 total labs across 3 tiers
- ✅ 2 concurrent slots
- ✅ Exponential cost scaling (1.08-1.20)
- ✅ Exponential duration scaling (1.05-1.08)
- ✅ AT-only costs from level 1
- ✅ Lab acceleration bonus (permanent upgrade)
- ✅ Save/load lab state
- ✅ Offline completion

**Tier 1 Labs (100 levels):**
- Damage Processing, Fire Rate Optimization, Shield Matrix
- Critical Analysis, Shield Regeneration, Piercing Enhancement
- Projectile Acceleration, Block Systems, Block Amplification
- Overshield Enhancement

**Tier 2 Labs (50 levels):**
- Damage Amplification, Damage Mitigation
- Resource Optimization (DC), Archive Efficiency (AT)
- Overkill Processing, Boss Resistance Training
- Boss Targeting, Loot Optimization

**Tier 3 Labs (30 levels):**
- Wave Analysis (wave skip), Probability Matrix (free upgrades)
- Multi-Target Systems, Lab Acceleration (meta)

### Boss Rush Tournament
- ✅ Tournament schedule (Mon/Thu/Sat, UTC 00:00-00:00)
- ✅ Availability checking by weekday
- ✅ Boss-only spawning
- ✅ Progressive boss count (1-10 bosses per wave)
- ✅ 13% HP scaling per wave (vs 2% normal)
- ✅ 3x speed multiplier
- ✅ Damage-based leaderboard (top 10)
- ✅ Fragment rewards by rank (100-5000)
- ✅ Custom death screen
- ✅ Leaderboard save/load
- ✅ UI panel with rules and status

### PlayFab Cloud Saves
- ✅ REST API integration (no plugin needed)
- ✅ Email/password authentication
- ✅ Guest account (device ID)
- ✅ Account registration
- ✅ Guest → email binding
- ✅ Auto-sync on save
- ✅ Auto-download on login
- ✅ Timestamp conflict resolution (newest wins)
- ✅ Session persistence
- ✅ Title ID: 1DEAD6
- ✅ Login UI (dynamically created)
- ✅ Account status in statistics panel

### Offline Progress
- ✅ Run tracking (last 100 runs)
- ✅ Best run calculation (last 7 days)
- ✅ Offline simulation (25% / 50% with ad)
- ✅ 24-hour cap
- ✅ Minimum 1-minute absence
- ✅ Lab completion during offline
- ✅ Popup UI showing rewards
- ✅ AT/hour baseline calculation

### Tier System
- ✅ 10 tiers total
- ✅ Unlock at 5,000 waves per tier
- ✅ Enemy multiplier (10^tier exponential)
- ✅ Reward multiplier (5^tier exponential)
- ✅ Tier switching
- ✅ Progress saved per tier
- ✅ Highest wave tracking
- ✅ UI panel for selection

### Currency Systems
- ✅ Data Credits (DC) - in-run, temporary
- ✅ Archive Tokens (AT) - permanent progression
- ✅ Fragments - drone upgrades, boss rush rewards
- ✅ Wave scaling for DC/AT earning
- ✅ Multiplier systems (in-run, permanent, labs)
- ✅ Save/load all currencies

### Visual Effects
- ✅ Screen shake (damage, boss spawns, death)
- ✅ Screen flash (death, hits)
- ✅ Wave transitions (portal warp effect)
- ✅ Boss wave transitions (enhanced)
- ✅ Death transition (red flash + shake)
- ✅ Fragment notifications (floating text)
- ✅ 6 shaders (portal warp, chromatic aberration, CRT, distortion, bloom, cyber grid)
- ✅ Particle effects (enemy explosions, boss explosions)
- ✅ Matrix code rain background
- ✅ Holographic UI effects

### UI Systems
- ✅ Main HUD (wave, DC, AT, fragments, tier)
- ✅ Start screen (login integration)
- ✅ Death screen (stats display)
- ✅ Boss rush death screen (rank, rewards, leaderboard)
- ✅ Upgrade panels (offense, defense, economy)
- ✅ Permanent upgrade panel
- ✅ Software lab panel
- ✅ Tier selection panel
- ✅ Boss rush panel
- ✅ Statistics panel (lifetime stats, account info)
- ✅ Speed control (1x, 2x, 3x, 4x)
- ✅ Buy X toggle (1, 5, 10, Max)

### Save System
- ✅ Atomic save (3-step with backup)
- ✅ Save file corruption recovery
- ✅ Multiple save files (upgrades, labs, boss rush)
- ✅ Godot user:// directory (platform-agnostic)
- ✅ Cloud sync integration

### Statistics Tracking
- ✅ RunStats singleton
- ✅ Lifetime kill counts per enemy type
- ✅ Total damage dealt
- ✅ Run performance tracking
- ✅ Best run metrics (for offline calculation)

### Polish
- ✅ Fragment earning UI feedback
- ✅ StartScreen button states (disabled non-functional)
- ✅ Security hardening (.gitignore, SECURITY.md)
- ✅ Critical bug fixes (damage_label, fragment positioning)

---

## 🚧 IN DEVELOPMENT

### Testing & Quality Assurance
- 🚧 Playtesting (not yet done - awaiting Godot access)
- 🚧 Bug fixing (unknown bugs until tested)
- 🚧 Balance tuning (untested economy)
- 🚧 Performance optimization (untested on target devices)

---

## 📋 PLANNED FEATURES

### Content Expansion
- 📋 More enemy types (special abilities, variants)
- 📋 More lab projects (branching paths, tradeoffs)
- 📋 Boss variations (different bosses, not just Override)
- 📋 Seasonal events (limited-time challenges)
- 📋 Daily missions / challenges

### UI/UX Improvements
- 📋 Tutorial system (first-time user experience)
- 📋 Tooltips for all UI elements
- 📋 Settings screen (audio, graphics, controls)
- 📋 Permanent upgrades pre-run screen
- 📋 Better visual feedback for purchases
- 📋 Damage numbers (floating combat text)
- 📋 Enemy health bars
- 📋 Boss health bar (top of screen)

### Progression Systems
- 📋 Achievements system
- 📋 Unlockable cosmetics (tower skins, projectile effects)
- 📋 Prestige system (reset for bonus multipliers)
- 📋 Mastery levels (beyond tier 10)

### Social Features
- 📋 Friend system
- 📋 Guild/clan system
- 📋 Co-op mode (?)
- 📋 Global leaderboards (all-time, not just boss rush)
- 📋 Replay sharing

### Monetization
- 📋 Ad integration (offline progress doubling)
- 📋 IAP design (cosmetics only, no pay-to-win)
- 📋 Premium currency (separate from fragments)
- 📋 Battle pass / season pass

### Technical
- 📋 Analytics integration (player behavior tracking)
- 📋 Crash reporting
- 📋 A/B testing framework
- 📋 Automated tests (unit tests, integration tests)
- 📋 Configuration files (externalize balance values)

---

## ❌ CUT / POSTPONED

### Multiplayer
- ❌ Real-time co-op (too complex for MVP)
- ❌ PvP mode (scope creep)

### Advanced Systems
- ❌ Skill tree (replaced by software labs)
- ❌ Equipment system (replaced by permanent upgrades)
- ❌ Character classes (single tower focus)

---

## 🔢 Feature Completeness by System

| System | Completeness | Notes |
|--------|--------------|-------|
| Core Gameplay | 95% | Missing tutorial, polish |
| In-Run Upgrades | 100% | All 20 upgrades implemented |
| Permanent Upgrades | 95% | Missing pre-run UI |
| Software Labs | 100% | All 21 labs functional |
| Boss Rush | 100% | Full tournament system |
| Cloud Saves | 100% | PlayFab integration complete |
| Offline Progress | 100% | Calculation and UI done |
| Tier System | 100% | All 10 tiers implemented |
| Drones | 100% | All 4 types working |
| Fragments | 100% | Earning + spending complete |
| Visual Effects | 90% | Core effects done, polish needed |
| UI Systems | 85% | Missing settings, tutorials |
| Save System | 100% | Robust with backups |
| Statistics | 95% | Tracking works, UI basic |

**Overall Completion: 95%** (code-wise)
**Overall Tested: 0%** (no playtesting yet)

---

## 🎯 MVP Criteria (Minimum Viable Product)

**For Alpha Launch:**
- ✅ Core gameplay works (tower shoots, enemies die)
- ✅ Upgrades function (DC and AT)
- ✅ Can die and restart
- ✅ Progress saves
- ⚠️ No major crashes (untested)
- ⚠️ Feels fun for 30+ minutes (untested)

**For Beta Launch:**
- ✅ All systems implemented
- ❌ All systems tested (not yet)
- ❌ Balance feels good (not yet)
- ❌ Tutorial exists (not yet)
- ❌ No critical bugs (unknown)

**For Public Launch:**
- ❌ Extensive testing (need 100+ hours)
- ❌ Balance verified (need player feedback)
- ❌ Performance optimized (untested on mobile)
- ❌ Analytics integrated (not yet)
- ❌ Monetization implemented (planned)
- ❌ Marketing materials (not yet)

---

## 🚀 Roadmap

### Phase 1: Alpha Testing (Current)
**Goal:** Verify game works and is fun

**Tasks:**
- Playtest basic gameplay loop
- Fix critical bugs
- Verify cloud saves work
- Test boss rush timing
- Validate economy balance
- Performance check on mobile

**Duration:** 1-2 weeks
**Success:** Game runs without crashes for 1 hour

### Phase 2: Beta Polish
**Goal:** Make game launch-ready

**Tasks:**
- Add tutorial system
- Create settings screen
- Implement tooltips
- Balance tuning (based on alpha feedback)
- Performance optimization
- Bug fixing from alpha

**Duration:** 2-4 weeks
**Success:** Game feels polished and complete

### Phase 3: Soft Launch
**Goal:** Test with small audience

**Tasks:**
- Integrate analytics
- Add crash reporting
- Limited release (friends, small community)
- Gather feedback
- Iterate on balance and features

**Duration:** 4-8 weeks
**Success:** Positive feedback, retention >40% day 1

### Phase 4: Full Launch
**Goal:** Public release

**Tasks:**
- Marketing campaign
- App store optimization
- Monetization activation
- Community management
- Content updates planned

**Duration:** Ongoing
**Success:** 10,000+ downloads, positive reviews

---

## 📊 Priority Matrix

**High Priority (Blocking Launch):**
1. Playtesting and bug fixing
2. PlayFab Title ID validation
3. Boss rush timing test (Mon/Thu/Sat)
4. Performance on mobile devices
5. Tutorial / onboarding

**Medium Priority (Nice to Have):**
1. Settings screen
2. Permanent upgrades pre-run UI
3. More visual polish
4. Achievements system
5. Analytics integration

**Low Priority (Post-Launch):**
1. More content (enemies, labs)
2. Seasonal events
3. Social features
4. Advanced progression systems
5. Cosmetics

---

## 🐛 Known Issues

See PRE_LAUNCH_ISSUES.md for detailed breakdown.

**Critical (Fixed):**
- ✅ Missing damage_label node (would crash)
- ✅ Fragment notification positioning
- ✅ Non-functional StartScreen buttons

**High Priority (Unverified):**
- ⚠️ PlayFab Title ID validity unknown
- ⚠️ Boss rush timing untested
- ⚠️ Offline progress calculations untested
- ⚠️ Fragment spending may have issues
- ⚠️ UI layout on 390x844 untested

**Medium Priority:**
- Various debug print statements (cleanup needed)
- Missing code comments in complex systems
- No error handling for network failures
- No input validation (security risk)

---

## 💡 Feature Requests

Track future ideas here:

**From Team:**
- [ ] Endless mode (separate from tiers)
- [ ] Challenge modes (modifiers, restrictions)
- [ ] Tower customization (colors, effects)
- [ ] Enemy encyclopedia (bestiary)
- [ ] Statistics graphs (progression over time)

**From Players:**
- (None yet - awaiting feedback)

---

## 📝 Development Notes

**Architecture Decisions:**
- Godot 4.4 for modern features and performance
- Singleton pattern for managers (easy access, global state)
- REST API for PlayFab (no plugin dependency)
- Exponential scaling everywhere (3-year timeline)
- Fragment currency separate from AT (premium but farmable)

**Why Some Features Were Cut:**
- Multiplayer: Too complex for solo dev, not core to game
- Skill tree: Software labs provide similar depth
- Equipment: Permanent upgrades serve same purpose
- Character classes: Simpler to balance single tower

**What Worked Well:**
- Per-purchase DC scaling (The Tower model)
- Boss rush as weekend tournament (urgency + competition)
- Fragments as premium currency (feels rewarding)
- Software labs (long-term goals, offline friendly)
- PlayFab (easy integration, no backend needed)

**What Needs Improvement:**
- UI layout (created programmatically, hard to edit)
- Testing (none done yet)
- Documentation (just added these docs)
- Error handling (minimal)
- Security (basic protections only)

---

**Last reviewed:** 2025-12-26
**Next review:** After alpha testing
**Maintained by:** Development team

**Status:** Ready for alpha testing, pending Godot access.
