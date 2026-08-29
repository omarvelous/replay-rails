# Standard: Work Lifecycle

## Rule

Every feature follows a consistent lifecycle from draft to shipped. Documentation and roadmap updates are part of the work, not afterthoughts.

## Starting work

Before writing any code:

1. **Create a branch** — named after the feature
2. **Promote the plan** — move from `drafts/` to `.claude/plans/` with a timestamp prefix
3. **Review the plan** — check if anything has changed since drafting (new models, renamed concepts, shipped dependencies)
4. **Update the roadmap** — mark the item as "In progress" in `.claude/product/roadmap.md`
5. **Commit** — the plan promotion and roadmap update are the first commit on the branch

## During work

5. **Follow TDD** — RED/GREEN commits per the commit cadence standard
6. **Update the plan** — if the approach changes during implementation, update the plan to reflect reality

## Finishing work

Before creating a PR:

7. **Update the roadmap** — mark the item as shipped with branch/PR reference
8. **Update developer docs** — if the feature changes architecture, models, or APIs, update the relevant docs in `docs/`
9. **Update CLAUDE.md** — if the feature changes conventions, auth, authorization, or project structure
10. **Update user docs** — if the feature adds or changes user-facing behavior, add or update pages in `app/views/docs/pages/` and `config/docs.yml`
11. **Create PR** — push, create PR with summary and test plan

## Checklist

Use this as a mental checklist before marking work as done:

- [ ] Plan promoted and updated
- [ ] Roadmap updated (in progress → shipped)
- [ ] Developer docs updated (if architecture/API changed)
- [ ] CLAUDE.md updated (if conventions changed)
- [ ] User docs updated (if user-facing behavior changed)
- [ ] Tests passing
- [ ] PR created

## Why

- Plans that don't reflect reality become misleading
- Docs that lag behind code become wrong — wrong docs are worse than no docs
- The roadmap is the single source of truth for what's shipped and what's next
- Doing these updates as part of the work (not later) ensures they actually happen
