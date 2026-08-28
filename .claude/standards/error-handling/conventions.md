# Standard: Error Handling

## Flash Messages

Use Rails flash messages for user-facing feedback:

- `flash[:notice]` — Success messages (green)
- `flash[:alert]` — Error or warning messages (red)

Display flash messages using DaisyUI alert components in the application layout:

```erb
<% if notice %>
  <div class="alert alert-success mb-4">
    <span><%= notice %></span>
  </div>
<% end %>

<% if alert %>
  <div class="alert alert-error mb-4">
    <span><%= alert %></span>
  </div>
<% end %>
```

## Controller Error Handling

Use `rescue_from` in `ApplicationController` for common errors:

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
```

Return appropriate HTTP status codes:
- `200` — Success (default for `render`)
- `302` — Redirect (default for `redirect_to`)
- `404` — Not found (`status: :not_found`)
- `422` — Validation error (`status: :unprocessable_entity`)
- `500` — Server error (handled by Rails error pages)

## Form Validation Errors

Display validation errors inline on forms using `model.errors`:

```erb
<% if @model.errors.any? %>
  <div class="alert alert-error mb-4">
    <div>
      <h3 class="font-bold"><%= pluralize(@model.errors.count, "error") %> prevented saving:</h3>
      <ul class="list-disc list-inside mt-2">
        <% @model.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  </div>
<% end %>
```

Re-render the form with `status: :unprocessable_entity` so Turbo handles the response correctly:

```ruby
def create
  @model = Model.new(model_params)
  if @model.save
    redirect_to @model, notice: "Created successfully."
  else
    render :new, status: :unprocessable_entity
  end
end
```

## Logging

Use `Rails.logger` for application logging at appropriate levels:

| Level | Use for |
|-------|---------|
| `debug` | Detailed diagnostic info (development only) |
| `info` | General operational events (request processed, job completed) |
| `warn` | Unexpected but recoverable situations |
| `error` | Errors that need attention but don't crash the app |
| `fatal` | Unrecoverable errors |

```ruby
Rails.logger.info "Account created: #{account.id}"
Rails.logger.error "Payment failed for user #{user.id}: #{error.message}"
```

Do not use `puts` or `p` for logging in application code (seeds are the exception).

## Error Pages

Customize error pages in `public/`:

- `public/404.html` — Page not found
- `public/422.html` — Unprocessable entity
- `public/500.html` — Internal server error

These are static HTML files served directly by the web server, so they must be self-contained (no ERB, no asset pipeline). Style them to match the application's look and feel as closely as possible.
