; =============================================================================
; SkyrimNet iActions - Drunk Sleep
; =============================================================================
; Detects player sleep events and calculates hours slept for sobering system.
; Part of v3.0 Sleep Sobering feature.
; =============================================================================
Scriptname iActions_DrunkSleep extends Quest
Import iActions_Lib
Import StorageUtil

; === Properties ===
iActions_DrunkCore Property Core Auto

; === State Tracking ===
Float _sleepStartTime = 0.0
Float _sleepEndTime = 0.0
Float _hoursSlept = 0.0

; =============================================================================
; --- Maintenance (called from DrunkCore.Maintenance()) ---
; =============================================================================

Function Maintenance()
    LogAlert("iActions_DrunkSleep running maintenance...")
    RegisterForSleep()
EndFunction

; =============================================================================
; --- Sleep Event Handlers ---
; =============================================================================

Event OnSleepStart(Float afSleepStartTime, Float afDesiredSleepEndTime)
    _sleepStartTime = afSleepStartTime
    LogAlert("OnSleepStart fired: startTime=" + afSleepStartTime + ", desiredEnd=" + afDesiredSleepEndTime)
EndEvent

Event OnSleepStop(Bool abInterrupted)
    _sleepEndTime = Utility.GetCurrentGameTime()
    _hoursSlept = (_sleepEndTime - _sleepStartTime) * 24.0
    LogAlert("OnSleepStop fired: hoursSlept=" + _hoursSlept + ", interrupted=" + abInterrupted)
    
    ; Sober drunk NPCs based on sleep duration
    If !abInterrupted
        SoberDrunkMembersOnSleep()
    EndIf
EndEvent

; =============================================================================
; --- Accessors (for Phase 6 sobering logic) ---
; =============================================================================

Float Function GetHoursSlept()
    Return _hoursSlept
EndFunction

Float Function GetSleepStartTime()
    Return _sleepStartTime
EndFunction

Float Function GetSleepEndTime()
    Return _sleepEndTime
EndFunction

; =============================================================================
; --- Sleep Sobering Logic ---
; =============================================================================

Function SoberDrunkMembersOnSleep()
    ; Check if sleep sobering is disabled (0 = disabled)
    If Core.PointsPerSleepHour <= 0
        LogAlert("Sleep sobering disabled (PointsPerSleepHour = 0)")
        Return
    EndIf
    
    ; Calculate points to deduct
    Int pointsToDeduct = (_hoursSlept * Core.PointsPerSleepHour) as Int
    If pointsToDeduct <= 0
        LogAlert("Sleep too short to sober NPCs (pointsToDeduct = 0)")
        Return
    EndIf
    
    ; Access tracking list via Core.Tracking (storage key is on the tracking quest itself)
    String storageKey = Core.Tracking.MemberStorageKey
    Int count = StorageUtil.FormListCount(Core.Tracking, storageKey)
    If count <= 0
        LogAlert("No drunk NPCs to sober")
        Return
    EndIf
    
    Int soberedCompletely = 0
    Int soberedPartially = 0
    
    ; Snapshot: timed decay removing a member mid-loop cannot shift our indexes.
    Form[] members = StorageUtil.FormListToArray(Core.Tracking, storageKey)
    Int i = members.Length
    While i > 0
        i -= 1
        Actor member = members[i] as Actor
        Int newRank = Core.Tracking.ApplySobering(member, pointsToDeduct)

        If newRank == -1
            soberedCompletely += 1
        ElseIf newRank >= 0
            soberedPartially += 1
        EndIf
    EndWhile
    
    ; Summary notification
    If soberedCompletely > 0 || soberedPartially > 0
        String summary = "Sleep sobering: -" + pointsToDeduct + " points (" + _hoursSlept + " hrs)"
        If soberedCompletely > 0
            summary += " | " + soberedCompletely + " fully sobered"
        EndIf
        If soberedPartially > 0
            summary += " | " + soberedPartially + " partially sobered"
        EndIf
        LogAlert(summary)
        
        ; Trigger tracking update check
        Core.Tracking.CheckAndManageUpdates()
    EndIf
EndFunction
