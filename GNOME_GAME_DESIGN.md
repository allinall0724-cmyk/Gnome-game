# Untitled Gnome Collector — Design Doc

## One-liner
Collect and farm biome-themed gnomes on your land for passive income, fight
through automatic Evolution Gates to unlock rarer gnomes, and manage soil
types, boosts, and weather events to optimize your plot.

## Platform
Roblox — local Rojo + GitHub workflow, solo dev.

---

## Core Loop

1. **Own a plot of land** with a fixed number of gnome slots
2. **Place gnomes on the land** — each gnome passively farms/produces money
   over time, no interaction needed
3. **Spend money** to buy more/better gnomes and expand your operation
4. **Repeat**, snowballing into bigger plots, better gnomes, more income

---

## How You Get Gnomes

### 1. Rotating Shop
- Shop rotates on a **timer**, offering different gnomes for a limited time —
  creates real FOMO/urgency, not just cosmetic variety
- Also sells: eggs (chance-based gnome reveal), damage boosts, coin/production
  boosts, and luck boosts for Evolution Gates — all **consumable/temporary**,
  need to be rebought, not permanent upgrades

### 2. Found on Land
- Some gnomes can be found directly on the plot of land (exact discovery
  mechanic TBD)

### 3. Evolution Gates
- A progression road of gates the player pushes through
- **Fights are fully automatic** — determined by the player's **total gnome
  power** (sum of stats across the whole collection), not a chosen team or
  player-controlled combat
- **Every few gates**: fight creatures guarding a captured gnome — winning
  breaks the gnome's chains and unlocks it for the player
- **Every 10 rounds**: a boss creature fight, unlocking a **boss gnome** on
  victory
- **Losing a gate fight**: sends the player back to the **start of the road**
  and imposes a **3-minute cooldown** before they can push through the gates
  again — a real setback, not a free-retry loop

---

## Gnome Types — Biome-Themed
- Gnomes come in biome types: **Forest, Desert, Mountain, Swamp** (expandable
  later)
- Each gnome is a **fixed unit** — no leveling up individual gnomes;
  progression comes from collecting better/rarer gnomes, not growing existing
  ones
- **Gnomes can be sold/dismantled** for currency if the player doesn't need
  them — gives weaker or duplicate gnomes ongoing value instead of just
  cluttering inventory

### Squad Composition Bonuses (Biome Clustering)
- Grouping multiple gnomes of the **same biome type** together grants a
  **scaling combo bonus** — more of the same biome in a cluster = bigger
  bonus (not a flat threshold)
- This bonus affects **both combat power (Evolution Gate fights) and farming
  production** — same-biome clustering is valuable everywhere, not just one
  system
- **Multiple simultaneous clusters are possible** — e.g. 3 Forest gnomes
  grouped together AND 3 Desert gnomes grouped together can each generate
  their own bonus at the same time, as long as each individual cluster is
  same-biome. Gnomes only "connect" with others of their own biome type —
  a mixed group doesn't combo with itself.
- This turns squad-building into an actual optimization puzzle: players
  decide whether to spread gnomes across many small same-biome clusters or
  consolidate into fewer, bigger ones for a larger scaling bonus per cluster

---

## Land & Soil
- **Buy more land** to extend the plot and increase gnome capacity — land
  size uses **fixed slots** (simple: more land = more slots, no soil-based
  capacity modifiers)
- **Different soil types** can be purchased/applied to land, each favoring
  specific gnome biome-types (e.g. Desert soil boosts Desert gnomes) —
  creates a real placement/strategy layer, not just "more slots = more money"

---

## Weather Events
- Random weather events occur **every ~10 minutes**, lasting **3–5 minutes**
- While active, gnomes gain **modifiers**: boosts to stats, production,
  speed, product sell price, etc.
- **Infinitely stackable** — multiple weather modifiers can apply at once —
  but **no duplicates** of the same modifier stacking on itself
- Creates a "drop what you're doing, this is a good window" live-event pull,
  similar to how Grow a Garden-style games use timed events for retention

---

## Systems List

| # | System | Notes |
|---|--------|-------|
| 1 | Land/Plot | Fixed gnome slots, expandable via purchase |
| 2 | Soil types | Purchasable, biome-matched boosts per gnome type |
| 3 | Gnome data | Biome type, base production rate, stats (power), rarity, sell value |
| 3b | Squad clustering | Detect same-biome groupings, calculate scaling bonus per cluster, apply to both combat power and production |
| 4 | Passive production | Server-side tick, sums active gnomes' production into player currency |
| 5 | Rotating shop | Timed rotation, sells gnomes/eggs + consumable boosts |
| 6 | Evolution Gates | Road/gate progression, auto-resolved fights based on total gnome power, chained-gnome unlocks every few gates, boss gnome every 10 |
| 7 | Loss penalty | Reset to start of road + 3 min cooldown on gate fight loss |
| 8 | Sell/dismantle | Convert unwanted gnomes to currency |
| 9 | Weather events | Timed (~10 min cycle, 3-5 min duration), stackable non-duplicate modifiers |
| 10 | Consumable boosts | Damage, production, luck — temporary, rebuyable |

## Suggested Build Order (solo, fastest path to playable core)

1. Gnome data module (type, stats, production rate, rarity, sell value) —
   plain data, no UI yet
2. Land/plot system — fixed slots, basic placement
3. Passive production loop — server tick granting currency from placed gnomes
4. Basic shop UI — buy a gnome, see it added to inventory/placed on land
5. Sell/dismantle a gnome for currency
6. Evolution Gate road — simple linear progression, auto-resolve fight using
   total gnome power vs. a gate "difficulty" number
7. Loss penalty (reset + cooldown)
8. Chained-gnome unlocks (every few gates) + boss gnome (every 10)
9. Soil types + biome matching
10. Rotating shop timer + FOMO-limited gnomes
11. Weather events (stackable modifiers) — last, since it's a live-service
    layer on top of an already-working core loop

## Notes / Guardrails
- All production ticks, gate-fight resolution, and currency changes must be
  **server-authoritative**.
- Keep gate "difficulty" numbers and gnome stat values in an easily tunable
  data table — this economy will need real balancing once gnomes/gates
  exist in enough numbers to test progression pacing.
- Since gnomes are fixed units (no leveling), the perceived progression
  entirely depends on the gnome stat curve across rarities feeling
  meaningfully different — this is worth prototyping early with just a
  handful of gnomes before building out the full roster.

---

## Team Split — 3 Workstreams

Split so each person can build and test independently against a shared
`GnomeData` module (defined first, owned by Person 1, but read-only for
everyone else) — avoids merge conflicts by keeping each person mostly in
their own folder/services.

### Person 1 — Land, Farming & Economy
Owns the passive-income core loop and the shared data foundation.
- **Gnome data module** — biome type, base stats, production rate, rarity,
  sell value (build this FIRST — everyone else depends on it)
- **Land/Plot system** — fixed slots, buying more land
- **Soil types** — purchasable, biome-matched production boosts
- **Passive production loop** — server tick granting currency from placed
  gnomes, factoring in soil match bonuses
- **Sell/dismantle system** — convert unwanted gnomes to currency
- **Squad clustering (production half)** — detect same-biome groupings on
  the land, calculate the production-side scaling bonus per cluster

### Person 2 — Evolution Gates & Combat
Owns the progression road and the automatic-fight resolution.
- **Evolution Gate road** — linear gate progression, gate difficulty values
- **Auto-resolve combat** — total gnome power vs. gate difficulty, win/lose
  determination
- **Squad clustering (combat half)** — same clustering data from Person 1,
  applied to combat power instead of production
- **Chained-gnome unlocks** — every few gates, unlock a captured gnome
- **Boss gnome fights** — every 10 rounds, bigger fight + boss gnome reward
- **Loss penalty** — reset to start of road + 3 min cooldown

### Person 3 — Shop, Boosts & Live Events
Owns everything that drives players to spend currency and check back
regularly.
- **Rotating shop** — timed rotation, sells gnomes/eggs, FOMO-limited stock
- **Consumable boosts** — damage, production, luck boosts (temporary,
  rebuyable)
- **Weather events** — ~10 min cycle, 3-5 min duration, stackable
  non-duplicate modifiers affecting stats/production/speed/sell price
- **Shop/boost UI** — purchase flows for all of the above

### Shared Dependency Notes
- Person 1's `GnomeData` module needs to be stubbed out (even with just
  placeholder values) on day one so Persons 2 and 3 aren't blocked waiting
  on final numbers.
- Squad clustering (3b in the systems list) is split across Person 1 and 2
  since it affects both production and combat — the *detection* logic
  (which gnomes are in which cluster) should live in one shared module
  both of them call into, rather than being duplicated.
- Weather event modifiers (Person 3) need to read from the same stat fields
  Person 1's production loop and Person 2's combat resolution use, so agree
  on those field names early.

