; =============================================================================
; SkyrimNet iActions - MCM Configuration Menu
; =============================================================================
Scriptname iActions_MCM extends SKI_ConfigBase

Import SKI_ConfigBase

; === Properties ===
iActions_DrunkCore Property DrunkSystem Auto ; Fill in CK: Point to iActions_MainQuest
iActions_DrunkTracking Property Tracking Auto ; Fill in CK: Point to iActions_MainQuest
iActions_Lib Property Lib Auto ; Fill in CK: Point to iActions_MainQuest
iActions_Food Property FoodScript Auto ; Fill in CK: Point to iActions_MainQuest
Quest Property BootstrapQuest Auto ; Fill in CK: Point to Bootstrap Quest

; =========================================================
; STATE TRACKING
; =========================================================

; Drunk Behavior Page
Int _oidRequireAlcohol
Int _oidDisableAlcoholRequirementInInns
Int _oidPointsPerLevel
Int _oidPointsPerDrink
Int _oidEnableDrunkCap
Int _oidMaxDrunkMembers
Int _oidEnableAutoSobering
Int _oidMemberPollRate
Int _oidPointsPerDecay
Int _oidPointsPerSleepHour

; Controls & Interface Page
Int _oidForcePushKey
Int _oidRespondDirectlyToActions
Int _oidMaxTransfersToTrack
Int _oidDrinkAlcoholCooldown
Int _oidStumbleAndFallCooldown
Int _oidPacifyCooldown
Int _oidExchangeItemsCooldown
Int _oidEnableAutoTakeAlcohol
Int _oidNPCDrinksOnTheHouse

; Food System
Int _oidEnableAutoGiveFood
Int _oidAutoGiveMaxCount
Int _oidFoodTierPriority
Int _oidReceiveFoodCooldown

; Advanced & Maintenance Page (moved to Controls & Interface)
Int _oidEnableDebugNotify
Int _oidEnableAnimations
Int _oidEnablePerformanceLogging
Int _oidListDrunk
Int _oidClearAll
Int _oidScanFix
Int _oidUninstall
Int _oidResetCoreSettings

; =========================================================
; CONSTANTS
; =========================================================

String Property MOD_VERSION = "0.6.8" AutoReadOnly

Int Function GetVersion()
    Return 2
EndFunction

; =========================================================
; EVENTS - Initialization
; =========================================================

Event OnConfigInit()
    ModName = "iActions [Drunk+] for SkyrimNet"
    Pages = New String[2]
    Pages[0] = "Drunk Behavior"
    Pages[1] = "Configuration"

    Debug.Trace("[iAct MCM] Welcome to " + ModName + "...")

    ; Validation
    If !DrunkSystem
        Debug.MessageBox("SETUP ERROR: DrunkSystem property not filled!")
    EndIf
    If !Tracking
        Debug.MessageBox("SETUP ERROR: Tracking property not filled!")
    EndIf
    If !Lib
        Debug.MessageBox("SETUP ERROR: Lib property not filled!")
    EndIf
EndEvent

Event OnConfigOpen()
    ; Validate DrunkSystem reference
    If !DrunkSystem
        Debug.MessageBox("ERROR: iActions MCM cannot find DrunkSystem script!\nPlease reinstall the mod.")
        Return ; Don't proceed if system is broken
    EndIf
EndEvent

; =========================================================
; PAGES
; =========================================================

Event OnPageReset(String page)
    SetCursorFillMode(TOP_TO_BOTTOM)
    
    If page == "Drunk Behavior"
        DrawDrunkBehaviorPage()
    ElseIf page == "Configuration"
        DrawControlsInterfacePage()
    EndIf
EndEvent

Function DrawDrunkBehaviorPage()
    SetCursorFillMode(TOP_TO_BOTTOM)
    
    ; === LEFT COLUMN ===
    AddHeaderOption("Alcohol System")
    If DrunkSystem
        _oidRequireAlcohol = AddToggleOption("Require Alcohol in Inventory", DrunkSystem.RequireAlcohol)
    Else
        _oidRequireAlcohol = AddToggleOption("Require Alcohol in Inventory", True) ; Safe default
    EndIf
    
    ; Location-based alcohol requirement override
    If DrunkSystem
        Int flags = OPTION_FLAG_NONE
        If !DrunkSystem.RequireAlcohol
            flags = OPTION_FLAG_DISABLED
        EndIf
        _oidDisableAlcoholRequirementInInns = AddToggleOption("Disable Alcohol Requirement in Inns", DrunkSystem.DisableAlcoholRequirementInInns, flags)
    Else
        _oidDisableAlcoholRequirementInInns = AddToggleOption("Disable Alcohol Requirement in Inns", False, OPTION_FLAG_DISABLED)
    EndIf
    
    ; Auto-take alcohol setting (also disabled when Require Alcohol is off)
    If DrunkSystem
        Int flags = OPTION_FLAG_NONE
        If !DrunkSystem.RequireAlcohol
            flags = OPTION_FLAG_DISABLED
        EndIf
        _oidEnableAutoTakeAlcohol = AddToggleOption("Auto-Take Alcohol", DrunkSystem.EnableAutoTakeAlcohol, flags)
        _oidNPCDrinksOnTheHouse = AddToggleOption("NPC Drinks on the House", DrunkSystem.NPCDrinksOnTheHouse, flags)
    Else
        _oidEnableAutoTakeAlcohol = AddToggleOption("Auto-Take Alcohol", False, OPTION_FLAG_DISABLED)
        _oidNPCDrinksOnTheHouse = AddToggleOption("NPC Drinks on the House", False, OPTION_FLAG_DISABLED)
    EndIf
    If DrunkSystem
        _oidMaxDrunkMembers = AddSliderOption("Max Simultaneous Drunk NPCs", DrunkSystem.MaxDrunkMembers, "{0}")
    Else
        _oidMaxDrunkMembers = AddSliderOption("Max Simultaneous Drunk NPCs", 32, "{0}")
    EndIf
    AddEmptyOption()

    AddHeaderOption("Drunkness Decay System")
    If DrunkSystem
        _oidEnableAutoSobering = AddToggleOption("Auto-Sobering", DrunkSystem.EnableAutoSobering)
        _oidMemberPollRate = AddSliderOption("Polling Interval (seconds)", DrunkSystem.MemberPollRate, "{0}")
        _oidPointsPerDecay = AddSliderOption("Points Lost Per Cycle", DrunkSystem.PointsPerDecay, "{0}")
        _oidPointsPerSleepHour = AddSliderOption("Points Lost Per Sleep Hour", DrunkSystem.PointsPerSleepHour, "{0}")
    Else
        _oidEnableAutoSobering = AddToggleOption("Auto-Sobering", True)
        _oidMemberPollRate = AddSliderOption("Polling Interval (seconds)", 300.0, "{0}")
        _oidPointsPerDecay = AddSliderOption("Points Lost Per Cycle", 1, "{0}")
        _oidPointsPerSleepHour = AddSliderOption("Points Lost Per Sleep Hour", 4, "{0}")
    EndIf
    
    ; === SWITCH TO RIGHT COLUMN ===
    SetCursorPosition(1) ; Move to right column
    
    AddHeaderOption("Drunk Progression")
    If DrunkSystem
        _oidPointsPerLevel = AddSliderOption("Points Per Drunk Category", DrunkSystem.PointsPerLevel, "{0}")
        _oidPointsPerDrink = AddSliderOption("Points Per Drink", DrunkSystem.PointsPerDrink, "{0}")
        _oidEnableDrunkCap = AddToggleOption("Enable Drunk Level Cap", DrunkSystem.EnableDrunkCap)
    Else
        _oidPointsPerLevel = AddSliderOption("Points Per Drunk Category", 2, "{0}")
        _oidPointsPerDrink = AddSliderOption("Points Per Drink", 2, "{0}")
        _oidEnableDrunkCap = AddToggleOption("Enable Drunk Level Cap", True)
    EndIf
    AddEmptyOption()
    
    AddHeaderOption("Drunk Level Guide")
    If DrunkSystem
        Int pointsPerLevel = DrunkSystem.PointsPerLevel
        Int maxDrunkLevel = DrunkSystem.MaxDrunkLevel
        Bool enableDrunkCap = DrunkSystem.EnableDrunkCap

        ; Buzzed is always Rank 0 only, then each category gets pointsPerLevel ranks
        AddTextOption("Buzzed Range", "0 (first drink)", OPTION_FLAG_DISABLED)
        AddTextOption("Tipsy Range", "1 to " + pointsPerLevel, OPTION_FLAG_DISABLED)
        AddTextOption("Drunk Range", (pointsPerLevel + 1) + " to " + (pointsPerLevel * 2), OPTION_FLAG_DISABLED)
        AddTextOption("Plastered Range", (pointsPerLevel * 2 + 1) + " to " + (pointsPerLevel * 3), OPTION_FLAG_DISABLED)

        ; Show accurate Black-out Range based on cap setting
        String blackoutRangeText
        If enableDrunkCap
            Int maxRank = maxDrunkLevel * pointsPerLevel
            Int blackoutStart = pointsPerLevel * 3 + 1
            If blackoutStart <= maxRank
                blackoutRangeText = blackoutStart + " to " + maxRank
            Else
                blackoutRangeText = "N/A (capped too low)"
            EndIf
        Else
            blackoutRangeText = (pointsPerLevel * 3 + 1) + "+"
        EndIf
        AddTextOption("Black-out Range", blackoutRangeText, OPTION_FLAG_DISABLED)
    Else
        AddTextOption("System Status", "ERROR: System not initialized", OPTION_FLAG_DISABLED)
    EndIf
EndFunction

Function DrawControlsInterfacePage()
    SetCursorFillMode(TOP_TO_BOTTOM)

    ; === LEFT COLUMN ===
    AddHeaderOption("Food System")
    If FoodScript
        _oidEnableAutoGiveFood = AddToggleOption("Auto-Give Food", FoodScript.EnableAutoGiveFood)
        _oidAutoGiveMaxCount = AddSliderOption("Auto-Give Max Food Items", FoodScript.AutoGiveMaxCount, "{0}")
        String[] tierLabels = New String[4]
        tierLabels[0] = "Large > Medium > Small"
        tierLabels[1] = "Medium > Large > Small"
        tierLabels[2] = "Small > Medium > Large"
        tierLabels[3] = "Medium > Small > Large"
        _oidFoodTierPriority = AddMenuOption("Food Preference Order", tierLabels[FoodScript.FoodTierPriority])
    Else
        _oidEnableAutoGiveFood = AddToggleOption("Auto-Give Food", False)
        _oidAutoGiveMaxCount = AddSliderOption("Auto-Give Max Food Items", 5, "{0}")
        _oidFoodTierPriority = AddMenuOption("Food Preference Order", "Large > Medium > Small")
    EndIf
    AddEmptyOption()

    AddHeaderOption("Misc.")
    If Lib
        _oidForcePushKey = AddKeyMapOption("Force Push Key", Lib.ForcePushKeyCode)
    Else
        _oidForcePushKey = AddKeyMapOption("Force Push Key", -1)
    EndIf

    If Lib
        _oidRespondDirectlyToActions = AddToggleOption("Respond Directly to Actions", Lib.RespondDirectlyToActions)
    Else
        _oidRespondDirectlyToActions = AddToggleOption("Respond Directly to Actions", False)
    EndIf

    ; Add Max Transfers to Track setting
    If Lib
        _oidMaxTransfersToTrack = AddSliderOption("Max Exchange Item Types Tracked", Lib.MaxTransfersToTrack, "{0}")
    Else
        _oidMaxTransfersToTrack = AddSliderOption("Max Exchange Item Types Tracked", 20, "{0}")
    EndIf
    AddEmptyOption()

    AddHeaderOption("Action Cooldowns")
    If Lib
        _oidDrinkAlcoholCooldown = AddSliderOption("Drink Alcohol Cooldown (seconds)", Lib.DrinkAlcoholCooldown, "{0}")
        _oidStumbleAndFallCooldown = AddSliderOption("Stumble & Fall Cooldown (seconds)", Lib.StumbleAndFallCooldown, "{0}")
        _oidPacifyCooldown = AddSliderOption("Pacify Cooldown (seconds)", Lib.PacifyCooldown, "{0}")
        _oidExchangeItemsCooldown = AddSliderOption("Exchange Items Cooldown (seconds)", Lib.ExchangeCooldown, "{0}")
    Else
        _oidDrinkAlcoholCooldown = AddSliderOption("Drink Alcohol Cooldown (seconds)", 20, "{0}")
        _oidStumbleAndFallCooldown = AddSliderOption("Stumble & Fall Cooldown (seconds)", 20, "{0}")
        _oidPacifyCooldown = AddSliderOption("Pacify Cooldown (seconds)", 20, "{0}")
        _oidExchangeItemsCooldown = AddSliderOption("Exchange Items Cooldown (seconds)", 20, "{0}")
    EndIf
    If FoodScript
        _oidReceiveFoodCooldown = AddSliderOption("Receive Food Cooldown (seconds)", FoodScript.ReceiveFoodCooldown, "{0}")
    Else
        _oidReceiveFoodCooldown = AddSliderOption("Receive Food Cooldown (seconds)", 20, "{0}")
    EndIf
    AddEmptyOption()
    
    ; === SWITCH TO RIGHT COLUMN ===
    SetCursorPosition(1) ; Move to right column
    
    AddHeaderOption("Debug Functions")
    If Lib
        _oidEnableDebugNotify = AddToggleOption("Enable Debug Notifications", Lib.EnableDebugNotify)
    Else
        _oidEnableDebugNotify = AddToggleOption("Enable Debug Notifications", False) ; Safe default
    EndIf
    If Lib
        _oidEnablePerformanceLogging = AddToggleOption("Enable Performance Logging", Lib.EnablePerformanceLogging)
    Else
        _oidEnablePerformanceLogging = AddToggleOption("Enable Performance Logging", False)
    EndIf
    If DrunkSystem
        _oidEnableAnimations = AddToggleOption("Enable Drink Animations", DrunkSystem.EnableAnimations)
    Else
        _oidEnableAnimations = AddToggleOption("Enable Drink Animations", True)
    EndIf
    _oidListDrunk = AddTextOption("List All Drunk NPCs", "Click to Execute")
    _oidScanFix = AddTextOption("Scan & Fix Orphaned Drunks", "Click to Execute")
    AddEmptyOption()
    
    AddHeaderOption("Mod Management (Caution!)")
    _oidClearAll = AddTextOption("Clear All Drunk NPCs", "Click to Execute", OPTION_FLAG_WITH_UNMAP)
    _oidResetCoreSettings = AddTextOption("Reset Core Settings", "Click to Execute", OPTION_FLAG_WITH_UNMAP)
    _oidUninstall = AddTextOption("Prepare for Uninstall", "Click to Execute", OPTION_FLAG_WITH_UNMAP)
    AddTextOption("", "NOTE: Sobers all NPCs first", OPTION_FLAG_DISABLED)
    AddEmptyOption()
EndFunction


; =========================================================
; EVENTS - Option Selection
; =========================================================

Event OnOptionSelect(Int option)
    If !DrunkSystem || !Lib
        ShowMessage("Error: System not initialized. Please reload save.", False, "$OK")
        Return
    EndIf
    
    If option == _oidRequireAlcohol
        DrunkSystem.RequireAlcohol = !DrunkSystem.RequireAlcohol
        SetToggleOptionValue(option, DrunkSystem.RequireAlcohol)
        ; Update the effective requirement immediately
        DrunkSystem.UpdatePlayerInInnStatus()
        ; Force page reset to update disabled state of location toggle
        ForcePageReset()
        
    ElseIf option == _oidDisableAlcoholRequirementInInns
        DrunkSystem.DisableAlcoholRequirementInInns = !DrunkSystem.DisableAlcoholRequirementInInns
        SetToggleOptionValue(option, DrunkSystem.DisableAlcoholRequirementInInns)
        ; Update the effective requirement immediately
        DrunkSystem.UpdatePlayerInInnStatus()
        If DrunkSystem.DisableAlcoholRequirementInInns
            Debug.Notification("[iAct MCM] Alcohol requirement disabled in inns")
        Else
            Debug.Notification("[iAct MCM] Alcohol requirement enabled in inns")
        EndIf
        
    ElseIf option == _oidEnableAutoSobering
        DrunkSystem.EnableAutoSobering = !DrunkSystem.EnableAutoSobering
        SetToggleOptionValue(option, DrunkSystem.EnableAutoSobering)
        ; Immediately manage polling state
        If !DrunkSystem.EnableAutoSobering
            ; Stop polling immediately if disabling
            Tracking.UnregisterForUpdate()
            If Lib.EnableDebugNotify
                Debug.Notification("[iAct MCM] Auto-sobering disabled - polling stopped")
            EndIf
        Else
            ; Start polling immediately if enabling and there are drunk members
            Tracking.CheckAndManageUpdates()
            If Lib.EnableDebugNotify
                Debug.Notification("[iAct MCM] Auto-sobering enabled - polling started")
            EndIf
        EndIf
        
    ElseIf option == _oidEnableDebugNotify
        Lib.EnableDebugNotify = !Lib.EnableDebugNotify
        SetToggleOptionValue(option, Lib.EnableDebugNotify)
        If Lib.EnableDebugNotify
            Debug.Notification("[iAct MCM] Debug notifications enabled")
        Else
            Debug.Notification("[iAct MCM] Debug notifications disabled")
        EndIf
        
    ElseIf option == _oidEnableAnimations
        DrunkSystem.EnableAnimations = !DrunkSystem.EnableAnimations
        SetToggleOptionValue(option, DrunkSystem.EnableAnimations)
        If DrunkSystem.EnableAnimations
            Debug.Notification("[iAct MCM] Drink animations enabled")
        Else
            Debug.Notification("[iAct MCM] Drink animations disabled - performance mode")
        EndIf

    ElseIf option == _oidEnablePerformanceLogging
        Lib.EnablePerformanceLogging = !Lib.EnablePerformanceLogging
        SetToggleOptionValue(option, Lib.EnablePerformanceLogging)
        If Lib.EnablePerformanceLogging
            Debug.Notification("[iAct MCM] Performance logging enabled - check Papyrus logs")
            Debug.Trace("[iActions PERF] Performance logging has been ENABLED via MCM", 0)
        Else
            Debug.Notification("[iAct MCM] Performance logging disabled")
            Debug.Trace("[iActions PERF] Performance logging has been DISABLED via MCM", 0)
        EndIf

    ElseIf option == _oidEnableDrunkCap
        Bool currentState = DrunkSystem.EnableDrunkCap
        Bool newState = !currentState
        
        ; Show confirmation dialog when enabling the cap (OFF -> ON)
        If newState && !currentState
            String confirmMsg = "Enabling the drunk level cap will reduce any NPCs currently over the maximum drunk level to the cap limit.\n\n"
            confirmMsg += "This cannot be undone without manually getting NPCs drunk again.\n\n"
            confirmMsg += "Continue with enabling the cap?"
            
            Bool confirm = ShowMessage(confirmMsg, True, "Enable Cap", "Cancel")
            If confirm
                ; User confirmed - enable the cap and reduce over-limit NPCs
                DrunkSystem.EnableDrunkCap = True
                SetToggleOptionValue(option, True)
                ForcePageReset() ; Refresh the drunk level guide display
                
                ; Reduce any NPCs that are currently over the limit
                DrunkSystem.CapExistingDrunkNPCs()
                
                Debug.Notification("[iAct MCM] Drunk level cap enabled - over-limit NPCs reduced")
            Else
                ; User cancelled - don't change the setting
                Debug.Notification("[iAct MCM] Drunk level cap remains disabled")
            EndIf
        Else
            ; Disabling the cap (ON -> OFF) - no confirmation needed
            DrunkSystem.EnableDrunkCap = newState
            SetToggleOptionValue(option, newState)
            ForcePageReset() ; Refresh the drunk level guide display
            If newState
                Debug.Notification("[iAct MCM] Drunk level cap enabled")
            Else
                Debug.Notification("[iAct MCM] Drunk level cap disabled - unlimited progression")
            EndIf
        EndIf
        
    ElseIf option == _oidEnableAutoTakeAlcohol
        DrunkSystem.EnableAutoTakeAlcohol = !DrunkSystem.EnableAutoTakeAlcohol
        SetToggleOptionValue(option, DrunkSystem.EnableAutoTakeAlcohol)
        If DrunkSystem.EnableAutoTakeAlcohol
            Debug.Notification("[iAct MCM] Auto-take alcohol enabled")
        Else
            Debug.Notification("[iAct MCM] Manual alcohol selection enabled - inventory will open")
        EndIf
        
    ElseIf option == _oidNPCDrinksOnTheHouse
        DrunkSystem.NPCDrinksOnTheHouse = !DrunkSystem.NPCDrinksOnTheHouse
        SetToggleOptionValue(option, DrunkSystem.NPCDrinksOnTheHouse)

    ElseIf option == _oidRespondDirectlyToActions
        Lib.RespondDirectlyToActions = !Lib.RespondDirectlyToActions
        SetToggleOptionValue(option, Lib.RespondDirectlyToActions)
        If Lib.RespondDirectlyToActions
            Debug.Notification("[iAct MCM] Direct action responses enabled")
        Else
            Debug.Notification("[iAct MCM] Direct action responses disabled")
        EndIf

    ElseIf option == _oidEnableAutoGiveFood
        FoodScript.EnableAutoGiveFood = !FoodScript.EnableAutoGiveFood
        SetToggleOptionValue(option, FoodScript.EnableAutoGiveFood)
        If FoodScript.EnableAutoGiveFood
            Debug.Notification("[iAct MCM] Auto-give food enabled")
        Else
            Debug.Notification("[iAct MCM] Auto-give food disabled - dialog will prompt")
        EndIf
        
    ElseIf option == _oidListDrunk
        SetTextOptionValue(option, "Executing...", False)
        DrunkSystem.ListDrunkMembersNotify()
        SetTextOptionValue(option, "Click to Execute", False)
        
    ElseIf option == _oidClearAll
        Bool confirm = ShowMessage("This will immediately sober ALL drunk NPCs.\n\nAre you sure?", True, "$Yes", "$No")
        If confirm
            SetTextOptionValue(option, "Executing...", False)
            DrunkSystem.ClearAllDrunkMembersNotify()
            SetTextOptionValue(option, "Click to Execute", False)
        EndIf
        
    ElseIf option == _oidScanFix
        SetTextOptionValue(option, "Executing...", False)
        DrunkSystem.ScanAndFixOrphanedDrunksNotify()
        SetTextOptionValue(option, "Click to Execute", False)
        
    ElseIf option == _oidUninstall
        Bool confirm = ShowMessage("This will prepare the mod for safe uninstallation.\nAll drunk NPCs will be sobered and all quests will be stopped.\n\nContinue?", True, "$Yes", "$No")
        If confirm
            SetTextOptionValue(option, "Executing...", False)
            
            ; Get Bootstrap alias from quest and call Shutdown
            If BootstrapQuest
                ; Get the alias by name (more reliable than ID)
                iActions_BootstrapAlias bootstrapScript = BootstrapQuest.GetAliasByName("BootstrapAlias") as iActions_BootstrapAlias
                
                If bootstrapScript
                    bootstrapScript.Shutdown()
                    SetTextOptionValue(option, "Done - Safe to Disable", False)
                    ShowMessage("Uninstall complete.\nSave your game, exit Skyrim completely, then disable the mod ESP in MO2.", False, "$OK")
                Else
                    SetTextOptionValue(option, "ERROR - Script Not Found", False)
                    ShowMessage("ERROR: Could not get BootstrapAlias from quest. Ensure the alias exists and has the script attached.", False, "$OK")
                EndIf
            Else
                SetTextOptionValue(option, "ERROR - Quest None", False)
                ShowMessage("ERROR: BootstrapQuest property is None. Ensure it's filled in CK.", False, "$OK")
            EndIf
        EndIf
        
    ElseIf option == _oidResetCoreSettings
        String settingsList = "The following settings will be reset to defaults:\n\n"
        settingsList += "- Require Alcohol: True\n"
        settingsList += "- Disable Alcohol Requirement in Inns: False\n"
        settingsList += "- Auto-Sobering: True\n"
        settingsList += "- Polling Interval: 300 seconds\n"
        settingsList += "- Points Per Level: 2\n"
        settingsList += "- Points Per Drink: 2\n"
        settingsList += "- Points Per Decay: 1\n"
        settingsList += "- Max Drunk Members: 32\n"
        settingsList += "- Drink Alcohol Cooldown: 20 seconds\n"
        settingsList += "- Stumble & Fall Cooldown: 20 seconds\n"
        settingsList += "- Pacify Cooldown: 20 seconds\n"
        settingsList += "- Exchange Items Cooldown: 20 seconds\n"
        settingsList += "- Max Exchange Item Types Tracked: 20 item types\n"
        settingsList += "- Auto-Give Food: False\n"
        settingsList += "- Auto-Give Max Food Items: 5\n"
        settingsList += "- Food Preference Order: Large > Medium > Small\n"
        settingsList += "- Receive Food Cooldown: 20 seconds\n"
        settingsList += "- Force Push Key: Unbound\n"
        settingsList += "- Respond Directly to Actions: True\n"
        settingsList += "- Enable Debug Notifications: False\n\n"
        settingsList += "This cannot be undone. Continue?"
        
        Bool confirm = ShowMessage(settingsList, True, "Reset All", "Cancel")
        If confirm
            SetTextOptionValue(option, "Resetting...", False)
            ResetAllCoreSettings()
            SetTextOptionValue(option, "Click to Execute", False)
            ShowMessage("All core settings have been reset to defaults.", False, "$OK")
            ForcePageReset() ; Refresh the display
        EndIf
    EndIf
EndEvent

Event OnOptionKeyMapChange(Int option, Int keyCode, String conflictControl, String conflictName)
    If !Lib
        ShowMessage("Error: System not initialized. Please reload save.", False, "$OK")
        Return
    EndIf
    
    If option == _oidForcePushKey
        Bool continue = True
        
        If keyCode != -1 && conflictControl != ""
            String msg = "This key is already mapped to:\n" + conflictControl
            If conflictName != ""
                msg += "\n(" + conflictName + ")"
            EndIf
            msg += "\n\nAre you sure you want to continue?"
            continue = ShowMessage(msg, True, "$Yes", "$No")
        EndIf
        
        If continue
            Lib.ForcePushKeyCode = keyCode
            ; Only call UpdateKeyRegistration if Lib is valid
            If Lib
                Lib.UpdateKeyRegistration()
            EndIf
            SetKeyMapOptionValue(option, keyCode)
            
            If keyCode == -1
                Debug.Notification("Force Push key unbound")
            Else
                Debug.Notification("Force Push key set")
            EndIf
        EndIf
    EndIf
EndEvent

Event OnOptionDefault(Int option)
    If !DrunkSystem || !Lib
        ShowMessage("Error: System not initialized. Please reload save.", False, "$OK")
        Return
    EndIf
    
    If option == _oidRequireAlcohol
        DrunkSystem.RequireAlcohol = True
        SetToggleOptionValue(option, True)
        
    ElseIf option == _oidDisableAlcoholRequirementInInns
        DrunkSystem.DisableAlcoholRequirementInInns = False
        SetToggleOptionValue(option, False)
        
    ElseIf option == _oidEnableAutoSobering
        DrunkSystem.EnableAutoSobering = True
        SetToggleOptionValue(option, True)
        
    ElseIf option == _oidEnableDebugNotify
        Lib.EnableDebugNotify = False
        SetToggleOptionValue(option, False)
        
    ElseIf option == _oidEnableAnimations
        DrunkSystem.EnableAnimations = True
        SetToggleOptionValue(option, True)

    ElseIf option == _oidEnablePerformanceLogging
        Lib.EnablePerformanceLogging = False
        SetToggleOptionValue(option, False)

    ElseIf option == _oidEnableDrunkCap
        DrunkSystem.EnableDrunkCap = True
        SetToggleOptionValue(option, True)
        
    ElseIf option == _oidEnableAutoTakeAlcohol
        DrunkSystem.EnableAutoTakeAlcohol = False
        SetToggleOptionValue(option, False)

    ElseIf option == _oidNPCDrinksOnTheHouse
        DrunkSystem.NPCDrinksOnTheHouse = False
        SetToggleOptionValue(option, False)
        
    ElseIf option == _oidRespondDirectlyToActions
        Lib.RespondDirectlyToActions = True
        SetToggleOptionValue(option, True)
        
    ElseIf option == _oidMemberPollRate
        DrunkSystem.MemberPollRate = 300.0
        SetSliderOptionValue(option, 300.0, "{0}")
        RestartPolling()
        
    ElseIf option == _oidPointsPerLevel
        DrunkSystem.PointsPerLevel = 2
        SetSliderOptionValue(option, 2, "{0}")
        ; Reset all drunk NPCs to sober when resetting points per level
        DrunkSystem.ClearAllDrunkMembers()
        If Lib.EnableDebugNotify
            Debug.Notification("[iAct MCM] Points per level reset - all drunk NPCs reset to sober")
        EndIf
        ForcePageReset() ; Refresh info display
        
    ElseIf option == _oidPointsPerDrink
        DrunkSystem.PointsPerDrink = 2
        SetSliderOptionValue(option, 2, "{0}")
        
    ElseIf option == _oidPointsPerDecay
        DrunkSystem.PointsPerDecay = 1
        SetSliderOptionValue(option, 1, "{0}")

    ElseIf option == _oidPointsPerSleepHour
        DrunkSystem.PointsPerSleepHour = 4
        SetSliderOptionValue(option, 4, "{0}")
        
    ElseIf option == _oidDrinkAlcoholCooldown
        Lib.DrinkAlcoholCooldown = 20
        SetSliderOptionValue(option, 20, "{0}")
        ; Update SkyrimNet cooldown
        SkyrimNetAPI.SetActionCooldown("drink_alcohol", 20)
        
    ElseIf option == _oidStumbleAndFallCooldown
        Lib.StumbleAndFallCooldown = 20
        SetSliderOptionValue(option, 20, "{0}")
        ; Update SkyrimNet cooldown  
        SkyrimNetAPI.SetActionCooldown("stumble_and_fall", 20)
        
    ElseIf option == _oidPacifyCooldown
        Lib.PacifyCooldown = 20
        SetSliderOptionValue(option, 20, "{0}")
        ; Update SkyrimNet cooldown
        SkyrimNetAPI.SetActionCooldown("aggressively_comply", 20)

    ElseIf option == _oidExchangeItemsCooldown
        Lib.ExchangeCooldown = 20
        SetSliderOptionValue(option, 20, "{0}")
        ; Update SkyrimNet cooldown
        SkyrimNetAPI.SetActionCooldown("exchange_items", 20)

    ElseIf option == _oidMaxTransfersToTrack
        Lib.MaxTransfersToTrack = 20
        SetSliderOptionValue(option, 20, "{0}")

    ElseIf option == _oidForcePushKey
        Lib.ForcePushKeyCode = -1  ; Default to unbound
        If Lib
            Lib.UpdateKeyRegistration()
        EndIf
        SetKeyMapOptionValue(option, -1)
        Debug.Notification("Force Push key unbound")

    ElseIf option == _oidEnableAutoGiveFood
        FoodScript.EnableAutoGiveFood = False
        SetToggleOptionValue(option, False)

    ElseIf option == _oidAutoGiveMaxCount
        FoodScript.AutoGiveMaxCount = 5
        SetSliderOptionValue(option, 5, "{0}")

    ElseIf option == _oidFoodTierPriority
        FoodScript.FoodTierPriority = 0
        SetMenuOptionValue(option, "Large > Medium > Small")

    ElseIf option == _oidReceiveFoodCooldown
        FoodScript.ReceiveFoodCooldown = 20
        SetSliderOptionValue(option, 20, "{0}")
        SkyrimNetAPI.SetActionCooldown("receive_food", 20)

    ElseIf option == _oidMaxDrunkMembers
        DrunkSystem.MaxDrunkMembers = 32
        SetSliderOptionValue(option, 32, "{0}")
    EndIf
EndEvent

Event OnOptionSliderOpen(Int option)
    If !DrunkSystem || !Lib
        ShowMessage("Error: System not initialized. Please reload save.", False, "$OK")
        Return
    EndIf

    If option == _oidMemberPollRate
        SetSliderDialogStartValue(DrunkSystem.MemberPollRate)
        SetSliderDialogDefaultValue(300.0)
        SetSliderDialogRange(20.0, 600.0)
        SetSliderDialogInterval(20.0)

    ElseIf option == _oidPointsPerLevel
        SetSliderDialogStartValue(DrunkSystem.PointsPerLevel)
        SetSliderDialogDefaultValue(2)
        SetSliderDialogRange(1, 10)
        SetSliderDialogInterval(1)

    ElseIf option == _oidPointsPerDrink
        SetSliderDialogStartValue(DrunkSystem.PointsPerDrink)
        SetSliderDialogDefaultValue(2)
        SetSliderDialogRange(1, 10)
        SetSliderDialogInterval(1)

    ElseIf option == _oidPointsPerDecay
        SetSliderDialogStartValue(DrunkSystem.PointsPerDecay)
        SetSliderDialogDefaultValue(1)
        SetSliderDialogRange(1, 10)
        SetSliderDialogInterval(1)

    ElseIf option == _oidPointsPerSleepHour
        SetSliderDialogStartValue(DrunkSystem.PointsPerSleepHour)
        SetSliderDialogDefaultValue(4)
        SetSliderDialogRange(0, 40)
        SetSliderDialogInterval(1)

    ElseIf option == _oidDrinkAlcoholCooldown
        SetSliderDialogStartValue(Lib.DrinkAlcoholCooldown)
        SetSliderDialogDefaultValue(20)
        SetSliderDialogRange(1, 300)
        SetSliderDialogInterval(1)

    ElseIf option == _oidStumbleAndFallCooldown
        SetSliderDialogStartValue(Lib.StumbleAndFallCooldown)
        SetSliderDialogDefaultValue(20)
        SetSliderDialogRange(1, 300)
        SetSliderDialogInterval(1)

    ElseIf option == _oidPacifyCooldown
        SetSliderDialogStartValue(Lib.PacifyCooldown)
        SetSliderDialogDefaultValue(20)
        SetSliderDialogRange(1, 300)
        SetSliderDialogInterval(1)

    ElseIf option == _oidExchangeItemsCooldown
        SetSliderDialogStartValue(Lib.ExchangeCooldown)
        SetSliderDialogDefaultValue(20)
        SetSliderDialogRange(1, 300)
        SetSliderDialogInterval(1)

    ElseIf option == _oidMaxTransfersToTrack
        SetSliderDialogStartValue(Lib.MaxTransfersToTrack)
        SetSliderDialogDefaultValue(20)
        SetSliderDialogRange(10, 200)
        SetSliderDialogInterval(5)

    ElseIf option == _oidMaxDrunkMembers
        SetSliderDialogStartValue(DrunkSystem.MaxDrunkMembers)
        SetSliderDialogDefaultValue(32)
        SetSliderDialogRange(8, 128)
        SetSliderDialogInterval(4)

    ElseIf option == _oidAutoGiveMaxCount
        SetSliderDialogStartValue(FoodScript.AutoGiveMaxCount)
        SetSliderDialogDefaultValue(5)
        SetSliderDialogRange(1, 20)
        SetSliderDialogInterval(1)

    ElseIf option == _oidReceiveFoodCooldown
        SetSliderDialogStartValue(FoodScript.ReceiveFoodCooldown)
        SetSliderDialogDefaultValue(20)
        SetSliderDialogRange(1, 300)
        SetSliderDialogInterval(1)
    EndIf
EndEvent

Event OnOptionSliderAccept(Int option, Float value)
    If !DrunkSystem || !Lib
        ShowMessage("Error: System not initialized. Please reload save.", False, "$OK")
        Return
    EndIf

    If option == _oidMemberPollRate
        DrunkSystem.MemberPollRate = value
        SetSliderOptionValue(option, value, "{0}")
        RestartPolling()

    ElseIf option == _oidPointsPerLevel
        DrunkSystem.PointsPerLevel = value as Int
        SetSliderOptionValue(option, value, "{0}")
        ; Reset all drunk NPCs to sober when points per level changes
        DrunkSystem.ClearAllDrunkMembers()
        If Lib.EnableDebugNotify
            Debug.Notification("[iAct MCM] Points per level changed - all drunk NPCs reset to sober")
        EndIf
        ForcePageReset() ; Refresh info display

    ElseIf option == _oidPointsPerDrink
        DrunkSystem.PointsPerDrink = value as Int
        SetSliderOptionValue(option, value, "{0}")

    ElseIf option == _oidPointsPerDecay
        DrunkSystem.PointsPerDecay = value as Int
        SetSliderOptionValue(option, value, "{0}")

    ElseIf option == _oidPointsPerSleepHour
        DrunkSystem.PointsPerSleepHour = value as Int
        SetSliderOptionValue(option, value, "{0}")

    ElseIf option == _oidDrinkAlcoholCooldown
        Lib.DrinkAlcoholCooldown = value as Int
        SetSliderOptionValue(option, value, "{0}")
        ; Update SkyrimNet cooldown immediately
        SkyrimNetAPI.SetActionCooldown("drink_alcohol", value as Int)

    ElseIf option == _oidStumbleAndFallCooldown
        Lib.StumbleAndFallCooldown = value as Int
        SetSliderOptionValue(option, value, "{0}")
        ; Update SkyrimNet cooldown immediately
        SkyrimNetAPI.SetActionCooldown("stumble_and_fall", value as Int)

    ElseIf option == _oidPacifyCooldown
        Lib.PacifyCooldown = value as Int
        SetSliderOptionValue(option, value, "{0}")
        ; Update SkyrimNet cooldown immediately
        SkyrimNetAPI.SetActionCooldown("aggressively_comply", value as Int)

    ElseIf option == _oidExchangeItemsCooldown
        Lib.ExchangeCooldown = value as Int
        SetSliderOptionValue(option, value, "{0}")
        ; Update SkyrimNet cooldown immediately
        SkyrimNetAPI.SetActionCooldown("exchange_items", value as Int)

    ElseIf option == _oidMaxTransfersToTrack
        Lib.MaxTransfersToTrack = value as Int
        SetSliderOptionValue(option, value, "{0}")
        If Lib.EnableDebugNotify
            Debug.Notification("[iAct MCM] Max exchange item types tracked set to " + (value as Int))
        EndIf

    ElseIf option == _oidMaxDrunkMembers
        DrunkSystem.MaxDrunkMembers = value as Int
        SetSliderOptionValue(option, value, "{0}")

    ElseIf option == _oidAutoGiveMaxCount
        FoodScript.AutoGiveMaxCount = value as Int
        SetSliderOptionValue(option, value, "{0}")

    ElseIf option == _oidReceiveFoodCooldown
        FoodScript.ReceiveFoodCooldown = value as Int
        SetSliderOptionValue(option, value, "{0}")
        SkyrimNetAPI.SetActionCooldown("receive_food", value as Int)
    EndIf
EndEvent

Event OnOptionMenuOpen(Int option)
    If option == _oidFoodTierPriority
        SetMenuDialogStartIndex(FoodScript.FoodTierPriority)
        SetMenuDialogDefaultIndex(0)
        String[] tierLabels = New String[4]
        tierLabels[0] = "Large > Medium > Small"
        tierLabels[1] = "Medium > Large > Small"
        tierLabels[2] = "Small > Medium > Large"
        tierLabels[3] = "Medium > Small > Large"
        SetMenuDialogOptions(tierLabels)
    EndIf
EndEvent

Event OnOptionMenuAccept(Int option, Int index)
    If option == _oidFoodTierPriority
        FoodScript.FoodTierPriority = index
        String[] tierLabels = New String[4]
        tierLabels[0] = "Large > Medium > Small"
        tierLabels[1] = "Medium > Large > Small"
        tierLabels[2] = "Small > Medium > Large"
        tierLabels[3] = "Medium > Small > Large"
        SetMenuOptionValue(option, tierLabels[index])
    EndIf
EndEvent

Event OnOptionHighlight(Int option)
    If option == _oidRequireAlcohol
        SetInfoText("NPCs must have alcohol in inventory to get drunk")
    ElseIf option == _oidDisableAlcoholRequirementInInns
        SetInfoText("When enabled, NPCs don't need alcohol to get drunk while in inns/taverns. Automatically disabled when 'Require Alcohol' is off.")
    ElseIf option == _oidEnableDebugNotify
        SetInfoText("Debug: Enable debug notifications for all iActions systems (drunk levels, setting changes, actions, etc.)")
    ElseIf option == _oidEnableAnimations
        SetInfoText("Enable drinking/sobering animations. Disable if experiencing lag/freezing when NPCs drink (animations include 3s of delays)")
    ElseIf option == _oidEnablePerformanceLogging
        SetInfoText("Debug: Logs execution time for key functions to Papyrus logs (independent of debug notifications). Use for performance optimization only. Default: Off")
    ElseIf option == _oidEnableAutoSobering
        SetInfoText("When enabled, drunk NPCs gradually sober up over time. When disabled, NPCs stay drunk until manually sobered.")
    ElseIf option == _oidMemberPollRate
        SetInfoText("How often the decay system checks drunk NPCs (20-600 seconds)")
    ElseIf option == _oidPointsPerLevel
        SetInfoText("Points needed to advance to next drunk category (1-10) - Changes reset existing drunk NPCs")
    ElseIf option == _oidPointsPerDrink
        SetInfoText("Points added each time NPC drinks (1-10) - Applies immediately to new drinks")
    ElseIf option == _oidPointsPerDecay
        SetInfoText("Points removed per polling cycle (1-10) - Applies to next decay cycle")
    ElseIf option == _oidPointsPerSleepHour
        SetInfoText("Points deducted per hour slept (0-40, 0 = disabled). Default 4 means 8hr sleep = 32 points lost.")
    ElseIf option == _oidDrinkAlcoholCooldown
        SetInfoText("Time between drink actions for same NPC (1-300 seconds) - Tied to 'drink_alcohol' action. Applies immediately")
    ElseIf option == _oidStumbleAndFallCooldown
        SetInfoText("Time between stumble actions for same NPC (1-300 seconds) - Tied to 'stumble_and_fall' action. Applies immediately")
    ElseIf option == _oidPacifyCooldown
        SetInfoText("Time between pacify actions for same NPC (1-300 seconds) - Tied to 'aggressively_comply' action. Applies immediately")
    ElseIf option == _oidExchangeItemsCooldown
        SetInfoText("Time between item exchange actions for the same NPC (1-300 seconds) - Tied to 'exchange_items' action. Applies immediately")
    ElseIf option == _oidMaxTransfersToTrack
        SetInfoText("Maximum number of item transfers to track during inventory exchange (10-200 items). Higher values allow more complex trades but may impact performance.")
    ElseIf option == _oidListDrunk
        SetInfoText("Shows all currently drunk NPCs with their levels")
    ElseIf option == _oidClearAll
        SetInfoText("Emergency: Immediately sober all drunk NPCs")
    ElseIf option == _oidScanFix
        SetInfoText("Finds and fixes NPCs stuck in drunk faction")
    ElseIf option == _oidUninstall
        SetInfoText("Required before disabling mod - sobers all NPCs")
    ElseIf option == _oidResetCoreSettings
        SetInfoText("Resets all core settings to their default values (does not affect drunk NPCs)")
    ElseIf option == _oidEnableDrunkCap
        SetInfoText("Caps drunk levels at maximum. Over-limit NPCs are reduced when enabled. Disable for unlimited progression.")
    ElseIf option == _oidEnableAutoTakeAlcohol
        SetInfoText("When enabled, if NPC attempts to alcohol but has none, drink will be auto-taken from player's inventory, otherwise a choice dialog box will prompt for player input.")
    ElseIf option == _oidNPCDrinksOnTheHouse
        SetInfoText("When an NPC buys a drink from a merchant through iActions, they pay nothing. The drink still comes from the merchant's stock. Your own trades are unchanged. Default: Off")
    ElseIf option == _oidRespondDirectlyToActions
        SetInfoText("When enabled, stumble actions, alcohol failure messages, and area pacify actions will send direct narration for immediate character responses. When disabled, only regular notifications are shown.")
    ElseIf option == _oidForcePushKey
        SetInfoText("Key to push objects/NPCs under crosshair. When 'Debug: Show Drunk Ranks' is enabled, shows drunk levels. Default: Unbound")
    ElseIf option == _oidMaxDrunkMembers
        SetInfoText("Maximum number of NPCs that can be drunk at once (8-128). Safety measure to prevent performance issues. Most users won't reach this limit during normal gameplay. Default: 32")
    ElseIf option == _oidEnableAutoGiveFood
        SetInfoText("When enabled, food is automatically transferred from player to NPC without dialog prompt")
    ElseIf option == _oidAutoGiveMaxCount
        SetInfoText("Maximum number of food items to auto-transfer at once (1-20). Prevents giving away entire stockpile.")
    ElseIf option == _oidFoodTierPriority
        SetInfoText("Which food tier to give first when multiple types are available. Large = cooked/hearty, Small = raw/snacks.")
    ElseIf option == _oidReceiveFoodCooldown
        SetInfoText("Time between food actions for the same NPC (1-300 seconds) - Tied to 'receive_food' action. Applies immediately")
    EndIf
EndEvent

; =========================================================
; HELPER FUNCTIONS
; =========================================================

Function RestartPolling()
    If !Tracking
        Debug.Notification("[iAct MCM] Error - Cannot restart polling (system not initialized)")
        Return
    EndIf

    ; Cancel current polling
    Tracking.UnregisterForUpdate()

    ; Restart with new interval
    Tracking.RegisterForSingleUpdate(10.0) ; Initial delay

    Debug.Notification("[iAct MCM] Polling interval updated to " + DrunkSystem.MemberPollRate as Int + " seconds")
EndFunction

Function ResetAllCoreSettings()
    If !DrunkSystem || !Lib
        Debug.Notification("[iAct MCM] Error - Cannot reset settings (system not initialized)")
        Return
    EndIf
    
    ; Reset DrunkSystem properties
    DrunkSystem.RequireAlcohol = True
    DrunkSystem.DisableAlcoholRequirementInInns = False
    DrunkSystem.EnableAutoSobering = True
    ; Note: ShowDrunkRank is now handled by Lib.EnableDebugNotify
    DrunkSystem.EnableDrunkCap = True
    DrunkSystem.EnableAutoTakeAlcohol = False
    DrunkSystem.NPCDrinksOnTheHouse = False
    DrunkSystem.EnableAnimations = True
    DrunkSystem.MaxDrunkMembers = 32
    DrunkSystem.MemberPollRate = 300.0
    DrunkSystem.PointsPerLevel = 2
    DrunkSystem.PointsPerDrink = 2
    DrunkSystem.PointsPerDecay = 1
    DrunkSystem.PointsPerSleepHour = 4
    
    ; Reset Lib properties
    Lib.DrinkAlcoholCooldown = 20
    Lib.StumbleAndFallCooldown = 20
    Lib.PacifyCooldown = 20
    Lib.ExchangeCooldown = 20
    Lib.MaxTransfersToTrack = 20
    Lib.ForcePushKeyCode = -1
    Lib.RespondDirectlyToActions = True
    Lib.EnableDebugNotify = False
    Lib.EnablePerformanceLogging = False

    
    ; Update SkyrimNet cooldowns
    SkyrimNetAPI.SetActionCooldown("drink_alcohol", 20)
    SkyrimNetAPI.SetActionCooldown("stumble_and_fall", 20)
    SkyrimNetAPI.SetActionCooldown("aggressively_comply", 20)
    SkyrimNetAPI.SetActionCooldown("exchange_items", 20)
    SkyrimNetAPI.SetActionCooldown("receive_food", 20)
    
    ; Reset Food System properties
    If FoodScript
        FoodScript.EnableAutoGiveFood = False
        FoodScript.AutoGiveMaxCount = 5
        FoodScript.FoodTierPriority = 0
        FoodScript.ReceiveFoodCooldown = 20
    EndIf
    
    ; Update key registration
    Lib.UpdateKeyRegistration()
    
    ; Restart polling with new settings
    RestartPolling()
    
    ; Update the effective requirement immediately after reset
    DrunkSystem.UpdatePlayerInInnStatus()
    
    Debug.Notification("[iAct MCM] All settings reset to defaults")
EndFunction

; =========================================================
; --- WebUI Bridge Functions ---
; =========================================================

; === Safe Uninstall via WebUI ===
; This function is specifically designed to be called from WebUI
; It bridges to the proper Bootstrap.Shutdown() orchestration
Function WebUI_PrepareForUninstall()
    Debug.Trace("[iAct MCM] WebUI_PrepareForUninstall called - bridging to Bootstrap...")
    
    If !BootstrapQuest
        Debug.MessageBox("ERROR: BootstrapQuest property is None.\nCannot execute uninstall.\nUse MCM instead.")
        Debug.Trace("[iAct MCM] ERROR: BootstrapQuest is None", 2)
        Return
    EndIf
    
    ; Get Bootstrap alias and call Shutdown
    iActions_BootstrapAlias bootstrapScript = BootstrapQuest.GetAliasByName("BootstrapAlias") as iActions_BootstrapAlias
    
    If bootstrapScript
        Debug.Trace("[iAct MCM] Calling Bootstrap.Shutdown() via WebUI bridge...")
        bootstrapScript.Shutdown()
        Debug.Notification("[iAct] Uninstall complete. Save your game, exit Skyrim, then disable the mod.")
        Debug.Trace("[iAct MCM] Uninstall complete via WebUI bridge")
    Else
        Debug.MessageBox("ERROR: Could not get BootstrapAlias from quest.\nUse MCM uninstall instead.")
        Debug.Trace("[iAct MCM] ERROR: BootstrapAlias cast failed", 2)
    EndIf
EndFunction

; === List Drunk NPCs via WebUI ===
; Convenience bridge for WebUI access
Function WebUI_ListDrunkNPCs()
    If DrunkSystem
        DrunkSystem.ListDrunkMembersNotify()
    Else
        Debug.Notification("[iAct] ERROR: DrunkSystem not available")
    EndIf
EndFunction

; === Clear All Drunk NPCs via WebUI ===
; Convenience bridge for WebUI access
Function WebUI_ClearAllDrunkNPCs()
    If DrunkSystem
        DrunkSystem.ClearAllDrunkMembersNotify()
    Else
        Debug.Notification("[iAct] ERROR: DrunkSystem not available")
    EndIf
EndFunction

; === Scan & Fix Orphaned Drunks via WebUI ===
; Convenience bridge for WebUI access
Function WebUI_ScanAndFixOrphanedDrunks()
    If DrunkSystem
        DrunkSystem.ScanAndFixOrphanedDrunksNotify()
    Else
        Debug.Notification("[iAct] ERROR: DrunkSystem not available")
    EndIf
EndFunction
