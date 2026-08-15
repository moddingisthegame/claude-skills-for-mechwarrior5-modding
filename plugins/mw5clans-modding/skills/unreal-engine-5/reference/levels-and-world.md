# UE5 levels, Level Instances, World Partition, and Data Layers

Sources: Epic UE5 docs pinned to 5.5 —
`level-instancing-in-unreal-engine`, `world-partition-in-unreal-engine`,
`world-partition---data-layers-in-unreal-engine`, each with
`?application_version=5.5`. Install observations are from
`MW5ClansEditor\Modding\MW5Clans\` under the Epic Games Launcher install.

This is the area where UE5 diverges most sharply from UE4, and it is the area
Clans mission building lives in.

## Level Instances — the workhorse for Clans missions

A **Level Instance** is a level asset (`.umap`) placed inside another level as
a single actor. Epic describes it as "a level-based workflow designed to
improve and streamline the level editing experience": you group actors, save
them as a level, and place copies across your world with edits staying
synchronized.

**Creating one:** select the actors in the Viewport or Outliner, right-click,
then **Level → Create Level Instance**. A dialog lets you configure the pivot
before saving.

**Editing one:** you edit the instance in place and commit, rather than
opening the source map separately. Every other placement of that Level
Instance picks up the change.

Why this matters for Clans: the official mission guide has you build garrisons
and gameplay pockets as Level Instances, and the shipped example mod follows
that layout with `LevelInstances/LI_ModMission_Gameplay.umap` and
`LevelInstances/LI_ModMission_Garrison_Urban_190x190_Town01.umap`. **There is
no UE4 equivalent** — a Mercs modder's `_MRK` sublevel habits do not map onto
this.

### Packed Level Actors — the sibling you usually don't want

A **Packed Level Blueprint / Packed Level Actor** converts Static Mesh assets
in a level into a **single Blueprint Actor optimized for rendering**. Epic
recommends them "for static buildings and dense visual setups."

The trade-off is in the name: packing consolidates meshes, which is a
rendering win and a gameplay loss. If the level contains spawners, objective
volumes, or anything a mission script needs to reference, packing it is wrong.

*Whether Clans supports Packed Level Actors in mod content is not documented
by PGI — `[verify in 5.5]`. Default to plain Level Instances for anything
carrying gameplay actors.*

## World Partition

**World Partition** is "an automatic data management and distance-based level
streaming system." Instead of an author manually splitting a map into
sublevels, the world stays a single persistent level divided into **grid
cells** that load and unload based on distance from streaming sources.

Key facts that prevent mistakes:

- **It is per-map, not per-project.** A project can have partitioned and
  non-partitioned maps. It gets enabled by creating a map from the Open World
  template, by the Games templates, or by running the **Convert Level** tool
  on an existing map.
- **It replaces the UE4 sublevel workflow** rather than supplementing it.
  Epic's stated motivation is that the old approach "often created issues
  sharing files between multiple users, and viewing the whole world in context
  became a difficult task."
- **Epic's docs do not explicitly state whether the two can be mixed within a
  single map**, and the existence of a conversion tool suggests they are
  treated as distinct approaches. Do not assume you can partially convert.

### One File Per Actor (`__ExternalActors__`)

**OFPA** saves each actor into its own package file rather than serializing it
into the `.umap`. It exists so multiple people can edit one level without
checking out a single monolithic file.

On disk this appears as `Content/__ExternalActors__/<MapPath>/...` and
`Content/__ExternalObjects__/...`.

**Verified in Clans:** both directories exist at `MW5Clans/Content/`, with
per-map subfolders under `__ExternalActors__/Maps/Campaign/` including
`Courchevel_Base`, `Courchevel_Mountains`, `Luthien_Factory`, `Luthien_Hills`,
`TurtleBay_City`, `TurtleBay_Caves`, `Santander_Wilds`, `Simpod` and
`MissionHubWorld`. The project ships **400 `.umap` files** total.

**That the campaign maps use OFPA is fact. That they are World Partition maps
is inference** — the two are designed together, but OFPA can be enabled
independently. Check World Settings in the Editor before asserting it.

Practical consequence for modders either way: **do not move or rename map
files in Windows Explorer.** An OFPA map is a `.umap` plus a directory of
actor packages keyed to its path; separating them orphans every actor.

> **Do not misread `bIsWorldPartitioned=False`.** That line appears in
> `Config/DefaultEngine.ini` inside a **RecastNavMesh** navigation block
> (surrounded by `RegionPartitioning=Watershed`, `LayerChunkSplits`,
> `bSortNavigationAreasByCost`). It concerns **navmesh** partitioning and says
> nothing about World Partition levels.

## Data Layers

**Data Layers** organize actors in the editor and at runtime. Two kinds:

| | What it is |
|---|---|
| **Data Layer Asset** | a project-level, reusable Content Browser asset holding the layer's name, type and debug color |
| **Data Layer Instance** | a world-specific implementation of that asset; multiple worlds can instance the same asset with different properties |

And two behaviors:

- **Editor Data Layers** organize assets during authoring. You load/unload and
  toggle visibility from the Data Layers Outliner. **No gameplay effect.**
- **Runtime Data Layers** are manipulated from Blueprints or C++ during play,
  via the Data Layer Subsystem. Three runtime states: **Loaded** (hidden),
  **Activated** (loaded and visible), **Unloaded**. Epic's example use is
  swapping world states for quest progression.

**Data Layers require World Partition to be enabled on the map.** Epic states
this explicitly. So if a Clans map is not partitioned, engine Data Layers are
not available on it.

### The `KelDataLayerTriggerAsset` caveat

`Config/DefaultGame.ini` registers primary asset types named
`KelDataLayerTriggerAsset` and `KelTitleScreenDataLayerAsset`, both under
`/Script/MechWarrior.*`, and sets
`DefaultDataLayerAssetID=(Id="KelTitleScreenDataLayerAsset:SJ_Act1_TitleScreenLayers")`.

The `MechWarrior` module prefix means these are **PGI game classes, not UE5's
`UDataLayerAsset`**. They may wrap engine Data Layers, or they may be an
independent system that borrowed the name. **Unverified.** Do not answer
questions about them from Epic's Data Layer documentation without saying which
is which.

## What survived from UE4

Not everything changed. Still present and still working the same way:

- **Persistent level + sublevels** remain available for non-partitioned maps,
  including the **Levels** window and per-sublevel transform.
- **Level Blueprints** still exist per level.
- **Streaming methods** (Always Loaded vs Blueprint) still apply to classic
  sublevels.
- **`NavMeshBoundsVolume`** is unchanged in concept, and **`P` in the viewport
  still toggles navmesh visualization** — Clans ships an elaborate
  RecastNavMesh configuration in `Config/DefaultEngine.ini`, so this is a
  useful debugging trick when AI won't path.
