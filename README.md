![iActions welcomes you!](https://raw.githubusercontent.com/Gerkinfeltser/iActions/master/images/iActions-banner.png)
# iActions v0.7.0 for SkyrimNet — Quick Start

**Current release: v0.7.0.** Get it from [iActions on Nexus Mods](https://www.nexusmods.com/skyrimspecialedition/mods/198692) and SkyrimNet from [SkyrimNet on Nexus Mods](https://www.nexusmods.com/skyrimspecialedition/mods/198346). GitHub remains the source/history for the project, but its files and releases are not assumed to be current downloads. Previous release history: [v0.6.7 on GitHub](https://github.com/Gerkinfeltser/iActions/releases/tag/0.6.7).

> **SkyrimNet** is REQUIRED. Test on a separate/non-precious save first if you're risk-averse. Upgrading from v0.6.7 does not require a clean-save migration: replace the old mod folder; do not merge files. [Upgrade notes](#upgrading).
> (For detailed documentation, see the [iActions Wiki](https://github.com/Gerkinfeltser/iActions/wiki).)

## What changes in v0.7.0

- **Skyrim VR support.** A single native DLL supports Skyrim SE/AE and VR. Tested on Skyrim 1.6.1170 and 1.7.104; VR 1.4.15 was tested with the 0.6.8 build; 0.7.0 is untested on VR. Expected to work on 1.5.97, 1.6.640 and 1.7.99 via Address Library, but untested. (VR support first came in the unpublished 0.6.8 build.)
- **Drinks from other NPCs.** An NPC can hand a drink to another NPC, and an innkeeper or other vendor sells one from their stock (the drinker pays). An NPC with no drink buys one from a nearby merchant who sells alcohol. The narration says where the drink came from.
- **Request prompt.** Drink and food requests now ask you through a new iActions prompt in [Magelight UI](https://www.nexusmods.com/skyrimspecialedition/mods/193303). It replaces Papyrus MessageBox, which still works where installed (on 1.7.104 with a community build) and is expected to be dropped later. You need one of the two, or the MCM workaround below.
- **Keyword drinks.** Any drink with the keyword `iActions_Alcohol` counts as alcohol, so a [Keyword Item Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/55728) ini can add mod drinks (see What It Does).
- **NPCs know their drinks.** When alcohol is required, an NPC's bio lists the alcohol they carry, so they can ask for a drink they actually have.
- **Fixes:** at the drunk-NPC limit a new drinker is refused instead of being left drunk forever; sobering no longer overwrites a drink that lands mid-update; one bottle can no longer be drunk twice; mod drinks with unusual names no longer break the drink list; "(N left)" counts keyword drinks.
- **New MCM options (Drunk Behavior, both off by default):** **NPC Drinks on the House** lets NPCs take drinks from merchants without paying (the narration still reads as a normal sale; your own trades are unchanged). **Short-Lived Drink Events** keeps drink results in SkyrimNet's scene context for 2 minutes instead of saving them to event history and memories, so long drinking sessions don't fill NPC memories (NPCs won't recall the drinks later; their drunk level still shows).
- **DLL log level** is now set in `iActions.ini` (see [DLL log level](#dll-log-level)).

The 0.7.0 drink changes were tested on Skyrim 1.6.1170 and 1.7.104. Save compatible with v0.6.7: no clean-save migration. Match SKSE / SKSEVR and Address Library / VR Address Library to your Skyrim executable, alongside a compatible SkyrimNet build and the required dependencies below.

### No request prompt? MCM workaround

Drink and food requests ask you through Magelight UI or, failing that, Papyrus MessageBox (on 1.7.104 it needs a community build). With neither installed, configure the iActions MCM to use player-supplied drinking or food requests:

- **Drunk Behavior → Auto-Take Alcohol: ON** for drinks taken from your inventory. If the toggle is greyed out, enable **Require Alcohol in Inventory** first.
- **Configuration → Auto-Give Food: ON** for food requests. **Auto-Give Max Food Items** controls the transfer limit.

These settings allow automatic transfers without asking you to choose or decline. Keep them enabled, including after an MCM reset. With a prompt installed, use this workaround only if you prefer not to be asked. Normal drinking from an NPC's own inventory does not need auto-take; named-drink requests can check your inventory first, so keep it on for those too. This workaround does not certify the full runtime or other dependencies.

**Upgrading:** Replace the previous iActions mod folder rather than merging files. No clean-save migration is required from v0.6.7. Enable only one iActions copy.

## TL;DR
### **What it does**: NPCs drink, get drunk & sober over time (plus a few extras) via SkyrimNet actions
- **NEW v0.7.0**: Skyrim VR support, NPCs give and sell each other drinks, new Magelight UI request prompt, keyword-tagged drinks; see [What changes in v0.7.0](#what-changes-in-v070)
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

- Skyrim SE/AE or VR, with matching [SKSE / SKSEVR](https://skse.silverlock.org) and [Address Library](https://www.nexusmods.com/skyrimspecialedition/mods/32444) / [VR Address Library](https://www.nexusmods.com/skyrimspecialedition/mods/58101) for the exact game runtime
- **[SkyrimNet](https://www.nexusmods.com/skyrimspecialedition/mods/198346)** (required)
- [JContainers SE](https://www.nexusmods.com/skyrimspecialedition/mods/16495) or its VR build, matching the game; [PO3 Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) SE or VR build, matching the game
- [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604) SE or VR build matching the game
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048) or its VR build, matching the game (SkyrimNet also requires it)
- For drink and food request prompts, one of: [Magelight UI](https://www.nexusmods.com/skyrimspecialedition/mods/193303) 1.6.0 or newer (recommended; works on 1.7.x; tested on 1.6.1170 and 1.7.104, untested on VR; SeverActions includes a copy), or [Papyrus MessageBox SE](https://www.nexusmods.com/skyrimspecialedition/mods/83578) (older and expected to be dropped in a later version; v1.0.0 worked on VR; on 1.7.104 add the community [PapyrusMessageBox-1.7.104](https://www.nexusmods.com/skyrimspecialedition/mods/193932) build). With neither, use the MCM workaround above.
- Optional: [Keyword Item Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/55728) to tag mod drinks with the keyword `iActions_Alcohol`
- Optional: Open Animation Replacer (OAR); optional animation add-on [Drunk or drugged animations OAR](https://www.nexusmods.com/skyrimspecialedition/mods/62191)

## Quick Installation
1. Install SKSE / SKSEVR and Address Library / VR Address Library matching your Skyrim executable, SkyrimNet, matching JContainers and PO3 Papyrus Extender SE/VR, and SkyUI SE/VR, plus Magelight UI (or Papyrus MessageBox where available) for request prompts; with neither, use the workaround above. KID, OAR and the animation add-on are optional.
2. Install the v0.7.0 ZIP with your mod manager. Its ESP, Magelight, meshes, Scripts, SKSE, Source and `README-iActions.md` belong at the mod folder root, not inside an extra `iActions/` or `Data/` folder. Enable only one iActions copy.
3. If using OAR and the optional animation add-on, load iActions after them.
4. Configure in MCM.

### Upgrading

> **iActions v0.7.0 requires SkyrimNet.** Match SKSE / SKSEVR and Address Library / VR Address Library to your Skyrim executable before launching the game.

#### From v0.6.5, v0.6.6 or v0.6.7 to v0.7.0

1. Install or update to **SkyrimNet**
2. Replace the previous iActions mod folder with the new one; do not merge files. No clean-save migration is required.
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

#### From v0.5.7 to v0.7.0

1. Install **SkyrimNet** first. Install Magelight UI (or Papyrus MessageBox where available) for request prompts; with neither, use the workaround above.
2. Replace the previous iActions mod folder rather than merging files — save compatible, no clean-save migration needed.

#### From v0.6.0 to v0.7.0

1. Install or update to **SkyrimNet**
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

**License:** First-party iActions code is [MIT](LICENSE), copyright 2025–2026 Gerkinfeltser. SkyrimNet's `PublicAPI.h` has its [own MIT notice](source/CppAPI/PublicAPI-LICENSE.txt) from Fateless.Ai; SkyrimNet itself is licensed separately. The adapted OAR configuration and Bethesda `Tankard.nif` are **not** covered by the iActions MIT license.

## DLL log level

`iActions.log` records startup and warnings by default. For per-call decorator detail, create `Data/SKSE/Plugins/iActions.ini` (not shipped, so mod updates never overwrite it) and restart the game:

```ini
[Log]
Level=debug
```

Accepted levels: `trace`, `debug`, `info` (default), `warn`, `error`, `off`.

## Credits
The bundled OAR configuration is adapted from [Drunk or drugged animations OAR](https://www.nexusmods.com/skyrimspecialedition/mods/62191) by samuelga24. `Tankard.nif` is a vanilla Skyrim mesh.

**Made with AI.** iActions couldn't have been made without the aid of AI, but it is tested by real humans.


## What It Does
- **Drunk System**: NPCs drink alcohol → get drunk → sober up automatically (5 levels: Buzzed, Tipsy, Drunk, Plastered, Blackout)
- **Sleep Sobering**: NPCs lose drunk points while you sleep (configurable rate, default 4 points/hour)
- **Actions**: Drink alcohol (specific drinks by name!), request food, request alcohol, sober up, extract arrows, stumble
- **Player Features**: Force push, optional in-game debug notifications
- **Custom Drinks**: Add mod-added alcohol via `SKSE/Plugins/iActions/extra_alcohol.json` (Bruma, Interesting NPCs, etc.), or tag drinks with the keyword `iActions_Alcohol` using the optional [Keyword Item Distributor](https://www.nexusmods.com/skyrimspecialedition/mods/55728), e.g. `Keyword = iActions_Alcohol|Potion|Greenwood Mead,Applewatch Cider` in a `*_KID.ini`
- **Smart Inventory**: SKSE decorators `iActions_get_npc_alcohol` and `iActions_get_alcohol_formids` for real-time alcohol detection
- **Web Agent**: Built-in SkyrimNet web agent (`iActions Extra Alcohol Helper`) to auto-detect mod-added drinks and generate config — ready to use in the WebUI Agents area
- **Smart Spawning**: Free-drinks mode spawns the specific drink the NPC asked for (not random)
- **Performance**: Optimized inventory detection, cached alcohol lookups, reduced script lag

### Where drinks come from

When an NPC drinks, iActions looks for the drink in this order and stops at the first one it finds:

1. **Another NPC (the giver).** When SkyrimNet names an NPC as handing or selling the drink:
   - If the giver carries alcohol, they hand one over.
   - If not, and the giver is a merchant (an innkeeper, for example), the drinker buys one from the giver's shop stock at its base price. A drinker without enough gold doesn't drink, and the narration says why. Buying only happens when alcohol is required.
   - A giver who is dead or too far from the drinker is ignored.
2. **The drinker's own inventory.**
3. **The nearest merchant who sells alcohol.** When no NPC giver was named (or you were named but carry no alcohol), a drinker with nothing buys from the nearest merchant within reach whose stock has alcohol: an innkeeper, a tavern keeper, a general store. Same price and gold check as above; only when alcohol is required. With MCM **Drunk Behavior → NPC Drinks on the House** on (default off), no gold changes hands, here and in step 1, but the narration reads as a normal sale, so neither NPC knows it was free. Your own trades are unchanged.
4. **A free drink**, when alcohol is not required (MCM **Require Alcohol in Inventory** off, or in an inn with **Disable Alcohol Requirement in Inns** on; only locations Skyrim tags as inns count, and some taverns, such as the Drunken Huntsman, are not tagged).
5. **You**, only when SkyrimNet names you as the giver: the request prompt (or Auto-Take) gives a drink from your inventory.

If the NPC asks for a drink by name ("a bottle of Black-Briar Mead"), each step looks for that drink first. The narration says where the drink came from, and the drinker reacts (with a giver or seller, the drinker decides who to address).

## Key MCM Settings
- Alcohol required by default (can be disabled completely or only in locations Skyrim tags as inns)
- **v0.7.0**: NPC Drinks on the House (NPCs don't pay merchants; off by default), Short-Lived Drink Events (drink results fade after 2 minutes instead of entering NPC memories; off by default)
- 20-second cooldowns to prevent drink/stumble spam
- Auto-incremental sobering every 5 minutes (configurable)
- **v0.6.5**: 26 drinks, custom drinks JSON, specific drink selection, FormID-based detection
- **v0.6.0**: Receive Food — Followers request food (survival mode focus), Auto-Give toggle, Max Food Items (1-20), Food Preference Order (4 options), Cooldown (1-300s)
- **v0.5.7**: Sleep Sobering — PointsPerSleepHour (0-40, default: 4). Points drunk NPCs lose per hour of sleep. Set to 0 to disable. Example: 8 hours sleep × 4 points = 32 points lost (~4 drunk tiers)
- **v0.5.1**: Exchange Items (max types tracked: default 20, tested up to 50; more items = longer processing)
- **v0.5.0**: Max simultaneous drunk NPCs (8-128, default 32)
- **v0.5.0**: Toggle drink animations (user preference for animation timing)
- **v0.5.0**: Performance logging for optimization monitoring
- Key-bindable shove (middle-mouse button works well, unbound by default)
- All(/most) settings in MCM menu

---

For full details, see the [iActions Wiki](https://github.com/Gerkinfeltser/iActions/wiki).