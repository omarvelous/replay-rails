# Standard: Code Organization

## Thin Controllers

Controllers handle HTTP concerns only:
- Accept and permit parameters
- Call models or services to perform business logic
- Set flash messages
- Redirect or render with appropriate status codes

Business logic does **not** belong in controllers. If a controller action is more than 10 lines, consider extracting logic into the model or a service object.

```ruby
# Good — controller delegates to model
def create
  @listing = Current.account.listings.build(listing_params)
  if @listing.save
    redirect_to @listing, notice: t(".success")
  else
    render :new, status: :unprocessable_entity
  end
end
```

## Concerns

Use `ActiveSupport::Concern` for shared behavior across models or controllers.

- Model concerns go in `app/models/concerns/`
- Controller concerns go in `app/controllers/concerns/`
- Name concerns after the behavior they provide (e.g., `PublicIdentifiable`, `Authentication`, `HoneypotProtection`)

```ruby
# app/models/concerns/public_identifiable.rb
module PublicIdentifiable
  extend ActiveSupport::Concern

  included do
    before_create :generate_public_id
  end

  def to_param
    public_id
  end
end
```

## Service Objects

For complex operations that span multiple models or involve side effects, create POROs in `app/services/`.

- Name as verb phrases: `AcceptInvite`, `CaptureLead`, `PairPlayerToScreen`
- Single public method: `call`
- Accept dependencies through the initializer
- Return a `Result` struct for success/failure

```ruby
# app/services/capture_lead.rb
class CaptureLead
  Result = Struct.new(:success?, :lead, :error, keyword_init: true)

  def initialize(params:, request_context:)
    @params = params
    @request_context = request_context
  end

  def call
    # ... build and save lead
    Result.new(success?: true, lead: lead)
  rescue => e
    Result.new(success?: false, error: e.message)
  end
end
```

## Presenters

For complex view logic that doesn't belong in the model or controller, use presenters in `app/presenters/`.

```ruby
# app/presenters/dashboard_presenter.rb
class DashboardPresenter
  def initialize(account:)
    @account = account
  end

  def total_scans
    # ...
  end
end
```

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Models | Singular nouns | `Listing`, `Agent`, `QrCode` |
| Controllers | Plural of model | `ListingsController`, `AgentsController` |
| Services | Verb phrases | `AcceptInvite`, `CaptureLead`, `PairPlayerToScreen` |
| Concerns | Behavior names | `PublicIdentifiable`, `Authentication` |
| Mailers | Noun + Mailer | `LeadMailer`, `InviteMailer` |
| Presenters | Noun + Presenter | `DashboardPresenter` |

## Scoping (Multi-Tenant)

All tenant-scoped queries go through `Current.account` or `acts_as_tenant`:

```ruby
# Good — scoped through current account (controllers)
Current.account.listings
Current.account.ads.find_by_param!(params[:id])

# Good — acts_as_tenant auto-scopes (models)
Listing.all  # automatically filtered by current tenant

# Bad — bypasses tenant scoping
Listing.unscoped.find(params[:id])
```

In contexts without a tenant (admin, public pages, background jobs), use `ActsAsTenant.without_tenant` or `ActsAsTenant.with_tenant(account)` blocks.
