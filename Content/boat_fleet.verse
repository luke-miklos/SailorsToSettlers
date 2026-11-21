using { /Fortnite.com/Devices }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Gives every player their own boat at sea and reports when each one docks.
# Player N (in join order) gets Boats[N]. Boats nobody uses stay disabled, so a
# 2-player game only has 2 boats in the water.
# Prototype P1, grown into the start of the real boat_system.
boat_fleet := class(creative_device):

    # One boat spawner per possible player (12). Boat1 goes to the first player to join.
    # Separate fields, because the editor can't wire references inside an array.
    @editable
    Boat1 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat2 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat3 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat4 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat5 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat6 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat7 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat8 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat9 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat10 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat11 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    @editable
    Boat12 : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    # How often to check whether a boat has reached land.
    @editable
    CheckIntervalSeconds : float = 0.25

    # Signaled once per player, the moment their boat touches land.
    PlayerDockedEvent<public> : event(player) = event(player){}

    var UsedBoats : [int]logic = map{}
    var Docked : [player]logic = map{}

    # Succeeds if this player's boat has touched land (or they were placed ashore).
    IsDocked<public>(Player:player)<transacts><decides>:void =
        Docked[Player]?

    # For players placed ashore by the docking deadline: counts them as docked
    # and stops watching their boat.
    MarkDocked<public>(Player:player):void =
        if (set Docked[Player] = true) {}

    GetBoats()<transacts>:[]vehicle_spawner_boat_device =
        array{Boat1, Boat2, Boat3, Boat4, Boat5, Boat6, Boat7, Boat8, Boat9, Boat10, Boat11, Boat12}

    OnBegin<override>()<suspends>:void =
        Print("boat_fleet: started, {GetPlayspace().GetPlayers().Length} player(s) present")
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        for (Player : GetPlayspace().GetPlayers()):
            OnPlayerAdded(Player)
        # Once players have been assigned, remove the boats nobody is using.
        Sleep(5.0)
        var Index : int = 0
        for (Boat : GetBoats()):
            if (not UsedBoats[Index]?):
                Boat.DestroyVehicle()
            set Index += 1

    OnPlayerAdded(Player:player):void =
        spawn:
            AssignNearestBoat(Player)

    # The island picks a random spawn pad (one above each boat), so wait until the player
    # has appeared and give them the free boat nearest to where they are.
    AssignNearestBoat(Player:player)<suspends>:void =
        loop:
            if (Player.IsActive[], Player.GetFortCharacter[]):
                break
            Sleep(0.25)
        if (Character := Player.GetFortCharacter[]):
            Start := Character.GetTransform().Translation
            var BestIndex : int = -1
            var BestDistance : float = 0.0
            var Index : int = 0
            for (Boat : GetBoats()):
                if (not UsedBoats[Index]?):
                    BoatPosition := Boat.GetTransform().Translation
                    DX := BoatPosition.X - Start.X
                    DY := BoatPosition.Y - Start.Y
                    Distance := DX * DX + DY * DY
                    if (BestIndex < 0 or Distance < BestDistance):
                        set BestIndex = Index
                        set BestDistance = Distance
                set Index += 1
            if (Boat := GetBoats()[BestIndex], set UsedBoats[BestIndex] = true):
                Print("boat_fleet: player appeared at ({Start.X}, {Start.Y}), assigning nearest boat {BestIndex}")
                SailAndDock(Player, Boat, BestIndex)
            else:
                Print("boat_fleet: no free boat for a new player")

    SailAndDock(Player:player, Boat:vehicle_spawner_boat_device, Index:int)<suspends>:void =
        Boat.Enable()
        Sleep(1.0)
        if (not Boat.Vehicle?):
            Boat.RespawnVehicle()
        Vehicle := WaitForVehicle(Boat, Index)
        Boat.AssignDriver(Player)
        Print("boat_fleet: player seated in boat {Index}")
        loop:
            Sleep(CheckIntervalSeconds)
            if (IsDocked[Player]):
                break
            if (Vehicle.IsOnGround[], Vehicle.GetOccupants().Length > 0):
                MarkDocked(Player)
                Position := Vehicle.GetTransform().Translation
                Print("boat_fleet: boat {Index} DOCKED at ({Position.X}, {Position.Y}, {Position.Z})")
                PlayerDockedEvent.Signal(Player)
                break

    WaitForVehicle(Boat:vehicle_spawner_boat_device, Index:int)<suspends>:fort_vehicle =
        var Waited : float = 0.0
        loop:
            if (V := Boat.Vehicle?):
                Print("boat_fleet: boat {Index} is ready")
                return V
            Sleep(0.25)
            set Waited += 0.25
            if (Waited = 5.0):
                Print("boat_fleet: boat {Index} has no vehicle after 5s, respawning")
                Boat.RespawnVehicle()
