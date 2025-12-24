# Visual System Integration Guide

## What's Been Added

A complete runtime visual system that creates all graphics procedurally using GDScript.

## Files Created

1. **VisualFactory.gd** - Autoload singleton that generates all visuals
2. **crt_screen.gdshader** - CRT screen effect with scanlines
3. **cyber_grid.gdshader** - Animated background grid

## What's Integrated

The following scripts now automatically create visuals:

- ✅ **enemy.gd** - Different shapes per enemy type with glow layers + status effect overlays
- ✅ **tower.gd** - Concentric cyber rings
- ✅ **projectile.gd** - Elongated energy bullets
- ✅ **drone_flame.gd** - Orange flame drone visual
- ✅ **drone_poison.gd** - Purple poison drone visual
- ✅ **drone_frost.gd** - Cyan frost drone visual
- ✅ **drone_shock.gd** - Yellow shock drone visual

## Enemy Visuals by Type

- **Breacher**: Red diamond (aggressive)
- **Slicer**: Yellow triangle (fast attack)
- **Sentinel**: Blue hexagon (tank)
- **Null Walker**: Purple octagon (special)
- **Override**: Green rotated square (hacker)
- **Signal Runner**: Orange elongated diamond (speed)

## Status Effects

Enemies show pulsing colored rings when affected:
- 🔥 **Burn**: Red-orange ring
- 🟣 **Poison**: Purple ring
- ❄️ **Slow**: Cyan ring
- ⚡ **Stun**: Yellow ring

## Using the Shaders (Optional)

### CRT Screen Effect

Apply to a ColorRect covering your viewport:

1. In your main scene, add a `ColorRect` as a child of a `CanvasLayer`
2. Set its layout to "Full Rect"
3. In the `Material` property, create a new `ShaderMaterial`
4. Load `res://crt_screen.gdshader` as the shader
5. Adjust parameters in the inspector:
   - `scanline_count`: Line density (100-1000)
   - `scanline_intensity`: How visible lines are (0-1)
   - `vignette_strength`: Edge darkening (0-1)
   - `distortion_amount`: Screen curve (0-0.1)
   - `tint_color`: Screen color tint
   - `tint_strength`: Tint intensity (0-0.5)

### Cyber Grid Background

Apply to a ColorRect behind your gameplay:

1. Add a `ColorRect` as the first child (renders behind everything)
2. Set its size to cover the play area
3. Create a new `ShaderMaterial`
4. Load `res://cyber_grid.gdshader`
5. Adjust parameters:
   - `grid_color`: Grid line color (cyan recommended)
   - `grid_spacing`: Distance between lines (10-100)
   - `grid_alpha`: Opacity (0-1)
   - `scan_speed`: Animation speed (0-2)
   - `glow_intensity`: Line brightness (0-2)

## Customization

All visuals are generated in `VisualFactory.gd`. To customize:

- **Colors**: Edit the Color() parameters in each create function
- **Sizes**: Adjust radius values
- **Shapes**: Modify the polygon point arrays
- **Animations**: Use the helper functions at the bottom

Example - making enemies glow more:
```gdscript
# In VisualFactory.gd, find _create_breacher_visual()
var glow = _create_polygon_shape([...], Color(1.0, 0.2, 0.2, 0.5))  # Increase alpha from 0.3 to 0.5
glow.scale = Vector2(1.5, 1.5)  # Increase scale from 1.3 to 1.5
```

## Why This Approach Works

- ✅ **No .tscn editing** - Everything is pure code
- ✅ **One-line integration** - Just one call in each `_ready()` function
- ✅ **No external assets** - Polygon2D and Line2D only
- ✅ **Fully customizable** - All parameters in one file
- ✅ **Performance** - Lightweight vector graphics

## Troubleshooting

**Visuals don't appear:**
- Check that VisualFactory is registered as an autoload in project.godot
- Verify the integration lines are in each script's `_ready()` function

**Status effects stick around:**
- Check that the remove_status_effect_overlay() calls are in place
- Verify the effect names match exactly ("burn", "poison", "slow", "stun")

**Shaders not working:**
- Make sure the .gdshader files are in the root project directory
- Verify the ColorRect has a ShaderMaterial assigned
- Check that the shader file path is correct in the material
