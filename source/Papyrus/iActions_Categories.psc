; =============================================================================
; SkyrimNet iActions - Category Registration & Global Execution Wrappers
; -----------------------------------------------------------------------------
; Registers "Food & Drink" sub-category and 3 actions via SkyrimNetApi.
; stumble_and_fall stays as independent YAML action (not food/drink).
; Global execution wrappers resolve quest instances and delegate to quest-bound methods.
; =============================================================================
Scriptname iActions_Categories extends Quest
Import SkyrimNetApi
Import iActions_Lib

iActions_Lib Property Lib Auto

Function RegisterCategories()
    RegisterSubCategory( \
        "Food & Drink", \
        "Actions related to eating, drinking, and intoxication", \
        "iActions_Categories", "AlwaysEligible", \
        "", 9, "", "Food & Drink")
    
    RegisterAction("drink_alcohol", \
        "Use this action when {{ npc.name }} **wants** to consume alcohol. They will attempt to obtain a drink from their own inventory, or ask {{ player.name }} for some if they have none. {{ npc.name }} only drinks if they actually receive alcohol (player can deny). Drinking increases intoxication level. IMPORTANT: ALWAYS select the drink_alcohol action over the GESTURE action whenever drunkenness or alcohol is involved. Optionally provide a specific drinkName to request a particular drink (e.g. 'Nord Mead', 'Alto Wine').", \
        "iActions_Categories", "AlwaysEligible", \
        "iActions_Categories", "DrinkAlcohol_Execute", \
        "", "PAPYRUS_CUSTOM", 9, \
        "{\"abIsDrunk\": \"Bool\", \"drinkName\": \"String\"}", "Food & Drink", "")
    
    RegisterAction("receive_food", \
        "USE WHEN you are hungry and/or have no food and wish to receive some from {{ player.name }} (they may agree or decline).", \
        "iActions_Categories", "AlwaysEligible", \
        "iActions_Categories", "ReceiveFood_Execute", \
        "", "PAPYRUS_CUSTOM", 9, \
        "{}", "Food & Drink", "")
    
    RegisterAction("sobers_up", \
        "Stop acting drunk and return to normal behavior. Use this when {{ npc.name }} mentions sobering up, feeling clear-headed, or when enough time has passed since drinking.", \
        "iActions_Categories", "AlwaysEligible", \
        "iActions_Categories", "SobersUp_Execute", \
        "", "PAPYRUS_CUSTOM", 8, \
        "{}", "Food & Drink", "")
    
    LogAlert("[iAct CAT] Food & Drink category registered with 3 actions")
EndFunction

Bool Function AlwaysEligible(Actor akActor, String contextJson, String paramsJson) Global
    Return True
EndFunction

Function DrinkAlcohol_Execute(Actor akActor, String contextJson, String paramsJson) Global
    Bool abIsDrunk = GetJsonBool(paramsJson, "abIsDrunk", True)
    String drinkName = GetJsonString(paramsJson, "drinkName", "")
    iActions_DrunkCore core = Quest.GetQuest("iActions_MainQuest") as iActions_DrunkCore
    If core
        core.SetDrunkState_Execute(akActor, abIsDrunk, drinkName)
    Else
        LogAlert("[iAct CAT] DrinkAlcohol_Execute: could not resolve iActions_DrunkCore", True)
    EndIf
EndFunction

Function ReceiveFood_Execute(Actor akActor, String contextJson, String paramsJson) Global
    iActions_Food food = Quest.GetQuest("iActions_MainQuest") as iActions_Food
    If food
        food.ReceiveFood_Execute(akActor)
    Else
        LogAlert("[iAct CAT] ReceiveFood_Execute: could not resolve iActions_Food", True)
    EndIf
EndFunction

Function SobersUp_Execute(Actor akActor, String contextJson, String paramsJson) Global
    iActions_DrunkCore core = Quest.GetQuest("iActions_MainQuest") as iActions_DrunkCore
    If core
        core.SetDrunkState_Execute(akActor, False)
    Else
        LogAlert("[iAct CAT] SobersUp_Execute: could not resolve iActions_DrunkCore", True)
    EndIf
EndFunction
