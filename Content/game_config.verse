# game_config: every tunable number for SailorsToSettlers lives here.
# Change numbers here, not in gameplay code, so playtests only touch data.
# Values are the starting points agreed in README.md.

game_config<public> := module:

    # --- Rounds and phases ---
    TotalRounds<public>:int = 10
    DockingDeadlineSeconds<public>:float = 120.0
    PrepareSeconds<public>:float = 120.0
    DefendSeconds<public>:float = 120.0
    FinalDefendSeconds<public>:float = 240.0
    # Short pause after each defend phase before the next prepare phase.
    ResultSeconds<public>:float = 5.0
    # How long the win or lose screen shows before the game ends.
    EndScreenSeconds<public>:float = 10.0

    # --- Wood economy ---
    BaseWoodPerMinute<public>:float = 30.0
    # Wood cost of each weapon tier (index 0 = tier 1). Roughly doubles each tier;
    # reaching tier 5 costs 500 wood in total (tier 5 rounded up from 256 to hit 500).
    WeaponTierCosts<public>:[]int = array{16, 32, 64, 128, 260}
    # Tier 3 and above are ranged weapons and can damage the boss ship.
    FirstRangedWeaponTier<public>:int = 3

    # --- Harvesting and landing bonus ---
    # Units gained per completed gather (the button hold time sets the pace).
    HarvestYield<public>:int = 1
    # A landing bonus adds one extra unit every Nth gather of that job (2 = 1.5x).
    LandingBonusEveryNth<public>:int = 2

    # --- AI budget (from the P2 crowd-load test, see PLAN.md) ---
    # UEFN allows at most 90 active AI on an island (guards, creatures, wildlife, tamed pets).
    # Plan for about 50 alive at once; recheck with 12 players in M8.
    IslandAILimit<public>:int = 90
    TargetMaxAliveAI<public>:int = 50
    NpcCount<public>:int = 8
    # Hard cap on the crew's total pets, because every pet takes an AI slot.
    MaxCrewPets<public>:int = 12
    # Pirates alive at once = TargetMaxAliveAI - NpcCount - MaxCrewPets.
    MaxAlivePirates<public>:int = 30

    # --- Communal fire ---
    FireMaxHeat<public>:float = 100.0
    FireStartHeat<public>:float = 50.0
    # One feed spends this much crew wood and adds this much heat.
    FireWoodPerFeed<public>:int = 5
    FireHeatPerFeed<public>:float = 10.0
    # Heat lost per second during Prepare and Defend (0.15 is about 36 per 4-minute round).
    FireCoolPerSecond<public>:float = 0.15
    # At each round start: the dead revive if heat is at least this...
    FireReviveHeat<public>:float = 50.0
    # ...and the crew has nightmares (lower max health) if heat is below this.
    FireNightmareBelowHeat<public>:float = 25.0
    NormalMaxHealth<public>:float = 100.0
    NightmareMaxHealth<public>:float = 70.0

    # --- Pirate waves ---
    # Pirates per defend phase = base + per player (who joined) + per round after the first,
    # capped at MaxAlivePirates.
    PirateBase<public>:int = 2
    PiratesPerPlayer<public>:int = 1
    PiratesPerRound<public>:int = 1
    # Seconds between pirate spawns while a wave lands.
    PirateSpawnIntervalSeconds<public>:float = 0.5

    # --- Pirate boss ---
    BossTargetToggleSeconds<public>:float = 15.0
