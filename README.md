# Gnome-game

Roblox gnome collector. See [GNOME_GAME_DESIGN.md](GNOME_GAME_DESIGN.md) for the
full design.

## What is built so far

Three starter gnomes standing on your plot, one Evolution Gate you can walk up
and fight, and the economy loop around them: earn gold, spend it in the
rotating shop, dismantle what you don't want.

- **A 19 gnome roster** across all four biomes and four rarities, built from
  parts (no imported assets) — classic garden gnomes with red pointed hats,
  white beards, tunics and boots. The three starters are:
  - Pip Toadstool — Forest, 14 PWR / 60 HP
  - Dustan Sandsock — Desert, 11 PWR / 50 HP
  - Bruk Stonebeard — Mountain, 17 PWR / 85 HP
- **Stage 1 — The Mossy Gate**, guarded by a Thistle Sprite (260 HP / 18 PWR).
- **Automatic gate combat**, as the design doc calls for: total squad power vs.
  the creature, resolved server-side. Your gnomes march through the gate, trade
  blows with the creature, and march home.
- **Loss penalty**: a 3 minute road cooldown, per the design doc.
- **Passive production** — a server tick turns each owned gnome's production
  rate into gold.
- **Rotating shop** — four gnomes on a 15 minute rotation, three mystery eggs
  plus a featured boss egg, and damage / production / luck boosts. Legendary
  gnomes are egg-only.
- **Sell / dismantle** — multi-select in the inventory and cash gnomes in.
- **Weather events** — a random event every ~10 minutes for 3-5 minutes,
  stacking (but never duplicating) production, damage and luck modifiers.

The starter squad wins Stage 1 with roughly 40% health left, so it is beatable
but not a walkover.

## Interface

Dark, chunky panels with colour-coded borders — rarity on shop and inventory
cards, biome on squad cards. Every screen is assembled from the builders in
`src/shared/Theme.luau`; put new UI through those so it stays one interface.

Inventory and shop cards show the **real gnome model** rendered in a
ViewportFrame rather than an icon, which keeps the no-imported-assets rule
intact all the way into the UI.

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
front of the gate and hold **E** to challenge it. **SHOP** and **INVENTORY** in
the top right open the two screens.

## Layout

```
default.project.json   Rojo mapping (RemoteEvents are declared here)
rokit.toml             pinned toolchain (rojo, stylua, selene, luau-lsp)
src/shared/
  GnomeData.luau      the roster: stats, rarity, price, sell value  <- tune here
  ShopData.luau       eggs, boosts, rotation and economy constants  <- and here
  Stages.luau         the gate road; tick rate and loss cooldown
  Theme.luau          palette and UI builders (panels, cards, buttons, portraits)
  Parts.luau          primitive helpers (cones, discs, welding, nameplates)
  GnomeBuilder.luau   builds the gnome and creature models
src/server/
  init.server.luau    bootstrap: build map, hand out gnomes, wire the gate
  World.luau          the map, plot slots, arena slots
  GateService.luau    auto-resolved gate combat, server-authoritative
  Economy.luau        gold, owned gnomes, production tick, boosts
  ShopService.luau    rotation clock, purchase validation, selling
  Weather.luau        the timed live-event modifiers
src/client/
  init.client.luau    bootstrap: builds the screens and routes remotes
  Hud.luau            gold, weather banner, boost pills, screen buttons
  ShopScreen.luau     the full-page rotating shop
  InventoryScreen.luau  biome filter rail, gnome grid, sell bar
  BattleUi.luau       squad panel, stage panel, battle overlay
```

## Not built yet

From the design doc: land buying, soil types, biome cluster bonuses, gates 2+,
chained-gnome unlocks and boss gnome fights.

Known limits of the current slice:

- **One shared plot and one shared squad** per server. Per-player plots arrive
  with the Land system. Gold, inventory and boosts *are* per player.
- Because of that split, **buying gnomes raises your income but not your gate
  power** — the fight still uses the three gnomes standing on the shared plot.
  The design doc wants total collection power; that lands when plots go
  per-player.
- Inventory doubles as "placed on land", so every owned gnome produces.
- **Nothing persists.** State is in memory and resets when the server stops;
  there is no DataStore yet.
