![iActions welcomes you!](https://raw.githubusercontent.com/Gerkinfeltser/iActions/master/images/iActions-banner.png)
# iActions v0.6.8 candidate for SkyrimNet — Quick Start

**Current candidate: v0.6.8.** Tested on Skyrim 1.6.1170, 1.7.104 and VR 1.4.15. Get the candidate from [iActions on Nexus Mods]([IACTIONS_NEXUS_URL]) and SkyrimNet from [SkyrimNet on Nexus Mods](https://www.nexusmods.com/skyrimspecialedition/mods/198346). GitHub remains the source/history for the project, but its files and releases are not assumed to be current downloads. Previous release history: [v0.6.7 on GitHub](https://github.com/Gerkinfeltser/iActions/releases/tag/0.6.7).

> **SkyrimNet Beta 25 or newer is REQUIRED**; earlier versions are unsupported. Test on a separate/non-precious save first if you're risk-averse. Upgrading from v0.6.7 does not require a clean-save migration: replace the old mod folder; do not merge files. [Upgrade notes](#upgrading).
> (For detailed documentation, see the [iActions Wiki](https://github.com/Gerkinfeltser/iActions/wiki).)

## What changes in v0.6.8

Version 0.6.8 adds Skyrim VR support. A single native DLL supports Skyrim SE/AE and VR. Tested on 0.6.8: Skyrim 1.6.1170, 1.7.104 and VR 1.4.15. Expected to work on 1.5.97, 1.6.640 and 1.7.99 via Address Library, but untested.

This candidate changes no gameplay or save behavior. Match SKSE / SKSEVR and Address Library / VR Address Library to your Skyrim executable, alongside a compatible SkyrimNet build and the required dependencies below.

### Papyrus MessageBox workaround (Skyrim 1.7.x only)

Papyrus MessageBox is unavailable on Skyrim 1.7.x. To use player-supplied drinking or food requests there, configure the iActions MCM:

- **Drunk Behavior → Auto-Take Alcohol: ON** for drinks taken from your inventory. If the toggle is greyed out, enable **Require Alcohol in Inventory** first.
- **Configuration → Auto-Give Food: ON** for food requests. **Auto-Give Max Food Items** controls the transfer limit.

These settings allow automatic transfers without asking you to choose or decline. Keep them enabled, including after an MCM reset. On VR, use this workaround only if you prefer no dialogs. Normal drinking from an NPC's own inventory does not need auto-take; named-drink requests can check your inventory first, so keep it on for those too. This workaround does not certify the full runtime or other dependencies.

**Upgrading:** Replace the previous iActions mod folder rather than merging files. No clean-save migration is required from v0.6.7. Enable only one iActions copy.

## TL;DR
### **What it does**: NPCs drink, get drunk & sober over time (plus a few extras) via SkyrimNet actions
- **NEW v0.6.8**: Skyrim VR support; tested on Skyrim 1.6.1170, 1.7.104 and VR 1.4.15.
- **v0.6.7**: Drinking, food requests, arrow extraction and sobering became standalone actions, with the old category definitions removed
- **v0.6.6**: Requires SkyrimNet Beta 25 or newer; moves content into the `phospheneoverdrive.iactions` external bundle, adopts snake_case action identifiers, and prevents `exchange_items` from being suggested for merchant transactions
- **v0.6.5**: 26 vanilla drinks recognized (was 15), custom drinks via JSON config, specific drink selection by name, smart NPC alcohol inventory via SKSE decorator
- **v0.6.0**: Receive Food — Followers request food via dynamic dialog, configurable tier priority and auto-give
- **v0.5.7**: Sleep Sobering — Drunk NPCs gradually sober up while you sleep (configurable PointsPerSleepHour, default: 4)
- **v0.5.5**: NPCs can sit & drink at the same time... generally, prompt updated & ready for SkyrimNet Beta14
- **v0.5.1.x**: NPCs can now request to trade items with you
- **v0.5.0**: 5-tier drunk system (Buzzed→Blackout), major performance optimizations, new MCM settings, rebranded to clarify non-official status
- **Install**: Mod manager → configure in MCM; OAR and animation add-on are optional

## Requirements

- Skyrim SE/AE or VR, with matching SKSE / SKSEVR and Address Library / VR Address Library for the exact game runtime
- **SkyrimNet Beta 25 or newer** (required; earlier versions are unsupported)
- JContainers SE or VR build matching the game; PO3 Papyrus Extender SE or VR build matching the game
- SkyUI SE or VR build matching the game
- Papyrus MessageBox SE ([Nexus page](https://www.nexusmods.com/skyrimspecialedition/mods/83578)) for choice dialogs on supported runtimes; unavailable on Skyrim 1.7.x, where the MCM workaround above applies. The normal v1.0.0 file worked on VR; the workaround is optional there for users who prefer no dialogs.
- Optional: Open Animation Replacer (OAR); iActions includes a first-party drunk-animation trigger configuration. Optional animation assets are a separate download: [Drunk or drugged animations OAR](https://www.nexusmods.com/skyrimspecialedition/mods/62191) by samuelga24.

## Quick Installation
1. Install SKSE / SKSEVR and Address Library / VR Address Library matching your Skyrim executable, SkyrimNet Beta 25 or newer, matching JContainers and PO3 Papyrus Extender SE/VR, and SkyUI SE/VR. Install Papyrus MessageBox for supported runtimes; on 1.7.x, use the workaround above. On VR, the normal v1.0.0 file was tested working; use the workaround only if you prefer no dialogs. OAR and the animation add-on are optional.
2. Install the v0.6.8 candidate ZIP with your mod manager. Its ESP, meshes, Scripts, SKSE, Source and `README-iActions.md` belong at the mod folder root, not inside an extra `iActions/` or `Data/` folder. Enable only one iActions copy.
3. If using the optional animation mod, load iActions after it (below it in MO2's left pane). The included first-party config replaces its config, so its other-mod triggers (SunHelm, iNeed, etc.) no longer apply while this override is active. Hide or remove the iActions config to restore them.
4. Configure in MCM.

### Upgrading

> **iActions v0.6.8 requires SkyrimNet Beta 25 or newer.** Match SKSE / SKSEVR and Address Library / VR Address Library to your Skyrim executable before launching the game.

#### From v0.6.5, v0.6.6 or v0.6.7 to v0.6.8

1. Install or update to **SkyrimNet Beta 25 or newer**
2. Replace the previous iActions mod folder with the candidate; do not merge files. No clean-save migration is required.
3. Review SkyrimNet plugin enablement, priority, Hub association, and overlay relationships after upgrading
4. Reapply per-action settings stored under old action names only when upgrading from v0.6.5 or v0.6.6

The external bundle uses plugin id `phospheneoverdrive.iactions`, and action names use snake_case. The wake-up event is distributed by a separate plugin.


#### From v0.4.x (Clean migration required)

The v0.5.0 ESL conversion requires a clean migration from v0.4.x:

1. Run iActions MCM's "Prepare for Uninstall"
2. Save game and exit Skyrim completely
3. Disable iActions in the mod manager
4. Without iActions enabled, load the save, save again, and exit
5. Enable the new iActions version and load that save

Use `setstage SKI_ConfigManagerInstance 1` if the MCM does not appear after some time.

#### From v0.3.0 (No MCM uninstall)

1. Use SkyrimNet WebUI to run `WebUI_PrepareForUninstall()` on the `iActions_MCM` script
2. Save, quit, disable the mod, load the save, save, and quit again
3. Install and enable the new version, then load the save

#### From v0.5.7 to v0.6.8

1. Install **SkyrimNet Beta 25 or newer** first. Install Papyrus MessageBox for supported runtimes; on 1.7.x use the workaround above. On VR, MessageBox v1.0.0 worked; the workaround is optional if you prefer no dialogs.
2. Replace the previous iActions mod folder rather than merging files — save compatible, no clean-save migration needed.

#### From v0.6.0 to v0.6.8

1. Install or update to **SkyrimNet Beta 25 or newer**
2. Replace the previous iActions mod folder rather than merging files — save compatible, no clean-save migration needed.
3. Optional: edit `SKSE/Plugins/iActions/extra_alcohol.json` to add custom drinks

## Source & building

The history-free source snapshot is under [`source/`](source): native SKSE code in `CppAPI/`, Papyrus scripts in `Papyrus/`. Native build prerequisites: Windows x64, Visual Studio 2022 Community with Desktop development with C++ and a Windows SDK, CMake 3.21+, Ninja, Git, and the VS-bundled vcpkg. Network access is needed for pinned CommonLibVR and vcpkg dependencies; no private checkout or prebuilt DLL is required.

Use a short checkout path (for example `C:\src\iActions`); deeply nested paths can fail inside vcpkg with Git's `Filename too long`. For a long checkout, temporarily map its `source` directory with `subst Q: <absolute-source-directory>` if `Q:` is unused, and start the recipe from `Q:\` instead of running `cd source`; remove the mapping afterward with `subst Q: /D`. The process-local Git setting below also covers recursive clones that resolve the physical long path. From this repository root in a fresh PowerShell terminal:

```powershell
cd source
$vs = 'C:\Program Files\Microsoft Visual Studio\2022\Community'
Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll" -ErrorAction Stop
Enter-VsDevShell -VsInstallPath $vs -Arch amd64 -SkipAutomaticLocation -ErrorAction Stop | Out-Null
$env:VCPKG_ROOT = "$vs\VC\vcpkg"
$env:VCPKG_VISUAL_STUDIO_PATH = $vs
$env:VCPKG_MAX_CONCURRENCY = '2'
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'core.longpaths'
$env:GIT_CONFIG_VALUE_0 = 'true'
foreach ($name in 'SKYRIM_FOLDER', 'SKYRIM_MODS_FOLDER') {
    if (Test-Path "Env:$name") { Remove-Item "Env:$name" -ErrorAction Stop }
}
$build = 'CppAPI/.buildenv/build/public-vs2022-clean'
if (Test-Path $build) { throw 'Choose an absent build directory' }
cmake --preset release -S CppAPI/.buildenv -B $build -DIACTIONS_COPY_OUTPUT=OFF
if ($LASTEXITCODE -ne 0) { throw 'Configure failed' }
cmake --build $build --config Release --parallel 2 --target iActions iActions_saved_parent_abi
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
& "$build/iActions_saved_parent_abi.exe"
if ($LASTEXITCODE -ne 0) { throw 'Saved-parent ABI check failed' }
& "$build/iActions_saved_parent_abi.exe" --wrong-slot
if ($LASTEXITCODE -ne 1) { throw 'Wrong-slot negative control must fail with exit 1' }
```

The `release` preset uses Ninja, C++23 and `x64-windows-static-md` (dynamic `/MD`); the configuration requires VS2022 and applies `/Od /Ob0 /DNDEBUG`. The DLL is produced in `$build`. Keep `IACTIONS_COPY_OUTPUT=OFF`: its default `ON` copies into `source/iActions/SKSE/Plugins` in this snapshot layout, not into a mod manager. The ABI fixture is excluded from normal builds, hence the explicit target; its five synthetic runtime checks and expected-failing negative control do not certify gameplay. Papyrus compilation additionally needs the Creation Kit Papyrus compiler and dependency script imports; the native commands do not compile `.psc` files.

Dependencies are fetched, not vendored: [CommonLibVR](https://github.com/MinLL/CommonLibVR/tree/550cc4fb9114649dcf526d1f3d73d710c5d7003b) (MIT), OpenVR (BSD-3-Clause), DirectXMath/DirectXTK (MIT), rapidcsv (BSD-3-Clause), spdlog (MIT), and fmt (MIT). Preserve their respective notices when distributing binaries.

**License:** First-party iActions code and the first-party OAR trigger configuration are [MIT](LICENSE), copyright 2025–2026 Gerkinfeltser. SkyrimNet's `PublicAPI.h` has its [own MIT notice](source/CppAPI/PublicAPI-LICENSE.txt) from Fateless.Ai; SkyrimNet itself is licensed separately. Bethesda `Tankard.nif` is not covered by iActions MIT.

## Credits
Animation author: [samuelga24](https://www.nexusmods.com/skyrimspecialedition/mods/62191); the optional animation assets are a separate download and are not included. `Tankard.nif` is a vanilla Bethesda mesh.


## What It Does
- **Drunk System**: NPCs drink alcohol → get drunk → sober up automatically (5 levels: Buzzed, Tipsy, Drunk, Plastered, Blackout)
- **Sleep Sobering**: NPCs lose drunk points while you sleep (configurable rate, default 4 points/hour)
- **Actions**: Drink alcohol (specific drinks by name!), request food, request alcohol, sober up, extract arrows, stumble
- **Player Features**: Force push, optional in-game debug notifications
- **Custom Drinks**: Add mod-added alcohol via `SKSE/Plugins/iActions/extra_alcohol.json` (Bruma, Interesting NPCs, etc.)
- **Smart Inventory**: SKSE decorators `iActions_get_npc_alcohol` and `iActions_get_alcohol_formids` for real-time alcohol detection
- **Web Agent**: Built-in SkyrimNet web agent (`iActions Extra Alcohol Helper`) to auto-detect mod-added drinks and generate config — ready to use in the WebUI Agents area
- **Smart Spawning**: Free-drinks mode spawns the specific drink the NPC asked for (not random)
- **Performance**: Optimized inventory detection, cached alcohol lookups, reduced script lag

## Key MCM Settings
- Alcohol required by default (can be disabled completely or only in inns/taverns)
- 20-second cooldowns to prevent drink/stumble spam
- Auto-incremental sobering every 5 minutes (configurable)
- **v0.6.5**: 26 drinks, custom drinks JSON, specific drink selection, FormID-based detection
- **v0.6.0**: Receive Food — Followers request food (survival mode focus), Auto-Give toggle, Max Food Items (1-20), Food Preference Order (4 options), Cooldown (1-300s)
- **v0.5.7**: Sleep Sobering — PointsPerSleepHour (0-100, default: 4). Points drunk NPCs lose per hour of sleep. Set to 0 to disable. Example: 8 hours sleep × 4 points = 32 points lost (~4 drunk tiers)
- **v0.5.1**: Exchange Items (max types tracked: default 20, tested up to 50; more items = longer processing)
- **v0.5.0**: Max simultaneous drunk NPCs (8-128, default 32)
- **v0.5.0**: Toggle drink animations (user preference for animation timing)
- **v0.5.0**: Performance logging for optimization monitoring
- Key-bindable shove (middle-mouse button works well, unbound by default)
- All(/most) settings in MCM menu

---

For full details, see the [iActions Wiki](https://github.com/Gerkinfeltser/iActions/wiki).