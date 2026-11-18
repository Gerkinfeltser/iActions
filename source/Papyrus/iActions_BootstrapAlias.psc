; =============================================================================
; SkyrimNet iActions - BootstrapAlias: System Initialization
; -----------------------------------------------------------------------------
; Ensures main quest & scripts are running on every load
; =============================================================================
Scriptname iActions_BootstrapAlias extends ReferenceAlias

Quest Property iActions_MainQuest Auto
Quest Property iActions_MCMQuest Auto

Event OnInit()
    Debug.Trace("[iAct BOOT] Bootstrap OnInit...")
    RegisterForSingleUpdate(2.0) ; Small delay to ensure everything's loaded
EndEvent

Event OnPlayerLoadGame()
    Debug.Trace("[iAct BOOT] Bootstrap OnPlayerLoadGame...")
    RegisterForSingleUpdate(0.5)
EndEvent

Event OnUpdate()
    Debug.Trace("[iAct BOOT] Running iActions bootstrap sequence...")
    UnregisterForUpdate()
    RunMaintenance()
EndEvent

Function RunMaintenance()
    Bool hasErrors = False
    
    ; Start main quest first
    If !iActions_MainQuest
        Debug.Trace("[iAct BOOT] ERROR: Bootstrap missing iActions_MainQuest property!")
        hasErrors = True
    ElseIf !iActions_MainQuest.IsRunning()
        Debug.Trace("[iAct BOOT] Starting iActions_MainQuest...")
        iActions_MainQuest.Start()
        If !iActions_MainQuest.IsRunning()
            Debug.Trace("[iAct BOOT] ERROR: Failed to start iActions_MainQuest!")
            hasErrors = True
        EndIf
    EndIf
    
    ; Start MCM quest
    If !iActions_MCMQuest
        Debug.Trace("[iAct BOOT] ERROR: Bootstrap missing iActions_MCMQuest property!")
        hasErrors = True
    ElseIf !iActions_MCMQuest.IsRunning()
        Debug.Trace("[iAct BOOT] Starting iActions_MCMQuest...")
        iActions_MCMQuest.Start()
        If !iActions_MCMQuest.IsRunning()
            Debug.Trace("[iAct BOOT] ERROR: Failed to start iActions_MCMQuest!")
            hasErrors = True
        Else
             Debug.Trace("[iAct BOOT] iActions_MCMQuest is already up & running")
        EndIf
    EndIf
    
    ; Wait a moment for scripts to initialize, then call maintenance
    If !hasErrors
        Utility.Wait(0.5) ; Brief pause for quest scripts to initialize
        
        ; Call maintenance on main quest components (they should be running now)
        If iActions_MainQuest && iActions_MainQuest.IsRunning()
            ; Get the script instances from the running quest
            iActions_Lib libScript = iActions_MainQuest as iActions_Lib
            iActions_DrunkCore coreScript = iActions_MainQuest as iActions_DrunkCore
            iActions_Decorators decoratorsScript = iActions_MainQuest as iActions_Decorators
            
            If libScript
                Debug.Trace("[iAct BOOT] Calling Lib.Maintenance()...")
                libScript.Maintenance()
            Else
                Debug.Trace("[iAct BOOT] WARNING: Could not get Lib script from MainQuest")
            EndIf
            
            If coreScript
                Debug.Trace("[iAct BOOT] Calling DrunkCore.Maintenance()...")
                coreScript.Maintenance()
            Else
                Debug.Trace("[iAct BOOT] WARNING: Could not get DrunkCore script from MainQuest")
            EndIf

            If decoratorsScript
                Debug.Trace("[iAct BOOT] Calling DecoratorsScript.Maintenance()...")
                decoratorsScript.RegisterSkyrimNetDecorators()
            Else
                Debug.Trace("[iAct BOOT] WARNING: Could not get DecoratorsScript script from MainQuest")
            EndIf
        EndIf      
    EndIf
    
    ; Summary
    If hasErrors
        Debug.Trace("[iAct BOOT] Bootstrap completed with ERRORS - check properties in CK!")
    Else
        Debug.Trace("[iAct BOOT] Bootstrap completed successfully - all systems online")
    EndIf
EndFunction

; =========================================================
; --- Location Detection Events ---
; =========================================================

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
    Debug.Trace("[iAct BOOT] Location changed, updating PlayerIsInInn status...")
    If iActions_MainQuest && iActions_MainQuest.IsRunning()
        iActions_DrunkCore coreScript = iActions_MainQuest as iActions_DrunkCore
        If coreScript
            coreScript.UpdatePlayerInInnStatus()
        Else
            Debug.Trace("[iAct BOOT] WARNING: Could not get DrunkCore script for location update")
        EndIf
    Else
        Debug.Trace("[iAct BOOT] WARNING: MainQuest not available for location update")
    EndIf
EndEvent

Event OnCellLoad()
    Debug.Trace("[iAct BOOT] Cell loaded, updating PlayerIsInInn status...")
    If iActions_MainQuest && iActions_MainQuest.IsRunning()
        iActions_DrunkCore coreScript = iActions_MainQuest as iActions_DrunkCore
        If coreScript
            coreScript.UpdatePlayerInInnStatus()
        Else
            Debug.Trace("[iAct BOOT] WARNING: Could not get DrunkCore script for cell load")
        EndIf
    Else
        Debug.Trace("[iAct BOOT] WARNING: MainQuest not available for cell load")
    EndIf
EndEvent

; =========================================================
; --- Shutdown Sequence ---
; =========================================================

Function Shutdown()
    Debug.Trace("[iAct BOOT] Beginning complete shutdown sequence...")
    Bool hasErrors = False
    
    ; Get script instances from main quest and clean them up
    If iActions_MainQuest && iActions_MainQuest.IsRunning()
        iActions_DrunkCore coreScript = iActions_MainQuest as iActions_DrunkCore
        iActions_Lib libScript = iActions_MainQuest as iActions_Lib
        iActions_Decorators decoratorsScript = iActions_MainQuest as iActions_Decorators
        
        ; Clean up DrunkCore
        If coreScript
            Debug.Trace("[iAct BOOT] Calling DrunkCore.PrepareForUninstall()...")
            coreScript.PrepareForUninstall()
        Else
            Debug.Trace("[iAct BOOT] WARNING: Could not get DrunkCore for cleanup")
            hasErrors = True
        EndIf
        
        ; Clean up Lib
        If libScript
            Debug.Trace("[iAct BOOT] Calling Lib.Cleanup()...")
            libScript.Cleanup()
        Else
            Debug.Trace("[iAct BOOT] WARNING: Could not get Lib for cleanup")
            hasErrors = True
        EndIf
        
        ; Clean up Decorators (optional - no cleanup needed currently)
        If decoratorsScript
            Debug.Trace("[iAct BOOT] Calling Decorators.Cleanup()...")
            decoratorsScript.Cleanup()
        EndIf
        
        ; Stop main quest
        Debug.Trace("[iAct BOOT] Stopping Main Quest...")
        iActions_MainQuest.Stop()
    Else
        Debug.Trace("[iAct BOOT] WARNING: MainQuest not running or not available")
        hasErrors = True
    EndIf
    
    ; Stop MCM quest
    If iActions_MCMQuest && iActions_MCMQuest.IsRunning()
        Debug.Trace("[iAct BOOT] Stopping MCM Quest...")
        iActions_MCMQuest.Stop()
    Else
        Debug.Trace("[iAct BOOT] WARNING: MCMQuest not running or not available")
        hasErrors = True
    EndIf
    
    ; Stop bootstrap quest last (this quest)
    Quest bootstrapQuest = GetOwningQuest()
    If bootstrapQuest && bootstrapQuest.IsRunning()
        Debug.Trace("[iAct BOOT] Stopping Bootstrap Quest...")
        bootstrapQuest.Stop()
    EndIf
    
    If hasErrors
        Debug.Trace("[iAct BOOT] Shutdown completed with WARNINGS - check logs")
    Else
        Debug.Trace("[iAct BOOT] Shutdown completed successfully - all systems offline")
    EndIf
EndFunction
