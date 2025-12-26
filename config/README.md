# Game Configuration Files

This directory contains JSON configuration files for game balance and settings.

## Files

### `game_balance.json`
**Purpose:** Central configuration for all game balance values

**Usage:**
```gdscript
# Access via ConfigLoader singleton (autoload)
var damage_cost = ConfigLoader.get_in_run_base_cost("damage")
var tier_multiplier = ConfigLoader.get_tier_reward_multiplier_base()
```

**Sections:**

1. **permanent_upgrades** - AT-based permanent progression
   - `cost_scaling`: Exponential scaling factor (default: 1.13)
   - `base_costs`: Starting cost for each upgrade
   - `cost_increments`: Legacy parameter (not used)

2. **in_run_upgrades** - DC-based temporary upgrades
   - `cost_scaling`: Per-purchase scaling (default: 1.15)
   - `base_costs`: Initial cost for each upgrade
   - `per_level_bonuses`: Stat increase per level
   - `caps`: Maximum values for capped upgrades
   - `damage_milestone_scaling`: Special formula for damage scaling

3. **currency_rewards** - DC and AT earning rates
   - `wave_scaling_percent`: Linear wave scaling (default: 2% per wave)
   - `wave_at_bonus`: Polynomial wave completion bonus
   - `enemy_base_dc/at`: Base rewards per enemy type

4. **tier_system** - Progression tiers
   - `total_tiers`: Number of tiers (default: 10)
   - `waves_per_tier`: Waves to unlock next tier (default: 5000)
   - `reward_multiplier_base`: Exponential base (5^tier)

5. **boss_rush** - Tournament mode
   - `hp_scaling_base`: HP growth per wave (default: 1.13)
   - `fragment_rewards`: Rewards by leaderboard rank
   - `schedule`: Tournament days and time

6. **software_labs** - Long-term upgrades
   - `tier_1/2/3_labs`: Settings per tier
   - `cost_scaling`: Exponential cost increase
   - `duration_scaling`: Time increase per level

7. **drones** - Autonomous units
   - `base_stats`: Initial stats per drone type
   - `max_level`: Cap for drone upgrades
   - `cost_increment_per_level`: Linear cost increase

8. **offline_progress** - Idle rewards
   - `base_efficiency`: Earning rate without ad (25%)
   - `ad_efficiency`: Earning rate with ad (50%)
   - `max_duration_hours`: Cap on offline time (24h)

9. **fragments** - Premium currency
   - `boss_kill_base`: Base fragments per boss
   - `boss_rush_participation`: Fragments for entering

10. **enemy_types** - Enemy definitions
    - `base_hp/damage/speed`: Starting stats
    - `spawn_weight`: Relative spawn probability

11. **wave_progression** - Difficulty scaling
    - `base_hp_scaling`: HP growth per wave (1.02 = 2%)
    - `enemies_per_wave_growth`: Enemy count increase

12. **constants** - Game-wide values
    - Fixed values like viewport size, tower range

13. **save_system** - Persistence settings
    - Backup count, autosave interval, cloud sync

## Adding ConfigLoader to Project

1. **Add to autoload** (project.godot):
```ini
[autoload]
ConfigLoader="*res://ConfigLoader.gd"
```

2. **Access in scripts:**
```gdscript
# Get single value
var cost = ConfigLoader.get_in_run_base_cost("damage")

# Get complex config
var boss_rush_schedule = ConfigLoader.get_boss_rush_schedule()

# Reload after editing config file
ConfigLoader.reload_config()
```

## Editing Balance Values

### Safe to Edit:
- ✅ Base costs (adjust economy pace)
- ✅ Scaling factors (1.08, 1.13, 1.15 - change carefully)
- ✅ Per-level bonuses (stat increases)
- ✅ Caps (maximum values)
- ✅ Reward amounts (DC, AT, fragments)
- ✅ Enemy stats (HP, damage, speed)
- ✅ Offline efficiency percentages

### Dangerous to Edit:
- ⚠️ Exponents (1.15, 1.12, etc.) - small changes = huge impact
- ⚠️ Multiplier bases (changing 5^tier to 6^tier breaks late game)
- ⚠️ Formula coefficients without understanding formula

### Do NOT Edit:
- ❌ Key names (code references these exact strings)
- ❌ Structure (removing sections breaks ConfigLoader)
- ❌ Types (changing int to string will cause errors)

## Formula Reference

**Permanent Upgrade Cost:**
```
cost = base * (1.13 ^ level)
```

**In-Run Upgrade Cost:**
```
cost = base * (1.15 ^ purchases)
```

**Wave DC/AT Reward:**
```
reward = base * (1.0 + wave * 0.02) * multiplier * tier_mult
```

**Wave AT Bonus:**
```
bonus = floor(0.25 * (wave ^ 1.15)) * multiplier
```

**Boss Rush HP:**
```
hp = base * (1.13 ^ wave) * 5.0
```

**Lab Cost:**
```
cost = base * (scaling ^ (level - 1))
```

**Offline Progress:**
```
at = best_run_at_per_hour * efficiency * hours_away
```

## Testing Changes

1. Edit `game_balance.json`
2. Save file
3. Restart game (or call `ConfigLoader.reload_config()`)
4. Test affected systems
5. Check for:
   - Costs feel fair
   - Progression isn't too fast/slow
   - No integer overflows (very large numbers)
   - Late game still challenging

## A/B Testing

To test different balance approaches:

1. Create `game_balance_variant_a.json`
2. Copy original to `game_balance_variant_b.json`
3. Edit variant B with changes
4. Swap files and compare player feedback/metrics

## Version Control

- Always commit `game_balance.json` changes
- Document reasoning in commit messages
- Keep old versions in `config/archive/` for rollback

## Common Balance Adjustments

**Make early game easier:**
- Reduce in-run base costs (damage, fire_rate)
- Increase starting currency rewards
- Reduce permanent upgrade base costs

**Make late game harder:**
- Increase boss_rush hp_scaling_base
- Reduce offline efficiency
- Increase tier unlock requirements

**Speed up progression:**
- Reduce cost_scaling values (1.15 → 1.12)
- Increase wave_scaling_percent (0.02 → 0.025)
- Increase offline ad_efficiency (0.50 → 0.60)

**Slow down progression:**
- Increase cost_scaling values (1.13 → 1.15)
- Reduce per_level_bonuses
- Reduce fragment rewards

## Support

Questions about config files? See:
- `BALANCE_GUIDE.md` - Detailed formula explanations
- `FEATURE_STATUS.md` - System overviews
- Code comments in `UpgradeManager.gd`, `RewardManager.gd`

---

**Last Updated:** 2025-12-26
**Version:** 1.0.0
