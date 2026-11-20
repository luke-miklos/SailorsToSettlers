# game_config: every tunable number for SailorsToSettlers lives here.
# Change numbers here, not in gameplay code, so playtests only touch data.
# Values are the starting points agreed in README.md.

game_config<public> := module:

    # --- Rounds and phases ---
    TotalRounds<public>:int = 10
    DockingDeadlineSeconds<public>:float = 60.0
    PrepareSeconds<public>:float = 60.0
    DefendSeconds<public>:float = 60.0
    FinalDefendSeconds<public>:float = 180.0

    # --- Wood economy ---
    BaseWoodPerMinute<public>:float = 30.0
    # Wood cost of each weapon tier (index 0 = tier 1). Doubles each tier.
    WeaponTierCosts<public>:[]int = array{10, 20, 40, 80, 160}
    # Tier 3 and above are ranged weapons and can damage the boss ship.
    FirstRangedWeaponTier<public>:int = 3

    # --- Pirate boss ---
    BossTargetToggleSeconds<public>:float = 15.0
