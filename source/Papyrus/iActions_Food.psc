; =============================================================================
; SkyrimNet iActions - Food: NPC Food Request System
; =============================================================================
Scriptname iActions_Food extends Quest
Import PO3_SKSEFunctions
Import iActions_Lib

iActions_Lib Property Lib Auto
iActions_Exchange Property Exchange Auto
Keyword Property VendorItemFood Auto
Bool Property EnableAutoGiveFood = False Auto
Int Property AutoGiveMaxCount = 5 Auto
Int Property ReceiveFoodCooldown = 20 Auto
Int Property FoodTierPriority = 0 Auto

MagicEffect Property Survival_FoodRestoreHungerSmall Auto
MagicEffect Property Survival_FoodRestoreHungerMedium Auto
MagicEffect Property Survival_FoodRestoreHungerLarge Auto

; =========================================================
; --- Main Entry Point ---
; =========================================================

Function ReceiveFood_Execute(Actor akActor)
    If !akActor || akActor.IsDead()
        Return
    EndIf

    Float startTime = Utility.GetCurrentRealTime()

    String npcName = akActor.GetDisplayName()
    Actor player = Game.GetPlayer()

    If HasFoodInInventory(akActor)
        LogAlert(npcName + " already has food", True)
        Lib.LogPerformance("ReceiveFood_Execute", startTime)
        Return
    EndIf

    Form foodItem = GetFoodItem(player)
    If !foodItem
        LogAlert(npcName + " is asking for food, but " + player.GetDisplayName() + " doesn't have any.", True, Lib.RespondDirectlyToActions)
        Lib.LogPerformance("ReceiveFood_Execute", startTime)
        Return
    EndIf

    If EnableAutoGiveFood
        Int playerCount = player.GetItemCount(foodItem)
        Int transferCount = iActions_Lib.Min(playerCount, AutoGiveMaxCount)
        TransferFoodToNPC(akActor, foodItem, transferCount)
        Lib.LogPerformance("ReceiveFood_Execute", startTime)
        Return
    EndIf

    String result = ShowFoodChoiceDialog(akActor, foodItem)

    If result == "0"
        Int playerCount = player.GetItemCount(foodItem)
        Int transferCount = iActions_Lib.Min(playerCount, AutoGiveMaxCount)
        TransferFoodToNPC(akActor, foodItem, transferCount)
    ElseIf result == "1"
        EnableAutoGiveFood = True
        Int playerCount = player.GetItemCount(foodItem)
        Int transferCount = iActions_Lib.Min(playerCount, AutoGiveMaxCount)
        TransferFoodToNPC(akActor, foodItem, transferCount)
        LogAlert("Auto-give food enabled for future interactions", True)
    ElseIf result == "2"
        Exchange.StartInventoryExchange(akActor, Exchange.PlayerInventoryAlias, False)
    Else
        LogAlert("You declined to give food to " + npcName, True, Lib.RespondDirectlyToActions)
    EndIf

    Lib.LogPerformance("ReceiveFood_Execute", startTime)
EndFunction

; =========================================================
; --- Food Detection ---
; =========================================================

Int Function GetFoodTier(Form akItem)
    If !akItem || !akItem.HasKeyword(VendorItemFood)
        Return -1
    EndIf
    Potion pot = akItem as Potion
    If !pot
        Return -1
    EndIf
    Int numEffects = pot.GetNumEffects()
    Int i = 0
    While i < numEffects
        MagicEffect eff = pot.GetNthEffectMagicEffect(i)
        If eff == Survival_FoodRestoreHungerLarge
            Return 2
        ElseIf eff == Survival_FoodRestoreHungerMedium
            Return 1
        ElseIf eff == Survival_FoodRestoreHungerSmall
            Return 0
        EndIf
        i += 1
    EndWhile
    Return -1
EndFunction

Bool Function IsFoodItem(Form akItem)
    Return GetFoodTier(akItem) >= 0
EndFunction

Bool Function HasFoodInInventory(Actor akActor)
    If !akActor
        Return False
    EndIf
    Form[] potions = PO3_SKSEFunctions.AddItemsOfTypeToArray(akActor, 46, false, false, false)
    If !potions || potions.Length == 0
        Return False
    EndIf
    Int i = 0
    While i < potions.Length
        If IsFoodItem(potions[i])
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Form Function GetFoodItem(Actor akActor)
    If !akActor
        Return None
    EndIf
    Form[] potions = PO3_SKSEFunctions.AddItemsOfTypeToArray(akActor, 46, false, false, false)
    If !potions || potions.Length == 0
        Return None
    EndIf
    Form bestFood = None
    Int bestPriority = -1
    Int i = 0
    While i < potions.Length
        Int tier = GetFoodTier(potions[i])
        If tier >= 0
            Int priority = GetTierPriority(tier)
            If priority > bestPriority
                bestPriority = priority
                bestFood = potions[i]
            EndIf
        EndIf
        i += 1
    EndWhile
    Return bestFood
EndFunction

Int Function GetTierPriority(Int tier)
    If tier < 0
        Return -1
    EndIf
    If FoodTierPriority == 0
        Return tier
    ElseIf FoodTierPriority == 1
        If tier == 1
            Return 2
        ElseIf tier == 2
            Return 1
        Else
            Return 0
        EndIf
    ElseIf FoodTierPriority == 2
        Return 2 - tier
    ElseIf FoodTierPriority == 3
        If tier == 1
            Return 2
        ElseIf tier == 0
            Return 1
        Else
            Return 0
        EndIf
    EndIf
    Return tier
EndFunction

Form[] Function GetFoodItems(Actor akActor)
    If !akActor
        Return None
    EndIf
    Form[] potions = PO3_SKSEFunctions.AddItemsOfTypeToArray(akActor, 46, false, false, false)
    If !potions || potions.Length == 0
        Return None
    EndIf
    Form[] results = None
    Int foodCount = 0
    Int i = 0
    While i < potions.Length
        If IsFoodItem(potions[i])
            foodCount += 1
        EndIf
        i += 1
    EndWhile
    If foodCount == 0
        Return None
    EndIf
    results = Utility.CreateFormArray(foodCount)
    Int resultIdx = 0
    i = 0
    While i < potions.Length
        If IsFoodItem(potions[i])
            results[resultIdx] = potions[i]
            resultIdx += 1
        EndIf
        i += 1
    EndWhile
    Return results
EndFunction

Int Function GetFoodCount(Actor akActor, Form foodItem)
    If !akActor || !foodItem
        Return 0
    EndIf
    Return akActor.GetItemCount(foodItem)
EndFunction

; =========================================================
; --- Food Transfer ---
; =========================================================

Function TransferFoodToNPC(Actor akNPC, Form foodItem, Int count)
    If !akNPC || !foodItem || count <= 0
        Return
    EndIf

    Actor player = Game.GetPlayer()
    String npcName = akNPC.GetDisplayName()
    String foodName = foodItem.GetName()

    player.RemoveItem(foodItem, count, false, akNPC)

    String msg = npcName + " receives " + count + "x " + foodName + " from " + player.GetDisplayName()
    LogAlert(msg, True, Lib.RespondDirectlyToActions)
EndFunction

; =========================================================
; --- Dialog ---
; =========================================================

String Function ShowFoodChoiceDialog(Actor akActor, Form foodItem)
    String npcName = akActor.GetDisplayName()
    String msg = npcName + " is asking for food..."
    String result = Lib.ShowRequestPrompt(msg, "food", AutoGiveMaxCount)
    Return result
EndFunction
