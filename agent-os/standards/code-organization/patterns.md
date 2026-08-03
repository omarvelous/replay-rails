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
  @building = Current.user.account.buildings.build(building_params)
  if @building.save
    redirect_to @building, notice: "Building created."
  else
    render :new, status: :unprocessable_entity
  end
end

# Bad — business logic in controller
def create
  @building = Building.new(building_params)
  @building.account = Current.user.account
  @building.normalize_address
  @building.geocode_location
  @building.assign_default_settings
  # ...
end
```

## Concerns

Use `ActiveSupport::Concern` for shared behavior across models or controllers.

- Model concerns go in `app/models/concerns/`
- Controller concerns go in `app/controllers/concerns/`
- Name concerns after the behavior they provide (e.g., `Trackable`, `Filterable`, `Authenticatable`)

```ruby
# app/models/concerns/trackable.rb
module Trackable
  extend ActiveSupport::Concern

  included do
    has_many :activity_logs, as: :trackable
  end

  def last_activity
    activity_logs.order(created_at: :desc).first
  end
end
```

## Service Objects

For complex operations that span multiple models or involve external services, create POROs (Plain Old Ruby Objects) in `app/services/`.

- Name as verb phrases: `CreateAccount`, `SendNotification`, `ProcessPayment`
- Single public method: `call`
- Accept dependencies through the initializer
- Return a result or raise a specific error

```ruby
# app/services/create_account.rb
class CreateAccount
  def initialize(user:, account_params:)
    @user = user
    @account_params = account_params
  end

  def call
    Account.transaction do
      account = Account.create!(@account_params)
      @user.update!(account: account)
      account
    end
  end
end
```

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Models | Singular nouns | `User`, `Building`, `MaintenanceRequest` |
| Controllers | Plural of model | `UsersController`, `BuildingsController` |
| Services | Verb phrases | `CreateAccount`, `SendNotification` |
| Concerns | Adjectives/behavior | `Trackable`, `Filterable` |
| Mailers | Noun + Mailer | `UserMailer`, `NotificationMailer` |

## Scoping (Multi-Tenant)

In multi-tenant applications, scope all queries through the current account to prevent data leakage:

```ruby
# Good — scoped through current account
Current.user.account.buildings
Current.user.account.units
Current.user.account.maintenance_requests

# Bad — unscoped query (exposes other accounts' data)
Building.all
Building.find(params[:id])
```

Use `Current` (via `ActiveSupport::CurrentAttributes`) to access the authenticated user and their account throughout the request lifecycle.
