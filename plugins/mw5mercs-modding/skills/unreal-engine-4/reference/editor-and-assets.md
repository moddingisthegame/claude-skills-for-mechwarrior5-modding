# UE4 assets, packages, plugins, and levels

Sources: Epic UE4 docs, pinned to 4.27 —
[Assets and Packages](https://dev.epicgames.com/documentation/en-us/unreal-engine/assets-and-packages?application_version=4.27),
[Plugins](https://dev.epicgames.com/documentation/en-us/unreal-engine/plugins?application_version=4.27),
[Managing Multiple Levels](https://dev.epicgames.com/documentation/en-us/unreal-engine/managing-multiple-levels?application_version=4.27)

## Assets and packages

An **Asset** is a piece of content for a project — think of it as a `UObject`
serialized to a file. Each **`.uasset`** file typically contains a single
Asset, stored under the project's `Content` folder.

- The Content Browser's **Sources Panel** shows the Asset Tree; the folder
  structure directly determines each asset's path on disk.
- **Asset paths are directory-style.** An asset `MyCharacter` in
  `Content/Characters/` has the full path
  `/UE4/MyProject/Content/Characters/MyCharacter.MyCharacter.uasset`.
- **References embed that full path**, formatted like
  `Blueprint'/MyProject/Content/Characters/MyCharacter.MyCharacter'`.

### Redirectors — and why Explorer moves break things

When an asset is renamed or moved **within the Content Browser**, an
invisible **Redirector** is left at the original location so existing
references keep resolving. Running **Fix Up Redirectors in Folder** updates
all references and removes the redirector once assets are resaved.

Renaming or moving assets **outside** the Content Browser (in Windows
Explorer) bypasses this entirely and **breaks references**. The editor only
protects operations performed inside it.

> This is the mechanism behind MW5's rule that `ModOverride` content must sit
> at the *same path* as the asset it overrides — in UE4, path is identity.
> It also explains why MW5's port instructions specify copying *pre-cooked*
> `.uasset` files into exactly-mirrored folder structures.

## Plugins

A **Plugin** is a collection of code and data that can be enabled or disabled
per project in the editor. Plugins can add runtime gameplay functionality,
modify or extend engine features, create new file types, and extend the
editor with menus, toolbar commands, and sub-modes.

### Locations

- Engine plugins: `/[UE4 Root]/Engine/Plugins/[Plugin Name]/`
- Project plugins: `/[Project Root]/Plugins/[Plugin Name]/`

The engine scans subdirectories beneath the base `Plugins` folder, but does
**not** descend into an already-discovered plugin looking for more.

### Directory structure

| Folder | Contents |
|---|---|
| `Source` | Module code and `.Build.cs` files |
| `Binaries` | Compiled code |
| `Intermediate` | Temporary build products |
| `Content` | Asset files — present when `CanContainContent` is true |
| `Resources` | Contains `Icon128.png` |
| `Config` | Configuration files |

> MW5 mods use exactly this shape:
> `MW5Mercs/Plugins/<ModName>/` with `Content`, `Config` (holding
> `Tags/<ModName>Tags.ini` and `Input/<ModName>Input.ini`), plus MW5's own
> additions `ModOverride/` and `Paks/`.

### The `.uplugin` descriptor

A required JSON file in the plugin's root directory. Key fields:

- **`FileVersion`** (required, typically `3`)
- **`FriendlyName`** — display name
- **`Description`**
- **`Category`**
- **`EnabledByDefault`**
- **`CanContainContent`** — must be true for the plugin to ship assets
- **`Modules`** — array of module definitions, each with `Name`,
  `Type` (`Runtime` / `Developer` / `Editor`), and `LoadingPhase`

Plugin load ordering in stock UE4 comes from module `LoadingPhase`. MW5's
`mod.json` `loadOrder` integer is an MW5-specific addition, **not** a UE4
plugin field.

### Plugins editor window

**Edit > Plugins** lists installed plugins with name, icon, version,
description, author, and enabled state, with category browsing, search, and
per-plugin enable/disable toggles.

## Levels: persistent level and sublevels

Every map has exactly one **Persistent Level**. You may add one or more
**sublevels**, which are either always loaded or streamed in via Level
Streaming Volumes, Blueprints, or C++.

The **Levels** window (**Windows > Levels**) manages all of them.

- **Current level** is shown in **bold blue text**. Right-click a level →
  **Make Current** to switch which level receives newly placed actors.
  *(This is the single most common source of "I placed it in the wrong
  level" mistakes — MW5's mission guide repeatedly warns about it.)*
- **Creating sublevels**, three ways:
  - **Levels > Add Existing** — bring in another map.
  - **Levels > Create New** — a blank sublevel.
  - **Levels > Create New with Selected Actors** — split existing actors off
    into a new level.
- **Streaming method** — right-click a sublevel to set it. **Always Loaded**
  sublevels load and become visible together with the persistent level, and
  ignore streaming volumes and any Blueprint/C++ load-unload requests. The
  alternative is **Blueprint** (loaded on request).
- **Transform** — sublevels have their own **Position** and **Rotation** in
  **Level Details** (the magnifying-glass icon), letting a sublevel be
  offset from the persistent level. MW5's markup levels use the default
  `0,0,0`.
- **Visibility and lock** — right-click toggles. Note Epic's caveat:
  changing a level's visibility is **for visualization only and does not
  affect whether the level will stream**.

> MW5's `<Level>_Friendlies_MRK` / `<Level>_Enemies_MRK` markup levels are
> ordinary UE4 sublevels of the terrain persistent level.
