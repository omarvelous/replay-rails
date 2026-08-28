# Standard: Git Commit Cadence

## Rule

Commit after every significant, discrete step. Do not accumulate changes across multiple tasks before committing.

## What Warrants a Commit

Each of the following is a commit boundary:

- A new standard or documentation file added to `.claude/`
- A RED spec written and confirmed failing (one commit per spec file)
- A GREEN implementation that makes a spec pass (one commit per red-green pair)
- A migration created and run
- A controller or set of views created
- Seeds updated
- Linting or test suite fixes

## Commit Message Format

Use a short imperative subject line that names the task and its state:

```
Task 2 (RED): Building model spec + factory

Task 3 (GREEN): Building model, migration, account association

Task 6 (RED): Buildings request spec

Task 8 (GREEN): Buildings controller, views, routes
```

Prefix RED commits with `(RED):` and GREEN commits with `(GREEN):` so the TDD rhythm is visible in git history.

## Why

- Small commits make code review fast and focused
- Bisecting failures is only useful if commits are granular
- The RED commit proves the test was written before the implementation
- Reverting a bad implementation is easy when the spec is a separate commit

## Enforcement

Before moving from one plan task to the next, check `git status`. If there are staged or unstaged changes, commit them before proceeding.
