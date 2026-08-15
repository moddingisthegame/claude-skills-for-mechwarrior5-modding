# OmniMech Setup — MW5: Clans

Source: official video tutorial *"06 OmniMech Set up"* (32:22) —
https://www.youtube.com/watch?v=JDYJamXJhPc. Auto-generated captions were
downloaded and paraphrased into this document; nothing here is a verbatim
transcript. No PDF covers this topic — the string "omni" appears zero times
in either official PDF, so the video is the only official source and this
file is a paraphrase of it, not an independently-verified reference. Treat
exact field labels as reliable (the presenter is on screen showing the
Editor UI) but treat exact default *values* with caution where noted.

**This covers OmniMech variants only** (e.g. a new Stormcrow variant). The
presenter states Battlemechs (non-Omni) follow a **different, separate**
process "more similar to Mercs" and were not covered in this video.

## This does not follow the mission-scripting pattern

Unlike almost everything in `mission-setup.md`, OmniMech setup is **pure
data-asset configuration** — there is no placed actor, no
`BP_KelMissionScript_Base` variable, and no Event Graph wiring. It's closer
in spirit to Mercs' Mech Data Asset (MDA) workflow than to Clans' usual
place-actor → SoftObjectReference → Event Graph pattern.

## Folder layout

No fixed directory is required — confirmed: the Trials of War DLC's
Stormcrow Hero variant ("Lacerator") lives in a completely different folder
tree than the base Stormcrow, and the game accepts it fine. The presenter's
example project uses (as a convention only): `MechPartConfig/`,
`Omnipods/`, `Loadouts/`, `UnitCards/`, one subfolder per mech.

## MDA (Mech Data Asset)

Only **one MDA per chassis**, shared by every variant — unlike Mercs, where
each variant/tag typically gets its own. (The full expansion "Mech Data
Asset" is inferred from context and the presenter's direct comparison to
Mercs; not confirmed against a written Clans source.)

The only OmniMech-specific requirement on the MDA: check **"Can Equip
Omnipods"**. Nothing else about it changes for Omni variants.

## Mech Part Config (per body location)

One asset per location: Head, CT, Left/Right Arm, Left/Right Torso,
Left/Right Leg. Recommended workflow: **copy an existing variant's Mech
Part Config set and rename it**, rather than building from scratch — the
presenter calls custom mech part files "very finicky and very error-prone."

**Gotcha:** Unreal will let you multi-select several copied Mech Part
Config files and edit them as a batch, but they are **not** safe to
batch-edit — each is per-location and per-variant. Open and edit every file
individually.

**Plan the full loadout externally first** (MechDB, MegaMek, MechFactory,
or similar) before touching the Editor, so every slot's contents are known
ahead of time.

### What belongs in the Mech Part Config vs. the Loadout

The Mech Part Config holds only what's **locked to the mech and not meant
to be adjusted by the player**: engine, gyro, fixed/internal slots, and the
upper arm / lower arm / hand actuators. Weapons, ammo, and heat sinks are
**never** placed here — those go in the Loadout asset (see below).

Clan OmniMech engines are **slot-locked** by default (e.g. Clan XL 330) —
confirmed: Clan OmniMechs cannot swap their engine, so this is normally
left untouched.

### Hardpoints

Each weapon slot on a Mech Part Config location has three things to set:
**Slot Type** (e.g. Energy, Missile, General Equipment), a **slot count**
(1, 2, 3…), and a **Hardpoint ID** (e.g. `Forearm Left EH1`) pulled from
that mech's Hardpoint file, which enumerates every hardpoint by location —
a hardpoint tagged for the left arm only appears on left-arm Mech Part
Config files. "Blank" hardpoint entries are pure geometry with no gameplay
function.

**Gotcha — always hit Save immediately after resizing a slot**, before
making further edits. Resizing (e.g. 1 slot → 3 slots) doesn't retroactively
clear the slots it now overlaps until you save; edit further before saving
and the leftover slots can end up in an inconsistent state.

Two ways to give a location multiple weapon slots of the same type:
- **Separate single-slot hardpoints** (e.g. `EH1`, `EH2` as two independent
  1-slot Energy entries) — simplest, but restricts that space to two
  single-slot weapons; a 2-slot weapon (Large Pulse Laser, ERPPC) won't fit.
- **One combined multi-slot hardpoint** carrying both hardpoint IDs (resize
  the slot to N, then add both IDs to it) — lets the player fit either
  multiple small weapons *or* one larger one in the same space. Confirmed
  design use: the Nova intentionally uses six separate single-slot energy
  hardpoints (no combining) specifically to cap what it can mount, since
  it's already a powerful chassis.

**Melee hardpoints — the single most emphasized gotcha in the video:**
"Getting the melee hardpoints wrong is the most common cause of mechs
breaking." Confirmed requirements:
- The slot's **Hardpoint ID** must be the melee-specific one for that exact
  limb/side (the presenter audibly second-guesses the exact ID on screen
  before landing on the correct one — treat exact ID spelling per-mech as
  something to verify against that mech's own Hardpoint file, not memorized).
- The **slot type** must match the equipment's melee category exactly:
  weight class (Light/Medium/Heavy/Assault) *and* location type (Hand vs.
  Lower Arm). A mismatch (e.g. a Medium melee weapon in a slot typed for a
  different weight class) makes the whole mech **invalid** in-game with no
  obvious error pointing at the cause — this is presented as a real,
  time-costly trap.
- A hand-actuator melee weapon and a lower-arm-actuator melee weapon are
  mutually exclusive per arm: switching to a lower-arm melee weapon means
  deleting the (now redundant) locked hand/lower-arm-actuator internal
  slot entries and adding the lower-arm melee hardpoint in their place.

### Locked/internal slots

Shoulder, upper arm, lower arm, and hand actuators are internal equipment
slots (e.g. "Clan Equipment Shoulder Slot"), locked by default since
players can't remove or change them. Hand and lower-arm actuators are
called out as "where things tend to break" — see melee hardpoints above.

### Per-slot flags

| Flag | Effect |
|---|---|
| **Default Equipment** | Pre-fills the slot with a specific item (e.g. `ER Large`) |
| **Slot Locked** | Player cannot unequip the item (padlock icon shown in mech lab) |
| **Immune to Damage** | Item cannot be crit'd out |
| **Disallow Empty Slot** | Player can swap the item but can't leave the slot empty — used on engines so a mech can never end up with no engine installed |

## Omnipods

Two separate asset types:

1. **Omnipod assets** — one per body location per variant. Create by
   copying an existing variant's Omnipod files and batch-renaming.
2. **Omnipod Bundle** — one per variant, references all of that variant's
   Omnipod assets. Fields: **Display Order** (position in the mech lab's
   pod list — pick the next free number after existing/DLC entries),
   **XP unlock cost**, **Always Unlocked** (available as soon as the base
   chassis is unlocked — used for Prime variants), **Disable** (exists in
   game data but hidden from the normal player-facing unlock list — used
   for one-off loadouts like a unique boss mech that shouldn't be
   player-obtainable).

Each per-location Omnipod asset has an **Aggregate Stats** fragment where
quirks (extra ammo, heat sinks, armor, etc.) can be added. The presenter
states Piranha's own design stance is to avoid quirks and balance mechs by
other means, but the field is available.

After creating all per-location Omnipod assets, multi-select them and use
**bulk edit** to assign them all to the new Omnipod Bundle in one action.

**Gotcha:** newly-created Omnipods sometimes don't appear in dropdown
pickers elsewhere (e.g. when assigning them in a Loadout) because "Unreal
Engine has not indexed them yet." Fix: save everything and restart the
Editor. The presenter estimates this is needed roughly 70% of the time —
treat that percentage as an offhand estimate, not a measured figure.

## Loadout (one per variant)

- Sets the **default skin** (any skin in the game) and **default colors**
  (unset = falls back to the skin's own default colors).
- Sets **health** values (presenter didn't detail these — "pretty
  self-explanatory").
- **Must select the Omnipod Bundle before per-location Omnipod fields
  become assignable.** Each location's Omnipod dropdown must match that
  location (left torso Omnipod → left torso slot, etc).
- Once Omnipods are assigned and saved, the weapon-hardpoint grid (matching
  the Mech Part Config's hardpoint layout) becomes editable — this is
  where actual weapons/ammo/heat sinks get placed. Melee weapons set as
  Default Equipment in the Mech Part Config do **not** need to be re-added
  here.
- **Gotcha:** equipment items occupy a specific number of slots (shown on
  the item itself — e.g. Clan LRM 15 = 2 slots). Overlapping two multi-slot
  items, or trying to place two separate weapons into what is really one
  single hardpoint, both cause **mech lab errors**. The hardpoint index
  display shows how many contiguous slots a given hardpoint spans.
- Naming gotcha: what's commonly called an "Active Probe" is actually
  named **"Clan Beagle Active Probe"** in the equipment picker.
- **Additional Engine Heat Sinks** on the Loadout is a **Battlemech-only**
  field (0–6, how many heat sinks sit inside the engine) — for OmniMechs
  this is always 0. An OmniMech's fixed engine heat sinks are configured
  instead back in the Mech Part Config's **Center Torso** part, under
  **Engine Slot Size** and a **"Provides Fixed Engine Heat Sinks"**
  checkbox + count. Confirmed example: the Stormcrow's 330 XL engine has
  zero fixed heat sinks despite the large engine size, so that checkbox
  stays unchecked.
- Live **tonnage display** in the Loadout editor, so you don't need the
  in-game mech lab to check overweight status. Confirmed behavior: Clans
  rounds tonnage **up to the next quarter-ton** (the presenter first says
  "half-ton" on screen, then corrects/demonstrates quarter-ton in practice
  — treat quarter-ton as the confirmed figure).

## Unit Cards

**Not required for a player-selectable OmniMech loadout** — this is a
divergence from Mercs, which the presenter calls out explicitly ("the unit
card is not like Mercs"). Unit Cards are only needed to spawn **NPC** mechs
in a level (see `mission-setup.md` → *Spawning AI*). To let an NPC use a
new variant, duplicate a Unit Card and point its loadout reference at the
new Loadout asset.

## Build order and a real on-camera mistake

Confirmed order: **Mech Part Config (all locations) → Omnipod assets (all
locations) → Omnipod Bundle (assign the omnipods + set Display
Order/unlock/flags) → Loadout (select the bundle, assign per-location
Omnipods, then equip weapons)**.

The presenter demonstrates forgetting a step live: testing in the mech lab
showed the new variant not appearing correctly because the Loadout hadn't
been pointed at the Omnipod Bundle, and the Omnipods hadn't been added to
the bundle. Fixing both (assigning the bundle to the Loadout, and the
Omnipods to the bundle) resolved it — a concrete illustration of why the
order above matters.

## Not covered / uncertain

- Exact spelling of in-game debug-console commands used to instantly grant
  currency/XP for testing — mumbled in captions, not reproduced here.
- The full Battlemech (non-Omni) creation process — presenter says it's
  covered in a separate, not-yet-released video.
- Custom mech part file creation from scratch (rather than copying an
  existing variant) — presenter explicitly defers this to a future video.
