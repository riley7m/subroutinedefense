// PlayFab CloudScript for Subroutine Defense
// This JavaScript code runs on PlayFab servers for server-side validation
// Upload this to PlayFab Dashboard → Automation → CloudScript (legacy)

// ============================================================================
// BOSS RUSH VALIDATION
// ============================================================================

/**
 * Validates Boss Rush score submission
 * Prevents impossible scores and detects cheating
 *
 * @param {Object} args - {damage: int, waves: int, tier: int, timestamp: int}
 * @param {Object} context - PlayFab context
 * @returns {Object} {valid: bool, reason: string, rank: int}
 */
handlers.validateBossRushScore = function(args, context) {
    var damage = args.damage || 0;
    var waves = args.waves || 0;
    var tier = args.tier || 1;
    var submitTimestamp = args.timestamp || 0;
    var playerId = currentPlayerId;

    log.info("Validating Boss Rush score: " + damage + " damage, " + waves + " waves");

    // === BASIC VALIDATION ===

    // Check for negative/zero values
    if (damage <= 0 || waves <= 0) {
        return {
            valid: false,
            reason: "Invalid damage or wave count"
        };
    }

    // Check for impossibly high values
    if (damage > 1000000000000000000) {  // 10^18 (int64 max)
        return {
            valid: false,
            reason: "Damage exceeds maximum possible value"
        };
    }

    if (waves > 10000) {  // No one can survive 10,000 waves
        return {
            valid: false,
            reason: "Wave count impossibly high"
        };
    }

    // === RATE LIMITING ===

    // Get player's internal data (server-side only, can't be faked)
    var playerData = server.GetUserInternalData({
        PlayFabId: playerId,
        Keys: ["lastBossRushSubmit", "bossRushSubmitCount", "maxWaveReached"]
    });

    var now = Date.now();
    var lastSubmit = parseInt(playerData.Data.lastBossRushSubmit ? playerData.Data.lastBossRushSubmit.Value : 0);
    var submitCount = parseInt(playerData.Data.bossRushSubmitCount ? playerData.Data.bossRushSubmitCount.Value : 0);

    // Max 1 submission per 5 minutes
    if (now - lastSubmit < 300000) {  // 5 minutes in milliseconds
        return {
            valid: false,
            reason: "Submission too frequent. Wait 5 minutes between attempts."
        };
    }

    // Max 3 submissions per tournament (prevents grinding)
    var lastTournamentReset = getLastTournamentStartTime();
    var lastCountReset = parseInt(playerData.Data.lastTournamentReset ? playerData.Data.lastTournamentReset.Value : 0);

    if (lastCountReset < lastTournamentReset) {
        submitCount = 0;  // Reset counter for new tournament
    }

    if (submitCount >= 3) {
        return {
            valid: false,
            reason: "Maximum 3 submissions per tournament reached"
        };
    }

    // === PROGRESSION VALIDATION ===

    var maxWaveReached = parseInt(playerData.Data.maxWaveReached ? playerData.Data.maxWaveReached.Value : 0);

    // Player can't submit score for wave they've never reached
    // Allow +10 wave buffer for skill variance
    if (waves > maxWaveReached + 10) {
        return {
            valid: false,
            reason: "Wave count exceeds player progression (max: " + maxWaveReached + ")"
        };
    }

    // === DAMAGE PER WAVE SANITY CHECK ===

    var damagePerWave = damage / waves;
    var maxDamagePerWave = calculateMaxDamagePerWave(tier, waves);

    // Damage per wave can't exceed theoretical maximum for tier/wave
    if (damagePerWave > maxDamagePerWave * 2) {  // 2x buffer for variance
        return {
            valid: false,
            reason: "Damage per wave impossibly high for tier " + tier
        };
    }

    // === TOURNAMENT TIME VALIDATION ===

    if (!isTournamentActive()) {
        return {
            valid: false,
            reason: "Boss Rush not currently active"
        };
    }

    // === UPDATE PLAYER DATA (Server-side tracking) ===

    server.UpdateUserInternalData({
        PlayFabId: playerId,
        Data: {
            "lastBossRushSubmit": now.toString(),
            "bossRushSubmitCount": (submitCount + 1).toString(),
            "lastTournamentReset": lastTournamentReset.toString(),
            "maxWaveReached": Math.max(waves, maxWaveReached).toString(),
            "lastValidatedDamage": damage.toString()
        }
    });

    // === ALL CHECKS PASSED ===

    log.info("Score validated successfully for player " + playerId);

    return {
        valid: true,
        reason: "Score passed all validation checks",
        damagePerWave: Math.floor(damagePerWave)
    };
};

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Check if Boss Rush tournament is currently active
 * Tournaments run Mon/Thu/Sat (UTC 00:00-00:00)
 */
function isTournamentActive() {
    var now = new Date();
    var dayOfWeek = now.getUTCDay();  // 0=Sunday, 1=Monday, ..., 6=Saturday
    var tournamentDays = [1, 4, 6];  // Monday, Thursday, Saturday

    return tournamentDays.indexOf(dayOfWeek) !== -1;
}

/**
 * Get timestamp of last tournament start (most recent Mon/Thu/Sat at UTC 00:00)
 */
function getLastTournamentStartTime() {
    var now = new Date();
    var currentDay = now.getUTCDay();
    var tournamentDays = [1, 4, 6];

    // Find most recent tournament day
    var daysBack = 0;
    for (var i = 0; i < 7; i++) {
        var checkDay = (currentDay - i + 7) % 7;
        if (tournamentDays.indexOf(checkDay) !== -1) {
            daysBack = i;
            break;
        }
    }

    // Calculate timestamp of that day at UTC 00:00
    var tournamentStart = new Date(now);
    tournamentStart.setUTCDate(now.getUTCDate() - daysBack);
    tournamentStart.setUTCHours(0, 0, 0, 0);

    return tournamentStart.getTime();
}

/**
 * Calculate maximum theoretical damage per wave based on tier and wave number
 * This is a rough heuristic based on game balance
 */
function calculateMaxDamagePerWave(tier, wave) {
    // Base damage scales with tier exponentially (5^tier reward multiplier)
    var tierMultiplier = Math.pow(5, tier);

    // Wave scaling: HP increases by 1.13^wave * 5 in Boss Rush
    var hpScaling = Math.pow(1.13, wave) * 5;

    // Assume max damage is proportional to enemy HP
    // Boss has ~1000 base HP, scales with wave
    var baseEnemyHP = 1000;
    var enemyHP = baseEnemyHP * hpScaling;

    // Bosses per wave: 1-10 (increases every 10 waves)
    var bossCount = Math.min(Math.floor(wave / 10) + 1, 10);

    // Max damage per wave = (enemies killed * enemy HP) * tier multiplier
    // Assume player kills all bosses + some overkill
    var maxDamage = (bossCount * enemyHP * tierMultiplier) * 1.5;  // 1.5x overkill factor

    return maxDamage;
}

// ============================================================================
// SAVE DATA VALIDATION
// ============================================================================

/**
 * Validate cloud save data before accepting it
 * Prevents save file manipulation
 *
 * @param {Object} args - {saveData: string (JSON)}
 * @returns {Object} {valid: bool, reason: string}
 */
handlers.validateCloudSave = function(args, context) {
    var saveDataJson = args.saveData || "";
    var playerId = currentPlayerId;

    try {
        var saveData = JSON.parse(saveDataJson);

        // Validate currency bounds
        var at = saveData.archive_tokens || 0;
        var fragments = saveData.fragments || 0;

        if (at < 0 || at > 1000000000000000000) {  // 10^18
            return {valid: false, reason: "Invalid AT value: " + at};
        }

        if (fragments < 0 || fragments > 1000000000000) {  // 10^12
            return {valid: false, reason: "Invalid fragments value: " + fragments};
        }

        // Validate upgrade levels
        var permDamage = saveData.perm_projectile_damage || 0;
        if (permDamage < 0 || permDamage > 9223372036854775807) {  // int64 max
            return {valid: false, reason: "Invalid perm damage: " + permDamage};
        }

        // Validate wave count
        var totalWaves = saveData.total_waves_completed || 0;
        if (totalWaves < 0 || totalWaves > 1000000000) {  // 1 billion
            return {valid: false, reason: "Invalid wave count: " + totalWaves};
        }

        // Check for impossible progression speed
        var playerData = server.GetUserInternalData({
            PlayFabId: playerId,
            Keys: ["accountCreated", "lastSaveValidation"]
        });

        var accountCreated = parseInt(playerData.Data.accountCreated ? playerData.Data.accountCreated.Value : Date.now());
        var accountAgeDays = (Date.now() - accountCreated) / (1000 * 60 * 60 * 24);

        // Can't complete more than 100k waves per day (extremely generous)
        var maxWavesForAccount = accountAgeDays * 100000;
        if (totalWaves > maxWavesForAccount) {
            return {
                valid: false,
                reason: "Progression too fast for account age"
            };
        }

        // Update validation timestamp
        server.UpdateUserInternalData({
            PlayFabId: playerId,
            Data: {
                "lastSaveValidation": Date.now().toString(),
                "validatedWaves": totalWaves.toString()
            }
        });

        return {valid: true, reason: "Save data valid"};

    } catch (e) {
        return {valid: false, reason: "JSON parse error: " + e.message};
    }
};

// ============================================================================
// BAN SYSTEM
// ============================================================================

/**
 * Check if player is banned
 * Returns ban status and reason
 */
handlers.checkBanStatus = function(args, context) {
    var playerId = currentPlayerId;

    var playerData = server.GetUserInternalData({
        PlayFabId: playerId,
        Keys: ["banned", "banReason", "banExpiry"]
    });

    var banned = playerData.Data.banned ? playerData.Data.banned.Value === "true" : false;
    var banReason = playerData.Data.banReason ? playerData.Data.banReason.Value : "";
    var banExpiry = parseInt(playerData.Data.banExpiry ? playerData.Data.banExpiry.Value : 0);

    // Check if temporary ban has expired
    if (banned && banExpiry > 0 && Date.now() > banExpiry) {
        // Unban player
        server.UpdateUserInternalData({
            PlayFabId: playerId,
            Data: {
                "banned": "false",
                "banReason": "",
                "banExpiry": "0"
            }
        });
        banned = false;
    }

    return {
        banned: banned,
        reason: banReason,
        expiryTime: banExpiry
    };
};

/**
 * Report suspicious activity
 * Increments cheat counter, auto-bans after threshold
 */
handlers.reportSuspiciousActivity = function(args, context) {
    var playerId = currentPlayerId;
    var activityType = args.activityType || "unknown";

    var playerData = server.GetUserInternalData({
        PlayFabId: playerId,
        Keys: ["cheatScore", "cheatLog"]
    });

    var cheatScore = parseInt(playerData.Data.cheatScore ? playerData.Data.cheatScore.Value : 0);
    var cheatLog = playerData.Data.cheatLog ? JSON.parse(playerData.Data.cheatLog.Value) : [];

    // Increment cheat score
    cheatScore += 1;
    cheatLog.push({
        type: activityType,
        timestamp: Date.now()
    });

    // Auto-ban after 5 suspicious activities
    if (cheatScore >= 5) {
        server.UpdateUserInternalData({
            PlayFabId: playerId,
            Data: {
                "banned": "true",
                "banReason": "Multiple cheating violations detected",
                "banExpiry": "0",  // Permanent ban
                "cheatScore": cheatScore.toString(),
                "cheatLog": JSON.stringify(cheatLog)
            }
        });

        log.info("Player " + playerId + " auto-banned for cheating");

        return {banned: true, reason: "Multiple cheating violations"};
    }

    // Update cheat score
    server.UpdateUserInternalData({
        PlayFabId: playerId,
        Data: {
            "cheatScore": cheatScore.toString(),
            "cheatLog": JSON.stringify(cheatLog)
        }
    });

    return {
        banned: false,
        cheatScore: cheatScore,
        warning: "Suspicious activity logged"
    };
};
