; =============================================================================
; SkyrimNet iActions - Decorators: SkyrimNet Data Providers
; -----------------------------------------------------------------------------
; Provides decorator functions for SkyrimNet to access mod data
; =============================================================================
Scriptname iActions_Decorators extends Quest

; =========================================================
; --- SkyrimNet Decorator Registration ---
; =========================================================

Function RegisterSkyrimNetDecorators()
    Debug.Trace("[iAct BOOT] Registering SkyrimNet decorators...")
    Return
    ; Register paralysis status decorator
    ; SkyrimNetAPI.RegisterDecorator("get_npc_paralysis_status", "iActions_Decorators", "GetParalysisStatus")    
    
    Debug.Trace("[iAct BOOT] SkyrimNet decorators registered successfully")
EndFunction

; =========================================================
; --- Paralysis Status Decorator ---
; =========================================================

; Function: GetParalysisStatus
; Purpose: Returns paralysis status of an actor for SkyrimNet prompts
; Parameters: Actor akActor - The actor to check
; Returns: String - "paralyzed" if actor is paralyzed, "not paralyzed" otherwise
String Function GetParalysisStatus(Actor akActor) Global
    ; Handle invalid or dead actors
    If akActor == None || akActor.IsDead()
        Return "unknown"
    EndIf
    
    ; Check paralysis actor value
    Float paralysisValue = akActor.getAV("Paralysis")
    
    If paralysisValue >= 1.0
        Return "paralyzed"
    Else
        Return "not paralyzed"
    EndIf
EndFunction

; =========================================================
; --- Debug Helper Functions ---
; =========================================================

; Function: DebugParalysisStatus
; Purpose: Debug function to test paralysis status with logging
; Parameters: Actor akActor - The actor to check and log
; Example usage:
; ```
; {% if get_npc_paralysis_status(npc.UUID) == "paralyzed" %}
;     {{ decnpc(npc.UUID).name }} is paralyzed and cannot speak.
; {% endif %}
; ```

Function DebugParalysisStatus(Actor akActor) Global
    If akActor == None
        Debug.Trace("[iAct Decorators] DebugParalysisStatus: Actor is None")
        Return
    EndIf
    
    String actorName = akActor.GetDisplayName()
    Float paralysisValue = akActor.getAV("Paralysis")
    String status = GetParalysisStatus(akActor)
    
    Debug.Trace("[iAct Decorators] " + actorName + " paralysis value: " + paralysisValue + " (status: " + status + ")")
EndFunction

Function Cleanup()
    Debug.Trace("[iAct Decorators] Cleanup called (no cleanup needed currently)")
    ; If decorators were actually registered, unregister them here:
    ; SkyrimNetAPI.UnregisterDecorator("get_npc_paralysis_status")
EndFunction
