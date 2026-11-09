; =============================================================================
; SkyrimNet iActions - Lib: Shared Library
; =============================================================================
Scriptname iActions_Lib extends Quest

; === Properties ===
Package Property iActions_Passout Auto
Package Property iActions_StopUsingFurniture Auto
Idle Property IdleiActSleep Auto
Idle Property IdleForceDefaultState Auto
iActions_DrunkCore Property Core Auto ; Reference to drunk core for debug output
iActions_Exchange Property Exchange Auto ; Reference to exchange system
Bool Property RespondDirectlyToActions = True Auto

; Pass-through property for MCM and PlayerInventoryTracker compatibility
Int Property MaxTransfersToTrack
    Int Function Get()
        If Exchange
            Return Exchange.MaxTransfersToTrack
        EndIf
        Return 20 ; Default
    EndFunction
    Function Set(Int value)
        If Exchange
            Exchange.MaxTransfersToTrack = value
        EndIf
    EndFunction
EndProperty

; Pass-through property for MCM compatibility
Int Property ExchangeCooldown
    Int Function Get()
        If Exchange
            Return Exchange.ExchangeCooldown
        EndIf
        Return 20 ; Default
    EndFunction
    Function Set(Int value)
        If Exchange
            Exchange.ExchangeCooldown = value
        EndIf
    EndFunction
EndProperty

Bool Property EnableDebugNotify = False Auto ; Enable debug notifications across all iActions systems

; =========================================================
; --- Initialization/Update ---
; =========================================================

Event OnInit()
    Maintenance()
EndEvent

Event OnPlayerLoadGame()
    Maintenance()
EndEvent

Function Maintenance()
    LogAlert("iActions_Lib running maintenance...")
    
    ; Set all action cooldowns
    SetCooldowns()
    
    ; Register for configured force push key
    UpdateKeyRegistration()
EndFunction

Int Property StumbleAndFallCooldown = 20 Auto
Int Property PacifyCooldown = 20 Auto
Int Property DrinkAlcoholCooldown = 20 Auto
Int Property ReceiveFoodCooldown = 20 Auto
Bool Property EnablePerformanceLogging = False Auto ; Enable performance logging for all systems
Function SetCooldowns()
    SetActionCooldown("stumble_and_fall", StumbleAndFallCooldown)
    SetActionCooldown("aggressively_comply", PacifyCooldown)
    SetActionCooldown("drink_alcohol", DrinkAlcoholCooldown)
    SetActionCooldown("receive_food", ReceiveFoodCooldown)
    ; Note: exchange_items cooldown handled by iActions_Exchange.OnInit()
EndFunction

Function SetActionCooldown(String actionName, Int cooldown)
    SkyrimNetAPI.SetActionCooldown(actionName, cooldown)
    LogAlert(actionName + " cooldown: " + cooldown + " seconds.")
EndFunction

Function LogPerformance(String functionName, Float startTime)
    If EnablePerformanceLogging
        Float elapsed = (Utility.GetCurrentRealTime() - startTime) * 1000.0 ; Convert to milliseconds
        Debug.Trace("[iAct PERF] " + functionName + " took " + elapsed + "ms", 0)
    EndIf
EndFunction

; =========================================================
; --- Key Registration Management ---
; =========================================================

Function UpdateKeyRegistration()
    ; Unregister all keys first (to clear any previous registration)
    UnregisterForAllKeys()
    
    ; Register for the new key if it's not unbound (-1)
    If ForcePushKeyCode != -1
        RegisterForKey(ForcePushKeyCode)
        LogAlert("Force Push key registered: " + ForcePushKeyCode)
    Else
        LogAlert("Force Push key unbound")
    EndIf
EndFunction

; =========================================================
; --- Push with Configured Key ---
; =========================================================

Int Property ForcePushKeyCode = -1 Auto ; Default: Unbound (-1)
Event OnKeyDown(Int keyCode)
    ; Check if the key pressed matches our configured force push key
    If keyCode == ForcePushKeyCode && ForcePushKeyCode != -1
        ForcePush()
    EndIf
EndEvent

Function ForcePush(Bool asMessage = False)
    ObjectReference crosshairRef = Game.GetCurrentCrosshairRef()
    if crosshairRef == None
        LogAlert("No target under crosshair.", True, False, False, False)
        Return
    Else
        If crosshairRef != None && crosshairRef as Actor != None
            Actor targetActor = crosshairRef as Actor
            Game.GetPlayer().PushActorAway(targetActor, Utility.RandomInt(3, 5))
            
            ; Debug output for actors being pushed
            If EnableDebugNotify && Core
                Int drunkRank = Core.GetDrunkRank(targetActor)
                If drunkRank >= 0
                    ; Actor is drunk - show full debug info
                    Int maxRank = Core.GetMaxDrunkRank()
                    String drunkLevel = Core.GetDrunkLevel(targetActor)
                    LogAlert("DEBUG: " + targetActor.GetDisplayName() + ": " + drunkRank + "/" + maxRank + " (" + drunkLevel + ") [PUSHED]", True)
                Else
                    ; Actor is sober - show simple debug info
                    LogAlert("DEBUG: " + targetActor.GetDisplayName() + ": SOBER [PUSHED]", True)
                EndIf
            EndIf
        ElseIf crosshairRef != None
            ; Push non-actor objects using Havok impulse
            Actor player = Game.GetPlayer()
            Float playerX = player.GetPositionX()
            Float playerY = player.GetPositionY()
            Float objX = crosshairRef.GetPositionX()
            Float objY = crosshairRef.GetPositionY()
            
            ; Calculate direction from player to object
            Float dirX = objX - playerX
            Float dirY = objY - playerY
            Float distance = Math.sqrt(dirX * dirX + dirY * dirY)
            
            ; Normalize direction vector
            Float normalizedX = dirX / distance
            Float normalizedY = dirY / distance
            Float normalizedZ = 0.5  ; More upward component
            
            Float magnitude = 1.0
            
            ; Replace your current ApplyHavokImpulse section with this:
            Float objectMass = crosshairRef.GetMass()
            Float clampedMass = ClampFloat(objectMass, 1.0, 100.0)
            Float massMultiplier = Math.sqrt(clampedMass)  ; Cap mass
            Float adjustedMagnitude = 5.0 + (15.0 * massMultiplier / 10.0)  ; 5-20 range

            crosshairRef.ApplyHavokImpulse(normalizedX, normalizedY, normalizedZ, adjustedMagnitude)
        Else
            LogAlert("No valid target to push.", True, False, False, False)
        EndIf
    EndIf
EndFunction

; =========================================================
; --- Eligibility Check ---
; =========================================================

Bool Function iAction_IsEligible(Actor akActor)
    If akActor == None || akActor.IsDead()
        Debug.Trace("iAction_IsEligible is False!")
        return False
    EndIf
    Debug.Trace("iAction_IsEligible is True!")
    return True
EndFunction

Bool Function iAction_IfNotFriend_IsEligible(Actor akActor)
    If akActor == None || akActor.IsDead()
        return False
    ElseIf akActor.GetRelationshipRank(Game.GetPlayer()) >= 0
        Debug.Trace("iAction_IfNotFriend_IsEligible Relationship: " + akActor.GetRelationshipRank(Game.GetPlayer()))
        return False
    EndIf
    
    Debug.Trace("iAction_IfNotFriend_IsEligible Relationship: " + akActor.GetRelationshipRank(Game.GetPlayer()))
    return True
EndFunction

; =========================================================
; --- Various Execute Functions ---
; =========================================================

; === Stumble With Narration ===
Function StumbleStandalone_Execute(Actor akActor)
    If akActor && !akActor.IsDead()
        akActor.PushActorAway(akActor, 1.0)
        
        ; Add DirectNarration for stumbling
        String npcName = akActor.GetDisplayName()
        String broadcastMsg
        
        Int random = Utility.RandomInt(0, 2)
        If random == 0
            broadcastMsg = npcName + " loses their balance."
        ElseIf random == 1  
            broadcastMsg = npcName + " trips and falls over."
        Else
            broadcastMsg = npcName + " stumbles."
        EndIf
        
        LogAlert(broadcastMsg, True, RespondDirectlyToActions) ; Use local property for direct narration
    EndIf
EndFunction

; === Extract Arrows ===
Function ClearExtraArrows_Execute(Actor akPincushion, Actor akSurgeon = None)
    If akPincushion
        string msg = akPincushion.GetDisplayName() + "'s arrows removed"
        akPincushion.ClearExtraArrows()
        If akSurgeon && !akSurgeon.IsDead() && akSurgeon != akPincushion
            msg = msg + " by " + akSurgeon.GetDisplayName()
        EndIf
        
        String surgeonName = "self"
        If akSurgeon && !akSurgeon.IsDead() && akSurgeon != akPincushion
            surgeonName = akSurgeon.GetDisplayName()
        EndIf
        
        String eventDescription = akPincushion.GetDisplayName() + "'s arrows removed"
        If akSurgeon && !akSurgeon.IsDead() && akSurgeon != akPincushion
            eventDescription += " by " + akSurgeon.GetDisplayName()
        EndIf
        
        LogAlert(msg, True)
    EndIf
EndFunction

; currently not implemented
Spell Property PacifySelfSpell Auto ; iActions_PacifySelfSpell
Function PacifyTarget_Execute(Actor akActor)    
    If !akActor.IsDead() && PacifySelfSpell
        String actorName = akActor.GetDisplayName()
        PacifySelfSpell.Cast(akActor, akActor)
        LogAlert(actorName + " ceases hostilities, persuaded", True, RespondDirectlyToActions)
    EndIf
EndFunction

; implemented but action disabled
Spell Property PacifyAOESpell Auto ; Cast by Speaker: iActions_PacifyAOESpell
Function PacifyAOE_Execute(Actor akActor)    
    If !akActor.IsDead() && PacifyAOESpell
        String actorName = akActor.GetDisplayName()
        PacifyAOESpell.Cast(akActor, akActor)
        LogAlert("Everyone stops fighting, persuaded to temporarily cease hostilities", True, RespondDirectlyToActions)
    EndIf
EndFunction

; =========================================================
; --- Sleep / Pass Out Functions ---
; =========================================================

Function ApplyPassout(Actor akActor)
    ActorUtil.AddPackageOverride(akActor, iActions_Passout)
    akActor.EvaluatePackage()
EndFunction

Function RemovePassout(Actor akActor)
    ; Before RemovePassout
    LogAlert("Current package: " + akActor.GetCurrentPackage())

    ; Force interrupt current package behavior
    akActor.PlayIdle(IdleForceDefaultState)
    utility.wait(2)

    ; Remove the override
    ActorUtil.RemovePackageOverride(akActor, iActions_Passout)
    
    ; Force immediate re-evaluation
    akActor.EvaluatePackage()
    
    ; Redundant force-default in case package lingers
    akActor.PlayIdle(IdleForceDefaultState)

    ; After RemovePassout  
    LogAlert("Package after removal: " + akActor.GetCurrentPackage())
EndFunction

; =========================================================
; --- Utility Functions ---
; =========================================================

; === Log Trace & Notify ===
Function LogAlert(String sMessage="", Bool bNotifyInGame=False, Bool bUseDirectNarration=False, Bool bMessageBox = False, Bool bTraceLog=True) Global

    If bNotifyInGame
        Debug.Notification(sMessage)
    EndIf
    If bUseDirectNarration
        SkyrimNetAPI.DirectNarration(sMessage) ; System selects speaker, addresses all
    EndIf
    If bMessageBox
        Debug.MessageBox("[iAct] " + sMessage)
    EndIf
    If bTraceLog
        Debug.Trace("[iAct] " + sMessage)
    EndIf
EndFunction

; === Math: Min ===
int Function Min(int a, int b) Global
    if a < b
        return a
    else
        return b
    endif
EndFunction

; === Math: Float Clamp ===
Float Function ClampFloat(Float value, Float minVal, Float maxVal) Global
    If value < minVal
        Return minVal
    ElseIf value > maxVal
        Return maxVal
    Else
        Return value
    EndIf
EndFunction

; === Coin Flip ===
bool Function CoinFlip() Global
    return Utility.RandomInt(0, 1) == 0
EndFunction

; === Get Drunk Category from Faction Rank ===
; Converts a faction rank to a drunk category
; Returns: 0=Buzzed, 1=Tipsy, 2=Drunk, 3=Plastered, 4=Blackout
; Note: Rank 0 is special case (Buzzed), ranks 1+ use formula
Int Function GetCategoryFromRank(Int rank, Int pointsPerLevel) Global
    If rank <= 0
        return 0  ; DrunkCategory_Buzzed
    EndIf
    return ((rank - 1) / pointsPerLevel) + 1
EndFunction

; Check if actor is using any furniture
Bool Function IsUsingFurniture(Actor akActor)
    Return akActor.GetFurnitureReference() != None
EndFunction

; === Stop Using Furniture so animations can play reliably ===
Function StopUsingFurniture(Actor akActor)
    If IsUsingFurniture(akActor)
        ObjectReference furnitureRef = akActor.GetFurnitureReference()
        LogAlert(akActor.GetDisplayName() + " is currently using " + furnitureRef.GetDisplayName() + ":" + furnitureRef)
        ActorUtil.AddPackageOverride(akActor, iActions_StopUsingFurniture)
        akActor.EvaluatePackage()
        utility.wait(0.5)
        ActorUtil.RemovePackageOverride(akActor, iActions_StopUsingFurniture)
        akActor.EvaluatePackage()
    EndIf
EndFunction

Function Debug_GetCurrentPackage(Actor akActor)
    Package pkg = akActor.GetCurrentPackage()
    If pkg
        Int formID = pkg.GetFormID()
        ; Or use Trace for auto hex formatting
        LogAlert(" CurrentPackage FormID: " + formID)
    EndIf
EndFunction

Function Cleanup()
    LogAlert("iActions_Lib running cleanup...")

    ; Unregister hotkeys
    UnregisterForAllKeys()

    LogAlert("iActions_Lib cleanup complete.")
EndFunction
