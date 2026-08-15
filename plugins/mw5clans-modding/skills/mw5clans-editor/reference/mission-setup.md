# Mod Mission Setup — MW5: Clans

Source: `KEL-Mod-Mission-Setup-v1.pdf` (69 pp) —
https://mw5clans.com/downloads/KEL-Mod-Mission-Setup-v1.pdf

Step-by-step mission authoring, broad to specific. Nearly everything routes
through one Blueprint: **`BP_KelMissionScript_Base`** ("the MissionScript").

This document also folds in corrections and additions from four official
video tutorials (auto-generated captions, reviewed and paraphrased — not
verbatim transcripts), linked at point of use below. Offer the relevant video
to a user who wants a visual walkthrough or when a question needs more detail
than what's written here.

## The recurring pattern

Almost every feature below follows the same three steps. Learn it once:

1. **Place the actor** in the level and configure it in the Details panel.
2. **Create a variable** in the MissionScript — nearly always a
   **SoftObjectReference** of that actor's type.
3. **Assign the placed actor** to that variable on the MissionScript instance,
   then call nodes from it in the Event Graph.

Where a step deviates (a Component instead of a variable, a Set instead of a
single reference), it is called out below.

## Set up a mod

**Mod Manager → New Mod →** keep the folder as-is, name it, select **Basic
Mod** (which enables **Create Mod**) **→ Create Mod →** restart Unreal. You
now have a Content folder under `Plugins/<ModName>`.

### Set up the Holo Table

*Video: [05 Campaign and Holotable Set up](https://www.youtube.com/watch?v=nWfuseI5R08) (9:08).*

- Create a **`KelCampaignTrigger`** asset (found under **Kelpie**). Set
  **Valid Campaigns** = `CoreGame_Attributes`, **Active** = `Always True`.
  The **Valid Campaigns** dropdown has more entries than just the core game
  (DLC/story-specific options were visible on screen but not clearly
  legible in captions — pick the core game option unless targeting a
  specific DLC campaign).
- Create a **DataTable** asset as a **`KelLocaleDataAsset`**. Fill in
  **Display Name**, **Holotable Prop**, **Component Name**, **Scenario**
  (created later — see *Make mission playable in campaign*) and
  **Trigger Asset**.
  **Component Name must be `Planet`** (capital P) for it to appear.

## Creating a level

*Video: [02 Level Creation](https://www.youtube.com/watch?v=rBORWUGXzg4) (18:13).*

Suggested folder layout: a `Missions` root, a folder per mission, and inside
that one folder for sublevels and one for mission files.

1. Right-click in the mission folder → create your level.
2. Add an existing lighting sublevel so you can see — the guide uses
   `L_Lighting_daytime_no_fog`.
3. Add a **landscape** with a heightmap (sculpt in Unreal or import).
   **Landscape resolution is 4081 x 4081.** Use material
   `LandscapeTest_MTL` to see it properly. Must be authored while the
   **Persistent Level** is the active level, not a sublevel. If building a
   blank canvas instead of importing a heightmap, don't hit **Fill World**
   — that does something else; use **Create** with a component count
   (e.g. 64x64) for a flat starting canvas.
4. Create a new **sublevel**. Set sublevels to **Always Loaded** or they
   won't be visible in game — **this includes the lighting sublevel**;
   skip it there and the level renders dark with nothing visible.
5. Add a **`NavMeshBoundsVolume`** roughly the size of the map so AI can
   move (zero out its location in Details to center it on the map, then
   scale the Transform to cover the play area). Build it via **Build →
   Build Paths** (once destructible zones exist, use **Kel Build Map**
   instead — see *Destructible zone Objective* — which builds destructibles
   and navigation together). Press **`P`** to visualise NavMesh once built.
6. In the Missions folder create a **`BP_KelMissionScript_Base`**, named for
   your mission. This holds all mission logic.
7. Drag the MissionScript into the Gameplay level, plus a
   **`CinematicStartEncounter`**.
8. Drag in **5 `MWSpawnPoints`** (the player squad) and a
   **`BP_CinematicStartEncounterSequence`**. Assign them in the
   `CinematicStartEncounter`.
9. Assign the `CinematicStartEncounter` to the MissionScript — this is what
   tells players to spawn. Toggle **On Initial Power State** on the
   `CinematicStartEncounter` if mechs should start already powered up
   (skips the manual power-up step during testing).
10. Create a LevelSequences folder and a **Level Sequence** with a **1-second
    Fade track** (opacity 1 at 0s → opacity 0 at 1s — fades in from black).
    The project needs an intro sequence to let the mechs walk around. Assign
    it to `BP_CinematicStartEncounterSequence`'s **Sequence Asset**, then
    play it from the MissionScript.
11. **World Settings → override GameMode to `BP_KelMissionScriptTestMode`**
    to test in-editor.
12. Confirm the **MissionScript** and **Default Mission Start** are selected.

### Starting the mission from the Event Graph

On the MissionScript's **Event Start Mission**: right-click it and add
**Call to Parent Function** first (runs the base class's own startup logic —
skip this and things silently don't run properly). Then: get the
`CinematicStartEncounter` soft reference, resolve it and cast to
`CinematicStartEncounter`, call **Start Encounter** on it, **Bind Event to
On Finished**, then from that bound event create a matching custom event
(e.g. `MissionStart`) to hang the rest of the mission's logic off of once
the intro finishes.

### Make mission playable in campaign

*Video: [05 Campaign and Holotable Set up](https://www.youtube.com/watch?v=nWfuseI5R08) (9:08).*

- Create an **`MW.AreaSpecification`** asset **before** the
  `MW.ScenarioSpecification` below — the scenario needs to reference a
  completed Area Spec. **Level Path** = your Persistent Level; under **Kel
  Mission Script Parameters → Mission Script** = your MissionScript.
- Create an **`MW.ScenarioSpecification`** asset. Click **Generate** for the
  **Scenario Id** and **save immediately** — this ID is important and
  shouldn't be left uncommitted. Add a **Mission Name**, set **Allowed
  Tonnage** (500 or lower depending on permitted mech weight). Set **Area
  Spec Asset** to the `MW.AreaSpecification` and **Trigger Condition** to the
  `KelCampaignTrigger`. There are also **Level Completion Rewards** and a
  next-mission prep-time field on this asset that neither PDF nor the video
  explains in depth — left undocumented here rather than guessed at.
- Go back to the `KelLocaleDataAsset` and set its **Scenario** field now
  that the scenario exists (the two assets reference each other).
- To test: **Play** from an empty/restarted level to reach the base game's
  main menu, confirm the mod is enabled under the **Mods** menu, then start
  a new campaign. Starting partway through the campaign (rather than from
  the very beginning) reaches the Holotable faster for iteration.

## Objectives

*Video: [03 Objectives](https://www.youtube.com/watch?v=cLWl22ZfUsU) (38:44)
— covers all six objective types below in depth.*

Every **Add Objective** node shares these fields:

| Field | Options / notes |
|---|---|
| Objective Type | **Primary** (shown top-left, the main goal), **Secondary**, **Optional**, **Unlisted** (tracked but not shown to the player — also a way to drive one visible objective from many hidden triggers), **Status**, **Additional Mission Parameters** |
| Progress Style | **None**, **Progress Counter** (e.g. kill 5/5, counts up), **Percentage** (e.g. % of a base destroyed), **Tally** (similar to Progress Counter), **Capture** (for capture objectives) |
| Display Text | Shown on the left of the screen |
| Marker Class | The in-world marker widget. Common ones seen in official use: **Primary Objective Marker** (default/most common), **Attack Building Marker** (destroy-building objectives), **Active Comms Marker** (scan objectives) |

After creating an objective, **promote it to a variable immediately** — it's
referenced repeatedly later. Any objective variable also exposes a
**Resolve** node to complete it manually, for cases where the automatic
tracking node for its type doesn't fit your logic flow.

### Objective Waypoint
Drag in a trigger, make it large, ensure **Generate Overlap Events = true**.
The trigger's **pivot/center point is where the on-screen marker renders** —
keep it near ground level, not floating at the geometric center of a tall
box. In the MissionScript create a **`TriggerBase`** SoftObjectReference
variable. From the mission-start event, add **Add Objective**. Then add
**`TrackVolumeEnteredByUnit`**, plugging in the trigger and objective — its
**Objective Tracking** pin won't accept the objective variable directly;
use **Split Struct Pin** (or build a Set) first. Logic can fire after the
trigger is hit by whatever the unit filter specifies.

### Destroy Objective
Place an object with a **Destructible Component** (guide uses
`UTL_Industrial_Military_SatelliteDish`). Create two variables: the actor
(type **Actor**, SoftObjectReference) and the objective (type
**MWObjective**, Object Reference).

In the **Components** tab create a **`DestroyObjectivesTracker`** — only one
is needed in the level even across multiple destroy objectives. Drag it into
the Event Graph, get its **Objectives to Destroy** array, and add your
actor. This array is a **hard reference array**; resolve your actor's soft
reference into it (rather than hard-referencing the actor directly) to
avoid load-time issues. Add an **Add Destroy Object Objective** node with
Display Text and Marker Class, plugging in the actors-to-destroy and the
tracker. **Progress Style** can be set to *Progress Counter* to show a
count.

**The objective does not resolve automatically** — bind an event to
**OnObjectivesDestroyed** to resolve it and continue. **Gotcha:** if the
destructible target can be destroyed by the player before this
tracker/objective setup has actually run, it throws an error — make sure
the objective is live before the target is reachable.

### Destroy Units Objective
Create an **Add Objective** node with Display Text (everything else
optional). Plug the **MWObjective** variable into the **SpawnUnits** node and
it tracks the units spawned. Units can also be tracked later rather than at
spawn time.

### Scan Objective
Place an actor with a **`KelScannableComponent`** (guide uses
`BP_GateTerminal`). Create variables for the actor and the objective. Add an
**Add Objective** node with Display Text, then a
**`StartTrackingInteractionTasks`** node with the scan actor and scan
objective plugged in — this needs an array, and it's a soft-reference array
(use Split Struct Pin as above). Completes when scanned.

`KelScannableComponent` settings worth knowing (per-instance, doesn't affect
the parent class): **Is Interactable** toggle; interaction type — **Basic**,
**Charge Match**, **Waveform Match**, **Code Match**, **Circles Match**;
**Object Name** (the display label, e.g. "Terminal" vs "Gate Terminal");
**Segments** (number of scan stages required — fewer is faster to
complete); **Radial Duration** (time to fill the scan ring per attempt).
Any actor can get scan behavior by adding a `KelScannableComponent` to it.

### Destructible zone Objective
1. You need something to destroy. A **Garrison from MW5 Mercenaries** can be
   added. Copy the garrison you want into your `LevelInstance` folder.
2. Open it and **delete the foliage and landscape actors — these aren't used
   in Clans and won't work.**
3. Add it to your level as a sublevel and position it.
4. Place a **`BP_KelMissionObjectiveDestructibleZone`** over the garrison and
   set its radius.
5. **Build → Kel Build Map** (builds destructibles and navigation together).
6. Select the zone and click **Generate** so destruction registers. Set it to
   **hostile** if friendly mechs should target the buildings.
7. Create a **Set** of SoftObjectReferences of type
   `BP_KelMissionObjectiveDestructibleZone`, plus an **MWObjective** variable.
8. **Add Objective**, then a **Track Destructibles** node with the zone and
   objective. Give the **Destruction Meter** a name and set a **Destruction
   Complete Target**. Logic can fire at intermediate destruction percentages.

### Timer Objective
**Add Timer Objective** node — **Count Down** (bool), **Display Text**,
**Time in Seconds**, **Time Expired Resolution**.

## Spawning AI

*Video: [04 AI Set up](https://www.youtube.com/watch?v=xmhwY86tlNM) (31:57) —
covers this section plus **Waypoints** and **JumpJet links** below.*

Place **UnitCards** in the level. They can **AutoSpawn**, but the guide
recommends spawning via the MissionScript so they appear when needed. After
spawning, send units to a **Waypoint** then an **AttackWaypoint** to get them
out of their spawn location.

Key UnitCard settings:
- **Team** — Hostile, Neutral or Friendly (one video shows the dropdown as
  Hostile/Allied/Neutral/No Team instead — labels may have changed between
  the PDF and the current build; verify against the live dropdown)
- **Attitude** — Passive or Aggressive
- **Behavior Config** — difficulty; named tiers seen in the editor: Green,
  Regular, Veteran, Elite, Boss (plus custom boss behaviors)
- **Combat Tactic** — behavior preset: **Hit and Run** (fast mechs, hit and
  disengage), **Mobile** (fast, stays close, mixes in melee), **Tank**
  (closes in and stays in the player's face), **Ranged** (snipers/missile
  boats)
- **Paint Theme** — faction skin (e.g. a specific Clan or Inner Sphere house)
- **Leader** — designates one unit in a group; other units with a leader set
  will follow it into battle
- **Sequence List** — movement and targeting

Placement matters for more than position: the unit's forward (X) axis at
spawn is the direction it faces, so orient the placed actor toward where it
should be looking, not just where it should stand.

Create a **`KelUnitSpawner`** SoftObjectReference variable and use a
**SpawnUnits** node.

**Spawn locations:**
- **Hidden** placement
- **Dropships** — `BP_SpawnSequence_LeopardDrop` (Inner Sphere, max 4) and
  `BP_SpawnSequence_BroadswordDrop` (Clan, max 5). The mech portraits shown
  in the dropship actor's slot list do **not** reflect the actual landing
  spot — units drop from inside the ship. **Origin Relative** controls
  whether the drop point is relative to the placed dropship actor; turn it
  off only if building a fully custom drop sequence for that level.
- **Spawn Door** — `BP_SpawnSequence_MegaFactoryDoor`
- **Spawn Garages** — `BP_SpawnSequence_GroundGarage`. Place on
  reasonably flat ground; units emerge one at a time through the garage
  doors — useful for indoor/underground spawns where a dropship doesn't
  make sense.

### Track Unit Death / Damage

**Track Unit Death** outputs: Pass through, Unit Death (fires per death),
All Units Dead, Dead Enemy (the actor that died), Total Dead, Percentage Dead.
For conditional logic (e.g. "spawn reinforcements once 2 of 4 are dead" via
an integer counter + branch), wire off **All Units Dead** rather than the
raw Pass-through output where possible — called out as the safer choice.

**Track Unit Damage** outputs: Pass through, Unit Damage, Damaged Unit,
Damage, Accumulated Damage, Critical Health Percent.

## Waypoints

All three waypoint types share these settings:

| Setting | Meaning |
|---|---|
| Radius | How close the unit must get to count as "arrived." Smaller = tighter precision (e.g. a sniper spot right at a ledge); larger = more leeway |
| Assigned Actor | Only used by SmartObjectWaypoint |
| Switch To | Move to a waypoint outside the UnitCard's sequence |
| Start Attitude | Attitude while moving to this waypoint |
| End Attitude | Attitude once reached |
| Start/End Perception Config | **Not used** |
| Hold Delay | Seconds before next waypoint (**0.0 = infinite** — stays forever; used as a rough stand-in for a guard point when not using SmartObjectWaypoint) |
| Hold Damage | Damage taken before moving on (**0.0 = infinite** — holds regardless of damage taken; useful for a sniper/ambush unit that should break off after taking a hit or two, set above 0) |

**Start/End Attitude values and their actual effect:** **Aggressive** — breaks
off the waypoint route the instant it perceives an enemy and just attacks;
**Safe** — returns fire but stays on the planned route (the commonly
recommended default so units still look like they're following a designed
path); **Passive** — follows the route no matter what and never fires back,
even under fire.

**Cycle Sequence** (set on the UnitCard's sequence list, not per-waypoint)
loops the waypoint list — useful for patrols/guard loops; leave off for a
one-shot route, which is the more common case.

**MoveToWaypoint** — the unit moves to it.

**SmartObjectWaypoint** — uses **Assigned Actor** to make units behave more
intelligently. Smart actor types:
- **GuardPoint** — waits the Hold time, looks left and right
- **ParkingSpot** — unit can't move unless told otherwise
- **Melee Target** — melees targets in range
- **LandingPad** — VTOLs only, like ParkingSpot
- **LookAtPlayer** — focuses on the player

**Gotcha:** once a SmartObjectWaypoint's Assigned Actor is set (e.g. to a
placed GuardPoint), the waypoint marker snaps to that actor's location.
Moving the waypoint node itself does nothing further — reposition it by
moving the assigned GuardPoint actor instead.

**AttackWaypoint** — use on all AI that needs to attack. Anything entering
its radius is selected as a target, which stops AI standing around. Extra
settings:
- **Hold Position** — stay put once reached
- **Combat Range Override** — replaces the waypoint radius as combat range

Common pattern: end a sequence of MoveToWaypoints with one large
AttackWaypoint as the final entry — useful for reinforcements that arrive
without direct line of sight on the player, so they push into the area and
engage the nearest target instead of standing idle.

## JumpJet links

For mechs with jump jets, to force jumping over obstacles or down ledges.

Set the UnitCard's **Initial Attitude** to **Safe** or **Passive** so it
doesn't break off to attack. Give it a **MoveToWaypoint** for the
destination and an **AttackWaypoint** for on-arrival; set the
MoveToWaypoint's **End Attitude** to **Aggressive**.

Drag in a **`KelJumpJetNavLinkProxy`**. It has **Left and Right handles** —
move a handle to the surface the mech comes from and **make sure it
intersects the landscape mesh** so it influences the NavMesh. Place it in the
unit's path. The guide recommends **three of them** so the link is still hit
if the path shifts slightly. Run **KelBuildMap**, then press **`P`** to
confirm the link is active.

## Custom UnitCards

Keep custom units in their own folder inside the mission folder. Copy any
UnitCard you want to customise.

**Only these settings should be touched:**
- **Mech Loadout Template** (copy the file and change it)
- **Mech Starting Structure Damage**
- **Mech Starting Armor Damage**
- **Mech Starting Rear Armor Damage**
- **AIBehaviour Config** (copyable; exposes health, accuracy, etc.)
- **Persona Asset** (speaking pilot)
- **Unit Skin Customization**
- **Unit Quirks** (can dramatically strengthen/weaken a unit — e.g. double
  damage)

The Mech Loadout holds structure health, armor and weapon group settings.

## Mission features

### Repair bays
**`MobileRepairBase`** — set **Is Powered = true** to work. Settings: **Ammo
Resupply** (%), **Armor Repair** (%), **Uses**, **Is Powered**, **Infinite
Uses**. Toggle at runtime by calling **Manage Power** from a
`MobileRepairBase` SoftObjectReference variable.

### Out of bounds system (OOB)
Create a **spline** covering the whole play area, **flush with the landscape**
and set to **Loop**. With it selected go to **MeshSplines**: **Thickness = 1**,
**Output Type = Volume**, **Volume Type = `KelMissionAreaVolume`**. Accept.

Select the volume in the Outliner, click **GenerateMissionAreaMesh** to create
a Mesh Actor in the mission folder root, and save that mesh.

Multiple volumes can exist to open up more space later. **The first active one
must be Enabled and the rest Disabled.** When swapping at runtime, **enable
the new one before disabling the old** — one must be active at all times. Use
**Enable Mission Area**.

### Artillery
Place an **Artillery** actor. Under **Allegiance** set it **Hostile** and
**Can Target when Hostile = true**.

Place a **`BP_ArtilleryBombardmentZone`** where it should fire. Assign the
artillery to **Artillery Source Soft** and set **Auto Start**. Settings:
- **Artillery Source Soft** — firing stops when this artillery is destroyed
- **Explosion Class External** — leave alone
- **Auto Start**, **Radius**, **Bombing Interval in Seconds**,
  **Num Bombs Per Interval**, **Max Random Bomb Launch Delay**

Enable in script by calling **Set Enabled** from a zone variable.

### Turrets
Variants: **Regular Turret**, **Turret Tower**, **Turret Popup** (pops out of
ground or walls when a hostile is close).

**Popup turrets in MissionScript** — UnitCards named **Triggered** can be
driven from script. Create a `KelUnitSpawner` SoftObjectReference pointing at
the Popup Turret Triggered UnitCard, then call **Activate Popup Turrets** /
**Deactivate Popup Turrets**.

**Capture turrets** — players can convert hostile turrets. Place a
`UTL_GPL_Military_Industrial_SmallTurretControlTower`; the guide puts a
`BP_TurretControlTower_Bunker` on top to stop it being destroyed. Assign
turrets to the tower's **Linked Turret Spawners**. In the MissionScript create
an **Actor** SoftObjectReference for the tower and call **Start Tracking
Interaction Tasks** with it as **Tasked Actors**.

### Indestructible units
Create a **`KelIndestructibleScript`** **Component**. In Details, add units to
the **Spawner List**. Drag the component into the Event Graph and call
**Request Indestructible** (true to make them indestructible).

### Gates
Guide uses **`BP_Space_Station_Gate`** plus cubes on each side to actually
block the path. A **`BP_Gate_Terminal`** is scanned to open/close it. On the
terminal's **KelScannableComponent**: **Interaction|NumSectionRequired = 1**,
**bDestroyScanComponentAfterInteraction = false**,
**bIsOneTimeInteraction = false**.

Two SoftObjectReference variables (terminal as **Actor**, gate as
**BP_Space_Station_Gate**). Call **Start Tracking Interaction Tasks** on the
terminal. The guide uses a **FlipFlop** — output A calls **Open Door**,
output B calls **Close Door** — with a sequence resetting the interaction
after 5 seconds to give the gate time to move.

### Hiding mesh from Battlegrid
A roof (structure or cave) blocks Battlegrid commands. Set the mesh's
**Collision Presets = Custom** and **Visibility = Ignore**.

### Proximity mines
Placeable as Friendly or Hostile. Settings: **Explosion Radius**, **Explosion
Damage**, **Explosion Delay**, **Health Points**, **Team Membership**.
*Anything not listed here should not be touched.*

### NIS (Level Sequences)
**In-game sequence** — create a Level Sequence, drag a
**`KelGameplaySequence`** into the level and set its **Sequence Asset**.
Create a `KelGameplaySequence` SoftObjectReference, get the **Sequence
Player**, call **Play**.

**Cinematic sequence** — same, but with **`BP_CinematicSequence`**. Call
**Enter Cinematic Presentation State** then **Play**; bind an event to
**Sequence Finished** and call **Exit Cinematic Presentation State** to
return to gameplay.

### Union ship
**`BP_UnionBoss`**. Settings: **Turrets HP**, **Turret Explosion Damage**
(damage to the Union when a turret dies), **Team Attitude**, **Clan** (skin),
**Mech 1–4** (spawnable mechs), **Turrets 1–8**.

From a SoftObjectReference call **Spawn Turrets**; call **Open Doors** and
**Spawn Mechs** to deploy mechs.

### Laser fence
Triggers an alarm when hit. Place **`BP_Scannable_TripwireBeacon`** and copy
it to form the shape of the guarded area, assigning **Connected Beacons** in
order. Settings: **Enabled**, **Connected Beacons**, **Regenerate Link**
(fence stays active after triggering), **Beam Color**, **Debug Show
Connection**.

Put a **NavModifierVolume** around the guarded area with **Area Class =
`AvoidenceArea_VeryHighCost`** so other AI doesn't trigger it *(spelling as in
the source)*. Run **KelBuildMap**.

Place a **`BP_AlarmTrigger_Manager`** and assign the beacons and the
NavModifierVolume. In the MissionScript, bind an event to **On Alarm
Triggered**.

### Ammo / treasure crates
**Ammo Crate** is a **Resupply Actor** — works on placement. Settings:
**Refill Percentage**, **Uses**, **Infinite Uses**.

**Treasure Crate** is a **TreasureActor** — works on placement; a separate
actor defines its contents. Create a **`KelMetaRewards`** asset in the mission
folder to define rewards granted when the player scans it.

### AeroSpaceFighter sequences
**`BP_AeroSpaceFighterAttackSequence`** — adds flying **Shilones** or
**Jagatai**. Assign UnitCards to **Slots 1, 2 and 3**. It has a **Box
component**; size it to taste — the sequence plays when a player is inside.

**`BP_AeroSpaceFighterAttackSequence_Triggerable`** — same, but fired from the
MissionScript. Create a SoftObjectReference and call **Play Looping** from the
Sequence Player.

### Dialogue
Create an **`MWDialogueBook`** asset. Per line: **Persona** (the speaking
character), **Caption** (the line), and a **Name** used to reference it.

Create a **`KelConversationAsset`** — one per conversation. In sequence, tell
it to **Play** and set **Dialogue Line Name** to a line from the
MWDialogueBook, repeating to build the conversation.

Call **PostDialogue** in the MissionScript, choosing your `KelConversationAsset`
as the **Mission Dialogue Asset**.
