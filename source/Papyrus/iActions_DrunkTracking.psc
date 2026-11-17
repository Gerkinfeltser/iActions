Scriptname iActions_DrunkTracking extends Quest
Import StorageUtil
Import iActions_Lib
iActions_DrunkCore Property Core Auto
iActions_DrunkFaction Property DrunkFaction Auto
String Property MemberStorageKey = "iActions_DrunkMembers" AutoReadOnly
Bool _isStartupMode = True
Bool _updateRunning = False

; === Helper: Remove drunk spell from actor ===
Function RemoveDrunkSpell(Actor akActor)
    If Core.DrunkSpell && akActor.HasSpell(Core.DrunkSpell)
        akActor.RemoveSpell(Core.DrunkSpell)
    EndIf
EndFunction

Function Maintenance()
    _isStartupMode = True
    RegisterForSingleUpdate(5.0)
EndFunction
Event OnUpdate()
    If _isStartupMode
        _isStartupMode = False
        ScanAndFixOrphanedDrunks()
        PruneInvalidMembers()
        If StorageUtil.FormListCount(Self, MemberStorageKey) > 0
            CheckAndManageUpdates()
        EndIf
        Return
    EndIf
    If StorageUtil.FormListCount(Self, MemberStorageKey) == 0
        UnregisterForUpdate()
        Return
    EndIf
    Utility.Wait(0.5)
    If Core.EnableAutoSobering
        SoberUpDrunkMembers()
    EndIf
    ListDrunkMembers()
    PruneInvalidMembers()
    CheckAndManageUpdates()
EndEvent

; Returns True if akActor is tracked after the call, False if the list is full.
; A caller that gets False must not leave the actor in the drunk faction.
Bool Function TrackDrunkMember(Actor akActor)
    If !akActor
        Return False
    EndIf
    If StorageUtil.FormListFind(Self, MemberStorageKey, akActor) != -1
        Return True
    EndIf
    If StorageUtil.FormListCount(Self, MemberStorageKey) >= Core.MaxDrunkMembers
        PruneInvalidMembers() ; dead or sober entries may be holding slots
        If StorageUtil.FormListCount(Self, MemberStorageKey) >= Core.MaxDrunkMembers
            Return False
        EndIf
    EndIf
    StorageUtil.FormListAdd(Self, MemberStorageKey, akActor)
    If StorageUtil.FormListCount(Self, MemberStorageKey) == 1 && !_isStartupMode
        CheckAndManageUpdates()
    EndIf
    Return True
EndFunction

; For MakeActorDrunk: refuse a drinker who would not fit before the drink changes hands.
; Faction membership is not enough: an untracked faction member (orphan) needs a slot too.
Bool Function HasRoom(Actor akActor)
    Return StorageUtil.FormListFind(Self, MemberStorageKey, akActor) != -1 || StorageUtil.FormListCount(Self, MemberStorageKey) < Core.MaxDrunkMembers
EndFunction


Function UntrackDrunkMember(Actor akActor)
    If akActor
        Int index = StorageUtil.FormListFind(Self, MemberStorageKey, akActor)
        If index != -1
            StorageUtil.FormListRemoveAt(Self, MemberStorageKey, index)
        EndIf
    EndIf
EndFunction

Function CheckAndManageUpdates()
    If _isStartupMode
        Return
    EndIf
    
    Int count = StorageUtil.FormListCount(Self, MemberStorageKey)
    
    If count > 0
        _updateRunning = True
        RegisterForSingleUpdate(Core.MemberPollRate)
    ElseIf count == 0 && _updateRunning
        _updateRunning = False
        UnregisterForUpdate()
    EndIf
EndFunction

; Deducts points from one drunk member; shared by timed decay and sleep sobering.
; Returns the new rank (>= 0), -1 if fully sobered (removed from faction and untracked), -2 if skipped.
Int Function ApplySobering(Actor member, Int points)
    If !member || member.IsDead() || !member.IsInFaction(Core.DrunkFaction)
        Return -2
    EndIf

    Int currentRank = member.GetFactionRank(Core.DrunkFaction)
    Int newRank = currentRank - points

    If newRank < 0
        member.RemoveFromFaction(Core.DrunkFaction)
        RemoveDrunkSpell(member)
        UntrackDrunkMember(member)
        member.EvaluatePackage()
        Return -1
    EndIf

    ; One native call instead of Get -> Set: a drink landing mid-decay is added to, not overwritten.
    ; ModFactionRank does nothing to a non-member and never goes below 0, so it cannot re-add an actor
    ; that another thread sobered up in the meantime.
    member.ModFactionRank(Core.DrunkFaction, -points)
    newRank = member.GetFactionRank(Core.DrunkFaction)
    If newRank < 0
        Return -2 ; sobered up by another thread meanwhile
    EndIf

    Int oldCategory = iActions_Lib.GetCategoryFromRank(currentRank, Core.PointsPerLevel)
    Int newCategory = iActions_Lib.GetCategoryFromRank(newRank, Core.PointsPerLevel)
    If oldCategory > Core.DrunkCategory_Tipsy && newCategory <= Core.DrunkCategory_Tipsy
        RemoveDrunkSpell(member)
    EndIf
    Return newRank
EndFunction

Function SoberUpDrunkMembers()
    Float startTime = Utility.GetCurrentRealTime()
    Int count = StorageUtil.FormListCount(Self, MemberStorageKey)
    If count <= 0
        If Core.Lib
            Core.Lib.LogPerformance("SoberUpDrunkMembers", startTime)
        EndIf
        Return
    EndIf

    ; Snapshot: sleep sobering or sobers_up removing a member mid-loop cannot shift our indexes.
    Form[] members = StorageUtil.FormListToArray(Self, MemberStorageKey)
    Int points = Core.PointsPerDecay
    Int i = members.Length
    Int soberedUp = 0

    While i > 0
        i -= 1
        Actor member = members[i] as Actor
        Int newRank = ApplySobering(member, points)

        If newRank == -1
            soberedUp += 1
            LogAlert(member.GetDisplayName() + " has sobered up completely", True, False)
        ElseIf newRank >= 0
            String oldLevel = DrunkFaction.GetDrunkLevelFromRank(newRank + points)
            String newLevel = DrunkFaction.GetDrunkLevelFromRank(newRank)
            If oldLevel != newLevel
                LogAlert(member.GetDisplayName() + " is now " + newLevel + " (was " + oldLevel + ")", False, False)
            EndIf
        EndIf
    EndWhile

    If soberedUp > 0
        LogAlert(soberedUp + " NPCs sobered up this cycle")
        CheckAndManageUpdates()
    EndIf

    If Core.Lib
        Core.Lib.LogPerformance("SoberUpDrunkMembers", startTime)
    EndIf
EndFunction

Function PruneInvalidMembers()
    Int count = StorageUtil.FormListCount(Self, MemberStorageKey)
    If count <= 0
        Return
    EndIf
    
    ; Work on a snapshot and remove by value: the calls below yield, and another thread can
    ; add or remove entries meanwhile, so a stored index could point at a different actor.
    Form[] members = StorageUtil.FormListToArray(Self, MemberStorageKey)
    Int i = members.Length
    Int pruned = 0

    While i > 0
        i -= 1
        Actor member = members[i] as Actor

        If !member || member.IsDead() || member.GetFactionRank(Core.DrunkFaction) < 0
            StorageUtil.FormListRemove(Self, MemberStorageKey, members[i])
            pruned += 1
        EndIf
    EndWhile
    
    If pruned > 0
        LogAlert("Pruned " + pruned + " dead/invalid/sober drunks")
        If !_isStartupMode
            CheckAndManageUpdates()
        EndIf
    EndIf
EndFunction

Function ListDrunkMembers(Bool abMessageBox = False)
    Int count = StorageUtil.FormListCount(Self, MemberStorageKey)
    
    If count <= 0
        LogAlert("No drunk members found", False, False, abMessageBox)
        Return
    EndIf
    
    String output = count + " Characters are currently inebriated:"
    
    Int i = 0
    While i < count
        Actor member = StorageUtil.FormListGet(Self, MemberStorageKey, i) as Actor
        If member
            String drunkLevel = DrunkFaction.GetDrunkLevel(member)
            output += " - " + member.GetDisplayName() + ": " + drunkLevel + " (" + member.GetFactionRank(Core.DrunkFaction) + ")"
            
            If member.IsDead()
                output += " [DEAD]"
            ElseIf !member.Is3DLoaded()
                output += " [UNLOADED]"
            EndIf
        Else
            output += " - <INVALID>"
        EndIf
        i += 1
    EndWhile
    
    LogAlert(output, False, False, abMessageBox)
EndFunction

Function ScanAndFixOrphanedDrunks(Bool abMessageBox = False)
    LogAlert("Scanning for orphaned drunk NPCs...", abMessageBox)
    Int fixed = 0
    ; PO3 returns every faction member the game is processing, not only the player's cell
    Actor[] drunks = PO3_SKSEFunctions.GetAllActorsInFaction(Core.DrunkFaction)
    Int i = drunks.Length
    While i > 0
        i -= 1
        fixed += FixOrphanedDrunk(drunks[i], abMessageBox)
    EndWhile
    If drunks.Length == 0
        ; Nobody drunk, or a PO3 build without GetAllActorsInFaction: fall back to the player's cell
        Cell currentCell = Game.GetPlayer().GetParentCell()
        i = currentCell.GetNumRefs(43)
        While i > 0
            i -= 1
            fixed += FixOrphanedDrunk(currentCell.GetNthRef(i, 43) as Actor, abMessageBox)
        EndWhile
    EndIf
    LogAlert("Scan complete. Fixed: " + fixed, False, False, abMessageBox)
EndFunction

; Tracks a drunk actor missing from the list, or sobers them if the list is full. Returns 1 if it acted.
Int Function FixOrphanedDrunk(Actor akActor, Bool abMessageBox)
    If !akActor || akActor.IsDead() || !akActor.IsInFaction(Core.DrunkFaction)
        Return 0
    EndIf
    If StorageUtil.FormListFind(Self, MemberStorageKey, akActor) != -1
        Return 0
    EndIf
    If TrackDrunkMember(akActor)
        LogAlert("Fixed orphaned drunk: " + akActor.GetDisplayName() + " (Rank " + akActor.GetFactionRank(Core.DrunkFaction) + ")", abMessageBox)
    Else
        akActor.RemoveFromFaction(Core.DrunkFaction)
        RemoveDrunkSpell(akActor)
        akActor.EvaluatePackage()
        LogAlert("Sobered untracked drunk (limit " + Core.MaxDrunkMembers + " reached): " + akActor.GetDisplayName(), abMessageBox)
    EndIf
    Return 1
EndFunction

Function ClearAllDrunkMembers(Bool abMessageBox = False)
    Int count = StorageUtil.FormListCount(Self, MemberStorageKey)
    If count <= 0
        LogAlert("No drunk members to clear", False, False, abMessageBox)
        Return
    EndIf
    
    Int i = count
    While i > 0
        i -= 1
        Actor member = StorageUtil.FormListGet(Self, MemberStorageKey, i) as Actor
        If member && member.IsInFaction(Core.DrunkFaction)
            member.RemoveFromFaction(Core.DrunkFaction)
            RemoveDrunkSpell(member)
            member.EvaluatePackage()
        EndIf
    EndWhile
    
    StorageUtil.FormListClear(Self, MemberStorageKey)
    
    If !_isStartupMode
        CheckAndManageUpdates()
    EndIf
    
    LogAlert("Cleared " + count + " drunk NPCs", False, False, abMessageBox)
EndFunction

Function ForceRemoveAllFromFaction()
    LogAlert("Force-removing ALL actors from drunk faction...", True)
    Int removed = 0
    Cell currentCell = Game.GetPlayer().GetParentCell()
    Int numRefs = currentCell.GetNumRefs(43)
    Int i = 0
    While i < numRefs
        Actor akActor = currentCell.GetNthRef(i, 43) as Actor
        If akActor && akActor.IsInFaction(Core.DrunkFaction)
            akActor.RemoveFromFaction(Core.DrunkFaction)
            RemoveDrunkSpell(akActor)
            akActor.EvaluatePackage()
            StorageUtil.UnsetFloatValue(akActor, "iActions_LastDrinkTime")
            removed += 1
        EndIf
        i += 1
    EndWhile
    StorageUtil.FormListClear(Self, MemberStorageKey)
    If !_isStartupMode
        CheckAndManageUpdates()
    EndIf
    LogAlert("Force-removed " + removed + " actors from faction", True)
EndFunction

Function CapExistingDrunkNPCs()
    Int count = StorageUtil.FormListCount(Self, MemberStorageKey)
    If count <= 0
        LogAlert("No drunk NPCs to cap", True)
        Return
    EndIf
    
    Int maxRank = Core.GetMaxDrunkRank()
    Int capped = 0
    
    Int i = count
    While i > 0
        i -= 1
        Actor member = StorageUtil.FormListGet(Self, MemberStorageKey, i) as Actor
        If member && member.IsInFaction(Core.DrunkFaction)
            Int currentRank = member.GetFactionRank(Core.DrunkFaction)
            If currentRank > maxRank
                member.SetFactionRank(Core.DrunkFaction, maxRank)
                Int oldCategory = iActions_Lib.GetCategoryFromRank(currentRank, Core.PointsPerLevel)
                Int newCategory = iActions_Lib.GetCategoryFromRank(maxRank, Core.PointsPerLevel)

                If oldCategory > Core.DrunkCategory_Tipsy && newCategory <= Core.DrunkCategory_Tipsy
                    RemoveDrunkSpell(member)
                EndIf
                capped += 1
            EndIf
        EndIf
    EndWhile
    
    If capped > 0
        LogAlert(capped + " drunk NPCs reduced to maximum level (" + maxRank + ")", True)
    Else
        LogAlert("No drunk NPCs were over the limit", True)
    EndIf
EndFunction
