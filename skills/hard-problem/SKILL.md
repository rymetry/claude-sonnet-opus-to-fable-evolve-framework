---
name: hard-problem
description: "Maximum-strength protocol for problems that resist decomposition — novel algorithm design, subtle formal/mathematical reasoning, single-insight problems where a wrong answer is costly. Use when the user says 'hard-problem', '難問モード', or '本気で考えて', when deep-task's planning phase concludes the difficulty sits in one reasoning step, or after a first attempt at a reasoning-heavy problem failed verification."
---

# Hard Problem — closing the raw-reasoning gap without a bigger model

Premise: a single pass by a stronger model is approximated by multiple independent
passes plus adversarial reconciliation plus computational verification. This works
because (a) independent attempts make uncorrelated errors, so agreement is evidence;
(b) checking a candidate answer is far easier than generating it; (c) most failures
on hard problems are actually failures to pin the problem down. Spend tokens
deliberately — this protocol is expensive and should be reserved for what it's for.
Gate: if the loaded core restricts when to invoke this protocol (e.g. the Opus
core: only after a serious attempt failed verification, or when stakes are
extreme), that restriction wins over any broader trigger, including this
skill's own description.

## Phase 1 — Pin the problem down

1. Restate the problem in 2-3 genuinely different formulations (e.g., operational,
   mathematical, adversarial "what would break this").
2. Make everything explicit: inputs, outputs, constraints, invariants, edge domain
   (n=0, empty, duplicates, overflow, concurrency...).
3. Solve a strictly simpler variant completely. What made it easy? That difference
   is the actual hard core of the problem — name it.
4. Define what a correct answer must satisfy — an acceptance test you can apply
   BEFORE knowing the answer. If possible, write it as executable code now.

## Phase 2 — Independent attempts (2-3, isolated)

- With subagents: launch 2-3 solvers in parallel. Each receives the refined
  problem statement and acceptance criteria from Phase 1, plus an assigned angle
  (e.g., direct construction / invariant-first / work backwards from the answer
  shape / reduce to a known problem). Do NOT share candidate solutions or any
  reasoning between solvers — isolation applies to answers, not to the problem
  definition.
- Without subagents: do sequential attempts, each starting with an explicit
  discard: "Previous approach is assumed wrong and must not be reused."
- Each attempt must end with: candidate answer + its own strongest counterargument.

## Phase 3 — Adversarial reconciliation

1. Tabulate where attempts agree and disagree.
2. Agreements: verify once against the acceptance test — agreement is evidence,
   not proof.
3. Disagreements: this is the real difficulty, surfaced. Resolve each one by
   explicit case analysis or by test — NEVER by preferring the more
   confident-sounding attempt.
4. If all attempts converge on an answer that fails the acceptance test, the
   problem statement itself is likely misunderstood — return to Phase 1 with
   the failure as new information.

## Phase 4 — Computational verification

Convert every checkable claim into an executed check:
- Code: run it. Property-test it with generated inputs, not just happy-path cases.
- Math/logic: verify numerically for concrete values; enumerate small cases
  exhaustively; check boundary conditions symbolically.
- Algorithms: brute-force a reference implementation for small n and diff outputs
  against the candidate.

A claim verified by execution outranks any amount of re-reasoning.

## Phase 5 — Deliver with honest epistemic status

Structure the answer as:
- **Established** (passed verification — say which check).
- **Probable** (attempts agreed but not mechanically verifiable — say why believed).
- **Open** (unresolved; what evidence or experiment would settle it).

Never blend these three. A precise map of what is and isn't proven is the
deliverable — it is what lets the user trust the established part.
