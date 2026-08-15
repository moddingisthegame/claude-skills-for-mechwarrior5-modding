# MW5 Mercenaries vs. MW5 Clans — modding differences

For modders coming from Mercs. **These are different games with different
tooling on different engine generations.** Habits transfer; specifics do not.

Sourced from the official Clans PDFs and the MW5 Mercs Mod Editor Guide v2.3
(see the `mw5mercs-editor` skill). Where a row is marked
*unverified*, it has not been confirmed against a primary source.

## Engine

| | Mercs | Clans |
|---|---|---|
| Engine | **UE 4.23.1** | **UE 5.5.4** (game shipped 16 Oct 2024) |

Clans' exact version is verified from the installed Clans Editor:
`Engine/Build/Build.version` reports Major 5 / Minor 5 / Patch 4 with
`"IsLicenseeVersion": 0`, and `UnrealEditor.exe` carries FileVersion `5.5.4`.

This is the single most consequential difference. The **`unreal-engine-4`**
skill explicitly excludes UE5 and **should not be applied to Clans** — UE5
differs substantially in landscape, lighting (Lumen/Nanite), and level
composition. Notably, the Clans mission guide uses **Level Instances**, a UE5
workflow with no UE4 equivalent. Use the **`unreal-engine-5`** skill for the
engine layer beneath Clans.

## Editor workflow

| | Mercs | Clans |
|---|---|---|
| Toolbar | **Create Mod**, **Manage Mod**, **Active Mod** selector | Single **Mod Manager** window |
| Templates | none documented | must pick **"Basic Mod"** (Create Mod stays greyed out otherwise) |
| Mod content location | `<ModName> Content` + `ModOverride Content` | `Plugins/<ModName>` with a `ModOverride` subfolder |
| Override an asset | right-click → **Save To Mod**; takes effect immediately | right-click → **Save To Mod**; **requires an Editor restart** |
| Remove an override | not documented | right-click base asset → **Delete from Mod** |
| Distribution | Package Mod → copy folder into the game's `Mods` folder manually | **Package**, then **Export** *or* **Publish direct to Steam Workshop** from the Editor |
| Extra prerequisites | none | **.NET 8.0 SDK** |

Two workflow traps for a Mercs modder:

1. **The restart requirement is real and repeated.** Clans docs state it for
   overrides *and* before Package, Export and Publish. Mercs had no such step.
   Batch your overrides and restart once.
2. **Clans can publish to Steam Workshop from inside the Editor.** In Mercs
   this was entirely manual.

## Mission scripting — the biggest conceptual change

| | Mercs | Clans |
|---|---|---|
| Model | **Mission Flow Nodes** — a data-driven graph with `Additional Mission Data` parameters per node | **`BP_KelMissionScript_Base`** — an ordinary Blueprint you subclass and fill with an Event Graph |
| Campaign hook | **Campaign Arc** + **Metagame Objective** + Arc Actions | **`KelCampaignTrigger`** + **`KelLocaleDataAsset`** (Holotable) + **`MW.ScenarioSpecification`** |
| Area definition | **AreaSpec** | **`MW.AreaSpecification`** (same idea, `MW.`-prefixed asset) |

In Clans nearly every mission feature follows one pattern: place the actor,
make a **SoftObjectReference** variable of its type in the MissionScript,
assign the placed actor to it, then call nodes from it. Learning that pattern
once covers most of the mission guide.

## Naming

Clans uses a **`Kel`** prefix throughout (`KelUnitSpawner`,
`KelScannableComponent`, `KelCampaignTrigger`, `KelBuildMap`, `KelUI`) — from
the internal codename **Kelpie**, also visible in the Wwise project path
`WwiseProjectKelpie\kelpie\kelpie.wproj`.

Some **`MW`**-prefixed types survive from Mercs (`MWObjective`,
`MWSpawnPoints`, `MWDialogueBook`, `MW.AreaSpecification`), so a `MW` prefix
does **not** mean an asset is shared or behaves identically. Check the Clans
docs rather than assuming.

## Audio (Wwise)

| | Mercs | Clans |
|---|---|---|
| Wwise version | **2021.1.2.7629** | **2024.1.1.8691** |
| Extra plugins | Wwise Convolution, McDSP ML1/Futzbox | **Motion**, **AK Convolution** |
| Project path | project's `WwiseProject` folder | `MW5CEarlyEditor\Editor\MW5Clans\WwiseProjectKelpie\kelpie\kelpie.wproj` |

Both use the Short ID → Audiokinetic Event → Post Event flow, and both warn
that skipping a named soundbank risks cross-mod conflicts. **The Wwise
versions are not interchangeable** — each editor requires its exact version.

## OmniMech / mech variant creation

> **"OmniMech" is not a Clans-exclusive term — don't let it alone signal
> which game a user means.** MW5 Mercenaries added its own OmniMechs (Clan
> chassis such as the Timber Wolf/Mad Cat) via the *Legend of the Kestrel
> Lancers* DLC, using **OmniSlots** — hardpoints flexible on weapon category
> (missile/ballistic/energy) rather than fixed to one. **This is a different
> mechanic from Clans' Omnipods.** Mercs OmniMechs have no swappable
> per-location Omnipod content-package system; modding one is the ordinary
> Mercs workflow — one `MWMechLoadoutAsset` per variant, weapons assigned via
> the `Hardpoint ID` dropdown, same as any other Mercs 'Mech (see
> `mw5mercs-editor`'s `reference/mod-editor-guide.md`). **No Clans-style
> Omnipod/Omnipod Bundle setup applies.** *This paragraph is sourced from
> general game/community information, not the official Mod Editor Guide
> (which predates this DLC) — treat the OmniSlot mechanics above as
> lower-confidence than the PDF-sourced rows elsewhere in this file, and
> verify specifics in the live editor if precision matters.*

Sourced from the video-derived [omnimech-setup.md](omnimech-setup.md) (no
PDF covers this). The official OmniMech tutorial repeatedly contrasts itself
against the Mercs mech-creation workflow:

| | Mercs | Clans OmniMech |
|---|---|---|
| MDA per variant | One MDA per variant/tag | **One MDA per chassis**, shared by every variant — check "Can Equip Omnipods" and nothing else changes |
| Unit Card | Required to define a player mech | **Not required** for a player-selectable OmniMech loadout — Unit Cards are only for spawning NPC mechs in a level |
| Hardpoint assignment format | — | Described as "a very similar format" to Mercs hardpoint assignment |

Battlemech (non-Omni) creation in Clans is described as its own, separate,
not-yet-documented process "more similar to Mercs" than the OmniMech
workflow above — treat that as a pointer to unwritten territory, not a
confirmed equivalence.

## Content that crosses over

The Clans mission guide explicitly imports **Garrisons from MW5 Mercenaries**
for destructible-zone objectives — but instructs you to **delete the foliage
and landscape actors, which "aren't used in clans, so won't work."**

Treat that as the general rule: Mercs assets may be present and partially
usable, but Mercs-era subsystems are not guaranteed to function.

## What has no Clans equivalent documented

Mercs' **custom DataTable** workflow (export a stats table as JSON, repoint a
Weapon Data Asset at it) and **custom Gameplay Tag containers**
(`Config/Tags/<ModName>Tags.ini`) have **no counterpart in the Clans
documentation**. *Unverified whether equivalents exist and are simply
undocumented.* Do not assume the JSON-DataTable trick — the most
update-resilient Mercs technique — transfers to Clans without checking.
