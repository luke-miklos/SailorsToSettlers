# SailorsToSettlers: Development Plan

Draft for review. See [README.md](README.md) for the design. This plan turns it into build steps. Time estimates are deliberately left out; the order and the exit criteria matter more.

## Approach

1. **De-risk first.** Build throwaway prototypes of the two things most likely to break the design (boats, and crowd load) before building anything that depends on them.
2. **Build the spine, then fill it.** The round and phase manager, the shared resource stockpile and the config come first. Everything else plugs into them.
3. **One vertical slice early.** A single full round (prepare, defend, result) with placeholder content, playable by 2+ people, before adding all 8 NPCs, pets, and 10 rounds.
4. **Tunable by design.** Every number (timers, costs, pirate counts, thresholds) lives in one config so playtests only change data, not code.

## Progress

- **M0 (in progress):** Verse build loop verified (clean build). `game_config.verse` holds the agreed numbers, and a throwaway `smoke_test_device.verse` is placed in `Prototypes/M0_Smoke`. Still to do: run it in a play session.
- **M1 / P1 (started):** `boat_dock_prototype.verse` is written, builds cleanly, and is wired to a motorboat spawner in `Prototypes/P1_Boats`. Dock detection polls `fort_vehicle.IsOnGround`. The level already has a large island, an ocean (water level about z = -52) and lakes. The boat spawner is in open water at (43000, 18056), east of a gentle beach marked by a Device Mannequin at about (40300, 18056). The two Verse test devices are on the beach at x = 39000. Ran in a play session: the smoke test prints correctly and the boat spawns. The level had no player spawn device, so players fell from the sky; a spawn pad is now on the beach at (39800, 18056). Design note from the first test: each player should spawn already seated in their own boat at sea, and sail to a landing spot of their choice, so the next P1 step is one boat spawner per player with auto-seating (check `AssignDriver`). Docking detection confirmed with one player: the Verse output printed "DOCKED" about 6 seconds after boarding, when the boat touched land at speed 11, so `IsOnGround` works and the scripted-voyage fallback looks unnecessary. Not yet tested with several players (testing is solo for now). Seating works: `AssignDriver` put the player in the boat. The prototype has since grown into `boat_fleet.verse`: 12 boat spawners in a line at sea (x = 43000, y = 13856 to 21556, 700 apart), player N (in join order) gets boat N, unused boats stay disabled, and a `PlayerDockedEvent` fires with the dock position. The editor can't wire boat references into a Verse array, so the device has 12 separate fields (`Boat1` to `Boat12`). Play-tested solo: the player was seated in boat 1, but first appeared on the beach pad and was moved a second later. To remove that hiccup, the beach pad is gone and 12 player spawners now sit above the boats (z = 250). Tested on 2026-11-20: the player first appears at (42996, 13853, 353), right above boat 1, and is seated about a second later, so the beach hiccup is gone. `boat_fleet` now prints that first position. Session tooling note: after `StopGame`, a Verse-only `PushChanges` was refused ("Refresh command is not currently available") even with a real edit, so a full `StopSession` and `StartSession` was needed to load the new code. What's left for P1 is the multiplayer test (4+ players, each in their own boat, all reported docked), which needs real testers.
- **M1 / P2 (first run done, 2026-11-20):** `crowd_load_test.verse` plus 6 spawners in `Prototypes/P2_Crowd` on the beach (x 35500 to 37800). 2 guard spawners stand in for the 8 NPCs (team 1), 2 wildlife spawners (wolf, boar, team 1) for 12 pets, and 2 hostile guard spawners (team 2) for pirates. Everything is invulnerable, so the fighting goes on without stopping and the counts stay fixed. The controller tops up the counts and raises pirates by 10 every 40 s, printing a `P2 STEP` line each time. Solo run, measured with the Spatial Profiler (24 s window per step, median values):

  | AI alive (NPC + pets + pirates) | Client frame | Client game update | Client GPU | Server frame (median / max) |
  |---|---|---|---|---|
  | 30 (8 + 12 + 10) | 17.2 ms | 16.2 ms | 6.1 ms | 33.4 / 35.8 ms |
  | 40 | 33.4 ms | 20.2 ms | 6.9 ms | 33.4 / 40.4 ms |
  | 50 | 33.4 ms | 22.8 ms | 6.9 ms | 33.4 / 46.8 ms |
  | 60 | 33.7 ms | 27.8 ms | 7.5 ms | 33.4 / 50.0 ms |
  | 70 | 34.1 ms | 31.3 ms | 8.0 ms | 33.4 / 60.2 ms |
  | 80 | 37.1 ms | 34.7 ms | 8.6 ms | 33.4 / 61.7 ms |
  | 90 | 40.0 ms | 37.5 ms | 8.9 ms | 33.4 / 37.8 ms |

  Findings: (1) **The island has a hard limit of 90 active AI** (guards, creatures and wildlife together), which the spawners state. Exceeding it needs a per-spawner opt-in that Epic warns about. Tamed pets count toward it. (2) The server held its 30 Hz tick (33.4 ms median) all the way to 90; its worst spikes grew to about 60 ms at 70 to 80 AI. (3) The client is CPU-bound: game update grows by about 0.35 ms per AI, and GPU stays well under budget. The jump from 17 to 33 ms frame time between 30 and 40 AI is partly the frame rate dropping from 60 to 30 fps, and partly the tester moving the camera onto the beach. (4) Caveats: editor, server and client all ran on one PC, so the client numbers are pessimistic, the test had 1 player rather than 12, and there is no 0-AI baseline (the match couldn't be restarted, see below). **Proposed content budget: plan for about 50 AI alive at once (8 NPCs + up to 12 pets + about 30 pirates), with 90 as the absolute ceiling, and recheck on a published build with 12 players in M8.** This makes the "pile of pets" design pet-capped: the crew-wide pet total needs a hard cap (about 12) in `game_config`. Wildlife spawners have taming built in (tamed follow distance, 1 to 3 tamed per player), which lowers the M5 taming risk. Tooling note: with the island set to auto-start, `StopGame` returns Completed but the match keeps running; only `StopSession` ends it. Findings so far: UEFN has a real `vehicle_spawner_boat_device` with a `SpawnedEvent`, `AgentEntersVehicleEvent` and per-vehicle `IsInWater`, `IsOnGround`, `GetOccupants` and `Speed`.

- **M2 (in progress, branch `lbm/m2_spine`):** `game_manager.verse` is the state machine (Intro, then Prepare / Defend / Result for each of the 10 rounds, then Victory; GameOver from any timed phase). `resource_stockpile.verse` is the single owner of water, wood, food and pets (pets capped at `MaxCrewPets`), and there is a text HUD for each player. Intro waits for every player to dock or for the deadline, then teleports stragglers to a landing-spot teleporter. Dead players are tracked from `fort_character.EliminatedEvent`, and everyone dead at once is an instant game over. The dead are revived with `agent.Respawn` at the start of the next prepare phase (unconditionally for now; M4 ties it to the fire). Test settings on the device: `TimeScale` (currently 0.1 in the level), `FakeHarvest` (currently on) and `SimulateWipeAtRound`. Island settings changed to Spawn Limit 1 (spectate after death), manual respawn off, and eliminated players keep their items. Tested on 2026-11-20: the win path ran all 10 rounds with an 18 s final defend (3 min at 0.1x) and ended in Victory, after which the end-game device ended the match. The loss path (simulated wipe in round 3) ended in Game Over at once. The docking deadline teleport worked. `boat_fleet` now gives each player the free boat nearest the spawn pad they landed on (the island picks pads at random), verified with boat 9. Not yet tested: whether the HUD shows correctly. Real-death test on 2026-11-20 (4 hostile pirates, solo): the elimination was detected in round 1's defend phase, but with Spawn Limit 1 Fortnite itself ends the match the moment the last player is out (game state goes back to CanStart). So solo, the revive can't be tested, and a real full wipe ends the match before our Game Over screen. **Decision: keep real spectating (Spawn Limit 1).** Test the revive with 2+ testers, and accept that a full wipe ends the match without our end screen for now (revisit in M7 for the final tallies).

- **M2: done** for everything one person can test (HUD confirmed by the tester). The revive needs 2+ testers.
- **M3 (in progress, branch `lbm/m3_island`):** four `landing_zone` devices with a 50 m radius: Wood on the north headland shore (41000, 11500), Food on the north-east beach (10000, 40000), Water on the east coast (-12000, 34500) near the large lake, and Pets on the west coast (24000, -40000). There are 12 `harvest_node`s (4 each for wood, water and food). Each is a button with a 2 s hold, which is about 30 per minute, and rests 3 s after use. Gathering only counts during Prepare for living players and goes straight to the stockpile. The landing bonus is 1.5x (+1 every 2nd gather of your job), given from the dock position; players placed ashore by the deadline get none. The boats and their spawn pads were moved from x = 43000 to x = 53000 (deep water, about 100 m out), because the old start line was only about 20 m from the headland. Fixed false docks: an unused boat spawner's pad keeps its collision, so touching "ground" within 30 m of any spawner is ignored. Button devices have their pivot at mid-height (128 cm above the base), so they're now placed at the highest nearby ground + 128 cm. Tested on 2026-11-20: a real dock on the headland gave the Wood bonus, wood rose 1, 3, 4, 6, and gathering in Defend gave nothing. Food also verified: docked at (10044, 41607), got the Food bonus, food rose 1, 3. Water verified by the tester too. **M3 done:** all three gathering zones work (dock, right bonus, gather into the shared stockpile). The pets zone exists but has no nodes until M5.

- **M4 (in progress, branch `lbm/m4_slice`):** `communal_fire.verse` (heat 0 to 100, starts at 50; a feed spends 5 crew wood for +10 heat; cools 0.15 per second in Prepare and Defend). At each round start the fire revives last round's dead if heat >= 50, and gives nightmares (max health 70 for the round) if heat < 25. `camp_station.verse` is a camp button that either feeds the fire or upgrades the user's weapon, which spends the next tier's cost from the crew wood and calls `GrantItemIndex(tier)` on one item granter. Pirate waves: two shore guard spawners (team 2, disabled outside Defend) land `2 + 1 per player + 1 per round` pirates, capped at 30, and any still alive are removed when Defend ends. The HUD adds the fire heat, the pirate forecast (in Prepare) or pirates ashore (in Defend), the weapon tier and next cost, and a nightmare warning. Level: camp at the landing beach (folder `Game/M4_Camp`) with a Campfire device as the visual (lit while heat > 0, its own healing set to 0), and pirate spawners at (38600, 16000) and (38600, 20500). Granter set to Keep All (it defaulted to Clear Inventory). Granter items (set via MCP, tier order): Torch, Infinity Blade, Flintlock pistol, epic pump shotgun, legendary assault rifle. These are the only melee items in the project besides the Flag. Pirate boats as visuals are deferred.

## Architecture (proposed)

All gameplay is in Verse, in a few small modules instead of one large device. This is the shape to build toward, not a contract.

| Module | Responsibility |
|---|---|
| `game_config` | All tunable numbers: phase lengths, resource thresholds, pet cost curve, pirate scaling, round count |
| `game_manager` | The state machine: Intro, Prepare, Defend, Result, GameOver, Victory. Owns the round counter and timers |
| `resource_stockpile` | Shared crew stockpile: water, wood, food, pets. Exposes add, spend, level and change events |
| `fire_system` | The one communal fire: fuel from wood, heat level, effects (nightmares, revive) |
| `boat_system` | Per-player boats, steering, dock detection, landing-zone bonus |
| `harvest_system` | Water, wood and food sources, gathering, respawn timing, landing bonus applied |
| `pet_system` | Taming, the escalating cost, pet behavior and stats, owner or team assignment |
| `npc_system` | 8 NPCs: wants, satisfaction, mood, state-driven dialogue |
| `pirate_system` | Per-round pirate boats, landing, zombie-like waves, cleanup at round end, boss ship |
| `player_state` | Per-player status: alive, spectating, debuffs, landing bonus, revive handling |
| `ui_system` | HUD: timer, round, stockpile, fire, pirate forecast, NPC prompts |
| `settlement_growth` | Visible upgrades unlocked by surviving rounds |

Related skills installed in `~/.claude/skills`: `uefn-disciplines` (which skill for which concept), `verse-patterns` (state machines, timers, multiplayer authority), `game-ai-uefn` (enemies), `uefn-device-gotchas`, `uefn-ui-widgets` and `game-ui-designer` (HUD), `uefn-profiling` (performance), `level-design-uefn` (island layout), `game-feel-uefn`, `camera-audio-uefn`.

Reference code in `C:\Users\lukeb\Documents\Fortnite Examples` that looks relevant: `uefn-verse-examples/examples/vehicles-movement/move-boat-manager.verse` and the custom vehicle and car examples (boats); `UEFN-Verse-Collection/Game/enemy_wave_spawner.verse` and `boss_fight.verse` (pirate waves and boss). These need reading before use; I haven't verified them against the current UEFN version.

## Milestones

### M0: Project setup
- Confirm the Verse build loop works (edit, build, push) and the MCP servers connect.
- Create the Verse folder layout and an empty `game_config`.
- Set up a basic island blockout area for testing.
- **Done when:** an empty device builds and runs in a play session.

### M1: Risk prototypes (throwaway)
**P1: Boats.** One player-controlled boat on water: simple steering, collision with the shore, and "docked" detection when it touches land.
- Try the vehicle-device route and a custom Verse-moved route. Pick the one that gives simple, reliable controls.
- Test with several players in separate boats.
- **Fallback if neither works well:** a scripted voyage (the boat moves along a path and the player chooses a landing point), which the README already allows.
- **Done when:** 4+ players can each sail a boat, land, and be reported as docked, and we know the fallback isn't needed (or we have chosen it).

**P2: Crowd load.** 12 players, 8 NPCs, a pile of pets and a pirate wave on the placeholder island.
- Measure with `uefn-profiling`. Find out the real ceiling on pirate and pet counts.
- **Done when:** we have a number for "max pirates and pets at a stable frame rate", which sets the content budget for the rest of the plan.

### M2: Game spine
- `game_manager` state machine with the intro-then-10-rounds cycle and the timer from `game_config`.
- Rule for players who haven't docked when the first round starts (for example a deadline, then they are placed at a landing spot).
- `resource_stockpile` with events, and a minimal HUD showing timer, round and stockpile.
- Spectator handling for players who die, and the "all players dead" instant game over.
- **Done when:** a test session cycles through all rounds with fake data and ends correctly in both win and loss.

### M3: Island and harvesting
- Island layout with distinct coastal zones tied to the four jobs (water, wood, food, pets), so a landing spot means something.
- `harvest_system` for water, wood and food, with respawn and gather-rate rules.
- Landing-zone bonus applied from the player's dock location.
- **Done when:** a player docks, gets the right bonus, and gathers into the shared stockpile.

### M4: Fire and defense (the first vertical slice)
- `fire_system`: wood in, heat level, nightmare debuff when neglected, and revive of last round's dead players when hot enough.
- Wood-to-weapons crafting, with the fire-or-weapons trade-off made visible in the HUD.
- `pirate_system` (basic): pirate boats arrive, land, attack like zombies, and are removed at the end of the defend phase. Difficulty from the number of players who joined. The crew sees the pirate forecast before each round.
- **Done when:** one full playable round works end to end, with 2 players and with 8+, and the difficulty feels fair at both.
- **Checkpoint:** playtest the slice before building more. If the 2-minute phases are too short or too long, tune now.

### M5: Food, pets and consequences
- Food gathering and the "reduced health and performance" penalty.
- `pet_system`: taming any animal, the cost curve that rises with the crew's total pets, species-specific pet roles, shared by the crew, never dying. Decisions needed first (see Decisions).
- Settlement upgrades after each survived round.
- **Done when:** the pet cost rule creates a visible "race versus coordinate" choice in a test session.

### M6: NPCs
- `npc_system` with 8 NPCs, two per resource (one communal-level, one donation, per the README).
- Mood tracking, written dialogue that depends on game state, and the effect on the defend phase (a satisfied NPC helps, an angry one doesn't).
- HUD hints that tell players what each NPC wants.
- **Done when:** every NPC can be satisfied and angered, and their dialogue clearly reflects the game state.

### M7: Content, scaling and the finale
- Pirate scaling for rounds 1 to 10: more boats each round, and a pass to find the difficulty curve.
- Round 10 boss ship.
- Win and lose screens, final tallies.
- **Done when:** a full 10-round run is playable and winnable by a good crew.

### M8: Polish and performance
- Game feel, audio, effects, camera moments for docking and the boss (`game-feel-uefn`, `camera-audio-uefn`).
- Performance pass against the M1 budget, including a full 12-player test.
- Art and lighting pass on the island.
- **Done when:** a full 12-player game holds a stable frame rate.

### M9: Playtest and publish
- Structured playtests at 2, 6 and 12 players. Record where players get stuck.
- Tune the numbers in `game_config`.
- Prepare the title, description, thumbnail and tags, and publish.

## Decisions

Decided (also in the README):
- Docking deadline is 2 minutes, then players are auto-placed at a landing spot.
- Prepare and defend phases are 2 minutes each, and the round 10 final battle is 4 minutes (all raised on 2026-11-20 from 1, 1 and 3 minutes; the docking deadline from 1 to 2).
- One coastal zone per job (water, wood, food, pets), with a landing bonus.
- Pets are shared and never die. There are 8 bonuses, one species each. Donating a pet to an NPC reduces the crew's pet count.
- 5 weapon tiers. The wood cost doubles each tier, and tier 3 and above are ranged weapons.
- Phases are timer-only.
- 8 NPCs wander the island and are present before players dock.
- Round 10: a boss ship that only ranged weapons (tier 3+) can damage, plus a large pirate boss that toggles between the lowest-health player and the highest-damage player.

Also decided: re-tinted wolf, boar and chicken fill the three remaining pet bonuses (assignment confirmed). Weapons never reset. The pirate boss toggles targeting every 15 seconds, and the final battle lasts 4 minutes. Surviving it wins the game and the bosses die when the timer ends.

AI budget (from P2): at most about 50 AI alive at once, inside UEFN's hard limit of 90. The crew's pets are capped at 12 in total, because every pet takes an AI slot, which leaves about 30 pirates alive at once. All in `game_config`, to recheck with 12 players in M8.

Agreed starting values, still to tune in playtests (in `game_config`): harvest about 30 wood per minute per player, weapon tier costs 16, 32, 64, 128, 260 (500 wood in total for tier 5; rescaled on 2026-11-20 for the 2-minute prepare phases).

No design decisions are blocking. The NPC roster is agreed for now and can be changed by the designer later.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Boat movement is hard or unreliable in UEFN | Intro phase and pirate boats both depend on it | Prototype first (P1), with the scripted voyage as the fallback. Pirate boats can be simpler than player boats |
| Too many actors (12 players, pets, pirates, NPCs) | Frame rate drops | Prototype first (P2), cap counts, use `uefn-profiling`, and keep per-tick work out of Verse |
| Phase length feels wrong (raised to 2 minutes; a full game is now about 45 minutes) | Tasks can't be finished, so the loop feels bad | Keep every number in `game_config` and tune in the M4 playtest |
| The 2-player and 12-player experience diverge | Map is only fun at one size | Scale pirates from the number of players who joined, and test both sizes at M4 |
| Pet cost curve is too punishing or too weak | The "selfish or coordinated" design doesn't land | Make the curve a config value and playtest it in M5 |
| Taming needs custom logic: wildlife spawners make wild animals, not followers | Pets are the least-proven system | Prototype taming early in M5 (swap a wild animal for a follower NPC) and keep per-pet logic cheap |
| Shared stockpile with many players causes contention bugs | Wrong counts, desyncs | One authority module owns the stockpile and everything else sends requests to it |

## Working agreements

- Commit at the end of each milestone, and use a branch per milestone.
- Playtest at each "Done when" before moving on.
- Update the README's Decided and Open sections as questions are answered.
- New lessons about UEFN or Verse go into the `uefn-lessons` skill.

## Suggested first steps

1. Review the open decisions above and answer the ones needed for M2 and M3.
2. Start M0 and M1 (P1, boats), because the answer shapes everything after.
3. After P1 and P2, revise this plan with the real numbers.
