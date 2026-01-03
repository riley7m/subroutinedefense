# Configuration Files

This directory contains game configuration files that can be modified without changing code.

## Files

### `game_balance.json`
Game balance configuration including:
- Permanent upgrade costs and scaling
- In-run upgrade costs and bonuses
- Currency rewards and scaling
- Tier system parameters
- Boss rush configuration
- Software labs settings
- Drone parameters
- Offline progress settings
- Enemy types and wave progression

**DO NOT commit changes to production values** - balance changes should be reviewed by game design team.

### `playfab_config.json`
PlayFab API configuration for cloud saves and online features.

**Structure:**
```json
{
  "title_id": "YOUR_PLAYFAB_TITLE_ID",
  "api_url": "https://{{TITLE_ID}}.playfabapi.com"
}
```

**Setup:**
1. Create a PlayFab account at [playfab.com](https://playfab.com)
2. Create a new title in your PlayFab dashboard
3. Copy your Title ID from the dashboard
4. Replace `YOUR_PLAYFAB_TITLE_ID` with your actual Title ID
5. The `{{TITLE_ID}}` placeholder will be automatically replaced at runtime

**Security Notes:**
- PlayFab Title IDs are designed to be public (safe to include in client code)
- DO NOT include secret keys or admin credentials in this file
- For production, consider using environment variables or secure config management
- See `SECURITY.md` in the project root for more information

### `playfab_config.json.example`
Template file showing the expected structure for PlayFab configuration.

**Usage:**
- Copy this file to `playfab_config.json` and fill in your values
- Helps new developers understand the required configuration format
- Safe to commit to version control (contains no sensitive data)

## Adding New Configuration

To add new configuration values:

1. Add the value to the appropriate JSON file
2. Add a getter function to `ConfigLoader.gd`
3. Update this README with documentation
4. Test with both default and custom values

## Configuration Loading

All configuration is loaded automatically by the `ConfigLoader` autoload at startup. If configuration files are missing or invalid, fallback defaults are used.

**Load Order:**
1. `ConfigLoader._ready()` loads `game_balance.json`
2. `ConfigLoader._ready()` loads `playfab_config.json` (optional)
3. Other managers access config via `ConfigLoader.get_*()` methods

**Error Handling:**
- Missing files: Warning logged, fallback defaults used
- Invalid JSON: Error logged, fallback defaults used
- Missing keys: Default values returned from getter functions
