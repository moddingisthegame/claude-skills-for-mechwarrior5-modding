---
name: mw5clans-editor
description: "Reference for MechWarrior 5 Clans modding resources — the MW5 Clans Editor (Mod Manager, Basic Mod template, ModOverride, Package/Export/Steam Workshop publish), Wwise audio setup, and the full Mod Mission Setup guide (BP_KelMissionScript_Base, objectives, AI spawning and waypoints, turrets, artillery, OOB volumes, level sequences, dialogue), with official video tutorials linked at point of use, and a Mercs-to-Clans differences guide. Use when the user asks about modding MechWarrior 5 Clans, the Clans Editor, Kel* assets, Clans mission scripting, or Clans-style Omnipod/OmniMech Loadout modding. Do NOT use for MechWarrior 5: Mercenaries — that is a separate game on a different engine with different tooling; use the mw5mercs-editor skill instead. Note: MW5 Mercenaries also has its own OmniMechs (DLC-added) but NOT Omnipods — a bare 'OmniMech' question is not automatically a Clans question, confirm the game. If the user says only 'MechWarrior 5' or 'MW5' without naming Mercs or Clans, that's ambiguous — ask which game before proceeding rather than assuming."
---

# MechWarrior 5: Clans — Official Modding Resources

Reference skill indexing the official Clans modding resources page and the
full text of both PDFs it links. Detailed content lives in `reference/` and is
**read on demand** — load only what the question needs. The six official
video tutorials are linked inline in the reference files at the section they
cover — see the table below.

**Game scope:** **MechWarrior 5: Clans** only. MechWarrior 5: Mercenaries is a
separate game with its own tooling — use the **`mw5mercs-editor`**
skill for it. The two are frequently confused; confirm which game the user
means before answering if it is at all ambiguous.

> ## Engine warning
> Clans runs on **UE 5.5.4**. Mercs runs on **UE 4.23.1**.
> The **`unreal-engine-4`** skill explicitly excludes UE5 and **must not be
> applied to Clans work** — landscape, lighting, and level composition all
> differ, and the Clans mission guide uses **Level Instances**, which have no
> UE4 equivalent. For the engine layer beneath Clans, use the companion
> **`unreal-engine-5`** skill in this same plugin.

**Companion skill:** MW5 Clans is built on **Unreal Engine 5.5.4**. For the
engine concepts underneath this workflow — Level Instances and Packed Level
Actors, World Partition and One File Per Actor, Lumen/Nanite/Virtual Shadow
Maps, Enhanced Input, Blueprints and soft references, Gameplay Tags, Data
Assets and the Asset Manager, plugins and redirectors — use the
**`unreal-engine-5`** skill. It includes a Clans-concept→UE5-feature mapping
and, importantly, a verified list of which UE5 features this project actually
enables (PCG, CommonUI, GameplayAbilities, StateTree, MassEntity and Water are
all **off**).

## Reference files — read only what you need

| File | Read this when the question is about... |
|---|---|
| [reference/getting-started.md](reference/getting-started.md) | installing the Editor, creating a mod, the Basic Mod template, creating/overriding/removing assets, Wwise audio, packaging, exporting, publishing to Steam Workshop |
| [reference/mission-setup.md](reference/mission-setup.md) | building a mission: levels and sublevels, the Holotable, objectives (waypoint/destroy/scan/destructible-zone/timer), AI spawning, waypoints, jump jets, custom UnitCards, turrets, artillery, OOB volumes, sequences, dialogue |
| [reference/omnimech-setup.md](reference/omnimech-setup.md) | creating a new OmniMech variant — Mech Part Config, hardpoints, Omnipods/Omnipod Bundle, Loadout, tonnage/heat-sink quirks. Synthesized from video 6, the only official source |
| [reference/mercs-vs-clans.md](reference/mercs-vs-clans.md) | a user coming from MW5 Mercs — what transfers, what changed, what traps to avoid |

Typical combinations: a new mission needs `mission-setup.md` alone for most
questions, plus `getting-started.md` for packaging and distribution. A Mercs
veteran should get `mercs-vs-clans.md` early — several Mercs habits actively
mislead in Clans.

## The pattern that covers most of Clans mission scripting

Almost every mission feature works the same way:

1. Place the actor in the level, configure it in Details.
2. Create a **SoftObjectReference** variable of that type in the
   **`BP_KelMissionScript_Base`** subclass.
3. Assign the placed actor to that variable, then call nodes from it in the
   Event Graph.

Exceptions (Components rather than variables, Sets rather than single
references) are called out in `mission-setup.md`.

## Official source documents (real URLs)

| Document | URL |
|---|---|
| Modding resources landing page | https://mw5clans.com/resources/modding |
| Getting Started With Modding (PDF, 13 pp) | https://mw5clans.com/downloads/MW5Clans-Getting-Started-With-Modding.pdf |
| Mod Mission Setup, KEL v1 (PDF, 69 pp) | https://mw5clans.com/downloads/KEL-Mod-Mission-Setup-v1.pdf |
| MW5 Clans Editor | Epic Games Store |
| Wwise (optional, audio) | https://www.audiokinetic.com/en/profile/school/6808/ |
| .NET 8.0 SDK (required) | https://dotnet.microsoft.com/en-us/download/dotnet/8.0 |
| Official YouTube channel | https://www.youtube.com/channel/UCtxZZEEuHtOzD7xKVZQvqjw |
| EULA | https://mw5clans.com/eula |
