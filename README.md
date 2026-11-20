# SailorsToSettlers

A cooperative survival and exploration map for Fortnite, built in UEFN. A crew of 2-12 players each sail to a new island, make camp together, and survive wave after wave of pirate raids.

> Status: concept. Numbers (timers, costs, scaling) are starting values to tune in playtests.

## Pitch

Each player sails their own boat from the outside edge of the sea and docks on the island. Where you land gives you a strength in one core job. Together the crew gathers water, wood, fire, food and pets to keep the island's NPCs happy and the settlement alive, and then fights off pirates who land from boats. This repeats for 10 rounds, with more pirate boats and higher stakes each time.

## Players

- 2-12 players share one world and work toward shared goals.
- Co-op only. Players depend on each other and don't compete.
- No classes. Differences between players come from where they land.

## Structure: a short intro, then 10 rounds of prepare and defend

The game moves forward for all players together.

| Phase | Player role | Length | Focus |
|---|---|---|---|
| 1. Castaways (intro) | Sailors | until docked | Sail your own boat (simple, easy controls) and explore to find a place to dock. The moment your boat touches land you are **docked** and your intro is over. Your landing spot gives you an advantage in one core job (for example landing near a spring helps with water). |
| 2. Settlers (prepare) | Settlers | 1 minute | Scavenge the shore, find and harvest water, harvest wood and make fire, turn local fauna into food or pets, find local flora for food, craft stronger weapons (takes wood). |
| 3. Defenders (defend) | Defenders | 1 minute | Defend the island from pirates! Pirates land in groups from boats and attack like zombies. More boats come in each successive defend phase. Any pirates still alive when the minute ends are removed. |

Phases 2 and 3 repeat 10 times with increasing difficulty and higher stakes. Phases are timer-only: each ends when its timer runs out, and nothing can end a phase early. The 1-minute timers are a starting point to tune. Players who haven't docked 1 minute after the voyage begins are automatically placed at a landing spot.

### Wood economy (agreed starting values, to tune in playtests)

- A player with no bonuses harvests about **30 wood per minute**. Landing in the wood zone and the wood-harvesting pet raise this (suggested +25% to +50% each).
- Weapon tier costs double: **10, 20, 40, 80, 160 wood** for tiers 1 to 5. Reaching tier 5 costs 310 wood in total, which is about 10 minutes of harvesting with no bonuses, or essentially all 10 prepare phases.
- Tier 3 (70 wood in total) takes about 2.3 minutes of harvesting, and tier 4 (150 wood) takes 5 minutes. That leaves room for fire, which also needs wood.

### Ending
- **Win:** survive round 10. The final attack includes a boss ship that the crew must fire at, plus a large pirate boss who lands on the island with the final wave. The round 10 battle lasts 3 minutes, longer than the normal 1-minute defend phase. If the crew survives the 3 minutes, they win, and the boss and boss ship die when the timer ends, just as ordinary pirates do.
- **Lose:** every player dies at the same time. This is an instant game over.

## Core loop

The crew has a shared stockpile of **water, wood, food and pets**, plus one communal **fire**. Neglecting any of them has a cost that carries into later rounds.

- **Water.** If there isn't enough, local NPCs get thirsty and angry, talk angrily at you, and may not help defend against pirates.
- **Wood and fire.** Wood fuels the one communal fire. If the fire isn't kept up, players have nightmares next round (impaired vision or performance). A hot enough fire revives players who died in the previous pirate round.
- **Wood and weapons.** Wood also crafts stronger weapons, in 5 tiers. The wood cost doubles with each tier. Weapons never reset: a weapon keeps its tier until the player upgrades it. Reaching tier 5 should take essentially every minute of every prepare phase spent harvesting wood, so most players should finish the game with tier 3 or 4, and tier 5 is rare. Tier 3 and above are ranged weapons. This is a deliberate trade-off: a bigger fire or stronger weapons?
- **Food.** Harvest enough food from plants and animals, or players have reduced health and performance.
- **Pets.** Any animal can be tamed. Pets are shared by the whole crew and never die, and each species gives a different crew bonus (see the pet table below). The cost to tame rises steeply with the total number of pets all players have tamed, and donating a pet to an NPC lowers that total. The first pet is cheapest, so selfish players race for it, but a coordinated crew can pick the best pets for the team.

### Pet species

Any animal can be tamed, and each of these species gives the crew one bonus. The base models (wolf, boar, chicken, raptor, jungle raptor) are the ones that exist in this project's editor. Three of the bonuses use re-tinted (recolored) copies of the wolf, boar and chicken.

| Bonus | Species | Why it fits |
|---|---|---|
| More damage in the defend phase | Wolf | Predator with fangs |
| More health in the defend phase | Boar | Tough and tusked |
| Improved food (plant) harvesting | Chicken | Pecks and forages |
| Hotter fire | Raptor (green with red markings) | Fiery colors |
| Improved water harvesting | Jungle Raptor (blue and teal) | Water colors |
| Improved wood harvesting | Boar, re-tinted green-brown | Roots through the undergrowth |
| Cheaper pet taming | Chicken, re-tinted gold | Friendly and cheerful |
| Cheaper weapon crafting | Wolf, re-tinted steel-grey | Forged-metal look |

## NPCs

- NPCs can all talk with you. Their lines are written by hand and change with the state of the game (resources, round number, how the crew has treated them).
- There are 8 NPCs. They wander around the island and are already there when the first player docks. Each wants one of four resources: water, wood, food or pets.
- Each NPC is satisfied in one of two ways: the **communal stockpile** of their resource reaches a higher level, or players **donate** that resource to them directly. There are two NPCs per resource, one of each kind.
- Satisfying an NPC helps the settlement grow and keeps them on your side in the defend phase.

### The 8 NPCs (agreed for now; the designer may change them later)

| NPC | Wants | How | Personality |
|---|---|---|---|
| Marisol the Well-Digger | Water | Communal stockpile reaches a high level | Calm and practical. Gets curt and cold when water runs short |
| Bartleby the Ship's Cook | Water | Players donate water to him | Gruff and dramatic. Talks about the soup he'll make |
| Oakley the Shipwright | Wood | Communal stockpile reaches a high level | Proud builder. Cheers each time the settlement grows |
| Hazel the Carpenter | Wood | Players donate wood to her | Brisk and bossy. Wants her tools replaced |
| Granny Mabel the Forager | Food | Communal stockpile reaches a high level | Warm, but scolds the crew when they go hungry |
| Pip the Cabin Boy | Food | Players donate food to him | Always hungry, cheerful, a bit of a worrier |
| Fennimore the Naturalist | Pets | Crew's total pet count reaches a high level | Excited scholar who loves the animals |
| Captain Dolly Quill | Pets | Players donate a pet to her | Old sailor who misses her parrot. Gruff but sentimental |

Pet donation (Dolly) uses one of the crew's tamed pets, so it competes with the crew's pet count for Fennimore.

## Round 10 boss

- **Boss ship:** sits offshore. Only players with a ranged weapon (tier 3 or above) can damage it.
- **Pirate boss:** a large pirate who lands with the final wave. It switches between two targeting modes every 15 seconds: the player with the lowest health, and the player who has dealt the most damage. The battle lasts 3 minutes, and surviving it wins the game.

## Death, difficulty and growth

- A player who dies in a defend phase spectates until the next round, when a hot enough fire revives them.
- Pirate difficulty is set from the number of players who joined, so 2 players and 12 players both get a fair fight.
- The crew sees the incoming pirate force's size and strength before each defend phase.
- The settlement visibly upgrades with each survived round (walls, towers and so on).

## Design pillars

- **Teamwork matters.** Shared resources and shared goals reward cooperation. The pet-cost rule makes the crew choose between selfish and coordinated play.
- **Clear progression.** Each phase feels higher pressure than the last, and players always know what to do next.
- **A sense of place.** The sea, the shoreline and the growing settlement tell the story.
- **Scales with the crew.** The map should be fun with 2 players and with 12.

## Decided

- World: one big island
- Persistence: one long session, no save data
- Roles or classes: none
- NPCs: the 8 listed below, two per resource (one communal-level, one donation). Fire is not an NPC want
- Pet re-tints: green-brown boar (wood), gold chicken (cheaper taming), steel-grey wolf (cheaper weapon crafting)
- Wood economy: 30 wood per minute base harvest, and weapon tiers cost 10, 20, 40, 80, 160
- Combat: PvE only, with pirates landing from boats during every defend phase
- Phases: timer-only, with no early ending
- Players who haven't docked by a deadline are auto-placed at a landing spot
- Docking deadline: 1 minute
- Landing zones: one coastal zone per job (water, wood, food, pets), and landing in a zone boosts that job
- Pets: shared by the crew, one species per bonus (8 bonuses), and they never die. Donating a pet to an NPC reduces the crew's pet count (and so lowers the taming cost)
- Weapons: 5 tiers, crafted with wood. The cost doubles each tier. Tier 3 and above are ranged. Weapons never reset between rounds
- NPCs wander the island and are present before the first player docks
- Boss ship: damaged only by ranged weapons (tier 3+)
- Pirate boss: toggles between attacking the lowest-health player and the highest-damage player every 15 seconds. The final battle lasts 3 minutes, and surviving it wins the game
- Round 10: a boss ship the crew must fire at, plus a large pirate boss who lands with the final wave

## Open questions

- What is the fallback if boat movement is too hard to build in UEFN (for example a scripted voyage)?

## Tech

- Engine: UEFN (Unreal Editor for Fortnite), with gameplay in Verse
- Project: `SailorsToSettlers.uefnproject`
- MCP servers for editor automation are configured in `.mcp.json`
- Design and engineering skills for this work live in `~/.claude/skills`

## Repository layout

- `Content/`: map and assets
- `Resources/`: project resources (icon)
