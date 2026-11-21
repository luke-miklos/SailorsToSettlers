# communal_fire: the crew's one fire. Wood raises its heat, and heat slowly drops while
# the round runs. At each round start, its heat decides whether last round's dead are
# revived and whether the crew has nightmares. Owned by game_manager.
communal_fire<public> := class:
    var Heat : float = game_config.FireStartHeat

    GetHeat<public>()<transacts>:float = Heat

    # Adds one feed's worth of heat, up to the maximum.
    AddFeed<public>():void =
        set Heat = Min(Heat + game_config.FireHeatPerFeed, game_config.FireMaxHeat)

    Cool<public>(Seconds:float):void =
        set Heat = Max(Heat - game_config.FireCoolPerSecond * Seconds, 0.0)

    IsFull<public>()<transacts><decides>:void = Heat >= game_config.FireMaxHeat

    CanRevive<public>()<transacts><decides>:void = Heat >= game_config.FireReviveHeat

    CausesNightmares<public>()<transacts><decides>:void = Heat < game_config.FireNightmareBelowHeat

    Summary<public>()<transacts>:string =
        var Whole : int = 0
        if (H := Int[Heat]):
            set Whole = H
        Status := if (CausesNightmares[]) then "nightmares!" else if (CanRevive[]) then "warm, revives the fallen" else "too cold to revive"
        "Fire heat {Whole} ({Status})"
