---
name: mw5mercs-editor
description: "Reference for official MechWarrior 5 Mercenaries (MW5 Mercs) modding resources — Mod Editor install/workflow (substitution mods, new-asset mods, Wwise audio), 'Mech Loadout and weapon modding via hardpoints (including Mercs' own DLC-added OmniMechs, which use the same Loadout/hardpoint system, NOT Clans-style Omnipods), the full Mission Flow Node scripting reference, the Mission Building Quick-Start (terrain/markup/AreaSpec) guide, and Adding Custom Missions to Campaign (Campaign Arc/Metagame Objective). Also ships a status script for inspecting a RUNNING Mod Editor session (process, loaded map, shader compile progress, which mod plugin exists, filtered errors/warnings) — Claude cannot see the editor UI, so run it whenever the user says the editor is open, reports something broken, or has just created/saved/packaged a mod. Use when the user asks about modding, the MW5 Mercs Mod Editor, 'Mech/weapon/OmniMech modding, mission creation/scripting, mission flow nodes, campaign arcs, finding/installing MW5 Mercs mods, or what their editor session is currently doing. Do NOT use for MechWarrior 5: Clans — that is a separate game on UE5 with its own tooling; use the mw5clans-editor skill for Clans. If the user says only 'MechWarrior 5' or 'MW5' without naming Mercs or Clans, that's ambiguous — ask which game before proceeding rather than assuming."
---

# MechWarrior 5: Mercenaries — Official Modding Resources

This is primarily a reference skill: there is no app or service in this
directory to launch, and nothing here drives the Mod Editor. It does ship
one **observation** script — `scripts/mw5-editor-status.ps1`, which reads a
running editor's log and project files (see "Live session awareness"
below). It indexes the official MW5 Mercs modding
resources page and the full content of every MW5-Mercs-specific document it
links to. The detailed content lives in `reference/` and is **read on
demand** — load only the file(s) relevant to the current question, not all
of them, to keep this skill token-efficient as more reference material gets
added.

**Game scope:** This covers **MechWarrior 5: Mercenaries** only.
MechWarrior 5: Clans is a separate, standalone game with different tooling
and is out of scope here — do not apply these resources to it. Clans runs on
**UE 5.5.4** (Mercs is UE 4.23.1) and has its own editor, mission-scripting model
and asset naming. For Clans, use the **`mw5clans-editor`** skill; for what
does and doesn't carry over between the two, see that skill's
`reference/mercs-vs-clans.md`.

**Companion skill:** MW5 Mercs is built on **Unreal Engine 4** (4.23.1). For
the engine concepts underneath this workflow — Blueprints and parent-class
inheritance, Gameplay Tags, Data Tables and Data Assets, `.uasset` paths and
redirectors, plugins, sublevels, landscape layers, foliage, NavMesh — use the
**`unreal-engine-4`** skill. It includes an MW5-concept→UE4-feature mapping.

## Reference files — read only what you need

| File | Read this when the question is about... |
|---|---|
| [reference/eula.md](reference/eula.md) | licensing/legal terms for the Mod Editor or distributing mods |
| [reference/mod-editor-guide.md](reference/mod-editor-guide.md) | installing the Mod Editor, the Create Mod/Manage Mod/packaging workflow, substitution vs. new-asset mods, custom data tables/tags, or Wwise **audio** modding |
| [reference/mission-creation-guide.md](reference/mission-creation-guide.md) | building a mission from scratch: terrain, markup levels, locators, AreaTiles, AreaSpec, wiring Mission Flow Node logic together |
| [reference/mission-flow-nodes.md](reference/mission-flow-nodes.md) | the exact node type / `Additional Mission Data` parameters for a specific mission behavior (spawn AI, timer, destroy building, go-to, evac, etc.) |
| [reference/campaign-integration.md](reference/campaign-integration.md) | hooking a finished mission into the campaign/starmap (Campaign Arc, Metagame Objective, Arc Actions) |

Typical combinations: building a new mission usually needs
`mission-creation-guide.md` + `mission-flow-nodes.md` together; inserting
that mission into the campaign additionally needs
`campaign-integration.md`; anything about the editor itself (install,
packaging, weapons/loadouts, audio) only needs `mod-editor-guide.md`.

## Live session awareness — `scripts/mw5-editor-status.ps1`

**Claude cannot see the Mod Editor.** No viewport, no Content Browser, no
open Blueprint, no dialog boxes. When the user says "I opened the editor",
"I made a mod", or "it's broken", none of that is visible. This script is
the only window in, and it is written for Claude to read — terse
`KEY value` lines, not a human dashboard.

```powershell
& '<skill>/scripts/mw5-editor-status.ps1'        # new activity since last run
& '<skill>/scripts/mw5-editor-status.ps1' -Full  # whole log, ignore state
```

It reports: editor process + uptime + RAM, log freshness, shader-compile
backlog, loaded map, **user mod plugins** (anything in `Plugins/` that
isn't stock), `modlist.json` state, and errors/warnings with known-benign
families suppressed.

### Run it when

- **The user first mentions the editor is open.** Establishes the baseline
  — which mod exists, what map, is it still compiling. Cheap, and it has
  already caught a mod plugin appearing that was otherwise invisible.
- **Before diagnosing anything.** "Why won't my mod load / why is my
  weapon missing / why did packaging fail" — read the log before
  theorising. Guessing at MW5 mod problems without the log wastes turns.
- **After the user does something in the editor** — created a mod, saved
  an asset, packaged. Confirms it actually happened on disk.
- **Before claiming the editor is ready.** A 2-minute map load and a long
  shader queue are normal; `BUSY shaders_left=N` says whether "it's stuck"
  is really "it's working".
- **On an interval during active work**, via the `loop` skill, so errors
  surface as they happen rather than when someone thinks to ask.

### Don't run it when

The editor isn't open, or the question is pure reference ("what does the
Set Objective node do") — that is what `reference/` is for. It reads a
multi-MB log; it is not free.

### Reading the output

- `NEW +N lines` — repeat runs report only new activity. State lives in
  `%TEMP%\mw5-editor-status.state` and self-resets when the log shrinks
  (editor restart). `-Reset` re-baselines, `-Full` ignores state.
- `MODS plugins:` — **the highest-signal line.** `none (stock only)` means
  no mod has been created yet, so there are no text files to edit and the
  user's first step is **Create Mod**.
- Repeated identical errors are de-duplicated and capped at 8 per severity.

### Maintaining the suppression list — important

The `$Benign` array at the top of the script is the reason it is useful.
Without it a run buries real problems under ~100 lines of missing-VFX,
cold-DDC, and callstack noise. **When a warning family is investigated
and found harmless, add it to `$Benign` with a `Why =` note** explaining
what cleared it, so a later session can distinguish "investigated,
harmless" from "someone silenced a real bug".

Suppress narrowly. Scope patterns to the specific message, never to a
whole log category — the existing entry hides one named DataValidation
ensure and bare callstack frames while leaving every other
`Ensure condition failed:` visible. Use `-ShowBenign` to audit what is
being hidden.

**Known-noisy but NOT suppressed, deliberately:** PGI's stock content
ships with Blueprint compile errors (`EncounterClassParent`,
`MissionComponent`, `ScenarioGeneratorClass`, a `DEADPACKAGE` level
generator). Not caused by the user, but they matter if a mod subclasses
those assets, so they stay visible.

## Official source documents (real URLs)

| Document | URL |
|---|---|
| Modding resources landing page | https://mw5mercs.com/resources/2020/01/29-modding-resources |
| Mod Editor EULA | http://static.mw5mercs.com/docs/MW5_Mod_Editor_EULA.pdf |
| Mod Editor Guide (v2.3) | https://static.mw5mercs.com/docs/MW5Mercs_Mod_Editor_Guide_(v2.3).pdf |
| Mission Scripting Reference (Mission Flow Nodes) | https://mw5mercs.com/static/docs/MW5%20Mission%20Scripting%20Reference.pdf |
| Mission Campaign Integration Guide | https://mw5mercs.com/static/docs/MW5%20Mission%20Campaign%20Integration%20Guide.pdf |
| Mission Creation Guide | https://mw5mercs.com/static/docs/MW5%20Mission%20Creation%20Guide.pdf |
| Finished Tutorial Save File (mod content folder, zip) | https://mw5mercs.com/static/downloads/mymod-content-folder.zip |
| Mission Building video series (Parts 1–5) | https://youtu.be/ScwhbGx7LZ0, https://youtu.be/BJyKxCISrV0, https://youtu.be/ROQJShWCDFw, https://youtu.be/VpBMu9vSbpo, https://youtu.be/x5X2QcBZ1No |
| Modding Discord invite | https://discord.gg/2DXB6Zt |
| Steam Workshop | https://steamcommunity.com/app/784080/workshop/ |
| Epic Games Store mods | https://store.epicgames.com/en-US/all-mods/mechwarrior-5 |
| Nexus Mods | https://www.nexusmods.com/mechwarrior5mercenaries/mods/ |

General UE4 docs/learning links (not fetched in depth — genuinely generic
UE4 material, not MW5-specific): UE4 Documentation, UE4 Online Learning, and
Epic's "Getting Started with UE4" / "Live Training" YouTube playlists, all
linked from the landing page above.

## Community

Official MW5 Mercs modding Discord: https://discord.gg/2DXB6Zt — for
discussing modding ideas/methods with PGI staff and other modders.

## Finding and Installing Mods

Not the only sources, but the official starting points: Steam Workshop,
Epic Games Store mods, Nexus Mods (URLs in the table above).

**Support boundaries (per Piranha Games, the developer):**
- PGI is not responsible for game performance, save file, or config file
  issues caused by installing mods, nor for hardware issues.
- PGI does not offer customer support for getting mods working.
- PGI can guide restoring the game to its default (unmodded) installation
  state.
- Recommendation to pass along: back up savegames and config files before
  installing any mods.

## Notes on how this skill was built

Built by fetching and reading (via direct PDF extraction, not the lossy
web-summarizer path) every MW5-Mercs-specific document linked from the
official resources landing page — the EULA, the v2.3 Mod Editor Guide,
the full Mission Flow Node Scripting Reference, the Mission Building
Quick-Start guide, and the Campaign Integration guide — then split into
the `reference/` files above for progressive disclosure. General UE4
documentation/learning links and the raw mod-listing sites (Steam
Workshop/Epic/Nexus) were deliberately not fetched in depth — they're
either generic third-party engine docs or live, frequently-changing mod
listings, neither of which benefits from being frozen into this skill.

`scripts/mw5-editor-status.ps1` was added later, after a session where
locating the editor log took several wrong guesses (it lives under
`%LOCALAPPDATA%\MW5Mercs\Saved\Logs\`, **not** the project's `Saved\`) and
triaging its warnings burned a chunk of context. Both of those are one-time
discoveries now baked into the script, which is the whole reason it earns
its place: the per-session facts get collected automatically, and the
already-answered questions stop being re-asked.

There is still no code here to build/launch/drive — if a real MW5 Mercs mod
project (UE4 project files, a mod source tree) shows up later, that would
warrant an actual run/build skill in addition to this reference one.
