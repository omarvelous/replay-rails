# Plan: Separate Team (Users) from Invites

## Problem

The invites index currently does double duty — it renders both
account members (AccountUsers grouped by User) and pending invites.
This mixes two concerns in one controller and one view:

- **Team members** — who's on the account, what roles they have
- **Invites** — pending outbound invitations

The sidebar has one "Team" link pointing to `invites#index`. There's
no dedicated place to view a team member's details (roles, linked
agent profile, activity).

## Goal

Separate into two resources with proper routing:

| Resource | Controller | What it shows |
|----------|-----------|---------------|
| **Team** | `App::UsersController` | Members list (index), member detail (show) |
| **Invites** | `App::InvitesController` | Pending invites (index), invite form (new/create), accept flow (show/update), revoke (destroy) |

Sidebar gets two links under Settings:
- **Team** → `users#index` (members)
- **Invites** → `invites#index` (pending invites)

---

## Routes

```ruby
constraints subdomain: "app" do
  scope module: "app" do
    # ... existing resources
    resources :users, only: %i[ index show ]
    resources :invites, param: :token, only: %i[ index new create show update destroy ]
    # ...
  end
end
```

`users#index` is the team page. `users#show` is the member detail.
Invites keeps its existing routes but the index only shows invites.

---

## App::UsersController

The controller works with Users. The policy scope joins through
AccountUser to find users on this account — the controller never
touches AccountUser directly.

```ruby
module App
  class UsersController < App::BaseController
    def index
      @users = authorized_scope(User.all)
                 .includes(:account_users)
                 .order(:first_name)
    end

    def show
      @user = authorized_scope(User.all).find(params[:id])
      @roles = @user.account_users.where(account: Current.account)
      @agent_profile = @user.agent_profile
    end
  end
end
```

### UserPolicy

The scope joins through AccountUser to find users who are members
of the current account. The controller gets User records back —
the join is the policy's concern, not the controller's.

```ruby
class UserPolicy < ApplicationPolicy
  def index? = user&.can_manage?(account)
  def show?  = user&.can_manage?(account)

  scope_for :active_record_relation do |relation|
    relation.joins(:account_users)
            .where(account_users: { account_id: account.id })
            .distinct
  end
end
```

Agents can't view the team page — only managers and owners.

---

## Users index view (Team page)

```
┌─────────────────────────────────────────────────────────┐
│  Team                          [Invite user]            │
│  3 members                                              │
├─────────────────────────────────────────────────────────┤
│  DU  Demo Owner     demo@example.com     Owner      →  │
│  MM  Morgan Manager manager@example.com  Manager    →  │
│  JB  Jane Broker    jane.broker@...      Agent      →  │
└─────────────────────────────────────────────────────────┘
```

Each row links to `user_path(user)` for the detail page.
"Invite user" button links to `new_invite_path`.

Roles displayed per user by filtering their account_users to the
current account:

```erb
<% @users.each do |member| %>
  <% roles = member.account_users.select { |au| au.account_id == Current.account.id } %>
  <div class="flex items-center justify-between p-4">
    <%= link_to user_path(member), class: "..." do %>
      ...
      <% roles.each do |au| %>
        <span class="..."><%= au.role.capitalize %></span>
      <% end %>
    <% end %>
  </div>
<% end %>
```

The `includes(:account_users)` eager load avoids N+1.

---

## Users show view (Member detail)

```
┌─────────────────────────────────────────────────────────┐
│  ← Team                                                 │
│  Jane Broker                                            │
│  jane.broker@example.com                                │
├─────────────────────────────────────────────────────────┤
│  Roles                                                  │
│  ┌──────────┐                                           │
│  │  Agent   │                                           │
│  └──────────┘                                           │
│                                                         │
│  Agent Profile                                          │
│  Jane Broker · jane.broker@example.com · 212-555-0003   │
│  → View agent profile                                   │
│                                                         │
│  Member since Aug 27, 2026                              │
└─────────────────────────────────────────────────────────┘
```

Shows:
- Name, email, phone
- All roles on this account (badges)
- Linked agent profile (if any) with link to agent show page
- Member since date (earliest AccountUser created_at)
- Future: activity summary, last login

---

## Invites index (simplified)

Remove the members section — invites index only shows invites:

```
┌─────────────────────────────────────────────────────────┐
│  Invites                       [Invite user]            │
│  1 pending                                              │
├─────────────────────────────────────────────────────────┤
│  tom@example.com   Agent   2 days ago   [Revoke]        │
└─────────────────────────────────────────────────────────┘
│                                                         │
│  No pending invites? Invite a team member to get        │
│  started.                                               │
└─────────────────────────────────────────────────────────┘
```

---

## Sidebar update

Two links under Settings instead of one:

```erb
<%# Settings — managers and owners only %>
<% if allowed_to?(:index?, User.new) %>
  <li>
    <div class="text-xs/6 font-semibold text-gray-400">Settings</div>
    <ul role="list" class="-mx-2 mt-2 space-y-1">
      <li>
        <% active = controller_name == 'users' %>
        <%= link_to users_path, class: "..." do %>
          <svg ...></svg>
          Team
        <% end %>
      </li>
      <li>
        <% active = controller_name == 'invites' %>
        <%= link_to invites_path, class: "..." do %>
          <svg ...></svg>
          Invites
          <% pending = Current.account&.invites&.pending&.count || 0 %>
          <% if pending.positive? %>
            <span class="ml-auto ..."><%= pending %></span>
          <% end %>
        <% end %>
      </li>
    </ul>
  </li>
<% end %>
```

Invites link shows a pending count badge (like leads unread badge).

---

## InvitesController changes

Remove members loading from index — it only handles invites now:

```ruby
def index
  @invites = authorized_scope(Invite.all)
               .order(created_at: :desc)
end
```

Remove `@members`. The "Invite user" button stays.

---

## What stays the same

- Invite create/show/update/destroy actions — unchanged
- InvitePolicy — unchanged
- Accept flow — unchanged
- InviteMailer — unchanged
- AccountUserPolicy — already exists for scoping

---

## Build order

### Phase 1 — UserPolicy (RED/GREEN)
1. RED: `UserPolicy` spec — managers+ can index/show, agents denied, scope returns account members only
2. GREEN: `UserPolicy` with scope joining through AccountUser

### Phase 2 — UsersController + views (RED/GREEN)
3. RED: Users request spec — index lists members, show displays detail, tenant isolation
4. GREEN: `App::UsersController` index + show, route, index view, show view

### Phase 3 — Simplify invites + sidebar
5. Simplify invites index view — remove members section
6. Update `InvitesController#index` — remove `@members`
7. Sidebar: two links (Team → `users#index`, Invites → `invites#index` with badge)
8. Full suite green, lint clean
9. Move plan to `.claude/plans/`
