; =============================================================================
; SkyrimNet iActions - Drunk Cache
; =============================================================================
; JContainers alcohol cache management for O(1) lookups.
; Extracted from iActions_DrunkSystem.psc lines 59-297.
; =============================================================================
Scriptname iActions_DrunkCache extends Quest
Import JIntMap
Import JValue
Import iActions_Lib

; Cross-script property (fill in CK/Spriggit)
iActions_DrunkCore Property Core Auto

; ===========================================
; Cache State Properties
; ===========================================

; Array cache of alcohol FormList contents (for iteration when needed)
Form[] Property _cachedAlcoholForms Auto Hidden

; Count of cached alcohol forms
Int Property _cachedAlcoholCount Auto Hidden

; JIntMap handle for O(1) FormID lookup
; Key: FormID (int), Value: 1 (presence flag)
Int Property _alcoholFormIDMap Auto Hidden
; FIXME: LEGACY - No longer used since switching to FormList.HasForm(). Can be removed once confirmed stable.

; Flag to track if cache is initialized
Bool Property _cacheInitialized Auto Hidden

; EditorID of the keyword that marks an item as alcohol (distributed by KID; see docs/EXTRA-ALCOHOL-GUIDE.md).
; The DLL matches the same string (CppAPI/src/main.iactions.cpp).
String Property AlcoholKeywordName = "iActions_Alcohol" AutoReadOnly

; ===========================================
; FUNCTION: InitializeAlcoholCache
; ===========================================
; Call this in Maintenance() function after UpdatePlayerInInnStatus()
; Should only run once per game session
;
; Prerequisites:
;   - Core.iActions_AlcoholList property must be set (FormList)
;   - JContainers must be loaded
;
; Performance: One-time cost of ~10-50ms depending on FormList size
; ===========================================

Function InitializeAlcoholCache()
    LogAlert("InitializeAlcoholCache called, _cacheInitialized=" + _cacheInitialized, False, False, False)
    If _cacheInitialized
        LogAlert("Alcohol cache already initialized, skipping", False, False, False)
        Return
    EndIf
    
    ; Validate FormList exists via Core
    If !Core || !Core.iActions_AlcoholList
        LogAlert("ERROR: Core.iActions_AlcoholList is None!", False, False, False)
        Return
    EndIf
    
    ; Get FormList size
    _cachedAlcoholCount = Core.iActions_AlcoholList.GetSize()
    
    If _cachedAlcoholCount <= 0
        LogAlert("WARNING: Alcohol FormList is empty", False, False, False)
        _cacheInitialized = True
        Return
    EndIf
    
    ; Create array to cache FormList contents
    _cachedAlcoholForms = Utility.CreateFormArray(_cachedAlcoholCount)
    
    ; FIXME: LEGACY - JIntMap no longer used. Can be removed once confirmed stable.
    ; Create JIntMap for O(1) FormID lookups
    _alcoholFormIDMap = JIntMap.object()
    JValue.retain(_alcoholFormIDMap)  ; Prevent garbage collection
    
    ; Populate both caches
    Int i = 0
    While i < _cachedAlcoholCount
        Form alcoholItem = Core.iActions_AlcoholList.GetAt(i)
        _cachedAlcoholForms[i] = alcoholItem
        
        ; FIXME: LEGACY - JIntMap population no longer used. Can be removed once confirmed stable.
        If alcoholItem
            Int formID = alcoholItem.GetFormID()
            JIntMap.setInt(_alcoholFormIDMap, formID, 1)
        EndIf
        
        i += 1
    EndWhile
    
    _cacheInitialized = True
    LogAlert("Alcohol cache initialized with " + _cachedAlcoholCount + " items", False, False, False)
    
    LoadExtraAlcohol()
EndFunction

; ===========================================
; FUNCTION: CleanupAlcoholCache
; ===========================================
; Call this if mod is being uninstalled or reset
; ===========================================

Function CleanupAlcoholCache()
    If _alcoholFormIDMap != 0
        JValue.release(_alcoholFormIDMap)
        _alcoholFormIDMap = 0
    EndIf
    
    _cachedAlcoholForms = Utility.CreateFormArray(0)
    _cachedAlcoholCount = 0
    _cacheInitialized = False
    
    LogAlert("Alcohol cache cleaned up")
EndFunction

; ===========================================
; FUNCTION: RefreshAlcoholCache
; ===========================================
; Force cache refresh if FormList was modified at runtime
; Call this if you detect FormList changes
; ===========================================

Function RefreshAlcoholCache()
    CleanupAlcoholCache()
    InitializeAlcoholCache()
EndFunction

; ===========================================
; FUNCTION: IsAlcohol
; ===========================================
; Returns true if the given form is in the alcohol list
; Uses FormList.HasForm() for proper base form matching
;
; Parameters:
;   akForm - The form to check
;
; Returns: True if form is alcohol, False otherwise
;
; NOTE: JIntMap cache (_alcoholFormIDMap) is no longer used here.
;       If this fix works, consider removing the JIntMap infrastructure
;       in InitializeAlcoholCache/CleanupAlcoholCache to reduce complexity.
; ===========================================

Bool Function IsAlcohol(Form akForm)
    If !Core || !akForm || !Core.iActions_AlcoholList
        Return False
    EndIf
    
    ; Use FormList.HasForm() which properly matches base forms to inventory items
    ; Keyword route: KID (or a patch plugin) tags drinks with "iActions_Alcohol". Without KID no
    ; keyword of that name exists and HasKeywordString returns False.
    Bool result = Core.iActions_AlcoholList.HasForm(akForm) || akForm.HasKeywordString(AlcoholKeywordName)

    ; Debug: Log alcohol detection attempts
    If Core.Lib && Core.Lib.EnableDebugNotify
        LogAlert("IsAlcohol check: " + akForm.GetName() + " = " + result, False, False, False)
    EndIf
    
    Return result
EndFunction

; ===========================================
; FUNCTION: GetCachedAlcoholCount
; ===========================================
; Returns the number of cached alcohol forms
; ===========================================

Int Function GetCachedAlcoholCount()
    Return _cachedAlcoholCount
EndFunction

; ===========================================
; FUNCTION: GetCachedAlcoholForm
; ===========================================
; Returns a cached alcohol form at the given index
; ===========================================

Form Function GetCachedAlcoholForm(Int index)
    If !_cacheInitialized || index < 0 || index >= _cachedAlcoholCount
        Return None
    EndIf
    Return _cachedAlcoholForms[index]
EndFunction

; ===========================================
; FUNCTION: LoadExtraAlcohol
; ===========================================
; Loads user-defined extra alcohol from JSON config and injects into FormList.
; Called at the end of InitializeAlcoholCache().
; Silently skips entries for plugins that aren't installed.
; ===========================================

Bool Property _extrasLoaded = False Auto

Function LoadExtraAlcohol()
    If _extrasLoaded
        LogAlert("Extras already loaded, skipping.")
        Return
    EndIf
    _extrasLoaded = True
    LogAlert("Loading extra alcohol config...")
    String configPath = "Data/SKSE/Plugins/iActions/extra_alcohol.json"
    Int jRoot = JValue.readFromFile(configPath)
    
    If !jRoot
        LogAlert("No extra alcohol config found at " + configPath + " (file missing or BOM-encoded)")
        Return
    EndIf
    
    Int extraArr = JValue.solveObj(jRoot, ".extra_alcohol")
    If !extraArr
        LogAlert("Extra alcohol config has no .extra_alcohol array")
        JValue.release(jRoot)
        Return
    EndIf
    
    Int arrLen = JArray.count(extraArr)
    If arrLen <= 0
        LogAlert("Extra alcohol config array is empty")
        JValue.release(jRoot)
        Return
    EndIf
    
    LogAlert("Found " + arrLen + " entries in extra alcohol config")
    Int added = 0
    Int i = 0
    While i < arrLen
        Int jEntry = JArray.getObj(extraArr, i)
        
        String formHex = JValue.solveStr(jEntry, ".formID")
        String pluginName = JValue.solveStr(jEntry, ".plugin")
        String itemName = JValue.solveStr(jEntry, ".name")
        
        If !formHex
            formHex = JValue.solveStr(jEntry, ".form")
        EndIf
        
        If formHex && pluginName
            Int formInt = HexStringToInt(formHex)
            If formInt > 0
                If Game.GetModByName(pluginName) == 255
                    LogAlert("Extra alcohol entry skipped: plugin '" + pluginName + "' not loaded (" + formHex + " " + itemName + ")")
                Else
                    Form theForm = Game.GetFormFromFile(formInt, pluginName)
                    If theForm
                        Core.iActions_AlcoholList.AddForm(theForm)
                        added += 1
                        LogAlert("Extra alcohol: " + theForm.GetName() + " (" + formHex + " from " + pluginName + ")")
                    Else
                        LogAlert("Extra alcohol entry skipped: form " + formHex + " not found in " + pluginName + " (" + itemName + ")")
                    EndIf
                EndIf
            Else
                LogAlert("Extra alcohol entry skipped: invalid FormID '" + formHex + "'")
            EndIf
        Else
            LogAlert("Extra alcohol entry " + i + " skipped: missing formID or plugin")
        EndIf
        
        i += 1
    EndWhile
    
    JValue.release(jRoot)
    
    LogAlert("Loaded " + added + "/" + arrLen + " extra alcohol entries from config")
    If added > 0
        RefreshAlcoholCache()
    EndIf
EndFunction

; ===========================================
; FUNCTION: HexStringToInt
; ===========================================
; Converts a hex string like "0xB91D7" to an integer
; ===========================================

Int Function HexStringToInt(String hexStr)
    If !hexStr
        Return 0
    EndIf
    
    hexStr = StringUtil.Substring(hexStr, 2, 0) ; Remove "0x" prefix
    If !hexStr
        Return 0
    EndIf
    
    Int result = 0
    Int len = StringUtil.GetLength(hexStr)
    Int i = 0
    While i < len
        String ch = StringUtil.GetNthChar(hexStr, i)
        Int digit = 0
        If ch == "0"
            digit = 0
        ElseIf ch == "1"
            digit = 1
        ElseIf ch == "2"
            digit = 2
        ElseIf ch == "3"
            digit = 3
        ElseIf ch == "4"
            digit = 4
        ElseIf ch == "5"
            digit = 5
        ElseIf ch == "6"
            digit = 6
        ElseIf ch == "7"
            digit = 7
        ElseIf ch == "8"
            digit = 8
        ElseIf ch == "9"
            digit = 9
        ElseIf ch == "A" || ch == "a"
            digit = 10
        ElseIf ch == "B" || ch == "b"
            digit = 11
        ElseIf ch == "C" || ch == "c"
            digit = 12
        ElseIf ch == "D" || ch == "d"
            digit = 13
        ElseIf ch == "E" || ch == "e"
            digit = 14
        ElseIf ch == "F" || ch == "f"
            digit = 15
        Else
            Return 0
        EndIf
        result = result * 16 + digit
        i += 1
    EndWhile
    Return result
EndFunction
