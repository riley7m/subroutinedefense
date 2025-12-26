# PlayFab CloudScript Setup Guide

This guide walks you through deploying the CloudScript to PlayFab for online multiplayer features.

## Prerequisites

- PlayFab account created
- Title ID configured in game: `1DEAD6`
- Access to PlayFab Developer Dashboard

---

## Step 1: Upload CloudScript

### Navigate to CloudScript Editor:
1. Go to [PlayFab Developer Dashboard](https://developer.playfab.com)
2. Select your title
3. In the left menu, click: **Automation → Cloud Script**
4. You should see a tab called **"Revisions (Legacy)"** - click it

### Upload the Code:
1. Click the **"Upload new revision"** button
2. A code editor will appear
3. Open `playfab/CloudScript.js` from this repository
4. **Copy the entire file contents** (385 lines)
5. **Paste into the PlayFab editor** (replacing any existing code)
6. Click **"Save CloudScript"** or **"Upload"**
7. The new revision should become **"live"** automatically

✅ **CloudScript is now deployed!**

---

## Step 2: Configure Leaderboards

### Create Boss Rush Leaderboard Statistic:
1. Go to: **Leaderboards** in the left menu
2. Click **"New Leaderboard"**
3. Configure:
   - **Statistic Name:** `BossRushDamage`
   - **Aggregation Method:** `Last Value`
   - **Reset Frequency:** `Never` (or `Weekly` for weekly tournaments)
   - **Type:** `Integer`
   - **Sort Order:** `Descending` (higher is better)
4. Click **"Save Leaderboard"**

### Create Boss Rush Waves Statistic:
1. Click **"New Leaderboard"** again
2. Configure:
   - **Statistic Name:** `BossRushWaves`
   - **Aggregation Method:** `Last Value`
   - **Reset Frequency:** `Never`
   - **Type:** `Integer`
   - **Sort Order:** `Descending`
3. Click **"Save Leaderboard"**

✅ **Leaderboards configured!**

---

## Step 3: Verify CloudScript Functions

### Test the Deployment:
1. Go to: **Automation → Cloud Script**
2. Click the **"Functions"** tab
3. You should see these functions listed:
   - `validateBossRushScore`
   - `validateCloudSave`
   - `checkBanStatus`
   - `reportSuspiciousActivity`

### Optional: Test a Function
1. Select `validateBossRushScore` from the list
2. Click **"Test Function"**
3. Enter test parameters:
```json
{
  "damage": 1000000,
  "waves": 50,
  "tier": 1,
  "timestamp": 1640000000
}
```
4. Click **"Execute CloudScript"**
5. You should see a response like:
```json
{
  "valid": true,
  "reason": "Score passed validation"
}
```

✅ **CloudScript is working!**

---

## Step 4: Configure Title Data (Optional)

### Tournament Schedule Settings:
1. Go to: **Content → Title Data**
2. Add these keys (optional customization):
   - `TournamentDays`: `[1,4,6]` (Monday, Thursday, Saturday)
   - `MaxSubmissionsPerTournament`: `3`
   - `BossRushRateLimit`: `300` (5 minutes in seconds)

These have default values in CloudScript, so this step is optional.

---

## What's Now Working

✅ **Boss Rush Online Leaderboards:**
- Global leaderboard with rank-based fragment rewards
- Server-side score validation (prevents cheating)
- Rate limiting: 1 submission per 5 minutes
- Tournament schedule: Mon/Thu/Sat

✅ **Encrypted Cloud Saves:**
- AES-256 encryption for all save data
- Server-side validation before accepting saves
- Rate limiting: 10s uploads, 5s downloads
- MD5 integrity hashing (detects tampering)

✅ **Anti-Cheat System:**
- Impossible score detection
- Progression validation (can't skip ahead)
- Auto-ban after 5 violations
- Cheat score tracking

---

## Troubleshooting

### "Function not found" error:
- Make sure CloudScript is deployed (Revision should be "live")
- Check the function name matches exactly: `validateBossRushScore`
- Wait 1-2 minutes after upload for propagation

### "Invalid session ticket" error:
- Player needs to log in first via `CloudSaveManager`
- Session tickets expire after 24 hours

### Leaderboard not showing scores:
- Verify statistic name matches exactly: `BossRushDamage`
- Check PlayFab logs: **Data → Event History**
- Ensure score validation passes (check CloudScript logs)

### Save encryption errors:
- Encryption key generates automatically on first run
- Stored at: `user://encryption.key` (local only)
- Reinstalling game = new key = can't decrypt old saves (by design)

---

## Security Notes

🔒 **Encryption Key:**
- Generated locally per device (32 bytes, AES-256)
- NOT synced to cloud (prevents key theft)
- If user reinstalls, they lose access to old encrypted saves
- This is intentional for security

🔒 **Server-Side Validation:**
- CloudScript runs on PlayFab servers (can't be bypassed)
- Internal Player Data can't be modified by client
- All validation happens server-side before accepting data

🔒 **Rate Limiting:**
- Enforced both client-side AND server-side
- Server-side limits can't be bypassed by modifying client
- Prevents API spam and abuse

---

## Monitoring & Analytics

### View Player Data:
1. Go to: **Players** in left menu
2. Search for player by ID or email
3. Click player name
4. View **"Internal Data"** tab to see:
   - `lastBossRushSubmit` - Last submission timestamp
   - `maxWaveReached` - Highest wave reached
   - `bossRushSubmitCount` - Tournament submission count
   - `cheatScore` - Cheat violation count
   - `banned` - Ban status

### View CloudScript Logs:
1. Go to: **Automation → Cloud Script**
2. Click **"Logs"** tab
3. See execution history and errors

### View Event History:
1. Go to: **Data → Event History**
2. Filter by player ID
3. See all API calls and statistic updates

---

## Next Steps

1. ✅ Upload CloudScript (you're doing this now!)
2. ✅ Configure leaderboards (5 minutes)
3. 🧪 Test with a real player account
4. 📊 Monitor for cheaters via Player Internal Data
5. 🎮 Launch to production!

---

## Support

- **PlayFab Docs:** https://docs.microsoft.com/gaming/playfab/
- **CloudScript Guide:** https://docs.microsoft.com/gaming/playfab/features/automation/cloudscript/
- **Leaderboards Guide:** https://docs.microsoft.com/gaming/playfab/features/social/tournaments-leaderboards/

---

Last Updated: 2025-12-26
CloudScript Version: 1.0 (385 lines)
