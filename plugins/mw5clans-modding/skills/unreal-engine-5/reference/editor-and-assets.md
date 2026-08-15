# UE5 assets, packages, plugins, and how Clans mods are built

Sources: `MW5Clans/Mods/ExampleModMission/`, `MW5Clans/ModTemplates/`,
`MW5Clans.uproject`, and the engine's own
`Engine/Source/Programs/MW5/bin/Development/net8.0/UnrealBuildTool.xml` in the
installed Clans Editor, plus Epic's plugin and asset documentation.

## Assets, packages, and paths

Unchanged from UE4 in all the ways that matter:

- A **`.uasset`** file is a **package** containing one or more objects.
- **Path is identity.** A reference embeds the object's full path, e.g.
  `/Game/Characters/MyCharacter.MyCharacter`. Two assets at different paths are
  different assets no matter how identical their contents.
- **`/Game/`** maps to the project's `Content/` folder. **Plugin content
  mounts under its own root**, not under `/Game/` — which is why a mod's
  content appears as a sibling of the main Content folder in the Content
  Browser rather than a subfolder of it.
- **`.umap`** is the package extension for levels.

### Redirectors

Renaming or moving an asset **in the Content Browser** leaves an invisible
**Redirector** at the old path so existing references keep resolving.
**Fix Up Redirectors in Folder** resolves and removes them.

Moving or renaming `.uasset` files **in Windows Explorer bypasses this and
breaks references.** This is more dangerous in UE5 than it was in UE4, because
of One File Per Actor: an OFPA map is a `.umap` plus a directory of actor
packages under `Content/__ExternalActors__/<MapPath>/`, keyed to the map's
path. Moving the `.umap` in Explorer orphans every actor in it. See
[levels-and-world.md](levels-and-world.md).

## Plugins — and why Clans mods are plugins

A UE5 plugin lives at `[Project Root]/Plugins/[Plugin Name]/` (Clans uses
`Mods/` as an additional mod root) and is described by a **`.uplugin`** JSON
descriptor. A plugin may carry its own `Content` folder when its descriptor
sets `"CanContainContent": true`.

The shipped `Mods/ExampleModMission/` demonstrates the full Clans mod layout:

```
ExampleModMission/
  ExampleModMission.uplugin        <- UE5 plugin descriptor
  mod.json                         <- PGI mod metadata (NOT Unreal)
  Resources/Icon128.png
  Config/
    Input/ExampleModMissionInput.ini
    Tags/ExampleModMissionTags.ini
    InstanceTypes.ini
  Content/
    ModMission/
      LVL_ModMission.umap
      LevelInstances/LI_*.umap
      LevelSequences/LS_*.uasset
      Missions/BP_ModMission_MissionScript.uasset
      Missions/ModMission_AreaSpec.uasset
      Missions/CustomUnits/*.uasset
      Missions/Dialogue/*.uasset
```

### The `.uplugin` descriptor

```json
{
  "FileVersion": 3,
  "Version": 1,
  "VersionName": "1.0",
  "FriendlyName": "ExampleModMission",
  "Category": "Mod",
  "CanContainContent": true,
  "IsMod": true,
  "AddToAssetSearchRoots": true,
  "Plugins": [
    { "Name": "DLC00_0", "Enabled": true, "Optional": true },
    { "Name": "DLC00_1", "Enabled": true, "Optional": true },
    { "Name": "DLC01_0", "Enabled": true, "Optional": true }
  ]
}
```

**All of these are stock Unreal fields.** Verified against the engine's own
UnrealBuildTool documentation, which lists `PluginDescriptor.bIsMod`,
`PluginDescriptor.bAddToAssetSearchRoots` and
`PluginDescriptor.bCanContainContent` among ~39 descriptor fields. Clans is
using UE5's built-in mod-plugin support, not a bespoke PGI layer.

- **`IsMod`** marks the plugin as a mod rather than an engine/project plugin.
- **`AddToAssetSearchRoots`** adds the plugin's content to the Asset Manager's
  `$AssetSearchRoots` scan — the mechanism that makes mod data assets
  discoverable. See [data-assets-and-tables.md](data-assets-and-tables.md).
- **`Optional: true`** on the DLC plugin references is what lets the mod load
  for players who do not own that DLC. Without it, a missing dependency is
  fatal.

### `mod.json` is PGI's, not Unreal's

```json
{
  "modPluginName": "ExampleModMission",
  "displayName": "ExampleModMission",
  "version": "1.0",
  "gameVersion": "1.0.4182",
  "steamModVisibility": "Private",
  "packageData": { "buildNumber": 0, "steamPublishedFileId": 0, ... },
  "dependencies": {
    "strictDependencies": [],
    "dlcDependencies": ["DLC00_0", "DLC00_1", "DLC01_0"]
  }
}
```

None of this is Unreal. `gameVersion`, Steam publishing state, and the
`strictDependencies` / `dlcDependencies` split are all PGI's mod system.

**Note that DLC dependencies are declared twice** — as `Optional` plugin
entries in the `.uplugin` *and* in `mod.json`'s `dlcDependencies`. If a modder
edits one by hand, they must edit both.

## Mod templates

`MW5Clans/ModTemplates/` ships two:

| Template | Contents |
|---|---|
| **`BasicMod`** | `Config/Input/PLUGIN_NAMEInput.ini`, `Config/Tags/PLUGIN_NAMETags.ini`, `Config/InstanceTypes.ini`, `Resources/Icon128.png` |
| **`CodeMod`** | `Source/PLUGIN_NAME/PLUGIN_NAME.Build.cs` (a stock Epic `ModuleRules`), `Source/PLUGIN_NAME/{Private,Public}/`, `Resources/Icon128.png` |

`PLUGIN_NAME` is the token the Mod Manager substitutes at creation time.

The Clans documentation covers only the **Basic Mod** path, and Create Mod
stays greyed out until a template is selected. On `CodeMod`'s practical
viability — no engine headers ship with this build — see `../SKILL.md`.

## `ModOverride` and overriding shipped assets

The Clans workflow is right-click an asset → **Save To Mod**, which places a
copy under a `ModOverride` subfolder of your mod, and right-click the base
asset → **Delete from Mod** to remove the override.

The engine-level reason overrides must mirror the original's folder structure
is the one stated at the top of this file: **path is identity**. An override
substitutes for the original only if its path matches.

**The Editor restart requirement is real and repeated** — the Clans docs state
it for overrides and again before Package, Export and Publish. The likely
mechanism is plugin content-root mounting plus the Asset Manager's startup
directory scan; see `mw5clans-mapping.md`, where it is marked as inference.
Batch your overrides and restart once.

## The project's own plugin list

`MW5Clans.uproject` carries **80 plugin entries** — 55 explicitly enabled, 25
explicitly disabled. The disabled set is almost entirely platform-specific
media and mobile/console subsystems (`AndroidMedia`, `PS5Media`, `WmfMedia`,
`OnlineSubsystemGooglePlay`, `WindowsMoviePlayer`, `StudioTelemetry`), which
is normal shipping-title hygiene rather than anything a modder needs to work
around.

The enabled set that matters for modding is summarized in `../SKILL.md`, along
with the notable **absences** (PCG, CommonUI, GameplayAbilities, StateTree,
MassEntity, Water). Check that table before recommending any UE5 feature —
"UE5 can do X" is not the same as "Clans can do X."
