# UE4 Gameplay Tags

Source: Epic UE4 docs, pinned to 4.27 —
https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-tags?application_version=4.27

The system behind essentially every MW5 Mercs tag (`Objectives.Type.*`,
`UnitType.*`, `Object.Building.*`, `Config.Default`, `DialogueContext.*`).
See [mw5mercs-mapping.md](mw5mercs-mapping.md) for the MW5-specific
implications.

## Core concept

Gameplay Tags are hierarchical, user-defined labels for identifying and
categorizing objects, written in **dot notation**. A tag implicitly carries
all of its ancestors: `Vehicle.Air.Helicopter` implies `Vehicle.Air` and
`Vehicle`.

Two data types:
- **`FGameplayTag`** — a single tag.
- **`FGameplayTagContainer`** — multiple tags, with additional query
  capability.

## Defining tags — three methods

All are configured under **Project Settings > Project > Gameplay Tags**.

**1. Manually, through Project Settings.** Enable **Import Tags From
Config**, which loads `Config/DefaultGameplayTags.ini` plus any files in
`Config/Tags/`. The UI offers **Add New Gameplay Tag**, with an optional
description used as a tooltip.

**2. By editing `.ini` files directly** in `Config/Tags/`:

```ini
[/Script/GameplayTags.GameplayTagsList]
GameplayTagList=(Tag="Vehicle.Air.Helicopter",DevComment="tooltip text")
```

A separate developer-only config file can be designated via the **Gameplay
Tags Developer** settings.

> This is exactly the mechanism MW5's per-mod `Config/Tags/<ModName>Tags.ini`
> uses — a plugin shipping its own tag ini rather than editing shared tag
> assets, which is what makes mod-added tags conflict-free.

**3. From DataTable assets.** Create a DataTable with row type
**`GameplayTagTableRow`**, then add it to the **Gameplay Tag Table List** in
Project Settings (click **Add Element (+)**, then pick your DataTable from
the new index's dropdown). Useful for importing tags from spreadsheets.

## Managing tags

Project Settings dropdowns allow:
- **Searching for references** to a tag.
- **Deleting** — only permitted for `.ini`-sourced tags with no references.
- **Renaming** — creates a `GameplayTagRedirects` entry so existing
  references keep resolving.

## Restricted tags `[post-4.23?]`

Under **Advanced Gameplay Tags**, tags can be restricted so only designated
owners may modify them: specify owners, use a non-default ini (e.g.
`RestrictedTags.ini`), and control child creation with
`bAllowNonRestrictedChildren`. Restricted tags hide rename/delete options
from non-owners.

*Version note: the introduction version of restricted tags could not be
established, so do not assume this exists in MW5's 4.23.1 editor without
checking.*

## Matching and testing

Hierarchical matching distinguishes exact matches from parent matches —
the most important behavior to internalize:

| Operation | Behavior |
|---|---|
| `MatchesTag` / `HasTag` | **Parent match** (hierarchical) — a query for `Vehicle` matches `Vehicle.Air.Helicopter` |
| `MatchesTagExact` / `HasTagExact` | Exact match only |
| `MatchesAny` / `HasAny` | True if any tag matches (parent or exact) |
| `MatchesAllExact` / `HasAllExact` | All must match exactly |

Empty containers return `false` for everything except `HasAll` /
`MatchesAll`.

## Gameplay Tag Queries

Queries encapsulate reusable tests, built from three basic operations:
- **Any Tags Match** — at least one tag found.
- **All Tags Match** — no tags missing.
- **No Tags Match** — zero overlap.

These nest inside expression containers (**Any Expressions Match**, **All
Expressions Match**, **No Expressions Match**) to build compound logic.

## Using tags on objects

Add an `FGameplayTag` or `FGameplayTagContainer` property to a game object
and edit it in code or in the editor. For a uniform way to read tags across
unrelated object types, implement **`IGameplayTagAssetInterface`** in C++ and
override **`GetOwnedGameplayTags()`**.

> The C++ portion is background for modders — the MW5 Mod Editor exposes no
> C++ toolchain. It matters only for understanding why MW5's own classes can
> all be queried for tags uniformly.
