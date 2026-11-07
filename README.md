![iActions welcomes you!](https://raw.githubusercontent.com/Gerkinfeltser/iActions/master/images/iActions-banner.png)
# iActions v0.6.8 candidate for SkyrimNet — Quick Start

**Current candidate: v0.6.8.** This is an experimental, not-yet-runtime-accepted candidate; the rebuilt DLL still needs owner retesting. Get the candidate from [iActions on Nexus Mods]([IACTIONS_NEXUS_URL]) and SkyrimNet from [SkyrimNet on Nexus Mods]([SKYRIMNET_NEXUS_URL]). GitHub remains the source/history for the project, but its files and releases are not assumed to be current downloads. Previous release history: [v0.6.7 on GitHub](https://github.com/Gerkinfeltser/iActions/releases/tag/0.6.7).

> **SkyrimNet Beta 25 or newer is REQUIRED**; earlier versions are unsupported. Test on a separate/non-precious save first if you're risk-averse. Upgrading from v0.6.7 does not require a clean-save migration: replace the old mod folder; do not merge files. [Upgrade notes](#upgrading).
> (For detailed documentation, see the [iActions Wiki](https://github.com/Gerkinfeltser/iActions/wiki).)

## What changes in v0.6.8

Version 0.6.8 adds Skyrim VR support. A single native DLL supports Skyrim SE/AE and VR. Owner-reported tests for the preceding 0.6.7-numbered VR-capable DLL cover Skyrim 1.6.1170, 1.7.104 and Skyrim VR 1.4.15; the rebuilt 0.6.8 DLL needs retesting. Skyrim 1.5.97, 1.6.640 and 1.7.99 are untested, but expected to work via Address Library.

This candidate changes no gameplay or save behavior. Match SKSE / SKSEVR and Address Library / VR Address Library to your Skyrim executable, alongside a compatible SkyrimNet build and the required dependencies below.

### Papyrus MessageBox workaround

Papyrus MessageBox is unavailable on Skyrim 1.7.x and Skyrim VR, so dialog-based drink and food requests are unavailable there. To use those actions without their choice dialogs, configure the iActions MCM before requesting them:

- **Drunk Behavior → Auto-Take Alcohol: ON** for drinks taken from your inventory. If the toggle is greyed out, enable **Require Alcohol in Inventory** first.
- **Configuration → Auto-Give Food: ON** for food requests. **Auto-Give Max Food Items** controls the transfer limit.

These settings allow automatic transfers from your inventory without asking you to choose or decline. Keep them enabled, including after an MCM reset. Normal drinking from an NPC's own inventory does not need auto-take; named-drink requests can check your inventory first, so keep it on for those too. Do not rely on the **Auto Give**, **Always Auto Give**, **Give (Choose)** or **Nope** dialogs on 1.7.x or VR; use this workaround instead of installing an incompatible MessageBox DLL. This workaround does not certify the full runtime or other dependencies.

**Upgrading:** Replace the previous iActions mod folder rather than merging files. No clean-save migration is required from v0.6.7. Enable only one iActions copy.

## TL;DR
### **What it does**: NPCs drink, get drunk & sober over time (plus a few extras) via SkyrimNet actions
- **NEW v0.6.8 candidate**: Skyrim VR support; one native DLL for SE/AE and VR. Prior-DLL owner reports and untested runtimes are detailed above; rebuilt candidate needs retesting.
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
- Papyrus MessageBox SE ([Nexus page](https://www.nexusmods.com/skyrimspecialedition/mods/83578)) on runtimes it supports; unavailable on Skyrim 1.7.x and VR, where the MCM workaround above applies
- Optional: Open Animation Replacer (OAR); optional animation add-on [Drunk or drugged animations OAR](https://www.nexusmods.com/skyrimspecialedition/mods/62191)

## Quick Installation
1. Install SKSE / SKSEVR and Address Library / VR Address Library matching your Skyrim executable, SkyrimNet Beta 25 or newer, matching JContainers and PO3 Papyrus Extender SE/VR, and SkyUI SE/VR. Install Papyrus MessageBox only for supported runtimes; on 1.7.x and VR, use the workaround above. OAR and the animation add-on are optional.
2. Install the v0.6.8 candidate ZIP with your mod manager. Its ESP, meshes, Scripts, SKSE, Source and `README-iActions.md` belong at the mod folder root, not inside an extra `iActions/` or `Data/` folder. Enable only one iActions copy.
3. If using OAR and the optional animation add-on, load iActions after them.
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

1. Install **SkyrimNet Beta 25 or newer** first. Install Papyrus MessageBox only for supported runtimes; on 1.7.x and VR use the auto-take/auto-give workaround above.
2. Replace the previous iActions mod folder rather than merging files — save compatible, no clean-save migration needed.

#### From v0.6.0 to v0.6.8

1. Install or update to **SkyrimNet Beta 25 or newer**
2. Replace the previous iActions mod folder rather than merging files — save compatible, no clean-save migration needed.
3. Optional: edit `SKSE/Plugins/iActions/extra_alcohol.json` to add custom drinks

## Credits
The bundled OAR configuration is adapted from [Drunk or drugged animations OAR](https://www.nexusmods.com/skyrimspecialedition/mods/62191) by samuelga24. `Tankard.nif` is a vanilla Skyrim mesh.


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