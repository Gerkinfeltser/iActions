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

; Nearest living NPC within 1000 units (the giver range) whose merchant chest holds alcohol; None if there is none.
; FindDrinkOn prefers the named drink but accepts any alcohol, like BuyDrinkFrom.
Actor Function FindNearestSeller(Actor akBuyer, String drinkName)
    Actor[] nearby = MiscUtil.ScanCellNPCs(akBuyer, 1000.0)
    Actor best = None
    Float bestDistance = 0.0
    Int i = 0
    While i < nearby.Length
        Actor a = nearby[i]
        If a && a != akBuyer && a != Game.GetPlayer() && !a.IsDead()
            Float d = a.GetDistance(akBuyer)
            ObjectReference chest = None
            If best == None || d < bestDistance
                chest = GetMerchantChest(a)
            EndIf
            If chest && FindDrinkOn(chest, drinkName)
                best = a
                bestDistance = d
            EndIf
        EndIf
        i += 1
    EndWhile
    Return best
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

Form Function ShowAlcoholChoiceDialog(Actor akActor, Form playerAlcohol)
    ; Free-drinks spawning already ran in DrinkOnce; this only asks the player.
    If playerAlcohol == None
        LogAlert(akActor.GetDisplayName() + " wants alcohol, but " + Game.GetPlayer().GetDisplayName() + " doesn't have any.", True, Core.Lib.RespondDirectlyToActions)
        Return None
    EndIf

    If Core.EnableAutoTakeAlcohol
        Game.GetPlayer().RemoveItem(playerAlcohol, 1, false, akActor)
        LogAlert(akActor.GetDisplayName() + " takes a " + playerAlcohol.GetName() + " from " + Game.GetPlayer().GetDisplayName(), True)
        Return playerAlcohol
    EndIf

    String result = Core.Lib.ShowRequestPrompt(akActor.GetDisplayName() + " is asking for a drink...")

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

Form Function GetAlcoholItem(ObjectReference akActor)
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

Form Function ResolveSpecificAlcohol(String drinkName, ObjectReference searchActor)
    If !drinkName || !searchActor
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

; The merchant chest of the first faction akSeller belongs to that has one, or None.
; Not Faction.IsVendor(): SKSE tests 0x1000 (kCrimeGold_UseDefaults in CommonLib TESFaction.h), not the vendor
; bit 0x4000, so it is False for vendor factions and True for crime factions such as Whiterun.
ObjectReference Function GetMerchantChest(Actor akSeller)
    Faction[] factions = akSeller.GetFactions(-128, 127)
    Int i = 0
    While i < factions.Length
        If factions[i]
            ObjectReference chest = factions[i].GetMerchantContainer()
            If chest
                Return chest
            EndIf
        EndIf
        i += 1
    EndWhile
    Return None
EndFunction

; What the last BuyDrinkFrom did, as a sentence for the narrated drink line ("" when nothing worth telling).
; ponytail: one shared variable; two NPCs buying in the same instant could swap notes. Return it from
; BuyDrinkFrom instead if that ever shows up.
String BuyNote = ""

; akBuyer pays a drink's value into akSeller's merchant chest and takes the drink from it.
; Returns None when akSeller is no vendor, stocks no alcohol, or akBuyer cannot pay.
Form Function BuyDrinkFrom(Actor akSeller, Actor akBuyer, String drinkName)
    BuyNote = ""
    ObjectReference chest = GetMerchantChest(akSeller)
    If chest == None
        Return None
    EndIf
    Form drink = FindDrinkOn(chest, drinkName)
    If drink == None
        LogAlert("BuyDrinkFrom: no alcohol in " + akSeller.GetDisplayName() + "'s merchant chest", False, False, False)
        Return None
    EndIf
    Form gold = Game.GetFormFromFile(0x0000000F, "Skyrim.esm")
    Int price = drink.GetGoldValue()
    If Core.NPCDrinksOnTheHouse
        ; No gold moves, but the narration reads as a normal sale (owner 2026-11-17: the seller should not know).
        chest.RemoveItem(drink, 1, True, akBuyer)
        BuyNote = akBuyer.GetDisplayName() + " buys a " + drink.GetName() + " from " + akSeller.GetDisplayName() + " for " + price + " gold. "
        Return drink
    EndIf
    If akBuyer.GetItemCount(gold) < price
        BuyNote = akBuyer.GetDisplayName() + " can't afford a " + drink.GetName() + " from " + akSeller.GetDisplayName() + " (" + price + " gold). "
        Return None
    EndIf
    akBuyer.RemoveItem(gold, price, True, chest)
    chest.RemoveItem(drink, 1, True, akBuyer)
    BuyNote = akBuyer.GetDisplayName() + " buys a " + drink.GetName() + " from " + akSeller.GetDisplayName() + " for " + price + " gold. "
    Return drink
EndFunction

; Drinks akHolder carries: list drinks and keyword-tagged ones, each item counted once.
Int Function CountAlcohol(ObjectReference akHolder)
    Form[] potions = PO3_SKSEFunctions.AddItemsOfTypeToArray(akHolder, 46, false, false, false)
    Int total = 0
    Int i = 0
    While i < potions.Length
        If potions[i] && Cache.IsAlcohol(potions[i])
            total += akHolder.GetItemCount(potions[i])
        EndIf
        i += 1
    EndWhile
    Return total
EndFunction

Form Function FindDrinkOn(ObjectReference akHolder, String drinkName)
    Form found = ResolveSpecificAlcohol(drinkName, akHolder)
    If found == None
        found = GetAlcoholItem(akHolder)
    EndIf
    Return found
EndFunction

; Reports the outcome. With an NPC giver or seller, that NPC is the one SkyrimNet has answer the drinker;
; with "respond directly" off they still get the event in their history, without a reaction.
Function TellDrinkResult(String msg, Actor akActor, Actor akGiver)
    If akGiver == None || akGiver == Game.GetPlayer()
        LogAlert(msg, True, Core.Lib.RespondDirectlyToActions)
        Return
    EndIf
    LogAlert(msg, True)
    If Core.Lib.RespondDirectlyToActions
        SkyrimNetApi.DirectNarration(msg, akGiver, akActor)
    Else
        SkyrimNetApi.RegisterPersistentEvent(msg, akActor, akGiver)
    EndIf
EndFunction

; Lookup order: preselected -> giver NPC (gift, else bought from their merchant chest) -> the drinker's own
; -> bought from the nearest merchant with alcohol in stock -> spawn (free-drinks mode) -> the player.
; The player is only asked when named as akGiver.
; Actors in the middle of a drink. The bottle is only used up after the animation, so a second drink_alcohol in that
; window would drink the same bottle again (0.7.0 run 2026-11-16-run6: one Ale, two rank steps).
Actor[] _drinkers

; No calls to other objects here, so the check and the claim run without yielding the script lock.
; ponytail: 16 slots; past that, extra drinkers go unguarded.
Bool Function ClaimDrinker(Actor akActor)
    If !_drinkers
        _drinkers = new Actor[16]
    EndIf
    If _drinkers.Find(akActor) >= 0
        Return False
    EndIf
    Int slot = _drinkers.Find(None)
    If slot >= 0
        _drinkers[slot] = akActor
    EndIf
    Return True
EndFunction

; Called on game load: a claim whose thread died (stack dump, script reset) would refuse that actor for good.
Function ResetDrinkers()
    _drinkers = new Actor[16] ; "= None" fails at runtime: Cannot cast from None to Actor[]
EndFunction

Function ReleaseDrinker(Actor akActor)
    If !_drinkers
        Return
    EndIf
    Int slot = _drinkers.Find(akActor)
    If slot >= 0
        _drinkers[slot] = None
    EndIf
EndFunction

Function MakeActorDrunk(Actor akActor, Form preSelectedAlcohol = None, String drinkName = "", Actor akGiver = None)
    If akActor == None
        Return
    EndIf
    If !ClaimDrinker(akActor)
        LogAlert("MakeActorDrunk: " + akActor.GetDisplayName() + " is still drinking; ignored", False, False, False)
        TellDrinkResult(akActor.GetDisplayName() + " is still drinking. ", akActor, akGiver)
        Return
    EndIf
    DrinkOnce(akActor, preSelectedAlcohol, drinkName, akGiver)
    ReleaseDrinker(akActor)
EndFunction

Function DrinkOnce(Actor akActor, Form preSelectedAlcohol, String drinkName, Actor akGiver)
    If akActor.IsDead()
        Return
    EndIf
    
    String npcName = akActor.GetDisplayName()
    Bool dbg = Core.Lib && Core.Lib.EnableDebugNotify
    String drinkMsg = ""
    Actor player = Game.GetPlayer()

    ; Ignore a giver that is the drinker, dead, or out of reach.
    ; 1000.0 is a tuning value: SkyrimNet resolves giver names up to 2000 units from the player.
    If akGiver == akActor || (akGiver && akGiver != player && (akGiver.IsDead() || akGiver.GetDistance(akActor) > 1000.0))
        akGiver = None
    EndIf

    LogAlert("MakeActorDrunk: " + npcName + " drinkName='" + drinkName + "' preSelected=" + preSelectedAlcohol + " giver=" + akGiver, False, False, False)

    ; Refuse before any drink moves: a new drinker past the cap would be drunk but never tracked.
    If !Core.Tracking.HasRoom(akActor)
        TellDrinkResult(npcName + " can't drink right now: too many drunk NPCs (" + Core.MaxDrunkMembers + "). ", akActor, akGiver)
        Return
    EndIf

    UpdatePlayerInInnStatus()

    If dbg
        LogAlert("DEBUG: RequireAlcohol=" + Core.RequireAlcohol + " EffectiveRequire=" + Core.EffectiveRequireAlcohol + " InnFreeDrinks=" + Core.DisableAlcoholRequirementInInns + " InInn=" + Core.PlayerIsInInn + " (only checked when InnFreeDrinks)", False, False, False)
    EndIf

    Form drink = preSelectedAlcohol

    If drink == None && akGiver && akGiver != player
        drink = FindDrinkOn(akGiver, drinkName)
        If drink
            akGiver.RemoveItem(drink, 1, True, akActor)
            drinkMsg = akGiver.GetDisplayName() + " gives " + npcName + " a " + drink.GetName() + ". "
        ElseIf Core.EffectiveRequireAlcohol
            ; The gift or sale goes into drinkMsg so the one narrated line tells SkyrimNet where the drink came from.
            drink = BuyDrinkFrom(akGiver, akActor, drinkName)
            drinkMsg = BuyNote
        EndIf
    EndIf

    If drink == None
        drink = FindDrinkOn(akActor, drinkName)
    EndIf

    ; A drinker with nothing buys from a nearby merchant (innkeeper, tavern, general store) instead of going without.
    ; Not limited to inns: the Drunken Huntsman's location has no LocTypeInn. Runs when no NPC giver was named,
    ; or when the player was named but has nothing to give. Buying needs alcohol required, as above.
    If drink == None && Core.EffectiveRequireAlcohol && (akGiver == None || (akGiver == player && FindDrinkOn(player, drinkName) == None))
        Actor seller = FindNearestSeller(akActor, drinkName)
        If seller
            drink = BuyDrinkFrom(seller, akActor, drinkName)
            If BuyNote != ""
                ; A sale or "can't afford": the seller answers, as with a named giver.
                drinkMsg = BuyNote
                akGiver = seller
            EndIf
        EndIf
    EndIf

    If drink == None && !Core.EffectiveRequireAlcohol
        drink = SpawnSpecificAlcohol(drinkName, akActor)
        If drink == None
            drink = SpawnAndGiveAlcohol(akActor)
        EndIf
    EndIf

    ; Owner decision 2026-11-16: with no giver and no drink the NPC is only told they have none (no popup).
    If drink == None && akGiver == player
        drink = ShowAlcoholChoiceDialog(akActor, FindDrinkOn(player, drinkName))
        If drink == None
            ; Declined, nothing to give, or "Give (Choose)": that one drinks later via ProcessAlcoholTransfer.
            Return
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
        If Core.EffectiveRequireAlcohol && drink != None
            Int remainingDrinks = CountAlcohol(akActor)
            drinkMsg += " (" + remainingDrinks + " left)"
        EndIf
        
        Int category = DrunkFaction.GetDrunkCategory(akActor)
        If Core.AllowStumble && category >= Core.DrunkCategory_Blackout && akActor && !akActor.IsDead()
            akActor.PushActorAway(akActor, 0.0)
            drinkMsg += " & stumbles"
        EndIf
           
        TellDrinkResult(drinkMsg, akActor, akGiver)
        akActor.EvaluatePackage()
    Else
        If Core.EffectiveRequireAlcohol
            TellDrinkResult(drinkMsg + npcName + " has no alcohol to drink!", akActor, akGiver)
        EndIf
    EndIf
EndFunction

Function ProcessAlcoholTransfer(Actor akActor, Form alcoholItem)
    If !akActor || !alcoholItem || akActor.IsDead()
        Return
    EndIf

    If !Core.IsAlcohol(alcoholItem)
        LogAlert("ProcessAlcoholTransfer: " + alcoholItem.GetName() + " is not alcohol (not in the list, no iActions_Alcohol keyword)", True)
        Return
    EndIf

    MakeActorDrunk(akActor, alcoholItem)
    LogAlert("Processed alcohol transfer: " + akActor.GetDisplayName() + " -> " + alcoholItem.GetName(), False)
EndFunction
