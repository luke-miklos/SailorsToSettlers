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

    var Phase : game_phase = game_phase.Intro
    var CurrentRound : int = 0
    var SecondsLeft : float = 0.0
    var Dead : [player]logic = map{}
    var Hud : [player]text_block = map{}
    var EliminationSubs : [player]cancelable = map{}

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

        RunIntro()

        for (R := 1..game_config.TotalRounds):
            set CurrentRound = R
            ReviveDead()
            Prepared := RunTimedPhase(game_phase.Prepare, game_config.PrepareSeconds)
            if (not Prepared?):
                return EndMatch(game_phase.GameOver)
            if (R = SimulateWipeAtRound):
                spawn{ SimulateWipe() }
            DefendSeconds := if (R = game_config.TotalRounds) then game_config.FinalDefendSeconds else game_config.DefendSeconds
            Defended := RunTimedPhase(game_phase.Defend, DefendSeconds)
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

    # Brings back everyone who died last round, at the landing spot.
    # M4 will make this depend on the fire's heat; for now everyone revives.
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
        for (Player -> Text : Hud):
            var Lines : string = "{Header}\n{Resources}"
            if (IsDead[Player]):
                set Lines += "\nYou are down. Spectating until next round."
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
