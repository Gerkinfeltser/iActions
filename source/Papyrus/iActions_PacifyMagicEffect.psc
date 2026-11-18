; =============================================================================
; SkyrimNet iActions - Pacify MagicEffect
; =============================================================================
Scriptname iActions_PacifyMagicEffect extends ActiveMagicEffect
Faction Property PotentialFollowerFaction Auto ; 0005C84D

; === Properties ===
Bool Property _VerboseLog = False Auto
Int Property _FinalRelationshipRank = 1 Auto ; Sets to friend by default
Int Property _FinalAgressionValue = 0 Auto ; Sets to not agressive

; === Instance Variables ===
Actor _targetActor
Actor _player

; =============================================================================
; Helper Functions
; =============================================================================

Function LogActorState(String header, Actor targetActor)
    If !_VerboseLog || !targetActor
        Return
    EndIf
    
    Actor akPlayer = Game.GetPlayer()
    String msg = " ===\n" + header + "\n" + \
        "=== Target: " + targetActor.GetDisplayName() + "\n" + \
        "=== Aggression: " + targetActor.GetActorValue("Aggression") + "\n" + \
        "=== Relationship: " + targetActor.GetRelationshipRank(akPlayer) + "\n" + \
        "=== In Combat: " + targetActor.IsInCombat() + "\n" + \
        "=== Is Hostile: " + targetActor.IsHostileToActor(akPlayer) + "\n" + \
        "=== Is potential follower: " + targetActor.GetFactionRank(PotentialFollowerFaction)
    Debug.Trace(msg)
EndFunction

Function SetFriendship(Actor akActor, Bool abEvalPackage = False)
    _targetActor.StopCombat()
    _targetActor.StopCombatAlarm()
    akActor.SetAV("Aggression", _FinalAgressionValue)
    If akActor.GetRelationshipRank(_player) < _FinalRelationshipRank
        akActor.SetRelationshipRank(_player, _FinalRelationshipRank)
    EndIf
    
    ; Prevent them from being pulled into faction combat
    akActor.SetActorValue("Assistance", 0)  ; Won't help allies in combat
    
    If abEvalPackage
        akActor.EvaluatePackage()
    EndIf
    akActor.AddToFaction(PotentialFollowerFaction)
EndFunction

; =============================================================================
; Helper Functions
; =============================================================================

Event OnEffectStart(Actor akTarget, Actor akCaster)
    _targetActor = akTarget
    _player = Game.GetPlayer()
    if _targetActor == _player
        _targetActor = akCaster
    EndIf
    LogActorState("=== iACT_AOE_PACIFY OnEffectStart START ===", _targetActor)
    SetFriendship(_targetActor)

    LogActorState("=== iACT_AOE_PACIFY OnEffectStart END ===", _targetActor)
    RegisterForSingleUpdate(1.5)
EndEvent

Event OnUpdate()
    If _targetActor && !_targetActor.IsDead()
        SetFriendship(_targetActor)
    EndIf
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    SetFriendship(_targetActor, True)

    LogActorState("=== iACT_AOE_PACIFY OnEffectStart END ===", _targetActor)
    _targetActor = None
    _player = None
EndEvent
