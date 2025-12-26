# Security Documentation

## 🔒 Security Overview

This document outlines security practices and what data is safe to be public in this repository.

## ✅ What's Safe to Be Public

### PlayFab Title ID
- **Location**: `CloudSaveManager.gd:14`
- **Value**: `"1DEAD6"`
- **Status**: ✅ **SAFE TO BE PUBLIC**
- **Why**: PlayFab Title IDs are designed to be in client code. They identify your game but don't grant access. Similar to Firebase project IDs or AWS Cognito pool IDs.

### Game Configuration
- All game balance values (upgrade costs, enemy stats, etc.)
- UI layouts and game logic
- Asset references

## 🔐 What Should NEVER Be Committed

### Authentication & API Keys
❌ **NEVER commit these** (protected by .gitignore):
- `export_presets.cfg` - May contain signing keys
- `*.keystore`, `*.jks` - Android signing keys
- `*.mobileprovision`, `*.p12` - iOS provisioning
- `.env` files - Environment variables
- `*secret*`, `*credentials*`, `*private_key*` - Any secret files

### User Data
❌ **Local save files** (automatically excluded via Godot's `user://` directory):
- `user://perm_upgrades.save` - Player progress
- `user://cloud_session.save` - Session tickets
- `user://device_id.save` - Device identifiers
- `user://boss_rush_leaderboard.save` - Local leaderboard

These files are stored in platform-specific locations:
- **Linux**: `~/.local/share/godot/app_userdata/Subroutine Defense/`
- **Windows**: `%APPDATA%/Godot/app_userdata/Subroutine Defense/`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/Subroutine Defense/`

## 🛡️ Security Measures in Place

### 1. Session-Based Authentication
- Session tickets expire after 24 hours
- Tickets are generated server-side by PlayFab
- No long-lived credentials stored in code

### 2. Password Security
- Passwords are NEVER stored locally
- PlayFab handles all password hashing and validation
- Password recovery handled by PlayFab servers

### 3. Device ID Protection
- Guest accounts use randomly generated UUIDs
- Device IDs stored locally (not in git)
- UUIDs are not sensitive (can't be used to access other accounts)

### 4. API Communication
- All API calls use HTTPS (encrypted)
- Session tickets sent via `X-Authorization` header
- No credentials in URL parameters

## 📋 Pre-Release Checklist

Before releasing your game, verify:

- [ ] No hardcoded test accounts or passwords
- [ ] `export_presets.cfg` not committed (contains signing keys)
- [ ] Android keystore files not committed
- [ ] iOS provisioning profiles not committed
- [ ] No `.env` files with secrets committed
- [ ] PlayFab Title ID is correct (public is OK)
- [ ] No developer notes with sensitive info

## 🚨 If You Accidentally Commit Secrets

If you accidentally commit sensitive data:

1. **Immediately rotate the compromised credentials**
   - PlayFab: Create new Title ID (if you leaked secret keys, though Title ID itself is safe)
   - Android: Generate new keystore
   - iOS: Revoke provisioning profile

2. **Remove from git history**:
   ```bash
   # Use git filter-branch or BFG Repo-Cleaner
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch PATH/TO/SECRET/FILE' \
     --prune-empty --tag-name-filter cat -- --all

   # Force push (WARNING: Rewrites history)
   git push origin --force --all
   ```

3. **Force push new history** (notify all collaborators)

## 🔍 Regular Security Audits

Run these checks periodically:

```bash
# Check for accidentally committed secrets
git log --all --full-history -- "*.keystore"
git log --all --full-history -- "*.env"
git log --all --full-history -- "*secret*"

# Check for large files (might be builds/assets)
git rev-list --objects --all | \
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
  awk '/^blob/ {print substr($0,6)}' | sort --numeric-sort --key=2 | tail -10
```

## 📚 Additional Resources

- [PlayFab Security Best Practices](https://learn.microsoft.com/en-us/gaming/playfab/features/data/playerdata/best-practices)
- [Godot Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-top-10/)

## 📞 Incident Response

If you discover a security vulnerability:

1. **Do not** disclose publicly until fixed
2. Assess impact (what data is exposed)
3. Rotate compromised credentials immediately
4. Remove from git history if committed
5. Document what happened and how to prevent it

---

**Last Updated**: 2025-12-26
**Next Review**: Before public release
