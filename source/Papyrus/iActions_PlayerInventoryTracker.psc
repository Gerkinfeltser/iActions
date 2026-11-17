; =============================================================================
; SkyrimNet iActions - Player Inventory Tracker (ReferenceAlias)
; =============================================================================
; Real-time inventory tracking using AddInventoryEventFilter for item exchanges
; Extends ReferenceAlias attached to the player
; =============================================================================

Scriptname iActions_PlayerInventoryTracker extends ReferenceAlias
Import iActions_Lib

; Properties to be set in CK
Actor Property PlayerRef Auto
Bool Property IsAlcoholExchange = False Auto

; Performance protection
; Note: MaxTransfersToTrack is now managed by iActions_Lib

; Tracking state
Bool bIsTracking = False
Actor TargetNPC = None
Int transfersTracked = 0

; Net accounting arrays (Phase 2 optimization)
; Replaces dual-array system with signed integers for automatic takeback handling
Form[] Property NetTrackedItems Auto           ; All unique items in trade
Int[] Property NetItemCounts Auto             ; Signed: +gave, -received, 0=cancelled
String[] Property NetItemNameCache Auto       ; Single name cache for all items

; Performance logging
Int PerformanceEventCounter = 0 ; For sampling event handler performance

; =========================================================
; --- Helper Functions ---
; =========================================================

; Helper function to get Lib script reference
iActions_Lib Function GetLib()
    Return GetOwningQuest() as iActions_Lib
EndFunction

; =========================================================
; --- Core Tracking Functions ---
; =========================================================

Function StartTracking(Actor akNPC)
    Float initStartTime = Utility.GetCurrentRealTime()

    ; DIAGNOSTIC: Confirm tracking is starting
    iActions_Lib libScript = GetOwningQuest() as iActions_Lib
    If libScript && libScript.EnableDebugNotify
        Debug.Trace("[iAct DIAG] StartTracking called for NPC: " + akNPC.GetDisplayName() + " (0x" + akNPC.GetFormID() + ")")
        Debug.Trace("[iAct DIAG] PlayerAlias attached to player: " + (PlayerRef == Game.GetPlayer()))
    EndIf

    ; Clear previous data - Phase 2: Initialize net accounting arrays (50% memory reduction)
    NetTrackedItems = new Form[128]
    NetItemCounts = new Int[128]
    NetItemNameCache = new String[128]

    TargetNPC = akNPC
    bIsTracking = True
    transfersTracked = 0
    PerformanceEventCounter = 0 ; Reset event counter for each tracking session

    ; Register for menu close to know when trading is done
    RegisterForMenu("ContainerMenu")

    ; Open NPC inventory
    akNPC.OpenInventory(True)

    If libScript
        libScript.LogPerformance("StartTracking - ArrayInit", initStartTime)
        LogAlert("Starting inventory exchange tracking with " + akNPC.GetDisplayName() + ". Max Transfers tracked: " + libScript.MaxTransfersToTrack, False)
    Else
        LogAlert("Starting inventory exchange tracking with " + akNPC.GetDisplayName() + ". Max Transfers tracked: 50", False)
    EndIf
EndFunction

; =========================================================
; --- Event Handlers ---
; =========================================================

; Event fires when player gets items
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    ; DIAGNOSTIC: Log every event when debug enabled to track what's happening
    iActions_Lib libScript = GetOwningQuest() as iActions_Lib
    If libScript && libScript.EnableDebugNotify
        String sourceInfo = "None"
        If akSourceContainer
            sourceInfo = akSourceContainer.GetDisplayName() + " (0x" + akSourceContainer.GetFormID() + ")"
        EndIf
        String itemName = "Unknown"
        If akBaseItem && akBaseItem.GetName()
            itemName = akBaseItem.GetName()
        EndIf
        String targetName = "None"
        If TargetNPC
            targetName = TargetNPC.GetDisplayName()
        EndIf
        Debug.Trace("[iAct DIAG] OnItemAdded: " + aiItemCount + "x " + itemName + " from " + sourceInfo + ", bIsTracking=" + bIsTracking + ", TargetNPC=" + targetName)
    EndIf

    If !bIsTracking || !akSourceContainer
        Return
    EndIf

    ; PERFORMANCE PROTECTION: Stop tracking after limit reached
    If transfersTracked >= GetLib().MaxTransfersToTrack
        LogAlert("Transfer limit reached (" + GetLib().MaxTransfersToTrack + "), stopping tracking to prevent stack dumping", False)
        Return
    EndIf

    ; Check if item came from our target NPC
    If akSourceContainer == TargetNPC
        ; Player received item from NPC (negative count in net accounting)
        AddItemNet(akBaseItem, aiItemCount, False)
        transfersTracked += 1
        LogAlert("Player received " + aiItemCount + "x " + akBaseItem.GetName() + " from " + TargetNPC.GetDisplayName(), False)
    EndIf
EndEvent

; Event fires when player loses items
Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    ; DIAGNOSTIC: Log every event when debug enabled to track what's happening
    iActions_Lib libScript = GetOwningQuest() as iActions_Lib
    If libScript && libScript.EnableDebugNotify
        String destInfo = "None"
        If akDestContainer
            destInfo = akDestContainer.GetDisplayName() + " (0x" + akDestContainer.GetFormID() + ")"
        EndIf
        ; Papyrus "a || b" yields a Bool, not the first non-empty string.
        String itemName = "Unknown"
        If akBaseItem && akBaseItem.GetName()
            itemName = akBaseItem.GetName()
        EndIf
        String targetName = "None"
        If TargetNPC
            targetName = TargetNPC.GetDisplayName()
        EndIf
        Debug.Trace("[iAct DIAG] OnItemRemoved: " + aiItemCount + "x " + itemName + " to " + destInfo + ", bIsTracking=" + bIsTracking + ", TargetNPC=" + targetName)
    EndIf

    If !bIsTracking || !akDestContainer
        Return
    EndIf

    ; PERFORMANCE PROTECTION: Stop tracking after limit reached
    If transfersTracked >= GetLib().MaxTransfersToTrack
        LogAlert("Transfer limit reached (" + GetLib().MaxTransfersToTrack + "), stopping tracking to prevent stack dumping", False)
        Return
    EndIf

    ; Check if item went to our target NPC
    If akDestContainer == TargetNPC
        ; Player gave item to NPC (positive count in net accounting)
        AddItemNet(akBaseItem, aiItemCount, True)
        transfersTracked += 1
        LogAlert("Player gave " + aiItemCount + "x " + akBaseItem.GetName() + " to " + TargetNPC.GetDisplayName(), False)
    EndIf
EndEvent

; Menu closed - finish tracking
Event OnMenuClose(String MenuName)
    iActions_Lib libScript = GetOwningQuest() as iActions_Lib
    If libScript && libScript.EnableDebugNotify
        Debug.Trace("[iAct DIAG] OnMenuClose: " + MenuName + ", bIsTracking=" + bIsTracking + ", transfersTracked=" + transfersTracked)
    EndIf

    If MenuName == "ContainerMenu" && bIsTracking
        FinishTracking()
    EndIf
EndEvent

; =========================================================
; --- Cleanup and Processing ---
; =========================================================

Function FinishTracking()
    ; Take this session's routing flag and clear the shared one before anything below yields.
    ; The alcohol callback waits for seconds; clearing after it could wipe the flag of an exchange started meanwhile.
    Bool wasAlcoholExchange = IsAlcoholExchange
    IsAlcoholExchange = False

    Float finishStartTime = Utility.GetCurrentRealTime()
    LogAlert("Container menu closed, processing " + transfersTracked + " tracked transfers", False)

    ; CRITICAL: Remove all inventory event filters to stop event queuing
    RemoveAllInventoryEventFilters()
    UnregisterForMenu("ContainerMenu")

    bIsTracking = False

    ; Build and send results
    String exchangeSummary = BuildExchangeSummary()

    ; Send results to Exchange for processing and logging
    iActions_Exchange exchangeScript = GetOwningQuest() as iActions_Exchange
    iActions_Lib libScript = GetOwningQuest() as iActions_Lib
    If exchangeScript
        ; Pass alcohol flag as parameter (refactored approach)
        exchangeScript.ProcessInventoryExchangeResults(TargetNPC, exchangeSummary, wasAlcoholExchange)
    EndIf
    If libScript
        libScript.LogPerformance("FinishTracking - total_transfers=" + transfersTracked, finishStartTime)
    EndIf

    LogAlert("Inventory exchange tracking completed", False)
EndFunction

; =========================================================
; --- Helper Functions ---
; =========================================================

; Phase 2: Old AddToArray function removed - replaced by AddItemNet()

; Phase 2: Unified net accounting function - replaces dual-array system
Function AddItemNet(Form akItem, Int aiCount, Bool bPlayerGaveItem)
    Float searchStartTime = Utility.GetCurrentRealTime()

    ; Convert to signed count: + if player gave, - if player received
    Int signedCount = aiCount
    If !bPlayerGaveItem
        signedCount = -aiCount
    EndIf

    ; Search for existing item
    Int i = 0
    While i < NetTrackedItems.Length && NetTrackedItems[i] != None
        If NetTrackedItems[i] == akItem
            ; Item exists, update net count
            NetItemCounts[i] = NetItemCounts[i] + signedCount

            ; Cache name on first encounter
            If NetItemNameCache[i] == "" && akItem
                NetItemNameCache[i] = akItem.GetName()
            EndIf

            iActions_Lib libScript = GetOwningQuest() as iActions_Lib
            If libScript
                libScript.LogPerformance("AddItemNet - existing_item", searchStartTime)
            EndIf
            Return
        EndIf
        i += 1
    EndWhile

    ; Add new item
    If i < NetTrackedItems.Length
        NetTrackedItems[i] = akItem
        NetItemCounts[i] = signedCount
        If akItem
            NetItemNameCache[i] = akItem.GetName()
        EndIf

        iActions_Lib libScript = GetOwningQuest() as iActions_Lib
        If libScript
            libScript.LogPerformance("AddItemNet - new_item_index=" + i, searchStartTime)
        EndIf
    Else
        LogAlert("TradeSystem: Array full, cannot track more items!", False)
    EndIf
EndFunction

; Build exchange summary for logging - Phase 2: Net accounting with OLD CLEAN FORMAT
String Function BuildExchangeSummary()
    Float summaryStartTime = Utility.GetCurrentRealTime()
    String targetName = TargetNPC.GetDisplayName()
    String playerName = Game.GetPlayer().GetDisplayName()

    ; Collect items for each section first
    String[] gaveItems = new String[128]
    String[] receivedItems = new String[128]
    Int gaveCount = 0
    Int receivedCount = 0

    ; Single pass through net arrays
    Int i = 0
    While i < NetTrackedItems.Length && NetTrackedItems[i] != None
        Int netCount = NetItemCounts[i]

        If netCount > 0
            ; Player gave this item to NPC
            gaveItems[gaveCount] = netCount as Int + "x " + NetItemNameCache[i]
            gaveCount += 1
        ElseIf netCount < 0
            ; Player received this item from NPC
            receivedItems[receivedCount] = Math.Abs(netCount) as Int + "x " + NetItemNameCache[i]
            receivedCount += 1
        ; netCount == 0: cancelled item, don't show in summary
        EndIf
        i += 1
    EndWhile

    ; Build summary from NPC's perspective for DirectNarration
    String summary = ""

    ; Items NPC received from player section
    If gaveCount > 0
        summary += targetName + " received from " + playerName + ": "
        Int j = 0
        While j < gaveCount
            summary += gaveItems[j]
            If j < gaveCount - 1
                summary += ", "
            EndIf
            j += 1
        EndWhile
        summary += "\n"
    EndIf

    ; Items NPC gave to player section
    If receivedCount > 0
        If gaveCount > 0
            summary += "\n"  ; Add space between sections
        EndIf
        summary += playerName + " received from " + targetName + ": "
        Int j = 0
        While j < receivedCount
            summary += receivedItems[j]
            If j < receivedCount - 1
                summary += ", "
            EndIf
            j += 1
        EndWhile
        summary += "\n"
    EndIf

    ; No exchange happened
    If gaveCount == 0 && receivedCount == 0
        summary = playerName + " and " + targetName + " didn't exchange any items."
    EndIf

    iActions_Lib libScript = GetOwningQuest() as iActions_Lib
    If libScript
        Int totalItems = gaveCount + receivedCount
        libScript.LogPerformance("BuildExchangeSummary - total_items=" + totalItems, summaryStartTime)
    EndIf

    Return summary
EndFunction

; Phase 2: Old CountTrackedItems function removed - no longer needed with net accounting