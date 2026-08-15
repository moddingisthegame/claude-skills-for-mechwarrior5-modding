# Mod Editor Guide (v2.3) — install, workflow, packaging

Source: `MW5Mercs_Mod_Editor_Guide_(v2.3).pdf` —
https://static.mw5mercs.com/docs/MW5Mercs_Mod_Editor_Guide_(v2.3).pdf

## Install
- Access via the Epic Games Store — your Epic account must **own MW5
  Mercenaries** to get the Mod Editor package in your Epic Launcher Library
  (alongside the game itself).
- Strongly recommended: install on an **SSD**, and set up version control /
  backups before serious mod work.
- On first launch, let **"Discovering Asset Data"** and **"Loading
  MechWarrior Assets"** fully complete before doing anything.
- Default level on launch is `TitleScreen`; the full title screen used in
  the shipped game is `TitleScreen_Background`.

## Core mod workflow (v2 Mod Editor)
The toolbar gains three mod-specific controls: **Create Mod**, **Manage
Mod**, **Active Mod** (selector).

1. **Create Mod** — first step for any project. Builds the folder
   structure for your mod content. Only the Mod Name is required (Author +
   Description recommended). Creates two content folders tied to your
   Active Mod:
   - **`ModOverride Content`** — modded (substitution) versions of
     existing game assets.
   - **`<ModName> Content`** — brand-new, non-substitution assets.
2. **Substitution mod** (modifying an existing asset): open the game
   asset → click **"Save To Mod"** (duplicates it into `ModOverride
   Content`, opens the duplicate, closes the original) → edit the
   duplicate (e.g. uncheck "Read from Table on Save" to edit stats
   directly instead of the source DataTable) → save. The Editor
   automatically uses your Mod version over the original when playing.
   The asset tab shows a **Mod icon**; an **"Open Game Asset"** button
   lets you reference the original.
3. **New asset mod:** right-click inside `<ModName> Content` → create the
   new asset type (e.g. a `Formation` asset under the "MW5 Misc" category)
   → configure it → reference it from wherever it needs to be used (often
   by making a substitution mod of the system that points at it, e.g.
   editing `SquadCommandComponent` under
   `\Modes\MissionDirectorSystem\MissionComponents` to point at a new
   Formation asset).
4. **Manage Mod** (packaging): click **Manage Mod** → set **Version Num**
   (start at `1.0`) and **Load Order** (leave default unless
   deliberately ordering vs. another mod — players can change it
   themselves) → **Package Mod** → choose output folder (defaults to
   `<Mod Editor>\MW5Mercs\Mods`).
5. **Install to game:** in MW5 Mercenaries, Title Screen → Mods → **Open
   Mod Folder** (creates `Mods` folder in your game install if absent) →
   copy the packaged mod folder in → **Refresh** in the Mods screen →
   check the box to enable → **Apply** → **restart the game** (required
   for mod changes to take effect).

## Porting old (v1 Editor) mods
- **Recommended:** back up your pre-cooked `.uasset` files (not PAKs, not
  cooked output) outside the project → Create Mod in the updated editor →
  drop new-asset UASSETs into `Content`, and modified-asset UASSETs into
  `ModOverride` **preserving the original folder structure** (e.g.
  `ModOverride\Objects\Weapons\Gauss\...`) → launch editor, verify → package
  normally.
- **Basic (compat-only) approach:** Create Mod as an empty container →
  package it once (to generate the folder) → drop your existing `.pak`
  file into the mod's `Paks` folder. This makes an old mod show up/toggle
  correctly in the new in-game Mods manager without a real port.
- Mods with a bare `.pak` and no v2 wrapper still work if manually placed
  in `\MWMercs\Content\Paks`, but won't appear in the in-game Mods screen.

## Load order after packaging
Edit `mod.json` (in the mod's root folder inside `\MW5Mercs\Mods\`) — the
`"loadOrder"` field is plain JSON, editable with Notepad, no editor needed.

## Custom Data Tables
As of a later patch, Weapon Data Assets can reference **any** DataTable
(not just the default one) — lets multiple weapon mods coexist without
clobbering the same shared stats table. Workflow: copy the base stats
table (e.g. `ProjectileWeaponStats` from
`Objects/Weapons/_common/Config`) into your `<ModName> Content` folder
(not ModOverride), rename it (e.g. `ProjectileWeaponStats_Mod`),
right-click → **Export as JSON** (so it doesn't just reference the
original) → make a substitution mod of the target Weapon Data Asset and
repoint its `Stats` dropdown at your new table.

## Custom Tag Containers
Each new Mod gets a `Config/Tags/<ModName>Tags.ini` under
`<Editor>/MW5Mercs/Plugins/<ModName>/Config`. Add custom Gameplay Tags
there (new 'Mechs, weapons, etc.) without touching shared source tag
assets — avoids cross-mod tag conflicts. Packaging auto-includes this
folder. Older mods can retrofit this by copying
`Content/ModTemplates/BaseTemplate/Config` into their Plugins folder and
renaming `PLUGIN_NAMETags` to match.

## Including external assets
Files invisible inside the Editor (WwiseAudio soundbank exports, tag INI
files) still get packaged automatically **if placed under**
`/Plugins/<ModName>/Config` or
`/Plugins/<ModName>/ModOverride/WwiseAudio` before packaging.

## Custom input events
Each new mod gets `Plugins/<ModName>/Config/Input/<ModName>Input.ini`.
Edit while the Editor is running — it hot-reloads new input events without
a restart.

## In-editor testing workflow
- **Test map:** `Ctrl+N` → Default level (Atmospheric Fog, Floor,
  Directional Light, Player Start, Sky Sphere, Skylight,
  SphereReflectionCapture). Scale the Floor actor's X/Y (e.g. to `500`)
  for room to work in.
- **Spawn an AI 'Mech:** drag `Objects\Spawners\SpawnPoint` into the
  level → set **Spawn On Begin Play**, **Team Id** (`0`=Ally, `1`=Enemy),
  **Spawner** → `Spawner Mech` → pick a **Mech Loadout** (defaults to
  `JM6-S_Loadout`).
- **Spawn as a 'Mech:** World Settings → **GameMode Override** → select
  `TestMode` → Play. To change which 'Mech you spawn as, open the
  `TestMode` asset (magnifying-glass icon next to the dropdown) →
  Campaign → **Starting Mechs** → pick a `MWMechLoadoutAsset`.
- **New weapon:** duplicate an existing Weapon Data Asset (e.g.
  `Objects\Weapons\AC20\Autocannon20_Lvl5` → `..._Lvl6`), move the
  duplicate into `<ModName> Content`, edit its Quirk values
  (`DamagePercentage_Quirk`, `SpeedPercentage_Quirk`,
  `CooldownPercentage_Quirk`, `RangePercentage_Quirk`,
  `HeatGeneratedPercentage_Quirk`, `CBillValuePercentage_Quirk` — all
  expressed as fractional offsets, e.g. `2.5` = +250%).
- **Modify a 'Mech Loadout:** open the target Loadout asset → **Save To
  Mod** → **Open Mod Asset** → edit **Weapon Loadout** hardpoints
  (`Weapon Id` dropdown per `Hardpoint ID`) to swap in your new weapon →
  point `TestMode`'s Starting Mechs at your modded Loadout → Play.
  **This is also how Mercs' own OmniMechs are modded** (Clan chassis added
  via the *Legend of the Kestrel Lancers* DLC) — they use the same
  `MWMechLoadoutAsset`/`Hardpoint ID` system, just with hardpoints flexible
  on weapon category ("OmniSlots"). There is no separate Omnipod-style
  workflow in Mercs; that's a MW5: Clans-only mechanic — see
  `mw5clans-editor`'s `reference/mercs-vs-clans.md` if the user is comparing
  the two.

## Audio modding via Audiokinetic Wwise
MW5 Mercs uses **Wwise** for audio. To mod sound you need a **free
non-commercial Wwise license** (Piranha cannot guarantee approval/renewal —
it's granted quarterly and must be renewed if the mod is ongoing).

1. **Register a project** at https://www.audiokinetic.com/register-project/
   — project type **Non-Commercial**; project name **must start with**
   `"MW5Mercs Modding"` plus a unique identifier (e.g. `"MW5Mercs Modding
   (YourHandle's Sound Packs)"`). Fill in Unreal Engine version `4.23.1`,
   Wwise Integration Version `2021.1.2.7629`, target platform Windows.
2. **Install Wwise** via the Wwise Launcher — must be **exactly version
   2021.1.2.7629** (matches MW5 Mercs) — Authoring package only (no SDK/
   C++), plug-ins **Wwise Convolution** and **McDSP ML1/Futzbox** only,
   install to a directory **outside** the Mod Editor's folder.
3. Point the Launcher at the Mod Editor's Unreal project
   (`<Mod Editor install>\MechWarrior5Editor\MW5Mercs`) and open its
   Wwise project via **"Open in Wwise 2021.1.2.7629"** (or directly via
   `...\MW5Mercs\WwiseProject\ghost.uproj`) — do **not** click "Integrate
   Wwise into Project" or "Open in Unreal".
4. Apply your license: Wwise → `Ctrl+L` (License Manager) → get your key
   from https://www.audiokinetic.com/customers/projects/ → Licenses →
   "Get license key" → paste into Wwise → Save.
5. Replace/add sounds under **Actor-Mixer Hierarchy** (e.g.
   `weapons > Ballistics > Gauss > Gauss_Fire`) — right-click the sound
   object → **Import Audio Files...** (`Shift+I`) → set **Create New
   Objects** mode → add your file → check its **Use** box to make the
   game use it over the original. Save the Wwise project (`Ctrl+S`); if
   you hit a "Read Only" save error, uncheck Read-only on the
   `WwiseProject` folder's Windows properties.
6. Back in the Mod Editor: **Project Settings** → search "wwise" → set
   **Wwise Windows Installation Path** to your Wwise install root.
7. Regenerate the relevant **Audiokinetic Bank** asset (in
   `Audio\Banks`): right-click → **Generate Selected Soundbank...** (a
   reported "failed" is normal/expected — it just means assets without
   your custom source audio didn't need regenerating) → then right-click
   again → **Refresh All Banks**. Verify via right-click → **Play Event**
   on the corresponding Audiokinetic Event.
8. **Before packaging an audio mod:** copy the newly-updated files from
   `\MW5Mercs\Content\WwiseAudio\Windows\` (sorted by Date Modified) into
   `\MW5Mercs\Plugins\<ModName>\ModOverride\WwiseAudio\Windows\`,
   preserving the path structure. Then package normally via Manage Mod —
   it auto-includes the WwiseAudio folder.
