# Patch Notes Template

Use this template for version updates and patch releases.

---

## Version X.Y.Z - [Release Name] (YYYY-MM-DD)

**Type:** [Major / Minor / Patch / Hotfix]
**Build:** [Build number]
**Platform:** [All / Android / iOS / Web]

---

### 🎉 NEW FEATURES

**[Feature Name]**
- Description of what it does
- How to access it
- Why it's awesome

*Example:*
**Boss Rush Tournament**
- New competitive mode available Mon/Thu/Sat
- Rank on damage leaderboard for fragment rewards
- Access via 🏆 Rush button in main HUD

---

### ⚡ IMPROVEMENTS

**[System Name]**
- What changed
- Why it's better

*Example:*
**Software Labs**
- Reduced lab duration by 20% across all tiers
- Labs now show estimated completion time more clearly
- Added notification when labs complete during active play

---

### 🔧 BALANCE CHANGES

**[What Changed]**
- Old value → New value
- Reasoning

*Example:*
**Permanent Upgrades**
- Damage base cost: 5,000 AT → 4,000 AT
- Fire Rate cost scaling: 1.13 → 1.12
- Reason: Progression felt too slow for new players

**DC Earning**
- Wave scaling: 2% per wave → 2.5% per wave
- Reason: Late game DC felt scarce

---

### 🐛 BUG FIXES

**Critical:**
- Fixed crash when starting boss rush on certain devices
- Fixed cloud save corruption when logging in offline
- Fixed negative currency exploit with wave skip

**High Priority:**
- Fragment notifications now appear at correct position
- Drone targeting no longer gets stuck on dead enemies
- Boss Rush leaderboard now sorts correctly by damage

**Low Priority:**
- Fixed typo in "Archive Tokens" label
- Corrected tooltip text for Multi-Target upgrade
- Minor visual glitch in death screen transition

---

### 💰 ECONOMY CHANGES

**Fragment Rewards:**
- Boss kills: 10+(wave/10) → 15+(wave/8)
- Boss Rush rank 1: 5000 → 6000 fragments
- Reason: Drone upgrades felt too grindy

**Offline Progress:**
- Base efficiency: 25% → 30%
- With ad: 50% → 60%
- Reason: Encourage daily check-ins

---

### 🎨 VISUAL / AUDIO

- Added new particle effects for boss explosions
- Improved screen shake feedback for critical hits
- Updated UI color scheme for better readability
- Added sound effects for upgrade purchases (coming soon)

---

### ⚙️ TECHNICAL

- Upgraded to Godot 4.4.1
- Optimized object pooling (10% performance improvement)
- Reduced save file size by 30%
- Improved network error handling for PlayFab
- Added analytics tracking for key events

---

### 🚨 KNOWN ISSUES

Issues we're aware of and working on:

- Boss Rush may show incorrect "Next tournament" time near midnight UTC
- Offline progress popup occasionally shows wrong AT amount (visual only)
- Fragment notification may overlap with other UI elements
- Statistics panel performance drops with 100+ lab completions

**Workarounds:**
- Boss Rush: Check in-game panel for accurate time
- Offline popup: Check actual AT count in top HUD
- Fragment overlap: No workaround, visual only
- Statistics lag: Clear statistics data in settings (coming soon)

---

### 📱 PLATFORM SPECIFIC

**Android:**
- Fixed touch input delay on certain devices
- Improved battery optimization
- Added support for Android 14

**iOS:**
- Fixed cloud save sync on iOS 17
- Improved performance on older devices (iPhone 8+)

**Web:**
- N/A (not yet supported)

---

### 🔐 SECURITY

- Improved input validation for cloud saves
- Added server-side verification for boss rush scores
- Fixed potential exploit with negative wave skip

---

### 📊 STATISTICS

Since last version:
- Total players: [X]
- Total waves cleared: [X]
- Boss Rush participants: [X]
- Average session time: [X] minutes
- Cloud saves: [X] active accounts

---

### 💬 COMMUNITY HIGHLIGHTS

**Top Feedback Addressed:**
1. "Progression too slow" → Reduced permanent upgrade costs
2. "Boss Rush too hard" → Adjusted HP scaling
3. "Need more visual feedback" → Added fragment notifications

**Thank You:**
- Special thanks to [usernames] for bug reports
- Shoutout to [community] for balance suggestions
- Appreciation for [streamer] for showcasing the game

---

### 🗺️ COMING SOON

**Next Version (X.Y.Z):**
- Settings screen (audio, graphics options)
- Tutorial system for new players
- More enemy variety (3 new types)
- Achievements system

**In Development:**
- Seasonal events
- Guild system
- Tower customization
- New boss types

---

### 📥 DOWNLOAD

**Current Version:** X.Y.Z

**Download Links:**
- Android: [Google Play Store link]
- iOS: [App Store link]
- Direct APK: [Link for sideloading]

**File Size:** [X] MB
**Requires:** Android 8.0+ / iOS 13+

---

### 🔄 UPDATE INSTRUCTIONS

**Automatic Update:**
Game will auto-update next launch if connected to internet.

**Manual Update:**
1. Download latest version from link above
2. Install over existing version
3. Launch game
4. Progress automatically restored from cloud

**⚠️ Important:**
- Ensure cloud save synced before updating
- Backup save files if using custom ROMs (Android)
- Update may take 1-5 minutes depending on connection

---

### 📝 DEVELOPER NOTES

**What We Learned:**
- Boss Rush tournaments drive 3x engagement on active days
- Players prefer shorter lab durations (<4 hours)
- Fragment economy needs more sources

**What We're Testing:**
- A/B testing offline progress efficiency (30% vs 35%)
- Different boss rush reward structures
- New enemy spawn patterns

**What We're Monitoring:**
- Tier 5+ progression rates
- Lab completion rates by tier
- Boss Rush participation trends

---

### ❓ FAQ

**Q: Will this update reset my progress?**
A: No, all progress is preserved via cloud saves.

**Q: Do I need to update?**
A: Recommended but not required. Old versions will work but may have bugs.

**Q: How big is the update?**
A: [X] MB download, [X] MB installed.

**Q: What if I encounter bugs?**
A: Report at [GitHub issues link] or [Discord/email].

---

### 📞 SUPPORT

**Having issues?**
- Check Known Issues section above
- Visit our Discord: [link]
- Email: [support email]
- GitHub: [repo link]

**Response time:** 1-2 business days

---

### 🙏 CREDITS

**Development:** [Your name/team]
**Testing:** [Testers]
**Community:** [Discord/Reddit]
**Special Thanks:** [Contributors]

**Powered by:** Godot 4.4 | PlayFab

---

**Full Changelog:** [Link to detailed changelog]
**Previous Versions:** [Link to archive]

---

## Template Usage Notes

**Version Numbering:**
- X.0.0 = Major release (big features, breaking changes)
- 0.X.0 = Minor release (new features, improvements)
- 0.0.X = Patch release (bug fixes, small tweaks)
- 0.0.0-hotfix.X = Emergency fixes

**Tone:**
- Professional but friendly
- Transparent about issues
- Grateful to community
- Excited about future

**Length:**
- Keep descriptions concise (1-2 sentences)
- Group similar changes together
- Highlight player impact, not technical details
- Aim for <1000 words total

**Frequency:**
- Major: Every 3-6 months
- Minor: Every 2-4 weeks
- Patch: Every 1-2 weeks
- Hotfix: As needed (critical bugs)

---

**Save this template as:** `PATCH_NOTES_vX.Y.Z.md`
**Archive in:** `/patch_notes/` directory
**Publish to:** Website, Discord, app store listings, in-game news
