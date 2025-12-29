# Graphics & UI Audit Report
**Date:** 2025-12-27
**Game:** Subroutine Defense
**Auditor:** Claude

---

## 🚨 CRITICAL ISSUES FOUND

### 1. Signal Connection Conflicts (CRITICAL)

#### ❌ Duplicate Connections (Will cause double-triggering)
| Button | .tscn Handler | Code Handler | Status |
|--------|--------------|--------------|---------|
| SpeedButton | `_on_speed_button_pressed` | `_on_speed_button_pressed` | ❌ DUPLICATE |
| DefenseButton | `_on_defense_button_pressed` | `_on_defense_button_pressed` | ❌ DUPLICATE |
| EconomyButton | `_on_economy_button_pressed` | `_on_economy_button_pressed` | ❌ DUPLICATE |

**Impact:** These buttons will fire their handlers TWICE per click, causing double purchases/actions.

#### ❌ Wrong Handler Names (Will cause errors)
| Button | .tscn Handler | Actual Handler | Status |
|--------|---------------|----------------|---------|
| OffenseButton | `_on_upgrade_damage_button_pressed` | `_on_offense_button_pressed` | ❌ HANDLER DOESN'T EXIST |
| DataCreditsUpgradeButton | `_on_data_credits_upgrade_button_pressed` | `_on_data_credits_upgrade_pressed` | ❌ HANDLER DOESN'T EXIST |
| ArchiveTokenUpgradeButton | `_on_archive_token_upgrade_button_pressed` | `_on_archive_token_upgrade_pressed` | ❌ HANDLER DOESN'T EXIST |
| FreeUpgradeChanceButton | `_on_free_upgrade_chance_button_pressed` | `_on_free_upgrade_chance_pressed` | ❌ HANDLER DOESN'T EXIST |
| WaveSkipChanceButton | `_on_wave_skip_chance_button_pressed` | `_on_wave_skip_chance_pressed` | ❌ HANDLER DOESN'T EXIST |

**Impact:** These buttons will show errors in console and may not work at all.

#### ✅ Correct Connections (OK)
| Button | Handler | Status |
|--------|---------|---------|
| BuyXButton | `_on_buy_x_button_pressed` | ✅ Only in .tscn (correct) |
| QuitButton | `_on_quit_button_pressed` | ✅ Only in .tscn (correct) |

---

### 2. Missing Graphics Assets (CRITICAL)

#### ❌ Drone Textures (Lines 108-134 in main_hud.tscn)
```tscn
[node name="Drone 1" type="TextureRect" parent="."]
offset_left = -18.0
offset_top = 615.0
offset_right = 12.0
offset_bottom = 645.0
# ❌ NO texture PROPERTY! This is invisible!

[node name="Drone 2" type="TextureRect" parent="."]
# ❌ NO texture property! Invisible!

[node name="Drone 3" type="TextureRect" parent="."]
# ❌ NO texture property! Invisible!

[node name="Drone 4" type="TextureRect" parent="."]
# ❌ NO texture property! Invisible!
```

**What's Missing:**
- `res://assets/drones/drone_flame.png`
- `res://assets/drones/drone_frost.png`
- `res://assets/drones/drone_poison.png`
- `res://assets/drones/drone_shock.png`

**Required Specs:**
- Size: 30x30 pixels (based on offset dimensions)
- Format: PNG with transparency
- Style: Cyberpunk/tech theme matching game aesthetic

#### ❌ Tower Sprite Using Placeholder (Line 99-106 in main_hud.tscn)
```tscn
[node name="Main Tower Sprite" type="TextureRect" parent="."]
texture = ExtResource("2_b71xr")  # This is icon.svg - the Godot default icon!
```

**What's Missing:**
- `res://assets/tower/tower_base.png` or similar
- Size: 128x128 pixels (based on offset 92,503 to 220,631 = 128x128)
- Format: PNG with transparency
- Should show upgradeable visual tiers (code references `tower.update_visual_tier()`)

**Current State:** Using Godot's default icon.svg as a placeholder

---

### 3. Missing Graphics - Complete List

| Asset Type | Path Needed | Size | Priority | Notes |
|------------|-------------|------|----------|-------|
| **Drones** |
| Flame Drone | `res://assets/drones/drone_flame.png` | 30x30 | HIGH | TextureRect expects this |
| Frost Drone | `res://assets/drones/drone_frost.png` | 30x30 | HIGH | TextureRect expects this |
| Poison Drone | `res://assets/drones/drone_poison.png` | 30x30 | HIGH | TextureRect expects this |
| Shock Drone | `res://assets/drones/drone_shock.png` | 30x30 | HIGH | TextureRect expects this |
| **Tower** |
| Tower Base | `res://assets/tower/tower_base.png` | 128x128 | CRITICAL | Currently using icon.svg |
| Tower Tier 1-5 | `res://assets/tower/tower_tier_*.png` | 128x128 | MEDIUM | For visual upgrades |
| **Enemies** |
| Enemy sprites | Various | Various | MEDIUM | May be using TextureRects or Sprites2D |
| **Projectiles** |
| Projectile sprite | `res://assets/projectiles/projectile.png` | ~10x10 | MEDIUM | For tower bullets |
| **UI Elements** |
| Button backgrounds | Various | Various | LOW | Using theme default |
| Panel backgrounds | Various | Various | LOW | Using theme default |

---

### 4. Node Path Verification

#### ✅ In-Run Upgrade Buttons (Referenced in main_hud.gd)
| Variable | Node Path | Exists in .tscn? | Line |
|----------|-----------|------------------|------|
| `damage_upgrade` | `$UpgradeUI/OffensePanel/DamageUpgradeButton` | ✅ YES | 158 |
| `fire_rate_upgrade` | `$UpgradeUI/OffensePanel/FireRateUpgradeButton` | ✅ YES | 163 |
| `crit_upgrade_button` | `$UpgradeUI/OffensePanel/CritChanceUpgradeButton` | ✅ YES | 168 |
| `crit_damage_upgrade` | `$UpgradeUI/OffensePanel/CritDamageUpgradeButton` | ✅ YES | 172 |
| `unlock_multi_target_button` | `$UpgradeUI/OffensePanel/UnlockMultiTargetButton` | ✅ YES | 176 |
| `upgrade_multi_target_button` | `$UpgradeUI/OffensePanel/UpgradeMultiTargetButton` | ✅ YES | 180 |
| `multi_target_label` | `$UpgradeUI/OffensePanel/MultiTargetLabel` | ✅ YES | 184 |
| `shield_upgrade` | `$UpgradeUI/DefensePanel/ShieldIntegrityUpgradeButton` | ✅ YES | 195 |
| `regen_upgrade` | `$UpgradeUI/DefensePanel/ShieldRegenUpgradeButton` | ✅ YES | 200 |
| `reduction_upgrade` | `$UpgradeUI/DefensePanel/DamageReductionUpgradeButton` | ✅ YES | 204 |
| `data_credits_upgrade` | `$UpgradeUI/EconomyPanel/DataCreditsUpgradeButton` | ✅ YES | 240 |
| `archive_token_upgrade` | `$UpgradeUI/EconomyPanel/ArchiveTokenUpgradeButton` | ✅ YES | 245 |
| `free_upgrade_chance` | `$UpgradeUI/EconomyPanel/FreeUpgradeChanceButton` | ✅ YES | 250 |
| `wave_skip_chance` | `$UpgradeUI/EconomyPanel/WaveSkipChanceButton` | ✅ YES | 254 |

**Status:** ✅ All button node paths are correct!

#### ✅ Permanent Upgrade Buttons (Referenced via perm_nodes dict)
All permanent upgrade button paths verified correct (lines 20-65 in main_hud.gd, lines 275-417 in .tscn).

#### ⚠️ Runtime-Created Elements (Not in .tscn)
These are created programmatically in `_ready()`:
- `fragments_label` - Created at line 236
- `tier_label` - Created at line 245
- `software_upgrade_button` - Created at line 172
- `tier_selection_button` - Created at line 184
- `boss_rush_button` - Created at line 196
- `statistics_button` - Created at line 204
- `statistics_panel` - Created at line 1050

**Potential Issue:** Z-order conflicts with .tscn elements, positioning may be fragile.

---

## 📋 RECOMMENDED FIXES

### Fix 1: Remove All Signal Connections from .tscn ✅
**Reason:** Code already handles all connections. Having both creates duplicates and errors.

**Action:** Remove lines 435-444 from main_hud.tscn

### Fix 2: Add Missing Drone Textures 🎨
**Action:** Create 4 drone sprites (30x30 PNG):
1. Flame drone - Red/orange with fire effect
2. Frost drone - Blue/cyan with ice effect
3. Poison drone - Purple/green with toxic effect
4. Shock drone - Yellow/electric with lightning effect

Then update main_hud.tscn lines 108-134 to add texture properties.

### Fix 3: Create Tower Sprite 🎨
**Action:** Create tower_base.png (128x128) and replace icon.svg reference

### Fix 4: Consider Moving Runtime UI to .tscn 🔧
**Reason:** Mixing runtime/scene creation causes maintenance issues

**Options:**
A) Move fragments_label, tier_label, and UI buttons to .tscn
B) Keep as-is but document clearly

---

## 🎮 IMPACT ON MY BUTTON COST CHANGES

### ✅ My Changes Will Still Work Because:
1. I'm updating button `.text` property directly
2. Button node references (`@onready var`) are correct
3. Update functions don't depend on signal connections

### ⚠️ But These Issues Will Cause Problems:
1. **Duplicate connections** - SpeedButton, DefenseButton, EconomyButton will fire twice
2. **Missing handlers** - OffenseButton and Economy panel buttons may not work
3. **Missing graphics** - Drones and tower will be invisible or show default icon

---

## 🔧 IMMEDIATE ACTION ITEMS

1. **CRITICAL:** Fix signal connections in main_hud.tscn (remove duplicates)
2. **HIGH:** Create drone sprite assets (4 files)
3. **HIGH:** Create tower sprite asset (1 file)
4. **MEDIUM:** Test all buttons work correctly after connection fixes
5. **LOW:** Consider consolidating runtime/scene UI creation

---

## ✅ WORKING CORRECTLY

1. ✅ All button node paths are valid
2. ✅ Permanent upgrade buttons show costs correctly
3. ✅ In-run upgrade cost display logic is sound
4. ✅ Buy X/5/10/Max calculation works
5. ✅ UI update functions are correctly structured
