; =============================================================================
; SkyrimNet iActions - Drunk Faction Management
; =============================================================================
; Handles faction membership, rank management, and drunk level calculations.
; References Core for shared properties (DrunkFaction, DrunkSpell, etc.)
; =============================================================================
Scriptname iActions_DrunkFaction extends Quest
Import iActions_Lib

; Cross-script properties (fill in CK/Spriggit)
iActions_DrunkCore Property Core Auto
iActions_DrunkTracking Property Tracking Auto
iActions_DrunkAnimation Property DrunkAnimation Auto  ; Needed for MakeActorSober to call PlayAnim

; =========================================================
; --- Faction/Rank Functions ---
; =========================================================

; === Set Faction & Rank ===
int Function SetDrunkFactionMembership(Actor akActor, Bool bShouldJoin)
    If Core.DrunkFaction == None
        LogAlert("Drunk Faction unavailable.")
        return -100
    ElseIf akActor == None
        LogAlert("Attempted to modify None actor.")
        return -100
    ElseIf akActor.IsDead()
        LogAlert("Attempted to modify dead actor: " + akActor.GetDisplayName())
        return -100
    EndIf
    Int newRank = -2 ; set to sober at start
    If Core.DrunkFaction
        If bShouldJoin && akActor.IsInFaction(Core.DrunkFaction)
            ; Already drunk - add points per drink (capped at max if enabled)
            Int currentRank = akActor.GetFactionRank(Core.DrunkFaction)
            If Core.EnableDrunkCap
                Int maxRank = Core.GetMaxDrunkRank()
                newRank = Min(currentRank + Core.PointsPerDrink, maxRank)
            Else
                ; No cap - allow unlimited progression
                newRank = currentRank + Core.PointsPerDrink
            EndIf
            akActor.SetFactionRank(Core.DrunkFaction, newRank)
        ElseIf bShouldJoin
            ; First drink - join faction at rank 0 (buzzed)
            akActor.AddToFaction(Core.DrunkFaction)
            akActor.SetFactionRank(Core.DrunkFaction, 0) ; Start at rank 0 (level 0 = buzzed)
            Tracking.TrackDrunkMember(akActor)
        ElseIf akActor.IsInFaction(Core.DrunkFaction)
            ; Manual sobering up
            akActor.RemoveFromFaction(Core.DrunkFaction)
            Tracking.UntrackDrunkMember(akActor)
            
            ; Let CheckAndManageUpdates handle stopping updates if needed
            Tracking.CheckAndManageUpdates()
        EndIf
    EndIf
    newRank = akActor.GetFactionRank(Core.DrunkFaction)

    ; Apply/remove drunk spell based on rank
    If Core.DrunkSpell
        Int category = iActions_Lib.GetCategoryFromRank(newRank, Core.PointsPerLevel)

        If category > Core.DrunkCategory_Tipsy
            If !akActor.HasSpell(Core.DrunkSpell)
                akActor.AddSpell(Core.DrunkSpell, false) ; false = not permanent
            EndIf
        Else
            If akActor.HasSpell(Core.DrunkSpell)
                akActor.RemoveSpell(Core.DrunkSpell)
            EndIf
        EndIf
    Else
        LogAlert("WARNING: DrunkSpell property not set - OAR drunk animations disabled")
    EndIf

    akActor.EvaluatePackage()
    return newRank
EndFunction

; === Make Sober ===
Function MakeActorSober(Actor akActor)
    ; Debug output before sobering
    If Core.Lib.EnableDebugNotify && akActor.IsInFaction(Core.DrunkFaction)
        Int currentRank = akActor.GetFactionRank(Core.DrunkFaction)
        String currentLevel = GetDrunkLevelFromRank(currentRank)
        LogAlert("DEBUG: " + akActor.GetDisplayName() + ": " + currentRank + " -> SOBER (" + currentLevel + " -> sober)", True)
    EndIf
    
    SetDrunkFactionMembership(akActor, False)
    DrunkAnimation.PlayAnim(akActor, True) ; Play brow wiping animation
    LogAlert(akActor.GetDisplayName() + " is sobering up", True)

    akActor.EvaluatePackage()
EndFunction

; =========================================================
; --- Drunk Level Calculation Functions ---
; =========================================================

; === Delegate to Core for max rank calculation ===
Int Function GetMaxDrunkRank()
    return Core.GetMaxDrunkRank()
EndFunction

; === Get drunk category (0=buzzed, 1=tipsy, 2=drunk, 3=plastered, 4=blackout, -1=sober) ===
Int Function GetDrunkCategory(Actor akActor)
    If Core.DrunkFaction == None || !akActor
        return Core.DrunkCategory_Sober
    EndIf

    Int rank = akActor.GetFactionRank(Core.DrunkFaction)
    If rank < 0
        return Core.DrunkCategory_Sober
    EndIf

    return iActions_Lib.GetCategoryFromRank(rank, Core.PointsPerLevel)
EndFunction

; === Get sub-level within category (0 to PointsPerLevel-1) ===
Int Function GetDrunkSubLevel(Actor akActor)
    If Core.DrunkFaction == None || !akActor
        return -1
    EndIf
    
    Int rank = akActor.GetFactionRank(Core.DrunkFaction)
    If rank < 0
        return -1
    EndIf
    
    return rank % Core.PointsPerLevel
EndFunction

; === Get drunk level as string ===
String Function GetDrunkLevel(Actor akActor)
    If Core.DrunkFaction == None
        return "unknown"
    EndIf
    
    Int rank = akActor.GetFactionRank(Core.DrunkFaction)
    return GetDrunkLevelFromRank(rank)
EndFunction

; === Helper: Get drunk level from rank value ===
String Function GetDrunkLevelFromRank(Int rank)
    If rank < 0
        return "sober"
    EndIf

    ; Special case: Rank 0 is always "buzzed"
    If rank == 0
        return "buzzed"
    EndIf

    Int category = iActions_Lib.GetCategoryFromRank(rank, Core.PointsPerLevel)

    If category == Core.DrunkCategory_Tipsy
        return "tipsy"
    ElseIf category == Core.DrunkCategory_Drunk
        return "drunk"
    ElseIf category == Core.DrunkCategory_Plastered
        return "plastered"
    ElseIf category >= Core.DrunkCategory_Blackout
        return "black-out drunk"
    Else
        return "unknown"
    EndIf
EndFunction

; === Get numeric drunk rank for external use ===
Int Function GetDrunkRank(Actor akActor)
    If Core.DrunkFaction == None || !akActor || !akActor.IsInFaction(Core.DrunkFaction)
        return -2 ; Faction removal value
    EndIf
    return akActor.GetFactionRank(Core.DrunkFaction)
EndFunction
