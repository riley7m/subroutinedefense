# Big Number System

Subroutine Defense supports numbers from 0 to **1az** (10^237) using a scientific notation system.

## Quick Start

### Displaying Numbers

```gdscript
# Use NumberFormatter singleton for formatting
var damage = 1500000000000  # 1.5 trillion
var formatted = NumberFormatter.format(damage)  # "1.50T"

# Works with BigNumber objects too
var big_damage = BigNumber.new(1.5, 27)  # 1.5 * 10^27 (1.5 octillion)
var formatted_big = NumberFormatter.format_big(big_damage)  # "1.50Oc"
```

### Creating Big Numbers

```gdscript
# From regular number
var bn1 = BigNumber.new(1500)  # 1.5 * 10^3

# From coefficient and exponent
var bn2 = BigNumber.new(1.5, 27)  # 1.5 octillion

# From string
var bn3 = BigNumber.from_string("1.5Oc")  # 1.5 octillion
var bn4 = BigNumber.from_string("1.5e27")  # Scientific notation

# Using NumberFormatter
var bn5 = NumberFormatter.to_big(1500)
var bn6 = NumberFormatter.parse("1.5Qa")  # 1.5 quadrillion
```

### Arithmetic

```gdscript
var a = BigNumber.new(1.5, 12)  # 1.5 trillion
var b = BigNumber.new(2.0, 12)  # 2.0 trillion

# All operations modify in-place and return self (for chaining)
var sum = a.copy().add(b)         # 3.5 trillion
var diff = a.copy().subtract(b)   # -0.5 trillion
var product = a.copy().multiply(b)  # 3.0 * 10^24
var quotient = a.copy().divide(b)   # 0.75

# Power
var squared = a.copy().power(2)  # 2.25 * 10^24

# With regular numbers
var scaled = a.copy().multiply(2)  # 3.0 trillion
```

### Comparisons

```gdscript
var a = BigNumber.new(1.5, 12)
var b = BigNumber.new(2.0, 12)

a.less_than(b)       # true
a.greater_than(b)    # false
a.less_equal(b)      # true
a.greater_equal(b)   # false
a.equals(b)          # false

# Helper functions
BigNumber.max_bn(a, b)  # Returns b (copy)
BigNumber.min_bn(a, b)  # Returns a (copy)
```

## Number Suffixes

### Standard Suffixes (10^3 - 10^138)

| Suffix | Name | Power | Example |
|--------|------|-------|---------|
| K | Thousand | 10^3 | 1.5K = 1,500 |
| M | Million | 10^6 | 1.5M = 1,500,000 |
| B | Billion | 10^9 | 1.5B = 1.5 billion |
| T | Trillion | 10^12 | 1.5T = 1.5 trillion |
| Qa | Quadrillion | 10^15 | 1.5Qa = 1.5 quadrillion |
| Qi | Quintillion | 10^18 | 1.5Qi = 1.5 quintillion |
| Sx | Sextillion | 10^21 | 1.5Sx = 1.5 sextillion |
| Sp | Septillion | 10^24 | 1.5Sp = 1.5 septillion |
| Oc | Octillion | 10^27 | 1.5Oc = 1.5 octillion |
| No | Nonillion | 10^30 | 1.5No = 1.5 nonillion |
| Dc | Decillion | 10^33 | 1.5Dc = 1.5 decillion |
| UnDc | Undecillion | 10^36 | 1.5UnDc |
| DoDc | Duodecillion | 10^39 | 1.5DoDc |
| TrDc | Tredecillion | 10^42 | 1.5TrDc |
| ... | | | |
| Vg | Vigintillion | 10^63 | 1.5Vg |
| ... | | | |
| Tg | Trigintillion | 10^93 | 1.5Tg |

### Letter Suffixes (10^141 - 10^237+)

After standard suffixes, uses letter pairs: **aa, ab, ac... az, ba, bb... zz**

| Suffix | Power | Name |
|--------|-------|------|
| aa | 10^141 | First letter pair |
| ab | 10^144 | |
| ... | | |
| az | 10^237 | "1 azimuth" |
| ba | 10^240 | |
| ... | | |
| zz | 10^3000+ | Maximum |

## Current Implementation

### int64 Storage (Default)

Most game values use **int64** (signed 64-bit integer):

- **Max value:** 9,223,372,036,854,775,807 (~10^18)
- **Display:** Up to **quintillions** (Qi)
- **Pros:** Fast, native GDScript type
- **Cons:** Can't exceed ~10^18

**Current limits:**
- Permanent damage: int64 max (~10^18 Qi)
- Archive Tokens: 10^18
- Fragments: 10^12

### BigNumber Storage (For Future)

For numbers beyond int64, use **BigNumber class**:

- **Max value:** Limited only by float precision (~10^308 mantissa, unlimited exponent)
- **Display:** Up to **1az** (10^237) with proper suffixes
- **Pros:** Unlimited growth, full arithmetic support
- **Cons:** Slower than native int, requires conversion

**Migration path:**
```gdscript
# Old way (int64)
var damage: int = 1500000000000

# New way (BigNumber for huge values)
var damage: BigNumber = BigNumber.new(1.5, 27)  # 1.5 octillion
```

## Integration

### Using with Existing int64 Values

The `NumberFormatter` handles both int64 and BigNumber:

```gdscript
# Works with int64
var damage_int: int = 1500000000000
var display1 = NumberFormatter.format(damage_int)  # "1.50T"

# Works with BigNumber
var damage_big = BigNumber.new(1.5, 27)
var display2 = NumberFormatter.format(damage_big)  # "1.50Oc"

# Auto-converts near int64 limit
var huge_int: int = 9000000000000000000  # Close to int64 max
var display3 = NumberFormatter.format_auto(huge_int)  # Uses BigNumber display
```

### Migration Strategy

**Phase 1 (Current):** int64 storage, extended display
- ✅ All values stored as int64
- ✅ Display supports K, M, B, T, Qa, Qi suffixes
- ✅ Max: ~10^18 (quintillions)

**Phase 2 (Future):** BigNumber for damage only
- Damage values switch to BigNumber
- AT/DC/Fragments stay int64 (costs don't need octillions)
- Display supports full suffix range (up to az)

**Phase 3 (Way Future):** Full BigNumber
- All currency values use BigNumber
- Unlimited progression
- Requires UI updates for BigNumber input

## Examples

### Display Damage

```gdscript
func update_damage_label():
    var damage = UpgradeManager.get_projectile_damage()

    # Method 1: Direct int64 formatting (current)
    damage_label.text = "Damage: %s" % NumberFormatter.format(damage)

    # Method 2: BigNumber for future (if damage becomes BigNumber)
    # damage_label.text = "Damage: %s" % NumberFormatter.format_big(damage)
```

### Save/Load BigNumber

```gdscript
# Save
func get_save_data() -> Dictionary:
    return {
        "damage_mantissa": big_damage.mantissa,
        "damage_exponent": big_damage.exponent
    }

# Load
func load_save_data(data: Dictionary):
    big_damage = BigNumber.new()
    big_damage.mantissa = data.get("damage_mantissa", 0.0)
    big_damage.exponent = data.get("damage_exponent", 0)
    big_damage.normalize()
```

### Cost Calculation with BigNumber

```gdscript
func can_afford(cost: BigNumber) -> bool:
    var current_at = BigNumber.new(RewardManager.archive_tokens)
    return current_at.greater_equal(cost)

func purchase_upgrade(cost: BigNumber):
    if can_afford(cost):
        var current = BigNumber.new(RewardManager.archive_tokens)
        current.subtract(cost)
        RewardManager.archive_tokens = current.to_int()  # Convert back if still in int64 range
```

## Performance

### Benchmarks (Approximate)

| Operation | int64 | BigNumber | Ratio |
|-----------|-------|-----------|-------|
| Add | 1ns | 50ns | 50x slower |
| Multiply | 1ns | 100ns | 100x slower |
| Format | 100ns | 500ns | 5x slower |

**Recommendation:** Use int64 until you need numbers > 10^18, then switch to BigNumber for that specific value type.

## Testing

```gdscript
# Test formatting
assert(NumberFormatter.format(1500) == "1.50K")
assert(NumberFormatter.format(1500000) == "1.50M")
assert(NumberFormatter.format(1500000000) == "1.50B")

# Test BigNumber
var bn = BigNumber.new(1.5, 27)
assert(bn.format(2) == "1.50Oc")

# Test arithmetic
var a = BigNumber.new(1.5, 12)
var b = BigNumber.new(2.0, 12)
var sum = a.copy().add(b)
assert(sum.format(2) == "3.50T")
```

## API Reference

### BigNumber Class

**Constructor:**
- `BigNumber.new(value=0, exp=0)` - Create from number or coefficient+exponent
- `BigNumber.from_string(text)` - Parse from string ("1.5Oc" or "1.5e27")

**Arithmetic (in-place, returns self):**
- `.add(other: BigNumber)` - Addition
- `.subtract(other: BigNumber)` - Subtraction
- `.multiply(other)` - Multiplication (BigNumber or number)
- `.divide(other)` - Division (BigNumber or number)
- `.power(exp: int)` - Exponentiation

**Comparison:**
- `.less_than(other)`, `.greater_than(other)`
- `.less_equal(other)`, `.greater_equal(other)`
- `.equals(other)`

**Conversion:**
- `.to_int()` - Convert to int64 (loses precision if > 10^18)
- `.to_float()` - Convert to float (loses precision if > 10^308)
- `.format(decimals=2)` - Display string with suffix
- `.format_scientific()` - Scientific notation (1.5e27)

**Utility:**
- `.copy()` - Deep copy
- `.normalize()` - Normalize to standard form

**Static:**
- `BigNumber.max_bn(a, b)` - Max of two BigNumbers
- `BigNumber.min_bn(a, b)` - Min of two BigNumbers

### NumberFormatter Singleton

**Formatting:**
- `NumberFormatter.format(value, decimals=2)` - Format int/float/BigNumber
- `NumberFormatter.format_big(bn, decimals=2)` - Format BigNumber
- `NumberFormatter.format_auto(value, decimals=2)` - Auto-detect type

**Creation:**
- `NumberFormatter.to_big(value)` - Create BigNumber
- `NumberFormatter.parse(text)` - Parse string to BigNumber

**Utility:**
- `NumberFormatter.needs_big_number(value)` - Check if value needs BigNumber
- `NumberFormatter.auto_convert(value)` - Convert to BigNumber if needed

---

**Last Updated:** 2025-12-26
**Version:** 1.0.0
