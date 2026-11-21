using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/UI }
using { /Fortnite.com/Game }
using { /Fortnite.com/FortPlayerUtilities }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }

# The game's phases, in order: Intro, then Prepare / Defend / Result for each round,
# then Victory. GameOver can happen from any timed phase.
game_phase<public> := enum:
    Intro
    Prepare
    Defend
    Result
    GameOver
    Victory

PhaseTitle(Phase:game_phase)<computes>:string =
    case (Phase):
        game_phase.Intro => "SAIL TO THE ISLAND"
        game_phase.Prepare => "PREPARE"
        game_phase.Defend => "DEFEND"
        game_phase.Result => "ROUND SURVIVED"
        game_phase.GameOver => "GAME OVER"
        game_phase.Victory => "VICTORY"

HudMessage<localizes>(Text:string):message = "{Text}"

# The one authority for game flow: phases, round counter, timers, who is dead,
# and the shared stockpile. Other systems read state from here and send requests here.
game_manager := class(creative_device):

    @editable
    Fleet : boat_fleet = boat_fleet{}

    # Where players who haven't docked by the deadline are placed, and where the dead revive.
    @editable
    LandingSpot : teleporter_device = teleporter_device{}

    # Ends the match after the win or lose screen.
    @editable
    EndGame : end_game_device = end_game_device{}

    # The four coastal zones. Docking inside one gives that job's landing bonus.
    @editable
    WaterZone : landing_zone = landing_zone{}
    @editable
    WoodZone : landing_zone = landing_zone{}
    @editable
    FoodZone : landing_zone = landing_zone{}
    @editable
    PetsZone : landing_zone = landing_zone{}

    # Pirates land from these two shore spawners during each defend phase.
    @editable
    PirateSpawnerA : guard_spawner_device = guard_spawner_device{}
    @editable
    PirateSpawnerB : guard_spawner_device = guard_spawner_device{}

    # Holds the 5 weapon tiers as items 0 to 4 (tier 1 to tier 5).
    @editable
    WeaponGranter : item_granter_device = item_granter_device{}

    # The visible fire at the camp. Lit while the fire has any heat, out at zero.
    @editable
    CampfireVisual : campfire_device = campfire_device{}

    # --- Test settings (leave at defaults for real play) ---
    # Multiplies every phase length. 0.1 runs a whole game in a few minutes.
    @editable
    TimeScale : float = 1.0
    # Adds fake resources during Prepare so the HUD and stockpile can be tested.
    @editable
    FakeHarvest : logic = false
    # When above 0, every player counts as dead 2 seconds into that round's defend phase.
    @editable
    SimulateWipeAtRound : int = 0

    Stockpile<public> : resource_stockpile = resource_stockpile{}
    Fire<public> : communal_fire = communal_fire{}

    var Phase : game_phase = game_phase.Intro
    var CurrentRound : int = 0
    var SecondsLeft : float = 0.0
    var Dead : [player]logic = map{}
    var Hud : [player]text_block = map{}
    var EliminationSubs : [player]cancelable = map{}
    var LandingBonus : [player]resource_kind = map{}
    var BonusGatherCount : [player]int = map{}
    var WeaponTier : [player]int = map{}
    var PlayersAtStart : int = 0
    var PiratesAlive : int = 0
    var PiratesLanded : int = 0
    var Nightmares : logic = false
    var FireShownLit : logic = true

    AllDeadEvent : event() = event(){}

    GetPhase<public>()<transacts>:game_phase = Phase
    GetRound<public>()<transacts>:int = CurrentRound
    IsDead<public>(Player:player)<transacts><decides>:void = Dead[Player]?

    OnBegin<override>()<suspends>:void =
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
        for (Player : GetPlayspace().GetPlayers()):
            OnPlayerAdded(Player)
        Stockpile.ChangedEvent.Subscribe(UpdateHud)
        PirateSpawnerA.SpawnedEvent.Subscribe(OnPirateSpawned)
        PirateSpawnerB.SpawnedEvent.Subscribe(OnPirateSpawned)
        PirateSpawnerA.EliminatedEvent.Subscribe(OnPirateEliminated)
        PirateSpawnerB.EliminatedEvent.Subscribe(OnPirateEliminated)
        PirateSpawnerA.Disable()
        PirateSpawnerB.Disable()

        RunIntro()
        AssignLandingBonuses()
        set PlayersAtStart = GetPlayspace().GetPlayers().Length

        for (R := 1..game_config.TotalRounds):
            set CurrentRound = R
            StartOfRound()
            Prepared := RunTimedPhase(game_phase.Prepare, game_config.PrepareSeconds)
            if (not Prepared?):
                return EndMatch(game_phase.GameOver)
            if (R = SimulateWipeAtRound):
                spawn{ SimulateWipe() }
            DefendSeconds := if (R = game_config.TotalRounds) then game_config.FinalDefendSeconds else game_config.DefendSeconds
            # The defend phase ends when its timer runs out, when every pirate is
            # dead (early win), or when every player is dead (RunTimedPhase gives false).
            Defended := race:
                RunTimedPhase(game_phase.Defend, DefendSeconds)
                block:
                    LandAndDefeatPirates()
                    true
            ClearPirates()
            if (not Defended?):
                return EndMatch(game_phase.GameOver)
            if (R < game_config.TotalRounds):
                Rested := RunTimedPhase(game_phase.Result, game_config.ResultSeconds)
                if (not Rested?):
                    return EndMatch(game_phase.GameOver)

        EndMatch(game_phase.Victory)

    # --- Phases ---

    # Waits until every player has docked, or the docking deadline passes, then places
    # anyone still at sea on the landing spot.
    RunIntro()<suspends>:void =
        EnterPhase(game_phase.Intro, game_config.DockingDeadlineSeconds)
        loop:
            UpdateHud()
            if (AllDocked[]):
                Log("all players docked")
                break
            if (SecondsLeft <= 0.0):
                for (Player : GetPlayspace().GetPlayers(), not Fleet.IsDocked[Player]):
                    Log("docking deadline: placing a player at the landing spot")
                    LandingSpot.Teleport(Player)
                    Fleet.MarkDocked(Player)
                break
            Sleep(0.5)
            set SecondsLeft -= 0.5

    # Counts down one phase. Returns false if every player died during it (instant game over).
    RunTimedPhase(NewPhase:game_phase, BaseSeconds:float)<suspends>:logic =
        EnterPhase(NewPhase, BaseSeconds)
        race:
            block:
                CountDown()
                true
            block:
                AllDeadEvent.Await()
                false

    CountDown()<suspends>:void =
        var Tick : int = 0
        loop:
            UpdateHud()
            if (SecondsLeft <= 0.0):
                break
            Sleep(1.0)
            set SecondsLeft -= 1.0
            set Tick += 1
            if (Phase = game_phase.Prepare or Phase = game_phase.Defend):
                Fire.Cool(1.0)
                ShowFire()
            if (FakeHarvest?, Phase = game_phase.Prepare):
                AddFakeResources(Tick)

    EnterPhase(NewPhase:game_phase, BaseSeconds:float):void =
        set Phase = NewPhase
        set SecondsLeft = BaseSeconds * TimeScale
        Log("phase {PhaseTitle(NewPhase)}, round {CurrentRound}, {SecondsLeft}s")
        UpdateHud()

    EndMatch(Final:game_phase)<suspends>:void =
        set Phase = Final
        set SecondsLeft = 0.0
        Log("match over: {PhaseTitle(Final)} at round {CurrentRound}")
        UpdateHud()
        Sleep(game_config.EndScreenSeconds)
        if (First := GetPlayspace().GetPlayers()[0]):
            EndGame.Activate(First)

    # --- Players, death and revive ---

    OnPlayerAdded(Player:player):void =
        spawn{ SetUpPlayer(Player) }

    # Waits for the player's character, then watches it for elimination and builds their HUD.
    SetUpPlayer(Player:player)<suspends>:void =
        loop:
            if (Player.GetFortCharacter[]):
                break
            Sleep(0.25)
        WatchCharacter(Player)
        CreateHud(Player)

    WatchCharacter(Player:player):void =
        if (Old := EliminationSubs[Player]):
            Old.Cancel()
        if (Character := Player.GetFortCharacter[]):
            Sub := Character.EliminatedEvent().Subscribe(OnEliminated)
            if (set EliminationSubs[Player] = Sub) {}

    OnPlayerRemoved(Player:player):void =
        if (Old := EliminationSubs[Player]):
            Old.Cancel()
        var NewDead : [player]logic = map{}
        for (P -> IsPlayerDead : Dead, P <> Player):
            if (set NewDead[P] = IsPlayerDead) {}
        set Dead = NewDead
        CheckAllDead()

    OnEliminated(Result:elimination_result):void =
        if (Agent := Result.EliminatedCharacter.GetAgent[], Player := player[Agent]):
            Log("a player was eliminated in {PhaseTitle(Phase)}, round {CurrentRound}")
            MarkDead(Player)

    MarkDead(Player:player):void =
        if (set Dead[Player] = true) {}
        UpdateHud()
        CheckAllDead()

    # The crew loses the moment every player is dead at the same time.
    CheckAllDead():void =
        Players := GetPlayspace().GetPlayers()
        if (Players.Length = 0):
            return
        for (Player : Players, not IsDead[Player]):
            return
        # Note: with Spawn Limit 1, Fortnite itself ends the match when the last player
        # is eliminated, so the end screen may be cut short. Accepted for now.
        Log("every player is dead")
        AllDeadEvent.Signal()

    # The fire decides the start of each round: a warm fire revives last round's dead,
    # and a cold one gives the crew nightmares (lower max health) for this round.
    StartOfRound():void =
        if (Fire.CanRevive[]):
            ReviveDead()
        else if (CurrentRound > 1):
            Log("fire too cold to revive the fallen")
        set Nightmares = if (CurrentRound > 1, Fire.CausesNightmares[]) then true else false
        if (Nightmares?):
            Log("the fire is too low: nightmares this round")
        ApplyMaxHealth()
        # Revived characters take a moment to exist again, so apply once more shortly after.
        spawn{ ApplyMaxHealthSoon() }

    ApplyMaxHealthSoon()<suspends>:void =
        Sleep(1.5)
        ApplyMaxHealth()

    ApplyMaxHealth():void =
        MaxHealth := if (Nightmares?) then game_config.NightmareMaxHealth else game_config.NormalMaxHealth
        for (Player : GetPlayspace().GetPlayers(), not IsDead[Player], Character := Player.GetFortCharacter[]):
            Character.SetMaxHealth(MaxHealth)
            if (Character.GetHealth() > MaxHealth):
                Character.SetHealth(MaxHealth)
        UpdateHud()

    # Brings back everyone who died last round, at the landing spot.
    ReviveDead():void =
        Spot := LandingSpot.GetTransform()
        for (Player -> IsPlayerDead : Dead, IsPlayerDead?):
            if (Character := Player.GetFortCharacter[], Character.IsActive[]):
                # Still alive (a simulated death): nothing to respawn.
                Log("revive: player was only marked dead")
            else:
                Log("revive: respawning a player at the landing spot")
                Player.Respawn(Spot.Translation, Spot.Rotation)
                spawn{ RewatchAfterRespawn(Player) }
        set Dead = map{}
        UpdateHud()

    RewatchAfterRespawn(Player:player)<suspends>:void =
        Sleep(1.0)
        WatchCharacter(Player)

    SimulateWipe()<suspends>:void =
        Sleep(2.0)
        Log("test: simulating a full crew wipe")
        for (Player : GetPlayspace().GetPlayers()):
            if (set Dead[Player] = true) {}
        UpdateHud()
        CheckAllDead()

    AllDocked()<transacts><decides>:void =
        Players := GetPlayspace().GetPlayers()
        Players.Length > 0
        for (Player : Players):
            Fleet.IsDocked[Player]

    # --- Landing bonus and harvesting ---

    # Gives each player the job of the zone their boat docked in. Players placed ashore
    # by the deadline, or who docked outside every zone, get no bonus.
    AssignLandingBonuses():void =
        for (Player : GetPlayspace().GetPlayers()):
            if (Position := Fleet.GetDockPosition[Player]):
                if (Zone := ZoneAt[Position], set LandingBonus[Player] = Zone.GetKind()):
                    Log("landing bonus: {KindName(Zone.GetKind())} (docked at {Position.X}, {Position.Y})")
                else:
                    Log("landing bonus: none (docked outside every zone at {Position.X}, {Position.Y})")
            else:
                Log("landing bonus: none (placed ashore by the deadline)")
        UpdateHud()

    ZoneAt(Position:vector3)<transacts><decides>:landing_zone =
        var Found : ?landing_zone = false
        for (Zone : array{WaterZone, WoodZone, FoodZone, PetsZone}, not Found?, Zone.Contains[Position]):
            set Found = option{Zone}
        Found?

    # Called by harvest nodes. Gathering only counts during Prepare and for living players.
    # Returns how many units were added to the stockpile (0 if the gather didn't count).
    Harvest<public>(Agent:agent, Kind:resource_kind):int =
        if (Player := player[Agent], Phase = game_phase.Prepare, not IsDead[Player]):
            var Amount : int = game_config.HarvestYield
            if (LandingBonus[Player] = Kind):
                var Count : int = 0
                if (Previous := BonusGatherCount[Player]):
                    set Count = Previous
                set Count += 1
                if (set BonusGatherCount[Player] = Count) {}
                if (Mod[Count, game_config.LandingBonusEveryNth] = 0):
                    set Amount += 1
            Stockpile.Add(Kind, Amount)
            Log("harvest: +{Amount} {KindName(Kind)}, stockpile now {Stockpile.Get(Kind)}")
            Amount
        else:
            Log("harvest: {KindName(Kind)} ignored in {PhaseTitle(Phase)}")
            0

    KindName(Kind:resource_kind)<computes>:string =
        case (Kind):
            resource_kind.Water => "Water"
            resource_kind.Wood => "Wood"
            resource_kind.Food => "Food"
            resource_kind.Pets => "Pets"

    # --- Fire and weapons (called by camp stations) ---

    FeedFire<public>(Agent:agent):void =
        if (not player[Agent]):
            return
        if (Fire.IsFull[]):
            Log("fire: already at full heat")
            return
        Paid := Stockpile.TrySpend(resource_kind.Wood, game_config.FireWoodPerFeed)
        if (Paid?):
            Fire.AddFeed()
            ShowFire()
            Log("fire: fed, {Fire.Summary()}")
            UpdateHud()
        else:
            Log("fire: not enough wood to feed")

    # Keeps the visible campfire in step with the heat (only calls the device on a change).
    ShowFire():void =
        ShouldBeLit := if (Fire.GetHeat() > 0.0) then true else false
        # The device needs an agent for lighting; any player will do.
        if (ShouldBeLit <> FireShownLit, Someone := GetPlayspace().GetPlayers()[0]):
            if (ShouldBeLit?) then CampfireVisual.Light(Someone) else CampfireVisual.Extinguish(Someone)
            set FireShownLit = ShouldBeLit

    # Spends the crew's wood on the next weapon tier for this player.
    UpgradeWeapon<public>(Agent:agent):void =
        if (Player := player[Agent], not IsDead[Player]):
            Current := CurrentTier(Player)
            if (Cost := game_config.WeaponTierCosts[Current]):
                Paid := Stockpile.TrySpend(resource_kind.Wood, Cost)
                if (Paid?):
                    WeaponGranter.GrantItemIndex(Agent, Current)
                    if (set WeaponTier[Player] = Current + 1) {}
                    Log("weapons: a player upgraded to tier {Current + 1} for {Cost} wood")
                    UpdateHud()
                else:
                    Log("weapons: tier {Current + 1} needs {Cost} wood")
            else:
                Log("weapons: already at the top tier")

    # Tiers already owned (0 = none yet, 5 = top).
    CurrentTier(Player:player)<transacts>:int =
        if (Tier := WeaponTier[Player]) then Tier else 0

    WeaponLine(Player:player)<transacts>:string =
        Tier := CurrentTier(Player)
        if (Cost := game_config.WeaponTierCosts[Tier]):
            "Weapon tier {Tier}   Next tier: {Cost} wood"
        else:
            "Weapon tier {Tier} (top tier)"

    # --- Pirates ---

    PiratesThisRound()<transacts>:int =
        Wanted := game_config.PirateBase + game_config.PiratesPerPlayer * PlayersAtStart + game_config.PiratesPerRound * (CurrentRound - 1)
        Min(Wanted, game_config.MaxAlivePirates)

    # Lands Count pirates, alternating between the two shore spawners. Enabling a
    # spawner lands one pirate by itself, so this counts real spawns (PiratesLanded)
    # and only calls Spawn() until Count have landed.
    LandPirates(Count:int)<suspends>:void =
        Log("pirates: {Count} landing in round {CurrentRound}")
        set PiratesLanded = 0
        PirateSpawnerA.Enable()
        PirateSpawnerB.Enable()
        var Index : int = 0
        loop:
            Sleep(game_config.PirateSpawnIntervalSeconds)
            if (PiratesLanded >= Count):
                break
            if (Mod[Index, 2] = 0) then PirateSpawnerA.Spawn() else PirateSpawnerB.Spawn()
            set Index += 1

    # Lands this round's pirates, then returns once every one of them is dead.
    LandAndDefeatPirates()<suspends>:void =
        LandPirates(PiratesThisRound())
        loop:
            if (PiratesAlive <= 0):
                Log("pirates: all {PiratesLanded} defeated, defend phase ends early")
                break
            Sleep(0.5)

    # Removes every pirate still alive when the defend phase ends.
    ClearPirates():void =
        PirateSpawnerA.Disable()
        PirateSpawnerB.Disable()
        if (PiratesAlive > 0):
            Log("pirates: {PiratesAlive} left at the end of the phase, removed")
        set PiratesAlive = 0
        UpdateHud()

    OnPirateSpawned(Agent:agent):void =
        set PiratesAlive += 1
        set PiratesLanded += 1
        UpdateHud()

    OnPirateEliminated(Result:device_ai_interaction_result):void =
        if (PiratesAlive > 0):
            set PiratesAlive -= 1
        UpdateHud()

    # --- Test data ---

    AddFakeResources(Tick:int):void =
        Alive := AliveCount()
        # About 30 wood per minute per living player, like the real harvest target.
        if (Mod[Tick, 2] = 0):
            Stockpile.Add(resource_kind.Wood, Alive)
        if (Mod[Tick, 5] = 0):
            Stockpile.Add(resource_kind.Water, 1)
            Stockpile.Add(resource_kind.Food, 1)
        if (Mod[Tick, 15] = 0):
            Stockpile.Add(resource_kind.Pets, 1)

    AliveCount()<transacts>:int =
        var Count : int = 0
        for (Player : GetPlayspace().GetPlayers(), not IsDead[Player]):
            set Count += 1
        Count

    # --- HUD ---

    CreateHud(Player:player):void =
        if (PlayerUI := GetPlayerUI[Player]):
            Text := text_block{DefaultText := HudMessage("")}
            Root := canvas:
                Slots := array:
                    canvas_slot:
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.0}, Maximum := vector2{X := 0.5, Y := 0.0}}
                        Offsets := margin{Top := 80.0}
                        Alignment := vector2{X := 0.5, Y := 0.0}
                        SizeToContent := true
                        Widget := Text
            PlayerUI.AddWidget(Root)
            if (set Hud[Player] = Text) {}
            UpdateHud()

    UpdateHud():void =
        Header := HeaderLine()
        Resources := Stockpile.Summary()
        FireLine := Fire.Summary()
        var PirateLine : string = ""
        if (Phase = game_phase.Prepare):
            set PirateLine = "\nIncoming this round: {PiratesThisRound()} pirates"
        else if (Phase = game_phase.Defend):
            set PirateLine = "\nPirates ashore: {PiratesAlive}"
        for (Player -> Text : Hud):
            var Lines : string = "{Header}\n{Resources}\n{FireLine}{PirateLine}\n{WeaponLine(Player)}"
            if (Bonus := LandingBonus[Player]):
                set Lines += "\nLanding bonus: {KindName(Bonus)} gathering x1.5"
            if (Nightmares?):
                set Lines += "\nNightmares: the fire burned low (max health {Int[game_config.NightmareMaxHealth] or 70})"
            if (IsDead[Player]):
                set Lines += "\nYou are down. You revive next round if the fire is warm."
            Text.SetText(HudMessage(Lines))

    HeaderLine()<transacts>:string =
        case (Phase):
            game_phase.Intro => "{PhaseTitle(Phase)}   Dock in {Clock()}"
            game_phase.GameOver => "GAME OVER   The crew fell in round {CurrentRound}"
            game_phase.Victory => "VICTORY   The settlement survived all {game_config.TotalRounds} rounds"
            _ => "ROUND {CurrentRound}/{game_config.TotalRounds}   {PhaseTitle(Phase)}   {Clock()}"

    Clock()<transacts>:string =
        var Total : int = 0
        if (Whole := Int[SecondsLeft + 0.999]):
            set Total = Whole
        if (Total < 0):
            set Total = 0
        var Minutes : int = 0
        var Seconds : int = Total
        if (M := Floor[(Total * 1.0) / 60.0], S := Mod[Total, 60]):
            set Minutes = M
            set Seconds = S
        if (Seconds < 10) then "{Minutes}:0{Seconds}" else "{Minutes}:{Seconds}"

    Log(Text:string):void =
        Print("game_manager: {Text}")
