# purchasekit gem

In-app purchase webhook handling for Rails. Provides a Rails engine with webhook endpoint, paywall helpers, JavaScript for Hotwire Native bridge communication, and optional Pay gem integration.

## Architecture

```
PurchaseKit (this gem)
├── Configuration - API credentials, demo mode, event handlers
├── Engine - Rails engine with controllers, helpers, JavaScript
├── ApiClient - HTTP client for PurchaseKit SaaS API
├── Product - Product abstraction (demo/remote)
├── Purchase::Intent - Purchase intent abstraction (demo/remote)
├── Events - Event publishing and callback system
├── WebhookSignature - HMAC-SHA256 signature verification
├── Pay integration (conditional) - Auto-detected when Pay gem is present
└── Error classes
```

## Pay gem integration

The gem auto-detects the Pay gem via `PurchaseKit.pay_enabled?` (checks `defined?(::Pay)`).

**With Pay gem**: Webhooks automatically create Pay::Subscription records and broadcast Turbo Stream redirects via ActionCable.

**Without Pay gem**: Use event callbacks to handle subscriptions with your own models.

## Rails engine

The gem provides a Rails engine that mounts at `/purchasekit`:

```ruby
# config/routes.rb
mount PurchaseKit::Engine, at: "/purchasekit"
```

This adds:
- `POST /purchasekit/webhooks` - Receives webhooks from PurchaseKit SaaS
- `POST /purchasekit/purchases` - Creates purchase intents for native apps (responds with Turbo Stream append)
- `POST /purchasekit/purchase/completions/:id` - Demo mode only - called by iOS after Xcode StoreKit purchase completes

### Controllers

- `PurchaseKit::WebhooksController` - Verifies signature, publishes events via callback system, queues for Pay if available
- `PurchaseKit::PurchasesController` - Creates intents, appends response div via Turbo Stream (form stays visible but disabled)
- `PurchaseKit::Purchase::CompletionsController` - Demo mode only, skips CSRF (called directly by iOS), publishes events and redirects

### Helpers

The `purchasekit_paywall` helper renders a paywall form:

```erb
<%= purchasekit_paywall customer_id: current_user.id, success_path: dashboard_path do |paywall| %>
  <%= paywall.plan_option product: @annual, selected: true do %>
    Annual - <%= paywall.price %>/year
  <% end %>
  <%= paywall.submit "Subscribe" %>
<% end %>
```

The helper accepts `customer_id:` (a simple ID). When using Pay gem, pass `current_user.payment_processor.id`.

### JavaScript

The gem provides:
- `purchasekit--paywall` Stimulus controller for Hotwire Native bridge communication
- `purchasekit/turbo_actions` custom Turbo Stream action for redirects

Import in your application:

```javascript
// app/javascript/application.js
import "purchasekit/turbo_actions"

// app/javascript/controllers/index.js
eagerLoadControllersFrom("purchasekit", application)
```

## Configuration

Configuration is a singleton accessed via `PurchaseKit.config`:

```ruby
PurchaseKit.configure do |config|
  config.api_url = "https://purchasekit.dev"  # Default
  config.api_key = "sk_xxx"
  config.app_id = "app_xxx"
  config.webhook_secret = "whsec_xxx"
  config.demo_mode = false
  config.demo_products = {}
end
```

### Event handlers

Register callbacks using `config.on`:

```ruby
config.on(:subscription_created) { |event| ... }
config.on(:subscription_canceled) { |event| ... }
```

Handlers are stored in `@event_handlers` hash, keyed by event type symbol.

## Event system

`PurchaseKit::Events` handles event publishing:

1. Calls all registered block handlers from `config.handlers_for(type)`
2. Publishes via `ActiveSupport::Notifications` for additional subscribers
3. Returns an `Event` object with parsed payload

### Event class

`PurchaseKit::Events::Event` wraps the raw payload with convenience methods:

- `customer_id` - Your user ID
- `subscription_id` - Store's transaction/purchase ID
- `store` - "apple" or "google"
- `store_product_id` - Store-specific product ID
- `subscription_name` - Name from PurchaseKit dashboard
- `status` - "active", "canceled", "expired"
- `current_period_start/end` - Billing period timestamps
- `ends_at` - When subscription will end
- `success_path` - Redirect path for post-purchase

Time fields are parsed via `Time.zone.parse` when accessed.

## Product and Intent

Both use polymorphic subclasses for demo vs. production:

```
Product.find(id)
├── demo_mode? → Product::Demo (reads from config)
└── else → Product::Remote (API call)

Purchase::Intent.create(...)
├── demo_mode? → Intent::Demo (in-memory store)
└── else → Intent::Remote (API call)
```

### Demo mode

Demo mode enables local development:
- `Product::Demo.find` reads from `config.demo_products`
- `Intent::Demo` stores intents in a class variable hash
- `Intent::Demo.clear_store!` resets for tests

**Demo mode purchase flow:**
1. User clicks Subscribe → form POSTs to `/purchasekit/purchases`
2. Controller creates `Intent::Demo`, appends response div via Turbo Stream
3. JS controller disables form, extracts data, triggers native purchase via bridge
4. iOS shows StoreKit sheet, user completes purchase
5. iOS detects Xcode environment, POSTs to `xcodeCompletionUrl` (absolute URL built by JS)
6. CompletionsController publishes `:subscription_created` event
7. JS receives success status, calls `Turbo.visit(successPath)` to redirect

### Remote mode

Remote implementations call the PurchaseKit SaaS API:
- Products: `GET /api/v1/apps/:app_id/products/:id`
- Intents: `POST /api/v1/apps/:app_id/purchase/intents`

## Webhook signature verification

`WebhookSignature` verifies HMAC-SHA256 signatures:

```ruby
PurchaseKit::WebhookSignature.verify!(
  payload: raw_body,
  signature: header_value,
  secret: config.webhook_secret
)
```

Raises `SignatureVerificationError` if:
- Secret is blank
- Signature is missing
- Signature doesn't match

## Error classes

All errors inherit from `PurchaseKit::Error`:

| Error | HTTP Code | Description |
|-------|-----------|-------------|
| `Error` | - | Base error |
| `NotFoundError` | 404 | Resource not found |
| `SubscriptionRequiredError` | 402 | PurchaseKit subscription needed |
| `SignatureVerificationError` | - | Invalid webhook signature |

## File structure

```
app/
├── controllers/purchase_kit/
│   ├── application_controller.rb
│   ├── webhooks_controller.rb
│   ├── purchases_controller.rb
│   └── purchase/
│       └── completions_controller.rb  # Demo mode Xcode completion
├── helpers/purchase_kit/
│   └── paywall_helper.rb
├── javascript/
│   ├── controllers/purchasekit/
│   │   └── paywall_controller.js
│   └── purchasekit/
│       └── turbo_actions.js
├── models/pay/purchasekit/          # Pay gem integration (loaded conditionally)
│   └── subscription.rb
└── views/purchase_kit/purchases/
    └── _intent.html.erb
config/
├── routes.rb
└── importmap.rb
lib/
├── purchasekit.rb           # Entry point, module definition, conditional Pay loading
└── purchasekit/
    ├── version.rb
    ├── configuration.rb     # Config + event handler registration
    ├── engine.rb            # Rails engine with conditional Pay initializers
    ├── error.rb             # Error classes
    ├── events.rb            # Event publishing + Event class
    ├── webhook_signature.rb # HMAC verification
    ├── api_client.rb        # HTTParty wrapper
    ├── product.rb           # Product base class
    ├── product/
    │   ├── demo.rb
    │   └── remote.rb
    ├── purchase/
    │   ├── intent.rb        # Intent base class
    │   └── intent/
    │       ├── demo.rb
    │       └── remote.rb
    └── pay/                 # Pay gem integration (loaded conditionally)
        ├── webhooks.rb      # Webhook handler registration
        └── webhook.rb       # Background job for webhook processing
```

## Dependencies

- `rails` (>= 7.0, < 9) - Rails engine, controllers, helpers
- `httparty` (~> 0.22) - HTTP client

## Testing

Tests should cover:

- Configuration (defaults, setters, event registration)
- Events (publishing, Event class methods)
- WebhookSignature (valid/invalid/missing signatures)
- Product (demo find, remote find with VCR)
- Intent (demo create/find, remote create with VCR)
- ApiClient (URL building, headers)
- Controllers (webhook verification, intent creation, demo completions)
- Helpers (paywall form generation)
- Pay integration (conditional loading, subscription creation)

## Key decisions

- **Single gem with conditional Pay**: Auto-detects Pay gem via `defined?(::Pay)` and loads integration
- **Rails engine**: Provides full-featured webhook handling out of the box
- **Callback-based**: Users without Pay bring their own storage/models
- **Polymorphism over conditionals**: Demo/Remote dispatch in base classes
- **Event object**: Parsed payload with time conversion, not raw hash
- **Signature verification extracted**: Reusable outside controllers
- **Demo mode completions**: Xcode StoreKit testing can complete purchases without real webhooks
