# Plan: Player Pairing Flow (v3 — ScreenPlayer join model)

_Supersedes `plan-player-pairing.md` and `plan-player-pairing-v2.md`._

## What changed

- **Player stays as its own model** — a physical device with its own lifecycle,
  provisioned by RePlay, shipped to customers.
- **ScreenPlayer join model** — the pairing is a relationship record, not a FK
  on Player. Unpairing deactivates the record (history preserved). Re-pairing
  creates a new record.
- **Minor updates for current codebase** — layout partials handle ad rendering
  (no eager loading of old `listing` association), QR codes render with screen
  attribution via `src=Screen.#{id}`.

---

## The three models

```
Player        — the physical device (token, firmware, heartbeat)
Screen        — the display config (name, orientation, site)
ScreenPlayer  — the active pairing + history
```

**Player** is account-agnostic until paired. It's a device that exists in the
world. It gets provisioned, shipped, and boots up showing a pairing code.

**Screen** belongs to a Site, which belongs to an Account. It represents the
logical display: "Window Display at Main Office."

**ScreenPlayer** is the event: "this player was paired to this screen at this
time by this user." Unpairing sets `active: false` and `unpaired_at`. The
record stays for history. Re-pairing creates a new `ScreenPlayer`.

---

## `Player` model

The device. No `screen_id` — the relationship lives on `ScreenPlayer`.

```ruby
# migration
create_table :players do |t|
  t.timestamps
  t.string   :token,            null: false
  t.string   :pairing_code
  t.datetime :pairing_code_expires_at
  t.datetime :last_heartbeat_at
  t.string   :ip_address
  t.string   :user_agent
  t.string   :firmware_version
end
add_index :players, :token, unique: true
add_index :players, :pairing_code, unique: true
```

```ruby
# app/models/player.rb
class Player < ApplicationRecord
  has_many :screen_players, dependent: :destroy
  has_one  :active_assignment, -> { active }, class_name: "ScreenPlayer"
  has_one  :screen, through: :active_assignment

  before_validation :generate_token, on: :create
  before_validation :generate_pairing_code, on: :create

  validates :token, uniqueness: true

  def paired?
    active_assignment.present?
  end

  def pairing_code_valid?
    pairing_code.present? && pairing_code_expires_at&.future?
  end

  def online?
    paired? && last_heartbeat_at.present? && last_heartbeat_at > 2.minutes.ago
  end

  def refresh_pairing_code!
    update!(
      pairing_code: SecureRandom.alphanumeric(6).upcase,
      pairing_code_expires_at: 10.minutes.from_now
    )
  end

  private

    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(32)
    end

    def generate_pairing_code
      self.pairing_code ||= SecureRandom.alphanumeric(6).upcase
      self.pairing_code_expires_at ||= 10.minutes.from_now
    end
end
```

---

## `ScreenPlayer` model

The pairing record. One active pairing per screen, one active pairing per player.

```ruby
# migration
create_table :screen_players do |t|
  t.timestamps
  t.references :screen, null: false, foreign_key: true
  t.references :player, null: false, foreign_key: true
  t.references :paired_by, foreign_key: { to_table: :users }
  t.boolean    :active, null: false, default: true
  t.datetime   :unpaired_at
end
add_index :screen_players, [ :screen_id, :active ], where: "active = true", unique: true,
          name: "idx_screen_players_active_screen"
add_index :screen_players, [ :player_id, :active ], where: "active = true", unique: true,
          name: "idx_screen_players_active_player"
```

```ruby
# app/models/screen_player.rb
class ScreenPlayer < ApplicationRecord
  belongs_to :screen
  belongs_to :player
  belongs_to :paired_by, class_name: "User", optional: true

  scope :active, -> { where(active: true) }
  scope :history, -> { where(active: false) }

  def unpair!
    update!(active: false, unpaired_at: Time.current)
  end
end
```

---

## Updated `Screen` model

```ruby
# app/models/screen.rb (additions)
has_many :screen_players, dependent: :destroy
has_one  :active_player_assignment, -> { active }, class_name: "ScreenPlayer"
has_one  :player, through: :active_player_assignment

def paired?
  player.present?
end

def online?
  player&.online?
end

def pair_player!(player, paired_by: nil)
  # Deactivate any existing pairing on this screen
  active_player_assignment&.unpair!

  # Deactivate any existing pairing on the player
  player.active_assignment&.unpair!

  # Create the new pairing
  screen_players.create!(
    player: player,
    paired_by: paired_by
  )

  # Clear the pairing code — it's been used
  player.update!(pairing_code: nil, pairing_code_expires_at: nil)
end

def unpair_player!
  active_player_assignment&.unpair!
end
```

---

## Routes

```ruby
# Device-facing (no session auth — token-based)
scope "/player" do
  post "/register",  to: "player_api#register"
  get  "/status",    to: "player_api#status"
  get  "/play",      to: "player_api#play"
  post "/heartbeat", to: "player_api#heartbeat"
end

# Admin pairing
resources :screens do
  resource :pairing, only: %i[ new create destroy ], controller: "screen_pairings"
end
```

---

## PlayerApi controller (device-facing)

```ruby
# app/controllers/player_api_controller.rb
class PlayerApiController < ActionController::Base
  before_action :authenticate_player!, only: %i[ play heartbeat ]

  # POST /player/register
  # Device boots up, creates a Player record with a pairing code.
  def register
    player = Player.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    render json: {
      pairing_code: player.pairing_code,
      expires_in: 600,
      token: player.token
    }
  end

  # GET /player/status
  # Device polls while showing the pairing code.
  def status
    player = Player.find_by!(pairing_code: params[:code]&.upcase)

    if player.paired?
      render json: {
        paired: true,
        token: player.token,
        screen_id: player.screen.id
      }
    else
      render json: { paired: false }
    end
  end

  # GET /player/play
  # Serves the playlist for the paired screen.
  def play
    screen = @player.screen

    unless screen
      return render "player_api/unpaired", layout: "player"
    end

    playlist = screen.screen_playlists.find_by(active: true)&.playlist

    if playlist
      @playlist_ads = playlist.playlist_ads.includes(:ad).order(:position)
      @screen = screen
      render "player_api/play", layout: "player"
    else
      render "player_api/idle", layout: "player"
    end
  end

  # POST /player/heartbeat
  def heartbeat
    @player.update!(
      last_heartbeat_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    render json: { ok: true }
  end

  private

    def authenticate_player!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")
      @player = Player.find_by(token: token)
      render json: { error: "Unauthorized" }, status: :unauthorized unless @player
    end
end
```

---

## ScreenPairings controller (admin-facing)

```ruby
# app/controllers/screen_pairings_controller.rb
class ScreenPairingsController < ApplicationController
  before_action :set_screen

  # GET /screens/:screen_id/pairing/new
  def new
  end

  # POST /screens/:screen_id/pairing
  def create
    player = Player.find_by(pairing_code: params[:code]&.strip&.upcase)

    if player.nil?
      flash[:alert] = "Code not found. Check the TV and try again."
      return redirect_to new_screen_pairing_path(@screen)
    end

    unless player.pairing_code_valid?
      flash[:alert] = "That code has expired. Restart the device to get a new one."
      return redirect_to new_screen_pairing_path(@screen)
    end

    @screen.pair_player!(player, paired_by: Current.user)

    ActionCable.server.broadcast(
      "pairing_#{player.pairing_code}",
      { paired: true, token: player.token, screen_id: @screen.id }
    )

    redirect_to @screen, notice: "Player paired successfully."
  end

  # DELETE /screens/:screen_id/pairing
  def destroy
    @screen.unpair_player!
    redirect_to @screen, notice: "Player unpaired."
  end

  private

    def set_screen
      @screen = Current.account.screens.find(params[:screen_id])
    end
end
```

---

## ActionCable channels

### PairingChannel (anonymous)

```ruby
# app/channels/pairing_channel.rb
class PairingChannel < ActionCable::Channel::Base
  def subscribed
    code = params[:code]
    stream_from "pairing_#{code}" if code.present?
  end
end
```

### ScreenChannel (token-authenticated)

```ruby
# app/channels/screen_channel.rb
class ScreenChannel < ActionCable::Channel::Base
  def subscribed
    token = params[:token]
    player = Player.find_by(token: token)
    return reject unless player&.paired?

    stream_from "screen_#{player.screen.id}"
  end
end
```

### Broadcast on playlist change

```ruby
# app/models/screen_playlist.rb
after_commit :notify_player, on: %i[ create update destroy ]

private

  def notify_player
    ActionCable.server.broadcast("screen_#{screen_id}", { event: "playlist_changed" })
  end
```

### ApplicationCable::Connection

Allow anonymous connections for players:

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    rescue
      # Allow anonymous connections — PairingChannel and ScreenChannel
      # authenticate via their own params
    end

    private

      def find_verified_user
        if session = Session.find_by(id: cookies.signed[:session_id])
          session.user
        end
      end
  end
end
```

---

## Device-side JavaScript

### Pairing controller

```javascript
// app/javascript/controllers/device_pairing_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = { code: String, token: String }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "PairingChannel", code: this.codeValue },
      { received: (data) => { if (data.paired) this.onPaired(data.token) } }
    )
    this.poll = setInterval(() => this.checkStatus(), 3000)
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.poll)
  }

  async checkStatus() {
    const res = await fetch(`/player/status?code=${this.codeValue}`)
    const data = await res.json()
    if (data.paired) this.onPaired(data.token)
  }

  onPaired(token) {
    clearInterval(this.poll)
    this.subscription?.unsubscribe()
    localStorage.setItem("player_token", token)
    window.location.href = "/player/play"
  }
}
```

### Playback controller

```javascript
// app/javascript/controllers/device_playback_controller.js
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  connect() {
    const token = localStorage.getItem("player_token")
    this.subscription = consumer.subscriptions.create(
      { channel: "ScreenChannel", token },
      {
        received: ({ event }) => {
          if (event === "playlist_changed") window.location.reload()
        }
      }
    )
    this.heartbeat = setInterval(() => this.sendHeartbeat(token), 30_000)
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.heartbeat)
  }

  async sendHeartbeat(token) {
    await fetch("/player/heartbeat", {
      method: "POST",
      headers: { "Authorization": `Bearer ${token}` }
    })
  }
}
```

---

## Views

### Player layout

```erb
<%# app/views/layouts/player.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= stylesheet_link_tag :app %>
    <%= javascript_importmap_tags %>
  </head>
  <body class="bg-black min-h-screen overflow-hidden">
    <%= yield %>
  </body>
</html>
```

### Pairing screen (`player_api/register`)

```erb
<div class="flex flex-col items-center justify-center h-screen text-white gap-8"
     data-controller="device-pairing"
     data-device-pairing-code-value="<%= @player.pairing_code %>"
     data-device-pairing-token-value="<%= @player.token %>">
  <p class="text-sm uppercase tracking-widest text-white/40 font-semibold">Pair this screen</p>
  <div class="font-mono text-7xl font-bold tracking-widest"><%= @player.pairing_code %></div>
  <p class="text-sm text-white/30 font-semibold">Enter this code at replay.com &rarr; Screens</p>
  <p class="text-xs text-white/20 mt-8">Code expires in 10 minutes</p>
</div>
```

### Playback (`player_api/play`)

```erb
<div data-controller="device-playback">
  <div class="w-full h-screen flex items-center justify-center relative"
       data-controller="slideshow">
    <% @playlist_ads.each_with_index do |pa, index| %>
      <div class="slide absolute inset-0 transition-opacity duration-700 <%= index == 0 ? 'opacity-100' : 'opacity-0' %>"
           style="z-index: 1; contain: content;"
           data-slideshow-target="slide"
           data-duration="<%= pa.duration %>">
        <%= render "ads/layouts/#{pa.ad.layout}", ad: pa.ad %>
      </div>
    <% end %>

    <div style="position: absolute; bottom: 0; left: 0; width: 100%; height: 4px; background: rgba(255,255,255,0.1); z-index: 10;">
      <div style="height: 100%; width: 100%; transform: scaleX(0); transform-origin: left; background: rgba(255,255,255,0.5);"
           data-slideshow-target="progress"></div>
    </div>
  </div>
</div>
```

### Idle screen (`player_api/idle`)

```erb
<div class="flex flex-col items-center justify-center h-screen text-white gap-4">
  <p class="text-2xl text-white/30 font-semibold">No content assigned</p>
  <p class="text-sm text-white/20 font-semibold">Assign a playlist to this screen in the dashboard</p>
</div>
```

### Unpaired screen (`player_api/unpaired`)

```erb
<div class="flex flex-col items-center justify-center h-screen text-white gap-4">
  <p class="text-2xl text-white/30 font-semibold">Player not paired</p>
  <p class="text-sm text-white/20 font-semibold">This player has been unpaired from its screen</p>
</div>
```

---

## Screen show page updates

Replace the stubbed hardware sidebar section:

```erb
<div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5 p-5">
  <h3 class="text-sm font-semibold mb-3">Player</h3>
  <% if @screen.paired? %>
    <div class="divide-y divide-gray-200">
      <div class="flex justify-between py-2 text-sm">
        <span class="text-gray-500">Status</span>
        <% if @screen.online? %>
          <span class="inline-flex items-center gap-1.5 text-green-600 font-semibold">
            <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            Online
          </span>
        <% else %>
          <span class="text-red-600 font-semibold">Offline</span>
        <% end %>
      </div>
      <div class="flex justify-between py-2 text-sm">
        <span class="text-gray-500">Paired</span>
        <span><%= time_ago_in_words(@screen.active_player_assignment.created_at) %> ago</span>
      </div>
      <% if @screen.player.last_heartbeat_at %>
        <div class="flex justify-between py-2 text-sm">
          <span class="text-gray-500">Last heartbeat</span>
          <span><%= time_ago_in_words(@screen.player.last_heartbeat_at) %> ago</span>
        </div>
      <% end %>
      <% if @screen.player.ip_address %>
        <div class="flex justify-between py-2 text-sm">
          <span class="text-gray-500">IP</span>
          <span class="font-mono text-xs"><%= @screen.player.ip_address %></span>
        </div>
      <% end %>
    </div>
    <%= button_to "Unpair", screen_pairing_path(@screen), method: :delete,
        class: "text-sm text-red-600 font-semibold mt-3",
        data: { turbo_confirm: "Unpair this player?" } %>
  <% else %>
    <p class="text-sm text-gray-500 mb-3">No player paired to this screen.</p>
    <%= link_to "Pair a player", new_screen_pairing_path(@screen),
        class: "inline-flex items-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500" %>
  <% end %>
</div>

<%# Pairing history %>
<% if @screen.screen_players.history.any? %>
  <div class="rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5 p-5">
    <h3 class="text-sm font-semibold mb-3">Pairing history</h3>
    <div class="space-y-2">
      <% @screen.screen_players.history.order(created_at: :desc).limit(5).each do |sp| %>
        <div class="flex justify-between text-xs text-gray-400">
          <span>Paired <%= sp.created_at.strftime("%b %-d, %Y") %></span>
          <span>Unpaired <%= sp.unpaired_at&.strftime("%b %-d, %Y") || "—" %></span>
        </div>
      <% end %>
    </div>
  </div>
<% end %>
```

---

## QR attribution from the player

The `PlayerApiController#play` action sets `@screen`. The layout partials
render QR codes via `_qr_badge.html.erb`, which already passes both
dimensions:

```erb
<%# In ads/layouts/_qr_badge.html.erb (already implemented) %>
<%= qr_svg(qr, ad: ad, screen: defined?(@screen) ? @screen : nil) %>
```

On the player, `@screen` is set → QR URL becomes `/s/Ab3kX9?a=456&s=123`.
In admin preview, `@screen` is nil → QR URL becomes `/s/Ab3kX9?a=456`.

Scans with both `a` and `s` are **qualified** — they count in metrics.
Scans missing either are **unqualified** — recorded but excluded from counts.

Analytics can now answer:
- "How many scans came from the Window Display?" → `QrScan.qualified.where(screen: screen)`
- "How many scans came from the Just Listed ad?" → `QrScan.qualified.where(ad: ad)`
- "How many scans from this ad on this screen?" → `QrScan.qualified.where(ad: ad, screen: screen)`

No changes needed to the player plan — attribution flows through the
existing `_qr_badge` partial and `QrHelper#qr_svg` with `ad:` / `screen:` kwargs.

---

## Build order

### Phase A — Schema
1. Player model — spec, factory, migration (RED/GREEN)
2. ScreenPlayer model — spec, factory, migration (RED/GREEN)
3. Screen model additions — `pair_player!`, `unpair_player!`, associations

### Phase B — Device API
4. PlayerApiController — register, status, play, heartbeat (RED/GREEN)
5. Player layout + pairing/idle/play/unpaired views

### Phase C — Admin pairing
6. ScreenPairingsController — new, create, destroy (RED/GREEN)
7. Pairing form view
8. Screen show page — player section + pairing history

### Phase D — ActionCable
9. PairingChannel
10. ScreenChannel
11. ScreenPlaylist broadcast on change
12. ApplicationCable::Connection — allow anonymous

### Phase E — Device JS
13. device_pairing_controller.js
14. device_playback_controller.js (heartbeat + ScreenChannel)

### Phase F — Polish
15. Seeds: create demo players + pairings

---

## What's deferred

- **QR-based pairing** — scan a QR on the TV instead of typing a code
- **Offline resilience** — service worker caches last playlist
- **Day-parting** — schedule-aware `current_playlist` (see day-parting plan)
- **Remote reboot** — broadcast `reload` via ScreenChannel
- **Firmware reporting** — device sends version with heartbeat
- **Player admin list** — `/players` index showing all provisioned devices
- **Player provisioning** — admin creates player records before shipping hardware
