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
| `event.customer_id` | Your user ID |
| `event.subscription_id` | Store's subscription ID |
| `event.store` | `"apple"` or `"google"` |
| `event.store_product_id` | e.g., `"com.example.pro.annual"` |
| `event.status` | `"active"`, `"canceled"`, `"expired"` |
| `event.current_period_start` | Start of billing period |
| `event.current_period_end` | End of billing period |
| `event.ends_at` | When subscription will end |
| `event.success_path` | Redirect path after purchase |

## Paywall helper

Build a paywall using the included helper:

```erb
<%= purchasekit_paywall customer_id: current_user.id, success_path: dashboard_path do |paywall| %>
  <%= paywall.plan_option product: @annual, selected: true do %>
    Annual - <%= paywall.price %>/year
  <% end %>

  <%= paywall.plan_option product: @monthly do %>
    Monthly - <%= paywall.price %>/month
  <% end %>

  <%= paywall.submit "Subscribe" %>
  <%= paywall.restore_link %>
<% end %>
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

This software is licensed under a custom PurchaseKit License. The gem may only be used in applications that actively integrate with the official PurchaseKit service at https://purchasekit.dev. See LICENSE for full details.
