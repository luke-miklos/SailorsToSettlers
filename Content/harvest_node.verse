using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

HarvestPrompt<localizes>(Text:string):message = "{Text}"

# One gathering spot (a water's edge, a tree, a berry bush). Players hold the button to
# gather; the amount goes to the crew stockpile through the game_manager, which applies
# the phase rules and landing bonus. The node rests for RestSeconds after each use.
harvest_node := class(creative_device):

    @editable
    Manager : game_manager = game_manager{}

    # The hold-to-use button. Its Interact Time sets the gather speed (2 s = about 30 per minute).
    @editable
    Button : button_device = button_device{}

    @editable
    Kind : resource_kind = resource_kind.Wood

    @editable
    RestSeconds : float = 3.0

    OnBegin<override>()<suspends>:void =
        Button.SetInteractionText(HarvestPrompt(PromptText()))
        Button.InteractedWithEvent.Subscribe(OnInteracted)

    OnInteracted(Agent:agent):void =
        Amount := Manager.Harvest(Agent, Kind)
        if (Amount > 0):
            spawn{ Rest() }

    Rest()<suspends>:void =
        Button.Disable()
        Sleep(RestSeconds)
        Button.Enable()

    PromptText()<transacts>:string =
        case (Kind):
            resource_kind.Water => "Collect water"
            resource_kind.Wood => "Chop wood"
            resource_kind.Food => "Gather food"
            resource_kind.Pets => "Tame"
