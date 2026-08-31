# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Roblox gnome-collector game, written in Luau and synced into Studio with Rojo.
`GNOME_GAME_DESIGN.md` is the spec of record — it defines the systems, the
numbers (3 min loss cooldown, ~10 min weather cycle, etc.) and the intended
build order. `README.md` tracks what is actually implemented so far versus what
is still only in the design doc. Read both before adding a system; most of the
design doc is not built yet, and new work should slot into its build order
rather than inventing a parallel structure.

Note the repo root is the inner `Gnome-game-main/` directory (the one holding
`default.project.json`); run all commands from there.

## Commands

The toolchain is pinned in `rokit.toml`. Nothing is on PATH by default — install
[Rokit](https://github.com/rojo-rbx/rokit), then:

```
rokit install          # rojo 7.6.1, StyLua 2.5.2, selene 0.31.0, luau-lsp 1.69.0
```

```
rojo serve                              # dev sync; connect from the Rojo Studio plugin
rojo build -o build.rbxlx               # one-off place build
rojo sourcemap default.project.json -o sourcemap.json   # needed by luau-lsp
stylua src                              # format (tabs, width 100 — see stylua.toml)
stylua --check src                      # verify formatting without writing
selene src                              # lint
luau-lsp analyze --sourcemap sourcemap.json src   # type check
```

There is no test suite; verification is done by running the place in Studio.

`selene.toml` needs the generated Roblox std, which is committed here as
`roblox.yml`. Regenerate with `selene generate-roblox-std` only if the API
surface used changes.

## Running the game

Open Roblox Studio on an **empty Baseplate** place, `rojo serve`, Connect from
the Rojo plugin, then Play. The place file is intentionally empty — the map,
gnomes and creature are all built at runtime by `World.luau` /
`GnomeBuilder.luau`, so nothing about the world lives outside source control.
Player spawn is south of the plot; walk north to the challenge stone and hold
**E**.

## Architecture

Rojo mapping (`default.project.json`): `src/shared` → `ReplicatedStorage.Shared`,
`src/server` → `ServerScriptService.Server`, `src/client` →
`StarterPlayerScripts.Client`. The four RemoteEvents are declared in the project
file, not created at runtime, so adding a remote means editing
`default.project.json` as well as the code.

**Data → world → fight → UI** is the dependency direction, and it is one-way:

- `src/shared/GnomeData.luau`, `src/shared/ShopData.luau` and
  `src/shared/Stages.luau` are pure data tables and the only place balance
  numbers live. Gnomes are fixed units (no leveling), so these tables *are* the
  progression curve. Tune here, never inline in a service. `GnomeData.Order` is
  an explicit array because `pairs()` order is not deterministic and the shop
  rotation seeds off it.
- `src/shared/Theme.luau` owns the entire look: palette, rarity/biome colours,
  and the builders (`Panel`, `Button`, `Pill`, `Price`, `GnomePortrait`,
  `Modal`) every screen is assembled from. Build new UI from these rather than
  raw `Instance.new`, or the screens drift apart. `GnomePortrait` renders a real
  `GnomeBuilder` model in a ViewportFrame, which is how cards show gnomes
  without importing art.
- `src/shared/Parts.luau` builds everything from primitives — no imported meshes
  or assets anywhere in the project. Models are built at a local origin with feet
  at `y = 0` facing `-Z`, then `Parts.Rig()` anchors the root, welds the rest to
  it and sets `PrimaryPart`, so a whole model can be tweened by driving its root
  alone. `GnomeBuilder.luau` composes these into gnome and creature models.
- `src/server/World.luau` owns map geometry and the slot coordinates
  (`PLOT_SLOTS`, `ARENA_SLOTS`, `ENEMY_POSITION`) that combat animation reads. The
  layout runs along `+Z`: plot at `z ≈ 0`, road north, gate at `z = 34`, arena
  beyond it.
- `src/server/GateService.luau` resolves gate fights. It takes a
  `powerMultiplier` argument rather than requiring `Economy`, which keeps combat
  independent of the economy layer.
- `src/server/Economy.luau` owns gold, the owned-gnome inventory, boosts and the
  production tick; `src/server/ShopService.luau` owns the rotation clock and
  validates purchases; `src/server/Weather.luau` runs the timed modifiers that
  both read.
- `src/server/init.server.luau` is the bootstrap: applies lighting, builds the
  map, places the starter squad, spawns the creature, starts the three economy
  services, and wires the challenge stone's ProximityPrompt to
  `GateService.Fight`.
- `src/client/` is draw-only. `init.client.luau` creates the one ScreenGui,
  builds `Hud`, `BattleUi`, `ShopScreen` and `InventoryScreen`, and does nothing
  but route remote payloads into them and player intent back out.

### Invariants to preserve

- **Server-authoritative.** Every damage roll, cooldown and (later) currency
  change happens on the server; remotes carry resulting numbers only. The client
  never computes an outcome it then reports back.
- **The client asks for state.** `init.server.luau` pushes state on `PlayerAdded`
  *and* answers a `RequestState` remote, because `PlayerAdded` can beat the
  LocalScript's listeners. Keep both paths when adding state.
- **Spawning is gated on the map.** The bootstrap sets
  `Players.CharacterAutoLoads = false`, builds the world, then re-enables it and
  loads anyone who joined meanwhile — otherwise players fall through the void.
- **Fight animation is decorative.** Tweens in `GateService` (lunge, flash,
  march) are fire-and-forget on top of the already-decided damage numbers; they
  must never gate or alter the combat loop.
- **Shop stock is derived, not broadcast.** `ShopData.StockFor(rotationIndex)`
  is deterministic and the rotation runs on wall-clock time, so client and
  server compute the same four gnomes independently; `ShopState` only carries
  the index. The server still recomputes stock to validate every purchase —
  never trust the client's idea of what is for sale.
- **Send the inventory only when it changed.** Every inventory card holds a
  ViewportFrame rendering a live gnome model, so `EconomyState` carries the
  `gnomes` list on change and omits it on the 1 Hz tick. The client merges.
- **No leveling.** The design doc is explicit that gnomes are fixed units.
  Reference mockups show level chips; do not add them.

### Current scope limits

The **plot and squad are shared per server** while **gold, inventory and boosts
are per player** — `init.server.luau` builds a single `squad` table at startup
and every player challenges the same gate, and `GateService` holds a single
`activeFight`. The visible consequence: buying gnomes raises a player's income
but not their gate power, since the fight uses the three gnomes on the shared
plot. The design doc wants total collection power; that lands when plots go
per-player with the Land system.

Because there is no Land system yet, `Economy` treats "owned" as "placed on
land" and every inventory gnome produces.

**Nothing persists** — profiles are in memory and there is no DataStore.

Only Stage 1 exists in `Stages.List`. Still unimplemented from the design doc:
land buying, soil types, biome cluster bonuses, gates 2+, chained-gnome unlocks
and boss gnome fights.

The design doc splits future work into three workstreams (land/economy, gates/
combat, shop/live-events) that all read from `GnomeData` as a shared, read-only
foundation — keep that module free of system-specific logic.
