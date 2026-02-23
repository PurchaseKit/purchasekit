# PurchaseKit

In-app purchase webhooks for Rails. Receive normalized Apple and Google subscription events with a simple callback interface.

## How it works

```
Native app (iOS/Android)
    ↓ StoreKit/Play Billing
App Store / Play Store
    ↓ Server-to-server notifications
PurchaseKit SaaS (normalizes Apple/Google data)
    ↓ Webhooks
Your Rails app (via this gem)
    ↓ Callbacks or Pay::Subscription
Your business logic
```

PurchaseKit handles the complexity of Apple and Google's different webhook formats, delivering you a consistent event payload regardless of which store the purchase came from.

## Installation

Add to your Gemfile:

```ruby
gem "purchasekit"
```

Create an initializer:

```ruby
# config/initializers/purchasekit.rb
PurchaseKit.configure do |config|
  config.api_key = Rails.application.credentials.dig(:purchasekit, :api_key)
  config.app_id = Rails.application.credentials.dig(:purchasekit, :app_id)
  config.webhook_secret = Rails.application.credentials.dig(:purchasekit, :webhook_secret)
end
```

Mount the engine in your routes:

```ruby
# config/routes.rb
mount PurchaseKit::Engine, at: "/purchasekit"
```

Import the JavaScript:

```javascript
// app/javascript/application.js
import "purchasekit/turbo_actions"

// app/javascript/controllers/index.js
eagerLoadControllersFrom("purchasekit", application)
```

## Pay gem integration

If you use the [Pay gem](https://github.com/pay-rails/pay), PurchaseKit automatically detects it and handles everything:

```ruby
gem "pay"
gem "purchasekit"
```

When Pay is detected, webhooks automatically create and update `Pay::Subscription` records and broadcast Turbo Stream redirects. No event callbacks needed.

## Event callbacks (without Pay)

If you're not using Pay, register callbacks to handle subscription events:

```ruby
# config/initializers/purchasekit.rb
PurchaseKit.configure do |config|
  # ... credentials ...

  config.on(:subscription_created) do |event|
    user = User.find(event.customer_id)
    user.subscriptions.create!(
      processor_id: event.subscription_id,
      store: event.store,
      status: event.status
    )
  end

  config.on(:subscription_canceled) do |event|
    subscription = Subscription.find_by(processor_id: event.subscription_id)
    subscription&.update!(status: "canceled")
  end

  config.on(:subscription_expired) do |event|
    subscription = Subscription.find_by(processor_id: event.subscription_id)
    subscription&.update!(status: "expired")
  end
end
```

### Available events

| Event | Description |
|-------|-------------|
| `:subscription_created` | New subscription started |
| `:subscription_updated` | Subscription renewed or plan changed |
| `:subscription_canceled` | User canceled (still active until `ends_at`) |
| `:subscription_expired` | Subscription ended |

### Event payload

| Method | Description |
|--------|-------------|
| `event.event_id` | Unique event identifier (for idempotency) |
| `event.customer_id` | Your user ID |
| `event.subscription_id` | Store's subscription ID |
| `event.store` | `"apple"` or `"google"` |
| `event.store_product_id` | e.g., `"com.example.pro.annual"` |
| `event.status` | `"active"`, `"canceled"`, `"expired"` |
| `event.current_period_start` | Start of billing period |
| `event.current_period_end` | End of billing period |
| `event.ends_at` | When subscription will end |
| `event.success_path` | Redirect path after purchase |

### Idempotency

Webhooks may be delivered more than once. Write idempotent callbacks using `find_or_create_by` or check `event.event_id` to avoid duplicate side effects.

## Paywall helper

Build a paywall using the included helper. Subscribe to the Turbo Stream for real-time redirects:

```erb
<%= turbo_stream_from "purchasekit_customer_#{current_user.id}" %>

<%= purchasekit_paywall customer_id: current_user.id, success_path: dashboard_path do |paywall| %>
  <%= paywall.plan_option product: @annual, selected: true do %>
    Annual - <%= paywall.price %>/year
  <% end %>

  <%= paywall.plan_option product: @monthly do %>
    Monthly - <%= paywall.price %>/month
  <% end %>

  <%= paywall.submit "Subscribe" %>
  <%= paywall.restore url: restore_purchases_path, class: "btn btn-link" %>
<% end %>
```

### Restore purchases

Apple requires apps with in-app purchases to include a "Restore purchases" button. This handles users who switch devices or reinstall the app.

The `paywall.restore` helper renders a button that reads active subscriptions directly from StoreKit (iOS) or Play Billing (Android) via the native bridge. Pass a `url:` to automatically POST the subscription IDs to your server:

```erb
<%= paywall.restore url: restore_purchases_path, class: "btn btn-link" %>
```

When the user taps restore, the JS controller sends a bridge message to the native app, receives the active subscription IDs, and POSTs them as JSON to your URL. If the server responds with a redirect, the page navigates automatically.

On the server, match the IDs against your stored subscriptions. The `subscription_ids` match the `subscription_id` field in PurchaseKit webhook payloads (Apple's `originalTransactionId`, Google's order ID):

```ruby
# routes.rb
post "restore_purchases", to: "subscriptions#restore"

# subscriptions_controller.rb
def restore
  ids = params[:subscription_ids] || []

  if ids.any? && current_user.subscriptions.where(processor_id: ids).active.any?
    redirect_to dashboard_path, notice: "Your subscription is active."
  else
    redirect_to paywall_path, alert: "No active subscription found."
  end
end
```

If you need custom behavior, omit the `url:` and listen for the DOM event instead:

```javascript
document.addEventListener("purchasekit--paywall:restore", (event) => {
  const { subscriptionIds, error } = event.detail
  // Handle as needed
})
```

Products are fetched from the PurchaseKit API:

```ruby
@annual = PurchaseKit::Product.find("prod_XXXXXXXX")
@monthly = PurchaseKit::Product.find("prod_YYYYYYYY")
```

## Demo mode

For local development without a PurchaseKit account:

```ruby
PurchaseKit.configure do |config|
  config.demo_mode = true
  config.demo_products = {
    "prod_annual" => { apple_product_id: "com.example.pro.annual" },
    "prod_monthly" => { apple_product_id: "com.example.pro.monthly" }
  }
end
```

Works with Xcode's StoreKit local testing.

## License

MIT License. See LICENSE for details.
