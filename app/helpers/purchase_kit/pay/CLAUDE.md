# Paywall helpers

View helpers for rendering paywalls.

## `PaywallHelper`

### `purchasekit_paywall(customer:, success_path:, **options)`

Renders a form that posts to the gem's PurchasesController.

**Parameters:**
- `customer:` (required) - `Pay::Customer` instance
- `success_path:` - Redirect destination after purchase (default: `main_app.root_path`)

**Yields:** `PaywallBuilder` instance

**Generated HTML:**
```html
<form action="/purchasekit/purchases" method="post"
      id="purchasekit_paywall"
      data-controller="purchasekit--paywall"
      data-purchasekit--paywall-customer-id-value="123">
  <input type="hidden" name="customer_id" value="123">
  <input type="hidden" name="success_path" value="/dashboard">
  <!-- yielded content -->
</form>
```

## `PaywallBuilder`

Builder yielded by the paywall helper.

### Methods

| Method | Purpose | Data attributes |
|--------|---------|-----------------|
| `plan_option(product:, selected:)` | Radio + label for a plan | `purchasekit__paywall_target: "planRadio"` |
| `price` | Span for localized price (must be within `plan_option` block) | `purchasekit__paywall_target: "price"` |
| `submit(text)` | Submit button (starts disabled) | `purchasekit__paywall_target: "submitButton"` |

## Usage

Fetch products in the controller, then use them in the view:

```ruby
# Controller
@annual = PurchaseKit::Product.find("prod_XXX")
@monthly = PurchaseKit::Product.find("prod_YYY")
```

```erb
<%= turbo_stream_from dom_id(customer) %>
<%= purchasekit_paywall customer: customer, success_path: paid_path do |paywall| %>
  <%= paywall.plan_option product: @annual, selected: true do %>
    <div>Annual</div>
    <%= paywall.price %>
  <% end %>

  <%= paywall.plan_option product: @monthly do %>
    <div>Monthly</div>
    <%= paywall.price %>
  <% end %>

  <%= paywall.submit "Subscribe" %>
<% end %>
```

Display text (name, description) lives in the view for i18n support. The product only contains the store product IDs.
