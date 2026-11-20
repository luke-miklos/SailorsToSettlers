using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Throwaway M0 check: proves the Verse build, push and play loop works,
# and that game_config values are readable. Delete once real systems exist.
smoke_test_device := class(creative_device):

    OnBegin<override>()<suspends>:void =
        Print("SailorsToSettlers smoke test: rounds={game_config.TotalRounds}, prepare={game_config.PrepareSeconds}s, final defend={game_config.FinalDefendSeconds}s")
