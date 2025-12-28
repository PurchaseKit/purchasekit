# PurchaseKit::Pay

PurchaseKit payment processor for the [Pay gem](https://github.com/pay-rails/pay).

Add mobile in-app purchases (IAP) to your Rails app with [PurchaseKit](https://purchasekit.dev) and Pay.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "purchasekit-pay"
```

And then execute:

```bash
bundle install
```

## Configuration

Configure your PurchaseKit API key:

```ruby
# config/initializers/purchasekit.rb
PurchaseKit::Pay.configure do |config|
  config.api_key = Rails.application.credentials.dig(:purchasekit, :api_key)
  config.app_id = Rails.application.credentials.dig(:purchasekit, :app_id)
  config.webhook_secret = Rails.application.credentials.dig(:purchasekit, :webhook_secret)
end
```

> **Important:** `webhook_secret` is required in production. Webhooks will be rejected if signature verification fails.

Mount the engine in your routes:

```ruby
# config/routes.rb
mount PurchaseKit::Pay::Engine, at: "/purchasekit"
```

### JavaScript setup

Import the Turbo Stream actions in your application:

```javascript
// app/javascript/application.js
import "purchasekit-pay/turbo_actions"
```

Register the gem's Stimulus controllers:

```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)
eagerLoadControllersFrom("purchasekit-pay", application)
```

## Usage

### Adding a paywall

First, ensure your user has a PurchaseKit payment processor:

```ruby
current_user.set_payment_processor(:purchasekit)
```

Fetch products in your controller:

```ruby
@annual = PurchaseKit::Product.find("prod_XXX")
@monthly = PurchaseKit::Product.find("prod_YYY")
```

Then render a paywall using the builder pattern:

```erb
<%# Subscribe to ActionCable for real-time redirect after purchase %>
<%= turbo_stream_from dom_id(current_user.payment_processor) %>

<%= purchasekit_paywall customer: current_user.payment_processor, success_path: dashboard_path do |paywall| %>
  <%= paywall.plan_option product: @annual, selected: true do %>
    <span>Annual</span>
    <%= paywall.price %>
  <% end %>

  <%= paywall.plan_option product: @monthly do %>
    <span>Monthl</span>
    <%= paywall.price %>
  <% end %>

  <%= paywall.submit "Subscribe", class: "btn btn-primary" %>
  <%= paywall.restore_link %>
<% end %>
```

### Paywall helper options

- `customer:` (required) - A `Pay::Customer` instance
- `success_path:` - Where to redirect after successful purchase (defaults to `root_path`)

### Builder methods

- `plan_option(product:, selected: false)` - Radio button and label for a plan
- `price` - Displays the localized price (must be inside `plan_option` block)
- `submit(text)` - Submit button (disabled until prices load)
- `restore_link(text: "Restore purchases")` - Link to restore previous purchases

### How it works

1. Page loads, Stimulus controller requests prices from native app via Hotwire Native Bridge
2. User selects a plan and taps subscribe
3. Form submits to PurchasesController, which creates a purchase intent with PurchaseKit
4. Native app handles the App Store/Play Store purchase flow
5. PurchaseKit receives webhook from Apple/Google, normalizes it, and POSTs to your app
6. Webhook handler creates `Pay::Subscription` and broadcasts a Turbo Stream redirect
7. User is redirected to `success_path`

## Webhook events

The gem handles these webhook events from the PurchaseKit:

- `subscription.created` - Creates a new `Pay::Subscription`
- `subscription.updated` - Updates subscription status and period
- `subscription.canceled` - Marks subscription as canceled
- `subscription.expired` - Marks subscription as expired

## Requirements

- Ruby 3.1+
- Rails 7.0 - 8.x
- Pay 11.4+
- Turbo Rails (for ActionCable broadcasts)
- Stimulus
- Hotwire Native app with PurchaseKit bridge component

### JavaScript dependencies

This gem vendors and pins:

- **@hotwired/hotwire-native-bridge** (v1.2.2)

If your app already pins this package, your version takes precedence.

## Development

After cloning the repo, run:

```bash
bundle install
bundle exec rake test
```

## Releasing

```bash
bin/release 1.2.0
```

This bumps the version, commits, tags, pushes, and publishes to RubyGems.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
