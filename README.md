![iActions welcomes you!](images/iActions-banner.png)
# iActions [Drunk+] for SkyrimNet - Quick Start

## 👉 [**Latest Release v0.6.6 here!!!**](https://github.com/Gerkinfeltser/iActions/releases/tag/0.6.6)

> ## ⚠️ **Warning: Experimental**
> Test on separate/non-precious saves first if you're risk-averse!  
> **SkyrimNet Beta 25 or newer is REQUIRED for iActions v0.6.6; earlier SkyrimNet versions are not supported.**
> **Upgrading from iActions v0.6.5 is save-compatible and does not require a clean install.** [See upgrade notes below](#upgrading)
> (For overly-detailed documentation on all the things, see the [iActions Wiki](https://github.com/Gerkinfeltser/iActions/wiki).)

## v0.6.7 compatibility candidate (unreleased)

Targets one native DLL for Skyrim **1.5.97.0, 1.6.640.0, 1.6.1170.0, 1.7.99.0 and 1.7.104.0**, using pinned MIT MinLL/CommonLibVR v4.39.5 with a shared SE/AE virtual-layout correction. VR and unnamed patches are not in scope. These are compatibility targets, not five passing game tests.

Requires matching SKSE, Address Library and SkyrimNet builds plus the existing full-mod dependencies. No gameplay/save-format changes are intended; use a separate test profile and preserve save/co-save rollback copies. A DLL-only override is not a complete mod upgrade.

The bundle/native candidate version is 0.6.7; no new GitHub or Plugin Hub release is implied. The historical Hub 0.6.7 label referred to mod 0.6.6. Build and per-runtime evidence are maintained in the development repository's `_docs/DEVNOTES.md`.

RC2 removes `customCategory` from `drink_alcohol`, `receive_food`, `have_arrows_extracted` and `sobers_up`, and removes the `food_and_drink` / `health_and_recovery` category definitions. These actions are now standalone candidates, subject to their existing eligibility checks. Native/Papyrus gameplay and save formats are unchanged.

When upgrading from a categorized build, replace the old iActions mod folder rather than merging files: deleted category YAMLs must not remain in the winning MO2 content. Disable the previous iActions copy and any competing development override.

**ADT test, 2026-10-07:** The user confirmed drinking worked. The archived session shows `drink_alcohol` directly exposed, selected and dispatched for Brenuin, followed by fallback from unavailable Nord Mead to player-provided Ale and the completed “now buzzed (0 left)” transition. A second drink started, but its completion was outside the capture. This verifies one drinking/intoxication path, not the complete runtime matrix: sobering, save/reload, native inventory payload correctness and exact loaded executable/DLL identity remain unverified.


## TL;DR
### **What it does**: NPCs drink, get drunk & sober over time (plus a few extras) via SkyrimNet actions
- **NEW v0.6.6**: **REQUIRES SkyrimNet Beta 25 or newer**; moves content into the `phospheneoverdrive.iactions` external bundle, adopts snake_case action identifiers, groups related actions under Food and Drink / Health and Recovery, and prevents `exchange_items` from being suggested for merchant transactions
- **NEW v0.6.5**: 26 vanilla drinks recognized (was 15), custom drinks via JSON config, specific drink selection by name, smart NPC alcohol inventory via SKSE decorator
- **v0.6.0**: Receive Food — Followers request food via dynamic dialog, configurable tier priority and auto-give
- **v0.5.7**: Sleep Sobering — Drunk NPCs gradually sober up while you sleep (configurable PointsPerSleepHour, default: 4)
- **v0.5.5**: NPCs can sit & drink at the same time... generally, prompt updated & ready for SkyrimNet Beta14
- **v0.5.1.x**: NPCs can now request to trade items with you
- **v0.5.0**: 5-tier drunk system (Buzzed→Blackout), major performance optimizations, new MCM settings, rebranded to clarify non-official status
- **Install**: Mod manager → Load after OAR drunk animations → Configure in MCM
- **Requirements**: Skyrim SE/AE + **SkyrimNet Beta 25 or newer (REQUIRED; earlier versions unsupported)** + OAR + JContainers + PO3_SKSEFunctions + [Papyrus MessageBox](https://www.nexusmods.com/skyrimspecialedition/mods/83578) + [drunk animations](https://www.nexusmods.com/skyrimspecialedition/mods/62191) (optional)

## Quick Installation
1. Install requirements (**SkyrimNet Beta 25 or newer is required**, plus OAR, JContainers, PO3_SKSEFunctions, and [Papyrus MessageBox](https://www.nexusmods.com/skyrimspecialedition/mods/83578))
2. Install iActions with mod manager
3. Load AFTER OAR drunk animations mod
4. Configure in MCM menu

### Upgrading

> **iActions v0.6.6 requires SkyrimNet Beta 25 or newer.** Install or update SkyrimNet before launching the game.

#### From v0.6.5 to v0.6.6 (Safe update)

1. Install or update to **SkyrimNet Beta 25 or newer**
2. Update iActions normally — **no clean install or uninstall preparation is required**
3. Review SkyrimNet plugin enablement, priority, Hub association, and overlay relationships after upgrading
4. Reapply any per-action settings stored under the old action names

The external bundle now uses plugin id `phospheneoverdrive.iactions`, and all action names use snake_case. The wake-up event is no longer included in iActions and is distributed by a separate plugin.

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

#### From v0.5.7 to v0.6.6 (Safe update)

1. Install [Papyrus MessageBox](https://www.nexusmods.com/skyrimspecialedition/mods/83578) and **SkyrimNet Beta 25 or newer** first
2. Update iActions normally — save compatible, no clean migration needed

#### From v0.6.0 to v0.6.6 (Safe update)

1. Install or update to **SkyrimNet Beta 25 or newer**
2. Update iActions normally — save compatible, no clean migration needed
3. Optional: edit `SKSE/Plugins/iActions/extra_alcohol.json` to add custom drinks

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
