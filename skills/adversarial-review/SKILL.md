---
name: adversarial-review
description: "Fresh-context adversarial review of a finished deliverable — code, document, analysis, design, plan. Use when the user explicitly asks for a rigorous review ('adversarial-review', '敵対的レビュー', '徹底的にレビュー/検証して' — an explicit ask always fires this skill regardless of scale), or before declaring a T3-scale deliverable (long-horizon, multi-file, or high-stakes work) complete. NOT for casual or routine review requests (a quick look at a PR, running a build, verifying a single fact) and NOT for unrequested reviews of T2-scale work, where a light self-check suffices. Also usable standalone on work produced elsewhere."
---

# Adversarial Review — the second pass that closes the quality gap

Premise: a stronger model is right more often on the first pass; a well-run
adversarial second pass recovers most of that difference. The single most common
failure mode is the reviewer inheriting the author's assumptions — so this skill
forces a hostile, fresh-eyes framing.

## Setup

1. Identify the deliverable and its ORIGINAL success criteria / requirements.
   If none were stated, reconstruct them first and confirm briefly.
2. If subagents are available, delegate the review to one with a clean context.
   Give it only: the deliverable, the requirements, and the reviewer brief below.
   Do NOT pass along the author's reasoning or justifications.
3. **No subagents available (chat, Cowork without delegation, self-review):**
   simulate the fresh context deliberately. Re-derive the requirements from the
   original request WITHOUT re-reading your own reasoning or justifications.
   Then review the deliverable strictly against that re-derivation, one category
   at a time, writing findings before moving to the next category — do not let
   memory of "why I did it that way" answer a question the artifact itself
   should answer.

## Reviewer brief

Adopt this stance fully:

> You did not create this work and you have no stake in it being good.
> Your reputation depends on finding real problems others missed.

Check, in order:

**Correctness** — Is each claim/behavior actually right? For code: trace edge
cases, error paths, boundary values, concurrency, resource cleanup. For analysis:
recompute key numbers, re-check each load-bearing fact against its source.

**Completeness** — Diff against requirements item by item. What was asked for
but not delivered? What was delivered but silently narrower than asked
(literal-scope bug: instruction applied to one case instead of all)?

**Consistency** — Do numbers, names, terminology, and claims agree across the
whole artifact? Do the conclusion and the evidence actually connect?

**Robustness** — What input, reader, or future change breaks this? What is the
strongest argument that the whole approach is wrong (steelman)?

## Reporting rules

- Report EVERYTHING found, including low-severity and low-confidence findings.
  Coverage first; filtering is a separate step. Silently dropping a possible bug
  is the only failure.
- Each finding: location → issue → why it matters → confidence (high/med/low)
  → severity (blocker/major/minor/nit).
- No praise padding. A short "no issues found in X" per category is enough.

## Close the loop (author side)

1. Triage: fix all blockers/majors, batch minors, judge nits.
2. Re-verify each fix — a fix without re-verification is a new unverified change.
3. Only then report completion, listing what was found and fixed.
