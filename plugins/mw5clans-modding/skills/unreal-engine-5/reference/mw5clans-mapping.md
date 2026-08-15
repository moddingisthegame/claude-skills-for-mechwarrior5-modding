# MW5 Clans concept → UE5 feature mapping

**What this file is:** a derived cross-reference. The Clans column is either
documented fact from the official Clans modding PDFs (see the
`mw5clans-editor` skill) or **directly verified from the installed Clans
Editor**. The UE5 column is documented fact from Epic's 5.5-pinned
documentation. The *connection between them* is inference — reasonable and
usually obvious, but not something Epic or PGI state explicitly. Confidence is
marked per section.

Engine version: MW5 Clans is **UE 5.5.4**, a stock Epic build. See the version
warning in `../SKILL.md`.

Paths below are relative to `MW5ClansEditor\Modding\` under wherever the Epic
Games Launcher installed the Clans Editor (commonly
`C:\Program Files\Epic Games\`, but Epic lets you install to any drive).

---

## Mods are UE5 Plugins — the single most useful mapping

**Confidence: high.** Verified on disk, not inferred.

Clans mods live at `MW5Clans/Mods/<ModName>/` and contain a real
`<ModName>.uplugin`. From the shipped `Mods/ExampleModMission/`:

```json
{
  "FileVersion": 3,
  "FriendlyName": "ExampleModMission",
  "Category": "Mod",
  "CanContainContent": true,
  "IsMod": true,
  "AddToAssetSearchRoots": true,
  "Plugins": [ { "Name": "DLC00_0", "Enabled": true, "Optional": true }, ... ]
}
```

Three things worth knowing:

- **`IsMod` and `AddToAssetSearchRoots` are stock Unreal fields, not PGI
  inventions.** Verified against the engine's own UnrealBuildTool
  documentation (`Engine/Source/Programs/MW5/bin/Development/net8.0/UnrealBuildTool.xml`),
  which lists `PluginDescriptor.bIsMod` and
  `PluginDescriptor.bAddToAssetSearchRoots` among its fields. So the Clans mod
  system is using UE5's built-in mod-plugin support rather than a bespoke
  layer. `bAddToAssetSearchRoots` is what makes a mod's content discoverable
  to the Asset Manager's `$AssetSearchRoots` scan (see
  [data-assets-and-tables.md](data-assets-and-tables.md)).
- **`mod.json` sits *beside* the `.uplugin` and is PGI-specific.** It carries
  `modPluginName`, `displayName`, `gameVersion`, `steamModVisibility`,
  `packageData.steamPublishedFileId`, and a `dependencies` block with
  `strictDependencies` and `dlcDependencies`. None of that is Unreal. Do not
  describe `mod.json` as a UE5 file.
- **DLC dependencies are expressed twice** — as `Optional: true` plugin
  references in the `.uplugin` *and* as `dlcDependencies` in `mod.json`. The
  `Optional` flag is what lets a mod load for players who lack that DLC.

This is the same mods-as-plugins architecture Mercs used, so that one Mercs
habit does transfer. See [editor-and-assets.md](editor-and-assets.md).

## `LI_*.umap` files are UE5 Level Instances

**Confidence: high.** The Clans mission guide documents the workflow; the
shipped example mod confirms the file layout.

`Mods/ExampleModMission/Content/ModMission/` contains:

```
LVL_ModMission.umap                                   <- the mission level
LevelInstances/LI_ModMission_Gameplay.umap            <- Level Instance
LevelInstances/LI_ModMission_Garrison_Urban_190x190_Town01.umap
```

A **Level Instance** in UE5 is a level asset (`.umap`) placed in another level
as a single actor, so one edit propagates to every placement. Epic's 5.5 docs
describe it as "a level-based workflow designed to improve and streamline the
level editing experience," created by selecting actors and choosing
**Level → Create Level Instance** from the right-click menu.

What this buys you that the Clans docs don't spell out:

- **Editing is in-place.** You do not open the `LI_` map separately and
  hand-sync; you enter edit mode on the instance and commit, and every other
  placement updates.
- **The `LI_` prefix is PGI convention, not engine-enforced.** Any `.umap` can
  be a Level Instance. Following the convention keeps the Content Browser
  sane, nothing more.
- **Packed Level Actors are the sibling feature you probably don't want
  here.** Epic's 5.5 docs recommend them "for static buildings and dense
  visual setups" because they consolidate Static Meshes into one Blueprint
  actor for rendering — but that consolidation is exactly what breaks
  gameplay actors. Clans garrisons contain spawners and objectives, so plain
  Level Instances are correct. *(That last clause is inference.)*

See [levels-and-world.md](levels-and-world.md).

## Clans gameplay tags are stock UE5 Gameplay Tags

**Confidence: high.** Verified from `MW5Clans/Config/`.

`Config/DefaultGameplayTags.ini` sets `ImportTagsFromConfig=True`, and
`Config/Tags/` holds **53 separate `.ini` files** split by domain —
`KelCampaignLogicTags.ini`, `KelUnitAttributeTags.ini`, `MW5ObjectivesTags.ini`,
`MW5MechTags.ini`, `MW5WeaponTags.ini`, `KelUIBreadcrumbingTags.ini`, and so
on. Tags are declared in the stock format:

```ini
+GameplayTagList=(Tag="AI.Behavior.Combat.Attack",DevComment="")
```

This is **identical in mechanism to Mercs** — one of the few places where UE4
knowledge transfers cleanly. The mod template
`ModTemplates/BasicMod/Config/Tags/PLUGIN_NAMETags.ini` ships as an empty
`[/Script/GameplayTags.GameplayTagsList]` section, ready for a mod's own tags,
which is why per-mod tags don't collide.

Two Clans-specific observations:

- **`GameplayTagRedirects` are used heavily.** `DefaultGameplayTags.ini`
  carries a long list of them (e.g.
  `OldTagName="Encounter.Garrison.MainBase.Large"` →
  `NewTagName="Encounter.Garrison.MainOperating.Large"`). This is UE5's
  rename-compatibility mechanism. Practical upshot: **tag names in older
  community guides or videos may be stale** — check the redirect list before
  concluding a documented tag is wrong.
- **The `Kel` vs `MW5` filename split mirrors the class-prefix split.** `Kel*`
  tag files cover Clans-native systems, `MW5*` files cover vocabulary
  inherited from the Mercs codebase. As with class names, a `MW5` prefix does
  **not** guarantee Mercs-identical behavior.

See [gameplay-tags.md](gameplay-tags.md).

## The Editor-restart requirement is an asset-registry/plugin-mount consequence

**Confidence: medium.** The requirement is documented fact; the explanation is
inference.

The Clans docs insist on restarting the Editor after **Save To Mod** and
before **Package**, **Export**, and **Publish** — a step Mercs never required.

The likely mechanism: a mod is a plugin, and a plugin's content root is
**mounted at load time**. Moving an asset into a mod changes which mount point
owns its path, and UE5 does not fully re-mount plugin content roots live.
`AddToAssetSearchRoots` (above) also feeds the Asset Manager's directory scan,
which is performed at startup.

*PGI does not document the reason. Present this as a plausible explanation,
not established fact.* The actionable advice is the same either way: **batch
your overrides and restart once.**

## Mission scripting is Blueprints — but the mission *model* is PGI's

**Confidence: high for the Blueprint half.**

`BP_KelMissionScript_Base` is an ordinary UE5 Blueprint class that you
subclass and fill with an Event Graph. That means stock Blueprint inheritance
rules apply: your subclass inherits variables, components and functions, and
you override or extend them.

The pattern the Clans docs repeat — place actor, make a
**SoftObjectReference** variable of its type, assign the placed actor, call
nodes from it — is UE5 **soft object references**. The reason PGI standardized
on soft rather than hard references is load-time: a soft reference stores a
path and does not force the target to load with the referencing asset. See
[blueprints.md](blueprints.md).

Note the contrast with Mercs, which used **data-driven Mission Flow Nodes**
rather than a Blueprint graph. This is the single biggest conceptual change
between the two games' mission systems, and it means Mercs mission-scripting
knowledge does not transfer.

## Clans uses Enhanced Input — but the documented mod hook is the legacy path

**Confidence: high.** This one is genuinely counterintuitive and verified from
two files.

`Config/DefaultInput.ini` sets:

```ini
DefaultPlayerInputClass=/Script/EnhancedInput.EnhancedPlayerInput
DefaultInputComponentClass=/Script/EnhancedInput.EnhancedInputComponent
```

So the game runs on **Enhanced Input** (Input Actions, Input Mapping Contexts,
Modifiers, Triggers). But the mod template
`ModTemplates/BasicMod/Config/Input/PLUGIN_NAMEInput.ini` offers modders the
**UE4-era legacy syntax**:

```ini
[/Script/Engine.InputSettings]
;+ActionMappings=(ActionName="InputActionName",bShift=False,...,Key=F5)
;+AxisMappings=(AxisName="InputAxisName",Scale=1.0,Key=Gamepad_RightY)
```

This works because Enhanced Input ships an explicit backward-compatibility
path from UE4's input system (Epic's 5.5 docs state it provides "an upgrade
path and backward compatibility from the default input system from Unreal
Engine 4"). *Whether Clans routes legacy mappings through that shim or handles
them separately is not documented — `[verify in 5.5]`.*

Practical guidance: **follow the template.** The commented examples in that
file are the supported, PGI-sanctioned extension point. Do not tell a modder
to author Input Mapping Contexts unless they have confirmed the game consumes
them from a mod plugin.

See [input-and-config.md](input-and-config.md).

## Campaign maps use One File Per Actor

**Confidence: high for OFPA, inference for World Partition.**

`MW5Clans/Content/` contains `__ExternalActors__/` and `__ExternalObjects__/`
directories, with per-map subfolders under
`__ExternalActors__/Maps/Campaign/` — `Courchevel_Base`, `Luthien_Factory`,
`TurtleBay_City`, `MissionHubWorld`, and so on. The project ships **400
`.umap` files** in total.

`__ExternalActors__` is UE5's **One File Per Actor** storage: each actor is
saved as its own package instead of being serialized into the `.umap`.

- **OFPA on the campaign maps is verified fact.**
- **That those maps are therefore World Partition maps is inference.** OFPA
  and World Partition are designed together and Epic's docs describe them as
  working in concert, but OFPA can be enabled on a non-partitioned level.
  Confirm in the Editor's World Settings before asserting it.
- **World Partition is per-map, not per-project** (Epic 5.5 docs). So the
  campaign maps being partitioned would say nothing about what a *mod's* map
  is. The example mod's `LVL_ModMission.umap` should be checked on its own.

Do not read the `bIsWorldPartitioned=False` line in `Config/DefaultEngine.ini`
as evidence about levels — **it sits in a RecastNavMesh navigation section**
(alongside `RegionPartitioning=Watershed` and `LayerChunkSplits`) and concerns
navmesh partitioning, not World Partition. This is an easy and consequential
misread.

See [levels-and-world.md](levels-and-world.md).

## Lighting is fully dynamic — baked lightmaps are gone

**Confidence: high.** Verified from `Config/DefaultEngine.ini` and cross-checked
against Epic's 5.5 Lumen docs.

The project ships:

```ini
r.ReflectionMethod=2              ; Lumen reflections
r.Lumen.HardwareRayTracing=False  ; software ray tracing
r.RayTracing=False
r.Lumen.TraceMeshSDFs=0           ; global distance field, not per-mesh detail
r.GenerateMeshDistanceFields=True ; required by Lumen software tracing
r.Shadow.Virtual.Enable=1         ; Virtual Shadow Maps
r.VirtualTextures=True
```

Epic's 5.5 docs state that enabling Lumen **disables precomputed static
lighting and hides all lightmaps**, and that **static lights are not
supported**. So for a Clans modder: there is no Lightmass bake step, no
"Build Lighting" workflow, and lightmap UVs on your imported meshes do not
matter for direct lighting. This is a hard break from Mercs.

`r.Lumen.TraceMeshSDFs=0` is a deliberate performance choice — Epic documents
this as Global Tracing (lower-detail global distance field) rather than Detail
Tracing (per-mesh distance fields). Expect softer, less precise indirect
lighting on small geometry than a default UE5 project produces.

See [rendering-and-materials.md](rendering-and-materials.md).

## Things that look like a mapping but are NOT

Be careful not to over-generalize:

- **Clans is not a Gameplay Ability System project.** The `Kel*` tag
  vocabulary looks like GAS, but **GameplayAbilities is not enabled** in
  `MW5Clans.uproject` and its `.uplugin` has `EnabledByDefault: false`. Do not
  suggest `GameplayAbility`, `AttributeSet` or `GameplayEffect` classes.
- **PCG, CommonUI, StateTree, MassEntity and Water are all present in the
  engine but disabled.** A folder named
  `__ExternalActors__/Art/Environments/PCG` exists, which is suggestive, but
  the PCG plugin is not enabled by the project — treat the folder name as
  unexplained rather than as evidence PCG is in use.
- **`KelDataLayerTriggerAsset` is a PGI class, not UE5's `UDataLayerAsset`.**
  `Config/DefaultGame.ini` registers it as a primary asset type under
  `/Script/MechWarrior.KelDataLayerTriggerAsset`. The `MechWarrior` module
  prefix marks it as game code. It may well wrap engine Data Layers, but that
  is unverified.
- **`mod.json` / `loadOrder` / Steam publishing metadata is PGI-specific**,
  not UE5 plugin metadata.
- **`Kel*` and `MW*` classes are Clans game code, not engine features.**
  `KelUnitSpawner`, `KelScannableComponent`, `KelCampaignTrigger`,
  `MW.AreaSpecification`, `MWDialogueBook` — UE5 documentation will never
  describe these. The `mw5clans-editor` skill will.
- **The Clans Editor is not a general UE5 install.** It ships no engine C++
  headers (see `../SKILL.md`), and its EULA restricts it to MW5 Clans work.
  UE5 documentation about C++ classes, `.Build.cs` modules or compiling
  plugins is background context only.
