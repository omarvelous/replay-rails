# Standard: Seed Data

## Rule

Every time a new model or significant feature is added, `db/seeds.rb` must be updated to include seed data for that model.

## Approach

Seeds reuse FactoryBot factories to stay DRY and consistent with tests:

```ruby
require "factory_bot_rails"
FactoryBot.reload  # clears any auto-loaded definitions to prevent DuplicateDefinitionError
```

## Requirements

1. **Always idempotent** — use guards (`unless Model.exists?(...)`) so `db:seed` can be run repeatedly without creating duplicates.

2. **One deterministic record per model** — at least one record with known, fixed values (no Faker) so developers can log in or navigate to a known state immediately.

3. **Additional random records** — use Faker-backed factories to create realistic variety (3-5 extra records is typically enough).

4. **Log output** — use `puts` to confirm what was created so seed runs are visible in the terminal.

## Template

```ruby
require "factory_bot_rails"
FactoryBot.reload  # clears any auto-loaded definitions to prevent DuplicateDefinitionError

# -----------------------------------------------------------------------
# ModelName
# -----------------------------------------------------------------------
unless ModelName.exists?(unique_field: "known_value")
  FactoryBot.create(:model_name, unique_field: "known_value", other: "fixed")
  puts "Created demo model_name: known_value"
end

if ModelName.count < 4
  (4 - ModelName.count).times { FactoryBot.create(:model_name) }
end
puts "Seeded #{ModelName.count} model_name(s)"
```

## Why

- Reusing factories means seed data and test data are created the same way — if the factory is wrong, both fail together, making issues easier to spot.
- Deterministic records give every developer the same starting point without needing to share database dumps.
- Idempotency lets seeds run in CI, staging resets, and local rebuilds without side effects.
