# Analysis: Role Management & Current.account_user

## The Actual Problem

`AccountUser` exists primarily for **multi-account membership** —
an agent can work at multiple brokerages with the same login. The
role is a secondary attribute on that membership. The current
design has one record per role per account, but in practice each
user only has one role per account.

The audit flagged that `Current.account_user` doesn't exist because
a user *could* have multiple `AccountUser` records for one account.
In reality, this never happens — seeds and invite flow create one
record per user-account pair.

---

## Options Evaluated

### Option 1: Keep Multi-Record Pattern (Status Quo)

One `AccountUser` per role per account per user. Composite unique
on `(account_id, user_id, role)`.

**Pros:** Already working. No migration.

**Cons:**
- Can't set `Current.account_user` (the trigger for this analysis)
- Every auth check queries `account_users` — 3-4 SQL queries per
  request for role checks
- Semantically wrong — your roles are hierarchical (owner > manager
  > agent), not additive. An owner doesn't need a separate "agent"
  record to manage listings.
- Redundant records if someone is both "manager" and "agent" —
  being a manager already implies agent capabilities

### Option 2: Single Record with Role Hierarchy (Recommended)

One `AccountUser` per user-account pair. Role is the highest level.
Unique index on `(account_id, user_id)`.

```ruby
class AccountUser < ApplicationRecord
  ROLES = %w[owner manager agent].freeze
  ROLE_HIERARCHY = { "owner" => 0, "manager" => 1, "agent" => 2 }.freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }

  def at_least?(required_role)
    ROLE_HIERARCHY[role] <= ROLE_HIERARCHY[required_role]
  end
end
```

**Pros:**
- Enables `Current.account_user` — one query on login, zero
  queries for auth throughout the request
- `AccountUser` becomes the clear "membership" record — the right
  place for invited_at, last_active_at, default_account, etc.
- Matches the real domain: an agent at Brokerage A has ONE
  membership with ONE role, not multiple records
- Multi-account stays clean — user has one `AccountUser` per
  account they belong to
- Policies simplify: `account_user.at_least?("manager")` instead
  of `user.can_manage?(account)` with a SQL query

**Cons:**
- Migration to consolidate any multi-role records (low risk —
  likely none exist in practice)
- If a future use case needs additive roles (e.g., "billing_admin"
  orthogonal to "manager"), would need a boolean column or pivot

**Multi-account flow with this option:**
```
User (sarah@example.com)
  ├── AccountUser (Brokerage A, role: "agent")
  ├── AccountUser (Brokerage B, role: "manager")
  └── AccountUser (Brokerage C, role: "owner")
```

On login, `Current.account_user` is set to the one for the active
account. Account switching changes `Current.account_user`. Clean.

### Option 3: Role Array on Single Record

One `AccountUser` with `roles: ["manager", "agent"]` as a
PostgreSQL array column.

**Verdict:** Overengineered. Roles are hierarchical, not additive.
Array implies independence between roles, which doesn't match the
domain. Adds query complexity (`ANY()` vs `=`).

### Option 4: Rolify Gem

**Verdict:** Wrong tool. Rolify is for apps with dynamic,
resource-scoped roles across many resource types. RePlay has one
resource type (Account) and three fixed roles. The `AccountUser`
join model is more domain-specific than Rolify's generic tables.
Would lose the membership concept entirely.

### Option 5: Stay on Action Policy

**Not a choice to make** — Action Policy is authorization, not role
management. It consumes whatever role system you build. Stay on it
regardless of which option above you pick.

---

## Recommendation: Option 2

Single `AccountUser` per user-account pair with hierarchical role.

### What Changes

| Layer | Before | After |
|-------|--------|-------|
| Schema | Unique on `(account_id, user_id, role)` | Unique on `(account_id, user_id)` |
| Model | Multiple records per pair possible | One record per pair, enforced |
| Current | `Current.user`, `Current.account` | + `Current.account_user` |
| Auth concern | Queries `account_users` each request | Sets `Current.account_user` once on session resume |
| Authorizable | `has_role?` does SQL query | `at_least?` is in-memory comparison |
| Policies | `user.can_manage?(account)` | `account_user&.at_least?("manager")` |
| Invites | Creates `AccountUser` with role | Same — no change |
| Account switching | Changes `Current.account` | Also changes `Current.account_user` |

### What Stays the Same

- Multi-account membership — user still has one `AccountUser` per
  account
- Three roles: owner, manager, agent
- Action Policy — same gem, same policy files, just different
  method calls
- Invite flow — already creates one `AccountUser` per invite
- `acts_as_tenant` — unchanged, still scopes by `Current.account`

### Performance Win

**Before (per request):**
- `owner_of?(account)` → SQL EXISTS query
- `can_manage?(account)` → SQL EXISTS query
- `agent_on?(account)` → SQL EXISTS query
- Policy scope → another SQL query

**After (per request):**
- `Current.account_user` set once on session resume (1 query)
- `account_user.at_least?("manager")` → in-memory hash lookup (0 queries)
- All subsequent auth checks → 0 queries

---

## Migration Sketch

```
1. Add AccountUser#at_least? method
2. Add Current.account_user attribute
3. Set Current.account_user in Authentication concern (session resume)
4. Update Authorizable to use account_user when available
5. Migration: consolidate any multi-role records, change unique index
6. Update policies to use account_user context
7. Update specs
```

---

## Open Questions

1. **Account switching UI** — when a user switches accounts, how
   is `Current.account_user` updated? Currently `Current.account`
   is set from the session. `Current.account_user` would be derived
   from `Current.user` + `Current.account`.

2. **Admin bypass** — admin controllers use `without_tenant`. They
   don't have an `account_user`. Policies need to handle
   `account_user: nil` for admin context.

3. **API/Player context** — API controllers authenticate by player
   token, not user session. No `account_user` in API context. Same
   as current — API doesn't use role-based auth.

4. **Background jobs** — jobs that check permissions need the
   `account_user` passed explicitly (same as current — jobs don't
   have `Current` context).
