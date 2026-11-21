using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Marks one coastal zone tied to a job. A player whose boat docks within RadiusMeters
# of this device gets that job's landing bonus for the whole game.
landing_zone := class(creative_device):

    @editable
    Kind : resource_kind = resource_kind.Wood

    @editable
    RadiusMeters : float = 50.0

    GetKind<public>()<transacts>:resource_kind = Kind

    # Horizontal distance only, so a dock on a slope or at sea level still counts.
    Contains<public>(Position:vector3)<transacts><decides>:void =
        Center := GetTransform().Translation
        DX := Position.X - Center.X
        DY := Position.Y - Center.Y
        Radius := RadiusMeters * 100.0
        DX * DX + DY * DY <= Radius * Radius
