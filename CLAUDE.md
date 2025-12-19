# purchasekit-pay gem

Pay gem integration for in-app purchases.

## Architecture

The gem acts as a bridge between:
1. **Rails app** - Renders paywall, handles webhooks, manages subscriptions
2. **PurchaseKit SaaS** - Normalizes Apple/Google webhooks, manages purchase intents
3. **Native app** - Handles App Store/Play Store purchase flow via Hotwire Native Bridge

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

## Key decisions

- SaaS normalizes Apple/Google payloads (gem never sees raw data)
- Uses Pay gem's webhook infrastructure (`Pay::Webhooks.delegator`)
- Real-time UI updates via Turbo Streams over ActionCable
- `success_path` passed through SaaS in webhook payload (no Rails.cache)
- ActionCable `async` adapter won't work for console testing (in-memory only)
