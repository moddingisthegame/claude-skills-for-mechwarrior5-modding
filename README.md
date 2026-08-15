# claude-skills-for-mechwarrior5-modding

[![Validate skills](https://github.com/moddingisthegame/claude-skills-for-mechwarrior5-modding/actions/workflows/validate-skills.yml/badge.svg)](https://github.com/moddingisthegame/claude-skills-for-mechwarrior5-modding/actions/workflows/validate-skills.yml)

A Claude plugin marketplace with skills for modding **MechWarrior 5: Mercenaries** and **MechWarrior 5: Clans**.

## Plugins

| Plugin | Skills | Covers |
|---|---|---|
| [`mw5mercs-modding`](plugins/mw5mercs-modding) | `mw5mercs-editor`, `unreal-engine-4` | MW5 Mercs Mod Editor, mission scripting, campaign integration, and the underlying Unreal Engine 4 (4.23.1) concepts |
| [`mw5clans-modding`](plugins/mw5clans-modding) | `mw5clans-editor`, `unreal-engine-5` | MW5 Clans Editor, Mod Manager, mission scripting, OmniMech setup, Wwise audio, and the underlying Unreal Engine 5 (5.5.4) concepts |

MW5 Mercs and MW5 Clans are separate games on different engines with different tooling — that's why they're split into separate plugins. Install whichever matches the game you're modding, or both.

## Install

Add this marketplace in Claude Code:

```
/plugin marketplace add moddingisthegame/claude-skills-for-mechwarrior5-modding
```

Then install one or both plugins:

```
/plugin install mw5mercs-modding@mechwarrior5-modding-marketplace
/plugin install mw5clans-modding@mechwarrior5-modding-marketplace
```

## Repo layout

```
.claude-plugin/
  marketplace.json              # marketplace catalog
.github/workflows/
  validate-skills.yml           # CI: structure checks run automatically;
                                 # eval checks are defined but commented out
                                 # (run locally instead — see EVALS.md)
scripts/
  validate_structure.py         # syntax/schema checks, no API key needed
  run_evals.py                  # runs eval_set.json locally against the CLI
plugins/
  mw5mercs-modding/
    .claude-plugin/plugin.json
    skills/
      mw5mercs-editor/
        evals/eval_set.json
      unreal-engine-4/
        evals/eval_set.json
  mw5clans-modding/
    .claude-plugin/plugin.json
    skills/
      mw5clans-editor/
        evals/eval_set.json
      unreal-engine-5/
        evals/eval_set.json
```

## Engine versions

The two games are on different engine generations, which is the root of most
cross-game confusion:

| Game | Engine | How it was verified |
|---|---|---|
| MW5 Mercenaries | **UE 4.23.1** | official Mod Editor Guide v2.3 (Wwise registration step) |
| MW5 Clans | **UE 5.5.4** | installed Clans Editor — `Engine/Build/Build.version` and `UnrealEditor.exe` FileVersion |

Each game's engine skill is scoped to its own version and explicitly excludes
the other.

## Evals

Each skill ships an `evals/eval_set.json` of trigger-rate test prompts —
queries that should and shouldn't invoke it — with negatives specifically
targeting confusion between the Mercs/Clans and UE4/UE5 sibling skills. See
[EVALS.md](EVALS.md).
