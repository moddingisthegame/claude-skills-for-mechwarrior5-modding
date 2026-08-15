# Adding Custom Missions to Campaign

Source: `MW5 Mission Campaign Integration Guide.pdf` ("Adding Custom
Missions to Campaign") —
https://mw5mercs.com/static/docs/MW5%20Mission%20Campaign%20Integration%20Guide.pdf

Walks through placing a custom mission onto a specific starmap location
inside the base MW5 Mercs campaign; the same technique scales up to full
custom mission arcs/campaigns. Assumes you already have a mission
**Scenario** to place — see
[mission-creation-guide.md](mission-creation-guide.md).

## Terms
- **Campaign Arc** — a "quest": bundles trigger conditions + the actions
  they fire.
- **Metagame Objective** — the "incoming transmission" (quest giver):
  holds display text and reward data, tracks progress.
- **Campaign Arc Action** — a single scripted event within a quest (offer
  it, place a mission, mark it complete, reset it, etc.) — implemented as
  Blueprint classes derived from specific `MWCampaignArcAction` subtypes.
- **Metagame Objective Header** — a category tag so the quest sorts/
  tracks correctly in the in-game Mission Log.

## Build sequence
1. **Campaign Arc** asset (MW5 Misc → `CampaignArc`) — the quest
   container.
2. **Metagame Objective** asset (MW5 Misc → `MetagameObjective`) — the
   quest-giver transmission.
3. **Four Campaign Arc Action Blueprints** (right-click → Blueprint Class,
   parent class picked via search):
   - Parent `PlaceMission_ArcAction` → e.g. `PlaceQuest_ArcAction`
     (places the mission on the starmap).
   - Parent `ObjectiveState_ArcAction` (specifically its
     `SetObjectiveState_ArcAction` subtype) → e.g.
     `OfferQuest_ArcAction` (sends the transmission / offers the quest).
   - Duplicate that one → `CompleteQuest_ArcAction` (marks the objective
     complete).
   - Parent `ResetScenario_ArcAction` → `ResetMission_ArcAction`
     (re-places the mission if the player fails it).
4. **Metagame Objective Header** asset (MW5 Misc →
   `MetagameObjectiveHeader`) — set its **Header Text** to the quest's
   log category name.

## Fill out the Metagame Objective
Key fields: **Employer** (metagame faction data, largely cosmetic),
**Screen Title/Sub Text** (shown in the transmission popup), **Prompt
Title/Sub Text** (shown in the starmap UI — can be a shorter version),
**Objective Briefing** (the transmission's body/flavor text), **Has
Rewards** (toggle) → **Objective Reward** (CBills, Reputation, and
item/pilot/'Mech rewards — for a 'Mech reward, expand **Mech Data
Asset**, generate a fresh **Item Id** GUID via the field's dropdown →
Generate), **Reward Briefing** (completion text), **Header** (point at
the Metagame Objective Header you made), **Only Show Currency Rewards**
(hides non-currency reward details as "?" until claimed).

- **Employer Agent → Persona Data:** either fill in a new character (Full
  Name + Portrait Asset Id) or select a pre-existing `MWPersonaAsset`
  (e.g. `Spears` = Sebastian Spears) from the **Persona Asset Id**
  dropdown.

## Fill out each Arc Action
- **OfferQuest_ArcAction:** `Objective` = your Metagame Objective;
  `Operation` = `Offer`.
- **PlaceQuest_ArcAction:** `Objective` = your Metagame Objective;
  `StarSystemId` = the numeric system ID (look it up in
  `Content/InnerSphereData/MW5_InnerSphereData` by system name, e.g.
  "Brundage" = `2065`); `Scenario` = the mission Scenario asset to place
  (can be an existing base-campaign mission or your own custom one).
- **CompleteQuest_ArcAction:** `Objective` = your Metagame Objective;
  `Operation` = `Complete`.
- **ResetMission_ArcAction:** `Scenario` = the same Scenario used in
  Place, so a failed mission re-appears on the map.

## Wire up the Campaign Arc's event graph
Open your `CampaignArc` asset → **Events → Campaign Event List** — one
entry per triggerable event, each with:
- **Trigger Conditions** — checkable thresholds (Reputation Level/Value,
  Date, Net Worth, CBills, Territory, DLC-enabled) plus **Event/
  Scenario/Objective/Faction Standing/Data Cache/Custom Triggers** you
  add explicitly.
- **Trigger Type** — `Immediate` (fires once, resolves immediately once
  met), `One Off` (fires once, resolves once any condition goes false),
  `Always` (can re-fire repeatedly as conditions toggle true/false).
- **Campaign Actions** — the Arc Action(s) this event invokes.

Build four events:
1. **"OfferQuest"** — `Trigger Type = Immediate`, condition e.g.
   `ReputationLevel >= 0` (fires for everyone right away) → Campaign
   Action: `OfferQuest_ArcAction`.
2. **"Place Quest"** — `Trigger Type = Always`, an **Objective Trigger**
   on your Metagame Objective set to **`In Play`** (accepted and
   running) → Campaign Action: `PlaceQuest_ArcAction`. (Other Objective
   Trigger states: `Offered`, `Active`, `Complete` — each invertible via
   a checkbox, enabling branching arcs gated on prior objectives.)
3. **"MissionSucceeded"** — a **Scenario Trigger** on your mission
   Scenario set to `Succeeded` → Campaign Action:
   `CompleteQuest_ArcAction`.
4. **"MissionFailed"** — a **Scenario Trigger** set to `Failed` →
   Campaign Action: `ResetMission_ArcAction`.

## Insert into the game
Open `Content/Campaign/CampaignArcs/MW5CoreCampaign` — the master
campaign arc, composed of `Sub Campaigns` (e.g.
`AllStarMapBorderChanges`, `CoreClusterArcs`, `Overdraft_Arc`,
`AddDefaultCodexEntries_Arc`, `HidingSystemsArc`, `ReputationArc`).
**Don't remove/reorder existing entries** — just add your new
`CustomMission_Arc` as one more entry in the `Sub Campaigns` set (order
doesn't matter; all trigger logic lives inside your own Arc).

## Test
Start or load a base-campaign save — the quest transmission should
appear per your trigger conditions, with the Accept button and reward
list populated from what you configured.
