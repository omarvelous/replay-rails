# Testing

RePlay uses RSpec with a TDD workflow. Every change follows the red-green cycle.

## Stack

| Tool | Purpose |
|------|---------|
| RSpec | Test framework |
| FactoryBot | Test data factories (`spec/factories/`) |
| Faker | Realistic random data |
| shoulda-matchers | One-liner validation/association tests |
| DatabaseCleaner | Clean state between tests (transaction strategy, truncation for system specs) |
| Capybara | System/integration tests with headless Chrome |
| SimpleCov | Code coverage reporting |

## Running tests

```bash
make test                                    # Full suite
make test-file FILE=spec/models/user_spec.rb # Single file
```

Both commands run `db:test:prepare` before executing specs.

## TDD workflow

1. **Red** — Write a failing spec. Run it. Confirm it fails for the right reason.
2. **Green** — Write the minimum implementation to make it pass.
3. **Refactor** — Clean up without breaking the spec.

RED and GREEN get separate commits. This makes the git history tell the story of what was tested and how it was implemented.

### Commit cadence

```
RED:   Add spec for LeadAgent assignment
GREEN: Implement LeadAgent assignment
RED:   Add spec for LeadMailer notification
GREEN: Send LeadMailer on lead creation
```

Factories are created in the RED step (they're part of the test infrastructure), not the GREEN step.

## Spec organization

```
spec/
├── models/           # Unit tests — validations, associations, scopes, methods
├── policies/         # Action Policy specs — permit/forbid per role
├── requests/         # Integration tests — full HTTP request/response cycle
├── jobs/             # Background job specs
├── mailers/          # Mailer specs
├── factories/        # FactoryBot factory definitions
├── support/          # Shared config and helpers
└── rails_helper.rb   # RSpec + Rails configuration
```

## Key conventions

### Request specs

- Default host: `app.replay.localhost`
- Use `sign_in(user)` helper from `spec/support/authentication.rb`
- Authentication creates a session and sets the signed cookie
- Test all three roles (owner, manager, agent) for authorization

### Policy specs

```ruby
describe ListingPolicy do
  let(:account) { create(:account) }
  let(:owner) { create(:user, :owner, account: account) }
  let(:agent) { create(:user, :agent, account: account) }

  describe "#update?" do
    it "permits owners" do
      expect(policy(owner)).to permit(:update)
    end

    it "forbids agents" do
      expect(policy(agent)).to forbid(:update)
    end
  end
end
```

### Model specs

Use shoulda-matchers for associations and validations:

```ruby
describe Listing do
  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_many(:listing_agents) }
  it { is_expected.to validate_presence_of(:address) }
end
```

## Database strategy

- Default: `:transaction` (fast, auto-rolled-back)
- System specs: `:truncation` (required for Capybara's separate thread)
- `use_transactional_fixtures = false` — DatabaseCleaner owns cleanup

## Coverage

SimpleCov generates a report at `coverage/index.html` after each run. Current thresholds:

- Line coverage: 95%+
- Branch coverage: 80%+

Coverage is checked in CI. If a PR drops below thresholds, the build fails.

## Support files

| File | Purpose |
|------|---------|
| `spec/support/authentication.rb` | `sign_in(user)` helper for request specs |
| `spec/support/action_policy.rb` | Custom `permit`/`forbid` matchers |
| `spec/support/database_cleaner.rb` | Cleanup strategy configuration |
| `spec/support/factory_bot.rb` | Include FactoryBot syntax methods |
| `spec/support/shoulda_matchers.rb` | Configure for RSpec + Rails |
| `spec/support/capybara.rb` | Headless Chrome driver, remote Selenium for Docker |
