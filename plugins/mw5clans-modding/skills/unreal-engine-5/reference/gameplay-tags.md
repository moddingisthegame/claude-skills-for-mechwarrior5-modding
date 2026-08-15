# UE5 Gameplay Tags in Clans

Sources: `MW5Clans/Config/DefaultGameplayTags.ini` and the 53 files in
`MW5Clans/Config/Tags/` in the installed Clans Editor, plus Epic's Gameplay
Tags documentation.

**This is the system that transfers most cleanly from Mercs.** The mechanism
is essentially unchanged between UE4 and UE5, so a Mercs modder's tag
intuitions are reliable here — unusually for Clans.

## The model

A Gameplay Tag is a **hierarchical dot-notation label**:
`Objectives.Class.ActivateInLineOfSight`, `Unit.Assignment.Guard`,
`Campaign.Logic.Research`.

Two properties do almost all the work:

- **Dots create implicit parents.** `Objectives.Class.Optional` implicitly
  carries `Objectives.Class` and `Objectives`. A filter written against a
  parent matches every child.
- **Matching is parent-aware by default.** `HasTag` / `MatchesTag` respect the
  hierarchy; exact-match variants (`HasTagExact`) exist when you need them. If
  a filter behaves more broadly than expected, hierarchical matching is the
  first thing to suspect.

## How Clans declares them

`Config/DefaultGameplayTags.ini` turns on config-driven tags:

```ini
[/Script/GameplayTags.GameplayTagsSettings]
ImportTagsFromConfig=True
WarnOnInvalidTags=True
ClearInvalidTags=False
AllowEditorTagUnloading=True
AllowGameTagUnloading=False
FastReplication=False
InvalidTagCharacters="\"',"
NumBitsForContainerSize=6
NetIndexFirstBitSegment=16
```

Tags themselves are split across **53 domain files** in `Config/Tags/`:

| Prefix | Examples |
|---|---|
| `Kel*` — Clans-native systems | `KelCampaignLogicTags.ini`, `KelUnitAttributeTags.ini`, `KelInventoryTags.ini`, `KelUIBreadcrumbingTags.ini`, `KelStoryTags.ini`, `KelBossUnitTags.ini` |
| `MW5*` — vocabulary inherited from the Mercs codebase | `MW5ObjectivesTags.ini`, `MW5MechTags.ini`, `MW5WeaponTags.ini`, `MW5UnitTags.ini`, `MW5BiomeTags.ini`, `MW5DialogueContextTags.ini` |

The declaration format inside those files:

```ini
[/Script/GameplayTags.GameplayTagsList]
GameplayTagList=(Tag="Objectives.Class.ActivateInLineOfSight",DevComment="")
GameplayTagList=(Tag="Unit.Assignment.Guard",DevComment="Stay near encounter and protect assets")
GameplayTagList=(Tag="Unit.Assignment.Dispatch",DevComment="Can be assigned to other encounters")
```

Two details worth getting right:

- The per-domain files use plain **`GameplayTagList=`**, while
  `DefaultGameplayTags.ini` uses the **`+GameplayTagList=`** array-append form.
  Match whichever file you are editing.
- **`DevComment` is populated with real semantics in places** — the
  `Unit.Assignment.*` examples above document actual AI behavior. When a
  modder asks what a Clans tag means, `grep` the `Config/Tags/` files for it
  before speculating; PGI may have already answered.

## Tag redirects — check these before calling a tag wrong

`DefaultGameplayTags.ini` carries a substantial `GameplayTagRedirects` list:

```ini
+GameplayTagRedirects=(OldTagName="Encounter.Garrison.MainBase.Large",NewTagName="Encounter.Garrison.MainOperating.Large")
+GameplayTagRedirects=(OldTagName="TileElement.Type.Garrison.Blockade",NewTagName="TileElement.Type.Garrison.Emplacement")
+GameplayTagRedirects=(OldTagName="UI.ColorPalette.HUD.Health",NewTagName="UI.ColorPalette.HUD.Level")
+GameplayTagRedirects=(OldTagName="Campaign.Logic.ChassisAchievements",NewTagName="Campaign.Logic.Achievements")
+GameplayTagRedirects=(OldTagName="Inventory.PlannedRepair",NewTagName="Inventory.Planned")
```

This is UE5's rename-compatibility mechanism: assets referencing the old name
resolve transparently to the new one.

**Practical consequence: tag names in older community guides, forum posts, or
the official video tutorials may be stale.** Before telling a modder a tag
name is wrong, check whether it appears as an `OldTagName` — if it does, the
guide was right when written and the redirect is still honoring it.

## Per-mod tags

The Basic Mod template ships
`ModTemplates/BasicMod/Config/Tags/PLUGIN_NAMETags.ini` containing only:

```ini
[/Script/GameplayTags.GameplayTagsList]
```

Because `ImportTagsFromConfig=True` loads `Config/Tags/` across the project
and its plugins, **each mod contributes its own tag file and mods do not
collide**. This is the same guarantee Mercs offered, and it is one of the few
Mercs techniques that carries over unchanged.

Advice for mod authors: **namespace your root tag** with something
mod-specific rather than extending `Objectives.` or `Unit.` directly.
Extending a game-owned branch works, but a future PGI patch that adds a
same-named child creates an ambiguity you will not enjoy debugging.
*(Namespacing advice is judgment, not PGI guidance.)*

## The GAS trap

Clans' tag vocabulary is elaborate enough to look like a **Gameplay Ability
System** project — `KelEffectApplicationContextTags.ini`,
`KelGameplayEventTags.ini` and `KelUnitAttributeTags.ini` all use GAS-flavored
vocabulary (*effect*, *event*, *attribute*).

**It is not.** `GameplayAbilities.uplugin` has `"EnabledByDefault": false` and
the plugin is **not** enabled in `MW5Clans.uproject`. Those tags are consumed
by PGI's own systems.

Do not suggest `UGameplayAbility`, `UAttributeSet`, `FGameplayEffectSpec`, or
any GAS Blueprint node to a Clans modder. Gameplay Tags are usable **without**
GAS — the tag system lives in its own module (`GameplayTags`), which is what
Clans uses.
