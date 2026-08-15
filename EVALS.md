# Skill-triggering evals

Each skill has an `evals/eval_set.json` — 20 realistic user prompts, 10 that
should invoke the skill and 10 that shouldn't. This tests the thing that
actually determines whether a skill gets used: Claude sees only the `name` +
`description` from each skill's frontmatter when deciding what to invoke, not
the skill body. A skill with great reference content is useless if its
description doesn't win that routing decision.

## Format

```json
[
  {"query": "the user's prompt", "should_trigger": true},
  {"query": "a prompt this skill should ignore", "should_trigger": false}
]
```

This is the schema used by Anthropic's [`skill-creator`](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md),
which can run these directly:

```
python -m scripts.run_loop \
  --eval-set plugins/<plugin>/skills/<skill>/evals/eval_set.json \
  --skill-path plugins/<plugin>/skills/<skill> \
  --model <id> --max-iterations 5
```

That loop runs each query 3× (trigger decisions aren't fully deterministic),
splits 60/40 train/test, and proposes description edits when trigger rate is
low — selecting the best candidate by held-out test score, not train score.

## CI: `.github/workflows/validate-skills.yml`

Runs on every push to any branch, plus manual dispatch — you don't need to
merge to `main` to find out a `SKILL.md` has broken frontmatter. Also runs on
`pull_request`, but **only for fork-originated PRs**: `push` alone never
fires for a fork (a fork is a separate repo — pushing there can't trigger
workflows here, no way around that), so `pull_request` is the only way to
validate outside contributions before merge. The job has an `if:` that skips
a `pull_request` event for a PR from a branch *within this repo*, since
`push` already validated that exact commit — this is what keeps the workflow
from reverting to the redundant push-and-PR double-fire per commit.

In-flight runs on the same branch/PR get cancelled when a newer push
supersedes them, so iterating quickly doesn't pile up redundant runs.

**`validate`** — the only job that runs automatically. No API key needed,
always deterministic. `scripts/validate_structure.py` checks:
- `marketplace.json` and every `plugin.json` parse and cross-reference
  correctly (declared plugin sources exist, names match)
- every `SKILL.md` has YAML frontmatter with a `name` matching its directory
  and a non-empty `description`
- every relative `.md` link under `plugins/` resolves to a real file
- every `evals/eval_set.json` is well-formed and has **at least one
  `true` and one `false` case** — a skill with no eval set, or an eval set
  that's all one value, fails CI. This is what makes "every skill has evals"
  an enforced invariant rather than a one-time manual pass.

**`evals`** — defined in the workflow but **commented out**, deliberately.
It's the only part of the pipeline that spends real Claude usage (subscription
or API credits), and that's not a cost worth incurring on every single push.
Run it locally instead when it actually matters — after changing a `SKILL.md`
description, or adding/editing an eval set:

```
pip install pyyaml
CLAUDE_CODE_OAUTH_TOKEN=... python scripts/run_evals.py   # or ANTHROPIC_API_KEY=...
```

(If the `claude` CLI is already installed and logged in locally, neither env
var is strictly required — `run_evals.py` will use that session. The env var
path is what CI would need, since a runner has no interactive login.)

To turn it back into an automatic CI job: uncomment the `evals:` job and the
matching `workflow_dispatch` inputs in the workflow file, and add
`CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` as a repo secret. Everything
below describes what that job does once re-enabled.

`scripts/run_evals.py` builds one system prompt listing every skill's
`name: description` found anywhere in the repo (not just the skill under
test — the realistic worst case is a user with both plugins installed,
seeing all four at once), then for each query in each skill's `eval_set.json`
asks which skills would be invoked and checks the result against
`should_trigger`. A skill's job fails if its pass rate drops below
`EVAL_PASS_THRESHOLD` (default 80%, not 100% — trigger decisions have some
inherent noise).

It runs through the **`claude` CLI itself** (`claude -p`), not a raw call to
the Messages API — specifically so a Claude subscription can pay for these
runs. `claude setup-token` generates a `CLAUDE_CODE_OAUTH_TOKEN` (valid ~1
year, no refresh — regenerate and update the secret when it expires) that
draws from plan usage instead of per-token API billing; `ANTHROPIC_API_KEY`
also works if that's what's configured. Each call passes `--safe-mode`
(isolates the session from this repo's/the runner's own CLAUDE.md, skills,
plugins, hooks — deliberately *not* `--bare`, which is the CLI's generally-
recommended flag for scripted calls but explicitly never reads OAuth
credentials, which would defeat the purpose here), `--tools ""` (no tool
access needed for a classification question), and `--json-schema` constraining
the response to `{"skills": [...]}` with an enum of real skill names, so
parsing doesn't depend on the model reliably following a "reply with only
JSON" instruction in prose.

If re-enabled without a `CLAUDE_CODE_OAUTH_TOKEN`/`ANTHROPIC_API_KEY` secret
configured, `run_evals.py` prints a notice and exits 0 rather than failing —
the job stays green rather than blocking contributors (or fork PRs, which
can't see repo secrets anyway, and are excluded from this job regardless — see
below) who don't have access. If a credential *is* set but invalid or expired,
the script runs a fast `claude auth status` preflight check and fails
immediately with a clear message instead of silently retrying all ~90 queries
for no reason. It also never runs on **any** `pull_request` event, fork or
not — a same-repo PR's commits are already covered by `push`, and a fork PR
could never do anything there but hit the no-credential skip anyway, since
GitHub deliberately withholds repo secrets from fork-authored workflow runs
(so a malicious PR can't edit `scripts/run_evals.py` or the workflow file to
exfiltrate the credential, or just spend your subscription budget). There's a
`pull_request_target` event that *does* expose secrets to fork-triggered
runs, but combining it with checking out and executing the fork's own code is
one of the most common real-world GitHub Actions supply-chain
vulnerabilities — not used here, and shouldn't be without a specific,
carefully-scoped reason.

Configurable via env vars / `workflow_dispatch` inputs:

| Var | Default | Meaning |
|---|---|---|
| `EVAL_MODEL` | `haiku` | model used to make the trigger decision — the CLI resolves this alias to whatever the latest Haiku is (currently `claude-haiku-4-5-20251001`), so it stays current without a pinned version needing a manual bump. Pass a full model id instead if you need to pin one, e.g. for reproducing a specific past run |
| `EVAL_RUNS` | `1` | times to repeat each query (majority vote); set higher (e.g. 3, matching `skill-creator`'s convention) for a noisier but more reliable signal |
| `EVAL_PASS_THRESHOLD` | `0.8` | per-skill minimum pass rate to succeed |

## Why the negative cases look the way they do

This marketplace's actual failure mode isn't "does the skill trigger for an
obviously-relevant prompt" — it's **cross-triggering between confusable
siblings**:

- **`mw5clans-editor` vs. `mw5mercs-editor`** — same publisher, same
  "MW5" branding, same modding vocabulary (mods, mission scripting, campaign
  arcs), different games. Each skill's negative set includes several prompts
  phrased in the *other* game's terms, sometimes using the sibling's own
  class/asset names (`BP_KelMissionScript_Base`, `AreaSpec`) as a stress test.
- **`unreal-engine-4` vs. `unreal-engine-5`** — same engine vendor, heavily
  overlapping vocabulary (Blueprints, Data Assets, NavMesh), scoped to
  different MW5 games. Cross-engine terms (Lumen/Nanite/World Partition vs.
  Foliage/Landscape-layers/sublevels) are the discriminator.
- **Engine skill vs. its own companion editor skill** — e.g. a generic
  "how does UE4 Gameplay Tags config work" question should route to
  `unreal-engine-4`, not `mw5mercs-editor`, even though both skills know about
  Gameplay Tags. Each engine skill's negatives include a couple of its own
  companion editor skill's workflow questions, and vice versa.
- **Generic, out-of-scope prompts** — plain non-MW5 programming questions
  (Node.js, Python, React) and generic "I want to use UE5 for my own game"
  prompts, to catch a description that's written broadly enough to fire on
  anything Unreal-flavored.

If a description edit ever makes one of these negatives start triggering,
that's a regression, not noise.

## The genuinely ambiguous cases

The categories above are all *resolvable* — the query contains a signal
(a class name, an engine feature, a game title) that a sufficiently precise
description can key off. Two categories don't have that:

**1. Bare "MechWarrior 5" with no game specified.** *"How do I get started
modding Mechwarrior 5?"* / *"How do I add a new weapon to MechWarrior 5?"* /
*"What engine does MechWarrior 5 use?"* contain no signal at all — Mercs and
Clans are equally plausible readings. There is no description text that can
correctly route this to one skill, because the correct answer depends on
information only the user has.

The fix applied here isn't a better description keyword — it's an explicit
instruction *in every skill's description* (the two editor skills and the two
engine skills) telling Claude to **ask which game before proceeding** rather
than picking one. This has to live in the description, not the skill body,
because the body is only read *after* a skill is invoked — by then the wrong
skill may already have been silently picked. All four eval sets mark these
queries `"should_trigger": false` on the theory that the ideal first move is
a clarifying question, not a silent invoke.

Treat that boolean as a soft signal, not a hard pass/fail: an agent that
briefly invokes one skill to phrase a *better* clarifying question (e.g. "did
you mean the Mod Manager in the Clans Editor, or the Mercs Mod Editor?") is
arguably fine too. What's actually being tested is whether the *description*
carries enough signal to keep Claude from confidently answering as if only
one game exists — watch the model's actual response in these cases, not just
whether a skill fired.

**2. Same-named mechanic, different games.** MW5 Mercenaries added its own
OmniMechs via the *Legend of the Kestrel Lancers* DLC — Clan chassis with
flexible **OmniSlot** hardpoints, but *not* Clans' swappable **Omnipod**
system. "OmniMech" and "Omnipod" sound interchangeable but aren't, and only
one of them is a reliable Clans signal. This is exactly the trap a naive
keyword-matched description falls into: a description that treats "OmniMech"
as Clans-exclusive vocabulary will misroute *"How do I mod a Timber Wolf
OmniMech's loadout in MW5 Mercenaries?"* to `mw5clans-editor`.

Unlike the bare-"MechWarrior 5" case, this one **is** cleanly resolvable —
the query names the game explicitly, it's just that "OmniMech" is a
false-friend keyword. Both editor eval sets mark this query with a hard
boolean (`true` for `mw5mercs-editor`, `false` for `mw5clans-editor`), and
both skills' descriptions and reference content (`mercs-vs-clans.md`,
`mod-editor-guide.md`) now spell out the OmniSlot/Omnipod distinction so an
invoked skill also *answers* correctly, not just triggers correctly.
