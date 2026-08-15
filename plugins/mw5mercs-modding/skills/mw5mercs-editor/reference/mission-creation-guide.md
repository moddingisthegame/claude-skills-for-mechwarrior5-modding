# Mission Creation ("Mission Building Quick-Start")

Source: `MW5 Mission Creation Guide.pdf` ("Mission Building Quick-Start") —
https://mw5mercs.com/static/docs/MW5%20Mission%20Creation%20Guide.pdf

Covers building a single custom-terrain mission by hand (as opposed to the
game's default procedural/tiled missions). Assumes UE4 familiarity. Pairs
with [mission-flow-nodes.md](mission-flow-nodes.md) (the node catalog
referenced throughout) and [campaign-integration.md](campaign-integration.md)
(hooking a finished mission into the campaign/starmap).

## Plan first
Mission components can express: timers, waves attacking a base/player/
location, mission end, artillery fire, capture/destroy/defend
buildings, scan an item, target a building/unit, destroy units, go-to a
location, go-to an evac point.

## Terrain level
- Custom (non-tiled) levels can be any size — for reference, standard proc
  tiles are 75600 units square (3×3 tile min = 2268m, 8×8 max = 6048m),
  but that's not a hard limit.
- **Terrain material:** use a `DynamicTerrain_*_MTI` instance (e.g.
  `DynamicTerrain_Default_MTI`) from
  `Content/Objects/Environments/_common/Materials/`; set its **Main** and
  **Secondary** layer info objects, fill Main, paint Secondary — this
  integrates with the biome system (e.g. Forest biome = green
  main/brown-dirt secondary automatically).
- **`NavMeshBoundsVolume`** is required, sized to cover anywhere AI should
  navigate.
- **Foliage:** don't place specific meshes — place **foliage spawners**
  from `Content/Objects/Environments/Foliage/_common/FoliageSpawnerTypes`
  (`FoliageSpawnerType_Bush_FLT`, `..._Rock_Large_FLT`,
  `..._Rock_Normal_FLT`, `..._Tree_Normal_FLT`) via the foliage paint
  tool — actual assets/density are resolved per-Biome at mission run time.
- **Landforms** (mountains, cliffs, etc.): drag prefab blueprints from
  `Content/Objects/Environments/TerrainFeatures/.../Prefab_*` folders,
  scale/orient, then check **"Bake Into Instanced Foliage Actor"** once
  placement is final (editor may freeze briefly — expected) — converts
  them into the foliage system.
- **Barrier walls:** place `WorldBarrierVolume` objects around the level
  perimeter to block the player from leaving (shows a red warning glow
  near the edge).

## Markup levels
- Add a sublevel to the terrain level, conventionally named
  `<Level>_MRK`. You need **two** — one for friendly content, one for
  enemy content (proc-mission tiles are normally flagged one or the
  other; a hand-built single tile needs both explicitly).
- Each markup level needs exactly one **`ConfigurationController`**
  actor. Add a Configuration Definition with Key Gameplay Tag
  `Config.Default`.
- Every locator you place must be registered under that
  `ConfigurationController`'s `Config.Default > Locators` map (name →
  locator reference) — this name is how the `AreaSpec` finds it later.
- **Friendlies markup:** typically just a
  `DropshipLandingZoneLocator` (mission start / disembark point).
- **Enemies markup — spawning AI units**, three methods:
  1. **Dropship:** `HotDropLocator` (max 4 units, mechs only).
  2. **WaveLocator:** place `SpawnPoint` actors (NOT `MWSpawnPoint` /
     `SpawnPointLocator`) where units should appear, set each one's
     `Spawner` type (`Spawner_Mech` / `Spawner_Tank` / `Spawner_VTOL`),
     then add a `WaveLocator` and list those SpawnPoints under
     **Locator Config → Aux Spawn Points**.
  3. **Garrison:** units defined in a garrison's own encounter data exist
     from mission load with no separate locator needed.
- **Garrisons ("bases"):** any spawned sub-level — a base, city, farm,
  factory, etc. Placed via size-specific locators:
  `GarrisonForwardOperating_190x190mLocator`,
  `GarrisonMain_360x360mLocator`, `GarrisonMain_FullTileLocator` (plus
  smaller variants). Garrison levels live under `Content/Levels/Garrisons`
  in subfolders like Agricultural/Industrial/Military/Urban/Unique.
- **Other locators:** waypoints/triggers with no special type use a plain
  `LocatorClass` object.

## AreaTiles
Right-click → MW5 Misc → **AreaTile**. A hand-built single-terrain mission
needs **two**: one referencing the main terrain **Level** + the enemies
**Markup Level**, and one referencing only the friendlies **Markup
Level** (no main Level).

## AreaSpecification ("AreaSpec")
Right-click → MW5 Misc → **Area Specification**. This is where ~99% of
mission-building work happens.

> **Important:** don't have any markup level open in the editor while
> working in an AreaSpec, or its locators won't be visible/available —
> `File > New` an empty level first.

- **Set `Mission Parameters` to `Objective Chain Mission Parameter`
  immediately** — nothing works without this.
- **Biome:** pick an existing one, or duplicate + customize one for this
  mission only. Weather/Sky properties are mostly self-explanatory;
  notable ones: `FreezingLevel` (Z height above which snow appears),
  `NearFieldType` (Full/Half/None — background mountain mesh coverage;
  Half useful for a one-sided ocean), `HasOcean` (flat plane on all
  sides — ocean or desert depending on biome), `BiomeOrientation`
  (0–360°, rotates background + lighting — main tool for light direction).
- **Territory List:** add one entry with `Team Alignment = Friendly` to
  support a friendly tile (index `0`); any `AreaTile` not tagged into a
  friendly territory defaults to enemy.
- **Area Tile List:** add your two `AreaTile` objects; the friendlies one
  needs `TerritoryIndex = 0` to match the Territory List entry above.
- For each tile entry, set its **Configuration** to `Config.Default`,
  then double-click each locator under **"Locators From Config"** to move
  it into **"Added Locators"** (a red dot appears in the 3D viewport for
  each).
- Each added locator gets an optional **Tile Element** dropdown — this is
  what actually loads content there:
  - Dropship start: `FadeInMissionStartArea` or
    `LeopardMissionStartDropZoneLandingArea_01`.
  - Garrisons: pick the matching `Garrison_*` Tile Element for that
    locator's footprint size.
  - `WaveLocator`s need **no** Tile Element.
  - `HotDropLocator`s need the `HotDrop_01` Tile Element to spawn AI, or
    `Pickup_01` to serve as an evac extraction point.
- **Adding AI units:** expand a locator's **Settings → Unit Deck**, add
  entries (+), each with a **Unit Card** (unit type), optional **Faction
  Asset Id**, and quirks (e.g. `UnitCard_PilotSkillLevel_Quirk`,
  `UnitCard_WeaponTechLevel_Quirk`). **Generate a Unit GUID** (click the
  arrow next to the field) so Mission Flow Nodes can reference this exact
  unit later.

## Mission Flow Node Data (inside AreaSpec → Mission Parameters)
Every gameplay element (spawn, waypoint, objective...) is one of these —
see [mission-flow-nodes.md](mission-flow-nodes.md) for the full catalog
of node types and their parameters. Common fields on every node:
- **Name** — must be unique; this is how other nodes/connections
  reference it.
- **Start on Setup?** — check to auto-start at mission begin (otherwise
  it must be triggered by another node's connection).
- **Location** — a locator reference (Tile GUID + Locator Key). Fastest
  entry method: right-click the locator's red dot in the viewport to
  copy it, then right-click the `Location > Locator` field in the node
  and Paste.
- **Node Type** — `Primary Objective` / `Secondary Objective` (both shown
  on HUD, required for success), `Optional Objective` (shown, not
  required), `Unlisted Objective` (shows a marker but no text, not
  required), `Non-Objective` (invisible to player).
- **Definition Tags** — the `Objectives.Type.*` tag selecting node
  behavior.
- **Additional Mission Data** — node-specific key/value parameters.
- **Dispatch Data** — wave-spawn source/target locators, only relevant
  to Dispatch nodes.
- **Dialogue Script** — audio to trigger on start/complete/fail/abort.

Common node patterns:
- **Spawn AI** — `Objectives.Type.Dispatch.WavesToAttackPlayerLance` /
  `...WavesToDestroyGarrison` / `...WavesToGoToTargetLocation`. No
  Location; instead set `Dispatch Data → SupportSources` to the
  WaveLocator/HotDropLocator, and (for garrison/location variants)
  `DispatchTargets` to the target locator. Which units spawn: add
  `Additional Mission Data` entry `wavedata1` with a `Guids` list of the
  unit GUIDs generated earlier in the AreaSpec.
- **Area trigger / waypoint** — `Objectives.Type.Travel.GoTo`, Location =
  any locator. Default trigger volume is a 200×200×90m box; override with
  `Additional Mission Data` entries `usesphere` (radius in meters) or
  `length`/`breadth`/`height` (box dimensions in meters).
- **Timer** — `Objectives.Type.Timer`; set the countdown via an
  `Additional Mission Data` entry named **`timer`** (lowercase — the
  node's own `Timer Value` field is a *different*, unrelated field, don't
  use it for this).
- **Destroy unit(s)** — `Objectives.Type.Destroy.Unit`; `Additional
  Mission Data` entry `Units` with a `Guids` list. Add a `nomarker` entry
  to suppress the HUD skull icon.
- **End mission** — `Objectives.Type.EndMission.Timed`; optional `Timer`
  entry (seconds to wait, e.g. for dialogue to finish), optional
  `Failure` entry to end in a failure state instead of success.
- **Evac pickup** — `Objectives.Type.Evac.GoToExtractionPoint`; Location
  must be a `HotDropLocator` with the `Pickup_01` Tile Element assigned.

## Mission Flow Node Connection (the mission's logic graph)
- Each entry has **From Mission Flow Node** (the node whose state you're
  watching) and one-or-more **To Mission Flow Node** entries, each with a
  **Link Trigger Type** (state that must occur on the From node —
  Successful/Failed/Aborted/Started) and **Link Type** (what to then do
  to the To node — Start/Succeed/Fail/Abort).
- **One-to-many** is trivial: add multiple `To Mission Flow Node` entries
  under one `From`.
- **Many-to-one** (e.g. "Node D starts only once A, B, and C all
  succeed"): create a separate `From` entry for each of A/B/C, each
  pointing `To` Node D. To let one *other* node (E) trigger D
  unconditionally regardless of A/B/C's state, set up E → D the same way
  but check **"Ignore Other Links"** on that link.

## Playing & publishing the mission
- **Test in-editor:** the big **Play** button at the top of the AreaSpec
  editor.
- **Instant Action menu:** create a **Scenario** asset (MW5 Misc →
  Scenario), give it a GUID/Name, set **Mission Spec → Area Spec Asset**
  to your AreaSpec, and check **"Show in Instant Action List"**.
- **Campaign integration:** see
  [campaign-integration.md](campaign-integration.md) (separate guide).

## Other techniques worth knowing
- **Existing-tile missions:** manually add existing proc-mission `AreaTile`
  objects with hand-entered coordinates/orientation, picking whichever
  Configuration on each best matches the locators you need.
- **"Baking" a good procedural mission:** running the game from the
  editor writes the current mission's JSON to
  `MW5Mercs/Saved/Logs`; keep that file, create a new AreaSpec, and
  right-click it → **Import From JSON** to get an editable copy of that
  exact procedurally-generated mission.
- **Custom garrisons:** just a new garrison level + a matching **Tile
  Element** (which level to load + which locator footprint it's
  compatible with) — best learned by inspecting existing Tile Elements
  and garrison levels.

## Best practices (from the guide's own recommendations)
- Name **everything** consistently — locators, flow nodes, files, paths.
- Keep an external spreadsheet mapping flow-node array indices → names
  (and separately, spawned units → type/spawning-node/GUID) — the
  in-editor arrays get unwieldy fast; the AreaSpec editor's filter bar
  helps but isn't a substitute.
- Consider an external flowchart of node logic links for debugging.
- Start with small, simple missions before attempting complex logic
  graphs.
- Leverage the parametric systems (biome swap, time-of-day, etc.) to get
  more mileage out of one hand-built level.
