# UE5 Data Assets, Data Tables, and the Asset Manager in Clans

Sources: `MW5Clans/Config/DefaultGame.ini` in the installed Clans Editor, plus
Epic's Asset Manager / Data Asset documentation.

This subsystem is where Clans is most heavily invested, and understanding it
explains both the `.uplugin` `AddToAssetSearchRoots` flag and the
Editor-restart requirement.

## Primary vs Secondary assets

UE5 splits assets in two:

| | Behavior |
|---|---|
| **Primary Asset** | directly managed by the **Asset Manager**, addressable by an `FPrimaryAssetId` of the form `Type:Name`, discoverable without something referencing it |
| **Secondary Asset** | loaded because a Primary Asset (or a loaded object) references it |

`UPrimaryDataAsset` is Epic's recommended base class for designer-authored
data assets, and **Data-Only Blueprints can inherit from it**.

The distinction is what makes a game data-driven: primary assets can be
enumerated and loaded by ID at runtime, so content can be added without code
changes. That is precisely what a mod needs.

## How Clans uses it — the numbers

`Config/DefaultGame.ini` registers **121 `PrimaryAssetTypesToScan` entries**.
A representative slice of the type names:

```
KelCampaignDataAsset          KelChassisUpgradeAsset
KelCampaignTriggerAsset       KelChassisGroupAsset
KelBattleMapAsset             KelCrewItemDataAsset
KelAreaModifiersAsset         KelCommendationAsset
KelAdvancedMissionParameterAsset  KelDataLayerTriggerAsset
```

A full entry looks like this:

```ini
+PrimaryAssetTypesToScan=(PrimaryAssetType="KelDataLayerTriggerAsset",
  AssetBaseClass="/Script/MechWarrior.KelDataLayerTriggerAsset",
  bHasBlueprintClasses=False, bIsEditorOnly=False,
  Directories=((Path="$AssetSearchRoots")), SpecificAssets=,
  Rules=(Priority=-1,ChunkId=-1,bApplyRecursively=True,CookRule=Unknown))
```

Three things to read out of that:

- **`AssetBaseClass=/Script/MechWarrior.*`** — every one of these is PGI game
  code in the `MechWarrior` module. Epic's documentation will never describe
  `KelChassisUpgradeAsset`. The `mw5clans-editor` skill is the source for what
  they mean.
- **`Directories=((Path="$AssetSearchRoots"))`** appears in **119 of the 121
  entries**. This is the hook that makes modding work at all.
- **`bHasBlueprintClasses`** distinguishes types scanned for Blueprint
  subclasses from types scanned for data asset instances.

## `$AssetSearchRoots` — why your mod's assets are found

`$AssetSearchRoots` is a token expanded by the Asset Manager into the set of
content roots it should scan. A plugin joins that set when its `.uplugin`
declares:

```json
"AddToAssetSearchRoots": true
```

which the shipped `Mods/ExampleModMission/ExampleModMission.uplugin` does, and
which is a **stock Unreal field** (`PluginDescriptor.bAddToAssetSearchRoots`,
verified in the engine's own `UnrealBuildTool.xml`).

So the chain is:

```
mod .uplugin sets AddToAssetSearchRoots
  → mod's Content root joins $AssetSearchRoots
    → the 119 PrimaryAssetTypesToScan entries scan it
      → a KelCampaignTriggerAsset in your mod is discovered like a shipped one
```

**This is the mechanism behind "just put an asset of the right type in your
mod and the game picks it up."** It also explains why the Clans docs demand an
Editor restart: the Asset Manager performs its directory scan at startup, and
a newly mounted plugin root was not in `$AssetSearchRoots` when that scan ran.
*(The restart explanation is inference — see `mw5clans-mapping.md`.)*

Practical consequences:

- **Asset *type* matters more than folder location** within your mod. The scan
  is recursive (`bApplyRecursively=True`).
- **Renaming a data asset can break references**, because
  `FPrimaryAssetId` is `Type:Name`. Editing contents in place is safe;
  renaming is not. Rename only via the Content Browser so a redirector is
  left behind — see [editor-and-assets.md](editor-and-assets.md).
- **Adding a genuinely new primary asset *type* requires a `DefaultGame.ini`
  entry**, which a content-only mod cannot supply for itself. *Whether Clans
  merges plugin-level `DefaultGame.ini` additions is unverified* — the Basic
  Mod template ships no `DefaultGame.ini`, which suggests not. Work within the
  121 existing types.

## Data Tables

**Data Tables** are row-based assets: rows keyed by a `Name` column, columns
mapping 1:1 to a C++ `UStruct` inheriting `FTableRowBase`. **Curve Tables** are
the float-curve equivalent.

Unchanged from UE4:

- **CSV and JSON import/export** are both available from the asset's context
  menu and the Data Table editor.
- **A duplicated Data Table keeps pointing at the original's imported source
  data** until you re-import from your own file. This is the trap behind the
  Mercs "export as JSON first" instruction.
- Data Tables can be edited with the editor running.

### The important caveat for Clans

**Mercs' signature technique — export a stats DataTable to JSON, repoint a
Weapon Data Asset at your copy — has no documented Clans equivalent.** The
official Clans PDFs do not describe a DataTable modding workflow. Given how
heavily Clans leans on the 121 primary Data Asset types instead, it is
plausible PGI moved that data into Data Assets.

*Unverified either way.* Do not tell a Mercs veteran the JSON-DataTable trick
transfers. Point them at the Data Asset types first, and have them confirm in
the Editor.

## Soft references and load cost

Because Clans mission scripting standardizes on **SoftObjectReference**
variables (see [blueprints.md](blueprints.md)), it is worth stating the
principle here: a **hard** reference forces the target to load whenever the
referencing asset loads; a **soft** reference stores a path and loads on
demand.

In a game with 121 scanned primary asset types, hard-referencing widely from a
mod asset is how you accidentally pull a large dependency chain into memory.
Prefer soft references in mod content, matching PGI's own convention.
