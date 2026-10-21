---
name: check
description: "Have an independent reviewer agent (Sonnet) check the changes already in the working tree, without changing anything. Usage: /work-review:check [what the changes were meant to do]."
argument-hint: "[what the changes were meant to do]"
disable-model-invocation: true
---

# work-review: check

Review only. You do not edit files in this skill.

**Arguments.** The invoking message reads: $ARGUMENTS

1. Run `git rev-parse --is-inside-work-tree`. If this is not a git repository, say that work-review needs one and stop.
2. If `git status --porcelain` is empty, there is nothing to review against HEAD. Say so and stop.
3. TASK is the argument text. If it is empty, use "Review the uncommitted changes in this repository." and say in your report that the reviewer had no stated intent to check against.
4. Launch the `reviewer` agent from this plugin (agent type `work-review:reviewer`) once, with:

   ```
   TASK: <TASK>
   BASELINE: commit <git rev-parse HEAD>; files already modified before the work: none (review all uncommitted changes)
   ROUND: 1
   SUMMARY: not provided (review-only run)
   ```

5. Report to the user in the language they wrote in: the verdict, the test result, and each finding with its `file:line`. Do not fix anything unless the user asks afterward.
