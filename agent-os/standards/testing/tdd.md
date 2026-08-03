# Standard: Test-Driven Development (TDD)

## The Red-Green Rhythm

All implementation work follows a strict red-green cycle:

1. **Red** — Write the spec describing the desired behavior. Run it. It must fail (confirming the behavior doesn't exist yet).
2. **Green** — Write the minimum implementation to make the spec pass. Run it. It must pass.
3. **Refactor** — Clean up the implementation without breaking the spec.

## Rules

- **No implementation without a spec.** Models, controllers, services, and jobs are not created until a failing spec exists for them.
- **Specs ship with the implementation task** — a red task writes the spec, the green task writes the implementation. They are committed together as a pair.
- **Factories are created alongside specs** — not alongside models. The factory lives in the red task, not the green task.
- **Run the spec before implementing.** If you write a spec and it passes immediately (without implementation), the spec is wrong — fix it before proceeding.

## Spec Layers

| Layer | Tool | Purpose |
|-------|------|---------|
| Model specs | RSpec + shoulda-matchers | Validations, associations, instance methods |
| Request specs | RSpec request specs | HTTP request/response behavior, controller logic |
| System specs | RSpec + Capybara | End-to-end user journeys in a real browser |

Use the narrowest layer that adequately covers the behavior. Prefer request specs over system specs for controller behavior. Use system specs for critical user journeys that require browser interaction (forms, navigation, JavaScript).

## File Locations

```
spec/
  factories/      # FactoryBot factories — one file per model
  models/         # Model specs
  requests/       # Request specs (controller/HTTP behavior)
  system/         # Capybara system specs
```
