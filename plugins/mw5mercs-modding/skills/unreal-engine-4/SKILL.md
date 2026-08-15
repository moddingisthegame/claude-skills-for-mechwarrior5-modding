---
name: unreal-engine-4
description: "Unreal Engine 4 (UE4) reference oriented toward MechWarrior 5 Mercenaries modding — the engine MW5 Mercs is built on (UE 4.23.1). Covers Blueprints and parent-class inheritance, Gameplay Tags, Data Tables and Primary Data Assets, .uasset/packages/redirectors, Plugins, persistent levels and sublevels, Landscape materials and layers, the Foliage tool, NavMesh, and Material Instances. Use when working with UE4 concepts, the MW5 Mercs Mod Editor's underlying engine behavior, or translating an MW5 modding task into the UE4 feature behind it. Do NOT use for Unreal Engine 5 or for MechWarrior 5: Clans (UE 5.5.4) — UE5 differs substantially and is out of scope; use the unreal-engine-5 skill instead. If the user asks a generic 'what engine does MechWarrior 5 use' question without saying Mercs or Clans, that's ambiguous — ask which game rather than assuming."
---

# Unreal Engine 4 — reference for MW5 Mercenaries modding

MechWarrior 5: Mercenaries and its Mod Editor are built on **Unreal Engine
4**. This skill covers the UE4 engine concepts that sit underneath the MW5
modding workflow, so an agent can reason about *why* the Mod Editor behaves
the way it does rather than just following recipes.

Detailed content lives in `reference/` and is **read on demand** — load only
the file(s) relevant to the current question, not all of them.

For the MW5-side workflow itself (Mod Editor steps, mission flow nodes,
campaign arcs), see the companion skill **`mw5mercs-editor`**.
This skill is the engine layer beneath it.

## ⚠ Version boundaries — read before adding or trusting content

- **MW5 Mercs runs UE 4.23.1.** Verified: the official MW5 Mod Editor Guide
  (v2.3) instructs modders registering a Wwise project to enter Game Engine
  = *Unreal Engine*, **Specify Version = `4.23.1`**.
- **Epic's archived UE4 docs default to 4.27** (the final UE4 release). Every
  fact in `reference/` was pulled from Epic's docs pinned to UE4 with the
  `?application_version=4.27` URL parameter.
- **Therefore 4.27 docs can describe features that did not exist in 4.23.**
  Where a feature is known or suspected to postdate 4.23, the reference files
  flag it inline as **`[post-4.23?]`**. Treat those as "verify in the Mod
  Editor before relying on it."
- **Do not use unversioned Epic doc URLs** — `dev.epicgames.com` now serves
  **UE5** documentation by default, which is out of scope and frequently
  differs (UE5 renamed/replaced Foliage Mode, Landscape layers, the Levels
  window, and much more).
- **If you cannot establish which UE version a claim applies to, leave it
  out.** An omission is cheap; a UE5 fact presented as UE4 will send a modder
  hunting for UI that does not exist in their editor.
- **MW5: Clans is UE 5.5.4 and is out of scope for this skill.** Its engine
  layer is covered by the **`unreal-engine-5`** skill in the
  `mw5clans-modding` plugin. Nothing here transfers to Clans unchecked.

To fetch more UE4 docs, always append `?application_version=4.27`:
`https://dev.epicgames.com/documentation/en-us/unreal-engine/<slug>?application_version=4.27`

Note: Epic's doc *landing/TOC* pages render their contents via JavaScript and
come back empty to a fetcher — fetch specific content pages, and use search
restricted to `dev.epicgames.com` to discover slugs.

## Reference files — read only what you need

| File | Read this when the question is about... |
|---|---|
| [reference/mw5mercs-mapping.md](reference/mw5mercs-mapping.md) | **start here for MW5 work** — which UE4 feature underlies a given MW5 Mod Editor concept (mods-as-plugins, `_MRK` sublevels, `Objectives.Type.*` tags, Data Assets, `_MTI` materials, foliage spawners) |
| [reference/gameplay-tags.md](reference/gameplay-tags.md) | hierarchical dot-notation tags, `Config/Tags/*.ini`, tag matching/parent matching, tag queries — the system behind every `Objectives.Type.*` / `UnitType.*` / `Config.Default` tag in MW5 |
| [reference/blueprints.md](reference/blueprints.md) | Blueprint Classes, parent-class inheritance, Data-Only Blueprints, Level Blueprints, Interfaces, Macro Libraries |
| [reference/data-tables-and-assets.md](reference/data-tables-and-assets.md) | Data Tables, Curve Tables, CSV/JSON import-export, Primary vs Secondary Assets, the Asset Manager, `UPrimaryDataAsset`, Asset IDs |
| [reference/editor-and-assets.md](reference/editor-and-assets.md) | `.uasset` files, packages, asset paths and references, redirectors, Plugins and `.uplugin` descriptors, the Levels window, persistent levels vs sublevels, level streaming |
| [reference/world-building.md](reference/world-building.md) | Landscape materials and paint layers, Material Instances, the Foliage tool, NavMesh Bounds Volumes |

Typical combinations: a mission-building question usually needs
`world-building.md` + `editor-and-assets.md` (sublevels); a
gameplay/data-modding question usually needs `data-tables-and-assets.md` +
`gameplay-tags.md`; almost any MW5-specific "why does the editor do this"
question should start with `mw5mercs-mapping.md`.

## Official UE4 sources

These are the two Unreal links listed on the MW5 Mercs modding resources
page, plus the version-pinned form actually used to build this skill:

| Resource | URL |
|---|---|
| UE4 Documentation (as linked from the MW5 page) | https://docs.unrealengine.com/en-US/index.html |
| UE4 Online Learning (as linked from the MW5 page) | https://www.unrealengine.com/en-US/onlinelearning |
| UE 4.27 archived documentation (version-pinned, what this skill cites) | https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-4-27-documentation?application_version=4.27 |
| Epic "Getting Started with UE4" YouTube playlist | https://www.youtube.com/user/UnrealDevelopmentKit/playlists?view=50&sort=dd&shelf_id=17 |
| Epic "Live Training" YouTube playlist | https://www.youtube.com/playlist?list=PLZlv_N0_O1ga0aV9jVqJgog0VWz1cLL5f |

Both original MW5-page links now **HTTP 403 to automated fetchers** and the
first redirects human browsers toward current (UE5) docs — which is exactly
why this skill pins to `?application_version=4.27` instead.

## How this skill was built

Content was fetched from Epic's official documentation with every request
pinned to UE4 via `?application_version=4.27`, then filtered down to what
actually bears on MW5 Mercs modding. Deliberately excluded: UE5-only
material; C++-programming-heavy topics that a Mod Editor user cannot act on
(the MW5 Mod Editor ships no C++ toolchain for modders); and features whose
introduction version could not be established. Epic's video playlists are
linked but not transcribed — they're long-form and not version-labeled per
video, so pinning their content to 4.23 vs. later UE4 isn't reliable.

The `mw5mercs-mapping.md` file is explicitly **derived** — it connects
verified UE4 documentation to verified MW5 Mod Editor documentation. Each
mapping notes which side is documented fact and which is inference.
