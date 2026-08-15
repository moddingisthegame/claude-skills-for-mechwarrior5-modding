# MW5 Mercs concept → UE4 feature mapping

**What this file is:** a derived cross-reference. The MW5 column is
documented fact from the official MW5 Mercs modding docs (see the
`mw5mercs-editor` skill). The UE4 column is documented fact from
Epic's UE4-pinned documentation. The *connection between them* is inference —
reasonable and usually obvious, but not something Epic or PGI state
explicitly. Confidence is marked per row.

Engine version: MW5 Mercs is **UE 4.23.1**; UE4 facts here are from the
4.27 archived docs. See the version warning in `../SKILL.md`.

---

## Mods are UE4 Plugins — the single most useful mapping

**Confidence: high.** The MW5 paths make this unambiguous.

MW5 mods live at `<Mod Editor>/MW5Mercs/Plugins/<ModName>/` with a
`Content` folder, a `Config` folder, and (for ported mods) a `Paks` folder.
That is precisely UE4's plugin layout: UE4 searches
`/[Project Root]/Plugins/[Plugin Name]/`, and a plugin may carry its own
`Content` folder when its `.uplugin` descriptor sets
`"CanContainContent": true`.

What this buys you:
- The MW5 "Create Mod" button is doing UE4 plugin scaffolding. The mod's
  descriptor is a `.uplugin` JSON file in the plugin root.
- `mod.json`'s `loadOrder` (which MW5 tells players they may hand-edit) is
  MW5's own layer on top — plugin load ordering in stock UE4 is driven by
  module `LoadingPhase` in the `.uplugin`, not a `loadOrder` integer. Treat
  `mod.json` as MW5-specific, **not** a UE4 file.
- Plugin content is mounted under its own root rather than `/Game/`, which
  is why MW5 shows `<ModName> Content` as a **sibling** of the main
  `Content` folder in the Content Browser rather than a subfolder of it.

See [editor-and-assets.md](editor-and-assets.md) for plugin structure detail.

## `ModOverride` and asset paths

**Confidence: high for the mechanism, inference for MW5's implementation.**

MW5 requires that assets placed in `ModOverride` **mirror the original
asset's folder structure** (a modified Gauss rifle goes in
`ModOverride/Objects/Weapons/Gauss/`). This follows directly from how UE4
references assets: a reference embeds the asset's full path, e.g.
`Blueprint'/MyProject/Content/Characters/MyCharacter.MyCharacter'`. Path
*is* identity in UE4, so an override only substitutes for the original if
its path matches.

Related UE4 behavior worth knowing when reorganizing mod content:
- Renaming/moving an asset **in the Content Browser** leaves an invisible
  **Redirector** so existing references keep resolving; "Fix Up Redirectors
  in Folder" resolves and removes them.
- Moving/renaming `.uasset` files **in Windows Explorer** bypasses this and
  breaks references. This is the mechanism behind MW5's instruction to copy
  *pre-cooked* `.uasset` files when porting a v1 mod, and to place them at
  matching paths.

## Markup levels (`_MRK`) are UE4 sublevels

**Confidence: high.**

MW5 mission building has you create `<Level>_Friendlies_MRK` and
`<Level>_Enemies_MRK` and add them as sublevels of the terrain level at
offset `0,0,0`. In UE4 terms: the terrain level is the **Persistent Level**,
the markup levels are **sublevels** managed in the **Levels** window
(`Windows > Levels`).

Direct consequences the MW5 docs rely on without explaining:
- **"Make Current"** is why MW5 keeps warning you to double-click the right
  level before placing actors — new actors go into whichever level is
  current, shown in **bold blue text**.
- Per-sublevel **Position/Rotation** exists in Level Details (the
  magnifying-glass icon); MW5's "offset at 0,0,0" instruction is just
  leaving that default alone.
- Level **visibility** toggles are visualization-only and do not affect
  streaming — useful when hand-editing crowded markup levels.
- Streaming method (**Always Loaded** vs **Blueprint**) is a UE4 sublevel
  setting. MW5's mission system loads garrisons via its own Tile
  Element/AreaSpec layer instead, so don't expect MW5 garrison spawning to
  map onto stock UE4 level-streaming volumes. *(That last clause is
  inference — MW5 does not document its streaming internals.)*

## `Objectives.Type.*` and friends are UE4 Gameplay Tags

**Confidence: high.** This is the highest-leverage mapping after plugins.

Every MW5 tag you meet — `Objectives.Type.Destroy.Building`,
`Objectives.Type.Dispatch.WavesToDestroyGarrison`, `UnitType.Vehicle`,
`Object.Building.Military.GuardTower`,
`Object.Interactions.Destructible`, `Config.Default`,
`DialogueContext.Mission.Wave` — is a UE4 **Gameplay Tag**: a hierarchical
dot-notation label.

What UE4 semantics tell you that the MW5 docs don't spell out:
- **Dots create implicit parents.** `Objectives.Type.Destroy.Building`
  implicitly carries `Objectives.Type.Destroy`, `Objectives.Type`, and
  `Objectives`. So a filter written against a parent tag matches all its
  children — which is exactly why MW5 says you can add
  `Object.Building.Military.GuardTower` as an extra filter tag on a
  destroy-buildings node and have it select that whole building category.
- **Matching is parent-aware by default** (`HasTag`/`MatchesTag`) but
  exact-match variants exist (`HasTagExact`). If an MW5 filter behaves more
  broadly than expected, hierarchical matching is the likely reason.
- **MW5's `<ModName>Tags.ini` in `Config/Tags/` is literally UE4's tag
  mechanism**, not an MW5 invention: UE4 loads `Config/DefaultGameplayTags.ini`
  plus files in `Config/Tags/` when "Import Tags From Config" is enabled,
  using the format
  `GameplayTagList=(Tag="Vehicle.Air.Helicopter",DevComment="...")`.
  This is why MW5 can promise that adding tags there won't conflict with
  other mods — each plugin ships its own tag ini.

See [gameplay-tags.md](gameplay-tags.md).

## Weapon stats tables are UE4 Data Tables

**Confidence: high.**

MW5's `ProjectileWeaponStats` (and the Missile/Trace equivalents) in
`Objects/Weapons/_common/Config` are UE4 **Data Tables**: rows keyed by a
`Name` column, columns mapping 1:1 to a C++ `UStruct` inheriting
`FTableRowBase`.

- MW5's "**Export as JSON**" step when copying a stats table into your mod
  is UE4's Data Table import/export facility (UE4 documents CSV prominently;
  JSON export is likewise available in-editor). The reason MW5 insists on it
  is that a duplicated table otherwise keeps pointing at the original's
  source data.
- The MW5 gotcha that "changes to the stats file may not visually update in
  an already-open Weapon Data Asset — close and reopen it" is a plain
  editor-refresh issue, not a data problem.
- UE4 Data Tables can be edited while the editor is running, which is why
  this workflow is viable at all.

## `...DataAsset` / `...AssetId` fields are UE4 Primary Data Assets

**Confidence: medium-high.** The naming is strongly indicative; MW5 does not
state its C++ base classes.

MW5 is full of `MWMechDataAsset`, `MWPersonaAsset`, `MWFactionAsset`,
`MWTileElementAsset`, `MWProjectileWeaponDataAsset`, and fields named
`Mech Data Asset Id`, `Persona Asset Id`, `Portrait Asset Id`,
`Default Formation Asset ID`. UE4's asset-management system splits assets
into **Primary** (directly managed by the `UAssetManager`, addressed by
`FPrimaryAssetId` of the form `Type:Name`) and **Secondary** (loaded when
referenced). `UPrimaryDataAsset` is Epic's recommended base for
designer-authored data assets, and Data-Only Blueprints can inherit from it.

Practical upshot: those `...AssetId` dropdowns in MW5 are asset *references*
resolved by name/type, so **renaming a data asset can break references** in a
way that editing its contents will not. Prefer editing in place, and rename
only via the Content Browser so a redirector is left behind.

## Campaign Arc Actions are Blueprint Classes with chosen parents

**Confidence: high.**

MW5's campaign integration has you right-click → **Blueprint Class**, then
pick a parent such as `PlaceMission_ArcAction`, `ObjectiveState_ArcAction`
(via `SetObjectiveState_ArcAction`), or `ResetScenario_ArcAction`, all
descending from `MWCampaignArcAction`. That is stock UE4 Blueprint
inheritance: a Blueprint Class inherits its parent's variables, components
and functions, and you then tweak the inherited properties.

Because these arc actions add no new logic — you only fill in `Objective`,
`Scenario`, `StarSystemId`, `Operation` — they are effectively UE4
**Data-Only Blueprints**: Blueprint Classes containing only inherited
members, which UE4 opens in a compact property editor rather than the full
graph editor. *(That they are formally Data-Only is inference; MW5's
screenshots do show an Event Graph tab available.)*

See [blueprints.md](blueprints.md).

## `DynamicTerrain_*_MTI` are Material Instances; Main/Secondary are landscape layers

**Confidence: high.**

MW5 tells you to use `DynamicTerrain_Default_MTI` from
`Content/Objects/Environments/_common/Materials/` and to assign **Layer
Info** objects for its **Main** and **Secondary** layers, then fill Main and
paint Secondary.

- The `_MTI` suffix is a **Material Instance** (specifically a Material
  Instance Constant) — a child of a parent Material exposing only the
  parameters the parent chose to expose.
- **Main/Secondary are landscape paint layers**, driven by
  `LandscapeLayerBlend` / `LandscapeLayerWeight` material nodes and requiring
  a **Layer Info** object per layer before you can paint. MW5's "they already
  exist, just select them" refers to those Layer Info assets.
- UE4 weight-blending guarantees layer weights sum to 1.0 — the reason
  filling Main and then painting Secondary behaves as a swap rather than an
  additive overlay.
- MW5's warning not to use landscape materials with extra layers unless
  needed matches UE4's note that each landscape component compiles its own
  `MaterialInstanceConstant` and that unused layers are discarded — more
  layers means more shader cost.

## Foliage spawners and "Bake Into Instanced Foliage Actor"

**Confidence: high for the UE4 mechanism.**

MW5 has you paint `FoliageSpawnerType_*_FLT` assets rather than real meshes,
and later check **"Bake Into Instanced Foliage Actor"** on placed landform
blueprints.

- That is UE4's **Foliage** tool (Foliage Mode, `Shift+3`), which requires a
  Landscape or collision-enabled Static Meshes to paint onto, and which
  renders placed instances via hardware instancing through an instanced
  foliage actor.
- MW5's layer on top is that the spawner types are *placeholders* resolved
  per-Biome at mission run time — so a tile with 1000 tree spawners may
  produce 10 trees at low biome density. The instancing is UE4; the
  biome indirection is MW5.
- MW5's "the editor may freeze for a while after you click the checkbox,
  don't panic" is consistent with converting many placed blueprint actors
  into foliage instances.

## `NavMeshBoundsVolume` is the stock UE4 actor

**Confidence: high.**

MW5 requires a `NavMeshBoundsVolume` covering any area AI should navigate.
This is unmodified UE4: NavMesh Bounds Volumes control where navigation
meshes are built, they can be overlapped freely, the mesh builds
automatically, and **`P` in the viewport toggles NavMesh visualization** —
a debugging trick the MW5 docs never mention but which works in any UE4
editor viewport.

## Things that look like a mapping but are NOT

Be careful not to over-generalize:
- **MW5 Mission Flow Nodes are not UE4 Blueprint nodes.** They are MW5's own
  data-driven objects (converted at run time into MW5 "Mission Components" by
  the Objective Chain Mission Director) authored as array entries in an
  AreaSpec's Details panel — not a UE4 graph. Their "connections" are
  likewise array entries, not wires. Don't advise dragging wires.
- **`mod.json` / `loadOrder` is MW5-specific**, not UE4 plugin metadata (see
  the plugins section above).
- **AreaSpec, AreaTile, Tile Element, ConfigurationController, Biome,
  Scenario, Campaign Arc, Metagame Objective are all MW5 game classes**, not
  engine features. UE4 knowledge will not document them; the
  `mw5mercs-editor` skill will.
- **The MW5 Mod Editor is not a general UE4 install.** Per its EULA you may
  not use it for non-MW5 projects, and modders get no C++ build toolchain —
  so UE4 documentation about C++ classes, `.Build.cs` modules, or compiling
  plugins is background context only, not an actionable path.
