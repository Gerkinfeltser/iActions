Scriptname iActions_DrunkAlcohol extends Quest
Import PO3_SKSEFunctions
Import iActions_Lib

iActions_DrunkCore Property Core Auto
iActions_DrunkCache Property Cache Auto
iActions_DrunkFaction Property DrunkFaction Auto
iActions_DrunkAnimation Property DrunkAnimation Auto

Function UpdatePlayerInInnStatus()
    if Core.RequireAlcohol && Core.DisableAlcoholRequirementInInns
        Core.PlayerIsInInn = IsPlayerInInn()
        Core.EffectiveRequireAlcohol = !Core.PlayerIsInInn
    Else
        Core.PlayerIsInInn = False
        Core.EffectiveRequireAlcohol = Core.RequireAlcohol
    EndIf
EndFunction

Bool Function IsPlayerInInn()
    Location currentLocation = Game.GetPlayer().GetCurrentLocation()
    If currentLocation && Core.LocTypeInn
        Return currentLocation.HasKeyword(Core.LocTypeInn)
    EndIf
    Return False
EndFunction

Form Function SpawnAndGiveAlcohol(Actor akActor)
    If !akActor || akActor.IsDead()
        Return None
    EndIf
    
    If !Core.iActions_AlcoholList || Core.iActions_AlcoholList.GetSize() <= 0
        Return None
    EndIf
    
    Int listSize = Core.iActions_AlcoholList.GetSize()
    Int randomIndex = Utility.RandomInt(0, listSize - 1)
    Form randomAlcohol = Core.iActions_AlcoholList.GetAt(randomIndex)
    
    If randomAlcohol
        akActor.AddItem(randomAlcohol, 1, True)
        LogAlert(akActor.GetDisplayName() + " spawned " + randomAlcohol.GetName())
        Return randomAlcohol
    EndIf
    Return None
EndFunction

Form Function SpawnSpecificAlcohol(String drinkName, Actor akActor)
    If !drinkName || !akActor || akActor.IsDead()
        Return None
    EndIf
    If !Core.iActions_AlcoholList
        Return None
    EndIf
    
    Int listSize = Core.iActions_AlcoholList.GetSize()
    Int i = 0
    While i < listSize
        Form alcoholForm = Core.iActions_AlcoholList.GetAt(i)
        If alcoholForm
            String formName = alcoholForm.GetName()
            If formName && StringUtil.Find(formName, drinkName) >= 0
                akActor.AddItem(alcoholForm, 1, True)
                LogAlert(akActor.GetDisplayName() + " spawned " + alcoholForm.GetName())
                Return alcoholForm
            EndIf
        EndIf
        i += 1
    EndWhile
    Return None
EndFunction

Form Function DetectTransferredItem(Actor akActor)
    If !akActor || akActor.IsDead() || akActor.GetNumItems() <= 0
        Return None
    EndIf
    
    Int listSize = Core.iActions_AlcoholList.GetSize()
    Int i = 0
    While i < listSize
        Form alcoholForm = Core.iActions_AlcoholList.GetAt(i)
        If alcoholForm && akActor.GetItemCount(alcoholForm) > 0
            Return alcoholForm
        EndIf
        i += 1
    EndWhile
    Return None
EndFunction

Form Function RequestAlcoholFromPlayer(Actor akActor)
    If !akActor || akActor.IsDead()
        Return None
    EndIf
    
    Form playerAlcohol = GetAlcoholItem(Game.GetPlayer())
    If !playerAlcohol
        LogAlert(akActor.GetDisplayName() + " wants alcohol, but " + Game.GetPlayer().GetDisplayName() + " doesn't have any.", True, Core.Lib.RespondDirectlyToActions)
        Return None
    EndIf
    
    Return ShowAlcoholChoiceDialog(akActor, playerAlcohol)
EndFunction

Form Function ShowAlcoholChoiceDialog(Actor akActor, Form playerAlcohol)
    If playerAlcohol == None && !Core.EffectiveRequireAlcohol
        Form spawnedAlcohol = SpawnAndGiveAlcohol(akActor)
        If spawnedAlcohol
            LogAlert(akActor.GetDisplayName() + " receives spawned " + spawnedAlcohol.GetName(), True)
            Return spawnedAlcohol
        EndIf
        Return None
    EndIf

    If playerAlcohol == None && Core.EffectiveRequireAlcohol
        LogAlert(akActor.GetDisplayName() + " wants alcohol, but " + Game.GetPlayer().GetDisplayName() + " doesn't have any.", True, Core.Lib.RespondDirectlyToActions)
        Return None
    EndIf

    If Core.EnableAutoTakeAlcohol
        Game.GetPlayer().RemoveItem(playerAlcohol, 1, false, akActor)
        LogAlert(akActor.GetDisplayName() + " takes a " + playerAlcohol.GetName() + " from " + Game.GetPlayer().GetDisplayName(), True)
        Return playerAlcohol
    EndIf

    String result = SkyMessage.Show(akActor.GetDisplayName() + " is asking for a drink...", "Auto Give", "Always Auto Give", "Give (Choose)", "Nope", getIndex = true)

    If result == "0"
        Game.GetPlayer().RemoveItem(playerAlcohol, 1, false, akActor)
        LogAlert(akActor.GetDisplayName() + " takes a " + playerAlcohol.GetName() + " from " + Game.GetPlayer().GetDisplayName(), True)
        Return playerAlcohol
    ElseIf result == "1"
        Core.EnableAutoTakeAlcohol = True
        Game.GetPlayer().RemoveItem(playerAlcohol, 1, false, akActor)
        LogAlert(akActor.GetDisplayName() + " takes a " + playerAlcohol.GetName() + " from " + Game.GetPlayer().GetDisplayName(), True)
        LogAlert("Auto-take alcohol enabled for future interactions", True)
        Return playerAlcohol
    ElseIf result == "2"
        Core.Lib.Exchange.StartInventoryExchange(akActor, Core.Lib.Exchange.PlayerInventoryAlias, True)
        Return None
    Else
        LogAlert(akActor.GetDisplayName() + " did not receive any alcohol from " + Game.GetPlayer().GetDisplayName(), True, Core.Lib.RespondDirectlyToActions)
        Return None
    EndIf
EndFunction

Form Function GetAlcoholItem(Actor akActor)
    Float startTime = Utility.GetCurrentRealTime()
    
    If !akActor
        If Core.Lib
            Core.Lib.LogPerformance("GetAlcoholItem", startTime)
        EndIf
        Return None
    EndIf

    If !Cache._cacheInitialized || Cache._cachedAlcoholCount <= 0
        If Core.Lib
            Core.Lib.LogPerformance("GetAlcoholItem", startTime)
        EndIf
        Return None
    EndIf

    Form[] potions = PO3_SKSEFunctions.AddItemsOfTypeToArray(akActor, 46, false, false, false)

    If !potions || potions.Length == 0
        If Core.Lib
            Core.Lib.LogPerformance("GetAlcoholItem", startTime)
        EndIf
        Return None
    EndIf

    Int i = 0
    While i < potions.Length
        Form item = potions[i]
        If item && Cache.IsAlcohol(item)
            If Core.Lib
                Core.Lib.LogPerformance("GetAlcoholItem", startTime)
            EndIf
            Return item
        EndIf
        i += 1
    EndWhile

    If Core.Lib
        Core.Lib.LogPerformance("GetAlcoholItem", startTime)
    EndIf
    Return None
EndFunction

Bool Function HasAlcohol(Actor akActor)
    Return GetAlcoholItem(akActor) != None
EndFunction

Form Function ResolveSpecificAlcohol(String drinkName, Actor searchActor)
    If !drinkName || !searchActor || searchActor.IsDead()
        Return None
    EndIf
    If !Core.iActions_AlcoholList
        Return None
    EndIf
    
    Form[] potions = PO3_SKSEFunctions.AddItemsOfTypeToArray(searchActor, 46, false, false, false)
    If !potions || potions.Length == 0
        Return None
    EndIf
    
    Int i = 0
    While i < potions.Length
        Form item = potions[i]
        If item && Cache.IsAlcohol(item)
            String itemName = item.GetName()
            If itemName && StringUtil.Find(itemName, drinkName) >= 0
                Return item
            EndIf
        EndIf
        i += 1
    EndWhile
    Return None
EndFunction

Function MakeActorDrunk(Actor akActor, Form preSelectedAlcohol = None, String drinkName = "")
    If akActor == None || akActor.IsDead()
        Return
    EndIf
    
    String npcName = akActor.GetDisplayName()
    Bool dbg = Core.Lib && Core.Lib.EnableDebugNotify
    String drinkMsg = ""

    LogAlert("MakeActorDrunk: " + npcName + " drinkName='" + drinkName + "' preSelected=" + preSelectedAlcohol, False, False, False)
    UpdatePlayerInInnStatus()

    If dbg
        LogAlert("DEBUG: RequireAlcohol=" + Core.RequireAlcohol + " EffectiveRequire=" + Core.EffectiveRequireAlcohol + " InInn=" + Core.PlayerIsInInn, False, False, False)
    EndIf

    Form drink = preSelectedAlcohol

    If drink == None && drinkName != ""
        LogAlert("MakeActorDrunk: resolving specific drink '" + drinkName + "' from player", False, False, False)
        Form specificDrink = ResolveSpecificAlcohol(drinkName, Game.GetPlayer())
        If specificDrink
            LogAlert("MakeActorDrunk: found '" + specificDrink.GetName() + "' in player inventory", False, False, False)
            If Core.EnableAutoTakeAlcohol
                Game.GetPlayer().RemoveItem(specificDrink, 1, false, akActor)
                LogAlert(npcName + " takes " + specificDrink.GetName() + " from " + Game.GetPlayer().GetDisplayName(), True)
                drink = specificDrink
            Else
                Form dialogResult = ShowAlcoholChoiceDialog(akActor, specificDrink)
                If dialogResult
                    drink = dialogResult
                EndIf
            EndIf
        Else
            LogAlert("MakeActorDrunk: '" + drinkName + "' not found in player, checking NPC", False, False, False)
            Form npcSpecific = ResolveSpecificAlcohol(drinkName, akActor)
            If npcSpecific
                LogAlert("MakeActorDrunk: found '" + npcSpecific.GetName() + "' in NPC inventory", False, False, False)
                drink = npcSpecific
            Else
                LogAlert("MakeActorDrunk: '" + drinkName + "' not found anywhere", False, False, False)
            EndIf
        EndIf
    EndIf

    If drink == None
        If Core.EffectiveRequireAlcohol
            LogAlert("MakeActorDrunk: checking NPC inventory for any alcohol", False, False, False)
            drink = GetAlcoholItem(akActor) as Form
            If drink
                LogAlert("MakeActorDrunk: found '" + drink.GetName() + "' in NPC inventory", False, False, False)
            Else
                LogAlert("MakeActorDrunk: no alcohol on NPC, requesting from player", False, False, False)
                Form gotAlcohol = RequestAlcoholFromPlayer(akActor)
                If gotAlcohol
                    drink = gotAlcohol
                Else
                    LogAlert("MakeActorDrunk: no alcohol available anywhere, aborting", False, False, False)
                    Return
                EndIf
            EndIf
        Else
            If drinkName != ""
                drink = SpawnSpecificAlcohol(drinkName, akActor)
            EndIf
            If drink == None
                LogAlert("MakeActorDrunk: spawning random alcohol (no requirement)", False, False, False)
                drink = SpawnAndGiveAlcohol(akActor)
            EndIf
        EndIf
    EndIf
    
    If drink != None
        LogAlert("MakeActorDrunk: " + npcName + " drinking '" + drink.GetName() + "'", False, False, False)
        Int drunkRank = DrunkFaction.SetDrunkFactionMembership(akActor, True)
        String drunkLevel = DrunkFaction.GetDrunkLevel(akActor)

        If dbg && drunkRank >= 0
            Int maxRank = Core.GetMaxDrunkRank()
            LogAlert("DEBUG: " + npcName + ": " + drunkRank + "/" + maxRank + " (" + drunkLevel + ")", True)
        EndIf

        DrunkAnimation.PlayAnim(akActor)
        Utility.Wait(2.5)

        If drink != None
            akActor.EquipItem(drink, False, False)
        EndIf
        
        drinkMsg += npcName + " drinks. They are now " + drunkLevel
        If Core.RequireAlcohol && drink != None
            Int remainingDrinks = akActor.GetItemCount(Core.iActions_AlcoholList)
            drinkMsg += " (" + remainingDrinks + " left)"
        EndIf
        
        Int category = DrunkFaction.GetDrunkCategory(akActor)
        If Core.AllowStumble && category >= Core.DrunkCategory_Blackout && akActor && !akActor.IsDead()
            akActor.PushActorAway(akActor, 0.0)
            drinkMsg += " & stumbles"
        EndIf
           
        LogAlert(drinkMsg, True, Core.Lib.RespondDirectlyToActions)
        akActor.EvaluatePackage()
    Else
        If Core.EffectiveRequireAlcohol
            LogAlert(npcName + " has no alcohol to drink!", True, Core.Lib.RespondDirectlyToActions)
        EndIf
    EndIf
EndFunction

Function ProcessAlcoholTransfer(Actor akActor, Form alcoholItem)
    If !akActor || !alcoholItem || akActor.IsDead()
        Return
    EndIf

    If !Core.iActions_AlcoholList.HasForm(alcoholItem)
        LogAlert("ProcessAlcoholTransfer: " + alcoholItem.GetName() + " is not in Alcohol List", True)
        Return
    EndIf

    MakeActorDrunk(akActor, alcoholItem)
    LogAlert("Processed alcohol transfer: " + akActor.GetDisplayName() + " -> " + alcoholItem.GetName(), False)
EndFunction
