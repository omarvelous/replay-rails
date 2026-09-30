# Plan: In-App Notifications

**Created:** 2026-09-29
**Status:** Draft
**Branch:** `feature/notifications`

## Problem

Users have no visibility into what's happening on their account
unless they're actively looking at the right page. New leads arrive
silently. Players go offline unnoticed. QR milestones pass without
celebration. The only notifications are email — no in-app awareness.

## Goals

1. Notification bell in sidebar with unread count
2. Notification inbox page (`/notifications`)
3. Real-time delivery via ActionCable (no page refresh needed)
4. Optional email delivery per notification type
5. Mark as read (individual + bulk)
6. Extensible — adding a new event type should be a one-liner

## Design

### Notification Model

```ruby
# db/migrate/..._create_notifications.rb
create_table :notifications do |t|
  t.timestamps
  t.references :account, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.string :category, null: false        # "lead", "player", "milestone", "team"
  t.string :title, null: false
  t.text :body
  t.string :url                          # in-app path to navigate to
  t.string :icon                         # optional icon identifier
  t.datetime :read_at
  t.references :source, polymorphic: true # Lead, Player, QrCode, etc.
end

add_index :notifications, [:user_id, :read_at]
add_index :notifications, [:account_id, :created_at]
```

**Key decisions:**
- Scoped to both `account` AND `user` — notifications belong to an
  account and are delivered to specific users within that account.
  Different roles get different notifications (agents get their leads,
  owners get everything).
- Inbox is filtered by `current_account` — switching accounts changes
  which notifications you see and the unread count in the bell.
- `source` is polymorphic — links back to the record that triggered it
- `category` for grouping/filtering in the inbox
- `url` is a relative path — clicking a notification navigates there
- `read_at` null = unread, timestamp = read

### NotificationService

Single entry point for creating notifications. Handles both in-app
and optional email delivery.

```ruby
# app/services/notify.rb
class Notify
  def self.call(account:, user:, category:, title:, body: nil, url: nil, source: nil, icon: nil, email: false)
    notification = Notification.create!(
      account: account,
      user: user,
      category: category,
      title: title,
      body: body,
      url: url,
      source: source,
      icon: icon
    )

    # Broadcast to user's channel with account_id so JS can filter
    NotificationsChannel.broadcast_to(user, {
      notification: notification.as_json,
      account_id: account.id
    })

    # Optional email
    NotificationMailer.notify(notification).deliver_later if email

    notification
  end
end
```

**Account is always explicit** — callers must pass the account.
This prevents ambiguity when a user belongs to multiple accounts.

### ActionCable Channel

```ruby
# app/channels/notifications_channel.rb
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

Broadcasts push notification data to the user's browser. The
Stimulus controller receives it and updates the bell badge count +
optionally shows a toast.

### Stimulus Controller

```javascript
// app/javascript/controllers/notifications_controller.js
// Connects to NotificationsChannel
// Values: currentAccountId (from data attribute)
// Targets: badge (bell count), toast (optional popup)
// On receive: check if msg.account_id matches currentAccountId
//   - if match: increment badge, show toast with title + url
//   - if no match: ignore (notification is for a different account)
// On click notification: mark as read via PATCH, navigate to url
```

### Sidebar Bell

Replace the static leads badge approach with a notification bell
next to the user avatar at the bottom of the sidebar.

```erb
<%# Bell with unread count (scoped to current account) %>
<%= link_to notifications_path do %>
  <svg><!-- bell icon --></svg>
  <% count = current_user.notifications.where(account: current_account).unread.count %>
  <% if count.positive? %>
    <span class="badge"><%= count %></span>
  <% end %>
<% end %>
```

### Notifications Controller

```ruby
# app/controllers/app/notifications_controller.rb
module App
  class NotificationsController < BaseController
    def index
      @notifications = current_user.notifications
        .where(account: current_account)
        .order(created_at: :desc)
      @pagy, @notifications = pagy(@notifications)
    end

    def update  # mark as read
      @notification = current_user.notifications
        .where(account: current_account)
        .find(params[:id])
      @notification.update!(read_at: Time.current)
      # Turbo Stream or redirect
    end

    def read_all
      current_user.notifications
        .where(account: current_account)
        .unread
        .update_all(read_at: Time.current)
      redirect_to notifications_path
    end
  end
end
```

All queries scoped to `current_account` — switching accounts
changes which notifications you see.

### Notification Events

Phase 1 — ship with these events:

| Event | Category | Recipients | Email? | Trigger |
|-------|----------|-----------|--------|---------|
| New lead | `lead` | Assigned agent, or owner | Yes (already exists via LeadMailer) | `CaptureLead` service |
| Player offline | `player` | Owner + managers | No (first version) | `PlayerOfflineCheckJob` |
| Player back online | `player` | Owner + managers | No | `RecordHeartbeat` service |
| Invite accepted | `team` | Inviter | No (email already exists) | `AcceptInvite` service |
| QR milestone | `milestone` | Owner | Yes | `QrMilestoneCheckJob` |

Phase 2 (later):
- Lead status changed to qualified
- Screen content changed
- Subscription renewal reminder
- User notification preferences (opt in/out per category)

### Player Offline Detection

Currently there's no job that checks for offline players. Add:

```ruby
# app/jobs/player_offline_check_job.rb
class PlayerOfflineCheckJob < ApplicationJob
  def perform
    # Find players that were online 15 min ago but aren't now
    Player.joins(:active_assignment)
      .where(last_heartbeat_at: 16.minutes.ago..15.minutes.ago)
      .find_each do |player|
        screen = player.screen
        account = screen.site.account

        account.users.joins(:account_users)
          .where(account_users: { role: %w[owner manager] })
          .find_each do |user|
            Notify.call(
              account: account,
              user: user,
              category: "player",
              title: "#{screen.name} went offline",
              body: "The player on #{screen.name} hasn't sent a heartbeat in 15 minutes.",
              url: "/screens/#{screen.to_param}",
              source: player
            )
          end
      end
  end
end
```

Schedule: every 5 minutes in `recurring.yml`.

### QR Milestone Detection

```ruby
# app/jobs/qr_milestone_check_job.rb
class QrMilestoneCheckJob < ApplicationJob
  MILESTONES = [100, 500, 1000, 5000].freeze

  def perform
    QrCode.find_each do |qr|
      count = qr.scan_count
      milestone = MILESTONES.find { |m| count >= m && count < m + 10 }
      next unless milestone
      next if Notification.exists?(source: qr, title: "#{milestone} scans!")

      Notify.call(
        account: qr.account,
        user: qr.account.users.joins(:account_users)
              .find_by(account_users: { role: "owner" }),
        category: "milestone",
        title: "#{qr.label} hit #{milestone} scans!",
        url: "/qr_codes/#{qr.to_param}",
        source: qr,
        email: true
      )
    end
  end
end
```

Schedule: daily at 8am in `recurring.yml`.

### NotificationMailer

Generic mailer for notification-triggered emails. Reuses the branded
layout. Simple: title as heading, body as paragraph, CTA button
linking to `url`.

```ruby
class NotificationMailer < ApplicationMailer
  def notify(notification)
    @notification = notification
    mail(
      to: notification.user.email_address,
      subject: notification.title
    )
  end
end
```

## Execution

### Phase 1 — Model + Service + Bell

```
1. RED:  Notification model spec (validations, scopes)
   GREEN: Migration, model, factory
   COMMIT

2. RED:  Notify service spec
   GREEN: Notify service
   COMMIT

3. RED:  NotificationsController spec (index, update, read_all)
   GREEN: Controller, views, routes
   COMMIT

4. Add notification bell to sidebar + unread count
   COMMIT
```

### Phase 2 — Real-time

```
5. NotificationsChannel + Stimulus controller
   Bell updates in real-time on broadcast
   COMMIT

6. Toast/popup on new notification (optional, can defer)
   COMMIT
```

### Phase 3 — Wire up events

```
7. Wire CaptureLead → Notify (new lead)
   COMMIT

8. Wire AcceptInvite → Notify (invite accepted, skip email since
   InviteMailer#accepted already handles it)
   COMMIT

9. PlayerOfflineCheckJob + schedule
   COMMIT

10. Player back online → Notify from RecordHeartbeat
    COMMIT

11. QrMilestoneCheckJob + schedule
    COMMIT
```

### Phase 4 — Polish

```
12. NotificationMailer (generic, for email: true notifications)
    COMMIT

13. Notification previews + specs for all events
    COMMIT

14. make lint, make test
    Docs + promote plan
    COMMIT
```

## Out of Scope

- User notification preferences (opt in/out per category)
- Push notifications (browser/mobile)
- Notification digest emails (daily/weekly summary)
- Slack/webhook integrations
- SMS notifications
- Read receipts / delivery tracking

## Verification

1. `make test` — green
2. `make lint` — clean
3. Create a lead → notification appears in bell without refresh
4. Pair then unplug a player → offline notification after 15 min
5. `/notifications` shows full inbox with read/unread states
6. "Mark all read" clears the badge
7. Click a notification → navigates to the source record
