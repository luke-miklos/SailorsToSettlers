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
    # Wood cost of each weapon tier (index 0 = tier 1). Doubles each tier.
    WeaponTierCosts<public>:[]int = array{10, 20, 40, 80, 160}
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

    # --- Pirate boss ---
    BossTargetToggleSeconds<public>:float = 15.0
