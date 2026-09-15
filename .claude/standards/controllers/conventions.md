# Standard: Controller Conventions

## Inheritance

Every controller inherits from an appropriate base:

| Namespace | Base Controller | Auth | Tenant |
|-----------|----------------|------|--------|
| `App::` | `App::BaseController` | Session cookie | `Current.account` via `acts_as_tenant` |
| `Api::V1::` | `Api::V1::BaseController` | Player token | None (token-scoped) |
| `Admin::` | `Admin::ApplicationController` | Session + admin role | `without_tenant` |
| `Marketing::` | `Marketing::BaseController` | None (public) | None |
| `Go::` | `ApplicationController` + `skip_before_action` | None (public) | None |
| `Play::` | `Play::BaseController` | Player token | None |

Never inherit directly from `ApplicationController` in the `App::` namespace.

## File Ordering

Each controller file follows this order:

```ruby
class ThingsController < BaseController
  # 1. Includes/concerns
  include HoneypotProtection

  # 2. Callbacks (auth → tenant → resource)
  before_action :set_thing, only: %i[show edit update destroy]

  # 3. Actions in RESTful order
  def index; end
  def show; end
  def new; end
  def create; end
  def edit; end
  def update; end
  def destroy; end

  # 4. Private section
  private

    # 5. set_* methods
    def set_thing; end

    # 6. *_params methods
    def thing_params; end
end
```

## Thin Controllers

Controllers handle HTTP concerns only:
- Accept and permit parameters
- Build or find records
- Authorize the record
- Delegate to a service object (if logic spans multiple models)
- Redirect or render with appropriate status

If a controller action exceeds ~10 lines of non-HTTP logic, extract
to a service object in `app/services/`.

## Record Lookup

Use `find_by_param!` for all record lookups. Never use `.find(params[:id])`.

```ruby
# Good
@listing = Current.account.listings.find_by_param!(params[:id])

# Also good (parent resource in nested route)
@playlist = Current.account.playlists.find_by_param!(params[:playlist_id])

# Bad — uses integer ID
@listing = Current.account.listings.find(params[:id])
```

## Authorization

Every action that reads or mutates a record calls `authorize!` or
`authorized_scope`:

```ruby
# Index — scope-based
def index
  @listings = authorized_scope(Listing.all)
end

# Show/edit — authorize the loaded record
def show
  authorize! @listing
end

# Create — authorize the built (unsaved) record
def create
  @listing = Current.account.listings.build(listing_params)
  authorize! @listing
end

# Destroy — authorize the loaded record
def destroy
  authorize! @listing
  @listing.destroy
end
```

Authorize the **instance**, not the class. The policy can inspect
the record's attributes (e.g., which account, which contentable
type) to make its decision.

Never inline role checks in controllers. All access decisions go
through policy classes in `app/policies/`.

## Strong Parameters

Every write action uses strong params with an explicit permit list.

```ruby
def listing_params
  params.require(:listing).permit(:address, :price, :status, photos: [])
end
```

Rules:
- Never `params.permit!` or `params.to_unsafe_h`
- Never permit `id`, `account_id`, `created_at`, `updated_at`
- Validate enum/type params against allowlists (or let the model
  validate via `inclusion`)
- Use `_sid` (signed ID) for public form hidden fields, never raw
  integer IDs

## Service Objects

Extract to `app/services/` when an action involves:
- Multi-model coordination (e.g., deactivate + create)
- External side effects (e.g., broadcast + mail)
- Validation logic beyond what the model handles (e.g., pairing code expiry)

Service interface:
- Name as verb phrase: `AssignScreenContent`, `PairPlayerToScreen`
- Accept dependencies via `initialize`
- Single public method: `call`
- Return a result struct with `success?` and relevant data

```ruby
class PairPlayerToScreen
  Result = Struct.new(:success?, :error, keyword_init: true)

  def initialize(screen:, code:, paired_by: nil)
    # ...
  end

  def call
    # ... returns Result.new(success?: true) or Result.new(success?: false, error: "...")
  end
end
```

Controller usage:
```ruby
result = PairPlayerToScreen.new(screen: @screen, code: params[:code], paired_by: Current.user).call
if result.success?
  redirect_to @screen, notice: "Paired."
else
  flash[:alert] = result.error
  redirect_to new_screen_screen_player_path(@screen)
end
```

## API Controllers

### Versioning

All API routes live under `/v1/`. Controllers in `Api::V1::`.

### Response Format

Use `render_data` and `render_error` helpers (defined in
`Api::BaseController`):

```ruby
# Success
render_data(token: player.token, pairing_code: player.pairing_code)
render_data({ ... }, status: :created)

# Error
render_error "Not found", status: :not_found

# No content
head :no_content
```

Response envelope:
```json
{ "data": { "token": "abc", "pairing_code": "XY1234" } }
{ "error": { "message": "Not found" } }
```

### Error Handling

`Api::BaseController` handles common exceptions:
- `ActiveRecord::RecordNotFound` → 404
- `ActiveRecord::RecordInvalid` → 422
- `ActionController::ParameterMissing` → 400

### Rate Limiting

All API endpoints have a baseline rate limit (60 req/min per IP).
Sensitive endpoints (registration, auth) have tighter limits.

```ruby
rate_limit to: 10, within: 1.minute, only: :create, by: -> { request.remote_ip }
```

## HTML Error Handling

- Failed form submissions: re-render with `status: :unprocessable_entity`
- Flash messages: `notice` for success, `alert` for errors
- Use I18n keys: `notice: t(".success")` — not hardcoded strings

## Multi-Tenant Scoping

App controllers scope all queries through `Current.account`:

```ruby
@listing = Current.account.listings.find_by_param!(params[:id])
@listings = authorized_scope(Listing.all)  # acts_as_tenant auto-scopes
```

Public controllers (`Go::`) skip authentication and query without
tenant scope. The `find_by_param!` call finds by UUID — no
enumeration possible.

Admin controllers bypass tenant scope with `around_action :without_tenant`.

## Performance

- **Eager load** associations rendered in views:
  `@listings = Listing.includes(:agents, :photos_attachments)`
- **Paginate** all index actions with Pagy
- **Never** query inside loops — eager load in the controller

## Testing

- Use **request specs** (`spec/requests/`), not controller specs
- Every resource includes `it_behaves_like "tenant isolated resource"`
- Test happy path, unauthorized access, and not-found for each action
- Policy specs cover role-based access in `spec/policies/`
- Service specs cover business logic in `spec/services/`
