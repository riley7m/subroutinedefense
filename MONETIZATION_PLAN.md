# Monetization Plan - Subroutine Defense

**Version:** 1.0
**Last Updated:** 2025-12-26
**Business Model:** Free-to-Play (F2P) with Optional Ads & IAP

---

## 🎯 Core Philosophy

**Priorities (in order):**
1. **Player Experience** - Fun first, monetization second
2. **Fairness** - No pay-to-win, cosmetics only for IAP
3. **Value** - Ads should feel rewarding, not punishing
4. **Respect** - No forced ads, no dark patterns
5. **Sustainability** - Enough revenue to support development

**Target:**
- 5-10% of players engage with ads
- 1-3% of players make IAP purchases
- $0.50-2.00 ARPU (Average Revenue Per User) monthly

---

## 💰 Revenue Streams

### 1. Rewarded Video Ads (Primary Revenue)

**Purpose:** Optional boost for engaged players

**Placements:**

**A) Offline Progress Doubling** ⭐ **PRIMARY**
- **Where:** Offline progress popup (on game launch after absence)
- **Offer:** "Watch ad to double offline rewards"
- **Benefit:** 50% efficiency → 100% efficiency (2x AT earned)
- **Frequency:** Once per login session (can be multiple per day)
- **Why it works:**
  - Players already getting something free (offline progress)
  - Doubling feels generous
  - Natural cadence (once per session)
  - High value proposition

**Example:**
```
Popup: "Welcome back! You were away 8 hours."
Offline Progress: 1,000 AT (25% efficiency)
[Watch Ad to Double] → 2,000 AT (50% efficiency)
```

**B) Daily Bonus Chest**
- **Where:** Start screen or main HUD
- **Offer:** "Daily free chest + watch ad for 3x rewards"
- **Benefit:** 500 AT → 1,500 AT (or fragments)
- **Frequency:** Once per day
- **Why it works:**
  - Creates daily login habit
  - Feels like a gift
  - 3x multiplier is attractive

**C) Boss Rush Retry** (Optional)
- **Where:** Boss Rush death screen
- **Offer:** "Watch ad to continue with 50% HP"
- **Benefit:** One retry per tournament
- **Frequency:** Max 3 times per week (tournament days)
- **Why it works:**
  - High stakes (tournament ranking)
  - Limited uses (doesn't cheapen experience)
  - Competitive players will use it

**D) Lab Speed Boost** (Optional)
- **Where:** Software lab panel
- **Offer:** "Watch ad to reduce duration by 20%"
- **Benefit:** Skip ahead in lab completion
- **Frequency:** Once per lab per day
- **Why it works:**
  - Long-term players have lots of labs
  - Convenience without breaking progression
  - Can stack with permanent lab acceleration

**Ad Revenue Estimate:**
```
10,000 MAU (Monthly Active Users)
5% watch ads = 500 active ad watchers
3 ads per day average = 1,500 ad views/day = 45,000/month

CPM: $10-20 (mobile games average)
Revenue: 45,000 / 1000 * $15 = $675/month

At 100,000 MAU: $6,750/month
```

---

### 2. Cosmetic IAP (Secondary Revenue)

**Purpose:** Vanity items for supporters, never gameplay advantage

**Pricing Tiers:**
- **Micro:** $0.99-1.99 (small cosmetics)
- **Small:** $2.99-4.99 (premium cosmetics)
- **Medium:** $4.99-9.99 (bundles)
- **Large:** $9.99-19.99 (exclusive packs)

**Items:**

**A) Tower Skins** ($1.99-4.99)
- Neon Tower (glowing outline)
- Matrix Tower (green digital effect)
- Cyber Tower (blue holographic)
- Gold Tower (prestige/flex)
- Animated effects (particle trails, idle animations)

**B) Projectile Effects** ($0.99-2.99)
- Rainbow bullets
- Lightning bolts
- Plasma orbs
- Laser beams
- Dragon fire

**C) UI Themes** ($1.99-3.99)
- Dark Mode (black/purple)
- Light Mode (white/gold)
- Retro Mode (CRT scanlines)
- Minimal Mode (clean UI)

**D) Death Screen Animations** ($0.99)
- Epic explosion
- Glitch effect
- Portal implosion
- Fireworks

**E) Background Themes** ($1.99)
- Space scene
- Cyberpunk city
- Digital void
- Matrix rain (enhanced)

**F) Victory Poses** ($1.99)
- Boss kill animations
- Wave milestone celebrations
- Tournament victory screens

**G) Bundles** ($9.99-19.99)
- Starter Pack: 3 skins + 2 effects + 1 theme
- Ultimate Pack: All cosmetics
- Seasonal Packs: Limited time themes

**IAP Revenue Estimate:**
```
10,000 MAU
1-3% conversion = 100-300 buyers
Average purchase: $5
Monthly: $500-1,500

At 100,000 MAU: $5,000-15,000/month
```

---

### 3. Premium Currency (Optional)

**Name:** Prisms (or Shards, Cores, etc.)

**Purpose:** Convenience currency for time-rich, money-poor players

**Earning:**
- Watch ads: 10 prisms per ad
- Daily login: 5 prisms/day
- Boss Rush participation: 25 prisms
- Achievements: 50-500 prisms
- Direct purchase: $0.99 = 100 prisms

**Spending:**
- Speed up lab: 50 prisms = -20% duration
- Instant lab completion: 500 prisms
- Refresh shop (if we add one): 25 prisms
- Cosmetic unlocks: 200-1000 prisms

**Why it might work:**
- Bridges F2P and paying players
- Gives ads secondary value
- Creates aspiration ("save up for skin")

**Why it might fail:**
- Adds complexity
- Players might feel pressured
- Could feel like pay-to-win if not careful

**Recommendation:** Wait for v2.0, focus on ads + cosmetics first

---

### 4. Battle Pass / Season Pass (Future)

**Concept:** $4.99/month subscription for exclusive rewards

**Benefits:**
- 2x offline progress efficiency (permanent during sub)
- Exclusive cosmetics (1 per month)
- Bonus fragments (+500/week)
- Priority support
- No ads (optional toggle)
- Exclusive Discord role

**Free Track vs Paid Track:**
- Free: Basic rewards (fragments, AT)
- Paid: Cosmetics, 2x bonuses, prisms

**Season Duration:** 30 days
**Target:** 0.5-1% of players subscribe

**Revenue Estimate:**
```
10,000 MAU
0.5% subscribe = 50 subscribers
$4.99 * 50 = $249.50/month

At 100,000 MAU: $2,495/month
```

**Recommendation:** Add after game is stable with 50,000+ MAU

---

## 🚫 What We Will NOT Do

**Never:**
- ❌ Pay-to-win (buying AT, DC, permanent upgrades)
- ❌ Loot boxes / gacha (predatory, controversial)
- ❌ Forced ads (interrupting gameplay)
- ❌ Energy systems (limiting play time)
- ❌ Wait timers that can only be skipped with money
- ❌ Exclusive content that's only available for money (cosmetics OK)
- ❌ Bait-and-switch (making game harder to sell solutions)

**Why:**
- Ethical concerns
- Player backlash
- Regulatory risks (especially loot boxes)
- Long-term sustainability > short-term gains

---

## 📊 Implementation Priority

### Phase 1: Launch (Ads Only)
**Focus:** Prove the game is fun and retains players

**Implement:**
1. Offline progress ad doubling
2. Daily bonus chest ad

**Revenue Goal:** Cover server costs ($50-100/month)
**Timeline:** Day 1

### Phase 2: Early Growth (Cosmetics)
**Focus:** Monetize superfans

**Implement:**
1. 3-5 tower skins
2. 2-3 projectile effects
3. 1 UI theme
4. Simple shop UI

**Revenue Goal:** Cover development time ($500-1000/month)
**Timeline:** Month 2-3

### Phase 3: Scaling (More Placements)
**Focus:** Optimize revenue

**Implement:**
1. Boss Rush retry ad
2. Lab speed boost ad
3. More cosmetic variety (10+ items)
4. Bundles

**Revenue Goal:** Sustainable income ($2,000-5,000/month at 50k+ MAU)
**Timeline:** Month 4-6

### Phase 4: Premium Features (Battle Pass)
**Focus:** VIP tier for supporters

**Implement:**
1. Monthly subscription
2. Exclusive cosmetics
3. QOL benefits (no ads, 2x efficiency)

**Revenue Goal:** Significant income ($5,000-10,000/month at 100k+ MAU)
**Timeline:** Month 7-12

---

## 🎨 Cosmetic Design Principles

**Must:**
- ✅ Look awesome (justify the price)
- ✅ Be visible during gameplay (not just menus)
- ✅ Not obscure important info (enemies, UI)
- ✅ Have previews (try before you buy)

**Should:**
- Fit the game's aesthetic (cyber/hacker theme)
- Have rarity tiers (common, rare, epic, legendary)
- Feel exclusive (limited quantity or time)
- Show status (flex to other players if multiplayer added)

**Examples:**

**Neon Tower ($2.99):**
- Glowing cyan outline
- Pulsing energy lines
- Sparkle particles on shoot
- Leaves light trail when upgrading

**Matrix Bullets ($1.99):**
- Green digital code trails
- Binary numbers floating off
- Glitch effect on hit
- Matrix rain on screen edges

---

## 💡 Monetization Best Practices

### Ad Implementation
1. **Always optional** - Never force
2. **Clear value** - "Watch ad for 2x rewards" not "Skip ad?"
3. **Respect time** - 30 second max, skippable after 5s if possible
4. **Limit frequency** - Once per session max for each placement
5. **Fallback** - If no ad available, give partial reward anyway

### IAP Implementation
1. **Preview** - Show what you're buying (screenshots, demos)
2. **Fair pricing** - $1-5 for most items, $10-20 for bundles only
3. **No regret** - Clear descriptions, refund policy
4. **Restore purchases** - Cross-device support
5. **Sale events** - 20-50% off occasionally (create urgency)

### Monetization UX
1. **Shop button** - Visible but not intrusive (bottom corner)
2. **First-time bonus** - 50% off first purchase
3. **Wishlists** - Let players bookmark items
4. **Gift system** - Buy for friends (future, social feature)
5. **Seasonal** - Limited time items (FOMO but fair)

---

## 📈 Analytics to Track

**Key Metrics:**
- **ARPU:** Average Revenue Per User
- **ARPPU:** Average Revenue Per Paying User
- **Conversion Rate:** % of players who spend
- **Ad Fill Rate:** % of ad requests filled
- **Ad Completion Rate:** % of ads watched to end
- **LTV:** Lifetime Value per player
- **DAU/MAU:** Daily/Monthly Active Users
- **Retention:** Day 1, 7, 30 retention rates

**Goals:**
- Day 1 retention: >40%
- Day 7 retention: >20%
- Day 30 retention: >10%
- Conversion: 1-3%
- ARPU: $0.50-2.00

**Benchmarks (Mobile Games):**
- Casual: $0.20-1.00 ARPU
- Mid-core: $1.00-5.00 ARPU
- Hardcore: $5.00-20.00 ARPU

---

## 🧪 A/B Testing Ideas

Test different approaches:

**Offline Ad Offer:**
- A: "2x offline rewards"
- B: "Double your progress"
- C: "Free 1,000 AT" (show exact number)

**Pricing:**
- A: Tower skins at $1.99
- B: Tower skins at $2.99
- C: Tower skins at $4.99

**Ad Placement:**
- A: Offline progress only
- B: Offline + daily chest
- C: Offline + daily + boss rush

**Track:** Which generates more revenue without hurting retention

---

## 🌍 Regional Considerations

**Ad CPM varies by region:**
- Tier 1 (US, UK, AU, CA): $10-20 CPM
- Tier 2 (EU, JP, KR): $5-10 CPM
- Tier 3 (Rest of world): $1-5 CPM

**Pricing adjustments:**
- Consider regional pricing (IAP costs less in India, Brazil, etc.)
- Google Play and App Store handle this automatically

---

## ⚖️ Balancing F2P vs Paying

**F2P Player Experience:**
- Can reach endgame without spending (3-6 months)
- Never feels pressured to pay
- Ads are optional bonuses, not requirements
- Cosmetics are nice-to-have, not status symbols

**Paying Player Experience:**
- Supports development (warm fuzzy feeling)
- Gets cool cosmetics (flex, self-expression)
- Slightly faster progression (battle pass)
- Never feels ripped off (fair prices)

**Whales (Top 5% spenders):**
- May buy all cosmetics ($50-100 total)
- Subscribe to battle pass ($5/month)
- Watch fewer ads (already supported game)
- Still play same game as F2P (no advantage)

---

## 🚀 Launch Strategy

### Soft Launch (100-1000 players)
- Ads only (offline progress)
- Test conversion rates
- Gather feedback on intrusion
- A/B test ad copy

### Public Launch (10,000+ players)
- Add cosmetic IAP
- Add daily bonus chest ad
- Monitor revenue vs retention
- Iterate based on data

### Growth (100,000+ players)
- Add more cosmetics
- Add battle pass
- Optimize ad placements
- Scale infrastructure

---

## 💬 Community Communication

**Be transparent:**
- "Ads keep the game free for everyone"
- "Cosmetics fund new content updates"
- "Battle pass is optional and cosmetic only"

**Listen to feedback:**
- If players hate ads, reduce frequency
- If IAP prices too high, adjust
- If battle pass feels pay-to-win, remove bonuses

**Stay ethical:**
- Never lie about what purchases do
- Never manipulate players (dark patterns)
- Never make game worse to sell solutions

---

## 📝 Legal & Compliance

**Required:**
- Terms of Service (TOS)
- Privacy Policy (GDPR, CCPA)
- Refund Policy
- Age rating (ESRB, PEGI)
- Parental controls (if targeting kids)

**Platform Requirements:**
- Google Play: 30% revenue share
- App Store: 30% revenue share (15% if <$1M/year)
- Ad networks: 20-40% revenue share

**Regulations:**
- Loot boxes banned/regulated in some countries
- COPPA (US) if targeting children
- GDPR (EU) for data collection
- Truth in advertising laws

---

## 🎯 Success Criteria

**Year 1 Goals:**
- 100,000+ downloads
- 10,000+ MAU
- $1,000-5,000/month revenue
- 4.0+ star rating
- Positive community (Discord, Reddit)

**Long-term Goals:**
- 1,000,000+ downloads
- 100,000+ MAU
- $10,000-50,000/month revenue
- Sustainable development (1-2 devs full-time)
- Active community (fan art, content creators)

---

## 🔮 Future Possibilities

**Year 2+:**
- Merchandise (t-shirts, stickers)
- Esports (boss rush tournaments with prizes)
- Content creators (sponsorships, affiliate codes)
- Licensing (other devs use our assets)
- Console port (premium upfront purchase)

---

**Conclusion:** Focus on player fun first, monetization second. Make money by making a great game, not by manipulating players.

**Next Steps:**
1. Integrate ad SDK (AdMob, Unity Ads, ironSource)
2. Design 3-5 cosmetic items
3. Implement shop UI
4. Test with alpha players
5. Launch with ads only, add IAP in month 2

**Estimated Development Time:**
- Ad integration: 1-2 days
- Cosmetic system: 3-5 days
- Shop UI: 2-3 days
- Testing: 1-2 days
- **Total: 1-2 weeks**

