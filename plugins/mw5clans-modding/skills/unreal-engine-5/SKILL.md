---
name: unreal-engine-5
description: "Unreal Engine 5 (UE5) reference oriented toward MechWarrior 5 Clans modding — the engine MW5 Clans is built on (UE 5.5.4). Covers Level Instances and Packed Level Actors, World Partition and One File Per Actor, Data Layers, Lumen and Nanite and Virtual Shadow Maps, Enhanced Input, Blueprints, Gameplay Tags, Data Tables and Primary Data Assets, .uasset/packages/redirectors, and mods-as-plugins. Use when working with UE5 concepts, the MW5 Clans Editor's underlying engine behavior, or translating a Clans modding task into the UE5 feature behind it. Do NOT use for MechWarrior 5: Mercenaries — that is UE 4.23.1; use the unreal-engine-4 skill instead. If the user asks a generic 'what engine does MechWarrior 5 use' question without saying Mercs or Clans, that's ambiguous — ask which game rather than assuming."
---

# Unreal Engine 5 — reference for MW5 Clans modding

MechWarrior 5: Clans and its Editor are built on **Unreal Engine 5.5.4**. This
skill covers the UE5 engine concepts that sit underneath the Clans modding
workflow, so an agent can reason about *why* the Editor behaves the way it does
rather than just following recipes.

Detailed content lives in `reference/` and is **read on demand** — load only
the file(s) relevant to the current question, not all of them.

For the Clans-side workflow itself (Mod Manager, mission setup, OmniMechs),
see the companion skill **`mw5clans-editor`**. This skill is the engine layer
beneath it.

## ⚠ Version boundaries — read before adding or trusting content

- **MW5 Clans runs UE 5.5.4.** Verified from the installed Clans Editor:
  `Modding/Engine/Build/Build.version` reports `MajorVersion 5`,
  `MinorVersion 5`, `PatchVersion 4`, `BranchName "UE5"`, and
  `"IsLicenseeVersion": 0`; `Engine/Binaries/Win64/UnrealEditor.exe` carries
  FileVersion **5.5.4**. `IsLicenseeVersion: 0` means this is a **stock Epic
  build**, not a custom PGI engine fork — so Epic's 5.5 documentation applies
  to the engine layer directly.
- **Pin every Epic doc fetch to 5.5** with `?application_version=5.5`.
  Unversioned `dev.epicgames.com` URLs serve whatever is current (5.6+ at time
  of writing), which drifts.
- **UE5 changes fast between minor versions.** A feature in 5.6 docs may not
  exist in 5.5, and Experimental features change behavior across point
  releases. Where a claim could not be pinned to 5.5, the reference files flag
  it inline as **`[verify in 5.5]`**.
- **Do not import UE4 knowledge unchecked.** Lumen, Nanite, Virtual Shadow
  Maps, World Partition, Level Instances and Enhanced Input have no UE4
  equivalent, and several UE4 habits (baked lightmaps, Levels-window
  sublevels, `ActionMappings` in Project Settings) are either gone or
  demoted. The **`unreal-engine-4`** skill is scoped to Mercs and must not be
  applied here.
- **If you cannot establish which UE version a claim applies to, leave it
  out.** An omission is cheap; a 5.6 fact presented as 5.5 will send a modder
  hunting for UI that does not exist in their Editor.

To fetch more UE5 docs, always append `?application_version=5.5`:
`https://dev.epicgames.com/documentation/en-us/unreal-engine/<slug>?application_version=5.5`

Note: Epic's doc *landing/TOC* pages render their contents via JavaScript and
come back as a bare table of contents to a fetcher — fetch specific content
pages, and use search restricted to `dev.epicgames.com` to discover slugs.

## Reference files — read only what you need

| File | Read this when the question is about... |
|---|---|
| [reference/mw5clans-mapping.md](reference/mw5clans-mapping.md) | **start here for Clans work** — which UE5 feature underlies a given Clans Editor concept (mods-as-plugins, `LI_*` Level Instances, `Config/Tags/*.ini`, `Kel*` classes, the restart requirement) |
| [reference/levels-and-world.md](reference/levels-and-world.md) | Level Instances and Packed Level Actors, World Partition, One File Per Actor (`__ExternalActors__`), Data Layers, persistent levels vs sublevels, level streaming |
| [reference/rendering-and-materials.md](reference/rendering-and-materials.md) | Lumen GI/reflections, Nanite, Virtual Shadow Maps, Virtual Textures, why baked lighting is gone, Material Instances, the exact renderer settings this project ships |
| [reference/input-and-config.md](reference/input-and-config.md) | Enhanced Input (Input Actions, Mapping Contexts, Modifiers, Triggers), legacy `ActionMappings`/`AxisMappings`, and the per-mod `Config/` extension points |
| [reference/gameplay-tags.md](reference/gameplay-tags.md) | hierarchical dot-notation tags, `Config/Tags/*.ini`, tag matching, tag redirects — the system behind every `Objectives.*` / `Encounter.*` / `UI.ColorPalette.*` tag in Clans |
| [reference/blueprints.md](reference/blueprints.md) | Blueprint Classes, parent-class inheritance, Data-Only Blueprints, Level Blueprints, Interfaces, soft vs hard references |
| [reference/data-assets-and-tables.md](reference/data-assets-and-tables.md) | Data Tables, Primary vs Secondary Assets, the Asset Manager, `UPrimaryDataAsset`, Asset IDs, `PrimaryAssetTypesToScan` |
| [reference/editor-and-assets.md](reference/editor-and-assets.md) | `.uasset` files, packages, asset paths and references, redirectors, Plugins and `.uplugin` descriptors, and why Clans mods are plugins |

Typical combinations: a mission-building question usually needs
`levels-and-world.md` + `mw5clans-mapping.md`; a "why does my mod asset not
override" question needs `editor-and-assets.md`; a visual/lighting question
needs `rendering-and-materials.md`; almost any Clans-specific "why does the
Editor do this" question should start with `mw5clans-mapping.md`.

## What this project actually enables — verified from the install

This is the highest-value thing this skill knows, because it prevents
recommending UE5 features that are **not available in Clans**.

**On** (from `MW5Clans.uproject` plus engine defaults): Niagara, Control Rig,
Chaos Vehicles, Chaos Cloth Asset, MetaHuman, RigLogic, Movie Render Pipeline,
Sequencer Scripting, Modeling Tools Editor Mode, Geometry Scripting, Smart
Objects, Python Script Plugin, Editor Scripting Utilities, HDRI Backdrop,
Hair Strands, DLSS / FSR3 / XeSS / Streamline Reflex, OpenXR, Online Subsystem
Steam + Epic.

**Off** — do not suggest these for Clans without checking first:

| Plugin | Status in Clans |
|---|---|
| **PCG** (Procedural Content Generation) | present in engine, `EnabledByDefault: false`, **not** enabled by the project |
| **CommonUI** | present, `EnabledByDefault: false`, **not** enabled |
| **GameplayAbilities** (GAS) | present, `EnabledByDefault: false`, **not** enabled |
| **StateTree** | present, `EnabledByDefault: false`, **not** enabled |
| **MassEntity** | present, `EnabledByDefault: false`, **not** enabled |
| **Water** | present, `EnabledByDefault: false`, **not** enabled |

GAS in particular is worth calling out: Clans has an elaborate
`Kel*`/`MW5*` gameplay-tag vocabulary that *looks* like a Gameplay Ability
System project, but **GAS is not enabled**. Those tags are consumed by PGI's
own systems. See [reference/gameplay-tags.md](reference/gameplay-tags.md).

## The C++ question — answer it plainly when it comes up

The Editor ships **two** mod templates in `MW5Clans/ModTemplates/`:
**`BasicMod`** (content only) and **`CodeMod`** (with
`Source/PLUGIN_NAME/PLUGIN_NAME.Build.cs`, a stock Epic `ModuleRules` file).

The presence of `CodeMod` strongly implies C++ mods are supported. **Be
cautious asserting that.** Verified: this installed build ships **no engine C++
headers** — `Engine/Source/` contains only `Programs/`, with no
`Runtime/`, no `Editor/`, and no `CoreMinimal.h` anywhere. Without engine
headers there is nothing to compile a game module against, even though
UnrealBuildTool itself is present in
`Engine/Binaries/DotNET/UnrealBuildTool/`.

*The missing-headers observation is verified fact; the conclusion that
`CodeMod` is therefore unusable as shipped is **inference**.* Treat C++ modding
as unproven and say so, rather than either promising or denying it. The
official Clans documentation covers only the Basic Mod path.

## Official UE5 sources

| Resource | URL |
|---|---|
| UE 5.5 documentation (version-pinned, what this skill cites) | https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-5-documentation?application_version=5.5 |
| Level Instances | https://dev.epicgames.com/documentation/en-us/unreal-engine/level-instancing-in-unreal-engine?application_version=5.5 |
| World Partition | https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine?application_version=5.5 |
| Lumen | https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-global-illumination-and-reflections-in-unreal-engine?application_version=5.5 |
| Enhanced Input | https://dev.epicgames.com/documentation/en-us/unreal-engine/enhanced-input-in-unreal-engine?application_version=5.5 |

## How this skill was built

Two source classes, and the reference files mark which is which:

1. **The installed MW5 Clans Editor** — `MW5ClansEditor\Modding\` under an
   Epic Games Launcher install (commonly `C:\Program Files\Epic Games\`, but
   Epic lets you pick any drive) — read directly.
   `Build.version`, `MW5Clans.uproject`, `Config/Default*.ini`,
   `Config/Tags/`, `ModTemplates/`, `Mods/ExampleModMission/`, the engine
   plugin `.uplugin` descriptors, and `UnrealBuildTool.xml`. This is a
   **primary source the `unreal-engine-4` skill never had**, and it is why
   this skill can state what Clans actually enables rather than what UE5
   offers in general.
2. **Epic's official documentation**, every request pinned with
   `?application_version=5.5`.

Deliberately excluded: UE 5.6+ material; features present in the engine but
disabled in this project (listed above) beyond noting that they are off; and
C++-programming topics that a Basic Mod user cannot act on.

`mw5clans-mapping.md` is explicitly **derived** — it connects verified UE5
documentation and verified on-disk project configuration to the official Clans
modding docs. Each mapping notes which side is documented fact and which is
inference, and carries a confidence marking.
