; =============================================================================
; SkyrimNet iActions - Drunk Core (Facade/Hub)
; =============================================================================
; Delegates to specialized scripts: Cache, Faction, Tracking, Alcohol, Animation
; =============================================================================
Scriptname iActions_DrunkCore extends Quest
Import ActorUtil
Import StorageUtil
Import PO3_SKSEFunctions
Import iActions_Lib
Import JIntMap
Import JValue

iActions_Lib Property Lib Auto
FormList Property iActions_AlcoholList Auto
iActions_DrunkCache Property Cache Auto
iActions_DrunkFaction Property FactionScript Auto
iActions_DrunkTracking Property Tracking Auto
iActions_DrunkAlcohol Property Alcohol Auto
iActions_DrunkAnimation Property DrunkAnimation Auto
iActions_DrunkSleep Property DrunkSleep Auto
Keyword Property LocTypeInn Auto
Bool Property DisableAlcoholRequirementInInns = False Auto
Bool Property PlayerIsInInn Auto
Bool Property EffectiveRequireAlcohol Auto
Faction Property DrunkFaction Auto
String Property MemberStorageKey = "iActions_DrunkMembers" AutoReadOnly
Int Property PointsPerLevel = 2 Auto
Int Property PointsPerDrink = 2 Auto
Int Property PointsPerDecay = 1 Auto
Int Property PointsPerSleepHour = 4 Auto
Int Property MaxDrunkLevel = 4 Auto
Float Property MemberPollRate = 300.0 Auto
Spell Property DrunkSpell Auto
Int Property DrunkCategory_Sober = -1 AutoReadOnly
Int Property DrunkCategory_Buzzed = 0 AutoReadOnly
Int Property DrunkCategory_Tipsy = 1 AutoReadOnly
Int Property DrunkCategory_Drunk = 2 AutoReadOnly
Int Property DrunkCategory_Plastered = 3 AutoReadOnly
Int Property DrunkCategory_Blackout = 4 AutoReadOnly
Bool Property AllowStumble = True Auto
Bool Property RequireAlcohol = True Auto
Bool Property EnableAutoSobering = True Auto
Bool Property EnableDrunkCap = True Auto

Bool Property EnableAutoTakeAlcohol = False Auto
; MCM "NPC Drinks on the House": an NPC buying a drink through iActions pays nothing. The player's own trades are unchanged.
Bool Property NPCDrinksOnTheHouse = False Auto
Bool Property EnableAnimations = True Auto
Int Property MIN_MEMBER_POLL_RATE = 20 AutoReadOnly
Int Property MAX_MEMBER_POLL_RATE = 600 AutoReadOnly
Int Property MAX_ALCOHOL_SCAN_ITEMS = 16 AutoReadOnly
Int Property MaxDrunkMembers = 32 Auto

Function Maintenance()
    LogAlert("iActions_DrunkCore running maintenance...")
    Alcohol.UpdatePlayerInInnStatus()
    Alcohol.ResetDrinkers()
    If Cache
        Cache._extrasLoaded = False
        If !Cache._cacheInitialized
            Cache.InitializeAlcoholCache()
        Else
            Cache.LoadExtraAlcohol()
        EndIf
    EndIf
    If Tracking
        Tracking.Maintenance()
    EndIf
    If DrunkSleep
        DrunkSleep.Maintenance()
    EndIf
EndFunction

Function RefreshAlcoholCache()
    If Cache
        Cache.RefreshAlcoholCache()
    EndIf
EndFunction

Bool Function IsAlcohol(Form akForm)
    If Cache
        Return Cache.IsAlcohol(akForm)
    EndIf
    If !akForm || !iActions_AlcoholList
        Return False
    EndIf
    Return iActions_AlcoholList.HasForm(akForm) || akForm.HasKeywordString("iActions_Alcohol")
EndFunction

Function SetDrunkState_Execute(Actor akActor, Bool abIsDrunk, String drinkName = "")
    SetActorDrunkState(akActor, abIsDrunk, drinkName)
EndFunction

; Entry point of drink_alcohol.yaml. sobers_up.yaml keeps SetDrunkState_Execute: SkyrimNet requires the
; YAML parameter count to equal the function's, so the two actions cannot share one signature.
Function DrinkAlcohol_Execute(Actor akActor, String drinkName = "", Actor akGiver = None)
    If akActor && !akActor.IsDead()
        Alcohol.MakeActorDrunk(akActor, None, drinkName, akGiver)
    EndIf
EndFunction

Function SetActorDrunkState(Actor akActor, Bool abIsDrunk, String drinkName = "")
    If akActor == None || akActor.IsDead()
        return
    EndIf
    If abIsDrunk
        Alcohol.MakeActorDrunk(akActor, None, drinkName)
    Else
        FactionScript.MakeActorSober(akActor)
    EndIf
EndFunction

Function ProcessAlcoholTransfer(Actor akActor, Form alcoholItem)
    Alcohol.ProcessAlcoholTransfer(akActor, alcoholItem)
EndFunction

Function UpdatePlayerInInnStatus()
    Alcohol.UpdatePlayerInInnStatus()
EndFunction

Int Function GetMaxDrunkRank()
    Return MaxDrunkLevel * PointsPerLevel
EndFunction

Int Function GetDrunkCategory(Actor akActor)
    Return FactionScript.GetDrunkCategory(akActor)
EndFunction

String Function GetDrunkLevel(Actor akActor)
    Return FactionScript.GetDrunkLevel(akActor)
EndFunction

Int Function GetDrunkRank(Actor akActor)
    Return FactionScript.GetDrunkRank(akActor)
EndFunction

Int Function GetDrunkSubLevel(Actor akActor)
    Return FactionScript.GetDrunkSubLevel(akActor)
EndFunction

Form Function GetAlcoholItem(Actor akActor)
    Return Alcohol.GetAlcoholItem(akActor)
EndFunction

Bool Function HasAlcohol(Actor akActor)
    Return Alcohol.HasAlcohol(akActor)
EndFunction

Function ClearAllDrunkMembers(Bool abMessageBox = False)
    Tracking.ClearAllDrunkMembers(abMessageBox)
EndFunction

Function ClearAllDrunkMembersNotify()
    Tracking.ClearAllDrunkMembers(True)
EndFunction

Function ListDrunkMembers(Bool abMessageBox = False)
    Tracking.ListDrunkMembers(abMessageBox)
EndFunction

Function ListDrunkMembersNotify()
    Tracking.ListDrunkMembers(True)
EndFunction

Function CapExistingDrunkNPCs()
    Tracking.CapExistingDrunkNPCs()
EndFunction

Function ScanAndFixOrphanedDrunks(Bool abMessageBox = False)
    Tracking.ScanAndFixOrphanedDrunks(abMessageBox)
EndFunction

Function ScanAndFixOrphanedDrunksNotify()
    Tracking.ScanAndFixOrphanedDrunks(True)
EndFunction

Function ForceRemoveAllFromFaction()
    Tracking.ForceRemoveAllFromFaction()
EndFunction

Function PrepareForUninstall()
    LogAlert("iActions: Beginning DrunkCore cleanup...", True)
    If Cache
        Cache.CleanupAlcoholCache()
    EndIf
    If Tracking
        Tracking.ClearAllDrunkMembers(False)
    EndIf
    StorageUtil.ClearAllPrefix(Self)
    LogAlert("iActions: DrunkCore cleanup complete.", True)
EndFunction
