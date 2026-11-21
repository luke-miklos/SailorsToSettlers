# resource_stockpile: the crew's one shared stockpile of water, wood, food and pets.
# Only game_manager owns an instance. Every other system asks it to add or spend,
# so there is one authority and no counting conflicts between systems.

resource_kind<public> := enum:
    Water
    Wood
    Food
    Pets

resource_stockpile<public> := class:
    var Water : int = 0
    var Wood : int = 0
    var Food : int = 0
    var Pets : int = 0

    # Signaled after any change, for the HUD and for systems that react to levels.
    ChangedEvent<public> : event() = event(){}

    Get<public>(Kind:resource_kind)<transacts>:int =
        case (Kind):
            resource_kind.Water => Water
            resource_kind.Wood => Wood
            resource_kind.Food => Food
            resource_kind.Pets => Pets

    # Adds Amount (can be negative). Never goes below 0, and pets never exceed the crew cap.
    Add<public>(Kind:resource_kind, Amount:int):void =
        var NewValue : int = Get(Kind) + Amount
        if (NewValue < 0):
            set NewValue = 0
        if (Kind = resource_kind.Pets, NewValue > game_config.MaxCrewPets):
            set NewValue = game_config.MaxCrewPets
        SetValue(Kind, NewValue)
        ChangedEvent.Signal()

    # Spends Amount if the stockpile has enough. Returns false and changes nothing otherwise.
    TrySpend<public>(Kind:resource_kind, Amount:int):logic =
        if (Get(Kind) >= Amount):
            Add(Kind, -Amount)
            true
        else:
            false

    Summary<public>()<transacts>:string =
        "Water {Water}   Wood {Wood}   Food {Food}   Pets {Pets}/{game_config.MaxCrewPets}"

    SetValue(Kind:resource_kind, Value:int)<transacts>:void =
        case (Kind):
            resource_kind.Water => set Water = Value
            resource_kind.Wood => set Wood = Value
            resource_kind.Food => set Food = Value
            resource_kind.Pets => set Pets = Value
