# Enhanced Input and the per-mod `Config/` extension points

Sources: Epic UE5 docs `enhanced-input-in-unreal-engine?application_version=5.5`,
plus `MW5Clans/Config/DefaultInput.ini` and
`MW5Clans/ModTemplates/BasicMod/Config/` in the installed Clans Editor.

## The headline: Clans runs Enhanced Input, but hands modders the legacy API

**Verified.** `Config/DefaultInput.ini` contains:

```ini
DefaultPlayerInputClass=/Script/EnhancedInput.EnhancedPlayerInput
DefaultInputComponentClass=/Script/EnhancedInput.EnhancedInputComponent
```

So the game itself is an Enhanced Input project. (`EnhancedInput.uplugin` has
`"EnabledByDefault": true`, which is why it does not appear in the
`MW5Clans.uproject` enabled list — it does not need to.)

But the **Basic Mod template** at
`ModTemplates/BasicMod/Config/Input/PLUGIN_NAMEInput.ini` offers the **UE4-era
legacy syntax**, with commented examples:

```ini
[/Script/Engine.InputSettings]
;+ActionMappings=(ActionName="InputActionName",bShift=False,bCtrl=False,bAlt=False,bCmd=False,Key=F5)
;+AxisMappings=(AxisName="InputAxisName",Scale=1.0,Key=Gamepad_RightY)
```

The template's own header comment advises: *"Add your own action and axis
mappings here, please try to give unique names for your action and axis names
so that you do not conflict with the game or other mods."*

**Guidance: follow the template.** That file is the supported, PGI-sanctioned
extension point for a mod's input. Do not tell a Clans modder to author Input
Mapping Contexts unless they have confirmed the game loads them from a mod
plugin — *that is unverified.*

This works at all because Enhanced Input ships a backward-compatibility path.
Epic states it provides "an upgrade path and backward compatibility from the
default input system from Unreal Engine 4." *The exact route Clans uses for
legacy mappings is not documented — `[verify in 5.5]`.*

Note also that the template comment links to the **UE4-era** `docs.unrealengine.com`
`EKeys` API page for key names. The key names themselves are still valid; the
URL is stale.

## Enhanced Input concepts

Worth understanding even if you author legacy mappings, because the game's own
input is built this way and any Blueprint you write may encounter it.

### Input Actions

**Data assets** representing a behavior a user can perform — "Crouch", "Fire
Weapon". Epic calls them "the communication link between the Enhanced Input
system and your project's code."

They carry a **value type**:

| Type | Data |
|---|---|
| Boolean | on/off |
| Axis1D | float |
| Axis2D | `FVector2D` |
| Axis3D | `FVector` |

This replaces UE4's hard split between *Action* mappings (digital) and *Axis*
mappings (analog) — one asset type covers both.

### Input Mapping Contexts

Collections that define **which keys trigger which Input Actions in a given
game state**. They can be added and removed **per-player at runtime**, with
priority.

Epic's illustrative example: CTRL triggers crouching while walking but sliding
while sprinting — same key, different context, no branching logic in the
handler.

This is the real conceptual upgrade over UE4, where mappings were global
Project Settings entries and context-switching meant hand-written `if` chains.

### Input Modifiers

**Preprocess the raw value before it reaches triggers.** Dead zones,
sensitivity scaling, axis swizzling, negation, smoothing. Built-in modifiers
exist and custom ones can be written in C++ **or Blueprints**.

### Input Triggers

**Decide whether a processed value actually fires the action.** They model
patterns like hold, tap, pressed, released.

Three trigger types, and the distinction matters:

| Type | Behavior |
|---|---|
| **Explicit** | the action succeeds if this trigger succeeds |
| **Implicit** | **all** implicit triggers must succeed |
| **Blocker** | forces failure |

## The per-mod `Config/` folder

The Basic Mod template ships three config extension points. All three appear
in the shipped `Mods/ExampleModMission/` too, so this is the real structure:

```
Config/
  Input/<ModName>Input.ini    legacy ActionMappings / AxisMappings
  Tags/<ModName>Tags.ini      the mod's own gameplay tags
  InstanceTypes.ini           EditInlineNew instanced-property config
```

### `Tags/<ModName>Tags.ini`

Ships as a bare `[/Script/GameplayTags.GameplayTagsList]` header. Because each
mod declares tags in its own file, mods do not collide in a shared tag list.
See [gameplay-tags.md](gameplay-tags.md).

### `InstanceTypes.ini`

Less obvious. Its own header explains it:

> *"Config file for classes that are EditInlineNew and instanced as an asset
> property. Used to configure read-only properties on an instanced type
> without making them editable in the editor asset-instanced property
> window."*

It points to `MW5Clans/Config/DefaultInstanceTypes.ini` for worked examples.
This is a **PGI mechanism**, not a stock UE5 config section — read the game's
own file before advising on it.

## What does *not* transfer from Mercs

Mercs modders configured input through the same
`[/Script/Engine.InputSettings]` block, so the *file format* is familiar. What
changed is everything underneath: the game consumes those mappings through an
Enhanced Input player-input class, so behavior at the margins (chords,
consumption, priority against the game's own contexts) may differ from UE4
expectations. If a mod's binding conflicts with a game binding, the resolution
order is **unverified** — test rather than predict.
