; =============================================================================
; SkyrimNet iActions - Drunk Animation Module
; =============================================================================
; Handles animation playback for drinking and sobering actions.
; Manages furniture detection and OAR animation integration.
; =============================================================================
Scriptname iActions_DrunkAnimation extends Quest
Import PO3_SKSEFunctions
Import iActions_Lib

; Cross-script property (fill in CK/Spriggit)
iActions_DrunkCore Property Core Auto

; Animation properties (from ESP)
Idle Property IdleForceDefaultState Auto
Idle Property IdleDrink Auto
Idle Property IdleWipeBrow Auto
Spell Property PlayAnimSpell Auto

; =========================================================
; --- Animation Functions ---
; =========================================================

; === PlayAnimation ===
; Plays drinking animation using spell-based approach with OAR animations
Function PlayAnim(Actor akActor, Bool abSobering = False)
    ; Guard clause: animations disabled or invalid actor
    if !Core.EnableAnimations || !akActor
        return
    EndIf

    ; === SOBERING ANIMATION ===
    If abSobering
        If IdleForceDefaultState
            akActor.PlayIdle(IdleForceDefaultState)
            utility.wait(0.2)
        EndIf

        If IdleWipeBrow
            akActor.PlayIdle(IdleWipeBrow)
            utility.wait(2.0)
        EndIf
        Return
    EndIf

    ; === FURNITURE TYPE DETECTION ===
    ; Check if actor is using furniture and determine type
    ObjectReference furnitureRef = akActor.GetFurnitureReference()

    If furnitureRef
        ; Actor is using furniture - check type
        Furniture furnitureBase = furnitureRef.GetBaseObject() as Furniture

        If furnitureBase
            Int furnitureType = PO3_SKSEFunctions.GetFurnitureType(furnitureBase)

            ; If leaning (type 1) or perching (type 0 - barstools), stand up before animation
            If furnitureType == 1 || furnitureType == 0  ; Lean or Perch
                If Core.Lib.EnableDebugNotify
                    LogAlert(akActor.GetDisplayName() + " is on furniture type " + furnitureType + ", standing up first", True)
                EndIf
                Core.Lib.StopUsingFurniture(akActor)  ; Package override

                ; Wait for NPC to actually exit furniture before casting spell
                Int waitCount = 0
                While akActor.GetFurnitureReference() && waitCount < 10
                    Utility.Wait(0.1)
                    waitCount += 1
                EndWhile

                If Core.Lib.EnableDebugNotify
                    If !akActor.GetFurnitureReference()
                        LogAlert(akActor.GetDisplayName() + " successfully exited furniture", False)
                    Else
                        LogAlert(akActor.GetDisplayName() + " still using furniture after timeout", True)
                    EndIf
                EndIf
            ; Else if seated (type 2) or other, stay seated for seated animation
            ElseIf Core.Lib.EnableDebugNotify
                LogAlert(akActor.GetDisplayName() + " using furniture type " + furnitureType + " (seated), staying put", False)
            EndIf
        EndIf
    EndIf

    ; === DRINKING ANIMATION ===
    ; Note: Tankard prop handled by OAR animation, no manual equip needed

    ; Interrupt ongoing animations for standing NPCs (bards, idle anims, etc.)
    ; This clears blocking animations before the drinking spell triggers
    If !akActor.GetFurnitureReference() && IdleForceDefaultState
        If Core.Lib.EnableDebugNotify
            LogAlert(akActor.GetDisplayName() + " is standing, clearing ongoing animations", False)
        EndIf
        akActor.PlayIdle(IdleForceDefaultState)
        Utility.Wait(0.5)
    EndIf

    ; Cast spell to trigger OAR animation (handles seated/standing automatically)
    If PlayAnimSpell
        PlayAnimSpell.RemoteCast(akActor, akActor, akActor)
        utility.wait(5.0)  ; Match spell duration
        Return
    EndIf

    ; === FALLBACK: Native animation (if spell not available) ===
    If IdleForceDefaultState
        akActor.PlayIdle(IdleForceDefaultState)
        utility.wait(0.2)
    EndIf

    If IdleDrink
        akActor.PlayIdle(IdleDrink)
        utility.wait(2.0)
    EndIf
EndFunction
