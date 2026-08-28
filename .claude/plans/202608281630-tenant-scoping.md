# Plan: Explicit Tenant Scoping

## Problem

Tenant isolation currently relies on convention — controllers use
`Current.account.listings` or `authorized_scope`, but nothing prevents
a background job, service object, or console query from calling
`Listing.all` and leaking data across accounts.

Action Policy handles authorization (who *should* see what), but there's
no model-level enforcement of isolation (who *can* see what).

## Goal

Every tenant-scoped model automatically restricts queries to the current
account. Creating a record without a tenant raises an error. Cross-tenant
queries require explicit opt-in.

## Approach: `acts_as_tenant` gem

The `acts_as_tenant` gem adds automatic query scoping, record creation
validation, and tenant enforcement at the model level. It works via
`default_scope` internally but with a well-tested API that handles the
sharp edges.

### How it works

```ruby
# config/initializers/acts_as_tenant.rb
ActsAsTenant.configure do |config|
  config.require_tenant = true  # Raise if no tenant set
end

# app/controllers/application_controller.rb
set_current_tenant_through_filter
before_action :set_tenant

def set_tenant
  set_current_tenant(Current.account)
end

# app/models/listing.rb
class Listing < ApplicationRecord
  acts_as_tenant :account
  # ...existing code...
end
```

Once set, all queries on `Listing` automatically scope to the current
tenant. `Listing.all` behaves like `Current.account.listings`. Creating
a record without `account_id` raises a validation error.

## Models to scope

Every model with `belongs_to :account` needs `acts_as_tenant :account`:

| Model | Has `account_id` | Notes |
|-------|:-:|-------|
| Site | Yes | |
| Listing | Yes | |
| Agent | Yes | |
| Ad | Yes | |
| Playlist | Yes | |
| QrCode | Yes | |
| QrScan | Yes | |
| Lead | Yes | |
| Impression | Yes | |
| MetricSnapshot | Yes | |
| Invite | Yes | |
| AccountUser | Yes | Special — this IS the tenant membership |

**Not scoped** (no `account_id`, or cross-tenant by design):

| Model | Why |
|-------|-----|
| Account | IS the tenant |
| User | Belongs to multiple accounts |
| Session | Tied to user, not account |
| Player | Cross-account (device moves between brokerages) |
| PaperTrail::Version | Has `account_id` but queried cross-tenant in admin |

### Join models

Join models that don't have `account_id` directly (ScreenPlayer,
ScreenPlaylist, PlaylistAd, ListingAgent, LeadAgent, CollectionAdAd)
are implicitly scoped through their parent associations. No changes
needed — they can only be reached through already-scoped parents.

## Tenant setting contexts

The tenant needs to be set in every execution context:

| Context | How to set tenant |
|---------|-------------------|
| App controllers | `set_current_tenant(Current.account)` via `before_action` |
| Admin controllers | `ActsAsTenant.without_tenant { ... }` — admin queries cross-tenant |
| Background jobs | `ActsAsTenant.with_tenant(account) { ... }` |
| Console | `ActsAsTenant.current_tenant = Account.find(1)` |
| Tests | Set via factory or explicit `ActsAsTenant.current_tenant =` |
| API controllers | Set from player's account via token lookup |
| Marketing/Go controllers | Set from the record being accessed |
| Seeds | `ActsAsTenant.without_tenant` or set per-account block |

### Admin panel

Admin (Administrate) needs cross-tenant access by design. The admin
base controller should use `ActsAsTenant.without_tenant`:

```ruby
module Admin
  class ApplicationController < Administrate::ApplicationController
    around_action :skip_tenant_scoping

    private

    def skip_tenant_scoping(&block)
      ActsAsTenant.without_tenant(&block)
    end
  end
end
```

### Background jobs

Jobs that operate on tenant-scoped data need the tenant set:

```ruby
class MetricsRollupJob < ApplicationJob
  def perform
    Account.find_each do |account|
      ActsAsTenant.with_tenant(account) do
        # All queries automatically scoped
        rollup_metrics_for(account)
      end
    end
  end
end
```

### Tests

Factory-created records need a tenant set. Two approaches:

1. Set tenant globally in `before(:each)` for request/model specs
2. Use `ActsAsTenant.with_tenant(account)` blocks in specs

The existing test setup already creates accounts via factories. The
main change is wrapping specs that query scoped models.

## Interaction with Action Policy

`acts_as_tenant` and Action Policy are complementary:

- **acts_as_tenant** → "You can only see data in your account" (isolation)
- **Action Policy** → "Within your account, what can your role do?" (authorization)

The `authorized_scope` calls in controllers become simpler — they no
longer need to add `where(account: account)` in every policy scope
because the tenant filter is already applied.

Policy scopes can be simplified from:

```ruby
# Before
relation_scope do |relation|
  relation.where(account: account)
end

# After — tenant scoping handles the where clause
relation_scope do |relation|
  relation  # already scoped to current tenant
end
```

Agent-role scoping (filtering to own listings/leads) remains in policies.

## Risks and mitigations

| Risk | Mitigation |
|------|-----------|
| `default_scope`-like surprises | `acts_as_tenant` is well-tested; `unscoped` works if needed |
| Forgetting to set tenant in jobs | `config.require_tenant = true` raises immediately |
| Admin panel breaks | `without_tenant` wrapper on admin base controller |
| Test setup complexity | Helper method or shared context to set tenant |
| Seeds break | Wrap in `without_tenant` or set tenant per-account block |
| Console debugging harder | Document `ActsAsTenant.current_tenant = Account.find(id)` |

## Build order

### Phase 1 — Setup + first model (TDD)

1. Add `acts_as_tenant` gem
2. Configure initializer with `require_tenant = true`
3. RED: Spec that `Listing.create` without tenant raises
4. RED: Spec that `Listing.all` with tenant set only returns tenant's records
5. GREEN: Add `acts_as_tenant :account` to Listing
6. Update `ApplicationController` with `set_current_tenant`
7. Update admin base controller with `without_tenant` wrapper
8. Run full test suite — fix any failures from missing tenant context

### Phase 2 — Roll out to all models

9. Add `acts_as_tenant :account` to remaining models (Site, Agent, Ad, Playlist, QrCode, QrScan, Lead, Impression, MetricSnapshot, Invite)
10. Update background jobs (MetricsRollupJob, VersionCleanupJob) with tenant blocks
11. Update seeds with tenant context
12. Run full test suite — fix failures

### Phase 3 — Simplify policy scopes

13. Remove redundant `where(account: account)` from policy relation scopes
14. Remove `Current.account.` prefix from controller queries where tenant scoping handles it
15. Run full test suite — verify no regressions

### Phase 4 — Documentation

16. Update CLAUDE.md tenant scoping section
17. Update `docs/architecture/overview.md` with acts_as_tenant info
18. Add console/job tenant patterns to developer docs

## What's deferred

- **Row-level security in PostgreSQL** — database-level enforcement via RLS policies. Maximum security but significantly more complex. Consider if compliance requirements demand it.
- **Tenant in URL** — some multi-tenant apps put the tenant in the subdomain or URL. Not needed — RePlay uses session-based tenant from AccountUser.
