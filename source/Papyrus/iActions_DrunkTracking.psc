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

Function TrackDrunkMember(Actor akActor)
    If akActor && StorageUtil.FormListFind(Self, MemberStorageKey, akActor) == -1
        If StorageUtil.FormListCount(Self, MemberStorageKey) >= Core.MaxDrunkMembers
            Return
        EndIf
        StorageUtil.FormListAdd(Self, MemberStorageKey, akActor)
        If StorageUtil.FormListCount(Self, MemberStorageKey) == 1 && !_isStartupMode
            CheckAndManageUpdates()
        EndIf
    EndIf
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

Function SoberUpDrunkMembers()
    Float startTime = Utility.GetCurrentRealTime()
    Int count = StorageUtil.FormListCount(Self, MemberStorageKey)
    If count <= 0
        If Core.Lib
            Core.Lib.LogPerformance("SoberUpDrunkMembers", startTime)
        EndIf
        Return
    EndIf

    Int i = count
    Int soberedUp = 0
    
    While i > 0
        i -= 1
        Actor member = StorageUtil.FormListGet(Self, MemberStorageKey, i) as Actor
        
        If member && !member.IsDead() && member.IsInFaction(Core.DrunkFaction)
            Int currentRank = member.GetFactionRank(Core.DrunkFaction)
            Int newRank = currentRank - Core.PointsPerDecay
            
            If newRank < 0
                member.RemoveFromFaction(Core.DrunkFaction)
                RemoveDrunkSpell(member)
                UntrackDrunkMember(member)
                member.EvaluatePackage()
                soberedUp += 1
                LogAlert(member.GetDisplayName() + " has sobered up completely", True, False)
            Else
                member.SetFactionRank(Core.DrunkFaction, newRank)
                String oldLevel = DrunkFaction.GetDrunkLevelFromRank(currentRank)
                String newLevel = DrunkFaction.GetDrunkLevelFromRank(newRank)
                Int oldCategory = iActions_Lib.GetCategoryFromRank(currentRank, Core.PointsPerLevel)
                Int newCategory = iActions_Lib.GetCategoryFromRank(newRank, Core.PointsPerLevel)

                If oldCategory > Core.DrunkCategory_Tipsy && newCategory <= Core.DrunkCategory_Tipsy
                    RemoveDrunkSpell(member)
                EndIf

                If oldLevel != newLevel
                    LogAlert(member.GetDisplayName() + " is now " + newLevel + " (was " + oldLevel + ")", False, False)
                EndIf
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
    
    Int i = count
    Int pruned = 0
    
    While i > 0
        i -= 1
        Actor member = StorageUtil.FormListGet(Self, MemberStorageKey, i) as Actor
        
        If !member || member.IsDead() || member.GetFactionRank(Core.DrunkFaction) < 0
            StorageUtil.FormListRemoveAt(Self, MemberStorageKey, i)
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
    Cell currentCell = Game.GetPlayer().GetParentCell()
    Int numRefs = currentCell.GetNumRefs(43)
    Int i = 0
    While i < numRefs
        Actor akActor = currentCell.GetNthRef(i, 43) as Actor
        If akActor && !akActor.IsDead() && akActor.IsInFaction(Core.DrunkFaction)
            If StorageUtil.FormListFind(Self, MemberStorageKey, akActor) == -1
                TrackDrunkMember(akActor)
                fixed += 1
                LogAlert("Fixed orphaned drunk: " + akActor.GetDisplayName() + " (Rank " + akActor.GetFactionRank(Core.DrunkFaction) + ")", abMessageBox)
            EndIf
        EndIf
        i += 1
    EndWhile
    LogAlert("Scan complete. Fixed: " + fixed, False, False, abMessageBox)
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
