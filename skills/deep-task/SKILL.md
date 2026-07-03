---
name: deep-task
description: "Full plan-execute-verify orchestration for complex, long-horizon, or high-stakes tasks (multi-file changes, large analyses, anything spanning many steps or sessions). Use when the user says 'deep-task' or 'deep task', or when a task is clearly complex: ambiguous scope, more than ~10 steps, or costly to get wrong. NOT for simple or routine tasks, even if they touch multiple files."
---

# Deep Task — Fable-grade orchestration

This skill turns one complex request into a managed project with explicit planning,
external memory, delegation, and mandatory verification. Follow ALL phases in order.
Phase 3 (verification) must never be skipped, however confident you are.

## Phase 0 — Intake (before any work)

1. Restate the goal in one sentence.
2. Write concrete success criteria — testable statements, not vibes.
3. List assumptions and ambiguities. If any decision is genuinely the user's,
   ask ALL questions now in one batch (use AskUserQuestion where available).
4. Estimate: number of steps, files touched, risk level. Confirm T3 is warranted;
   if not, say so and downgrade to a lighter flow.

## Phase 1 — Plan

1. Decompose into ordered steps with explicit dependencies.
2. Mark independent steps as parallelizable; mark risky steps for early verification.
3. For each step, note its verification method NOW (test, diff review, source check).
4. Create `STATE.md` in the working directory:

```markdown
# STATE — <task>
## Goal & success criteria
## Plan (ordered steps, each with verify method)
## Decisions (with why)
## Done
## Next
## Open questions / blockers
```

   Naming, placement, and resume rules for STATE.md follow SONNET-FABLE-CORE §3
   (STATE-<task-slug>.md when multiple tasks share a directory, Cowork
   connected-folder placement, resume-mismatch check before following it).

5. Stress-test the plan before finalizing: what would make it fail? Adjust once.
6. If planning reveals that the difficulty concentrates in a single deep
   reasoning step (not in coordination), run the `hard-problem` skill for that
   step instead of hoping the plan absorbs it.
7. **Checkpoint with the user:** present the plan summary and success criteria
   briefly before executing. Skip only if the task is low-risk or the user
   explicitly asked for full autonomy.

## Phase 2 — Execute

- Work step-by-step following STATE.md. Update `Done` / `Next` / `Decisions`
  after every meaningful unit BEFORE starting the next.
- Delegate to subagents (where available): exploration, bulk reads, independent
  workstreams. One objective per subagent; require condensed results back.
  Launch independent subagents in parallel, in one batch.
- Checkpoint every ~5 steps: re-read success criteria; confirm still on track;
  course-correct early rather than at the end.
- If blocked: record the blocker in STATE.md, attempt one alternative approach,
  then surface to the user with options — don't thrash silently.

## Phase 3 — Adversarial Verification (mandatory)

If the `adversarial-review` skill is available, run it for this phase — it
carries the fuller procedure (fresh-context setup, check categories, no-subagent
fallback). The brief below is the fallback for when that skill is not installed.

Use a FRESH context for review whenever possible — a verification subagent, or a
deliberately adversarial re-pass. The reviewer's brief:

> You did not write this. Find every problem: correctness, edge cases, missing
> requirements, internal inconsistencies, unverified claims. Report everything,
> including low-confidence findings, each with confidence (high/med/low) +
> severity (blocker/major/minor/nit). Coverage first — a separate step filters.

Then, as orchestrator:
1. Triage: fix all blockers/majors, batch minors, judge nits.
2. Re-verify the fixes (run tests again, re-check facts).
3. Diff final deliverable against the Phase 0 success criteria, item by item.

## Phase 4 — Deliver

- Lead with outcome and where the deliverables are.
- Report: success criteria → met/not-met, key decisions + why, known limitations,
  anything the verification could not fully confirm (labeled with confidence).
- Delete STATE.md when the task is fully closed (default — it is working
  memory, not a deliverable; same rule as SONNET-FABLE-CORE §3). Keep it, updated to
  final state, only when follow-up sessions are expected.
