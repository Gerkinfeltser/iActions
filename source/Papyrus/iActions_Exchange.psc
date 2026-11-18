; =============================================================================
; SkyrimNet iActions - Exchange: Item Exchange System
; =============================================================================
Scriptname iActions_Exchange extends Quest

; === Properties ===
iActions_DrunkCore Property Core Auto            ; For alcohol processing callback
FormList Property iActions_AlcoholList Auto      ; Alcohol FormList for exchange detection
ReferenceAlias Property PlayerInventoryAlias Auto ; Player ReferenceAlias for inventory tracking
Bool Property EnableDebugNotify = False Auto     ; Debug notifications

; === Cooldown ===
Int Property ExchangeCooldown = 20 Auto
Int Property MaxTransfersToTrack = 20 Auto

; =========================================================
; --- Initialization ---
; =========================================================

Event OnInit()
    SkyrimNetAPI.SetActionCooldown("exchange_items", ExchangeCooldown)
EndEvent

; =========================================================
; --- Exchange Items Functions ---
; =========================================================

; Start inventory tracking via player ReferenceAlias
Function StartInventoryExchange(Actor akNPC, ReferenceAlias playerAlias, Bool isAlcoholExchange = False)
    ; Get the tracker script from the alias
    iActions_PlayerInventoryTracker tracker = playerAlias as iActions_PlayerInventoryTracker

    If tracker
        ; Set routing flag for alcohol exchanges
        tracker.IsAlcoholExchange = isAlcoholExchange
        tracker.StartTracking(akNPC)
    Else
        iActions_Lib.LogAlert("ERROR: PlayerInventoryAlias not properly configured!", True)
    EndIf
EndFunction

; Process exchange results (called by ReferenceAlias when tracking completes)
Function ProcessInventoryExchangeResults(Actor akNPC, String exchangeSummary, Bool isAlcoholExchange = False)
    ; Standard exchange processing (unchanged behavior for general exchanges)
    If !isAlcoholExchange
        iActions_Lib.LogAlert(exchangeSummary, True)
        If StringUtil.Find(exchangeSummary, "didn't exchange") >= 0
            Return
        EndIf
        SkyrimNetAPI.DirectNarration(exchangeSummary, akNPC, Game.GetPlayer())
        Return
    EndIf

    ; ========== ALCOHOL EXCHANGE PROCESSING ==========

    ; CRITICAL: Validate property configuration (from Task 3)
    If !iActions_AlcoholList
        iActions_Lib.LogAlert("ERROR: iActions_AlcoholList property not configured in iActions_Exchange!", True)
        iActions_Lib.LogAlert("Please complete Task 3 to configure ESP properties", True)
        ; Fallback to standard processing
        iActions_Lib.LogAlert(exchangeSummary, True)  ; Show notification for feedback
        SkyrimNetAPI.DirectNarration(exchangeSummary, akNPC, Game.GetPlayer())
        Return
    EndIf

    ; Get tracker for direct array access
    iActions_PlayerInventoryTracker tracker = PlayerInventoryAlias as iActions_PlayerInventoryTracker
    If !tracker
        iActions_Lib.LogAlert("ERROR: PlayerInventoryAlias not properly configured!", True)
        Return
    EndIf

    ; CRITICAL: Validate all tracker arrays exist and are initialized
    If !tracker.NetTrackedItems || !tracker.NetItemCounts || !tracker.NetItemNameCache
        iActions_Lib.LogAlert("ERROR: Tracker arrays not properly initialized!", True)
        Return
    EndIf

    ; Verify arrays are synced (same length)
    Int itemsLength = tracker.NetTrackedItems.Length
    If tracker.NetItemCounts.Length != itemsLength || tracker.NetItemNameCache.Length != itemsLength
        iActions_Lib.LogAlert("ERROR: Tracker arrays have mismatched lengths! Items=" + itemsLength + ", Counts=" + tracker.NetItemCounts.Length + ", Names=" + tracker.NetItemNameCache.Length, True)
        Return
    EndIf

    ; Scan for alcohol items (early exit optimization)
    Form alcoholItem = None
    String otherItems = ""
    Bool alcoholDetected = False

    Int i = 0
    While i < itemsLength && !alcoholDetected
        Form item = tracker.NetTrackedItems[i]
        Int netCount = tracker.NetItemCounts[i]

        If item && netCount > 0
            If Core.IsAlcohol(item)
                ; Player gave alcohol to NPC - this is what we're looking for!
                alcoholDetected = True
                alcoholItem = item

                ; Collect other items given (for enhanced narration)
                ; Scan remaining items to build complete list
                Int j = 0
                While j < itemsLength
                    If j != i && tracker.NetTrackedItems[j] && tracker.NetItemCounts[j] > 0
                        If otherItems != ""
                            otherItems += ", "
                        EndIf
                        otherItems += tracker.NetItemNameCache[j]
                    EndIf
                    j += 1
                EndWhile
            EndIf
        EndIf
        i += 1
    EndWhile

    ; Process alcohol transfer with enhanced narration
    If alcoholDetected && alcoholItem
        ; Build enhanced narration
        String enhancedSummary = akNPC.GetDisplayName() + " receives " + alcoholItem.GetName()
        If otherItems != ""
            enhancedSummary += " and " + otherItems
        EndIf
        enhancedSummary += " from " + Game.GetPlayer().GetDisplayName()

        ; Log enhanced exchange
        iActions_Lib.LogAlert(enhancedSummary, True)  ; Show notification for feedback
        SkyrimNetAPI.DirectNarration(enhancedSummary, akNPC, Game.GetPlayer())

        ; Call DrunkCore for alcohol processing
        If Core
            Core.ProcessAlcoholTransfer(akNPC, alcoholItem)
        EndIf
    Else
        If StringUtil.Find(exchangeSummary, "didn't exchange") >= 0
            Debug.Trace("[iAct] Alcohol exchange completed with no items transferred")
            Return
        EndIf
        iActions_Lib.LogAlert(exchangeSummary, True)
        SkyrimNetAPI.DirectNarration(exchangeSummary, akNPC, Game.GetPlayer())
    EndIf
EndFunction

; Execute exchange_items action for SkyrimNet
Function ExchangeItems_Execute(Actor akActor)
    If !akActor || akActor.IsDead()
        Return
    EndIf

    iActions_Lib.LogAlert(akActor.GetDisplayName() + " wants to exchange items with you...", True)
    StartInventoryExchange(akActor, PlayerInventoryAlias)
EndFunction
