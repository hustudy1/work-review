---
name: run
description: "Do a task, then have an independent reviewer agent (Sonnet by default) check it, fix what it finds, and repeat until it passes or 3 rounds run out. Usage: /work-review:run [REVIEWER=sonnet|opus|haiku|codex] [CODEX_MODEL=name] [MAX_ROUNDS=n] <task>."
argument-hint: "[REVIEWER=sonnet|opus|haiku|codex] [CODEX_MODEL=name] [MAX_ROUNDS=n] <task>"
disable-model-invocation: true
---

# work-review: run

You are the implementer. You do the task yourself; an independent `reviewer` agent from this plugin (agent type `work-review:reviewer`) checks your work. You never review your own work in its place, and you never skip a review round.

**Arguments.** The invoking message reads: $ARGUMENTS

Settings come first, in any order, as `NAME=value` tokens; remove them:
- `REVIEWER=sonnet|opus|haiku|codex`: who reviews. `sonnet`, `opus` and `haiku` are this plugin's reviewer agent on that Claude model; `codex` is OpenAI Codex run read-only from the terminal. The default is `sonnet`. Any other value is an error: name the allowed values and stop.
- `CODEX_MODEL=name`: the Codex model (letters, digits, `.`, `_`, `-` only), used only with `REVIEWER=codex`. The default is Codex's own configured model.
- `MAX_ROUNDS=n`: the round limit, a whole number from 1 to 5. The default is 3.

Everything after the settings is the TASK, verbatim. If there is no task, reply with the usage line from the description and stop.

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

1. Launch the reviewer agent with its model set to REVIEWER (pass it as the agent's model parameter), and this message, filled in:

   ```
   TASK: <the task, verbatim>
   BASELINE: commit <BASELINE_COMMIT>; files already modified before the work: <PRE_EXISTING or "none">
   ROUND: <n>
   SUMMARY: <2–5 lines: what you changed and how you tested it>
   PREVIOUS FINDINGS: <round 2+: each previous finding, then "fixed: <how>" or "rejected: <reason>">
   ```

   Pass facts, not persuasion. Do not tell the reviewer the work is correct.

   If REVIEWER is `codex`, do not launch the agent. Instead run this with Bash (timeout 600000 ms), putting the same message between the markers, and treat its output as the reviewer's reply:

   ```
   bash "${CLAUDE_SKILL_DIR}/../../scripts/codex-review.sh" <CODEX_MODEL or nothing> <<'WORK_REVIEW_MSG'
   <the message>
   WORK_REVIEW_MSG
   ```

   Exit code 3 means the `codex` command is not installed: stop and tell the user to run `npm install -g @openai/codex` and then `codex login` (a login made in the Codex VS Code extension is shared, so `codex login` may not be needed). Exit code 4 means Codex failed: show the error lines and stop.

2. Find the `VERDICT:` line in the reply (ignore a surrounding code block or blank lines).
   - `VERDICT: PASS`: go to Step 4.
   - `VERDICT: CHANGES_REQUESTED`: if any finding is marked `(conflicts with TASK)`, stop the rounds and go to Step 4 with the result "needs your decision". Do not fix or reject those findings yourself; the user chooses between their instruction and the project rule. Otherwise, for each high or medium finding, either fix it or reject it with a concrete reason (for example, the finding misreads the code; show where). Re-run the tests. Then start the next round.
   - No `VERDICT:` line, or a value other than the two above: launch the reviewer once more with the same message. If the second reply is malformed too, stop the rounds and report that the review could not be completed.

If MAX_ROUNDS runs out without a PASS, stop. Do not keep fixing without review.

## Step 4: Report

Tell the user, in the language they wrote the task in:

- **Reviewer**: REVIEWER (and CODEX_MODEL if set).
- **Result**: passed in round n / not passed after n rounds / needs your decision (the task conflicts with a project rule: name the rule and the two options) / review could not be completed.
- **What changed**: the files and a one-line summary of each.
- **Review history**: per round, the findings and what you did (fixed / rejected and why).
- **Remaining**: open findings if it did not pass, and any low findings.
- **Tests**: the command and its final result.
- **Next**: the changes are not committed. Suggest a commit message.

Keep it short. The reviewer's full replies do not need to be repeated.
