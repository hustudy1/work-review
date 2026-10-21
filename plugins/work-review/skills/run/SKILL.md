---
name: run
description: "Do a task, then have an independent reviewer agent (Sonnet) check it, fix what it finds, and repeat until it passes or 3 rounds run out. Usage: /work-review:run [MAX_ROUNDS=n] <task>."
argument-hint: "[MAX_ROUNDS=n] <task>"
disable-model-invocation: true
---

# work-review: run

You are the implementer. You do the task yourself; an independent `reviewer` agent from this plugin (agent type `work-review:reviewer`) checks your work. You never review your own work in its place, and you never skip a review round.

**Arguments.** The invoking message reads: $ARGUMENTS

If it starts with `MAX_ROUNDS=n` (a whole number from 1 to 5), that is the round limit; remove it. The default is 3. Everything else is the TASK, verbatim. If there is no task, reply with the usage line from the description and stop.

## Step 1: Baseline

Run `git rev-parse --is-inside-work-tree`. If this is not a git repository, tell the user that work-review needs one (the reviewer reads `git diff`), suggest `git init` and a first commit, and stop.

Record:
- BASELINE_COMMIT: `git rev-parse HEAD` (if there are no commits yet, use the empty tree `4b825dc642cb6eb9a060e54bf8d69288fbee4904`).
- PRE_EXISTING: the files listed by `git status --porcelain` right now. These are changes the user made before you started. Do not revert them, and tell the reviewer about them.

## Step 2: Do the task

Read the project's rules first if they exist: `REVIEW.md`, `AGENTS.md`, `CLAUDE.md`. Then do the TASK. Follow the project's conventions. When you are done, run the project's tests (the command in `REVIEW.md` or `AGENTS.md`, or the obvious one) and fix failures before review.

Do not commit, push, or deploy. The user decides that after the run.

## Step 3: Review rounds

For ROUND = 1, 2, … up to MAX_ROUNDS:

1. Launch the reviewer agent with this message, filled in:

   ```
   TASK: <the task, verbatim>
   BASELINE: commit <BASELINE_COMMIT>; files already modified before the work: <PRE_EXISTING or "none">
   ROUND: <n>
   SUMMARY: <2–5 lines: what you changed and how you tested it>
   PREVIOUS FINDINGS: <round 2+: each previous finding, then "fixed: <how>" or "rejected: <reason>">
   ```

   Pass facts, not persuasion. Do not tell the reviewer the work is correct.

2. Find the `VERDICT:` line in the reply (ignore a surrounding code block or blank lines).
   - `VERDICT: PASS`: go to Step 4.
   - `VERDICT: CHANGES_REQUESTED`: if any finding is marked `(conflicts with TASK)`, stop the rounds and go to Step 4 with the result "needs your decision". Do not fix or reject those findings yourself; the user chooses between their instruction and the project rule. Otherwise, for each high or medium finding, either fix it or reject it with a concrete reason (for example, the finding misreads the code; show where). Re-run the tests. Then start the next round.
   - No `VERDICT:` line, or a value other than the two above: launch the reviewer once more with the same message. If the second reply is malformed too, stop the rounds and report that the review could not be completed.

If MAX_ROUNDS runs out without a PASS, stop. Do not keep fixing without review.

## Step 4: Report

Tell the user, in the language they wrote the task in:

- **Result**: passed in round n / not passed after n rounds / needs your decision (the task conflicts with a project rule: name the rule and the two options) / review could not be completed.
- **What changed**: the files and a one-line summary of each.
- **Review history**: per round, the findings and what you did (fixed / rejected and why).
- **Remaining**: open findings if it did not pass, and any low findings.
- **Tests**: the command and its final result.
- **Next**: the changes are not committed. Suggest a commit message.

Keep it short. The reviewer's full replies do not need to be repeated.
