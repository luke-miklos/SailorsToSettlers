using { /Fortnite.com/Devices }
using { /Fortnite.com/Vehicles }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# P1 prototype (throwaway): can a player sail a boat and be detected as "docked"
# the moment it touches land? Place one boat spawner on water, assign it below,
# then board the boat and sail onto a beach. Watch the Verse output log.
boat_dock_prototype := class(creative_device):

    @editable
    BoatSpawner : vehicle_spawner_boat_device = vehicle_spawner_boat_device{}

    # How often to check whether the boat has reached land.
    @editable
    CheckIntervalSeconds : float = 0.25

    OnBegin<override>()<suspends>:void =
        BoatSpawner.SpawnedEvent.Subscribe(OnBoatSpawned)
        Print("P1: waiting for the boat to spawn")

    OnBoatSpawned(Vehicle:fort_vehicle):void =
        spawn:
            WatchForDock(Vehicle)
        spawn:
            SeatFirstPlayer()

    # Put the first player in the driver's seat, so nobody has to swim out.
    SeatFirstPlayer()<suspends>:void =
        # Wait up to 30 seconds for a player to exist and have a character.
        for (I := 0..120):
            Players := GetPlayspace().GetPlayers()
            if (Player := Players[0], Player.IsActive[]):
                Sleep(1.0)
                BoatSpawner.AssignDriver(Player)
                Print("P1: seated first player in the boat")
                return
            Sleep(0.25)
        Print("P1: no player found to seat")

    # Waits for a player to board, then polls until the boat is on land.
    WatchForDock(Vehicle:fort_vehicle)<suspends>:void =
        Print("P1: boat spawned, waiting for a player to board")
        loop:
            Sleep(CheckIntervalSeconds)
            if (Vehicle.GetOccupants().Length > 0):
                break
        Print("P1: boat boarded, sailing")
        loop:
            Sleep(CheckIntervalSeconds)
            if (Vehicle.IsOnGround[]):
                Print("P1: DOCKED (boat touched land), speed={Vehicle.Speed}")
                break
            else if (Vehicle.GetOccupants().Length = 0):
                Print("P1: boat abandoned before docking")
                break
