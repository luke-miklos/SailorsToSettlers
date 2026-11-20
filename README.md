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

Phases 2 and 3 repeat 10 times with increasing difficulty and higher stakes. Moving on is driven by crew milestones, and a timer forces the next phase if the crew is not ready. The 1-minute timers are a starting point to tune.

### Ending
- **Win:** survive round 10. The final attack includes a boss ship.
- **Lose:** every player dies at the same time. This is an instant game over.

## Core loop

The crew has a shared stockpile of **water, wood, food and pets**, plus one communal **fire**. Neglecting any of them has a cost that carries into later rounds.

- **Water.** If there isn't enough, local NPCs get thirsty and angry, talk angrily at you, and may not help defend against pirates.
- **Wood and fire.** Wood fuels the one communal fire. If the fire isn't kept up, players have nightmares next round (impaired vision or performance). A hot enough fire revives players who died in the previous pirate round.
- **Wood and weapons.** Wood also crafts stronger weapons. This is a deliberate trade-off: a bigger fire or stronger weapons?
- **Food.** Harvest enough food from plants and animals, or players have reduced health and performance.
- **Pets.** Any animal can be tamed. Pets increase stats and help against pirates. The cost to tame rises steeply with the total number of pets all players have tamed. The first pet is cheapest, so selfish players race for it, but a coordinated crew can pick the best pets for the team.

## NPCs

- NPCs can all talk with you. Their lines are written by hand and change with the state of the game (resources, round number, how the crew has treated them).
- There are 8 NPCs. Each wants one of four resources: water, wood, food or pets.
- Each NPC is satisfied in one of two ways: the **communal stockpile** of their resource reaches a higher level, or players **donate** that resource to them directly. A natural split (proposed) is two NPCs per resource, one of each kind.
- Satisfying an NPC helps the settlement grow and keeps them on your side in the defend phase.

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
- Combat: PvE only, with pirates landing from boats during every defend phase

## Open questions

- Is the two-per-resource split (one communal-level, one donation) right? Fire isn't an NPC want. Is that intended?
- What are the 8 NPCs' names and personalities?
- How exactly do landing spots map to core-job bonuses?
- Do pets die, and does a dead pet make taming cheaper again? Are pets owned by one player or shared?
- What does the boss ship do in round 10?
- What is the fallback if boat movement is too hard to build in UEFN (for example a scripted voyage)?

## Tech

- Engine: UEFN (Unreal Editor for Fortnite), with gameplay in Verse
- Project: `SailorsToSettlers.uefnproject`
- MCP servers for editor automation are configured in `.mcp.json`
- Design and engineering skills for this work live in `~/.claude/skills`

## Repository layout

- `Content/`: map and assets
- `Resources/`: project resources (icon)
