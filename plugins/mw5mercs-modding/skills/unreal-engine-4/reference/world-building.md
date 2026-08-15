# UE4 landscape, materials, foliage, and navigation

Sources: Epic UE4 docs, pinned to 4.27 —
[Landscape Materials](https://dev.epicgames.com/documentation/en-us/unreal-engine/landscape-materials?application_version=4.27),
[Material Instances](https://dev.epicgames.com/documentation/en-us/unreal-engine/creating-and-using-material-instances?application_version=4.27),
[Foliage Tool](https://dev.epicgames.com/documentation/unreal-engine/foliage-tool?application_version=4.27),
[NavMesh Bounds Volume](https://dev.epicgames.com/documentation/en-us/unreal-engine/volumes-reference?application_version=4.27)

The engine layer under MW5's terrain-level construction step.

## Material Instances

**Material instancing** creates a parent Material used as a base for many
different-looking children (**Material Instances**).

- A **Material Instance Constant** is the asset type created in the Content
  Browser — the kind MW5's `_MTI` assets (e.g.
  `DynamicTerrain_Default_MTI`) are.
- To make a Material attribute editable in an instance, it must be
  designated a **parameter** in the parent Material — authored with parameter
  nodes rather than plain Material Expressions. Parameter types include
  **Scalar Parameters** (a single numeric value; the parameterized form of a
  Constant), **Vector Parameters** (four floats; parameterized Constant4
  Vector), **Texture Parameters**, and **Static Switch Parameters**.
- In the **Material Instance Editor**, parameters appear in the **Details**
  panel; **check the box next to a parameter** to enable it for editing, then
  set it via text field, slider, or color picker.
- Instances inherit all attributes of the parent Material, so one base
  material can yield many variations while staying linked to its parent.

## Landscape materials and paint layers

**LandscapeLayerBlend node** — blends multiple textures or material networks
as paintable landscape layers via an array. Three blend types:

| Blend type | Use |
|---|---|
| **LB_WeightBlend** | Data from external programs, or painting layers independently |
| **LB_AlphaBlend** | Detailed painting with a defined layer order — later layers occlude earlier ones |
| **LB_HeightBlend** | Weight blending plus height-based detail at layer transitions |

**LandscapeLayerWeight node** — blends material networks using layer weights
as the alpha. Nodes are chained: each layer's output feeds the next layer's
**Base** input, with the final output going to Base Color.

**Weight blending vs alpha blending:** weight blending guarantees all layer
weights sum to **1.0** at any point. This avoids the situation where one
layer at 100% coverage forces the others to 0%.

> This is why MW5's "fill the landscape with the Main layer, then paint
> Secondary as you see fit" behaves as a swap rather than an additive
> overlay — and why MW5 says Main/Secondary each need a **Layer Info** object
> assigned before painting works ("they already exist, just select them").

**Black spot problem:** when multiple `LB_HeightBlend` layers all have zero
height in the same area, no layer contributes color and you get black spots.
Fix by setting at least one layer to `LB_AlphaBlend`.

**Per-component material instances:** each landscape component gets its own
`MaterialInstanceConstant` generated from the main Landscape Material, and
layers unused on a given component are discarded. This lets you author a
complex master material while staying within hardware shader limits — and it
is why adding unnecessary layers raises cost, matching MW5's advice not to
use landscape materials with extra layers unless you need them.

**Hole materials:** `LandscapeVisibilityMask` nodes with an opacity mask
(Blend Mode: **Masked**) create cave entrances and terrain holes.

### Landscape Edit Layers `[post-4.23?]`

4.27 documents **Landscape Edit Layers** — multiple stacked layers for
sculpting/painting, with lock, hide, and Layer Contribution highlighting.
This is distinct from *paint/material* layers above. Its introduction
version was not established here and it is **not** referenced anywhere in
MW5's mission-building documentation — do not assume it exists in MW5's
4.23.1 editor.

## Foliage tool

The **Foliage Tool** paints or erases sets of Static Meshes or Actor Foliage
onto filter-enabled actors and geometry. Accessed in the **Modes** dropdown
(**`Shift+3`**).

**Requirement:** the level must contain either a Landscape Terrain or Static
Meshes with **collision enabled** — you cannot paint onto nothing.

**Foliage types:**
- **Static Mesh Foliage** — uses mesh instancing for performance; many
  instances render with a single draw call via hardware instancing.
- **Actor Foliage** `[post-4.23?]` — places Blueprint/native Actor instances
  at standard (non-instanced) rendering cost. Availability in 4.23 was not
  established.

**Tools (toolbar):**

| Tool | Behavior |
|---|---|
| **Selection** | Select individual/multiple instances to move, delete, transform |
| **Paint** | Add foliage on left-click; erase with `Shift`+left-click |
| **Reapply** | Change parameters on already-placed instances |
| **Single** | Place exactly one instance per click |
| **Fill** | Cover an entire Static Mesh actor in one click; repeat clicks add density |
| **Erase** | Remove only the selected meshes from an area |

**Brush settings:** **Size** (radius in Unreal units), **Density** (target
density, 0–1, when painting), **Erase Density** (target density when
erasing).

**Filters** (enabled by default): **Landscape**, **Static Meshes**, **BSP**,
**Foliage** (stack foliage on other foliage), **Translucent**.

> MW5 layers its own indirection on top: you paint `FoliageSpawnerType_*_FLT`
> placeholder spawners rather than real meshes, and the actual assets and
> densities are resolved per-Biome at mission run time. MW5's "Bake Into
> Instanced Foliage Actor" checkbox converts placed landform blueprints into
> foliage instances — expect an editor freeze while it processes.

## NavMesh Bounds Volume

**Nav Mesh Bounds Volumes** control where navigation meshes are built in a
level; nav meshes compute AI navigation paths through those areas.

- Create one or more enclosing the navigable areas — the nav mesh builds
  **automatically**.
- You may **overlap as many as needed** to produce the desired coverage.
- Place from the **Place Actors** panel (search `NavMeshBoundsVolume`), then
  scale/position it in the **Details** panel to cover the play area.
- **Press `P` in the viewport at any time to visualize the nav mesh.** This
  debugging toggle is not mentioned anywhere in MW5's docs but works in any
  UE4 editor viewport — the fastest way to confirm MW5's required
  `NavMeshBoundsVolume` actually covers your terrain.
