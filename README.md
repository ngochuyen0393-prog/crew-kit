# crew-kit

Run a **captain-crew discipline** (one controller agent, many worker "lanes", merge trains) on a **plain local repository** — no GitHub remote, no PR, no CI needed.

This is the machinery layer for [gstack](https://github.com/garrytan/gstack)'s [`/captain` skill](https://github.com/garrytan/gstack/blob/main/docs/captain.md). The discipline itself (READY contract, merge trains, flaky rerun rule, one-path-through-controller) is gstack's; this kit adapts it for repositories with **no remote**, where the official PR-based machinery (`gstack-ship-queue`, `gh pr merge`) has nothing to attach to.

Works with any host that can launch worker agents in isolated checkouts — we run it with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) lanes on [Orca](https://github.com/stablyai/orca) worktrees.

## The problem

`docs/captain.md` says the controller can be *"a Capy Captain, **or any controller agent**"*, and `docs/recommended-harness.md` classifies the ship-queue machinery as harness-generic. But the generic path still assumes a GitHub remote: lanes ship PRs, trains are PR-ordered. On a local-only repo, the READY contract has nothing to attach to.

## The adaptation

**READY block** — keyed by *branch + full head SHA + tree hash + named check lines*, ending with a frozen-head declaration:

```text
READY feature/mb-incread 3f9c1a7b2e8d4f6a9b0c1d2e3f4a5b6c7d8e9f0a
pin: 3f9c1a7b2e8d4f6a9b0c1d2e3f4a5b6c7d8e9f0a
base: master@dc21e54a9b01
tree: 8c2f…
checks: pytest-pure=green shell-test=green
flaky: none
Head frozen from now on; a push drops this READY and I will READY again.
```

**Mechanical validator** (`bin/validate-ready.sh`) — re-derives every fact from git itself, trusts no prose:

- branch tip ≠ stated SHA → reject ("did you push after freezing?")
- tree hash mismatch → reject (a lying SHA maps to the wrong code)
- BASE drift → reject (re-READY on latest BASE first)
- missing/non-green check → reject; flaky case not in the ledger → reject

It reads only three parameters — `REPO_PATH`, `BASE`, `CHECK_NAMES` — from the crew's `CREW.md`, so the same script serves every project.

**Local merge trains** — scratch worktree from BASE → slots merged `--no-ff` in order → one full gate on the train head → slots landed into BASE one by one → red means bisect by rebuilding without the suspect slot, at most once.

**Dropped on purpose**: stamp/slot-call version stamping (no version discipline in target repos — YAGNI), wave PRs.

**Kept 1:1 from the official templates**: CREW.md contract, DIGEST/NOTES, `reports/`, flaky ledger, brief/READY/report templates — so a crew graduates to the PR-based flow the day a remote appears.

## Design invariant

> **Generic globally, parameters locally.** This repo ships placeholder templates only. Every project instantiates its own *crew drive* (`<project>-crew/`) with a filled `CREW.md`; per-project facts (repo path, base branch, check commands, ports) live nowhere else.

## Bootstrap a project

Point your coding agent at [`bootstrap.md`](bootstrap.md) and say "bootstrap a crew for this project" — it asks four questions (repo path, base branch, required checks, exclusive resources), instantiates the drive, wires the lane rules into the repo's `AGENTS.md` (auto-loaded by every lane session), and **requires a live validator test** (one valid READY + forged rejections) before it counts as done.

## Layout

| Path | What |
|---|---|
| `SKILL.md` | agent-facing entry (role routing, invariants) |
| `bootstrap.md` | per-project instantiation procedure |
| `templates/CREW.md.tmpl` | crew contract: parameters + rules index |
| `templates/AGENTS.md.tmpl` | repo-level lane discipline (auto-loaded per session) |
| `templates/captain-runbook.md.tmpl` | controller manual: dispatch, validate, merge train |
| `templates/brief.md` `READY.md` `report.md` | lane-side formats |
| `templates/DIGEST.md` `NOTES.md` `flaky-ledger.md` | drive initial states |
| `bin/validate-ready.sh` | the mechanical READY validator |

## Status

In production on one local-only repository (multi-lane, merge trains live). The validator's frozen-head rule caught a real stale-READY during testing — a commit landed after the block was written, and the block was correctly rejected.

## License

MIT.
