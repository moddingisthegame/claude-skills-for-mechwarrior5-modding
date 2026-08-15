# Getting Started With Modding — MW5: Clans Editor

Source: `MW5Clans-Getting-Started-With-Modding.pdf` (13 pp) —
https://mw5clans.com/downloads/MW5Clans-Getting-Started-With-Modding.pdf

Video companion: official tutorial **"01 Mod Set up"** (1:53) —
https://www.youtube.com/watch?v=sq6rCDrJG68. Its auto-generated captions
confirm this document matches the video exactly — at under two minutes it's a
quick visual confirmation, worth pointing a user to only if they want to see
the Mod Manager UI in motion rather than read the steps.

## Setup

Download the Editor from the **Epic Games Store**.

Additional requirements listed on the resources page:
- **.NET 8.0 SDK** — https://dotnet.microsoft.com/en-us/download/dotnet/8.0
- **Wwise** (optional, audio only) — see Audio below

## Create your first mod

1. Launch the Editor.
2. **Mod Manager** from the main toolbar.
3. **New Mod**.
4. Select the **"Basic Mod"** template. *(If **Create Mod** is greyed out,
   the template isn't selected — this is the usual cause.)*
5. Enter a **Mod Name**. Keep **"Show Content Directory"** checked so the
   Content Browser navigates to the new mod.
6. Optionally add author, description, author URL.
7. Click **Create Mod**. The Editor prompts to restart.

Result: a Content folder under `Plugins/<ModName>`.

## Create a new asset

All mod assets must live in the mod's plugin folder, e.g.
`/Plugins/TutorialMod`. Group them into subfolders by theme or feature.

Standard Unreal asset creation applies. The guide's worked example:

1. Right-click in the mod's Content folder.
2. **Miscellaneous → DataAsset**.
3. Choose **`KelDifficultySettingAsset`** as the type.
4. Name it (e.g. `MyNewDifficulty`).
5. Fill in: **Display Name**, **Description**, **Valid Campaigns**
   (`CoreGame_Attributes`).
6. Play in-editor — the new difficulty appears.

## Override a base game asset

**The override does not take effect until the Editor is restarted.** You can
keep adding assets/overrides and restart once at the end.

1. Find the asset in the Content Browser.
2. Right-click → **"Save To Mod"** → choose the mod.
3. Accept the restart prompt.
4. Overridden assets land under a special **`ModOverride`** folder inside the
   mod, mirroring the original path — e.g.
   `/Plugins/TutorialMod/ModOverride/Game/KelUI/Frontend/TitleScreen/_common`.

Worked example from the guide: override `KelTitleScreenButton`, select the
`ButtonTextBlock` widget in Designer mode, change **Appearance → Color and
Opacity** (e.g. Violet `#D34DD2`), compile and save. Menu items show the new
colour in their un-highlighted state.

### Removing an override

1. Navigate to the **base game** asset.
2. Right-click → **"Delete from Mod"**.
3. Optionally reboot the Editor to remove it completely.

## Audio (Wwise)

1. Install Wwise from Audiokinetic. The compatible version is listed under
   **MW5Clans - MechWarrior 5: Clans Modding** in the courses section —
   **2024.1.1.8691** at the time the guide was written.
   Use the default plugin list, then add **"Motion"** and **"AK Convolution"**.
2. Open `MW5CEarlyEditor\Editor\MW5Clans\WwiseProjectKelpie\kelpie\kelpie.wproj`
   in Wwise.
3. Create a sound event: **Project → Import Audio Files**;
   **Events → New Child → Work Unit**; **Work Unit → New Child → Play**.
4. Note the event's **Short ID** (right-click → Copy Text).
5. **Layouts → SoundBank** (or `F7`).
6. Optionally create a soundbank named after your mod and add your event to
   it. **If you skip this, a soundbank is auto-generated for your event and
   the name may conflict with other mods.**
7. Check **Windows** for Platforms and **English(US)** for Languages, then
   **Generate Checked**. Errors that aren't about your event can be ignored.
   The first generation takes much longer than later ones.
8. Back in the Unreal Editor, create an **Audiokinetic Event** asset in your
   mod folder.
9. Enter the **Wwise Short Id** — the rest auto-fills.
10. Verify: right-click the Audiokinetic Event → **"Play Event"**. Silence
    means the soundbank wasn't created or the Short ID is wrong.
11. To play it in logic, use a **Post Event** node.
    Hint: enable **"Show Plugin Content"** in the Content Browser's search
    settings or you won't see the asset.

## Packaging, exporting, publishing

All three start the same way, and all three require the same precondition:

> **Restart the Editor first** so all mod assets and overrides are correct
> before packing.

**Package** — Mod Manager → **Edit** the mod → update details → **Package**.
Cooks the mod's assets and packages them into Pak files.

**Export** — Mod Manager → **Edit** → ensure it is packaged (the **Export**
button is otherwise unavailable) → **Export** → choose a folder. Then follow
the manual mod installation guide.

**Publish (Steam Workshop)** — Mod Manager → **Edit** → update details →
confirm it is packaged → set the desired **Steam visibility** → ensure the
Steam client is running, logged in, with MW5: Clans in the library → accept
the Steam Workshop Terms of Service once via **View** → **Publish**. Verify
with **"View on Steam Workshop"**.
