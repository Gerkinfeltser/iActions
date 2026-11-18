Scriptname iActions_PlayAnimEffect extends ActiveMagicEffect
{Generic magic effect that plays drinking animations}

; === PROPERTIES ===
Bool Property VerboseLog = False Auto
{Enable debug logging}

; === WHEN SPELL STARTS: Play animation ===
Event OnEffectStart(Actor akTarget, Actor akCaster)
    If !akTarget
        Return
    EndIf

    ; Guard clause: Skip if actor is in incompatible state
    If akTarget.IsSwimming() || akTarget.IsDead() || akTarget.IsInCombat()
        If VerboseLog
            Debug.Trace("[iActions_PlayAnim] Actor in incompatible state, skipping")
        EndIf
        Return
    EndIf

    If VerboseLog
        Debug.Trace("[iActions_PlayAnim] Triggering animation for " + akTarget.GetDisplayName())
    EndIf

    ; Check if actor is using furniture FIRST
    ObjectReference furnitureRef = akTarget.GetFurnitureReference()

    If furnitureRef
        ; Actor is seated/leaning - DON'T interrupt (would make them stand)
        ; Just send seated drinking animation
        Debug.SendAnimationEvent(akTarget as ObjectReference, "ChairDrinkingStart")
        If VerboseLog
            Debug.Trace("[iActions_PlayAnim] Seated - sent ChairDrinkingStart")
        EndIf
    Else
        ; Actor is standing - interrupt ongoing animations (bard instruments, etc.)
        Debug.SendAnimationEvent(akTarget as ObjectReference, "IdleForceDefaultState")
        Utility.Wait(0.5)
        ; Now play drinking animation
        Debug.SendAnimationEvent(akTarget as ObjectReference, "IdleDrink")
        If VerboseLog
            Debug.Trace("[iActions_PlayAnim] Standing - interrupted and sent IdleDrink")
        EndIf
    EndIf
EndEvent

; === WHEN SPELL ENDS: Cleanup ===
Event OnEffectFinish(Actor akTarget, Actor akCaster)
    If VerboseLog && akTarget
        Debug.Trace("[iActions_PlayAnim] Animation complete for " + akTarget.GetDisplayName())
    EndIf
EndEvent
