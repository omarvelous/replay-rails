# Plan: User Invites v2

## Current state

- Users are created via seeds, console, or the signup form (`/accounts/new`)
- Signup creates a new Account + User + AccountUser(owner) in one transaction
- No way for an existing account to add users
- RBAC is in place — AccountUser with multi-role support (owner/manager/agent, multiple per user)
- Action Policy with explicit `authorize :user, :account` context on all controllers
- `Authorizable` concern on User: `can_manage?(account)`, `owner_of?(account)`, `has_role?(role, account)`
- `LeadMailer`, `PasswordsMailer`, letter_opener_web configured
- `return_to_after_authenticating` mechanism in the Authentication concern
- Rack::Attack for rate limiting

---

## Goals

1. Owners and managers can invite users to their account by email
2. Owners can invite any role. Managers can only invite agents.
3. Invited user receives an email with a signup/accept link
4. If the user already has a RePlay account (different brokerage), they join without re-registering
5. Existing members can be invited with an additional role (agent invited as manager)
6. Invites expire after 7 days
7. Inviting an agent role auto-links to an existing Agent record by email match
8. Everything on the app subdomain — no cross-subdomain flows
9. One controller, standard RESTful routes

---

## One resource, two modalities

| Who | What they see | Actions |
|-----|--------------|---------|
| **Inviter** (owner/manager) | Team page, invite form, revoke | `index`, `new`, `create`, `destroy` |
| **Invitee** (recipient) | Accept page (auto-accept, login, or registration) | `show`, `update` |

```ruby
resources :invites, param: :token, only: %i[index new create show update destroy]
```

- `index` — team page: members + pending invites (authenticated)
- `new/create` — invite form (authenticated)
- `show` — accept page: auto-accept, login redirect, or registration (mixed auth)
- `update` — registration form submit for new users (unauthenticated)
- `destroy` — revoke (authenticated, by token)

No `edit` — delete and re-create to change a role.

---

## The three accept states

All accept traffic goes to `GET /invites/:token` on the app subdomain.

### State 1: Logged in, email matches → auto-accept

```
Click link → GET /invites/:token
    ↓
Current.user exists, email matches invite → accept!
    ↓
AccountUser created → redirect to app root
```

### State 2: Logged in, wrong email → denied

```
Click link → GET /invites/:token
    ↓
Current.user exists, email doesn't match
    ↓
InvitePolicy#show? returns false → "You don't have permission"
```

### State 3: Not logged in, existing user → login redirect

```
Click link → GET /invites/:token
    ↓
Not authenticated, User exists with this email
    ↓
require_authentication kicks in → stores return_to
    ↓
User logs in → redirected back to /invites/:token
    ↓
Now State 1 → auto-accept
```

### State 4: Not logged in, no existing user → registration form

```
Click link → GET /invites/:token
    ↓
Not authenticated, no User with this email
    ↓
allow_unauthenticated_access lets them through
    ↓
Shows registration form (email from invite, not editable)
    ↓
PATCH /invites/:token → creates User + accepts invite
    ↓
Start session → redirect to app root
```

### How authentication works

```ruby
allow_unauthenticated_access only: %i[show update]
before_action :require_authentication_for_existing_users, only: :show
```

The custom `require_authentication_for_existing_users` checks if
a User with the invite's email exists. If yes → enforce auth
(standard redirect to login with return_to). If no → let through
for registration.

---

## Routes

Everything on the app subdomain. One resource block:

```ruby
constraints subdomain: "app" do
  scope module: "app" do
    # ... existing resources
    resources :invites, param: :token, only: %i[index new create show update destroy]
  end
end
```

---

## Invite model

```ruby
class Invite < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: "User"

  ROLES = %w[manager agent].freeze

  before_create :generate_token

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true
  validates :role, inclusion: { in: ROLES }
  validate :not_already_in_role

  scope :pending, -> { where(accepted_at: nil).where(created_at: 7.days.ago..) }
  scope :expired, -> { where(accepted_at: nil).where(created_at: ...7.days.ago) }

  def pending?
    accepted_at.nil? && created_at > 7.days.ago
  end

  def expired?
    accepted_at.nil? && created_at <= 7.days.ago
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    transaction do
      update!(accepted_at: Time.current)
      AccountUser.create!(account: account, user: user, role: role)
      link_agent_profile(user) if role == "agent"
    end
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def not_already_in_role
    existing_user = User.find_by(email_address: email)
    return unless existing_user

    if AccountUser.exists?(account: account, user: existing_user, role: role)
      errors.add(:email, "already has the #{role} role on this account")
    end
  end

  def link_agent_profile(user)
    agent = Agent.find_by(account: account, email: email)
    agent&.update!(user: user) if agent && agent.user_id.nil?
  end
end
```

### Key difference from v1: `not_already_in_role`

With multi-role AccountUser, the validation checks if the user
already has this specific role — not if they're a member at all.
An existing agent CAN be invited as manager (additional role).
An existing manager CANNOT be re-invited as manager (duplicate).

### Migration

```ruby
create_table :invites do |t|
  t.timestamps
  t.references :account, null: false, foreign_key: true
  t.references :invited_by, null: false, foreign_key: { to_table: :users }
  t.string :email, null: false
  t.string :role, null: false, default: "agent"
  t.string :token, null: false
  t.datetime :accepted_at
end
add_index :invites, :token, unique: true
add_index :invites, [ :account_id, :email ]
```

---

## InvitePolicy (Action Policy)

```ruby
class InvitePolicy < ApplicationPolicy
  # Inviter actions — role-based
  def index?   = user&.can_manage?(account)
  def new?     = user&.can_manage?(account)
  def destroy? = user&.can_manage?(account)

  def create?
    return true if user&.owner_of?(account)
    user&.can_manage?(account) && record.role == "agent"
  end

  # Invitee actions — identity-based
  # user.nil? = new user registration (unauthenticated, token is the auth)
  # user.email matches = the intended recipient
  # user.email doesn't match = wrong person, denied
  def show?
    user.nil? || user.email_address == record.email
  end

  def update?
    user.nil? || user.email_address == record.email
  end

  # Tenant scoping for index
  scope_for :active_record_relation do |relation|
    relation.where(account: account)
  end
end
```

### Why this works

- **Unauthenticated new user** (`user.nil?`) → `show?` and `update?`
  return true. The token lookup + `require_authentication_for_existing_users`
  before_action provide the security boundary. The policy just confirms
  "yes, an unauthenticated user may view this invite."

- **Logged-in correct user** → email matches, permitted.

- **Logged-in wrong user** → email doesn't match, denied. Action Policy
  raises `Unauthorized`, controller redirects with alert.

- **Inviter actions** → standard `can_manage?` checks via Authorizable
  concern. Owners can invite any role, managers can only invite agents.

---

## App::InvitesController

```ruby
module App
  class InvitesController < App::BaseController
    allow_unauthenticated_access only: %i[show update]
    before_action :set_invite, only: %i[show update destroy]
    before_action :require_authentication_for_existing_users, only: :show

    # GET /invites — team page (authenticated)
    def index
      @members = authorized_scope(AccountUser.all).includes(:user).order(:created_at)
      @invites = authorized_scope(Invite.all).pending.order(created_at: :desc)
    end

    # GET /invites/new — invite form (authenticated)
    def new
      @invite = Invite.new(account: Current.account, role: "agent")
      authorize! @invite
    end

    # POST /invites — send invite (authenticated)
    def create
      @invite = Invite.new(invite_params)
      @invite.account = Current.account
      @invite.invited_by = Current.user
      authorize! @invite

      if @invite.save
        InviteMailer.invite(@invite).deliver_later
        redirect_to invites_path, notice: "Invite sent to #{@invite.email}."
      else
        render :new, status: :unprocessable_content
      end
    end

    # GET /invites/:token — accept page (mixed auth)
    def show
      authorize! @invite

      if @invite.expired?
        render :expired, layout: "public"
        return
      end

      if @invite.accepted?
        redirect_to app_root_path, notice: "This invite has already been accepted."
        return
      end

      if Current.user
        @invite.accept!(Current.user)
        redirect_to app_root_path, notice: "You've joined the team."
        return
      end

      # New user — show registration form
      @user = User.new
    end

    # PATCH /invites/:token — register + accept (unauthenticated)
    def update
      authorize! @invite

      if @invite.expired? || @invite.accepted?
        redirect_to app_root_path, alert: "This invite is no longer valid."
        return
      end

      @user = User.new(user_params)
      @user.email_address = @invite.email

      if @user.save
        @invite.accept!(@user)
        start_new_session_for(@user)
        redirect_to app_root_path, notice: "Welcome! You've joined the team."
      else
        render :show, status: :unprocessable_content
      end
    end

    # DELETE /invites/:token — revoke (authenticated)
    def destroy
      authorize! @invite
      @invite.destroy
      redirect_to invites_path, notice: "Invite revoked."
    end

    private

    def set_invite
      @invite = Invite.find_by!(token: params[:token])
    end

    def require_authentication_for_existing_users
      return if Current.user
      return unless User.exists?(email_address: @invite.email)

      require_authentication
    end

    def invite_params
      params.require(:invite).permit(:email, :role)
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :phone,
        :password, :password_confirmation
      )
    end
  end
end
```

### Auth split

| Action | Auth | Why |
|--------|------|-----|
| `index` | Required | Team page, needs Current.account |
| `new` | Required | Creating invite, needs Current.account |
| `create` | Required | Creating invite, needs Current.account |
| `show` | Conditional | Existing users → login redirect. New users → registration form. Wrong user → policy denies. |
| `update` | None | Registration form submission for new users. Policy checks `user.nil?`. |
| `destroy` | Required | Revoking invite, needs Current.account |

---

## InviteMailer

```ruby
class InviteMailer < ApplicationMailer
  def invite(invite)
    @invite = invite
    @accept_url = invite_url(token: invite.token, subdomain: "app")

    mail(
      to: invite.email,
      subject: "You're invited to RePlay"
    )
  end
end
```

### Email template

```erb
<%# app/views/invite_mailer/invite.html.erb %>
<h2 style="margin: 0 0 16px; font-size: 20px; color: #111827;">
  You've been invited to RePlay
</h2>

<p style="font-size: 14px; color: #374151; margin-bottom: 16px;">
  <%= @invite.invited_by.first_name %> <%= @invite.invited_by.last_name %>
  has invited you to join their team as
  <strong><%= @invite.role.capitalize %></strong>.
</p>

<a href="<%= @accept_url %>"
   style="display: inline-block; background: #4f46e5; color: #fff;
          padding: 12px 24px; border-radius: 6px; text-decoration: none;
          font-size: 14px; font-weight: 600;">
  Accept Invite
</a>

<p style="margin-top: 24px; font-size: 12px; color: #9ca3af;">
  This invite expires in 7 days. If you didn't expect this email,
  you can safely ignore it.
</p>
```

### Mailer preview

```ruby
class InviteMailerPreview < ActionMailer::Preview
  def invite
    invite = Invite.first || FactoryBot.create(:invite)
    InviteMailer.invite(invite)
  end
end
```

---

## Team page (index view)

Shows current members (with all their roles) and pending invites.

```
┌─────────────────────────────────────────────────────────┐
│  Team                          [Invite user]            │
├─────────────────────────────────────────────────────────┤
│  Members                                                │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Demo Owner     demo@example.com     Owner         │  │
│  │ Morgan Manager manager@example.com  Manager,Agent │  │
│  │ Jane Broker    jane.broker@...      Agent         │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  Pending Invites                                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │ tom@example.com   Agent   2 days ago   [Revoke]   │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

Members are grouped by user (not by AccountUser row) so multi-role
users show all their roles in one line.

---

## Accept page (show view)

Registration form for new users. Email from the invite, not editable.

```erb
<%# app/views/app/invites/show.html.erb %>
<div class="max-w-md mx-auto">
  <h1 class="text-2xl font-extrabold tracking-tight mb-2">Join RePlay</h1>
  <p class="text-sm text-gray-600 mb-6">
    You've been invited as <strong><%= @invite.role.capitalize %></strong>
    by <%= @invite.invited_by.first_name %>.
  </p>

  <%= form_with model: @user, url: invite_path(token: @invite.token),
      method: :patch do |f| %>
    <div class="mb-4">
      <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
      <p class="text-sm text-gray-900 py-2 px-3 bg-gray-50 rounded-md"><%= @invite.email %></p>
    </div>

    <div class="grid grid-cols-2 gap-3 mb-4">
      <div>
        <%= f.label :first_name, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.text_field :first_name, required: true,
            class: "block w-full rounded-md bg-white px-3 py-2 text-sm text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600" %>
      </div>
      <div>
        <%= f.label :last_name, class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= f.text_field :last_name, required: true,
            class: "block w-full rounded-md bg-white px-3 py-2 text-sm text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600" %>
      </div>
    </div>

    <div class="mb-4">
      <%= f.label :phone, class: "block text-sm font-medium text-gray-700 mb-1" %>
      <%= f.telephone_field :phone,
          class: "block w-full rounded-md bg-white px-3 py-2 text-sm text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600" %>
    </div>

    <div class="mb-4">
      <%= f.label :password, class: "block text-sm font-medium text-gray-700 mb-1" %>
      <%= f.password_field :password, required: true,
          class: "block w-full rounded-md bg-white px-3 py-2 text-sm text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600" %>
    </div>

    <div class="mb-6">
      <%= f.label :password_confirmation, class: "block text-sm font-medium text-gray-700 mb-1" %>
      <%= f.password_field :password_confirmation, required: true,
          class: "block w-full rounded-md bg-white px-3 py-2 text-sm text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600" %>
    </div>

    <%= f.submit "Join",
        class: "w-full rounded-md bg-indigo-600 px-3 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 cursor-pointer" %>
  <% end %>
</div>
```

---

## Expired page

```erb
<%# app/views/app/invites/expired.html.erb %>
<div class="max-w-md mx-auto text-center py-20">
  <h1 class="text-2xl font-extrabold mb-2">Invite expired</h1>
  <p class="text-sm text-gray-600">
    This invite is no longer valid. Ask the person who invited you
    to send a new one.
  </p>
</div>
```

---

## Sidebar link

Add "Team" to the sidebar, visible to managers and owners:

```erb
<% if allowed_to?(:index?, Invite) %>
  <li>
    <% active = controller_name == 'invites' %>
    <%= link_to invites_path, class: "..." do %>
      <svg ...></svg>
      Team
    <% end %>
  </li>
<% end %>
```

---

## Agent auto-linking

When an agent-role invite is accepted, `Invite#accept!` checks
if an `Agent` record exists on the account with the same email.
If so, it links the new User to that Agent via `agent.user = user`.

This handles the common case: a brokerage adds agents to listings
before those agents have RePlay logins. When the agent eventually
accepts their invite, their Agent profile is automatically connected.

---

## AccountUser policy for index scoping

The team page uses `authorized_scope(AccountUser.all)` to list
members. Need an AccountUser policy with tenant scoping:

```ruby
class AccountUserPolicy < ApplicationPolicy
  scope_for :active_record_relation do |relation|
    relation.where(account: account)
  end
end
```

---

## What this does NOT do

- **Bulk invites** — one at a time. Bulk CSV upload is future.
- **Resend invite** — destroy and re-create.
- **Role change for existing members** — not part of invites. Future team management.
- **Remove member** — destroy AccountUser. Separate from revoking an invite.
- **Account name** — the accept flow says "the team" since Account has no name field yet.
- **Multiple owners** — invites only allow manager/agent roles.
- **Account switcher** — multi-account users see their first account. Future enhancement.

---

## Build order

### Phase 1 — Invite model
1. Invite model — migration, validations, scopes, `accept!` method (RED/GREEN)
2. Factory for `:invite`
3. `not_already_in_role` validation — allows additional roles (RED/GREEN)
4. Agent auto-linking on accept (RED/GREEN)

### Phase 2 — Team management (authenticated actions)
5. `InvitePolicy` + spec — `can_manage?`, `owner_of?`, identity checks on show/update (RED/GREEN)
6. `AccountUserPolicy` with scope for team page (RED/GREEN)
7. `App::InvitesController` — index, new, create, destroy (RED/GREEN)
8. Team index view — members grouped by user with all roles + pending invites
9. Invite form — email + role select
10. Sidebar "Team" link with `allowed_to?(:index?, Invite)`

### Phase 3 — Accept flow (show + update)
11. `show` action — four states: auto-accept, wrong-user denied, login redirect, registration form (RED/GREEN)
12. `update` action — registration submit + accept (RED/GREEN)
13. `require_authentication_for_existing_users` before_action
14. Show view — registration form with email locked
15. Expired view

### Phase 4 — Email
16. `InviteMailer#invite` with HTML template
17. Mailer preview
18. Deliver on invite creation

### Phase 5 — Polish
19. Administrate dashboard for Invite
20. Admin route for invites
21. Seeds — create a pending invite for demo
22. Rack::Attack throttle on invite creation (5/hour per IP)

---

## What changed from v1

- **Action Policy instead of Pundit** — `authorize!`, `authorized_scope`, `allowed_to?` instead of `authorize`, `policy_scope`, `policy()`. Policy receives `user` and `account` as explicit context.
- **Identity check in policy** — `show?` and `update?` check `user.nil? || user.email_address == record.email`. Wrong-user access is denied by the policy, not custom controller logic.
- **Policy-owned tenant scoping** — `authorized_scope(Invite.all)` and `authorized_scope(AccountUser.all)` instead of `Current.account.invites`.
- **Multi-role aware validation** — `not_already_in_role` checks for duplicate role, not duplicate membership. An agent can be invited as manager.
- **State 2 (wrong user) added** — logged-in user with non-matching email is denied by the policy. v1 didn't handle this.
- **AccountUserPolicy added** — needed for `authorized_scope(AccountUser.all)` on the team page.
- **Team page shows multi-role** — members grouped by user, showing all roles.

---

## Dependencies

- **RBAC with multi-role (done)** — AccountUser allows multiple roles per user per account
- **Action Policy (done)** — policies with `authorize :user, :account` context
- **Authorizable concern (done)** — `can_manage?`, `owner_of?`, `has_role?` on User
- **Letter Opener Web (done)** — for testing invite emails in dev
- **Rack::Attack (done)** — for throttling invite creation
