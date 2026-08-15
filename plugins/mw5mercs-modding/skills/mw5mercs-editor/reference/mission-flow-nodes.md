# Mission Flow Node Scripting Reference (full node catalog)

Source: `MW5 Mission Scripting Reference.pdf` —
https://mw5mercs.com/static/docs/MW5%20Mission%20Scripting%20Reference.pdf

This is the authoritative source for exact `Additional Mission Data`
parameter names per node; this file is for quick lookup of *which* node
to use. Pairs with
[mission-creation-guide.md](mission-creation-guide.md) (how nodes fit
into a whole mission) — read that first if you're new to mission
building.

A **Mission Flow Node** is the scripting unit used by the **Objective
Chain Mission Director** (the standard mission-logic system) inside a
scenario/AreaSpec file; at run time it's converted into a **Mission
Component**. If writing a fully custom mission director instead of using
this system, work with Mission Components directly.

**Common values on every node:** Name, Start On Setup?, Location, Node
Type, Parent Mission Flow Node, Definition Tags, Timer Value (only
meaningful on nodes that document it — e.g. *not* a generic node-fail
timer; see the dedicated `Objectives.Type.Timer` node instead),
Additional Mission Data, Reward/Briefing, Description MainText/SubText,
Dispatch Data.

**Common Additional Mission Data keys usable on most nodes:**
`failontimer` / `succeedontimer` / `abortontimer` (fail/succeed/abort
this component after N seconds if it hasn't already resolved),
`highlighttext` (text shown in the HUD's highlight bar).

**Creating an Option String** (used by a few Additional Mission Data
values): `MakeMap` → `CreateOptionString` with `?` as the delimiter →
feed into `MakeAdditionalMissionData`.

## Game Control / Scripted Events
- **Container** — groups child nodes; succeeds only if ALL children
  succeed, fails if ANY fails. Optional `shownumberofsubobjectives` to
  show an "x/x" counter.
- **Timer** — succeeds after N seconds (`timer` key); optional
  `ShowBar` to display a progress bar.
- **Dispatch Waves To Attack Garrison / Attack Player Lance / Go To
  Target Location** — send AI waves at a garrison, the player lance
  (avoid unless needed — alerts the whole lance regardless of distance),
  or a location; supports `wavedataX` per-wave timing/conditions
  (`waitfordeathY`, `spawnwhenremainingY`, `spawnafterdeathsY`),
  `spawnnearlocation`/`spawnnearlance` (dynamic hotdrop spawn radius),
  `minSpawnDistance`, `teamid`.
- **End Mission - Timed** — ends the mission (success by default) after
  a delay; `failure` key flips it to a failure ending; `fadetime` key
  sets the fade-out duration.
- **Ambush Limiter** — caps the number of ambush encounters that can
  trigger (`number` key); `DelayStartDialogue` defers dialogue until the
  first patrol/ambush fires.
- **Artillery Control** — orchestrates scripted artillery strikes around
  the player or a locator (`useplayerastarget` /
  `uselocatorastarget`+radius), with firing-delay and
  target-filtering options.
- **Play Start Audio** — plays a dialogue/audio line and succeeds only
  once it finishes playing (useful for gating subsequent nodes on
  narration completing).
- **Play Climactic Music** — triggers the current music set's climactic
  cue.
- **Treasure/Loot Control** — spawns random loot crates
  (`lootamount`); can exclude garrisons listed in Dispatch Targets.
- **Capture Garrison** — player must stand in a marked area, keeping
  enemies out, for `CaptureDuration` seconds (1–600); options to hide
  the capture bar/ground marker or enable garrison radar pinging.

## Building-Related Objectives
- **Destroy Buildings** — succeed when the filtered building(s) at a
  garrison locator are destroyed (`amount` picks N from the filtered
  set); filter via `Object.Building.<Details>` tags, and only buildings
  tagged `Object.Interactions.Destructible` are eligible.
- **Destroy All Buildings** — destroy N (`amount`) or a percentage
  (`percentage`) of buildings across the whole mission (mutually
  exclusive params); `checkfriendlies` flips it to friendly buildings.
- **Defend Buildings** — fails if the targeted building(s) are
  destroyed.
- **Destroy Buildings In An Area** — succeed once a `percentage` of all
  buildings at one garrison locator are destroyed.
- **Scan** — succeed once `quantity` flagged actors are scanned;
  `incorrect` adds decoy scannable actors that don't count toward
  progress.
- **Destroy Garrison** / **Defend Garrison** — percentage-of-garrison
  destroyed as success/failure condition (`percentage`); `enableping`
  (Defend only) periodically reveals enemy locations; `removebar` hides
  the garrison health bar.
- **Turn On Garrison Speech** — enables ambient commander dialogue for a
  garrison (off by default).

## Units-Related Objectives
- **Destroy Units** — succeed when specific unit GUIDs (`units` key) are
  destroyed; `percentage` (default 100%) for partial kill counts;
  `markinrange` limits marking to units within N meters of the player;
  `CheckSpawning` treats never-spawned units as already destroyed after
  a delay (10–60s).
- **Destroy Units Of Type** — succeed once `amount` units matching a
  `UnitType.<Type>` filter tag are destroyed; `checkfriendlies` flips to
  friendly units.
- **Destroy Units In An Area** — succeed once `percentage` of units at a
  garrison/encounter locator (optionally filtered by `UnitType.<Type>`)
  are destroyed.
- **Target Units** — succeed once specific unit GUIDs are player-targeted
  (not necessarily destroyed).

## Movement-Related Objectives
- **Go To** — reach a waypoint volume (default box 200×200×90m; override
  with `usesphere`+radius, or `length`/`breadth`/`height`);
  `usenpcallies` lets NPC allies (not just the player) satisfy it;
  `TriggerOnExit` flips it to trigger on leaving the volume instead of
  entering.
- **Evac - Go To Safety Zone** — reach and hold at an extraction point;
  waits for Success Audio to finish before ending, if any is playing.
- **Evac - Go To Extraction Point** — same, but tied to a specific
  hotdrop-locator dropship pickup; `spawnnearlance` can dynamically pick
  the nearest valid reinforcement locator.
- **Go To Garrison** — reach a garrison's inner detection zone.
- **Go To Units** — reach within `range` meters of any of the listed unit
  GUIDs; player-controlled lancemate only (not AI lancemates).

## One-Offs
- **Repair** — succeed on using a repair bay at the given locator.

## Deprecated
Legacy `Objectives.Type.Dispatch` nodes — superseded by the
non-deprecated Dispatch Waves To \* nodes above; documented in the
reference only for maintaining old missions:
`<DEPR> Dispatch: Waves - Attack Garrison`, `Waves - Attack Player`,
`Waves - Go To New Base (Home Location)`, `Reinforce 1st Dispatch
Target`, `Alert 1st Dispatch Target`.
