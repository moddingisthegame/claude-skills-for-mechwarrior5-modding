# UE4 Blueprints

Sources: Epic UE4 docs, pinned to 4.27 —
[Types of Blueprints](https://dev.epicgames.com/documentation/en-us/unreal-engine/types-of-blueprints?application_version=4.27),
[Blueprint Class](https://dev.epicgames.com/documentation/en-us/unreal-engine/blueprint-class?application_version=4.27)

Relevant to MW5 mainly for **parent-class inheritance** — MW5's Campaign Arc
Actions are Blueprint Classes created by picking an MW5 parent class, and
MW5's `SquadCommandComponent` etc. are Blueprints you substitution-mod.

## Blueprint Class

A **Blueprint Class** is an asset that lets content creators add
functionality on top of existing gameplay classes, authored visually in the
editor instead of by typing code. It is saved as an asset in a content
package and effectively defines a new class/type of Actor, which can then be
placed into maps as instances.

Use it for gameplay elements you will have multiple instances of.

### Choosing a parent class

Creating a Blueprint Class requires specifying a **Parent Class** to inherit
properties from. Common parents documented for 4.27:

| Parent | What it is |
|---|---|
| **Actor** | An object that can be placed or spawned in the world |
| **Pawn** | An Actor that can be "possessed" and receive input from a Controller |
| **Character** | A Pawn that includes the ability to walk, run, jump, and more |
| **PlayerController** | An Actor responsible for controlling a Pawn used by the player |

Game Mode is also referenced as a parent option. The parent-picker dialog
additionally exposes an **All Classes** tree with a search filter — this is
how MW5 has you find `PlaceMission_ArcAction`, `SetObjectiveState_ArcAction`,
and `ResetScenario_ArcAction`.

### Inheritance

Blueprint Classes support hierarchical design: a child inherits everything
from its parent and adds or overrides on top. Epic's example: an `Animals`
Blueprint defines shared functionality, and a `Dogs` child Blueprint inherits
it while adding dog-specific behavior.

This is exactly the structure behind MW5's arc actions
(`MWCampaignArcAction` → `PlaceMission_ArcAction` → your
`PlaceQuest_ArcAction`) and behind `DerivedMech` spawn classes.

## Types of Blueprints

**Blueprint Class** — as above; the general case.

**Data-Only Blueprint** — a Blueprint Class containing *only* the code,
variables and components inherited from its parent. You can tweak and modify
those inherited properties, but **cannot add new elements** — no new
variables, no new components, no new code. UE4 opens these in a compact
property editor rather than the full graph editor. Use when you want
property variations without new functionality.

> This is the shape MW5's Campaign Arc Actions take in practice — you only
> fill in inherited fields like `Objective`, `Scenario`, `StarSystemId`,
> `Operation`.

**Level Blueprint** — a specialized Blueprint acting as a level-wide global
event graph. Every level has one by default. Used for level-specific events,
events on actor instances within that level, level streaming control, and
Sequencer binding. (UE3 users: this is the successor to Kismet.)

**Blueprint Interface** — a collection of function signatures (names only,
no implementations) that can be added to other Blueprints, guaranteeing those
functions exist across otherwise-unrelated Blueprint types. Cannot add
variables, edit graphs, or add components. Use when several different
Blueprints must communicate through a shared contract.

**Blueprint Macro Library** — a container holding reusable self-contained
graphs placeable as nodes in other Blueprints, with defined inputs and
outputs. They behave like collapsed nodes at compile time. Use to store
commonly repeated node sequences.

**Blueprint Utility (Blutility)** — an editor-only Blueprint used to perform
editor actions or extend editor functionality. *(Listed in 4.27's type
overview; Epic's page did not detail it further, and its availability/naming
in 4.23 was not established — treat as `[post-4.23?]` for MW5 purposes.)*

## Caution for MW5 work

MW5's **Mission Flow Nodes are not Blueprint nodes** and its "Mission Flow
Node Connections" are not Blueprint wires — they are array entries in an
AreaSpec's Details panel. Blueprint graph knowledge does not transfer there.
See [mw5mercs-mapping.md](mw5mercs-mapping.md).
