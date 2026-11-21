using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

camp_station_kind<public> := enum:
    FeedFire
    UpgradeWeapon

CampPrompt<localizes>(Text:string):message = "{Text}"

# A button at the camp: either feeds the communal fire or upgrades the user's weapon.
# All rules (costs, phase, who can use it) live in game_manager.
camp_station := class(creative_device):

    @editable
    Manager : game_manager = game_manager{}

    @editable
    Button : button_device = button_device{}

    @editable
    Kind : camp_station_kind = camp_station_kind.FeedFire

    OnBegin<override>()<suspends>:void =
        Text := case (Kind):
            camp_station_kind.FeedFire => "Feed the fire ({game_config.FireWoodPerFeed} wood)"
            camp_station_kind.UpgradeWeapon => "Upgrade weapon"
        Button.SetInteractionText(CampPrompt(Text))
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent:agent):void =
        case (Kind):
            camp_station_kind.FeedFire => Manager.FeedFire(Agent)
            camp_station_kind.UpgradeWeapon => Manager.UpgradeWeapon(Agent)
