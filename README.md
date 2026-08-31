# Gnome-game

Roblox gnome collector. See [GNOME_GAME_DESIGN.md](GNOME_GAME_DESIGN.md) for the
full design.

## What is built so far

The first playable slice: three starter gnomes standing on your plot, and one
Evolution Gate you can walk up to and fight.

- **Three gnomes**, built from parts (no imported assets) — classic garden
  gnomes with red pointed hats, white beards, tunics and boots:
  - Pip Toadstool — Forest, 14 PWR / 60 HP
  - Dustan Sandsock — Desert, 11 PWR / 50 HP
  - Bruk Stonebeard — Mountain, 17 PWR / 85 HP
- **Stage 1 — The Mossy Gate**, guarded by a Thistle Sprite (260 HP / 18 PWR).
- **Automatic gate combat**, as the design doc calls for: total squad power vs.
  the creature, resolved server-side. Your gnomes march through the gate, trade
  blows with the creature, and march home.
- **Loss penalty**: a 3 minute road cooldown, per the design doc.

The starter squad wins Stage 1 with roughly 40% health left, so it is beatable
but not a walkover.

## Running it

Needs [Rojo](https://rojo.space/docs/v7/getting-started/installation/).

1. Open Roblox Studio with a new **Baseplate** place (the map builds itself in
   code, so the place file can stay empty).
2. In this folder:
   ```
   rojo serve
   ```
3. In Studio, open the **Rojo plugin** and click **Connect**.
4. Press **Play**.

You spawn on the pad south of the plot. Walk north up the road to the stone in
front of the gate and hold **E** to challenge it.

## Layout

```
default.project.json   Rojo mapping
src/shared/
  GnomeData.lua        gnome stats, biomes, starter loadout  <- tune balance here
  Stages.lua           the gate road; tick rate and loss cooldown
  Parts.lua            primitive helpers (cones, discs, welding, nameplates)
  GnomeBuilder.lua     builds the gnome and creature models
src/server/
  init.server.lua      bootstrap: build map, hand out gnomes, wire the gate
  World.lua            the map, plot slots, arena slots
  GateService.lua      auto-resolved gate combat, server-authoritative
src/client/
  init.client.lua      squad panel, stage panel, battle overlay
```

## Not built yet

Everything else in the design doc: passive production, currency, land buying,
soil types, biome cluster bonuses, the shop, sell/dismantle, weather, and gates
2+. Also, this slice uses **one shared plot and one shared squad** for the
server — per-player plots arrive with the Land system.
