# UE4 Data Tables, Curve Tables, and Data Assets

Sources: Epic UE4 docs, pinned to 4.27 —
[Data Driven Gameplay Elements](https://dev.epicgames.com/documentation/en-us/unreal-engine/data-driven-gameplay-elements?application_version=4.27),
[Asset Management](https://dev.epicgames.com/documentation/en-us/unreal-engine/asset-management?application_version=4.27)

Underpins MW5's `ProjectileWeaponStats` DataTable workflow and its
pervasive `...DataAsset` / `...AssetId` fields.

## Data Tables

A **Data Table** stores structured data in rows and columns. Each row maps to
a C++ `UStruct` that inherits from **`FTableRowBase`**.

- The **first column must be named `Name`** and holds the row identifier;
  remaining columns correspond to the struct's member variables.
- Columns may be any valid `UObject` property, **including asset
  references**.
- Data Tables are Unreal assets (not `.ini` files), so they can be viewed and
  changed **while the editor is running** — which is what makes MW5's
  "duplicate the stats table and edit your copy" workflow practical.

Epic's example struct: `FLevelUpData : public FTableRowBase` containing
`int32 XPtoLvl`, `int32 AdditionalHP`, and
`TSoftObjectPtr<UTexture> AchievementIcon`.

### Import / export

1. Export a CSV from Excel or other spreadsheet software.
2. In the editor, choose **Import** in the Content Browser.
3. Select the CSV and pick the row-struct representation from the dropdown.
4. A DataTable object is created in the current Content Browser directory.
5. Update later via right-click → **Reimport**; double-click to view.

> MW5's instruction to right-click a duplicated stats table and **Export as
> JSON** is this same import/export facility. The reason it's mandatory in
> MW5's workflow is that without an external source file, the duplicate keeps
> referencing the original table's data.

### Hooking data up

Programmers expose Blueprint-visible variables using
**`FDataTableRowHandle`** (or `FCurveTableRowHandle`), which present two
fields: a table reference and a **RowName**. Runtime lookup uses `FindRow()`
(and `GetCurve()` for curve tables).

## Curve Tables

A **Curve Table** works like a Data Table but holds only floating-point
values. Each row is a curve usable in game: column headings are X-axis
values, row entries are the Y-axis values interpolated between.

## Primary vs Secondary Assets, and the Asset Manager

UE4 splits all assets into two categories:

- **Primary Assets** — manipulated directly by the Asset Manager via their
  **`FPrimaryAssetId`**, obtained from `GetPrimaryAssetId()`.
- **Secondary Assets** — loaded automatically when referenced by a Primary
  Asset. **By default only `UWorld` assets (levels) are Primary**; everything
  else is Secondary unless a class opts in.

An `FPrimaryAssetId` has two parts: a **Primary Asset Type** naming a group
of assets, and the asset's name (defaulting to its Content Browser name).
Epic's example: a `UMyGameZoneTheme` asset named "Forest" has the ID
`MyGameZoneTheme:Forest`.

> This `Type:Name` shape is why MW5's dropdowns display entries like
> `MWMechDataAsset:UM-K9_MDA`, `MWPersonaAsset:Spears`,
> `MWTileElementAsset:HotDrop_01`, and
> `MWProjectileWeaponDataAsset:Autocannon20`.

**`UAssetManager`** is the singleton that discovers and loads Primary Assets.
It holds an **`FStreamableManager`** which performs asynchronous loading and
keeps objects alive via **Streamable Handles** until it's appropriate to
unload them.

## `UPrimaryDataAsset` and Data-Only Blueprints

**`UPrimaryDataAsset`** is Epic's recommended base class for Primary Assets;
it includes built-in Asset Bundle support.

For classes you never need to instantiate, store data in a **Data-Only
Blueprint** inheriting from `UPrimaryDataAsset`. Child classes — including
Blueprint-based ones — can derive further: Epic's example chains
`UMyShape` (C++, extends `UPrimaryDataAsset`) → `BP_MyRectangle` → `BP_MySquare`.

Designers create instances of `UPrimaryDataAsset` child classes directly in
the Content Browser as non-Blueprint assets and reference them via soft
pointers.

## Asset Bundles and async loading

**Asset Bundles** are named collections of assets associated with a Primary
Asset, declared by tagging a `UPROPERTY` (typically a `TSoftObjectPtr`) with
`meta = (AssetBundles = "BundleName")`. They are loaded asynchronously with
`LoadPrimaryAssets()` and related functions.

> C++-only detail; included because it explains why MW5 asset references are
> soft/by-ID rather than hard pointers, and therefore why **renaming a data
> asset can break references that editing its contents would not**.
