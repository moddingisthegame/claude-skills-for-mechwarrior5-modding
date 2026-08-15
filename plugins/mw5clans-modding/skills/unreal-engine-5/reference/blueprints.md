# UE5 Blueprints for Clans modding

Sources: Epic's Blueprint documentation, plus the shipped
`Mods/ExampleModMission/` content in the installed Clans Editor.

Blueprints are the **one authoring surface a Clans modder actually has**. The
Editor ships no engine C++ headers (see `../SKILL.md`), so Blueprint is the
whole toolbox. Fortunately this is also the area where UE4 knowledge transfers
best — the fundamentals are unchanged.

## The fundamentals (unchanged from UE4)

- A **Blueprint Class** inherits its parent's variables, components and
  functions. You extend or override; you do not copy.
- A **Data-Only Blueprint** contains only inherited members — no new graph
  logic, no new variables, no new components. UE5 opens these in a compact
  property editor rather than the full graph editor, with a link to open the
  full editor if needed.
- **Level Blueprints** exist per level and can reference actors placed in that
  level directly. They cannot be reused across levels.
- **Blueprint Interfaces** declare function signatures a class promises to
  implement, letting unrelated classes be called uniformly.
- **Blueprint Macro Libraries** hold reusable node groups. Macros are inlined
  at compile time; functions are not.
- **Construction Script** runs in-editor when properties change; **Event
  Graph** runs at play time. Placing gameplay logic in a Construction Script
  is a common and confusing mistake.

## The Clans mission-scripting pattern

`BP_KelMissionScript_Base` is an ordinary Blueprint class. The Clans workflow
is to subclass it and fill the Event Graph — the shipped example is
`Mods/ExampleModMission/Content/ModMission/Missions/BP_ModMission_MissionScript.uasset`.

The pattern the official guide repeats for nearly every mission feature:

1. Place the actor in the level and configure it in Details.
2. Create a **SoftObjectReference** variable of that actor's type in your
   `BP_KelMissionScript_Base` subclass.
3. Assign the placed actor to that variable.
4. Call nodes from that variable in the Event Graph.

Learning this once covers most of the mission guide. Exceptions — Components
rather than variables, Sets rather than single references — are called out in
the `mw5clans-editor` skill's `mission-setup.md`.

### Why soft references

A **soft object reference** (`TSoftObjectPtr`) stores an **asset path**, not a
loaded pointer. The target is not forced into memory when the referencing
Blueprint loads; you resolve it explicitly.

| | Hard reference | Soft reference |
|---|---|---|
| Stores | direct pointer | path |
| Target loads when | referencing asset loads | you resolve it |
| Blueprint node | direct access | **Resolve Soft Reference**, or async load |

Two practical consequences for Clans modders:

- **A soft reference can be unresolved at runtime.** Your graph must handle
  the null case. A mission script that assumes the actor is there will fail
  silently rather than loudly.
- **Assigning a placed actor to a soft reference variable is done in the
  level, not in the Blueprint editor** — the variable must be marked
  **Instance Editable** (the eye icon) so it appears in the actor's Details
  panel when placed.

*Why PGI standardized on soft references is inference — the load-cost argument
is the obvious motivation, but they do not state it.*

## UE5 additions worth knowing

Mostly quality-of-life, but they change what advice is current:

- **Blueprint namespaces / node filtering** reduce the node palette to
  relevant entries. If a modder says "the node isn't in the list," this is
  worth checking before concluding the API doesn't exist.
- **Improved Blueprint diffing** against source control.
- **`Event Tick` is still the wrong default.** UE5's async and timer nodes are
  better documented than UE4's; prefer timers or event-driven logic in mission
  scripts, which run alongside a Lumen/Nanite renderer that wants the frame
  budget.
- **Field Notifies / `FieldNotify`** exist for UI data binding. *Relevance to
  Clans is unverified* — CommonUI is not enabled in this project, so the UI
  stack is PGI's own.

## What is NOT available

Be direct about these when they come up:

- **No C++.** The `CodeMod` template exists but the install ships no engine
  headers. See `../SKILL.md`.
- **No Gameplay Ability System nodes.** `GameplayAbilities` is not enabled —
  no `UGameplayAbility`, no `AttributeSet`, no `GameplayEffect`. See
  [gameplay-tags.md](gameplay-tags.md) for why the tag vocabulary misleads
  here.
- **No StateTree, no MassEntity, no PCG, no CommonUI.** All present in the
  engine, all disabled in `MW5Clans.uproject`.
- **Control Rig, Niagara, Sequencer Scripting and Geometry Scripting *are*
  enabled**, so those Blueprint node families are available.

## Debugging

Standard UE5 Blueprint debugging applies and is worth recommending, since
Clans mission scripts fail quietly:

- **Print String** with a long duration, plus the **Output Log**
  (`Window → Output Log`).
- **Blueprint breakpoints** (F9) and the **Blueprint Debugger**, which work in
  PIE.
- **Watch values** on pins to inspect them live.
- **`P`** in the viewport toggles navmesh visualization — the fastest check
  when AI spawned by a mission script refuses to move.
