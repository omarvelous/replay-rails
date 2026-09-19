# Plan: Split InvitesController into Invites + InviteRegistrations

## Context

`InvitesController` handles two distinct concerns with different
auth contexts:
- **Inviting** (managers send, resend, revoke) — requires authentication + membership
- **Registering** (invitees view and accept) — unauthenticated or self-authenticated

This forces `ApplicationPolicy` to make `account_user` optional
and use safe navigation (`&.`) everywhere. Splitting the controller
lets each side own its auth cleanly.

Branch from: `feature/single-account-user` (PR #76)

---

## What Changes

### New Controller: `App::InviteRegistrationsController`

Handles the invitee's experience — viewing and accepting an invite.

```ruby
module App
  class InviteRegistrationsController < BaseController
    allow_unauthenticated_access

    def show
      @invite = find_invite
      # If already logged in and email matches, auto-accept
      if Current.user&.email_address == @invite.email
        AcceptInvite.new(invite: @invite, user: Current.user).call
        redirect_to app_root_path, notice: "You've joined the team."
        return
      end
      # If logged in but wrong email, deny
      if Current.user
        redirect_to app_root_path, alert: "This invite is for #{@invite.email}."
        return
      end
      # Not logged in — show registration form
      @user = User.new
    end

    def update
      @invite = find_invite
      @user = User.new(user_params)
      @user.email_address = @invite.email

      if @user.save
        AcceptInvite.new(invite: @invite, user: @user).call
        start_new_session_for(@user)
        redirect_to app_root_path, notice: "Welcome! You've joined the team."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

      def find_invite
        invite = Invite.find_by!(token: params[:token])
        redirect_to app_root_path, notice: "This invite has already been accepted." if invite.accepted?
        redirect_to app_root_path, alert: "This invite is no longer valid." if invite.expired?
        invite
      end

      def user_params
        params.require(:user).permit(:first_name, :last_name, :phone, :password, :password_confirmation)
      end
  end
end
```

**No `authorize!` calls** — this controller doesn't check roles.
It checks identity (email match) and invite state (pending/expired).
No policy needed.

### Slimmed `App::InvitesController`

Keeps only the inviter's actions — all require membership:

```ruby
module App
  class InvitesController < BaseController
    def index
      authorize! Invite
      @invites = Current.account.invites.pending.order(created_at: :desc)
    end

    def new
      @invite = Current.account.invites.build
      authorize! @invite
    end

    def create
      @invite = Current.account.invites.build(invite_params)
      @invite.invited_by = Current.user
      authorize! @invite
      # ...
    end

    def destroy
      @invite = Current.account.invites.find_by_param!(params[:token])
      authorize! @invite
      @invite.destroy
      redirect_to invites_path, notice: t(".success")
    end

    def resend
      @invite = Current.account.invites.find_by_param!(params[:token])
      authorize! @invite
      # ...
    end
  end
end
```

No `allow_unauthenticated_access`. No `skip_before_action`. Every
action goes through `authorize!` which requires `account_user`.

### Routes

```ruby
# Before
resources :invites, param: :token, only: %i[index new create show update destroy] do
  member { post :resend }
end

# After
resources :invites, param: :token, only: %i[index new create destroy] do
  member { post :resend }
end
resource :invite_registration, only: %i[show update], param: :token,
         path: "invites/:token/register"
```

### ApplicationPolicy — Remove Optional

Once the split is done, `ApplicationPolicy` can require all
contexts:

```ruby
authorize :user, :account, :account_user
```

No `optional: true`. No `&.` in convenience methods. The
`InviteRegistrationsController` doesn't call `authorize!` so
it never hits the policy.

### InvitePolicy — Simplified

Only inviter actions remain:

```ruby
class InvitePolicy < ApplicationPolicy
  def index?   = manager_or_above?
  def create?  = owner? || (manager_or_above? && record.role == "agent")
  def resend?  = manager_or_above?
  def destroy? = manager_or_above?
end
```

No `show?` or `update?` — those moved to the registration
controller which doesn't use policies.

---

## Views

### Move invite acceptance views

```
app/views/app/invites/show.html.erb
  → app/views/app/invite_registrations/show.html.erb
```

The show template renders the invite details + registration form.
The invites index/new/create views stay with InvitesController.

---

## Specs

### New spec: `spec/requests/invite_registrations_spec.rb`

Tests: view invite, auto-accept for logged-in user, register new
user, expired invite, wrong email.

### Updated: `spec/requests/invites_spec.rb`

Remove show/update tests (moved to registration spec). Keep
index, create, destroy, resend.

### Remove: `spec/requests/invite_accept_spec.rb`

Merged into `invite_registrations_spec.rb`.

---

## Build Order

```
1. Create InviteRegistrationsController with show/update
2. Move show/update logic from InvitesController
3. Update routes
4. Move views
5. Update/create specs
6. COMMIT

7. Remove optional: true from ApplicationPolicy
8. Remove &. from convenience methods
9. Simplify InvitePolicy (remove show?/update?)
10. Update policy specs
11. COMMIT
```

---

## Verification

1. `make test` — green
2. Invite link (`/invites/:token/register`) renders registration form
3. Auto-accept works for logged-in user with matching email
4. Manager can create/resend/revoke invites
5. ApplicationPolicy has no `optional:` or `&.`
