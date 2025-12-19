# purchasekit-pay gem

Pay gem integration for in-app purchases.

## Configuration

```ruby
PurchaseKit::Pay.configure do |config|
  config.api_url = Rails.application.credentials.purchasekit[:api_url]
  config.api_key = Rails.application.credentials.purchasekit[:api_key]
  config.app_id = Rails.application.credentials.purchasekit[:app_id]
  config.webhook_secret = Rails.application.credentials.purchasekit[:webhook_secret]
end
```

## Architecture

The gem acts as a bridge between:
1. **Rails app** - Renders paywall, handles webhooks, manages subscriptions
2. **PurchaseKit SaaS** - Normalizes Apple/Google webhooks, manages products and purchase intents
3. **Native app** - Handles App Store/Play Store purchase flow via Hotwire Native Bridge

## Product API

Fetch products from the SaaS API:

```ruby
@product = PurchaseKit::Product.find("prod_XXXXX")
@product.id                 # => "prod_XXXXX"
@product.apple_product_id   # => "com.example.pro.annual"
@product.google_product_id  # => "pro_annual"
```

Products are configured in the SaaS dashboard. The gem fetches them via the API at `/api/v1/apps/:app_id/products/:id`.

## Data flow

```
User taps Subscribe
    -> Form submits to PurchasesController
    -> Creates purchase intent with SaaS (TODO)
    -> Returns correlation ID to native app
    -> Native app triggers App Store purchase
    -> Apple sends webhook to SaaS
    -> SaaS normalizes and POSTs to Rails app
    -> Webhook handler creates Pay::Subscription
    -> Broadcasts Turbo Stream redirect via ActionCable
    -> User redirected to success_path
```

## Engine setup

The engine (`lib/purchasekit/pay/engine.rb`) handles:

1. **Processor registration** - Adds `:purchasekit` to `Pay.enabled_processors`
2. **Webhook handlers** - Calls `Pay::Purchasekit.configure_webhooks` to register handlers
3. **Importmap** - Adds gem's JavaScript (turbo_actions, controllers) to app's importmap
4. **Helpers** - Makes `PaywallHelper` available in views

## Webhook handlers

Registered in `lib/pay/purchasekit.rb` via `Pay::Webhooks.configure`:

- `purchasekit.subscription.created` → Creates `Pay::Subscription`, broadcasts redirect
- `purchasekit.subscription.updated` → Updates status and period dates
- `purchasekit.subscription.canceled` → Sets status to canceled
- `purchasekit.subscription.expired` → Sets status to expired

## JavaScript

- `purchasekit_pay/turbo_actions.js` - Custom `redirect` Turbo Stream action
- `purchasekit_pay/paywall_controller.js` - Handles native bridge communication

Host app must import: `import "purchasekit-pay/turbo_actions"`

The paywall controller sends both `appleStoreProductId` and `googleStoreProductId` to the native bridge, letting the native code pick the right one for its platform.

## Key decisions

- SaaS normalizes Apple/Google payloads (gem never sees raw data)
- Uses Pay gem's webhook infrastructure (`Pay::Webhooks.delegator`)
- Real-time UI updates via Turbo Streams over ActionCable
- `success_path` passed through SaaS in webhook payload (no Rails.cache)
- ActionCable `async` adapter won't work for console testing (in-memory only)
- Products fetched from SaaS API; display text (name, description) lives in the view for i18n support
