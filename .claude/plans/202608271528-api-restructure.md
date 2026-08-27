# Plan: API Restructure — Split play + api subdomains

## Current state

- `PlayerApiController` — monolithic, inherits `ActionController::Base`
- `play` subdomain with custom routes (`/register`, `/status`, `/heartbeat`)
- Bearer token auth via `Authorization` header in a `before_action`
- 4 actions in one controller: `register`, `status`, `play`, `heartbeat`
- Views at `app/views/player_api/` (register, play, idle, unpaired)
- JS controllers use `localStorage.getItem("player_token")` + Bearer header
- Specs at `spec/requests/player_api_spec.rb`

### Problems

- Not RESTful — custom action names, no resource structure
- Monolithic controller — 4 unrelated actions in one file
- HTML and JSON responses mixed in one controller
- Auth is a private method on the controller, not a concern
- No clear place to add new endpoints (impressions)
- Inherits `ActionController::Base` instead of a proper base controller

---

## Target state

Two subdomains, two concerns:

| Subdomain | Purpose | Format | Auth |
|-----------|---------|--------|------|
| `play` | Visual content — what the TV displays | HTML | Token in URL |
| `api` | Machine communication — heartbeat, impressions, status | JSON | Token in URL |

```
play.replay.com/players/new                   GET    → pairing screen (HTML)
play.replay.com/players/:token                GET    → playback content (HTML)

api.replay.com/players                         POST   → register (JSON)
api.replay.com/players/:token                  GET    → player status (JSON)
api.replay.com/players/:token/heartbeat        POST   → device health (JSON)
api.replay.com/players/:token/impressions      POST   → record impression (JSON)
```

The player device points its browser at `play` (that's on the TV).
The JS on that page calls `api` for background operations.

---

## Device flow

```
1. Browser opens play.replay.com/players/new
       ↓
2. Page JS calls POST api.replay.com/players → gets token + pairing code
       ↓
3. TV shows pairing code. Admin enters it in the app.
       ↓
4. JS polls GET api.replay.com/players/:token → detects pairing
       ↓
5. Browser navigates to play.replay.com/players/:token → shows content
       ↓
6. JS fires POST api.replay.com/players/:token/heartbeat every 30s
       ↓
7. On each slide transition, JS fires POST api.replay.com/players/:token/impressions
```

---

## Routes

```ruby
# Play subdomain — visual content (HTML)
constraints subdomain: "play" do
  scope module: "play" do
    resources :players, param: :token, only: [ :new, :show ]
  end
end

# API subdomain — machine communication (JSON)
constraints subdomain: "api" do
  scope module: "api" do
    resources :players, param: :token, only: [ :create, :show ] do
      resource :heartbeat, only: [ :create ]
      resources :impressions, only: [ :create ]
    end
  end
end
```

### URL mapping (old → new)

| Old | New | Format |
|-----|-----|--------|
| `play.replay.com/register` (POST) | `api.replay.com/players` (POST) | JSON |
| `play.replay.com/register` (GET, HTML) | `play.replay.com/players/new` (GET) | HTML |
| `play.replay.com/status?code=X` | `api.replay.com/players/:token` (GET) | JSON |
| `play.replay.com/` (play, HTML) | `play.replay.com/players/:token` (GET) | HTML |
| `play.replay.com/heartbeat` | `api.replay.com/players/:token/heartbeat` | JSON |
| (new) | `api.replay.com/players/:token/impressions` | JSON |

---

## Play controllers (HTML)

### Play::PlayersController

Serves the visual content — pairing screen and playback.

```ruby
# app/controllers/play/players_controller.rb
module Play
  class PlayersController < Play::BaseController
    before_action :authenticate_player!, only: :show

    # GET /players/new — pairing screen
    def new
    end

    # GET /players/:token — playback content
    def show
      @screen = @player.screen

      unless @screen
        return render :unpaired
      end

      @playlist = @screen.screen_playlists.find_by(active: true)&.playlist

      if @playlist
        @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
      else
        render :idle
      end
    end
  end
end
```

### Play::BaseController

```ruby
# app/controllers/play/base_controller.rb
module Play
  class BaseController < ActionController::Base
    layout "player"

    private

    def authenticate_player!
      @player = Player.find_by(token: params[:token])
      head :unauthorized unless @player
    end
  end
end
```

### Play views

```
app/views/play/players/new.html.erb       ← pairing screen (was register)
app/views/play/players/show.html.erb      ← playback (was play)
app/views/play/players/idle.html.erb      ← no playlist assigned
app/views/play/players/unpaired.html.erb  ← not paired to a screen
```

The `new` view shows the pairing code and runs the pairing JS
controller. The JS calls the API subdomain to register and poll
status.

---

## API controllers (JSON)

### Api::BaseController

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::Base
    protect_from_forgery with: :null_session

    private

    def authenticate_player!
      @player = Player.find_by(token: params[:player_token])
      render json: { error: "Invalid player token" }, status: :unauthorized unless @player
    end
  end
end
```

### Api::PlayersController (register + status)

```ruby
# app/controllers/api/players_controller.rb
module Api
  class PlayersController < Api::BaseController
    before_action :authenticate_player!, only: :show

    # POST /players — register a new device
    def create
      player = Player.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      render json: {
        pairing_code: player.pairing_code,
        token: player.token,
        expires_in: 600
      }, status: :created
    end

    # GET /players/:token — player status
    def show
      render json: { paired: @player.paired?, screen_id: @player.screen&.id }
    end
  end
end
```

`create` is unauthenticated (registration). `show` requires a
valid token (status check). Standard REST — no extra controllers.

### Api::Players::HeartbeatsController

```ruby
# app/controllers/api/players/heartbeats_controller.rb
module Api
  module Players
    class HeartbeatsController < Api::BaseController
      before_action :authenticate_player!

      # POST /players/:token/heartbeat
      def create
        @player.update!(
          last_heartbeat_at: Time.current,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
        render json: { ok: true }
      end
    end
  end
end
```

### Api::Players::ImpressionsController

```ruby
# app/controllers/api/players/impressions_controller.rb
module Api
  module Players
    class ImpressionsController < Api::BaseController
      before_action :authenticate_player!

      # POST /players/:token/impressions
      def create
        screen = @player.screen
        Impression.create!(
          ad_id: params[:ad_id],
          screen: screen,
          player: @player,
          site: screen.site,
          playlist_id: params[:playlist_id],
          account: screen.site.account,
          position: params[:position],
          duration: params[:duration]
        )
        head :created
      end
    end
  end
end
```

---

## JS changes

JS runs on the play subdomain pages but calls the api subdomain
for data operations.

### CORS

The play subdomain JS calls the api subdomain — this is cross-origin.
Need CORS on the API:

```ruby
# config/initializers/cors.rb (or rack-cors gem)
# Allow play subdomain to call api subdomain
```

Alternatively, since both are same-origin (`replay.com`) with
different subdomains, use `domain: :all` on cookies or configure
the API to accept same-site cross-subdomain requests. The simplest
approach for development is the `rack-cors` gem:

```ruby
gem "rack-cors"

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /\Ahttps?:\/\/.*\.replay\.(com|localhost)/
    resource "/players/*", headers: :any, methods: [ :get, :post ]
  end
end
```

### device_pairing_controller.js

```javascript
import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { apiHost: String }

  async connect() {
    // Register the player via API
    const res = await fetch(`${this.apiHostValue}/players`, { method: "POST" })
    const data = await res.json()

    this.token = data.token
    this.displayCode(data.pairing_code)

    // Subscribe to pairing channel
    this.subscription = consumer.subscriptions.create(
      { channel: "PairingChannel", code: data.pairing_code },
      { received: (msg) => { if (msg.paired) this.onPaired() } }
    )

    // Fallback polling
    this.poll = setInterval(() => this.checkStatus(), 3000)
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.poll)
  }

  displayCode(code) {
    // Update the pairing code display
    this.element.querySelector("[data-code]").textContent = code
  }

  async checkStatus() {
    try {
      const res = await fetch(`${this.apiHostValue}/players/${this.token}`)
      if (!res.ok) return
      const data = await res.json()
      if (data.paired) this.onPaired()
    } catch { /* retry */ }
  }

  onPaired() {
    clearInterval(this.poll)
    this.subscription?.unsubscribe()
    localStorage.setItem("player_token", this.token)
    window.location.href = `/players/${this.token}`
  }
}
```

The `apiHostValue` is set from the view:

```erb
<%# play/players/new.html.erb %>
<div data-controller="device-pairing"
     data-device-pairing-api-host-value="<%= request.protocol %>api.<%= request.domain %>">
  <h1>Pair this screen</h1>
  <p data-code class="text-6xl font-mono">------</p>
</div>
```

### device_playback_controller.js

```javascript
import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { apiHost: String, playerToken: String, playlistId: Number }

  connect() {
    const token = this.playerTokenValue

    this.subscription = consumer.subscriptions.create(
      { channel: "ScreenChannel", token },
      {
        received: ({ event }) => {
          if (event === "playlist_changed") window.location.reload()
        }
      }
    )

    this.heartbeat = setInterval(() => this.sendHeartbeat(), 30_000)
    this.sendHeartbeat()

    this.element.addEventListener("slideshow:impression", (e) => {
      this.recordImpression(e.detail)
    })
  }

  disconnect() {
    this.subscription?.unsubscribe()
    clearInterval(this.heartbeat)
  }

  async sendHeartbeat() {
    try {
      await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/heartbeat`, {
        method: "POST"
      })
    } catch { /* retry */ }
  }

  async recordImpression({ adId, position, duration }) {
    try {
      await fetch(`${this.apiHostValue}/players/${this.playerTokenValue}/impressions`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ad_id: adId,
          playlist_id: this.playlistIdValue,
          position: position,
          duration: duration
        })
      })
    } catch { /* retry */ }
  }
}
```

The playback view passes context:

```erb
<%# play/players/show.html.erb %>
<div data-controller="slideshow device-playback"
     data-device-playback-api-host-value="<%= request.protocol %>api.<%= request.domain %>"
     data-device-playback-player-token-value="<%= params[:token] %>"
     data-device-playback-playlist-id-value="<%= @playlist&.id %>">
  <% @playlist_ads.each_with_index do |pa, index| %>
    <div class="slide ..."
         data-slideshow-target="slide"
         data-duration="<%= pa.duration %>"
         data-ad-id="<%= pa.ad.id %>"
         data-position="<%= pa.position %>">
      <%= render "app/ads/layouts/#{pa.ad.layout}", ad: pa.ad %>
    </div>
  <% end %>
</div>
```

---

## ActionCable

`ScreenChannel` currently authenticates with the Bearer token from
the connection params. This doesn't change — cable connections use
their own auth mechanism (connection-level, not per-request). The
token is passed when subscribing, not in the URL.

`PairingChannel` is anonymous (streams by pairing code). No change.

---

## Config changes

### CORS gem

```ruby
# Gemfile
gem "rack-cors"
```

### Subdomain host authorization

```ruby
# config/environments/development.rb
# Already has: config.hosts << ".replay.localhost"
# api.replay.localhost is already covered
```

---

## Spec structure

### API specs (JSON)

```
spec/requests/api/players_spec.rb                    → register + status
spec/requests/api/players/heartbeats_spec.rb         → heartbeat
spec/requests/api/players/impressions_spec.rb        → impression recording
```

All use `host! "api.replay.localhost"` and expect JSON responses.
No Bearer headers — token in URL.

### Play specs (HTML)

```
spec/requests/play/players_spec.rb                   → pairing + playback
```

Uses `host! "play.replay.localhost"` and expects HTML responses.

### Example

```ruby
# spec/requests/api/players_spec.rb
RSpec.describe "Api::Players" do
  before { host! "api.replay.localhost" }

  describe "POST /players" do
    it "registers a player and returns JSON" do
      post "/players", as: :json
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["token"]).to be_present
      expect(response.parsed_body["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
    end
  end

  describe "GET /players/:token" do
    let(:player) { create(:player) }

    it "returns paired: false when not paired" do
      get "/players/#{player.token}"
      expect(response.parsed_body["paired"]).to be false
    end

    it "returns paired: true with screen_id when paired" do
      screen = create(:screen)
      screen.pair_player!(player)
      get "/players/#{player.token}"
      expect(response.parsed_body["paired"]).to be true
      expect(response.parsed_body["screen_id"]).to eq(screen.id)
    end

    it "returns 401 for invalid token" do
      get "/players/invalid"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

# spec/requests/api/players/heartbeats_spec.rb
RSpec.describe "Api::Players::Heartbeats" do
  before { host! "api.replay.localhost" }

  let(:player) { create(:player) }
  let(:screen) { create(:screen) }

  before { screen.pair_player!(player) }

  describe "POST /players/:token/heartbeat" do
    it "updates heartbeat" do
      post "/players/#{player.token}/heartbeat"
      expect(response).to be_successful
      expect(player.reload.last_heartbeat_at).to be_within(5.seconds).of(Time.current)
    end

    it "returns 401 for invalid token" do
      post "/players/invalid/heartbeat"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

---

## Blast radius

| Layer | Change |
|-------|--------|
| Routes | Replace monolithic `play` block with `play` (HTML) + `api` (JSON) blocks |
| Controllers | Delete `PlayerApiController`, create 5 new controllers across two modules |
| Views | Move 4 views to `play/players/` namespace |
| JS | Update to cross-subdomain fetch calls with apiHost value, remove Bearer headers |
| Specs | Split into `api/` and `play/` spec directories |
| Gems | Add `rack-cors` for cross-subdomain JS fetch |
| ActionCable | No change |
| App controllers | No change |
| README | Update subdomain table |

### What does NOT change

- Player model — no changes
- Screen model — no changes
- ScreenPlayer pairing — no changes
- ActionCable channels — no changes
- App-side screen_players_controller — no changes (admin pairing UI)
- Authentication concern — not involved (that's for user auth)

---

## Build order

### Phase 1 — Api::BaseController + PlayersController (RED/GREEN)
1. Add `rack-cors` gem + CORS initializer
2. RED: Player registration + status spec on api subdomain
3. GREEN: `Api::BaseController` with token auth, `Api::PlayersController` (create + show)
4. Route: `api` subdomain with `resources :players, only: [:create, :show]`

### Phase 2 — API nested resources (RED/GREEN per controller)
5. RED: Heartbeats spec
6. GREEN: `Api::Players::HeartbeatsController#create`

### Phase 3 — Play subdomain (RED/GREEN)
9. RED: Play players spec (new + show)
10. GREEN: `Play::BaseController`, `Play::PlayersController` (new + show)
11. Move views to `play/players/`

### Phase 4 — JS updates
12. Update `device_pairing_controller.js` — register via API, poll via API, redirect to play
13. Update `device_playback_controller.js` — heartbeat via API, add impression dispatch
14. Add `apiHost` and `playerToken` data attributes to play views

### Phase 5 — Impressions (from analytics plan)
15. RED: Impressions spec
16. GREEN: `Api::Players::ImpressionsController#create`
17. Impression event dispatch in slideshow JS

### Phase 6 — Cleanup
18. Delete `PlayerApiController`
19. Delete old `player_api/` views
20. Delete old `player_api_spec.rb`
21. Remove old `play` subdomain routes
22. Update README subdomain table
23. Lint + full suite green

---

## How this affects the analytics plan

The analytics plan's impression endpoint is Phase 5 here. The
analytics plan should focus on:

- Impression model + migration (unchanged)
- Dashboard + charting (Phase 2 of analytics)
- Metrics on existing pages (Phase 3)
- Rollups (Phase 4)

The API restructure should be done first — it provides the
endpoint and JS infrastructure for impression recording.

---

## Dependencies

- None — infrastructure, not feature work
- Blocks analytics (impression endpoint lives here)
- Should be done before analytics Phase 1
