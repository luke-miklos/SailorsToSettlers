using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Prototype P2 (throwaway): crowd load.
# Keeps a fixed number of NPC stand-ins and pets alive, then raises the number of
# live pirates step by step. Each step prints a "P2 STEP" line with the live counts
# and the time, so profiler samples can be matched to a crowd size afterwards.
# Spawners top up anything that dies, so the counts stay at the target.
crowd_load_test := class(creative_device):

    # Stand-ins for the 8 island NPCs (guard spawners on the players' team).
    @editable
    NpcSpawnerA : guard_spawner_device = guard_spawner_device{}
    @editable
    NpcSpawnerB : guard_spawner_device = guard_spawner_device{}

    # Stand-ins for pets (wildlife spawners).
    @editable
    PetSpawnerA : wildlife_spawner_device = wildlife_spawner_device{}
    @editable
    PetSpawnerB : wildlife_spawner_device = wildlife_spawner_device{}

    # Pirates (hostile guard spawners near the shore).
    @editable
    PirateSpawnerA : guard_spawner_device = guard_spawner_device{}
    @editable
    PirateSpawnerB : guard_spawner_device = guard_spawner_device{}

    @editable
    NpcTarget : int = 8
    @editable
    PetTarget : int = 12

    # Pirate ramp: start at PirateStart, add PirateStep every StepSeconds, stop at PirateMax.
    @editable
    PirateStart : int = 0
    @editable
    PirateStep : int = 5
    @editable
    PirateMax : int = 60
    @editable
    StepSeconds : float = 30.0

    # Wait this long after the game starts before spawning, so players are seated first.
    @editable
    StartDelaySeconds : float = 10.0

    var NpcAlive : int = 0
    var PetAlive : int = 0
    var PirateAlive : int = 0
    var PirateTarget : int = 0
    var Elapsed : float = 0.0

    OnBegin<override>()<suspends>:void =
        NpcSpawnerA.SpawnedEvent.Subscribe(OnNpcSpawned)
        NpcSpawnerB.SpawnedEvent.Subscribe(OnNpcSpawned)
        NpcSpawnerA.EliminatedEvent.Subscribe(OnNpcEliminated)
        NpcSpawnerB.EliminatedEvent.Subscribe(OnNpcEliminated)
        PetSpawnerA.SpawnedEvent.Subscribe(OnPetSpawned)
        PetSpawnerB.SpawnedEvent.Subscribe(OnPetSpawned)
        PetSpawnerA.EliminatedEvent.Subscribe(OnPetEliminated)
        PetSpawnerB.EliminatedEvent.Subscribe(OnPetEliminated)
        PirateSpawnerA.SpawnedEvent.Subscribe(OnPirateSpawned)
        PirateSpawnerB.SpawnedEvent.Subscribe(OnPirateSpawned)
        PirateSpawnerA.EliminatedEvent.Subscribe(OnPirateEliminated)
        PirateSpawnerB.EliminatedEvent.Subscribe(OnPirateEliminated)

        Print("P2: waiting {StartDelaySeconds}s before spawning")
        Sleep(StartDelaySeconds)
        set PirateTarget = PirateStart
        spawn{ TopUpLoop() }

        loop:
            Print("P2 STEP t={Elapsed}s target pirates={PirateTarget} | alive npcs={NpcAlive} pets={PetAlive} pirates={PirateAlive}")
            if (PirateTarget >= PirateMax):
                break
            Sleep(StepSeconds)
            set Elapsed += StepSeconds
            set PirateTarget = Min(PirateTarget + PirateStep, PirateMax)

        # Hold at the max so a final sample can be taken, and keep reporting.
        loop:
            Sleep(StepSeconds)
            set Elapsed += StepSeconds
            Print("P2 HOLD t={Elapsed}s | alive npcs={NpcAlive} pets={PetAlive} pirates={PirateAlive}")

    # Spawns at most one of each kind per tick, alternating spawners, until the targets are met.
    TopUpLoop()<suspends>:void =
        var Flip : logic = false
        loop:
            if (NpcAlive < NpcTarget):
                if (Flip?) then NpcSpawnerA.Spawn() else NpcSpawnerB.Spawn()
            if (PetAlive < PetTarget):
                if (Flip?) then PetSpawnerA.Spawn() else PetSpawnerB.Spawn()
            if (PirateAlive < PirateTarget):
                if (Flip?) then PirateSpawnerA.Spawn() else PirateSpawnerB.Spawn()
            set Flip = if (Flip?) then false else true
            Sleep(0.5)

    OnNpcSpawned(Agent:agent):void = set NpcAlive += 1
    OnNpcEliminated(Result:device_ai_interaction_result):void = set NpcAlive -= 1
    OnPetSpawned(Agent:agent):void = set PetAlive += 1
    OnPetEliminated(Result:device_ai_interaction_result):void = set PetAlive -= 1
    OnPirateSpawned(Agent:agent):void = set PirateAlive += 1
    OnPirateEliminated(Result:device_ai_interaction_result):void = set PirateAlive -= 1
