---
name: check
description: "Have an independent reviewer agent (Sonnet by default) check the changes already in the working tree, without changing anything. Usage: /work-review:check [REVIEWER=sonnet|opus|haiku|codex] [CODEX_MODEL=name] [what the changes were meant to do]."
argument-hint: "[REVIEWER=sonnet|opus|haiku|codex] [CODEX_MODEL=name] [what the changes were meant to do]"
disable-model-invocation: true
---

# work-review: check

Review only. You do not edit files in this skill.

**Arguments.** The invoking message reads: $ARGUMENTS

1. Run `git rev-parse --is-inside-work-tree`. If this is not a git repository, say that work-review needs one and stop.
2. If `git status --porcelain` is empty, there is nothing to review against HEAD. Say so and stop.
3. Settings come first, in any order; remove them. `REVIEWER=sonnet|opus|haiku|codex` picks who reviews (`codex` is OpenAI Codex run read-only from the terminal); the default is `sonnet`, and any other value is an error: name the allowed values and stop. `CODEX_MODEL=name` (letters, digits, `.`, `_`, `-` only) picks the Codex model, only with `REVIEWER=codex`. TASK is the remaining text. If it is empty, use "Review the uncommitted changes in this repository." and say in your report that the reviewer had no stated intent to check against.
4. Launch the `reviewer` agent from this plugin (agent type `work-review:reviewer`) once, with its model set to REVIEWER (pass it as the agent's model parameter), and this message:

   ```
   TASK: <TASK>
   BASELINE: commit <git rev-parse HEAD>; files already modified before the work: none (review all uncommitted changes)
   ROUND: 1
   SUMMARY: not provided (review-only run)
   ```

   If REVIEWER is `codex`, do not launch the agent. Instead run this with Bash (timeout 600000 ms), putting the same message between the markers, and treat its output as the reviewer's reply:

   ```
   bash "${CLAUDE_SKILL_DIR}/../../scripts/codex-review.sh" <CODEX_MODEL or nothing> <<'WORK_REVIEW_MSG'
   <the message>
   WORK_REVIEW_MSG
   ```

   Exit code 3 means the `codex` command is not installed: stop and tell the user to run `npm install -g @openai/codex` and then `codex login` (a login made in the Codex VS Code extension is shared, so `codex login` may not be needed). Exit code 4 means Codex failed: show the error lines and stop.

5. Report to the user in the language they wrote in: the reviewer (REVIEWER, and CODEX_MODEL if set), the verdict, the test result, and each finding with its `file:line`. Do not fix anything unless the user asks afterward.
